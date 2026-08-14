import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum ExpeditionContractType { discovery, precision, chain }

extension ExpeditionContractTypeCopy on ExpeditionContractType {
  String get title => switch (this) {
    ExpeditionContractType.discovery => '발견 탐사',
    ExpeditionContractType.precision => '정밀 탐사',
    ExpeditionContractType.chain => '연쇄 탐사',
  };

  String get summary => switch (this) {
    ExpeditionContractType.discovery => '각 단계에서 물리 발견 2개 이상 기록',
    ExpeditionContractType.precision => '각 단계를 파 횟수 안에 클리어',
    ExpeditionContractType.chain => '각 단계에서 속성·기믹 사건 3종 이상 연결',
  };

  String get iconName => switch (this) {
    ExpeditionContractType.discovery => 'discovery',
    ExpeditionContractType.precision => 'precision',
    ExpeditionContractType.chain => 'chain',
  };
}

class ExpeditionStageOutcome {
  const ExpeditionStageOutcome({
    required this.stageId,
    required this.shotCount,
    required this.parShots,
    required this.discoveryCount,
    required this.gimmickCount,
    required this.chainScore,
  });

  final String stageId;
  final int shotCount;
  final int parShots;
  final int discoveryCount;
  final int gimmickCount;
  final int chainScore;
}

class ExpeditionContractProgress {
  ExpeditionContractProgress({
    required this.id,
    required this.type,
    required Iterable<String> stageIds,
    Iterable<String> completedStageIds = const [],
    Iterable<String> achievedStageIds = const [],
  }) : stageIds = List.unmodifiable(stageIds),
       completedStageIds = Set.unmodifiable(completedStageIds),
       achievedStageIds = Set.unmodifiable(achievedStageIds) {
    if (id.trim().isEmpty || this.stageIds.length != 3) {
      throw ArgumentError('탐사 계약은 ID와 정확히 3개의 단계가 필요합니다.');
    }
    if (this.stageIds.toSet().length != 3) {
      throw ArgumentError('탐사 단계는 중복될 수 없습니다.');
    }
    if (!this.stageIds.toSet().containsAll(this.completedStageIds) ||
        !this.completedStageIds.containsAll(this.achievedStageIds)) {
      throw ArgumentError('탐사 결과는 계약 단계의 하위 집합이어야 합니다.');
    }
  }

  final String id;
  final ExpeditionContractType type;
  final List<String> stageIds;
  final Set<String> completedStageIds;
  final Set<String> achievedStageIds;

  int get completedCount => completedStageIds.length;
  int get achievedCount => achievedStageIds.length;
  bool get isComplete => completedCount == stageIds.length;
  String? get nextStageId => stageIds
      .where((stageId) => !completedStageIds.contains(stageId))
      .firstOrNull;

  bool goalAchieved(ExpeditionStageOutcome outcome) => switch (type) {
    ExpeditionContractType.discovery => outcome.discoveryCount >= 2,
    ExpeditionContractType.precision => outcome.shotCount <= outcome.parShots,
    ExpeditionContractType.chain => outcome.gimmickCount >= 3,
  };

  ExpeditionContractProgress record(ExpeditionStageOutcome outcome) {
    if (!stageIds.contains(outcome.stageId)) return this;
    return ExpeditionContractProgress(
      id: id,
      type: type,
      stageIds: stageIds,
      completedStageIds: {...completedStageIds, outcome.stageId},
      achievedStageIds: {
        ...achievedStageIds,
        if (goalAchieved(outcome)) outcome.stageId,
      },
    );
  }

  Map<String, Object> toJson() => {
    'version': 1,
    'id': id,
    'type': type.name,
    'stageIds': stageIds,
    'completedStageIds': completedStageIds.toList()..sort(),
    'achievedStageIds': achievedStageIds.toList()..sort(),
  };

  factory ExpeditionContractProgress.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('지원하지 않는 탐사 버전');
    final rawStages = json['stageIds'];
    final rawCompleted = json['completedStageIds'];
    final rawAchieved = json['achievedStageIds'];
    if (rawStages is! List || rawCompleted is! List || rawAchieved is! List) {
      throw const FormatException('탐사 단계 데이터가 올바르지 않습니다.');
    }
    return ExpeditionContractProgress(
      id: json['id'] as String,
      type: ExpeditionContractType.values.byName(json['type'] as String),
      stageIds: rawStages.cast<String>(),
      completedStageIds: rawCompleted.cast<String>(),
      achievedStageIds: rawAchieved.cast<String>(),
    );
  }
}

/// 서버 없이 같은 목표와 같은 세 단계를 전달하는 짧은 탐사 코드다.
/// 진행도는 공유하지 않아 받는 사람은 처음부터 직접 탐사한다.
class ExpeditionShareCodec {
  const ExpeditionShareCodec._();

  static const String prefix = 'PSX1-';

  static String encode(ExpeditionContractProgress progress) {
    final payload = jsonEncode({
      'type': progress.type.name,
      'stageIds': progress.stageIds,
    });
    final bytes = utf8.encode(payload);
    final body = base64Url.encode(bytes).replaceAll('=', '');
    return '$prefix$body-${_checksum(bytes).toRadixString(16).padLeft(8, '0')}';
  }

  static ExpeditionContractProgress decode(String value) {
    final normalized = value.trim();
    if (!normalized.startsWith(prefix)) {
      throw const FormatException('속성 한방 탐사 코드가 아닙니다.');
    }
    final encoded = normalized.substring(prefix.length);
    final separator = encoded.lastIndexOf('-');
    if (separator <= 0 || separator == encoded.length - 1) {
      throw const FormatException('탐사 코드 형식이 올바르지 않습니다.');
    }
    final body = encoded.substring(0, separator);
    final checksum = int.tryParse(encoded.substring(separator + 1), radix: 16);
    try {
      final padded = body.padRight((body.length + 3) ~/ 4 * 4, '=');
      final bytes = base64Url.decode(padded);
      if (checksum == null || checksum != _checksum(bytes)) {
        throw const FormatException('탐사 코드가 손상되었습니다.');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> || decoded['stageIds'] is! List) {
        throw const FormatException('탐사 코드 내용이 올바르지 않습니다.');
      }
      final type = ExpeditionContractType.values.byName(
        decoded['type'] as String,
      );
      final stageIds = (decoded['stageIds'] as List).cast<String>();
      return ExpeditionContractProgress(
        id: 'expedition:${type.name}:shared:v1',
        type: type,
        stageIds: stageIds,
      );
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('탐사 코드를 읽을 수 없습니다.');
    }
  }

  static int _checksum(List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}

class ExpeditionContractStore {
  ExpeditionContractStore(this._preferences);

  static const storageKey = 'property_shot_expedition_contract_v1';
  final SharedPreferences _preferences;
  Future<void> _writeTail = Future<void>.value();

  Future<ExpeditionContractProgress?> load() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return ExpeditionContractProgress.fromJson(decoded);
    } on Object {
      await _preferences.remove(storageKey);
      return null;
    }
  }

  Future<ExpeditionContractProgress> start({
    required ExpeditionContractType type,
    required int startIndex,
    required List<String> allStageIds,
  }) async {
    if (allStageIds.length < 3) throw ArgumentError('탐사에는 3개 이상 단계가 필요합니다.');
    final normalized = startIndex.clamp(0, allStageIds.length - 3);
    final stages = allStageIds.sublist(normalized, normalized + 3);
    final progress = ExpeditionContractProgress(
      id: 'expedition:${type.name}:$normalized:v1',
      type: type,
      stageIds: stages,
    );
    await _save(progress);
    return progress;
  }

  Future<ExpeditionContractProgress> importCode(
    String code, {
    required Set<String> knownStageIds,
  }) async {
    final progress = ExpeditionShareCodec.decode(code);
    if (!knownStageIds.containsAll(progress.stageIds)) {
      throw const FormatException('현재 버전에 없는 스테이지가 포함되어 있습니다.');
    }
    await _save(progress);
    return progress;
  }

  Future<ExpeditionContractProgress?> record(
    ExpeditionStageOutcome outcome,
  ) async {
    ExpeditionContractProgress? updated;
    await _enqueue(() async {
      final current = await load();
      if (current == null) return;
      updated = current.record(outcome);
      await _preferences.setString(storageKey, jsonEncode(updated!.toJson()));
    });
    return updated;
  }

  Future<void> clear() => _enqueue(() async {
    await _preferences.remove(storageKey);
  });

  Future<void> _save(ExpeditionContractProgress progress) => _enqueue(() async {
    await _preferences.setString(storageKey, jsonEncode(progress.toJson()));
  });

  Future<void> _enqueue(Future<void> Function() action) async {
    final next = _writeTail.then((_) => action());
    _writeTail = next;
    await next;
  }
}
