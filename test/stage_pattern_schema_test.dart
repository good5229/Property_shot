import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';

void main() {
  test('스테이지 패턴은 JSON Map round-trip에서 모든 필드를 보존한다', () {
    final source = StageDefinition(
      stageId: 'stage_schema',
      title: '스키마 확인',
      patterns: [
        StagePattern(
          patternId: 'pattern_a',
          weight: 2.5,
          parShots: 4,
          difficultyBand: '중급',
          ballSpawn: const Vec2(56, 456),
          copyCharges: 1,
          bonusGoal: '세 번 안에 도착',
          copyCoreReward: 2,
          intendedStrategyId: 'bounce',
          acceptedStrategyIds: {'none', 'bounce'},
          solutionFamilies: {'벽 반사', '물체 밀기'},
          optionalChallenges: {'한 번에 성공'},
          metadata: {'지역': '초원', '설명': '여러 경로'},
          objects: const [
            PatternObjectDefinition(
              id: 'wall',
              type: EntityType.wall,
              position: Vec2(180, 12),
              size: Vec2(340, 24),
              solid: true,
              restitution: 0.12,
              visualState: '닫힘',
              linkId: 'gate_a',
            ),
            PatternObjectDefinition(
              id: 'heavy_ball',
              type: EntityType.ball,
              position: Vec2(72, 220),
              size: Vec2(24, 24),
              traits: {TraitType.heavy, TraitType.bouncy},
              movable: true,
              active: false,
              open: true,
              pressed: true,
              hitboxScale: 0.81,
            ),
          ],
        ),
      ],
    );

    final decoded = StageDefinition.fromJson(source.toJson());

    expect(decoded.stageId, source.stageId);
    expect(decoded.title, source.title);
    expect(decoded.patterns.single.toJson(), source.patterns.single.toJson());
    expect(
      decoded.patterns.single.objects
          .firstWhere((object) => object.id == 'wall')
          .toEntityState()
          .linkId,
      'gate_a',
    );
  });

  test('텍스트 JSON codec은 Map codec과 같은 결과를 만든다', () {
    final stage = StageDefinition(
      stageId: 'stage_text',
      title: '텍스트',
      patterns: [
        StagePattern(
          patternId: 'pattern_text',
          weight: 1,
          parShots: 2,
          difficultyBand: '초급',
          ballSpawn: const Vec2(20, 30),
          objects: const [],
        ),
      ],
    );

    final decoded = stageDefinitionFromJson(stageDefinitionToJson(stage));

    expect(decoded.toJson(), stage.toJson());
    expect(
      jsonDecode(stageDefinitionToJson(stage)),
      isA<Map<String, dynamic>>(),
    );
  });

  test('모든 현재 EntityType과 TraitType은 안정적인 이름으로 왕복한다', () {
    for (final type in EntityType.values) {
      expect(entityTypeFromSchemaName(entityTypeToSchemaName(type)), type);
    }
    for (final trait in TraitType.values) {
      expect(traitTypeFromSchemaName(traitTypeToSchemaName(trait)), trait);
    }
  });

  test('알 수 없는 enum 이름은 FormatException으로 거부한다', () {
    expect(
      () => entityTypeFromSchemaName('future_object'),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => traitTypeFromSchemaName('future_trait'),
      throwsA(isA<FormatException>()),
    );

    final json = _minimalPatternJson();
    (json['objects'] as List).single['type'] = 'future_object';
    expect(() => StagePattern.fromJson(json), throwsA(isA<FormatException>()));
  });

  test('필수 필드와 중첩 타입 오류를 FormatException으로 거부한다', () {
    final missingPatternId = _minimalPatternJson()..remove('patternId');
    expect(
      () => StagePattern.fromJson(missingPatternId),
      throwsA(isA<FormatException>()),
    );

    final invalidObjects = _minimalPatternJson()..['objects'] = 'not an array';
    expect(
      () => StagePattern.fromJson(invalidObjects),
      throwsA(isA<FormatException>()),
    );

    final invalidMetadata = _minimalPatternJson()..['metadata'] = {'seed': 42};
    expect(
      () => StagePattern.fromJson(invalidMetadata),
      throwsA(isA<FormatException>()),
    );
  });

  test('기존 1~4단계는 기본·제품 규칙 createState 결과를 모두 보존한다', () {
    for (var index = 0; index < levels.length; index++) {
      final legacy = levels[index];
      final patternId = '${legacy.id}_legacy';
      final stage = StageDefinition(
        stageId: legacy.id,
        title: legacy.name,
        patterns: [
          StagePattern.fromLevelDefinition(
            legacy,
            patternId: patternId,
            difficultyBand: '튜토리얼',
          ),
        ],
      );

      final converted = stage.levelDefinitionFor(patternId);
      expect(converted.id, legacy.id, reason: legacy.id);
      expect(converted.name, legacy.name, reason: legacy.id);
      expect(converted.patternId, patternId, reason: legacy.id);

      _expectStateEquivalent(
        legacy.createState(index),
        converted.createState(index),
        '${legacy.id} 기본 규칙',
      );
      _expectStateEquivalent(
        legacy.createState(
          index,
          productRules: true,
          copyCoreCount: 2,
          copyCoreRewarded: true,
        ),
        converted.createState(
          index,
          productRules: true,
          copyCoreCount: 2,
          copyCoreRewarded: true,
        ),
        '${legacy.id} 제품 규칙',
      );
    }
  });
}

Map<String, dynamic> _minimalPatternJson() {
  return {
    'patternId': 'pattern_minimal',
    'weight': 1,
    'parShots': 2,
    'difficultyBand': '초급',
    'ballSpawn': {'x': 10, 'y': 20},
    'objects': [
      {
        'id': 'wall',
        'type': 'wall',
        'position': {'x': 180, 'y': 12},
        'size': {'x': 340, 'y': 24},
      },
    ],
  };
}

String _entitySignature(EntityState entity) {
  return jsonEncode(PatternObjectDefinition.fromEntityState(entity).toJson());
}

void _expectStateEquivalent(
  GameState expected,
  GameState actual,
  String context,
) {
  expect(actual.levelIndex, expected.levelIndex, reason: context);
  expect(actual.levelName, expected.levelName, reason: context);
  expect(actual.ballSpawn, expected.ballSpawn, reason: context);
  expect(actual.phase, expected.phase, reason: context);
  expect(actual.shotCount, expected.shotCount, reason: context);
  expect(actual.score, expected.score, reason: context);
  expect(actual.selectedSourceId, expected.selectedSourceId, reason: context);
  expect(actual.selectedTrait, expected.selectedTrait, reason: context);
  expect(actual.equippedTrait, expected.equippedTrait, reason: context);
  expect(actual.aimDirection, expected.aimDirection, reason: context);
  expect(actual.aimPower, expected.aimPower, reason: context);
  expect(actual.copyCharges, expected.copyCharges, reason: context);
  expect(actual.copyChargeLimit, expected.copyChargeLimit, reason: context);
  expect(actual.copyCoreCount, expected.copyCoreCount, reason: context);
  expect(actual.copyCoreRewarded, expected.copyCoreRewarded, reason: context);
  expect(actual.message, expected.message, reason: context);
  expect(actual.history.length, expected.history.length, reason: context);
  expect(
    actual.entities.map(_entitySignature).toList(),
    expected.entities.map(_entitySignature).toList(),
    reason: context,
  );
}
