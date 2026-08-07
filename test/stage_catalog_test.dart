import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/levels/levels.dart';

import 'fixtures/legacy_levels.dart';
import '../tool/generate_stage_catalog.dart' as stage_catalog_generator;

void main() {
  late StageCatalog sourceCatalog;

  setUpAll(() {
    sourceCatalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
  });

  test('원본 카탈로그는 버전·순서·안정 ID를 보존한다', () {
    expect(sourceCatalog.schemaVersion, 1);
    expect(sourceCatalog.stages.map((stage) => stage.stageId).toList(), [
      'stage_heavy',
      'stage_bouncy',
      'stage_chain_gate',
      'stage_balloon',
      'stage_drained',
      'stage_speed',
      'stage_persistent',
      'stage_chain_score',
      'stage_rotating_reflector',
    ]);
    expect(
      sourceCatalog.stages.first.patterns.map((pattern) => pattern.patternId),
      ['stage_heavy_01', 'stage_heavy_02', 'stage_heavy_03', 'stage_heavy_04'],
    );
    expect(
      sourceCatalog
          .stageById('stage_bouncy')
          .patterns
          .map((pattern) => pattern.patternId),
      [
        'stage_bouncy_01',
        'stage_bouncy_02',
        'stage_bouncy_03',
        'stage_bouncy_04',
      ],
    );
    expect(
      sourceCatalog.stages
          .where(
            (stage) =>
                stage.stageId == 'stage_chain_gate' ||
                stage.stageId == 'stage_balloon',
          )
          .expand((stage) => stage.patterns.map((pattern) => pattern.patternId))
          .toList(),
      [
        'stage_chain_gate_01',
        'stage_chain_gate_02',
        'stage_chain_gate_03',
        'stage_chain_gate_04',
        'stage_balloon_01',
        'stage_balloon_02',
        'stage_balloon_03',
        'stage_balloon_04',
      ],
    );
    expect(sourceCatalog.validate(), isEmpty);
    expect(
      sourceCatalog
          .stageById('stage_persistent')
          .patterns
          .map((pattern) => pattern.patternId),
      [
        'stage_persistent_01',
        'stage_persistent_02',
        'stage_persistent_03',
        'stage_persistent_04',
      ],
    );
    expect(
      sourceCatalog
          .stageById('stage_chain_score')
          .patterns
          .map((pattern) => pattern.patternId),
      [
        'stage_chain_score_01',
        'stage_chain_score_02',
        'stage_chain_score_03',
        'stage_chain_score_04',
      ],
    );
    for (final stage in sourceCatalog.stages) {
      final baseline = sourceCatalog.baselinePatternFor(stage);
      expect(baseline.metadata, {
        StageCatalog.baselineMetadataKey: StageCatalog.baselineMetadataValue,
      });
    }
  });

  test('StageCatalog codec round-trip은 정규화된 모든 값을 보존한다', () {
    final roundTrip = stageCatalogFromJson(stageCatalogToJson(sourceCatalog));

    expect(roundTrip.toJson(), sourceCatalog.toJson());
    expect(
      jsonDecode(stageCatalogToJson(sourceCatalog)),
      isA<Map<String, dynamic>>(),
    );
  });

  test('생성 스냅샷은 원본 JSON과 완전히 일치한다', () {
    expect(generatedStageCatalog.toJson(), sourceCatalog.toJson());
    expect(generatedStageCatalog.schemaVersion, sourceCatalog.schemaVersion);
  });

  test('levels는 각 단계의 기준 패턴을 동기식으로 노출한다', () {
    expect(levels, hasLength(9));
    const expectedDifficultyBands = [
      '튜토리얼',
      '튜토리얼',
      '튜토리얼',
      '튜토리얼',
      '기초 응용',
      '기초 응용',
      '연쇄 응용',
      '연쇄 응용',
      '회전 입문',
    ];
    for (var index = 0; index < levels.length; index++) {
      expect(levels[index].id, sourceCatalog.stages[index].stageId);
      expect(
        levels[index].patternId,
        sourceCatalog.baselinePatternFor(sourceCatalog.stages[index]).patternId,
      );
      expect(levels[index].difficultyBand, expectedDifficultyBands[index]);
    }
    expect(() => levels.add(levels.first), throwsUnsupportedError);
  });

  test('기준 패턴은 JSON 패턴 순서와 무관하게 metadata로 선택한다', () {
    final stage = sourceCatalog.stages.first;
    final baseline = sourceCatalog.baselinePatternFor(stage);
    final decoy = StagePattern.fromJson({
      ...baseline.toJson(),
      'patternId': 'stage_heavy_decoy',
      'metadata': <String, String>{},
    });
    final reorderedStage = StageDefinition.fromJson({
      ...stage.toJson(),
      'patterns': [decoy.toJson(), baseline.toJson()],
    });
    final reorderedCatalog = StageCatalog(
      schemaVersion: sourceCatalog.schemaVersion,
      stages: [reorderedStage],
    );

    expect(
      reorderedCatalog.baselinePatternFor(reorderedStage).patternId,
      baseline.patternId,
    );
    expect(
      reorderedCatalog.baselineLevelDefinitionFor(reorderedStage).patternId,
      baseline.patternId,
    );
    expect(reorderedCatalog.validate(), isEmpty);
  });

  test('새 levels의 기존 게임 상태와 기준 fixture가 완전히 일치한다', () {
    expect(legacyLevels, hasLength(4));
    for (var index = 0; index < legacyLevels.length; index++) {
      final expected = legacyLevels[index];
      final actual = levels[index];

      expect(actual.id, expected.id, reason: 'stage $index id');
      expect(actual.name, expected.name, reason: 'stage $index name');
      expect(
        actual.ballSpawn,
        expected.ballSpawn,
        reason: 'stage $index spawn',
      );
      expect(actual.copyCharges, expected.copyCharges);
      expect(actual.parShots, expected.parShots);
      expect(actual.bonusGoal, expected.bonusGoal);
      expect(actual.copyCoreReward, expected.copyCoreReward);
      expect(actual.intendedStrategyId, expected.intendedStrategyId);
      expect(actual.acceptedStrategyIds, expected.acceptedStrategyIds);
      expect(
        actual.stageId,
        expected.id,
        reason: 'stage $index stageId metadata',
      );
      expect(
        actual.patternId,
        sourceCatalog.baselinePatternFor(sourceCatalog.stages[index]).patternId,
        reason: 'stage $index patternId metadata',
      );
      expect(
        actual.difficultyBand,
        '튜토리얼',
        reason: 'stage $index difficultyBand metadata',
      );
      expect(actual.patternMetadata, {
        StageCatalog.baselineMetadataKey: StageCatalog.baselineMetadataValue,
      }, reason: 'stage $index baseline metadata');
      expect(
        actual.entities.map(_entityJson).toList(),
        expected.entities.map(_entityJson).toList(),
        reason: 'stage $index entities',
      );

      _expectStateFieldsEqual(
        expected.createState(index),
        actual.createState(index),
        'stage $index 기본 규칙',
      );
      _expectStateFieldsEqual(
        expected.createState(
          index,
          productRules: true,
          copyCoreCount: 2,
          copyCoreRewarded: true,
        ),
        actual.createState(
          index,
          productRules: true,
          copyCoreCount: 2,
          copyCoreRewarded: true,
        ),
        'stage $index 제품 규칙',
      );
    }
  });

  test('StageCatalog와 levels의 내부 순서는 변경할 수 없다', () {
    expect(
      () => sourceCatalog.stages.add(sourceCatalog.stages.first),
      throwsUnsupportedError,
    );
  });

  test('지원하지 않는 schema와 빈 stages를 검증한다', () {
    final unsupported = StageCatalog(schemaVersion: 99, stages: const []);
    expect(unsupported.validate(), contains(contains('schemaVersion')));

    final empty = StageCatalog(schemaVersion: 1, stages: const []);
    expect(empty.validate(), contains(contains('stages는 하나 이상의')));
  });

  test('중복 stage·pattern·object ID를 검증한다', () {
    final duplicatePattern = _pattern(id: 'same_pattern');
    final duplicateStage = StageDefinition(
      stageId: 'same_stage',
      title: '중복',
      patterns: [duplicatePattern, duplicatePattern],
    );
    final duplicateObject = _pattern(
      id: 'object_pattern',
      objects: [_object('same_object'), _object('same_object')],
    );
    final catalog = StageCatalog(
      schemaVersion: 1,
      stages: [
        duplicateStage,
        duplicateStage,
        StageDefinition(
          stageId: 'object_stage',
          title: '물체 중복',
          patterns: [duplicateObject],
        ),
      ],
    );
    final messages = catalog.validate().join('\n');

    expect(messages, contains('stageId "same_stage"가 중복됩니다'));
    expect(messages, contains('patternId "same_pattern"가 중복됩니다'));
    expect(messages, contains('id "same_object"가 중복됩니다'));
  });

  test('기준 패턴이 없거나 둘 이상이면 검증과 선택이 실패한다', () {
    final noBaselineStage = StageDefinition(
      stageId: 'no_baseline',
      title: '기준 없음',
      patterns: [_pattern(metadata: const {})],
    );
    final twoBaselineStage = StageDefinition(
      stageId: 'two_baseline',
      title: '기준 둘',
      patterns: [
        _pattern(id: 'baseline_a'),
        _pattern(id: 'baseline_b'),
      ],
    );
    final noBaseline = StageCatalog(
      schemaVersion: 1,
      stages: [noBaselineStage],
    );
    final twoBaseline = StageCatalog(
      schemaVersion: 1,
      stages: [twoBaselineStage],
    );

    expect(noBaseline.validate().join('\n'), contains('현재 0개입니다'));
    expect(twoBaseline.validate().join('\n'), contains('현재 2개입니다'));
    expect(
      () => noBaseline.baselinePatternFor(noBaselineStage),
      throwsStateError,
    );
    expect(
      () => twoBaseline.baselinePatternFor(twoBaselineStage),
      throwsStateError,
    );
  });

  test('유효하지 않은 수치를 검증한다', () {
    final pattern = _pattern(
      weight: double.nan,
      parShots: 0,
      copyCharges: -1,
      copyCoreReward: -2,
      bonusGoal: ' ',
      ballSpawn: const Vec2(double.infinity, 10),
      objects: [
        _object(
          'bad',
          position: const Vec2(double.nan, 10),
          size: const Vec2(0, double.infinity),
          hitboxScale: double.nan,
          restitution: 2,
        ),
      ],
    );
    final report = StageCatalog(
      schemaVersion: 1,
      stages: [
        StageDefinition(stageId: 'numeric', title: '수치', patterns: [pattern]),
      ],
    ).validate().join('\n');

    expect(report, contains('weight는 0보다 큰 유한 수여야 합니다'));
    expect(report, contains('parShots는 1 이상이어야 합니다'));
    expect(report, contains('copyCharges는 0 이상이어야 합니다'));
    expect(report, contains('copyCoreReward는 0 이상이어야 합니다'));
    expect(report, contains('bonusGoal이 비어 있습니다'));
    expect(report, contains('ballSpawn은 유한한 좌표여야 합니다'));
    expect(report, contains('position은 유한한 좌표여야 합니다'));
    expect(report, contains('size는 양의 유한 크기여야 합니다'));
    expect(report, contains('hitboxScale은 0보다 큰 유한 수여야 합니다'));
    expect(report, contains('restitution은 0에서 1 사이여야 합니다'));
  });

  test('카탈로그 root·stages·필수 필드 오류를 FormatException으로 거부한다', () {
    expect(() => stageCatalogFromJson('[]'), throwsFormatException);
    expect(() => stageCatalogFromJson('null'), throwsFormatException);
    expect(
      () => stageCatalogFromJson('{"schemaVersion":1}'),
      throwsFormatException,
    );
    expect(
      () => stageCatalogFromJson('{"schemaVersion":1,"stages":{}}'),
      throwsFormatException,
    );
    expect(
      () => StageCatalog.fromJson({'stages': <dynamic>[]}),
      throwsFormatException,
    );
  });

  test('generator의 레거시 정적 검증 오류는 code·stage·pattern·한글 메시지를 포함한다', () {
    final stage = StageDefinition(
      stageId: 'stage_invalid',
      title: '잘못된 단계',
      patterns: [
        _pattern(
          id: 'pattern_invalid',
          objects: [_object('bad', size: const Vec2(0, 40))],
        ),
      ],
    );
    final issues = stage_catalog_generator.validateLegacyCatalog(
      StageCatalog(schemaVersion: 1, stages: [stage]),
    );
    final issue = issues.firstWhere((item) => item.codeName == 'invalid_size');
    final formatted = stage_catalog_generator.formatValidationIssue(issue);

    expect(formatted, contains('오류 코드=invalid_size'));
    expect(formatted, contains('스테이지=stage_invalid'));
    expect(formatted, contains('패턴=pattern_invalid'));
    expect(formatted, contains('양수여야 합니다'));
  });
}

Map<String, dynamic> _entityJson(EntityState entity) =>
    PatternObjectDefinition.fromEntityState(entity).toJson();

void _expectStateFieldsEqual(
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
    actual.entities.map(_entityJson).toList(),
    expected.entities.map(_entityJson).toList(),
    reason: context,
  );
}

StagePattern _pattern({
  String id = 'pattern',
  double weight = 1,
  int parShots = 2,
  int copyCharges = 0,
  int copyCoreReward = 0,
  String bonusGoal = '기준 목표',
  Vec2 ballSpawn = const Vec2(56, 456),
  Map<String, String> metadata = const {
    StageCatalog.baselineMetadataKey: StageCatalog.baselineMetadataValue,
  },
  List<PatternObjectDefinition>? objects,
}) {
  return StagePattern(
    patternId: id,
    weight: weight,
    parShots: parShots,
    copyCharges: copyCharges,
    copyCoreReward: copyCoreReward,
    bonusGoal: bonusGoal,
    difficultyBand: '튜토리얼',
    ballSpawn: ballSpawn,
    objects: objects ?? [_object('hole', type: EntityType.hole)],
    metadata: metadata,
  );
}

PatternObjectDefinition _object(
  String id, {
  EntityType type = EntityType.crate,
  Vec2 position = const Vec2(200, 200),
  Vec2 size = const Vec2(40, 40),
  double hitboxScale = 0.88,
  double restitution = 0.72,
}) {
  return PatternObjectDefinition(
    id: id,
    type: type,
    position: position,
    size: size,
    hitboxScale: hitboxScale,
    restitution: restitution,
  );
}
