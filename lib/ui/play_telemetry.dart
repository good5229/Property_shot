import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/domain/geometry.dart';
import '../game/levels/levels.dart';
import 'play_telemetry_schema.dart';

export 'play_telemetry_schema.dart';

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
  }) : sessionId =
           sessionId ??
           DateTime.now().toUtc().microsecondsSinceEpoch.toString(),
       _store = store ?? LocalPlayTelemetryStore();

  final String sessionId;
  final String buildId;
  final bool persistLocally;
  final LocalPlayTelemetryStore _store;
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
    };
    _appendEvent(event);
  }

  void _appendEvent(Map<String, Object?> event) {
    _events.add(event);
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
      '재시도' => 'retry_pressed',
      '단계 종료' => 'stage_exit',
      _ => 'custom',
    };
  }
}
