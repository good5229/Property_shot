import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/domain/geometry.dart';
import '../game/levels/levels.dart';
import 'play_telemetry_schema.dart';

export 'play_telemetry_schema.dart';

enum InputLatencyGateStatus { insufficientSamples, passed, failed }

class InputLatencyReport {
  const InputLatencyReport._({
    required this.sampleCount,
    required this.invalidSampleCount,
    required this.replaySampleCount,
    required this.p95Milliseconds,
    required this.maximumMilliseconds,
    required this.status,
  });

  static const minimumSampleCount = 20;
  static const targetP95Milliseconds = 50.0;

  factory InputLatencyReport.fromEvents(Iterable<Map<String, Object?>> events) {
    final samples = <double>[];
    var invalidSampleCount = 0;
    var replaySampleCount = 0;
    for (final event in events) {
      if (event['event_code'] != PlayTelemetryEventType.shotReleased.code) {
        continue;
      }
      if (event['is_replay'] == true) {
        replaySampleCount++;
        continue;
      }
      final raw = event['input_latency_ms'];
      if (raw is! num || !raw.isFinite || raw < 0) {
        invalidSampleCount++;
        continue;
      }
      samples.add(raw.toDouble());
    }
    samples.sort();
    final p95 = samples.isEmpty ? null : _nearestRank(samples, 0.95);
    final status = samples.length < minimumSampleCount
        ? InputLatencyGateStatus.insufficientSamples
        : p95! <= targetP95Milliseconds
        ? InputLatencyGateStatus.passed
        : InputLatencyGateStatus.failed;
    return InputLatencyReport._(
      sampleCount: samples.length,
      invalidSampleCount: invalidSampleCount,
      replaySampleCount: replaySampleCount,
      p95Milliseconds: p95,
      maximumMilliseconds: samples.isEmpty ? null : samples.last,
      status: status,
    );
  }

  final int sampleCount;
  final int invalidSampleCount;
  final int replaySampleCount;
  final double? p95Milliseconds;
  final double? maximumMilliseconds;
  final InputLatencyGateStatus status;

  String get statusLabel => switch (status) {
    InputLatencyGateStatus.insufficientSamples => '표본 부족',
    InputLatencyGateStatus.passed => '기준 통과',
    InputLatencyGateStatus.failed => '기준 미통과',
  };

  String get summaryLabel {
    if (p95Milliseconds == null) {
      return '입력 지연 표본 0/$minimumSampleCount개 · 더 수집 필요';
    }
    if (status == InputLatencyGateStatus.insufficientSamples) {
      return '입력 지연 표본 $sampleCount/$minimumSampleCount개 · '
          'p95 ${p95Milliseconds!.toStringAsFixed(1)}밀리초';
    }
    return '입력 지연 p95 ${p95Milliseconds!.toStringAsFixed(1)}밀리초 · '
        '$statusLabel';
  }

  Map<String, Object?> toJson() => {
    '판정': statusLabel,
    '유효표본수': sampleCount,
    '최소표본수': minimumSampleCount,
    '제외된잘못된표본수': invalidSampleCount,
    '제외된리플레이표본수': replaySampleCount,
    '입력지연p95밀리초': p95Milliseconds,
    '입력지연최대밀리초': maximumMilliseconds,
    '목표p95밀리초': targetP95Milliseconds,
  };

  static double _nearestRank(List<double> sorted, double ratio) {
    final rank = (sorted.length * ratio).ceil().clamp(1, sorted.length).toInt();
    return sorted[rank - 1];
  }
}

class LocalPlayTelemetryStore {
  LocalPlayTelemetryStore({this.maxEvents = 2000});

  static const storageKey = 'property_shot_local_play_log_v1';

  final int maxEvents;
  Future<void> _writeTail = Future<void>.value();

  Future<void> append(Map<String, Object?> event) {
    return appendAll([event]);
  }

  Future<void> appendAll(Iterable<Map<String, Object?>> newEvents) {
    final batch = newEvents.map(Map<String, Object?>.from).toList();
    if (batch.isEmpty) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final events = await _read(preferences);
      events.addAll(batch);
      final first = events.length > maxEvents ? events.length - maxEvents : 0;
      await preferences.setString(
        storageKey,
        jsonEncode(events.sublist(first)),
      );
    });
  }

  Future<List<Map<String, Object?>>> load() {
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      return _read(preferences);
    });
  }

  Future<void> clear() {
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(storageKey);
    });
  }

  Future<void> flush() => _writeTail;

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<List<Map<String, Object?>>> _read(
    SharedPreferences preferences,
  ) async {
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, Object?>>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, Object?>>[];
      }
      return decoded
          .whereType<Map>()
          .map((event) => Map<String, Object?>.from(event))
          .toList(growable: true);
    } on Object {
      return <Map<String, Object?>>[];
    }
  }
}

/// 실제 사용자 식별 정보 없이 내부 플레이 흐름만 기록하는 로컬 계측기다.
/// 서버 전송은 하지 않으며, 최근 이벤트를 로컬 저장소에만 보관한다.
class LocalPlayTelemetry {
  LocalPlayTelemetry({
    String? sessionId,
    this.buildId = 'property-shot-dev',
    LocalPlayTelemetryStore? store,
    this.persistLocally = true,
    this.maxMemoryEvents = 2000,
  }) : assert(maxMemoryEvents > 0),
       sessionId =
           sessionId ??
           DateTime.now().toUtc().microsecondsSinceEpoch.toString(),
       _store = store ?? LocalPlayTelemetryStore();

  final String sessionId;
  final String buildId;
  final bool persistLocally;
  final int maxMemoryEvents;
  final LocalPlayTelemetryStore _store;
  final Stopwatch _sessionElapsed = Stopwatch()..start();
  final List<Map<String, Object?>> _events = [];
  final List<Map<String, Object?>> _pendingPersistence = [];
  Timer? _persistTimer;

  List<Map<String, Object?>> get events => List.unmodifiable(_events);

  void record(
    String type, {
    required int stage,
    int? attempt,
    String? action,
    String? trait,
    double? angle,
    double? power,
    String? target,
    String? result,
    String? resultCode,
    String? routeTag,
    String? eventCode,
    int? shotId,
    String? objectId,
    String? objectType,
    String? contactId,
    String? attributeBefore,
    String? attributeAfter,
    Vec2? position,
    Vec2? velocity,
    Vec2? collisionNormal,
    double? speed,
    double? speedBefore,
    double? speedAfter,
    double? referenceSpeed,
    double? mass,
    double? impulse,
    bool? isReplay,
    String? fpsBucket,
    int? elapsedMs,
  }) {
    final event = <String, Object?>{
      '시간': DateTime.now().toUtc().toIso8601String(),
      'session_elapsed_ms': _sessionElapsed.elapsedMilliseconds,
      '유형': type,
      '단계': stage + 1,
      'stage_id': _stageId(stage),
      'session_id': sessionId,
      'build_id': buildId,
      'event_code': eventCode ?? _eventCode(type),
    };
    if (attempt != null) event['시도'] = attempt;
    if (action != null) event['행동'] = action;
    if (trait != null) event['속성'] = trait;
    if (angle != null) event['각도'] = angle;
    if (power != null) event['힘'] = power;
    if (target != null) event['대상'] = target;
    if (result != null) event['결과'] = result;
    if (resultCode != null) event['result_code'] = resultCode;
    if (routeTag != null) event['route_tag'] = routeTag;
    if (shotId != null) event['shot_id'] = shotId;
    if (objectId != null) event['object_id'] = objectId;
    if (objectType != null) event['object_type'] = objectType;
    if (contactId != null) event['contact_id'] = contactId;
    if (attributeBefore != null) {
      event['attribute_before'] = attributeBefore;
    }
    if (attributeAfter != null) event['attribute_after'] = attributeAfter;
    if (position != null) event['position'] = position.toJson();
    if (velocity != null) event['velocity'] = velocity.toJson();
    if (collisionNormal != null) {
      event['collision_normal'] = collisionNormal.toJson();
    }
    if (speed != null) event['speed'] = speed;
    if (speedBefore != null) event['speed_before'] = speedBefore;
    if (speedAfter != null) event['speed_after'] = speedAfter;
    if (referenceSpeed != null) event['reference_speed'] = referenceSpeed;
    if (mass != null) event['mass'] = mass;
    if (impulse != null) event['impulse'] = impulse;
    if (isReplay != null) event['is_replay'] = isReplay;
    if (fpsBucket != null) event['fps_bucket'] = fpsBucket;
    if (elapsedMs != null) event['elapsed_ms'] = elapsedMs;
    _appendEvent(event);
  }

  void recordTyped(TypedPlayTelemetryEvent typedEvent) {
    final context = typedEvent.context;
    final result = typedEvent.result ?? typedEvent.shot?.result;
    final event = <String, Object?>{
      '시간': DateTime.now().toUtc().toIso8601String(),
      'session_elapsed_ms': _sessionElapsed.elapsedMilliseconds,
      '유형': typedEvent.type.displayName,
      '단계': context.stageIndex + 1,
      'stage_id': context.stageId,
      'session_id': sessionId,
      'build_id': buildId,
      'event_code': typedEvent.type.code,
      if (result != null) '결과': result.displayName,
      if (result != null) 'result_code': result.code,
      ...context.toJson(),
      if (typedEvent.shot != null) ...typedEvent.shot!.toJson(),
      if (typedEvent.hint != null) ...typedEvent.hint!.toJson(),
      if (typedEvent.key != null) ...typedEvent.key!.toJson(),
      if (typedEvent.stageOutcome != null) ...typedEvent.stageOutcome!.toJson(),
      if (typedEvent.powerGauge != null) ...typedEvent.powerGauge!.toJson(),
      if (typedEvent.rewardUse != null) ...typedEvent.rewardUse!.toJson(),
    };
    _appendEvent(event);
  }

  void _appendEvent(Map<String, Object?> event) {
    _events.add(event);
    final overflow = _events.length - maxMemoryEvents;
    if (overflow > 0) {
      _events.removeRange(0, overflow);
    }
    if (persistLocally) {
      _pendingPersistence.add(Map<String, Object?>.from(event));
      _schedulePersistence();
    }
  }

  Future<void> flush() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    await _persistPending();
    await _store.flush();
  }

  Future<List<Map<String, Object?>>> loadPersisted() async {
    await flush();
    return _store.load();
  }

  Future<void> clearPersisted() async {
    _persistTimer?.cancel();
    _persistTimer = null;
    _pendingPersistence.clear();
    await _store.flush();
    await _store.clear();
  }

  Future<void> close() => flush();

  void _schedulePersistence() {
    if (_persistTimer != null) {
      return;
    }
    _persistTimer = Timer(const Duration(milliseconds: 250), () {
      _persistTimer = null;
      unawaited(_persistPending());
    });
  }

  Future<void> _persistPending() {
    if (_pendingPersistence.isEmpty || !persistLocally) {
      return Future<void>.value();
    }
    final batch = List<Map<String, Object?>>.from(_pendingPersistence);
    _pendingPersistence.clear();
    return _store.appendAll(batch);
  }

  void sessionStart({required int stage, String? experimentVariant}) {
    record(
      '세션 시작',
      stage: stage,
      eventCode: 'session_start',
      result: experimentVariant,
    );
  }

  void sessionEnd({required int stage}) {
    record('세션 종료', stage: stage, eventCode: 'session_end');
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_events);

  /// 현재 플레이 세션만 개인정보가 남지 않는 형태로 내보낸다.
  ///
  /// 서버 전송이나 외부 링크 생성은 하지 않는다. 절대 시각과 내부 세션 식별자는
  /// 제거하고, 사건 순서와 게임 분석에 필요한 값만 남긴다.
  Future<String> exportPrivacySafeSessionJson() async {
    final persisted = await loadPersisted();
    final sessionEvents = persisted
        .where((event) => event['session_id'] == sessionId)
        .toList(growable: false);
    final source = sessionEvents.isEmpty ? _events : sessionEvents;
    final sanitized = <Map<String, Object?>>[];
    for (var index = 0; index < source.length; index++) {
      final event = Map<String, Object?>.from(source[index])
        ..remove('시간')
        ..remove('session_id');
      sanitized.add(<String, Object?>{'순서': index + 1, ...event});
    }
    final eventCounts = <String, int>{};
    final stageCounts = <String, int>{};
    for (final event in sanitized) {
      final eventCode = event['event_code']?.toString() ?? 'unknown';
      final stageId = event['stage_id']?.toString() ?? 'unknown';
      eventCounts[eventCode] = (eventCounts[eventCode] ?? 0) + 1;
      stageCounts[stageId] = (stageCounts[stageId] ?? 0) + 1;
    }
    return const JsonEncoder.withIndent('  ').convert(<String, Object?>{
      'schema': 'property-shot-local-session/v1',
      'privacy': <String, Object?>{
        'local_only': true,
        'external_link_created': false,
        'removed_fields': const ['시간', 'session_id'],
      },
      'summary': <String, Object?>{
        'event_count': sanitized.length,
        'events_by_code': Map<String, int>.fromEntries(
          eventCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        ),
        'events_by_stage': Map<String, int>.fromEntries(
          stageCounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
        ),
      },
      'events': sanitized,
    });
  }

  InputLatencyReport get inputLatencyReport =>
      InputLatencyReport.fromEvents(_events);

  String exportInputLatencyReportJson() =>
      const JsonEncoder.withIndent('  ').convert(inputLatencyReport.toJson());

  String exportCsv() {
    const columns = [
      '시간',
      '유형',
      '단계',
      'stage_id',
      '시도',
      '행동',
      '속성',
      '각도',
      '힘',
      '대상',
      '결과',
      'result_code',
      'route_tag',
      'event_code',
      'session_id',
      'build_id',
      'shot_id',
      'object_id',
      'object_type',
      'contact_id',
      'attribute_before',
      'attribute_after',
      'position',
      'velocity',
      'collision_normal',
      'speed',
      'speed_before',
      'speed_after',
      'reference_speed',
      'mass',
      'impulse',
      'is_replay',
      'fps_bucket',
      'elapsed_ms',
      'pattern_id',
      'seed',
      'resolver_version',
      'reward_candidate_ids',
      'reward_selected_id',
      'reward_acquired_ids',
      'clone_core_count',
      'reward_used_id',
      'reward_use_key',
      'reward_use_trigger',
      'reward_use_stage_scoped',
      'reward_selection_record_id',
      'reward_use_stage_distance',
      'ball_traits',
      'causal_chain',
      'causal_depth',
      'effective_chain_length',
      'distinct_object_type_count',
      'distinct_object_count',
      'wall_use_count',
      'ball_use_count',
      'object_use_count',
      'score_damped',
      'nearest_hole_distance',
      'frame_duration_ms',
      'input_latency_ms',
      'telemetry_result',
      'hint_source',
      'hint_level',
      'hint_opened_count',
      'hint_failure_count_before_open',
      'hint_cleared_after_open',
      'key_id',
      'key_shot_id',
      'key_collected',
      'key_shots_until_collected',
      'key_collected_before_clear',
      'direct_clear',
      'hint_used_before_clear',
      'failure_count_before_hint',
      'failure_count_after_hint',
      'gimmick_types',
      'effective_chain_score',
      'power_gauge_charge_stage',
      'power_gauge_power',
      'power_gauge_cancelled',
      'session_elapsed_ms',
    ];
    final rows = <String>[columns.join(',')];
    for (final event in _events) {
      rows.add(columns.map((column) => _csvValue(event[column])).join(','));
    }
    return rows.join('\n');
  }

  static String _csvValue(Object? value) {
    final text = value?.toString() ?? '';
    if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
      return text;
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  static String _stageId(int stage) {
    if (stage >= 0 && stage < levels.length) {
      return levels[stage].id;
    }
    return 'stage_$stage';
  }

  static String _eventCode(String type) {
    return switch (type) {
      '세션 시작' => 'session_start',
      '세션 종료' => 'session_end',
      '단계 시작' => 'stage_enter',
      '속성 확인' => 'object_inspected',
      '속성 이전 열기' => 'attribute_transfer_opened',
      '속성 이전' => 'attribute_transferred',
      '속성 복사' => 'attribute_copied',
      '속성 행동 취소' => 'attribute_action_cancelled',
      '조준 시작' => 'aim_started',
      '조준 방향 변경' => 'aim_direction_changed',
      '충전 시작' => 'charge_started',
      '충전 종료' => 'charge_released',
      '발사' => 'shot_fired',
      '충돌' => 'collision_resolved',
      '연쇄 이동' => 'object_started_moving',
      '물체 정지' => 'object_stopped',
      '속성 소모' => 'attribute_consumed',
      '스위치 작동' => 'switch_activated',
      '문 열림' => 'door_opened',
      '풍선 변형' => 'balloon_deformed',
      '풍선 터짐' => 'balloon_popped',
      '점착 정지' => 'ball_stuck',
      '홀 진입' => 'ball_entered_hole',
      '클리어' => 'stage_cleared',
      '실패' => 'stage_failed_or_reset',
      '힌트 노출' => 'hint_exposed',
      '다음 단계 팁 보상 제시' => 'hint_reward_offered',
      '다음 단계 팁 보상 선택' => 'hint_reward_selected',
      '팁 사용 가능' => 'hint_available',
      '팁 열기' => 'hint_opened',
      '팁 단계 열기' => 'hint_level_opened',
      '열쇠 생성' => 'key_spawned',
      '열쇠 획득' => 'key_collected',
      '열쇠 미획득' => 'key_ignored',
      '시연 직선 클리어 감지' => 'demo_direct_clear_detected',
      '파워 게이지 충전 시작' => 'power_gauge_charge_started',
      '파워 게이지 취소' => 'power_gauge_cancelled',
      '재시도' => 'retry_pressed',
      '단계 종료' => 'stage_exit',
      _ => 'custom',
    };
  }
}
