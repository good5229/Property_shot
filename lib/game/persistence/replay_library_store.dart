import 'dart:convert';

import '../replay/replay_document.dart';
import '../replay/replay_failure.dart';
import 'run_state_store.dart';

const int replayLibrarySchemaVersion = 1;
const int defaultReplayLibraryMaxEntries = 24;
const int replayLibraryMaxEntriesLimit = 64;

/// 목록 화면이 문서 전체를 읽지 않고 표시할 수 있는 최소 리플레이 정보다.
class ReplayLibraryEntry {
  const ReplayLibraryEntry({
    required this.replayId,
    required this.createdAt,
    required this.mode,
    required this.dateKey,
    required this.challengeVersion,
    required this.stageId,
    required this.patternId,
    required this.totalScore,
    required this.shotCount,
  });

  final String replayId;
  final DateTime createdAt;
  final ReplayMode mode;
  final String? dateKey;
  final String? challengeVersion;
  final String stageId;
  final String patternId;
  final int totalScore;
  final int shotCount;
}

class ReplayLibrarySnapshot {
  ReplayLibrarySnapshot({
    required this.revision,
    required Iterable<ReplayLibraryEntry> entries,
    required Iterable<String> bestReplayIds,
  }) : entries = List.unmodifiable(entries),
       bestReplayIds = Set.unmodifiable(bestReplayIds);

  final int revision;
  final List<ReplayLibraryEntry> entries;
  final Set<String> bestReplayIds;

  bool isBest(String replayId) => bestReplayIds.contains(replayId);
}

/// 결정론 리플레이 문서를 제한된 로컬 A/B 라이브러리에 저장한다.
class ReplayLibraryStore {
  ReplayLibraryStore({
    required this.backend,
    this.maxEntries = defaultReplayLibraryMaxEntries,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (maxEntries < 1 || maxEntries > replayLibraryMaxEntriesLimit) {
      throw ArgumentError.value(
        maxEntries,
        'maxEntries',
        '1 이상 $replayLibraryMaxEntriesLimit 이하여야 합니다.',
      );
    }
  }

  static const int envelopeSchemaVersion = 1;
  static const String slotAKey = 'property_shot_replay_library_v1_slot_a';
  static const String slotBKey = 'property_shot_replay_library_v1_slot_b';
  static const String activePointerKey =
      'property_shot_replay_library_v1_active_pointer';
  static final Expando<_ReplayLibraryOperationCoordinator> _coordinators =
      Expando<_ReplayLibraryOperationCoordinator>();

  final RunStateKeyValueBackend backend;
  final int maxEntries;
  final DateTime Function() _now;
  late final _ReplayLibraryOperationCoordinator _coordinator = _coordinatorFor(
    backend,
  );

  Future<ReplayLibrarySnapshot> load() => _enqueue(() async {
    final selected = await _loadCandidate(tolerateReadErrors: true);
    return _snapshot(selected?.revision ?? 0, selected?.records ?? const []);
  });

  Future<ReplayLibraryEntry?> read(String replayId) => _enqueue(() async {
    _validateReplayId(replayId);
    final selected = await _loadCandidate(tolerateReadErrors: true);
    return selected?.records
        .where((record) => record.entry.replayId == replayId)
        .map((record) => record.entry)
        .firstOrNull;
  });

  Future<ReplayDocument?> readDocument(String replayId) => _enqueue(() async {
    _validateReplayId(replayId);
    final selected = await _loadCandidate(tolerateReadErrors: true);
    return selected?.records
        .where((record) => record.entry.replayId == replayId)
        .map((record) => record.document)
        .firstOrNull;
  });

  Future<ReplayLibraryEntry> save({
    required ReplayDocument document,
    required int totalScore,
  }) => _enqueue(() async {
    if (totalScore < 0) {
      throw ArgumentError.value(totalScore, 'totalScore', '음수일 수 없습니다.');
    }
    if (document.recoveredPastBallIds.isNotEmpty) {
      throw const ReplayFailure(ReplayFailureCode.unsupportedBetweenShotState);
    }
    final canonicalDocument = document.toCanonicalJson();
    final replayId = replayLibraryIdForCanonicalDocument(canonicalDocument);
    final selected = await _loadCandidate(tolerateReadErrors: false);
    final records = List<_StoredReplay>.from(selected?.records ?? const []);
    final existing = records
        .where((record) => record.entry.replayId == replayId)
        .firstOrNull;
    if (existing != null) {
      if (existing.entry.totalScore != totalScore) {
        throw StateError('같은 리플레이 문서의 점수 기록이 서로 다릅니다.');
      }
      return existing.entry;
    }

    final createdAt = _now().toUtc();
    final record = _StoredReplay(
      entry: ReplayLibraryEntry(
        replayId: replayId,
        createdAt: createdAt,
        mode: document.mode,
        dateKey: document.dateKey,
        challengeVersion: document.challengeVersion,
        stageId: document.stageId,
        patternId: document.patternId,
        totalScore: totalScore,
        shotCount: document.shots.length,
      ),
      document: document,
      canonicalDocument: canonicalDocument,
    );
    records.add(record);
    _trimToCapacity(records);
    await _saveRecords(records, selected);
    return record.entry;
  });

  Future<bool> delete(String replayId) => _enqueue(() async {
    _validateReplayId(replayId);
    final selected = await _loadCandidate(tolerateReadErrors: false);
    if (selected == null) return false;
    final records = List<_StoredReplay>.from(selected.records);
    final previousLength = records.length;
    records.removeWhere((record) => record.entry.replayId == replayId);
    if (records.length == previousLength) return false;
    await _saveRecords(records, selected);
    return true;
  });

  Future<void> _saveRecords(
    List<_StoredReplay> records,
    _ReplayLibraryCandidate? selected,
  ) async {
    final candidates = await _readCandidates(tolerateReadErrors: false);
    final pointer = await _readPointer(tolerateReadErrors: false);
    final latest = _selectCandidate(candidates, pointer);
    if (latest?.revision != selected?.revision) {
      throw StateError('리플레이 라이브러리가 저장 중 변경되었습니다. 다시 시도해 주세요.');
    }
    final revision = _maxRevision(candidates) + 1;
    final target = latest?.slot == _ReplayLibrarySlot.a
        ? _ReplayLibrarySlot.b
        : _ReplayLibrarySlot.a;
    final sortedRecords = List<_StoredReplay>.from(records)..sort(_newestFirst);
    final payload = replayCanonicalJson({
      'schemaVersion': replayLibrarySchemaVersion,
      'records': sortedRecords.map((record) => record.toJson()).toList(),
    });
    final envelope = jsonEncode({
      'schemaVersion': envelopeSchemaVersion,
      'complete': true,
      'revision': revision,
      'payload': payload,
      'checksum': replayOutcomeFingerprint(payload),
    });
    final targetKey = _keyFor(target);
    await backend.write(targetKey, envelope);
    final verified = await _readCandidate(target, tolerateReadErrors: false);
    if (verified == null ||
        verified.revision != revision ||
        verified.payload != payload) {
      throw StateError('리플레이 라이브러리 후보 슬롯 검증에 실패했습니다.');
    }
    await backend.write(activePointerKey, _pointerFor(target));
  }

  void _trimToCapacity(List<_StoredReplay> records) {
    while (records.length > maxEntries) {
      final bestIds = _bestReplayIds(records);
      final nonBest =
          records
              .where((record) => !bestIds.contains(record.entry.replayId))
              .toList()
            ..sort(_oldestFirst);
      final candidates = nonBest.isNotEmpty
          ? nonBest
          : (List<_StoredReplay>.from(records)..sort(_oldestFirst));
      records.remove(candidates.first);
    }
  }

  ReplayLibrarySnapshot _snapshot(
    int revision,
    Iterable<_StoredReplay> records,
  ) {
    final sorted = records.toList()..sort(_newestFirst);
    return ReplayLibrarySnapshot(
      revision: revision,
      entries: sorted.map((record) => record.entry),
      bestReplayIds: _bestReplayIds(sorted),
    );
  }

  Future<_ReplayLibraryCandidate?> _loadCandidate({
    required bool tolerateReadErrors,
  }) async {
    final candidates = await _readCandidates(
      tolerateReadErrors: tolerateReadErrors,
    );
    final pointer = await _readPointer(tolerateReadErrors: tolerateReadErrors);
    return _selectCandidate(candidates, pointer);
  }

  Future<Map<_ReplayLibrarySlot, _ReplayLibraryCandidate?>> _readCandidates({
    required bool tolerateReadErrors,
  }) async => {
    _ReplayLibrarySlot.a: await _readCandidate(
      _ReplayLibrarySlot.a,
      tolerateReadErrors: tolerateReadErrors,
    ),
    _ReplayLibrarySlot.b: await _readCandidate(
      _ReplayLibrarySlot.b,
      tolerateReadErrors: tolerateReadErrors,
    ),
  };

  Future<_ReplayLibraryCandidate?> _readCandidate(
    _ReplayLibrarySlot slot, {
    required bool tolerateReadErrors,
  }) async {
    final raw = await _readRaw(
      _keyFor(slot),
      tolerateReadErrors: tolerateReadErrors,
    );
    if (raw == null || raw.isEmpty) return null;
    try {
      final envelope = _stringMap(jsonDecode(raw), '리플레이 라이브러리 envelope');
      if (envelope['schemaVersion'] != envelopeSchemaVersion ||
          envelope['complete'] != true ||
          envelope['revision'] is! int ||
          (envelope['revision'] as int) < 1 ||
          envelope['payload'] is! String ||
          envelope['checksum'] is! String) {
        return null;
      }
      final payload = envelope['payload'] as String;
      if (replayOutcomeFingerprint(payload) != envelope['checksum']) {
        return null;
      }
      final payloadMap = _stringMap(jsonDecode(payload), '리플레이 라이브러리 payload');
      if (replayCanonicalJson(payloadMap) != payload ||
          payloadMap.keys.toSet().difference(const {
            'schemaVersion',
            'records',
          }).isNotEmpty ||
          payloadMap['schemaVersion'] != replayLibrarySchemaVersion ||
          payloadMap['records'] is! List) {
        return null;
      }
      final rawRecords = payloadMap['records'] as List;
      if (rawRecords.length > replayLibraryMaxEntriesLimit) return null;
      final records = <_StoredReplay>[
        for (final rawRecord in rawRecords)
          _StoredReplay.fromJson(_stringMap(rawRecord, '리플레이 라이브러리 항목')),
      ];
      if (records.map((record) => record.entry.replayId).toSet().length !=
          records.length) {
        return null;
      }
      return _ReplayLibraryCandidate(
        slot: slot,
        revision: envelope['revision'] as int,
        payload: payload,
        records: List.unmodifiable(records),
      );
    } on Object {
      return null;
    }
  }

  Future<String?> _readRaw(
    String key, {
    required bool tolerateReadErrors,
  }) async {
    if (!tolerateReadErrors) return backend.read(key);
    try {
      return await backend.read(key);
    } on Object {
      return null;
    }
  }

  Future<String?> _readPointer({required bool tolerateReadErrors}) async {
    final value = await _readRaw(
      activePointerKey,
      tolerateReadErrors: tolerateReadErrors,
    );
    return value == 'a' || value == 'b' ? value : null;
  }

  _ReplayLibraryCandidate? _selectCandidate(
    Map<_ReplayLibrarySlot, _ReplayLibraryCandidate?> candidates,
    String? pointer,
  ) {
    final a = candidates[_ReplayLibrarySlot.a];
    final b = candidates[_ReplayLibrarySlot.b];
    if (a == null) return b;
    if (b == null) return a;
    if (a.revision > b.revision) return a;
    if (b.revision > a.revision) return b;
    return pointer == 'b' ? b : a;
  }

  int _maxRevision(
    Map<_ReplayLibrarySlot, _ReplayLibraryCandidate?> candidates,
  ) => candidates.values.fold<int>(
    0,
    (maximum, candidate) => candidate != null && candidate.revision > maximum
        ? candidate.revision
        : maximum,
  );

  Future<T> _enqueue<T>(Future<T> Function() operation) =>
      _coordinator.enqueue(operation);

  static _ReplayLibraryOperationCoordinator _coordinatorFor(
    RunStateKeyValueBackend backend,
  ) {
    final identity = backend is RunStateBackendSynchronizationIdentity
        ? (backend as RunStateBackendSynchronizationIdentity)
              .synchronizationIdentity
        : backend;
    return _coordinators[identity] ??= _ReplayLibraryOperationCoordinator();
  }

  static String _keyFor(_ReplayLibrarySlot slot) =>
      slot == _ReplayLibrarySlot.a ? slotAKey : slotBKey;

  static String _pointerFor(_ReplayLibrarySlot slot) =>
      slot == _ReplayLibrarySlot.a ? 'a' : 'b';
}

String replayLibraryIdForDocument(ReplayDocument document) =>
    replayLibraryIdForCanonicalDocument(document.toCanonicalJson());

String replayLibraryIdForCanonicalDocument(String canonicalDocument) {
  ReplayDocument.fromCanonicalJson(canonicalDocument);
  return 'replay_${replayOutcomeFingerprint(canonicalDocument)}';
}

bool isReplayLibraryId(String value) =>
    RegExp(r'^replay_[0-9a-f]{64}$').hasMatch(value);

class _StoredReplay {
  const _StoredReplay({
    required this.entry,
    required this.document,
    required this.canonicalDocument,
  });

  final ReplayLibraryEntry entry;
  final ReplayDocument document;
  final String canonicalDocument;

  Map<String, Object?> toJson() => {
    'replayId': entry.replayId,
    'createdAt': entry.createdAt.toUtc().toIso8601String(),
    'mode': entry.mode.schemaName,
    'dateKey': entry.dateKey,
    'challengeVersion': entry.challengeVersion,
    'stageId': entry.stageId,
    'patternId': entry.patternId,
    'totalScore': entry.totalScore,
    'shotCount': entry.shotCount,
    'document': canonicalDocument,
  };

  factory _StoredReplay.fromJson(Map<String, dynamic> json) {
    const keys = <String>{
      'replayId',
      'createdAt',
      'mode',
      'dateKey',
      'challengeVersion',
      'stageId',
      'patternId',
      'totalScore',
      'shotCount',
      'document',
    };
    if (json.keys.toSet().difference(keys).isNotEmpty ||
        json.length != keys.length ||
        json['replayId'] is! String ||
        json['createdAt'] is! String ||
        json['mode'] is! String ||
        (json['dateKey'] != null && json['dateKey'] is! String) ||
        (json['challengeVersion'] != null &&
            json['challengeVersion'] is! String) ||
        json['stageId'] is! String ||
        json['patternId'] is! String ||
        json['totalScore'] is! int ||
        json['shotCount'] is! int ||
        json['document'] is! String) {
      throw const FormatException('리플레이 라이브러리 항목 형식이 올바르지 않습니다.');
    }
    final createdAt = DateTime.tryParse(json['createdAt'] as String)?.toUtc();
    final document = ReplayDocument.fromCanonicalJson(
      json['document'] as String,
    );
    final replayId = json['replayId'] as String;
    final totalScore = json['totalScore'] as int;
    final shotCount = json['shotCount'] as int;
    final mode = ReplayMode.fromSchemaName(json['mode'] as String);
    if (createdAt == null ||
        createdAt.toIso8601String() != json['createdAt'] ||
        totalScore < 0 ||
        shotCount != document.shots.length ||
        replayId != replayLibraryIdForDocument(document) ||
        mode != document.mode ||
        json['dateKey'] != document.dateKey ||
        json['challengeVersion'] != document.challengeVersion ||
        json['stageId'] != document.stageId ||
        json['patternId'] != document.patternId ||
        document.recoveredPastBallIds.isNotEmpty) {
      throw const FormatException('리플레이 라이브러리 메타데이터가 문서와 일치하지 않습니다.');
    }
    return _StoredReplay(
      entry: ReplayLibraryEntry(
        replayId: replayId,
        createdAt: createdAt,
        mode: mode,
        dateKey: document.dateKey,
        challengeVersion: document.challengeVersion,
        stageId: document.stageId,
        patternId: document.patternId,
        totalScore: totalScore,
        shotCount: shotCount,
      ),
      document: document,
      canonicalDocument: json['document'] as String,
    );
  }
}

enum _ReplayLibrarySlot { a, b }

class _ReplayLibraryCandidate {
  const _ReplayLibraryCandidate({
    required this.slot,
    required this.revision,
    required this.payload,
    required this.records,
  });

  final _ReplayLibrarySlot slot;
  final int revision;
  final String payload;
  final List<_StoredReplay> records;
}

class _ReplayLibraryOperationCoordinator {
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

Set<String> _bestReplayIds(Iterable<_StoredReplay> records) {
  final bestByGroup = <String, _StoredReplay>{};
  for (final record in records) {
    final entry = record.entry;
    final group = <String?>[
      entry.mode.schemaName,
      entry.dateKey,
      entry.challengeVersion,
      entry.stageId,
      entry.patternId,
    ].map((value) => value ?? '').join('\u0000');
    final current = bestByGroup[group];
    if (current == null || _isBetter(record, current)) {
      bestByGroup[group] = record;
    }
  }
  return {for (final record in bestByGroup.values) record.entry.replayId};
}

bool _isBetter(_StoredReplay candidate, _StoredReplay current) {
  final left = candidate.entry;
  final right = current.entry;
  if (left.totalScore != right.totalScore) {
    return left.totalScore > right.totalScore;
  }
  if (left.shotCount != right.shotCount) {
    return left.shotCount < right.shotCount;
  }
  final dateOrder = left.createdAt.compareTo(right.createdAt);
  if (dateOrder != 0) return dateOrder > 0;
  return left.replayId.compareTo(right.replayId) < 0;
}

int _newestFirst(_StoredReplay left, _StoredReplay right) {
  final dateOrder = right.entry.createdAt.compareTo(left.entry.createdAt);
  return dateOrder != 0
      ? dateOrder
      : left.entry.replayId.compareTo(right.entry.replayId);
}

int _oldestFirst(_StoredReplay left, _StoredReplay right) {
  final dateOrder = left.entry.createdAt.compareTo(right.entry.createdAt);
  return dateOrder != 0
      ? dateOrder
      : left.entry.replayId.compareTo(right.entry.replayId);
}

void _validateReplayId(String replayId) {
  if (!isReplayLibraryId(replayId)) {
    throw ArgumentError.value(replayId, 'replayId', '리플레이 식별자 형식이 올바르지 않습니다.');
  }
}

Map<String, dynamic> _stringMap(Object? value, String label) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$label 형식이 올바르지 않습니다.');
  }
  return Map<String, dynamic>.from(value);
}
