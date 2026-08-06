import 'dart:convert';

import 'geometry.dart';
import 'level_definition.dart';
import 'stage_pattern.dart';

/// 버전이 있는 스테이지 원본 카탈로그다.
///
/// JSON은 스테이지 배치의 기준 데이터이고, 생성 Dart 파일은 동기식
/// 실행 호환을 위한 스냅샷이다. 이 모델에는 패턴 추첨을 넣지 않는다.
class StageCatalog {
  StageCatalog({
    required this.schemaVersion,
    required List<StageDefinition> stages,
  }) : stages = List.unmodifiable(stages);

  static const baselineMetadataKey = 'baseline';
  static const baselineMetadataValue = 'true';

  final int schemaVersion;
  final List<StageDefinition> stages;

  factory StageCatalog.fromJson(Map<String, dynamic> json) {
    final reader = _CatalogJsonReader(json);
    return StageCatalog(
      schemaVersion: reader.requiredInt('schemaVersion'),
      stages: reader.requiredList('stages', StageDefinition.fromJson),
    );
  }

  factory StageCatalog.fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('stage catalog JSON: Map이어야 합니다.');
    }
    final json = <String, dynamic>{};
    for (final entry in decoded.entries) {
      if (entry.key is! String) {
        throw const FormatException('stage catalog JSON: 모든 키는 문자열이어야 합니다.');
      }
      json[entry.key as String] = entry.value;
    }
    return StageCatalog.fromJson(json);
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'stages': stages.map((stage) => stage.toJson()).toList(),
  };

  String toJsonString() => jsonEncode(toJson());

  StageDefinition stageById(String stageId) {
    for (final stage in stages) {
      if (stage.stageId == stageId) {
        return stage;
      }
    }
    throw ArgumentError.value(stageId, 'stageId', '카탈로그에 없는 스테이지입니다.');
  }

  StagePattern baselinePatternFor(StageDefinition stage) {
    final matches = stage.patterns
        .where(
          (pattern) =>
              pattern.metadata[baselineMetadataKey] == baselineMetadataValue,
        )
        .toList(growable: false);
    if (matches.length != 1) {
      throw StateError(
        '스테이지 "${stage.stageId}"의 기준 패턴은 metadata.'
        '$baselineMetadataKey=$baselineMetadataValue로 정확히 하나여야 합니다. '
        '현재 ${matches.length}개입니다.',
      );
    }
    return matches.single;
  }

  LevelDefinition baselineLevelDefinitionFor(StageDefinition stage) {
    return baselinePatternFor(
      stage,
    ).toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title);
  }

  List<LevelDefinition> baselineLevels() {
    return List.unmodifiable(stages.map(baselineLevelDefinitionFor));
  }

  /// 생성 전에 발견해야 하는 카탈로그 자체의 구조 오류를 한글로 반환한다.
  /// 패턴 수가 한 개인 기존 기준 카탈로그도 허용한다. 3~4 패턴 정책은
  /// 후속 패턴 제작 단계에서 StagePatternValidator가 담당한다.
  List<String> validate({int supportedSchemaVersion = 1}) {
    final issues = <String>[];
    if (schemaVersion != supportedSchemaVersion) {
      issues.add(
        'schemaVersion $schemaVersion 을 지원하지 않습니다. '
        '지원 버전은 $supportedSchemaVersion 입니다.',
      );
    }
    if (stages.isEmpty) {
      issues.add('stages는 하나 이상의 스테이지를 가져야 합니다.');
    }

    final stageIds = <String>{};
    for (var stageIndex = 0; stageIndex < stages.length; stageIndex++) {
      final stage = stages[stageIndex];
      final path = 'stages[$stageIndex]';
      if (stage.stageId.trim().isEmpty) {
        issues.add('$path.stageId가 비어 있습니다.');
      } else if (!stageIds.add(stage.stageId)) {
        issues.add('$path.stageId "${stage.stageId}"가 중복됩니다.');
      }
      if (stage.title.trim().isEmpty) {
        issues.add('$path.title이 비어 있습니다.');
      }
      if (stage.patterns.isEmpty) {
        issues.add('$path.patterns는 하나 이상의 패턴을 가져야 합니다.');
      }

      final baselineCount = stage.patterns
          .where(
            (pattern) =>
                pattern.metadata[baselineMetadataKey] == baselineMetadataValue,
          )
          .length;
      if (baselineCount != 1) {
        issues.add(
          '$path의 기준 패턴은 metadata.$baselineMetadataKey='
          '$baselineMetadataValue로 정확히 하나여야 합니다. '
          '현재 $baselineCount개입니다.',
        );
      }

      final patternIds = <String>{};
      for (
        var patternIndex = 0;
        patternIndex < stage.patterns.length;
        patternIndex++
      ) {
        final pattern = stage.patterns[patternIndex];
        final patternPath = '$path.patterns[$patternIndex]';
        if (pattern.patternId.trim().isEmpty) {
          issues.add('$patternPath.patternId가 비어 있습니다.');
        } else if (!patternIds.add(pattern.patternId)) {
          issues.add(
            '$patternPath.patternId '
            '"${pattern.patternId}"가 중복됩니다.',
          );
        }
        if (pattern.difficultyBand.trim().isEmpty) {
          issues.add('$patternPath.difficultyBand가 비어 있습니다.');
        }
        if (!pattern.weight.isFinite || pattern.weight <= 0) {
          issues.add('$patternPath.weight는 0보다 큰 유한 수여야 합니다.');
        }
        if (pattern.parShots <= 0) {
          issues.add('$patternPath.parShots는 1 이상이어야 합니다.');
        }
        if (pattern.copyCharges < 0) {
          issues.add('$patternPath.copyCharges는 0 이상이어야 합니다.');
        }
        if (pattern.copyCoreReward < 0) {
          issues.add('$patternPath.copyCoreReward는 0 이상이어야 합니다.');
        }
        if (pattern.bonusGoal.trim().isEmpty) {
          issues.add('$patternPath.bonusGoal이 비어 있습니다.');
        }
        if (!_isFiniteVec2(pattern.ballSpawn)) {
          issues.add('$patternPath.ballSpawn은 유한한 좌표여야 합니다.');
        }

        final objectIds = <String>{};
        for (
          var objectIndex = 0;
          objectIndex < pattern.objects.length;
          objectIndex++
        ) {
          final object = pattern.objects[objectIndex];
          final objectPath = '$patternPath.objects[$objectIndex]';
          if (object.id.trim().isEmpty) {
            issues.add('$objectPath.id가 비어 있습니다.');
          } else if (!objectIds.add(object.id)) {
            issues.add('$objectPath.id "${object.id}"가 중복됩니다.');
          }
          if (!_isFiniteVec2(object.position)) {
            issues.add('$objectPath.position은 유한한 좌표여야 합니다.');
          }
          if (!_isFiniteVec2(object.size) ||
              object.size.x <= 0 ||
              object.size.y <= 0) {
            issues.add('$objectPath.size는 양의 유한 크기여야 합니다.');
          }
          if (!object.hitboxScale.isFinite || object.hitboxScale <= 0) {
            issues.add('$objectPath.hitboxScale은 0보다 큰 유한 수여야 합니다.');
          }
          if (!object.restitution.isFinite ||
              object.restitution < 0 ||
              object.restitution > 1) {
            issues.add('$objectPath.restitution은 0에서 1 사이여야 합니다.');
          }
        }
      }
    }
    return issues;
  }
}

bool _isFiniteVec2(Vec2 value) {
  return value.x.isFinite && value.y.isFinite;
}

StageCatalog stageCatalogFromJson(String value) =>
    StageCatalog.fromJsonString(value);

String stageCatalogToJson(StageCatalog catalog) => catalog.toJsonString();

class _CatalogJsonReader {
  _CatalogJsonReader(this.json);

  final Map<String, dynamic> json;

  dynamic _required(String key) {
    if (!json.containsKey(key) || json[key] == null) {
      throw FormatException('stage catalog.$key: 필수 필드입니다.');
    }
    return json[key];
  }

  int requiredInt(String key) {
    final value = _required(key);
    if (value is int) {
      return value;
    }
    if (value is num && value.isFinite && value == value.roundToDouble()) {
      return value.toInt();
    }
    throw FormatException('stage catalog.$key: 정수여야 합니다.');
  }

  List<T> requiredList<T>(String key, T Function(Map<String, dynamic>) decode) {
    final value = _required(key);
    if (value is! List) {
      throw FormatException('stage catalog.$key: 배열이어야 합니다.');
    }
    return [
      for (var index = 0; index < value.length; index++)
        decode(_asMap(value[index], 'stage catalog.$key[$index]')),
    ];
  }

  Map<String, dynamic> _asMap(Object? value, String path) {
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
}
