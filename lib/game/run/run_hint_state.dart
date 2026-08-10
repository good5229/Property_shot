/// 런 진행과 분리해 힌트 접근권과 열쇠 획득을 직렬화하는 순수 모델이다.
///
/// HintCatalog의 문구 자체는 저장하지 않는다. 저장된 identity가 항상
/// `stageId + patternId + hintVersion`을 가리키므로 패턴 추첨이 복원돼도
/// 다른 배치의 힌트를 보여 주지 않는다.
const int currentHintVersion = 1;

enum HintEntitlementSource {
  clearReward('clear_reward'),
  stageKey('stage_key');

  const HintEntitlementSource(this.schemaName);

  final String schemaName;

  static HintEntitlementSource fromSchemaName(String value) {
    for (final source in values) {
      if (source.schemaName == value) return source;
    }
    throw FormatException('hint entitlement: 알 수 없는 source입니다: $value');
  }
}

class HintIdentity {
  HintIdentity({
    required this.stageId,
    required this.patternId,
    required this.hintVersion,
  }) {
    _requireId(stageId, 'stageId');
    _requireId(patternId, 'patternId');
    if (hintVersion < 1) {
      throw ArgumentError.value(hintVersion, 'hintVersion', '1 이상이어야 합니다.');
    }
  }

  final String stageId;
  final String patternId;
  final int hintVersion;

  String get storageKey => '$stageId\u0000$patternId\u0000$hintVersion';

  factory HintIdentity.fromJson(
    Map<String, dynamic> json, {
    String path = 'hint identity',
  }) {
    return HintIdentity(
      stageId: _requiredString(json, 'stageId', path),
      patternId: _requiredString(json, 'patternId', path),
      hintVersion: _requiredPositiveInt(json, 'hintVersion', path),
    );
  }

  Map<String, dynamic> toJson() => {
    'stageId': stageId,
    'patternId': patternId,
    'hintVersion': hintVersion,
  };
}

class RunHintEntitlement {
  RunHintEntitlement({
    required this.identity,
    required Iterable<HintEntitlementSource> sources,
    this.unlockedHintLevel = 1,
    this.consumed = false,
    this.openedCount = 0,
    this.failedShotCount = 0,
    this.failureCountAtFirstOpen,
    required this.acquiredAt,
  }) : sources = Set.unmodifiable(sources) {
    if (this.sources.isEmpty) {
      throw ArgumentError.value(sources, 'sources', '하나 이상의 획득 원인이 필요합니다.');
    }
    if (unlockedHintLevel < 1 || unlockedHintLevel > 2) {
      throw ArgumentError.value(
        unlockedHintLevel,
        'unlockedHintLevel',
        '현재 HintCatalog 계약의 1~2단계여야 합니다.',
      );
    }
    if (openedCount < 0 ||
        failedShotCount < 0 ||
        (failureCountAtFirstOpen != null && failureCountAtFirstOpen! < 0)) {
      throw ArgumentError('열람·실패 횟수는 음수일 수 없습니다.');
    }
    if ((!consumed && openedCount != 0) || (consumed && openedCount == 0)) {
      throw ArgumentError('힌트 열람 여부와 열람 횟수가 일치해야 합니다.');
    }
    if (!consumed && failureCountAtFirstOpen != null) {
      throw ArgumentError('열지 않은 힌트에는 첫 열람 실패 기준선이 있을 수 없습니다.');
    }
    if (failureCountAtFirstOpen != null &&
        failureCountAtFirstOpen! > failedShotCount) {
      throw ArgumentError('첫 열람 실패 기준선은 누적 실패 횟수를 넘을 수 없습니다.');
    }
    if (!acquiredAt.isUtc) {
      throw ArgumentError.value(acquiredAt, 'acquiredAt', 'UTC여야 합니다.');
    }
  }

  final HintIdentity identity;
  final Set<HintEntitlementSource> sources;
  final int unlockedHintLevel;

  /// 첫 열람 여부다. 힌트 접근권을 소모했다는 의미는 아니다.
  final bool consumed;
  final int openedCount;
  final int failedShotCount;

  /// 첫 힌트를 열기 직전까지 쌓인 실패 수다. 힌트 전/후 난이도 분석은
  /// 현재 누적값이 아니라 이 durable baseline을 기준으로 나눈다.
  final int? failureCountAtFirstOpen;
  final DateTime acquiredAt;

  RunHintEntitlement copyWith({
    Iterable<HintEntitlementSource>? sources,
    int? unlockedHintLevel,
    bool? consumed,
    int? openedCount,
    int? failedShotCount,
    int? failureCountAtFirstOpen,
  }) => RunHintEntitlement(
    identity: identity,
    sources: sources ?? this.sources,
    unlockedHintLevel: unlockedHintLevel ?? this.unlockedHintLevel,
    consumed: consumed ?? this.consumed,
    openedCount: openedCount ?? this.openedCount,
    failedShotCount: failedShotCount ?? this.failedShotCount,
    failureCountAtFirstOpen:
        failureCountAtFirstOpen ?? this.failureCountAtFirstOpen,
    acquiredAt: acquiredAt,
  );

  factory RunHintEntitlement.fromJson(Map<String, dynamic> json) {
    final sources = _requiredList(
      json,
      'sources',
      'hint entitlement',
    ).map((value) => HintEntitlementSource.fromSchemaName(value));
    return RunHintEntitlement(
      identity: HintIdentity.fromJson(
        _requiredMap(json, 'identity', 'hint entitlement'),
        path: 'hint entitlement.identity',
      ),
      sources: sources,
      unlockedHintLevel: _requiredPositiveInt(
        json,
        'unlockedHintLevel',
        'hint entitlement',
      ),
      consumed: _requiredBool(json, 'consumed', 'hint entitlement'),
      openedCount: _requiredNonNegativeInt(
        json,
        'openedCount',
        'hint entitlement',
      ),
      failedShotCount: _requiredNonNegativeInt(
        json,
        'failedShotCount',
        'hint entitlement',
      ),
      failureCountAtFirstOpen: _optionalNonNegativeInt(
        json,
        'failureCountAtFirstOpen',
        'hint entitlement',
      ),
      acquiredAt: _requiredUtcDateTime(json, 'acquiredAt', 'hint entitlement'),
    );
  }

  Map<String, dynamic> toJson() => {
    'identity': identity.toJson(),
    'sources': (sources.map((source) => source.schemaName).toList()..sort()),
    'unlockedHintLevel': unlockedHintLevel,
    'consumed': consumed,
    'openedCount': openedCount,
    'failedShotCount': failedShotCount,
    if (failureCountAtFirstOpen != null)
      'failureCountAtFirstOpen': failureCountAtFirstOpen,
    'acquiredAt': acquiredAt.toUtc().toIso8601String(),
  };
}

int? _optionalNonNegativeInt(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  if (!json.containsKey(key) || json[key] == null) return null;
  return _requiredNonNegativeInt(json, key, path);
}

class KeyCollectionRecord {
  KeyCollectionRecord({
    required this.identity,
    required this.keyId,
    required this.sourceBallId,
    required this.shotIndex,
    required this.acquiredAt,
  }) {
    _requireId(keyId, 'keyId');
    _requireId(sourceBallId, 'sourceBallId');
    if (shotIndex < 0) {
      throw ArgumentError.value(shotIndex, 'shotIndex', '음수일 수 없습니다.');
    }
    if (!acquiredAt.isUtc) {
      throw ArgumentError.value(acquiredAt, 'acquiredAt', 'UTC여야 합니다.');
    }
  }

  final HintIdentity identity;
  final String keyId;
  final String sourceBallId;
  final int shotIndex;
  final DateTime acquiredAt;

  String get storageKey => '${identity.storageKey}\u0000$keyId';

  factory KeyCollectionRecord.fromJson(Map<String, dynamic> json) =>
      KeyCollectionRecord(
        identity: HintIdentity.fromJson(
          _requiredMap(json, 'identity', 'key collection'),
          path: 'key collection.identity',
        ),
        keyId: _requiredString(json, 'keyId', 'key collection'),
        sourceBallId: _requiredString(json, 'sourceBallId', 'key collection'),
        shotIndex: _requiredNonNegativeInt(json, 'shotIndex', 'key collection'),
        acquiredAt: _requiredUtcDateTime(json, 'acquiredAt', 'key collection'),
      );

  Map<String, dynamic> toJson() => {
    'identity': identity.toJson(),
    'keyId': keyId,
    'sourceBallId': sourceBallId,
    'shotIndex': shotIndex,
    'acquiredAt': acquiredAt.toUtc().toIso8601String(),
  };
}

void _requireId(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '비어 있을 수 없습니다.');
  }
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = json[key];
  if (value is! Map) throw FormatException('$path.$key가 Map이 아닙니다.');
  return Map<String, dynamic>.from(value);
}

String _requiredString(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$path.$key가 비어 있거나 문자열이 아닙니다.');
  }
  return value;
}

List<String> _requiredList(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! List || value.any((entry) => entry is! String)) {
    throw FormatException('$path.$key가 문자열 배열이 아닙니다.');
  }
  return List<String>.from(value);
}

int _requiredNonNegativeInt(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = json[key];
  if (value is! int || value < 0) {
    throw FormatException('$path.$key가 음수가 아닌 정수가 아닙니다.');
  }
  return value;
}

int _requiredPositiveInt(Map<String, dynamic> json, String key, String path) {
  final value = _requiredNonNegativeInt(json, key, path);
  if (value < 1) throw FormatException('$path.$key가 1 이상이 아닙니다.');
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String key, String path) {
  final value = json[key];
  if (value is! bool) throw FormatException('$path.$key가 bool이 아닙니다.');
  return value;
}

DateTime _requiredUtcDateTime(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = _requiredString(json, key, path);
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('$path.$key가 UTC ISO-8601 날짜가 아닙니다.');
  }
  return parsed;
}
