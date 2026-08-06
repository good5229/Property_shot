import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'fixtures/stage_chain_gate_patterns.dart';

void main() {
  late StageCatalog catalog;
  late StageDefinition stage;

  setUpAll(() {
    catalog = StageCatalog.fromJsonString(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_chain_gate');
  });

  test('연쇄 문 열기 패턴 ID와 기준 메타데이터가 안정적이다', () {
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_chain_gate_01',
      'stage_chain_gate_02',
      'stage_chain_gate_03',
      'stage_chain_gate_04',
    ]);
    expect(
      stage.patterns
          .where(
            (pattern) =>
                pattern.metadata[StageCatalog.baselineMetadataKey] ==
                StageCatalog.baselineMetadataValue,
          )
          .map((pattern) => pattern.patternId),
      ['stage_chain_gate_01'],
    );
    expect(catalog.baselinePatternFor(stage).patternId, 'stage_chain_gate_01');

    for (final pattern in stage.patterns) {
      expect(pattern.intendedStrategyId, 'steel');
      expect(
        pattern.acceptedStrategyIds,
        containsAll(['steel', 'glue', 'none']),
      );
      expect(pattern.solutionFamilies.length, greaterThanOrEqualTo(2));
      expect(pattern.optionalChallenges, isNotEmpty);
      expect(pattern.metadata, isNot(contains('required_reward')));
      expect(
        pattern.objects
            .where((object) => object.type == EntityType.wall)
            .every((wall) => !wall.movable),
        isTrue,
      );
      expect(
        pattern.objects
            .where((object) => object.type == EntityType.gate)
            .every((gate) => !gate.movable),
        isTrue,
      );
    }
  });

  test('각 패턴은 production validator와 runtime probe를 통과한다', () {
    final validator = StagePatternValidator();
    final probe = ShotResolverPatternRuntimeProbe();

    for (final pattern in stage.patterns) {
      final report = validator.validatePattern(stage, pattern);
      expect(report.isValid, isTrue, reason: report.issues.join('\n'));

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
      expect(evidence.withinBudget, isTrue, reason: pattern.patternId);
    }
  });

  test('대표 입력은 none 우회와 steel 속성 이전 경로를 실제로 성공시킨다', () {
    const resolver = ShotResolver();
    final results = <String, ShotResult>{};

    for (final fixture in stageChainGateRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
      if (fixture.strategyId == 'steel') {
        expect(state.activeBall.traits, contains(TraitType.heavy));
      } else {
        expect(state.activeBall.traits, isEmpty);
      }

      final result = resolver.resolve(
        state,
        ShotInput(
          direction: fixture.direction,
          power: fixture.power,
          equippedTrait: state.equippedTrait,
        ),
      );
      results['${fixture.patternId}/${fixture.strategyId}'] = result;
      expect(
        result.state.phase,
        GamePhase.success,
        reason:
            '${fixture.patternId}/${fixture.strategyId} '
            '${fixture.degree}도 ${fixture.power} 성공 실패: ${result.events}',
      );
      expect(result.chainSafetyDiagnostics, isEmpty);
      expect(result.events, isNot(contains('chain_safety_stop')));
      expect(pattern.solutionFamilies, contains(fixture.familyId));

      if (fixture.strategyId == 'none') {
        expect(result.events, contains('hole_entered'));
        expect(result.events, isNot(contains('switch_pressed')));
        expect(result.state.entityById('gate')!.open, isFalse);
        expect(
          result.impacts.any((impact) => impact.entityId == 'hole'),
          isTrue,
        );
      } else {
        _expectSteelSwitchAndHoleEvidence(pattern, result);

        final sameInputNone = resolver.resolve(
          _stateFor(pattern, 'none'),
          ShotInput(direction: fixture.direction, power: fixture.power),
        );
        expect(
          sameInputNone.events,
          isNot(contains('switch_pressed')),
          reason: '${pattern.patternId} none 동일 입력이 스위치를 열었습니다.',
        );
        expect(sameInputNone.state.entityById('gate')!.open, isFalse);
      }
    }

    for (final pattern in stage.patterns) {
      final coveredFamilies = stageChainGateRepresentatives
          .where((fixture) => fixture.patternId == pattern.patternId)
          .map((fixture) => fixture.familyId)
          .toSet();
      if (pattern.patternId == 'stage_chain_gate_02') {
        final preparedResults = _preparedResults(
          pattern,
          stageChainGatePreparedShots.first,
        );
        expect(preparedResults.first.events, contains('sticky_attached'));
        expect(preparedResults.second.events, contains('spent_ball_bounced'));
        expect(preparedResults.second.state.phase, GamePhase.success);
        coveredFamilies.add('glue_preparation');
      }
      expect(
        coveredFamilies,
        containsAll(pattern.solutionFamilies),
        reason:
            '${pattern.patternId} 선언 solutionFamilies의 실제 fixture 증거가 부족합니다.',
      );
      expect(
        results['${pattern.patternId}/none'],
        isNotNull,
        reason: '${pattern.patternId} none 우회 대표 입력이 없습니다.',
      );
      expect(
        results['${pattern.patternId}/steel'],
        isNotNull,
        reason: '${pattern.patternId} steel 대표 입력이 없습니다.',
      );
    }
  });

  test('대표 입력 주변 15개 고유 입력 중 최소 3개가 패턴별로 성공한다', () {
    const resolver = ShotResolver();

    for (final fixture in stageChainGateRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
      final inputKeys = <String>{};
      var successCount = 0;

      for (final degreeDelta in [-2, 0, 2]) {
        for (final powerDelta in [-0.04, -0.02, 0, 0.02, 0.04]) {
          final degree = (fixture.degree + degreeDelta) % 360;
          final power = (fixture.power + powerDelta).clamp(0.05, 1.0);
          final key = '$degree/${power.toStringAsFixed(2)}';
          expect(
            inputKeys.add(key),
            isTrue,
            reason: '${fixture.patternId}/${fixture.strategyId} 입력 중복: $key',
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

      expect(inputKeys, hasLength(15));
      expect(
        successCount,
        greaterThanOrEqualTo(3),
        reason:
            '${fixture.patternId}/${fixture.strategyId} '
            '근방 성공점=$successCount/15',
      );
    }
  });

  test('stage_chain_gate_02는 점착 준비샷과 spent ball 인과를 증명한다', () {
    const resolver = ShotResolver();
    final pattern = stage.patternById('stage_chain_gate_02');
    final prepared = stageChainGatePreparedShots.first;
    final preparedResults = _preparedResults(pattern, prepared);
    final first = preparedResults.first;
    final armed = preparedResults.armed;
    expect(first.events, contains('sticky_attached'));
    final spent = first.state.entityById('spent_ball_1')!;
    expect(spent.movable, isFalse);
    expect(spent.visualState, 'stuck');
    expect(spent.traits, contains(TraitType.sticky));
    expect(first.state.entityById('steel')!.traits, contains(TraitType.heavy));
    expect(armed.activeBall.traits, contains(TraitType.heavy));
    expect(armed.equippedTrait, TraitType.heavy);

    final second = preparedResults.second;
    final spentImpact = second.impacts.firstWhere(
      (impact) => impact.entityId == 'spent_ball_1',
    );
    expect(second.state.phase, GamePhase.success);
    expect(second.events, contains('spent_ball_bounced'));
    expect(second.events, contains('bounced'));
    expect(second.events, isNot(contains('blocked_by_ball')));
    expect(spentImpact.sourceEntityId, 'active_ball');
    _expectPreparedCausalEvidence(pattern, second);
    final impactIds = second.impacts.map((impact) => impact.entityId).toList();
    expect(
      impactIds.indexOf('spent_ball_1'),
      lessThan(impactIds.indexOf('switch')),
    );
    expect(impactIds.indexOf('switch'), lessThan(impactIds.indexOf('hole')));
    expect(second.events, contains('hole_entered'));
    expect(
      spentImpact.pathIndex,
      lessThan(
        second.impacts
            .firstWhere((impact) => impact.entityId == 'hole')
            .pathIndex,
      ),
    );

    final noPreparation = resolver.resolve(
      _stateFor(pattern, 'none'),
      ShotInput(
        direction: prepared.secondDirection,
        power: prepared.secondPower,
      ),
    );
    expect(noPreparation.events, isNot(contains('spent_ball_bounced')));
    expect(noPreparation.events, isNot(contains('switch_pressed')));
    expect(noPreparation.state.entityById('gate')!.open, isFalse);
    expect(
      noPreparation.impacts.any((impact) => impact.entityId == 'spent_ball_1'),
      isFalse,
    );
    expect(
      noPreparation.state.phase != second.state.phase ||
          noPreparation.events.join('|') != second.events.join('|'),
      isTrue,
      reason: '준비샷 없는 동일 둘째 입력이 점착 과거 공 인과를 재현했습니다.',
    );

    final planKeys = <String>{};
    final firstAngles = <int>{};
    final firstPowers = <double>{};
    final secondAngles = <int>{};
    final secondPowers = <double>{};
    for (final plan in stageChainGatePreparedShots) {
      final key =
          '${plan.firstDegree}/${plan.firstPower}/'
          '${plan.secondDegree}/${plan.secondPower}';
      expect(planKeys.add(key), isTrue, reason: '준비샷 계획 중복: $key');
      expect(
        plan.firstPower,
        inInclusiveRange(0.12, 1.0),
        reason: '첫 샷 power가 실제 UI 충전 범위를 벗어났습니다: $key',
      );
      expect(
        plan.secondPower,
        inInclusiveRange(0.12, 1.0),
        reason: '둘째 샷 power가 실제 UI 충전 범위를 벗어났습니다: $key',
      );
      expect(
        _isUiChargeTick(plan.firstPower),
        isTrue,
        reason: '첫 샷 power가 UI 충전 눈금이 아닙니다: $key',
      );
      expect(
        _isUiChargeTick(plan.secondPower),
        isTrue,
        reason: '둘째 샷 power가 UI 충전 눈금이 아닙니다: $key',
      );
      firstAngles.add(plan.firstDegree);
      firstPowers.add(plan.firstPower);
      secondAngles.add(plan.secondDegree);
      secondPowers.add(plan.secondPower);

      final firstVariant = resolver.resolve(
        _stateFor(pattern, 'glue'),
        ShotInput(
          direction: plan.firstDirection,
          power: plan.firstPower,
          equippedTrait: _stateFor(pattern, 'glue').equippedTrait,
        ),
      );
      expect(firstVariant.events, contains('sticky_attached'));
      final armedVariant = const TraitResolver().transferSelectedTrait(
        const TraitResolver().selectSource(firstVariant.state, 'steel'),
      );
      final secondVariant = resolver.resolve(
        armedVariant,
        ShotInput(
          direction: plan.secondDirection,
          power: plan.secondPower,
          equippedTrait: armedVariant.equippedTrait,
        ),
      );
      _expectPreparedCausalEvidence(pattern, secondVariant);
    }
    expect(planKeys, hasLength(3));
    expect(firstAngles.length, greaterThan(1));
    expect(firstPowers.length, greaterThan(1));
    expect(secondAngles.length, greaterThan(1));
    expect(secondPowers.length, greaterThan(1));
  });

  test('모든 패턴 쌍은 최소 두 범주의 배치 차이를 가진다', () {
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

  test('선택 도전은 실제 대표 경로와 분리되어 증명된다', () {
    const resolver = ShotResolver();
    for (final pattern in stage.patterns) {
      final patternFixtures = stageChainGateRepresentatives.where(
        (fixture) => fixture.patternId == pattern.patternId,
      );
      final results = [
        for (final fixture in patternFixtures)
          resolver.resolve(
            _stateFor(pattern, fixture.strategyId),
            ShotInput(
              direction: fixture.direction,
              power: fixture.power,
              equippedTrait: _stateFor(
                pattern,
                fixture.strategyId,
              ).equippedTrait,
            ),
          ),
      ];

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
          case 'switch_and_hole':
            expect(
              results.any(
                (result) =>
                    result.events.contains('switch_pressed') &&
                    result.events.contains('hole_entered'),
              ),
              isTrue,
              reason: '${pattern.patternId} 스위치·홀 도전 증거 없음',
            );
          case 'prepare_with_glue':
            final preparedResults = _preparedResults(
              pattern,
              stageChainGatePreparedShots.first,
            );
            final first = preparedResults.first;
            final second = preparedResults.second;
            expect(first.events, contains('sticky_attached'));
            _expectPreparedCausalEvidence(pattern, second);
          default:
            fail('검증되지 않은 선택 도전입니다: $challenge');
        }
      }
      expect(pattern.metadata, isNot(contains('required_reward')));
    }
  });
}

GameState _stateFor(StagePattern pattern, String strategyId) {
  var state = pattern
      .toLevelDefinition(stageId: 'stage_chain_gate', stageTitle: '3. 연쇄 문 열기')
      .createState(0);
  if (strategyId == 'steel' || strategyId == 'glue') {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(
      traits.selectSource(state, strategyId),
    );
  }
  return state;
}

({ShotResult first, GameState armed, ShotResult second}) _preparedResults(
  StagePattern pattern,
  StageChainGatePreparedShot prepared,
) {
  const resolver = ShotResolver();
  const traits = TraitResolver();
  final firstState = _stateFor(pattern, 'glue');
  final first = resolver.resolve(
    firstState,
    ShotInput(
      direction: prepared.firstDirection,
      power: prepared.firstPower,
      equippedTrait: firstState.equippedTrait,
    ),
  );
  final armed = traits.transferSelectedTrait(
    traits.selectSource(first.state, 'steel'),
  );
  final second = resolver.resolve(
    armed,
    ShotInput(
      direction: prepared.secondDirection,
      power: prepared.secondPower,
      equippedTrait: armed.equippedTrait,
    ),
  );
  return (first: first, armed: armed, second: second);
}

void _expectPreparedCausalEvidence(StagePattern pattern, ShotResult result) {
  expect(result.state.phase, GamePhase.success);
  expect(result.events, contains('spent_ball_bounced'));
  _expectSteelSwitchAndHoleEvidence(pattern, result);
  final impactIds = result.impacts.map((impact) => impact.entityId).toList();
  expect(
    impactIds.indexOf('spent_ball_1'),
    lessThan(impactIds.indexOf('switch')),
  );
  expect(impactIds.indexOf('switch'), lessThan(impactIds.indexOf('hole')));
}

void _expectSteelSwitchAndHoleEvidence(
  StagePattern pattern,
  ShotResult result,
) {
  expect(result.events, contains('switch_pressed'));
  expect(result.events, contains('hole_entered'));
  expect(result.state.entityById('switch')!.pressed, isTrue);
  expect(result.state.entityById('gate')!.open, isTrue);

  final switchImpact = result.impacts.firstWhere(
    (impact) => impact.entityId == 'switch',
  );
  final gateImpact = result.impacts.where(
    (impact) => impact.entityId == 'gate',
  );
  final holeImpact = result.impacts.firstWhere(
    (impact) => impact.entityId == 'hole',
  );
  expect(switchImpact.pathIndex, lessThan(holeImpact.pathIndex));
  expect(
    result.impacts.any((impact) => impact.entityId == 'switch'),
    isTrue,
    reason: '${pattern.patternId} 실제 switch impact 없음',
  );
  expect(gateImpact, isEmpty, reason: '열린 문은 통과되어 막힘 충돌이 없어야 합니다.');

  final switchEvent = result.physicsEvents.firstWhere(
    (event) =>
        event.kind == PhysicsEventKind.impact &&
        event.targetEntityId == 'switch',
  );
  final gateOpenState = result.physicsEvents.firstWhere(
    (event) =>
        event.kind == PhysicsEventKind.stateChange &&
        event.targetEntityId == 'gate' &&
        event.visualState == 'open',
  );
  final gateOpeningMove = result.physicsEvents.firstWhere(
    (event) =>
        event.kind == PhysicsEventKind.move &&
        event.targetEntityId == 'gate' &&
        event.visualState == 'opening',
  );
  expect(switchEvent.pathIndex, lessThanOrEqualTo(gateOpenState.pathIndex));
  expect(switchEvent.pathIndex, lessThanOrEqualTo(gateOpeningMove.pathIndex));
  expect(gateOpenState.pathIndex, lessThanOrEqualTo(holeImpact.pathIndex));
  expect(gateOpeningMove.pathIndex, lessThanOrEqualTo(holeImpact.pathIndex));
}

Set<String> _differenceCategories(StagePattern left, StagePattern right) {
  final differences = <String>{};
  if (left.ballSpawn != right.ballSpawn) differences.add('ball');

  final leftByType = _objectsByType(left);
  final rightByType = _objectsByType(right);
  if (_signature(leftByType[EntityType.hole]) !=
      _signature(rightByType[EntityType.hole])) {
    differences.add('hole');
  }
  if (_signature(leftByType[EntityType.switchPad]) !=
          _signature(rightByType[EntityType.switchPad]) ||
      _signature(leftByType[EntityType.gate]) !=
          _signature(rightByType[EntityType.gate])) {
    differences.add('switchGateStructure');
  }
  if (_signature(leftByType[EntityType.weight]) !=
          _signature(rightByType[EntityType.weight]) ||
      _signature(leftByType[EntityType.stickySurface]) !=
          _signature(rightByType[EntityType.stickySurface])) {
    differences.add('traitSources');
  }
  if (_signature(leftByType[EntityType.crate]) !=
      _signature(rightByType[EntityType.crate])) {
    differences.add('movable');
  }
  if (_signature(leftByType[EntityType.wall]) !=
      _signature(rightByType[EntityType.wall])) {
    differences.add('wall');
  }
  return differences;
}

Map<EntityType, List<PatternObjectDefinition>> _objectsByType(
  StagePattern pattern,
) {
  final result = <EntityType, List<PatternObjectDefinition>>{};
  for (final object in pattern.objects) {
    result.putIfAbsent(object.type, () => []).add(object);
  }
  return result;
}

String _signature(List<PatternObjectDefinition>? objects) {
  if (objects == null) return '';
  return objects
      .map(
        (object) => [
          object.id,
          object.position.x,
          object.position.y,
          object.size.x,
          object.size.y,
          object.movable,
          object.solid,
          object.active,
          object.open,
          object.pressed,
          object.linkId,
        ].join(':'),
      )
      .join('|');
}

bool _isUiChargeTick(double power) {
  for (var index = 0; index <= 16; index++) {
    final tick = (0.12 + 0.055 * index).clamp(0.12, 1.0).toDouble();
    if ((power - tick).abs() < 0.000001) return true;
  }
  return false;
}

Vec2 _directionFor(int degree) {
  final radians = degree * math.pi / 180;
  return Vec2(math.cos(radians), math.sin(radians));
}
