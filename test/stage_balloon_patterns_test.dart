import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'fixtures/stage_balloon_patterns.dart';

void main() {
  late StageCatalog catalog;
  late StageDefinition stage;

  setUpAll(() {
    catalog = StageCatalog.fromJsonString(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_balloon');
  });

  test('풍선 패턴 ID·기준 메타데이터·불변 물리 조건을 보존한다', () {
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_balloon_01',
      'stage_balloon_02',
      'stage_balloon_03',
      'stage_balloon_04',
    ]);
    expect(
      stage.patterns
          .where(
            (pattern) =>
                pattern.metadata[StageCatalog.baselineMetadataKey] ==
                StageCatalog.baselineMetadataValue,
          )
          .map((pattern) => pattern.patternId),
      ['stage_balloon_01'],
    );
    expect(catalog.baselinePatternFor(stage).patternId, 'stage_balloon_01');

    for (final pattern in stage.patterns) {
      expect(pattern.intendedStrategyId, 'spike_source');
      expect(
        pattern.acceptedStrategyIds,
        containsAll(['none', 'spike_source']),
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

  test('모든 패턴이 production validator와 runtime probe를 통과한다', () {
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

  test('대표 sharp·none 경로가 선언한 실제 family를 증명한다', () {
    const resolver = ShotResolver();
    final results = <String, ShotResult>{};

    for (final fixture in stageBalloonRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
      expect(fixture.power, inInclusiveRange(0.12, 1.0));
      expect(_isUiChargeTick(fixture.power), isTrue);

      final result = _resolve(resolver, state, fixture.degree, fixture.power);
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

      if (fixture.strategyId == 'sharp') {
        _expectSharpEvidence(pattern, result);
        final sameInputNone = _resolve(
          resolver,
          _stateFor(pattern, 'none'),
          fixture.degree,
          fixture.power,
        );
        expect(sameInputNone.events, isNot(contains('balloon_popped')));
        expect(sameInputNone.events, isNot(contains('sharpness_consumed')));
        expect(sameInputNone.state.entityById('balloon')!.active, isTrue);
      } else if (fixture.familyId == 'balloon_bounce') {
        _expectBalloonBounceEvidence(pattern, result);
      } else {
        expect(result.events, isNot(contains('balloon_popped')));
        expect(result.events, isNot(contains('balloon_bounced')));
        expect(
          result.impacts.where(
            (impact) => impact.entityType == EntityType.balloon,
          ),
          isEmpty,
        );
      }
    }

    for (final pattern in stage.patterns) {
      final patternFixtures = stageBalloonRepresentatives.where(
        (fixture) => fixture.patternId == pattern.patternId,
      );
      final coveredFamilies = patternFixtures
          .map((fixture) => fixture.familyId)
          .toSet();
      expect(
        coveredFamilies,
        containsAll(pattern.solutionFamilies),
        reason: '${pattern.patternId} 선언 family의 대표 증거가 부족합니다.',
      );
      expect(results['${pattern.patternId}/sharp'], isNotNull);
      expect(results['${pattern.patternId}/none'], isNotNull);
      _expectOptionalChallenges(pattern, results);
    }
  });

  test('대표 입력 주변 15개 고유 입력 중 최소 3개가 성공한다', () {
    const resolver = ShotResolver();

    for (final fixture in stageBalloonRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
      final inputKeys = <String>{};
      var successCount = 0;

      for (final degreeDelta in [-2, 0, 2]) {
        for (final powerDelta in [-0.04, -0.02, 0, 0.02, 0.04]) {
          final degree = (fixture.degree + degreeDelta) % 360;
          final power = fixture.power + powerDelta;
          expect(power, inInclusiveRange(0.12, 1.0));
          final key = '$degree/${power.toStringAsFixed(3)}';
          expect(inputKeys.add(key), isTrue, reason: '입력 중복: $key');
          final result = _resolve(resolver, state, degree, power);
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

  test('모든 패턴 쌍은 두 범주 이상의 비대칭 배치 차이를 가진다', () {
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
}

GameState _stateFor(StagePattern pattern, String strategyId) {
  var state = pattern
      .toLevelDefinition(stageId: 'stage_balloon', stageTitle: '4. 풍선 터뜨리기')
      .createState(3);
  if (strategyId == 'sharp') {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(
      traits.selectSource(state, 'spike_source'),
    );
  }
  return state;
}

ShotResult _resolve(
  ShotResolver resolver,
  GameState state,
  int degree,
  double power,
) {
  final radians = degree * math.pi / 180;
  return resolver.resolve(
    state,
    ShotInput(
      direction: Vec2(math.cos(radians), math.sin(radians)),
      power: power,
      equippedTrait: state.equippedTrait,
    ),
  );
}

void _expectSharpEvidence(StagePattern pattern, ShotResult result) {
  expect(result.events, contains('balloon_popped'));
  expect(result.events, contains('sharpness_consumed'));
  expect(result.impacts.any((impact) => impact.entityId == 'balloon'), isTrue);
  final poppedId = pattern.patternId == 'stage_balloon_04'
      ? 'balloon_b'
      : 'balloon';
  final poppedBalloon = result.state.entityById(poppedId)!;
  expect(
    poppedBalloon.active,
    isFalse,
    reason: '${pattern.patternId}: ${result.events}',
  );
  expect(poppedBalloon.solid, isFalse);
  expect(poppedBalloon.visualState, 'popped');
  expect(result.state.equippedTrait, isNull);
  expect(result.state.entityById('active_ball'), isNull);

  if (pattern.patternId == 'stage_balloon_01' ||
      pattern.patternId == 'stage_balloon_02') {
    _expectFullCausalChain(result);
  }
  if (pattern.patternId == 'stage_balloon_04') {
    expect(
      result.events.where((event) => event == 'balloon_popped'),
      hasLength(1),
    );
    expect(
      result.events.where((event) => event == 'sharpness_consumed'),
      hasLength(1),
    );
    expect(result.events, contains('balloon_bounced'));
    final balloonBImpactIndex = result.impacts.indexWhere(
      (impact) => impact.entityId == 'balloon_b',
    );
    final primaryBalloonImpactIndex = result.impacts.indexWhere(
      (impact) => impact.entityId == 'balloon',
    );
    expect(balloonBImpactIndex, greaterThanOrEqualTo(0));
    expect(primaryBalloonImpactIndex, greaterThan(balloonBImpactIndex));

    final balloonBImpact = result.physicsEvents.firstWhere(
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetEntityId == 'balloon_b',
    );
    final balloonBPopped = result.physicsEvents.firstWhere(
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetEntityId == 'balloon_b' &&
          event.visualState == 'popped',
    );
    final sharpnessConsumed = result.physicsEvents.firstWhere(
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.visualState == 'sharpness_consumed',
    );
    final primaryBalloonImpact = result.physicsEvents.firstWhere(
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetEntityId == 'balloon',
    );
    expect(
      result.physicsEvents
          .where(
            (event) =>
                event.kind == PhysicsEventKind.impact &&
                event.targetEntityId == 'balloon_b',
          )
          .length,
      1,
    );
    expect(
      result.physicsEvents
          .where(
            (event) =>
                event.kind == PhysicsEventKind.stateChange &&
                event.targetEntityId == 'balloon_b' &&
                event.visualState == 'popped',
          )
          .length,
      1,
    );
    expect(
      result.physicsEvents
          .where(
            (event) =>
                event.kind == PhysicsEventKind.stateChange &&
                event.visualState == 'sharpness_consumed',
          )
          .length,
      1,
    );
    expect(
      balloonBImpact.pathIndex,
      lessThanOrEqualTo(balloonBPopped.pathIndex),
    );
    expect(
      balloonBPopped.pathIndex,
      lessThanOrEqualTo(sharpnessConsumed.pathIndex),
    );
    expect(
      sharpnessConsumed.pathIndex,
      lessThan(primaryBalloonImpact.pathIndex),
    );
    final untouched = result.state.entityById('balloon')!;
    expect(untouched.active, isTrue);
    expect(untouched.solid, isTrue);
    expect(untouched.position, const Vec2(150, 260));
    final popped = result.state.entityById('balloon_b')!;
    expect(popped.active, isFalse);
    expect(popped.solid, isFalse);
    expect(popped.position, const Vec2(250, 300));
    expect(
      result.impacts.any((impact) => impact.entityId == 'balloon'),
      isTrue,
    );
  }
}

void _expectBalloonBounceEvidence(StagePattern pattern, ShotResult result) {
  expect(result.events, contains('balloon_bounced'));
  expect(result.events, isNot(contains('balloon_popped')));
  final balloonId = pattern.patternId == 'stage_balloon_04'
      ? 'balloon_b'
      : 'balloon';
  final before = pattern.objects.firstWhere((object) => object.id == balloonId);
  final after = result.state.entityById(balloonId)!;
  expect(result.impacts.any((impact) => impact.entityId == balloonId), isTrue);
  expect(after.position, before.position);
  expect(after.active, before.active);
  expect(after.solid, before.solid);
  expect(after.visualState, before.visualState);
}

void _expectFullCausalChain(ShotResult result) {
  expect(result.events, contains('balloon_switch_revealed'));
  expect(result.events, contains('switch_pressed'));
  expect(result.events, contains('balloon_switch_pressed'));
  expect(result.events, contains('hole_entered'));
  final events = result.physicsEvents;
  final balloonImpact = _eventIndex(
    events,
    (event) =>
        event.kind == PhysicsEventKind.impact &&
        event.targetEntityId == 'balloon',
  );
  final popped = _eventIndex(
    events,
    (event) =>
        event.kind == PhysicsEventKind.stateChange &&
        event.targetEntityId == 'balloon' &&
        event.visualState == 'popped',
  );
  final revealed = _eventIndex(
    events,
    (event) =>
        event.kind == PhysicsEventKind.stateChange &&
        event.targetEntityId == 'balloon_switch' &&
        event.visualState == 'revealed',
  );
  final switchImpact = _eventIndex(
    events,
    (event) =>
        event.kind == PhysicsEventKind.impact &&
        event.targetEntityId == 'balloon_switch',
  );
  final opened = _eventIndex(
    events,
    (event) =>
        event.kind == PhysicsEventKind.stateChange &&
        event.targetEntityId == 'balloon_gate' &&
        event.visualState == 'open',
  );
  final holeImpact = _eventIndex(
    events,
    (event) =>
        event.kind == PhysicsEventKind.impact &&
        event.targetType == EntityType.hole,
  );
  final captured = _eventIndex(
    events,
    (event) =>
        event.kind == PhysicsEventKind.stateChange &&
        event.targetType == EntityType.hole &&
        event.visualState == 'captured',
  );

  expect(popped, greaterThan(balloonImpact));
  expect(revealed, greaterThan(popped));
  expect(switchImpact, greaterThan(revealed));
  expect(opened, greaterThan(switchImpact));
  expect(holeImpact, greaterThan(opened));
  expect(captured, greaterThan(holeImpact));
  expect(
    events.where((event) => event.kind == PhysicsEventKind.chainSafetyStop),
    isEmpty,
  );
}

void _expectOptionalChallenges(
  StagePattern pattern,
  Map<String, ShotResult> results,
) {
  final sharp = results['${pattern.patternId}/sharp']!;
  final none = results['${pattern.patternId}/none']!;
  for (final challenge in pattern.optionalChallenges) {
    switch (challenge) {
      case 'one_shot':
        expect(sharp.state.phase, GamePhase.success);
        expect(none.state.phase, GamePhase.success);
      case 'sharp_pop_chain':
        _expectFullCausalChain(sharp);
      case 'ordinary_balloon_bounce':
        _expectBalloonBounceEvidence(pattern, none);
      case 'sharp_pop_without_switch':
        expect(sharp.events, contains('balloon_popped'));
        expect(sharp.events, isNot(contains('switch_pressed')));
      case 'two_balloons_one_sharp':
        expect(
          sharp.events.where((event) => event == 'balloon_popped'),
          hasLength(1),
        );
        expect(sharp.events, contains('balloon_bounced'));
      default:
        fail('검증되지 않은 선택 도전입니다: $challenge');
    }
  }
}

int _eventIndex(List<PhysicsEvent> events, bool Function(PhysicsEvent) test) {
  final index = events.indexWhere(test);
  expect(index, greaterThanOrEqualTo(0));
  return index;
}

bool _isUiChargeTick(double power) {
  for (var index = 0; index <= 16; index++) {
    final tick = (0.12 + 0.055 * index).clamp(0.12, 1.0).toDouble();
    if ((power - tick).abs() < 0.000001) return true;
  }
  return false;
}

Set<String> _differenceCategories(StagePattern left, StagePattern right) {
  final categories = <String>{};
  if (left.ballSpawn != right.ballSpawn) categories.add('ball');
  for (final category in [
    'hole',
    'wall',
    'traitSources',
    'movable',
    'balloonLayout',
    'switchGateStructure',
  ]) {
    if (_categorySignature(left, category) !=
        _categorySignature(right, category)) {
      categories.add(category);
    }
  }
  return categories;
}

String _categorySignature(StagePattern pattern, String category) {
  Iterable<PatternObjectDefinition> objects;
  switch (category) {
    case 'hole':
      objects = pattern.objects.where(
        (object) => object.type == EntityType.hole,
      );
    case 'wall':
      objects = pattern.objects.where(
        (object) => object.type == EntityType.wall,
      );
    case 'traitSources':
      objects = pattern.objects.where((object) => object.traits.isNotEmpty);
    case 'movable':
      objects = pattern.objects.where((object) => object.movable);
    case 'balloonLayout':
      objects = pattern.objects.where(
        (object) => object.type == EntityType.balloon,
      );
    case 'switchGateStructure':
      objects = pattern.objects.where(
        (object) =>
            object.type == EntityType.switchPad ||
            object.type == EntityType.gate,
      );
    default:
      objects = const [];
  }
  return jsonEncode(objects.map((object) => object.toJson()).toList());
}
