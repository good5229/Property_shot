import 'dart:convert';

import 'entity_state.dart';
import 'geometry.dart';
import 'level_definition.dart';
import 'trait.dart';

/// JSON에 저장하는 EntityType 이름이다.
/// Dart enum의 순서나 이름을 바꾸어도 저장 데이터가 깨지지 않도록 명시한다.
String entityTypeToSchemaName(EntityType type) {
  switch (type) {
    case EntityType.ball:
      return 'ball';
    case EntityType.hole:
      return 'hole';
    case EntityType.wall:
      return 'wall';
    case EntityType.crate:
      return 'crate';
    case EntityType.bumper:
      return 'bumper';
    case EntityType.stickySurface:
      return 'sticky_surface';
    case EntityType.weight:
      return 'weight';
    case EntityType.switchPad:
      return 'switch_pad';
    case EntityType.gate:
      return 'gate';
    case EntityType.balloon:
      return 'balloon';
    case EntityType.spikeSource:
      return 'spike_source';
    case EntityType.powerSlider:
      return 'power_slider';
    case EntityType.rotatingReflector:
      return 'rotating_reflector';
  }
}

EntityType entityTypeFromSchemaName(String value) {
  switch (value) {
    case 'ball':
      return EntityType.ball;
    case 'hole':
      return EntityType.hole;
    case 'wall':
      return EntityType.wall;
    case 'crate':
      return EntityType.crate;
    case 'bumper':
      return EntityType.bumper;
    case 'sticky_surface':
      return EntityType.stickySurface;
    case 'weight':
      return EntityType.weight;
    case 'switch_pad':
      return EntityType.switchPad;
    case 'gate':
      return EntityType.gate;
    case 'balloon':
      return EntityType.balloon;
    case 'spike_source':
      return EntityType.spikeSource;
    case 'power_slider':
      return EntityType.powerSlider;
    case 'rotating_reflector':
      return EntityType.rotatingReflector;
    default:
      throw FormatException('entity type: 알 수 없는 enum 이름 "$value"');
  }
}

/// JSON에 저장하는 TraitType 이름이다.
String traitTypeToSchemaName(TraitType trait) {
  switch (trait) {
    case TraitType.heavy:
      return 'heavy';
    case TraitType.bouncy:
      return 'bouncy';
    case TraitType.sticky:
      return 'sticky';
    case TraitType.sharp:
      return 'sharp';
  }
}

TraitType traitTypeFromSchemaName(String value) {
  switch (value) {
    case 'heavy':
      return TraitType.heavy;
    case 'bouncy':
      return TraitType.bouncy;
    case 'sticky':
      return TraitType.sticky;
    case 'sharp':
      return TraitType.sharp;
    default:
      throw FormatException('trait type: 알 수 없는 enum 이름 "$value"');
  }
}

/// 하나의 패턴을 기존 물리 엔진이 사용하는 LevelDefinition으로 바꾼다.
///
/// 패턴 데이터 로딩과 런타임 선택은 후속 작업의 책임이며, 이 모델은 순수한
/// 변환만 제공한다. 따라서 여기서 seed를 만들거나 패턴을 섞지 않는다.
class StagePattern {
  const StagePattern({
    required this.patternId,
    required this.weight,
    required this.parShots,
    required this.difficultyBand,
    required this.ballSpawn,
    required this.objects,
    this.copyCharges = 0,
    this.bonusGoal = '복사 없이 클리어',
    this.copyCoreReward = 0,
    this.intendedStrategyId,
    this.acceptedStrategyIds = const {},
    this.solutionFamilies = const {},
    this.optionalChallenges = const {},
    this.metadata = const {},
  });

  final String patternId;
  final double weight;
  final int parShots;
  final String difficultyBand;
  final Vec2 ballSpawn;
  final List<PatternObjectDefinition> objects;

  // LevelDefinition의 기존 진행·보상 메타데이터.
  final int copyCharges;
  final String bonusGoal;
  final int copyCoreReward;
  final String? intendedStrategyId;
  final Set<String> acceptedStrategyIds;

  final Set<String> solutionFamilies;
  final Set<String> optionalChallenges;
  final Map<String, String> metadata;

  /// 기존 하드코딩 레벨을 패턴 데이터 경계로 감싸는 보조 변환이다.
  /// 실제 1~4단계 데이터 이전은 호출하는 쪽의 책임이며 여기서 수행하지 않는다.
  factory StagePattern.fromLevelDefinition(
    LevelDefinition level, {
    required String patternId,
    double weight = 1,
    String difficultyBand = 'legacy',
  }) {
    return StagePattern(
      patternId: patternId,
      weight: level.patternWeight == 1 ? weight : level.patternWeight,
      parShots: level.parShots,
      difficultyBand: level.difficultyBand ?? difficultyBand,
      ballSpawn: level.ballSpawn,
      objects: level.entities
          .map(PatternObjectDefinition.fromEntityState)
          .toList(),
      copyCharges: level.copyCharges,
      bonusGoal: level.bonusGoal,
      copyCoreReward: level.copyCoreReward,
      intendedStrategyId: level.intendedStrategyId,
      acceptedStrategyIds: level.acceptedStrategyIds,
      solutionFamilies: level.solutionFamilies,
      optionalChallenges: level.optionalChallenges,
      metadata: level.patternMetadata,
    );
  }

  factory StagePattern.fromJson(Map<String, dynamic> json) {
    final reader = _JsonReader(json, 'pattern');
    return StagePattern(
      patternId: reader.requiredString('patternId'),
      weight: reader.requiredDouble('weight'),
      parShots: reader.requiredInt('parShots'),
      difficultyBand: reader.requiredString('difficultyBand'),
      ballSpawn: reader.requiredVec2('ballSpawn'),
      objects: reader.requiredList('objects', PatternObjectDefinition.fromJson),
      copyCharges: reader.optionalInt('copyCharges', 0),
      bonusGoal: reader.optionalString('bonusGoal', '복사 없이 클리어'),
      copyCoreReward: reader.optionalInt('copyCoreReward', 0),
      intendedStrategyId: reader.optionalNullableString('intendedStrategyId'),
      acceptedStrategyIds: reader.optionalStringSet('acceptedStrategyIds'),
      solutionFamilies: reader.optionalStringSet('solutionFamilies'),
      optionalChallenges: reader.optionalStringSet('optionalChallenges'),
      metadata: reader.optionalStringMap('metadata'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patternId': patternId,
      'weight': weight,
      'parShots': parShots,
      'difficultyBand': difficultyBand,
      'ballSpawn': ballSpawn.toJson(),
      'objects': objects.map((object) => object.toJson()).toList(),
      'copyCharges': copyCharges,
      'bonusGoal': bonusGoal,
      'copyCoreReward': copyCoreReward,
      'intendedStrategyId': intendedStrategyId,
      'acceptedStrategyIds': _sortedStrings(acceptedStrategyIds),
      'solutionFamilies': _sortedStrings(solutionFamilies),
      'optionalChallenges': _sortedStrings(optionalChallenges),
      'metadata': _sortedMap(metadata),
    };
  }

  LevelDefinition toLevelDefinition({
    required String stageId,
    required String stageTitle,
  }) {
    return LevelDefinition(
      id: stageId,
      name: stageTitle,
      ballSpawn: ballSpawn,
      entities: objects.map((object) => object.toEntityState()).toList(),
      copyCharges: copyCharges,
      parShots: parShots,
      bonusGoal: bonusGoal,
      copyCoreReward: copyCoreReward,
      intendedStrategyId: intendedStrategyId,
      acceptedStrategyIds: acceptedStrategyIds,
      stageId: stageId,
      patternId: patternId,
      patternWeight: weight,
      difficultyBand: difficultyBand,
      solutionFamilies: solutionFamilies,
      optionalChallenges: optionalChallenges,
      patternMetadata: metadata,
    );
  }
}

/// 한 스테이지와 그 스테이지에서 사용할 패턴 묶음이다.
class StageDefinition {
  const StageDefinition({
    required this.stageId,
    required this.title,
    required this.patterns,
  });

  final String stageId;
  final String title;
  final List<StagePattern> patterns;

  factory StageDefinition.fromJson(Map<String, dynamic> json) {
    final reader = _JsonReader(json, 'stage');
    return StageDefinition(
      stageId: reader.requiredString('stageId'),
      title: reader.requiredString('title'),
      patterns: reader.requiredList('patterns', StagePattern.fromJson),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'title': title,
      'patterns': patterns.map((pattern) => pattern.toJson()).toList(),
    };
  }

  StagePattern patternById(String patternId) {
    for (final pattern in patterns) {
      if (pattern.patternId == patternId) {
        return pattern;
      }
    }
    throw ArgumentError.value(patternId, 'patternId', '스테이지에 없는 패턴입니다.');
  }

  LevelDefinition levelDefinitionFor(String patternId) {
    return patternById(
      patternId,
    ).toLevelDefinition(stageId: stageId, stageTitle: title);
  }

  List<LevelDefinition> toLevelDefinitions() {
    return patterns
        .map(
          (pattern) =>
              pattern.toLevelDefinition(stageId: stageId, stageTitle: title),
        )
        .toList();
  }
}

/// EntityState의 현재 필드를 모두 보존하는 패턴용 데이터 모델이다.
class PatternObjectDefinition {
  const PatternObjectDefinition({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.traits = const {},
    this.movable = false,
    this.solid = true,
    this.active = true,
    this.open = false,
    this.pressed = false,
    this.visualState = '',
    this.hitboxScale = 0.88,
    this.restitution = 0.72,
    this.linkId,
    this.direction = const Vec2(1, 0),
    this.referenceSpeed = 0,
    this.allowedTargets = const {},
    this.reflectorOrientation = 0,
    this.reflectorRotationCount = 0,
  });

  final String id;
  final EntityType type;
  final Vec2 position;
  final Vec2 size;
  final Set<TraitType> traits;
  final bool movable;
  final bool solid;
  final bool active;
  final bool open;
  final bool pressed;
  final String visualState;
  final double hitboxScale;
  final double restitution;
  final String? linkId;
  final Vec2 direction;
  final double referenceSpeed;
  final Set<EntityType> allowedTargets;
  final int reflectorOrientation;
  final int reflectorRotationCount;

  factory PatternObjectDefinition.fromEntityState(EntityState entity) {
    return PatternObjectDefinition(
      id: entity.id,
      type: entity.type,
      position: entity.position,
      size: entity.size,
      traits: entity.traits,
      movable: entity.movable,
      solid: entity.solid,
      active: entity.active,
      open: entity.open,
      pressed: entity.pressed,
      visualState: entity.visualState,
      hitboxScale: entity.hitboxScale,
      restitution: entity.restitution,
      linkId: entity.linkId,
      direction: entity.direction,
      referenceSpeed: entity.referenceSpeed,
      allowedTargets: Set.unmodifiable(entity.allowedTargets),
      reflectorOrientation: entity.reflectorOrientation,
      reflectorRotationCount: entity.reflectorRotationCount,
    );
  }

  factory PatternObjectDefinition.fromJson(Map<String, dynamic> json) {
    final reader = _JsonReader(json, 'object');
    return PatternObjectDefinition(
      id: reader.requiredString('id'),
      type: entityTypeFromSchemaName(reader.requiredString('type')),
      position: reader.requiredVec2('position'),
      size: reader.requiredVec2('size'),
      traits: reader
          .optionalStringSet('traits')
          .map(traitTypeFromSchemaName)
          .toSet(),
      movable: reader.optionalBool('movable', false),
      solid: reader.optionalBool('solid', true),
      active: reader.optionalBool('active', true),
      open: reader.optionalBool('open', false),
      pressed: reader.optionalBool('pressed', false),
      visualState: reader.optionalString('visualState', ''),
      hitboxScale: reader.optionalDouble('hitboxScale', 0.88),
      restitution: reader.optionalDouble('restitution', 0.72),
      linkId: reader.optionalNullableString('linkId'),
      direction: reader.optionalVec2('direction', const Vec2(1, 0)),
      referenceSpeed: reader.optionalDouble('referenceSpeed', 0),
      allowedTargets: Set.unmodifiable(
        reader
            .optionalStringSet('allowedTargets')
            .map(entityTypeFromSchemaName),
      ),
      reflectorOrientation: reader.optionalInt('reflectorOrientation', 0),
      reflectorRotationCount: reader.optionalInt('reflectorRotationCount', 0),
    );
  }

  EntityState toEntityState() {
    return EntityState(
      id: id,
      type: type,
      position: position,
      size: size,
      traits: traits,
      movable: movable,
      solid: solid,
      active: active,
      open: open,
      pressed: pressed,
      visualState: visualState,
      hitboxScale: hitboxScale,
      restitution: restitution,
      linkId: linkId,
      direction: direction,
      referenceSpeed: referenceSpeed,
      allowedTargets: Set.unmodifiable(allowedTargets),
      reflectorOrientation: reflectorOrientation,
      reflectorRotationCount: reflectorRotationCount,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'type': entityTypeToSchemaName(type),
      'position': position.toJson(),
      'size': size.toJson(),
      'traits': _sortedStrings(traits.map(traitTypeToSchemaName)),
      'movable': movable,
      'solid': solid,
      'active': active,
      'open': open,
      'pressed': pressed,
      'visualState': visualState,
      'hitboxScale': hitboxScale,
      'restitution': restitution,
      'linkId': linkId,
    };
    if (type == EntityType.powerSlider) {
      json['direction'] = direction.toJson();
      json['referenceSpeed'] = referenceSpeed;
      json['allowedTargets'] = _sortedEntityTypeNames(allowedTargets);
    }
    if (type == EntityType.rotatingReflector) {
      json['reflectorOrientation'] = reflectorOrientation;
      json['reflectorRotationCount'] = reflectorRotationCount;
    }
    return json;
  }
}

String stageDefinitionToJson(StageDefinition stage) =>
    jsonEncode(stage.toJson());

StageDefinition stageDefinitionFromJson(String value) {
  final decoded = jsonDecode(value);
  final map = _mapValue(decoded, 'stage JSON');
  return StageDefinition.fromJson(map);
}

List<String> _sortedStrings(Iterable<String> values) {
  final result = values.toList()..sort();
  return result;
}

List<String> _sortedEntityTypeNames(Iterable<EntityType> values) {
  final selected = values.toSet();
  return [
    for (final type in _stableEntityTypeOrder)
      if (selected.contains(type)) entityTypeToSchemaName(type),
  ];
}

const _stableEntityTypeOrder = <EntityType>[
  EntityType.ball,
  EntityType.hole,
  EntityType.wall,
  EntityType.crate,
  EntityType.bumper,
  EntityType.stickySurface,
  EntityType.weight,
  EntityType.switchPad,
  EntityType.gate,
  EntityType.balloon,
  EntityType.spikeSource,
  EntityType.powerSlider,
  EntityType.rotatingReflector,
];

Map<String, String> _sortedMap(Map<String, String> values) {
  final keys = values.keys.toList()..sort();
  return {for (final key in keys) key: values[key]!};
}

Map<String, dynamic> _mapValue(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path: Map이어야 합니다.');
  }
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path: 모든 키는 문자열이어야 합니다.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

class _JsonReader {
  _JsonReader(this.json, this.path);

  final Map<String, dynamic> json;
  final String path;

  dynamic _required(String key) {
    if (!json.containsKey(key) || json[key] == null) {
      throw FormatException('$path.$key: 필수 필드입니다.');
    }
    return json[key];
  }

  String requiredString(String key) {
    final value = _required(key);
    if (value is! String || value.isEmpty) {
      throw FormatException('$path.$key: 비어 있지 않은 문자열이어야 합니다.');
    }
    return value;
  }

  String optionalString(String key, String fallback) {
    if (!json.containsKey(key) || json[key] == null) {
      return fallback;
    }
    final value = json[key];
    if (value is! String) {
      throw FormatException('$path.$key: 문자열이어야 합니다.');
    }
    return value;
  }

  String? optionalNullableString(String key) {
    if (!json.containsKey(key) || json[key] == null) {
      return null;
    }
    final value = json[key];
    if (value is! String) {
      throw FormatException('$path.$key: 문자열 또는 null이어야 합니다.');
    }
    return value;
  }

  int requiredInt(String key) {
    final value = _required(key);
    return _asInt(value, '$path.$key');
  }

  int optionalInt(String key, int fallback) {
    if (!json.containsKey(key) || json[key] == null) {
      return fallback;
    }
    return _asInt(json[key], '$path.$key');
  }

  double requiredDouble(String key) {
    final value = _required(key);
    return _asDouble(value, '$path.$key');
  }

  double optionalDouble(String key, double fallback) {
    if (!json.containsKey(key) || json[key] == null) {
      return fallback;
    }
    return _asDouble(json[key], '$path.$key');
  }

  bool optionalBool(String key, bool fallback) {
    if (!json.containsKey(key) || json[key] == null) {
      return fallback;
    }
    final value = json[key];
    if (value is! bool) {
      throw FormatException('$path.$key: 불리언이어야 합니다.');
    }
    return value;
  }

  Vec2 requiredVec2(String key) {
    final map = _mapValue(_required(key), '$path.$key');
    final reader = _JsonReader(map, '$path.$key');
    return Vec2(reader.requiredDouble('x'), reader.requiredDouble('y'));
  }

  Vec2 optionalVec2(String key, Vec2 fallback) {
    if (!json.containsKey(key) || json[key] == null) {
      return fallback;
    }
    final map = _mapValue(json[key], '$path.$key');
    final reader = _JsonReader(map, '$path.$key');
    return Vec2(reader.requiredDouble('x'), reader.requiredDouble('y'));
  }

  List<T> requiredList<T>(String key, T Function(Map<String, dynamic>) decode) {
    final value = _required(key);
    if (value is! List) {
      throw FormatException('$path.$key: 배열이어야 합니다.');
    }
    return [
      for (var index = 0; index < value.length; index++)
        decode(_mapValue(value[index], '$path.$key[$index]')),
    ];
  }

  Set<String> optionalStringSet(String key) {
    if (!json.containsKey(key) || json[key] == null) {
      return const {};
    }
    final value = json[key];
    if (value is! List) {
      throw FormatException('$path.$key: 문자열 배열이어야 합니다.');
    }
    final result = <String>{};
    for (var index = 0; index < value.length; index++) {
      final item = value[index];
      if (item is! String || item.isEmpty) {
        throw FormatException('$path.$key[$index]: 비어 있지 않은 문자열이어야 합니다.');
      }
      result.add(item);
    }
    return result;
  }

  Map<String, String> optionalStringMap(String key) {
    if (!json.containsKey(key) || json[key] == null) {
      return const {};
    }
    final value = _mapValue(json[key], '$path.$key');
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.value is! String) {
        throw FormatException('$path.$key.${entry.key}: 문자열이어야 합니다.');
      }
      result[entry.key] = entry.value as String;
    }
    return result;
  }
}

int _asInt(Object? value, String path) {
  if (value is int) {
    return value;
  }
  if (value is num && value.isFinite && value == value.roundToDouble()) {
    return value.toInt();
  }
  throw FormatException('$path: 정수여야 합니다.');
}

double _asDouble(Object? value, String path) {
  if (value is num && value.isFinite) {
    return value.toDouble();
  }
  throw FormatException('$path: 유한한 숫자여야 합니다.');
}
