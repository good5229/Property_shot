// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'fixtures/stage_bouncy_patterns.dart';

void main() {
  late StageCatalog catalog;
  late StageDefinition stage;

  setUpAll(() {
    catalog = StageCatalog.fromJsonString(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_bouncy');
  });

  test('2단계는 안정 패턴 4개와 기준 패턴 1개를 갖는다', () {
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_bouncy_01',
      'stage_bouncy_02',
      'stage_bouncy_03',
      'stage_bouncy_04',
    ]);
    expect(
      stage.patterns
          .where(
            (pattern) =>
                pattern.metadata[StageCatalog.baselineMetadataKey] ==
                StageCatalog.baselineMetadataValue,
          )
          .map((pattern) => pattern.patternId),
      ['stage_bouncy_01'],
    );
    expect(catalog.baselinePatternFor(stage).patternId, 'stage_bouncy_01');
  });

  test('탄성 튜토리얼 메타데이터와 고정 조건을 유지한다', () {
    final report = StagePatternValidator().validate(stage);
    expect(report.isValid, isTrue, reason: report.issues.join('\n'));

    for (final pattern in stage.patterns) {
      expect(pattern.intendedStrategyId, 'jelly');
      expect(pattern.acceptedStrategyIds, containsAll(['jelly', 'none']));
      expect(pattern.solutionFamilies.length, greaterThanOrEqualTo(2));
      expect(pattern.optionalChallenges, isNotEmpty);
      expect(pattern.metadata, isNot(contains('required_reward')));
      expect(
        pattern.objects.where((object) => object.id == 'jelly').single.traits,
        contains(TraitType.bouncy),
      );
      expect(
        pattern.objects
            .where((object) => object.type == EntityType.wall)
            .every((wall) => !wall.movable),
        isTrue,
      );
    }
  });

  test('네 패턴의 모든 쌍은 최소 두 범주의 배치가 다르다', () {
    for (var leftIndex = 0; leftIndex < stage.patterns.length; leftIndex++) {
      for (
        var rightIndex = leftIndex + 1;
        rightIndex < stage.patterns.length;
        rightIndex++
      ) {
        final left = stage.patterns[leftIndex];
        final right = stage.patterns[rightIndex];
        final differences = _differenceCategories(left, right);
        expect(
          differences.length,
          greaterThanOrEqualTo(2),
          reason: '${left.patternId}/${right.patternId} 차이 범주=$differences',
        );
      }
    }
  });

  test('저장된 대표 입력은 none/jelly 실제 성공과 풀이 계열을 재현한다', () {
    const resolver = ShotResolver();
    final jellyWallReflectionPatterns = <String>{};
    for (final fixture in stageBouncyRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
      if (fixture.strategyId == 'jelly') {
        expect(state.activeBall.traits, contains(TraitType.bouncy));
        expect(
          state.entityById('jelly')!.traits,
          isNot(contains(TraitType.bouncy)),
        );
      }
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: fixture.direction,
          power: fixture.power,
          equippedTrait: state.equippedTrait,
        ),
      );
      expect(
        result.state.phase,
        GamePhase.success,
        reason:
            '${fixture.patternId}/${fixture.strategyId} ${fixture.degree}도 '
            '${fixture.power} 성공 실패: ${result.events}',
      );
      if (fixture.strategyId == 'jelly') {
        final noneResult = resolver.resolve(
          _stateFor(pattern, 'none'),
          ShotInput(direction: fixture.direction, power: fixture.power),
        );
        expect(
          noneResult.state.phase,
          isNot(GamePhase.success),
          reason: '${fixture.patternId} jelly 대표 입력이 같은 none 입력에서도 성공합니다.',
        );
        expect(
          result.impacts.any(
            (impact) =>
                (impact.entityType == EntityType.wall &&
                    pattern.objects.any(
                      (object) =>
                          object.id == impact.entityId &&
                          object.type == EntityType.wall,
                    )) ||
                (impact.entityId == 'jelly' &&
                    impact.entityType == EntityType.bumper),
          ),
          isTrue,
          reason: '${fixture.patternId} jelly 대표 입력의 실제 충돌 대상이 없습니다.',
        );
        if (_hasPatternWallImpact(pattern, result)) {
          jellyWallReflectionPatterns.add(fixture.patternId);
        }
        print(
          '${fixture.patternId}/jelly same-input none=${noneResult.state.phase} '
          'events=${noneResult.events} impacts=${noneResult.impacts.map((impact) => impact.entityId).join(',')}',
        );
      }
      expect(
        pattern.solutionFamilies,
        contains(fixture.familyId),
        reason: '${fixture.patternId}에 저장된 계열 ${fixture.familyId}가 없습니다.',
      );
      expect(
        _matchesFamily(pattern, result, fixture.familyId),
        isTrue,
        reason: '${fixture.patternId}/${fixture.strategyId} 실제 계열 근거 없음',
      );
      expect(result.chainSafetyDiagnostics, isEmpty);
      expect(result.events, isNot(contains('chain_safety_stop')));
    }
    expect(
      jellyWallReflectionPatterns.length,
      4,
      reason: '4개 jelly 대표 경로 모두 실제 pattern wall+bounced여야 합니다.',
    );

    for (final pattern in stage.patterns) {
      final coveredFamilies = stageBouncyRepresentatives
          .where((fixture) => fixture.patternId == pattern.patternId)
          .map((fixture) => fixture.familyId)
          .toSet();
      expect(
        coveredFamilies,
        containsAll(pattern.solutionFamilies),
        reason:
            '${pattern.patternId}의 모든 solutionFamilies를 대표 fixture가 덮지 못했습니다.',
      );
      expect(
        stageBouncyRepresentatives.where(
          (fixture) =>
              fixture.patternId == pattern.patternId &&
              fixture.strategyId == 'jelly',
        ),
        isNotEmpty,
      );
      expect(
        stageBouncyRepresentatives.where(
          (fixture) =>
              fixture.patternId == pattern.patternId &&
              fixture.strategyId == 'none',
        ),
        isNotEmpty,
      );
    }
  });

  test('선택 도전은 대표 성공 경로로 수행 가능하고 기본 성공과 분리된다', () {
    const resolver = ShotResolver();
    for (final pattern in stage.patterns) {
      final results = <ShotResult>[];
      for (final fixture in stageBouncyRepresentatives.where(
        (fixture) => fixture.patternId == pattern.patternId,
      )) {
        final state = _stateFor(pattern, fixture.strategyId);
        results.add(
          resolver.resolve(
            state,
            ShotInput(
              direction: fixture.direction,
              power: fixture.power,
              equippedTrait: state.equippedTrait,
            ),
          ),
        );
      }
      for (final challenge in pattern.optionalChallenges) {
        switch (challenge) {
          case 'one_shot':
            expect(
              results,
              everyElement(
                predicate<ShotResult>(
                  (result) => result.state.phase == GamePhase.success,
                ),
              ),
            );
          case 'jelly_hit':
            expect(
              results.any(
                (result) =>
                    result.events.contains('jelly_bounced') &&
                    result.impacts.any(
                      (impact) =>
                          impact.entityId == 'jelly' &&
                          impact.entityType == EntityType.bumper,
                    ),
              ),
              isTrue,
              reason: '${pattern.patternId} 젤리 도전 증거 없음',
            );
          case 'two_wall_banks':
            expect(
              results.any(
                (result) =>
                    result.events.contains('bounced') &&
                    result.impacts
                            .where(
                              (impact) =>
                                  impact.entityType == EntityType.wall &&
                                  pattern.objects.any(
                                    (object) =>
                                        object.id == impact.entityId &&
                                        object.type == EntityType.wall,
                                  ),
                            )
                            .map((impact) => impact.entityId)
                            .toSet()
                            .length >=
                        2,
              ),
              isTrue,
              reason: '${pattern.patternId} 두 벽 반사 도전 증거 없음',
            );
          case 'upper_wall_bank':
            expect(
              results.any(
                (result) =>
                    result.events.contains('bounced') &&
                    result.impacts.any(
                      (impact) =>
                          impact.entityId == 'wall_top' &&
                          impact.entityType == EntityType.wall,
                    ),
              ),
              isTrue,
              reason: '${pattern.patternId} 상단 벽 반사 도전 증거 없음',
            );
          default:
            fail('검증되지 않은 선택 도전입니다: $challenge');
        }
      }
      expect(pattern.metadata, isNot(contains('required_reward')));
    }
  });

  test('대표 입력은 각도·파워 근방 15점 중 최소 3개 이상 성공한다', () {
    const resolver = ShotResolver();
    final nearCounts = <String, int>{};
    for (final fixture in stageBouncyRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
      var successCount = 0;
      final inputKeys = <String>{};
      final powerDeltas = fixture.power >= 0.96
          ? [-0.04, -0.02, 0, 0.01, 0.02]
          : [-0.04, -0.02, 0, 0.02, 0.04];
      for (final degreeDelta in [-2, 0, 2]) {
        for (final powerDelta in powerDeltas) {
          final degree = (fixture.degree + degreeDelta) % 360;
          final power = (fixture.power + powerDelta).clamp(0.05, 1.0);
          final inputKey = '$degree/${power.toStringAsFixed(2)}';
          expect(
            inputKeys.add(inputKey),
            isTrue,
            reason:
                '${fixture.patternId}/${fixture.strategyId} 근방 입력 중복: $inputKey',
          );
          final result = resolver.resolve(
            state,
            ShotInput(
              direction: _directionFor(degree),
              power: power,
              equippedTrait: state.equippedTrait,
            ),
          );
          if (result.state.phase == GamePhase.success) successCount++;
        }
      }
      expect(
        inputKeys.length,
        15,
        reason:
            '${fixture.patternId}/${fixture.strategyId} 고유 근방 입력 수가 15가 아닙니다.',
      );
      final deliberatelyRareNoneRoute =
          fixture.strategyId == 'none' &&
          const {
            'stage_bouncy_01',
            'stage_bouncy_03',
          }.contains(fixture.patternId);
      expect(
        successCount,
        greaterThanOrEqualTo(deliberatelyRareNoneRoute ? 1 : 3),
        reason:
            '${fixture.patternId}/${fixture.strategyId} 대표 근방 성공점=$successCount/15',
      );
      nearCounts['${fixture.patternId}/${fixture.strategyId}/${fixture.familyId}'] =
          successCount;
    }
    print(
      'stage_bouncy 대표 근방 성공점: '
      '${nearCounts.entries.map((entry) => '${entry.key}=${entry.value}/15').join('; ')}',
    );
  });

  test('결정론 격자에서 jelly 전략의 성공 영역이 none보다 넓다', () {
    const resolver = ShotResolver();
    final counts = <String, ({int none, int jelly})>{};
    for (final pattern in stage.patterns) {
      final noneState = _stateFor(pattern, 'none');
      final jellyState = _stateFor(pattern, 'jelly');
      var none = 0;
      var jelly = 0;
      for (var degree = 0; degree < 360; degree += 4) {
        for (var powerStep = 1; powerStep <= 10; powerStep++) {
          final power = powerStep / 10;
          final noneResult = resolver.resolve(
            noneState,
            ShotInput(direction: _directionFor(degree), power: power),
          );
          final jellyResult = resolver.resolve(
            jellyState,
            ShotInput(
              direction: _directionFor(degree),
              power: power,
              equippedTrait: TraitType.bouncy,
            ),
          );
          if (noneResult.state.phase == GamePhase.success) none++;
          if (jellyResult.state.phase == GamePhase.success) jelly++;
        }
      }
      counts[pattern.patternId] = (none: none, jelly: jelly);
      expect(
        jelly,
        greaterThan(none),
        reason: '${pattern.patternId} 성공점 none=$none, jelly=$jelly',
      );
      if (const {
        'stage_bouncy_01',
        'stage_bouncy_03',
      }.contains(pattern.patternId)) {
        final maximumBypassRatio = pattern.patternId == 'stage_bouncy_01'
            ? 0.30
            : 0.10;
        expect(
          none / jelly,
          lessThanOrEqualTo(maximumBypassRatio),
          reason:
              '${pattern.patternId} 무속성 우회 비율이 허용치 '
              '${(maximumBypassRatio * 100).round()}%를 넘습니다: '
              'none=$none jelly=$jelly ratio=${none / jelly}',
        );
      }
    }
    print(
      'stage_bouncy 축소 격자 성공점: '
      '${counts.entries.map((entry) => '${entry.key} none=${entry.value.none}, '
          'jelly=${entry.value.jelly}').join('; ')}',
    );
  });

  test('같은 충돌 입력에서 탄성 공의 이동 도달 거리가 정량적으로 더 길다', () {
    const resolver = ShotResolver();
    final measurements = <String, double>{};
    for (final fixture in stageBouncyCollisionFixtures) {
      final pattern = stage.patternById(fixture.patternId);
      final noneState = _stateFor(pattern, 'none');
      final jellyState = _stateFor(pattern, 'jelly');
      final noneResult = resolver.resolve(
        noneState,
        ShotInput(direction: fixture.direction, power: fixture.power),
      );
      final jellyResult = resolver.resolve(
        jellyState,
        ShotInput(
          direction: fixture.direction,
          power: fixture.power,
          equippedTrait: TraitType.bouncy,
        ),
      );
      expect(
        noneResult.impacts.any(
          (impact) =>
              impact.entityType == EntityType.wall ||
              impact.entityType == EntityType.bumper,
        ),
        isTrue,
        reason: '${fixture.patternId} 일반 공의 충돌 증거 없음',
      );
      expect(
        jellyResult.impacts.any(
          (impact) =>
              impact.entityType == EntityType.wall ||
              impact.entityType == EntityType.bumper,
        ),
        isTrue,
        reason: '${fixture.patternId} 탄성 공의 충돌 증거 없음',
      );
      final nonePath = _pathLength(noneResult.path);
      final jellyPath = _pathLength(jellyResult.path);
      final gain = jellyPath - nonePath;
      expect(
        gain,
        greaterThan(fixture.minimumPathGain),
        reason:
            '${fixture.patternId} 경로 길이 none=$nonePath jelly=$jellyPath 증가=$gain',
      );
      measurements[fixture.patternId] = gain;
    }
    print(
      'stage_bouncy 탄성 경로 길이 증가: '
      '${measurements.entries.map((entry) => '${entry.key}=${entry.value.toStringAsFixed(3)}').join('; ')}',
    );
  });

  test('실행 probe에서도 새 패턴의 route·벽 불변·안전 조건이 유지된다', () {
    final probe = ShotResolverPatternRuntimeProbe();
    for (final pattern in stage.patterns) {
      final evidence = probe.probe(stage: stage, pattern: pattern);
      expect(evidence.autoClearDetected, isFalse, reason: pattern.patternId);
      expect(evidence.definitiveNoRoute, isFalse, reason: pattern.patternId);
      expect(evidence.wallMoved, isFalse, reason: pattern.patternId);
      expect(evidence.safetyStop, isFalse, reason: pattern.patternId);
      expect(evidence.nonDeterministic, isFalse, reason: pattern.patternId);
      expect(evidence.holePassThrough, isFalse, reason: pattern.patternId);
      expect(evidence.negativeTime, isFalse, reason: pattern.patternId);
      expect(evidence.finiteTime, isTrue, reason: pattern.patternId);
      expect(evidence.finiteCoordinates, isTrue, reason: pattern.patternId);
      expect(
        evidence.allRepresentativeInputsNoMovement,
        isFalse,
        reason: pattern.patternId,
      );
      expect(evidence.withinBudget, isTrue, reason: pattern.patternId);
    }
  });
}

GameState _stateFor(StagePattern pattern, String strategyId) {
  var state = pattern
      .toLevelDefinition(stageId: 'stage_bouncy', stageTitle: '2. 탄성 익히기')
      .createState(0);
  if (strategyId == 'jelly') {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(traits.selectSource(state, 'jelly'));
  }
  return state;
}

bool _matchesFamily(StagePattern pattern, ShotResult result, String family) {
  switch (family) {
    case 'wall_reflection':
      return result.events.contains('bounced') &&
          result.impacts.any(
            (impact) =>
                impact.entityType == EntityType.wall &&
                pattern.objects.any(
                  (object) =>
                      object.id == impact.entityId &&
                      object.type == EntityType.wall,
                ),
          );
    case 'jelly_interaction':
      return result.events.contains('jelly_bounced') &&
          result.impacts.any(
            (impact) =>
                impact.entityId == 'jelly' &&
                impact.entityType == EntityType.bumper,
          );
    case 'multi_wall_reflection':
      return result.events.contains('bounced') &&
          result.impacts
                  .where(
                    (impact) =>
                        impact.entityType == EntityType.wall &&
                        pattern.objects.any(
                          (object) =>
                              object.id == impact.entityId &&
                              object.type == EntityType.wall,
                        ),
                  )
                  .map((impact) => impact.entityId)
                  .toSet()
                  .length >=
              2;
    default:
      return false;
  }
}

bool _hasPatternWallImpact(StagePattern pattern, ShotResult result) {
  return result.events.contains('bounced') &&
      result.impacts.any(
        (impact) =>
            impact.entityType == EntityType.wall &&
            pattern.objects.any(
              (object) =>
                  object.id == impact.entityId &&
                  object.type == EntityType.wall,
            ),
      );
}

Set<String> _differenceCategories(StagePattern left, StagePattern right) {
  final differences = <String>{};
  if (left.ballSpawn != right.ballSpawn) differences.add('ballSpawn');
  if (_positionOf(left, 'hole') != _positionOf(right, 'hole')) {
    differences.add('hole');
  }
  if (_positionOf(left, 'jelly') != _positionOf(right, 'jelly')) {
    differences.add('jelly');
  }
  if (_wallSignature(left) != _wallSignature(right)) {
    differences.add('wall_structure');
  }
  if (left.objects.length != right.objects.length) {
    differences.add('object_composition');
  }
  return differences;
}

Vec2? _positionOf(StagePattern pattern, String id) {
  for (final object in pattern.objects) {
    if (object.id == id) return object.position;
  }
  return null;
}

String _wallSignature(StagePattern pattern) {
  return pattern.objects
      .where((object) => object.type == EntityType.wall)
      .map(
        (object) =>
            '${object.id}:${object.position.x},${object.position.y},'
            '${object.size.x},${object.size.y}',
      )
      .toList()
      .join('|');
}

double _pathLength(List<Vec2> path) {
  var total = 0.0;
  for (var index = 1; index < path.length; index++) {
    total += path[index].distanceTo(path[index - 1]);
  }
  return total;
}

Vec2 _directionFor(int degree) {
  final radians = (degree % 360) * math.pi / 180;
  return Vec2(math.cos(radians), math.sin(radians));
}
