import '../domain/geometry.dart';

/// 패턴별 힌트가 실제 기물과 일치하도록 만드는 데이터 계약이다.
///
/// 이 데이터는 UI가 정답 궤적을 그리는 용도가 아니다. [intentTags]와
/// [referencedObjectIds]는 문구를 검증하고 분석할 수 있게 하는 최소 메타데이터다.
class PatternHint {
  const PatternHint({
    required this.level,
    required this.text,
    required this.intentTags,
    required this.referencedObjectIds,
  });

  final int level;
  final String text;
  final Set<String> intentTags;
  final Set<String> referencedObjectIds;

  factory PatternHint.fromJson(Map<String, dynamic> json) => PatternHint(
    level: _requiredInt(json, 'level'),
    text: _requiredString(json, 'text'),
    intentTags: _stringSet(json['intentTags'], 'intentTags'),
    referencedObjectIds: _stringSet(
      json['referencedObjectIds'],
      'referencedObjectIds',
    ),
  );

  Map<String, dynamic> toJson() => {
    'level': level,
    'text': text,
    'intentTags': intentTags.toList()..sort(),
    'referencedObjectIds': referencedObjectIds.toList()..sort(),
  };
}

/// 힌트 접근권을 여는 선택 수집물의 비물리 정의다.
///
/// 물리 엔티티가 아니므로 `GameState`나 `ShotResolver`를 변경하지 않는다.
/// 실제 접촉 판정은 [DeterministicKeyCollectionResolver]가 확정된 샷 결과를
/// 다시 훑어 순수 이벤트로 만들며, UI/VFX는 그 이벤트를 소비한다.
class HintKeyDefinition {
  const HintKeyDefinition({
    required this.id,
    required this.position,
    required this.size,
    required this.version,
  });

  final String id;
  final Vec2 position;
  final Vec2 size;
  final int version;

  factory HintKeyDefinition.fromJson(Map<String, dynamic> json) {
    final position = _requiredMap(json, 'position');
    final size = _requiredMap(json, 'size');
    return HintKeyDefinition(
      id: _requiredString(json, 'id'),
      position: Vec2(_requiredNum(position, 'x'), _requiredNum(position, 'y')),
      size: Vec2(_requiredNum(size, 'x'), _requiredNum(size, 'y')),
      version: _requiredInt(json, 'version'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'position': position.toJson(),
    'size': size.toJson(),
    'version': version,
  };

  Bounds get bounds => Bounds(
    left: position.x - size.x / 2,
    top: position.y - size.y / 2,
    width: size.x,
    height: size.y,
  );
}

/// 데모에서만 직선 성공을 금지하는 정책이다. 일반 셔플 런의 난이도 정책이 아니다.
class DirectClearPolicy {
  const DirectClearPolicy({required this.allowed, this.demoPreferred = false});

  final bool allowed;
  final bool demoPreferred;

  factory DirectClearPolicy.fromJson(Map<String, dynamic> json) =>
      DirectClearPolicy(
        allowed: json['allowed'] == true,
        demoPreferred: json['demoPreferred'] == true,
      );

  Map<String, dynamic> toJson() => {
    'allowed': allowed,
    'demoPreferred': demoPreferred,
  };
}

class PatternHintEntry {
  const PatternHintEntry({
    required this.stageId,
    required this.patternId,
    required this.hintVersion,
    required this.hints,
    required this.intentTags,
    required this.directClearPolicy,
    this.key,
  });

  final String stageId;
  final String patternId;
  final int hintVersion;
  final List<PatternHint> hints;
  final Set<String> intentTags;
  final DirectClearPolicy directClearPolicy;
  final HintKeyDefinition? key;

  factory PatternHintEntry.fromJson(Map<String, dynamic> json) =>
      PatternHintEntry(
        stageId: _requiredString(json, 'stageId'),
        patternId: _requiredString(json, 'patternId'),
        hintVersion: _requiredInt(json, 'hintVersion'),
        hints: _requiredList(json, 'hints', PatternHint.fromJson),
        intentTags: _stringSet(json['intentTags'], 'intentTags'),
        directClearPolicy: DirectClearPolicy.fromJson(
          _requiredMap(json, 'directClearPolicy'),
        ),
        key: json['key'] == null
            ? null
            : HintKeyDefinition.fromJson(_requiredMap(json, 'key')),
      );

  Map<String, dynamic> toJson() => {
    'stageId': stageId,
    'patternId': patternId,
    'hintVersion': hintVersion,
    'hints': hints.map((hint) => hint.toJson()).toList(),
    'intentTags': intentTags.toList()..sort(),
    'directClearPolicy': directClearPolicy.toJson(),
    if (key != null) 'key': key!.toJson(),
  };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) throw FormatException('hint.$key 문자열이 필요합니다.');
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) return value;
  throw FormatException('hint.$key 정수가 필요합니다.');
}

double _requiredNum(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num && value.isFinite) return value.toDouble();
  throw FormatException('hint.$key 유한 수가 필요합니다.');
}

Map<String, dynamic> _requiredMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) throw FormatException('hint.$key 객체가 필요합니다.');
  return Map<String, dynamic>.from(value);
}

List<T> _requiredList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) read,
) {
  final value = json[key];
  if (value is! List) throw FormatException('hint.$key 배열이 필요합니다.');
  return List.unmodifiable(
    value.map((item) {
      if (item is! Map) throw FormatException('hint.$key 항목 객체가 필요합니다.');
      return read(Map<String, dynamic>.from(item));
    }),
  );
}

Set<String> _stringSet(Object? value, String key) {
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('hint.$key 문자열 배열이 필요합니다.');
  }
  return Set.unmodifiable(value.cast<String>());
}
