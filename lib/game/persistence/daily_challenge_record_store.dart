import 'dart:convert';

import '../run/daily_challenge.dart';
import '../run/run_state.dart';
import 'run_state_store.dart';

const int currentDailyChallengeRecordSchemaVersion = 2;

/// 정식 오늘의 도전만 기록하는 날짜·버전별 로컬 기록이다.
class DailyChallengeRecord {
  DailyChallengeRecord({
    required this.dateKey,
    required this.challengeVersion,
    required this.resolverVersion,
    required this.officialAttemptCount,
    required this.completed,
    required this.bestTotalScore,
    required this.bestShotSum,
    required this.activeAttemptId,
    required this.activeRunId,
    required this.completedAttemptId,
    required this.completedRunId,
    required this.completedRunRevision,
    required this.updatedAt,
  }) {
    DailyChallengeDate.fromKey(dateKey);
    if (challengeVersion.trim().isEmpty || resolverVersion.trim().isEmpty) {
      throw ArgumentError('오늘의 도전 버전은 비어 있을 수 없습니다.');
    }
    if (officialAttemptCount < 0 || bestTotalScore < 0) {
      throw ArgumentError('오늘의 도전 기록 수치는 음수일 수 없습니다.');
    }
    if (bestShotSum != null && bestShotSum! < 1) {
      throw ArgumentError('오늘의 도전 최고 샷 수는 1 이상이어야 합니다.');
    }
    if ((activeAttemptId == null) != (activeRunId == null)) {
      throw ArgumentError('진행 중인 시도와 런 식별자는 함께 기록되어야 합니다.');
    }
    final hasCompletedAttempt = completedAttemptId != null;
    if (hasCompletedAttempt != (completedRunId != null) ||
        hasCompletedAttempt != (completedRunRevision != null)) {
      throw ArgumentError('완료 시도, 런, revision은 함께 기록되어야 합니다.');
    }
    if (completedRunRevision != null && completedRunRevision! < 1) {
      throw ArgumentError('완료 revision은 1 이상이어야 합니다.');
    }
    if (completed != hasCompletedAttempt) {
      throw ArgumentError('완료 여부와 완료 시도 정보가 일치해야 합니다.');
    }
    if ((activeAttemptId != null || hasCompletedAttempt) &&
        officialAttemptCount < 1) {
      throw ArgumentError('시도 정보가 있는 기록의 정식 시도 수는 1 이상이어야 합니다.');
    }
    for (final attemptId in <String?>[activeAttemptId, completedAttemptId]) {
      if (attemptId != null &&
          !RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(attemptId)) {
        throw ArgumentError('오늘의 도전 시도 식별자 형식이 올바르지 않습니다.');
      }
    }
  }

  factory DailyChallengeRecord.empty(DailyChallengeDefinition definition) {
    return DailyChallengeRecord(
      dateKey: definition.dateKey,
      challengeVersion: definition.challengeVersion,
      resolverVersion: definition.resolverVersion,
      officialAttemptCount: 0,
      completed: false,
      bestTotalScore: 0,
      bestShotSum: null,
      activeAttemptId: null,
      activeRunId: null,
      completedAttemptId: null,
      completedRunId: null,
      completedRunRevision: null,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String dateKey;
  final String challengeVersion;
  final String resolverVersion;
  final int officialAttemptCount;
  final bool completed;
  final int bestTotalScore;
  final int? bestShotSum;
  final String? activeAttemptId;
  final String? activeRunId;
  final String? completedAttemptId;
  final String? completedRunId;
  final int? completedRunRevision;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'schemaVersion': currentDailyChallengeRecordSchemaVersion,
    'dateKey': dateKey,
    'challengeVersion': challengeVersion,
    'resolverVersion': resolverVersion,
    'officialAttemptCount': officialAttemptCount,
    'completed': completed,
    'bestTotalScore': bestTotalScore,
    'bestShotSum': bestShotSum,
    'activeAttemptId': activeAttemptId,
    'activeRunId': activeRunId,
    'completedAttemptId': completedAttemptId,
    'completedRunId': completedRunId,
    'completedRunRevision': completedRunRevision,
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory DailyChallengeRecord.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != currentDailyChallengeRecordSchemaVersion ||
        json['dateKey'] is! String ||
        json['challengeVersion'] is! String ||
        json['resolverVersion'] is! String ||
        json['officialAttemptCount'] is! int ||
        json['completed'] is! bool ||
        json['bestTotalScore'] is! int ||
        (json['bestShotSum'] != null && json['bestShotSum'] is! int) ||
        (json['activeAttemptId'] != null &&
            json['activeAttemptId'] is! String) ||
        (json['activeRunId'] != null && json['activeRunId'] is! String) ||
        (json['completedAttemptId'] != null &&
            json['completedAttemptId'] is! String) ||
        (json['completedRunId'] != null && json['completedRunId'] is! String) ||
        (json['completedRunRevision'] != null &&
            json['completedRunRevision'] is! int) ||
        json['updatedAt'] is! String) {
      throw const FormatException('오늘의 도전 기록 형식이 오래되었거나 손상되었습니다.');
    }
    final parsedUpdatedAt = DateTime.tryParse(json['updatedAt'] as String);
    if (parsedUpdatedAt == null) {
      throw const FormatException('오늘의 도전 기록 갱신 시각이 올바르지 않습니다.');
    }
    return DailyChallengeRecord(
      dateKey: json['dateKey'] as String,
      challengeVersion: json['challengeVersion'] as String,
      resolverVersion: json['resolverVersion'] as String,
      officialAttemptCount: json['officialAttemptCount'] as int,
      completed: json['completed'] as bool,
      bestTotalScore: json['bestTotalScore'] as int,
      bestShotSum: json['bestShotSum'] as int?,
      activeAttemptId: json['activeAttemptId'] as String?,
      activeRunId: json['activeRunId'] as String?,
      completedAttemptId: json['completedAttemptId'] as String?,
      completedRunId: json['completedRunId'] as String?,
      completedRunRevision: json['completedRunRevision'] as int?,
      updatedAt: parsedUpdatedAt.toUtc(),
    );
  }
}

/// 날짜·도전 버전·물리 버전별 공식 기록을 A/B 슬롯에 저장한다.
class DailyChallengeRecordStore {
  DailyChallengeRecordStore({
    required this.backend,
    required this.definition,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  static const int envelopeSchemaVersion = 1;
  static final Expando<_DailyRecordOperationCoordinator> _coordinators =
      Expando<_DailyRecordOperationCoordinator>();

  final RunStateKeyValueBackend backend;
  final DailyChallengeDefinition definition;
  final DateTime Function() _now;
  late final _DailyRecordOperationCoordinator _coordinator = _coordinatorFor(
    backend,
  );

  String get keyPrefix {
    final versionFingerprint = runStatePayloadChecksum(
      '${definition.challengeVersion}|${definition.resolverVersion}',
    );
    return 'property_shot_daily_record_v2_${definition.dateKey}_$versionFingerprint';
  }

  String get slotAKey => '${keyPrefix}_slot_a';
  String get slotBKey => '${keyPrefix}_slot_b';
  String get activePointerKey => '${keyPrefix}_active_pointer';

  Future<DailyChallengeRecord> load() => _enqueue(_loadUnqueued);

  /// 같은 [attemptId]로 재시도해도 시도 수는 한 번만 증가한다.
  Future<DailyChallengeRecord> beginOfficialAttempt({
    required String attemptId,
    required String runId,
  }) =>
      _enqueue(() => _beginOfficialAttempt(attemptId: attemptId, runId: runId));

  /// 진행 중인 시도를 사용자가 명시적으로 포기한 뒤에만 새 시도를 허용한다.
  Future<DailyChallengeRecord> abandonOfficialAttempt({
    required String attemptId,
    required String runId,
  }) => _enqueue(
    () => _abandonOfficialAttempt(attemptId: attemptId, runId: runId),
  );

  /// 연습 결과는 공식 기록을 변경하지 않고 현재 기록만 반환한다.
  Future<DailyChallengeRecord> recordPracticeResult({
    required int totalScore,
    required int totalShotSum,
  }) async {
    _validateResult(totalScore: totalScore, totalShotSum: totalShotSum);
    return load();
  }

  /// 저장된 완료 RunState를 직접 대조해 공식 기록을 멱등 복구한다.
  Future<DailyChallengeRecord> reconcileCompletedRun({
    required DailyChallengeRunStateStorage runStateStorage,
  }) => _enqueue(() => _reconcileCompletedRun(runStateStorage));

  Future<DailyChallengeRecord> _loadUnqueued() async {
    final a = await _readCandidate(_RecordSlot.a);
    final b = await _readCandidate(_RecordSlot.b);
    final pointer = await backend.read(activePointerKey);
    final selected = _selectCandidate(a, b, pointer);
    return selected?.record ?? DailyChallengeRecord.empty(definition);
  }

  Future<DailyChallengeRecord> _beginOfficialAttempt({
    required String attemptId,
    required String runId,
  }) async {
    _validateAttempt(attemptId: attemptId, runId: runId);
    final current = await _loadUnqueued();
    if ((current.activeAttemptId == attemptId &&
            current.activeRunId == runId) ||
        (current.completedAttemptId == attemptId &&
            current.completedRunId == runId)) {
      return current;
    }
    if (current.activeAttemptId != null) {
      throw StateError('진행 중인 정식 시도를 먼저 이어서 하거나 포기해 주세요.');
    }
    final next = DailyChallengeRecord(
      dateKey: definition.dateKey,
      challengeVersion: definition.challengeVersion,
      resolverVersion: definition.resolverVersion,
      officialAttemptCount: current.officialAttemptCount + 1,
      completed: current.completed,
      bestTotalScore: current.bestTotalScore,
      bestShotSum: current.bestShotSum,
      activeAttemptId: attemptId,
      activeRunId: runId,
      completedAttemptId: current.completedAttemptId,
      completedRunId: current.completedRunId,
      completedRunRevision: current.completedRunRevision,
      updatedAt: _nextUpdatedAt(current),
    );
    await _save(next);
    return next;
  }

  Future<DailyChallengeRecord> _abandonOfficialAttempt({
    required String attemptId,
    required String runId,
  }) async {
    _validateAttempt(attemptId: attemptId, runId: runId);
    final current = await _loadUnqueued();
    if (current.activeAttemptId == null) return current;
    if (current.activeAttemptId != attemptId || current.activeRunId != runId) {
      throw StateError('현재 정식 시도와 포기 요청이 일치하지 않습니다.');
    }
    final next = DailyChallengeRecord(
      dateKey: definition.dateKey,
      challengeVersion: definition.challengeVersion,
      resolverVersion: definition.resolverVersion,
      officialAttemptCount: current.officialAttemptCount,
      completed: current.completed,
      bestTotalScore: current.bestTotalScore,
      bestShotSum: current.bestShotSum,
      activeAttemptId: null,
      activeRunId: null,
      completedAttemptId: current.completedAttemptId,
      completedRunId: current.completedRunId,
      completedRunRevision: current.completedRunRevision,
      updatedAt: _nextUpdatedAt(current),
    );
    await _save(next);
    return next;
  }

  Future<DailyChallengeRecord> _reconcileCompletedRun(
    DailyChallengeRunStateStorage runStateStorage,
  ) async {
    final current = await _loadUnqueued();
    final attemptId = current.activeAttemptId ?? current.completedAttemptId;
    final expectedRunId = current.activeRunId ?? current.completedRunId;
    if (attemptId == null || expectedRunId == null) {
      throw StateError('대조할 정식 시도가 없습니다.');
    }
    if (runStateStorage.mode != DailyChallengeMode.official ||
        runStateStorage.attemptId != attemptId ||
        runStateStorage.definition.dateKey != definition.dateKey ||
        runStateStorage.definition.challengeVersion !=
            definition.challengeVersion ||
        runStateStorage.definition.resolverVersion !=
            definition.resolverVersion) {
      throw StateError('현재 정식 시도와 RunState 저장소가 일치하지 않습니다.');
    }
    final snapshot = await runStateStorage.loadSnapshot();
    final runState = snapshot.state;
    final runRevision = snapshot.revision;
    if (runState == null ||
        runRevision == null ||
        runState.phase != RunPhase.runCompleted ||
        runState.runId != expectedRunId ||
        runState.rootSeed != definition.rootSeed ||
        runState.resolverVersion != definition.resolverVersion) {
      throw StateError('저장된 완료 런이 현재 오늘의 도전 시도와 일치하지 않습니다.');
    }
    final totalShotSum = runState.shotsPerStage.values.fold<int>(
      0,
      (sum, shots) => sum + shots,
    );
    _validateResult(
      totalScore: runState.totalScore,
      totalShotSum: totalShotSum,
    );
    if (current.completedAttemptId == attemptId) {
      if (current.completedRunId != runState.runId ||
          current.completedRunRevision != runRevision) {
        throw StateError('이미 완료된 시도의 저장 revision이 달라졌습니다.');
      }
      return current;
    }
    if (current.activeAttemptId != attemptId ||
        current.activeRunId != runState.runId) {
      throw StateError('현재 정식 시도와 완료 런이 일치하지 않습니다.');
    }
    final next = DailyChallengeRecord(
      dateKey: definition.dateKey,
      challengeVersion: definition.challengeVersion,
      resolverVersion: definition.resolverVersion,
      officialAttemptCount: current.officialAttemptCount,
      completed: true,
      bestTotalScore: runState.totalScore > current.bestTotalScore
          ? runState.totalScore
          : current.bestTotalScore,
      bestShotSum:
          current.bestShotSum == null || totalShotSum < current.bestShotSum!
          ? totalShotSum
          : current.bestShotSum,
      activeAttemptId: null,
      activeRunId: null,
      completedAttemptId: attemptId,
      completedRunId: runState.runId,
      completedRunRevision: runRevision,
      updatedAt: _nextUpdatedAt(current),
    );
    await _save(next);
    return next;
  }

  Future<void> _save(DailyChallengeRecord record) async {
    final a = await _readCandidate(_RecordSlot.a);
    final b = await _readCandidate(_RecordSlot.b);
    final pointer = await backend.read(activePointerKey);
    final selected = _selectCandidate(a, b, pointer);
    final nextRevision = _maxRevision(a, b) + 1;
    final target = selected?.slot == _RecordSlot.a
        ? _RecordSlot.b
        : _RecordSlot.a;
    final payload = canonicalJson(record.toJson());
    final envelope = jsonEncode({
      'schemaVersion': envelopeSchemaVersion,
      'complete': true,
      'revision': nextRevision,
      'payload': payload,
      'checksum': runStatePayloadChecksum(payload),
    });
    await backend.write(_keyFor(target), envelope);
    final verified = await _readCandidate(target);
    if (verified == null ||
        verified.revision != nextRevision ||
        canonicalJson(verified.record.toJson()) != payload) {
      throw StateError('오늘의 도전 기록 후보 슬롯 검증에 실패했습니다.');
    }
    await backend.write(activePointerKey, _pointerFor(target));
  }

  Future<_RecordEnvelope?> _readCandidate(_RecordSlot slot) async {
    final raw = await backend.read(_keyFor(slot));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final envelope = Map<String, dynamic>.from(decoded);
      if (envelope['schemaVersion'] != envelopeSchemaVersion ||
          envelope['complete'] != true ||
          envelope['revision'] is! int ||
          (envelope['revision'] as int) < 1 ||
          envelope['payload'] is! String ||
          envelope['checksum'] is! String) {
        return null;
      }
      final payload = envelope['payload'] as String;
      final payloadJson = jsonDecode(payload);
      if (payloadJson is! Map) return null;
      final canonicalPayload = canonicalJson(payloadJson);
      if (canonicalPayload != payload ||
          runStatePayloadChecksum(payload) != envelope['checksum']) {
        return null;
      }
      final record = DailyChallengeRecord.fromJson(
        Map<String, dynamic>.from(payloadJson),
      );
      if (record.dateKey != definition.dateKey ||
          record.challengeVersion != definition.challengeVersion ||
          record.resolverVersion != definition.resolverVersion) {
        return null;
      }
      return _RecordEnvelope(
        slot: slot,
        revision: envelope['revision'] as int,
        record: record,
      );
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    } on TypeError {
      return null;
    }
  }

  _RecordEnvelope? _selectCandidate(
    _RecordEnvelope? a,
    _RecordEnvelope? b,
    String? pointer,
  ) {
    if (a == null) return b;
    if (b == null) return a;
    if (a.revision > b.revision) return a;
    if (b.revision > a.revision) return b;
    if (pointer == 'b') return b;
    return a;
  }

  int _maxRevision(_RecordEnvelope? a, _RecordEnvelope? b) {
    final aRevision = a?.revision ?? 0;
    final bRevision = b?.revision ?? 0;
    return aRevision > bRevision ? aRevision : bRevision;
  }

  String _keyFor(_RecordSlot slot) =>
      slot == _RecordSlot.a ? slotAKey : slotBKey;

  String _pointerFor(_RecordSlot slot) => slot == _RecordSlot.a ? 'a' : 'b';

  void _validateAttempt({required String attemptId, required String runId}) {
    final expectedRunId = definition.officialRunId(attemptId);
    if (runId != expectedRunId) {
      throw ArgumentError.value(runId, 'runId', '정식 시도 식별자와 일치하지 않습니다.');
    }
  }

  void _validateResult({required int totalScore, required int totalShotSum}) {
    if (totalScore < 0 || totalShotSum < 1) {
      throw ArgumentError('오늘의 도전 점수는 0 이상, 발사 합계는 1 이상이어야 합니다.');
    }
  }

  DateTime _nextUpdatedAt(DailyChallengeRecord current) {
    final now = _now().toUtc();
    return now.isAfter(current.updatedAt) ? now : current.updatedAt;
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) =>
      _coordinator.enqueue(operation);

  static _DailyRecordOperationCoordinator _coordinatorFor(
    RunStateKeyValueBackend backend,
  ) {
    final identity = backend is RunStateBackendSynchronizationIdentity
        ? (backend as RunStateBackendSynchronizationIdentity)
              .synchronizationIdentity
        : backend;
    return _coordinators[identity] ??= _DailyRecordOperationCoordinator();
  }
}

enum _RecordSlot { a, b }

class _RecordEnvelope {
  const _RecordEnvelope({
    required this.slot,
    required this.revision,
    required this.record,
  });

  final _RecordSlot slot;
  final int revision;
  final DailyChallengeRecord record;
}

class _DailyRecordOperationCoordinator {
  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(Future<T> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }
}
