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

import 'fixtures/stage_heavy_patterns.dart';

void main() {
  late StageCatalog catalog;
  late StageDefinition stage;

  setUpAll(() {
    catalog = StageCatalog.fromJsonString(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_heavy');
  });

  test('1단계는 안정 패턴 4개와 기준 패턴 1개를 갖는다', () {
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_heavy_01',
      'stage_heavy_02',
      'stage_heavy_03',
      'stage_heavy_04',
    ]);
    expect(
      stage.patterns
          .where(
            (pattern) =>
                pattern.metadata[StageCatalog.baselineMetadataKey] ==
                StageCatalog.baselineMetadataValue,
          )
          .map((pattern) => pattern.patternId),
      ['stage_heavy_01'],
    );
    expect(catalog.baselinePatternFor(stage).patternId, 'stage_heavy_01');
  });

  test('네 패턴은 튜토리얼 계약과 production 정적 검증을 유지한다', () {
    final report = StagePatternValidator().validate(stage);
    expect(report.isValid, isTrue, reason: report.issues.join('\n'));

    for (final pattern in stage.patterns) {
      expect(pattern.intendedStrategyId, 'anvil');
      expect(pattern.acceptedStrategyIds, containsAll(['none', 'anvil']));
      expect(pattern.solutionFamilies.length, greaterThanOrEqualTo(2));
      expect(pattern.optionalChallenges, isNotEmpty);
      expect(pattern.metadata, isNot(contains('required_reward')));
      expect(pattern.objects.any((object) => object.id == 'anvil'), isTrue);
      expect(
        pattern.objects.any(
          (object) => object.id == 'crate_a' && object.movable,
        ),
        isTrue,
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

  test('저장된 대표 입력은 none/anvil 실제 ShotResolver 성공을 재현한다', () {
    const resolver = ShotResolver();
    for (final fixture in stageHeavyRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
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
      expect(
        pattern.solutionFamilies,
        contains(fixture.familyId),
        reason: '${fixture.patternId}에 저장된 계열 ${fixture.familyId}가 없습니다.',
      );
      expect(
        _solutionFamiliesFor(result),
        contains(fixture.familyId),
        reason: '${fixture.patternId}/${fixture.strategyId} 실제 계열 근거 없음',
      );
      expect(result.chainSafetyDiagnostics, isEmpty);
      expect(result.events, isNot(contains('chain_safety_stop')));
    }
    for (final pattern in stage.patterns) {
      final coveredFamilies = stageHeavyRepresentatives
          .where((fixture) => fixture.patternId == pattern.patternId)
          .map((fixture) => fixture.familyId)
          .toSet();
      expect(
        coveredFamilies,
        containsAll(pattern.solutionFamilies),
        reason:
            '${pattern.patternId}의 모든 solutionFamilies를 대표 fixture가 덮지 못했습니다.',
      );
    }
  });

  test('대표 입력은 각도·파워 근방에서 여러 성공점을 갖는다', () {
    const resolver = ShotResolver();
    final nearCounts = <String, int>{};
    for (final fixture in stageHeavyRepresentatives) {
      final pattern = stage.patternById(fixture.patternId);
      final state = _stateFor(pattern, fixture.strategyId);
      var successCount = 0;
      for (final degreeDelta in [-2, 0, 2]) {
        for (final powerDelta in [-0.04, -0.02, 0, 0.02, 0.04]) {
          final result = resolver.resolve(
            state,
            ShotInput(
              direction: _directionFor(fixture.degree + degreeDelta),
              power: (fixture.power + powerDelta).clamp(0.05, 1.0),
              equippedTrait: state.equippedTrait,
            ),
          );
          if (result.state.phase == GamePhase.success) {
            successCount += 1;
          }
        }
      }
      expect(
        successCount,
        greaterThanOrEqualTo(3),
        reason:
            '${fixture.patternId}/${fixture.strategyId} 대표 근방 성공점=$successCount/15',
      );
      nearCounts['${fixture.patternId}/${fixture.strategyId}/${fixture.familyId}'] =
          successCount;
    }
    print(
      'stage_heavy 대표 근방 성공점: '
      '${nearCounts.entries.map((entry) => '${entry.key}=${entry.value}/15').join('; ')}',
    );
  });

  test('축소된 결정론 격자에서도 무거움 성공 영역이 항상 더 넓다', () {
    const resolver = ShotResolver();
    final counts = <String, ({int none, int anvil})>{};
    for (final pattern in stage.patterns) {
      final noneState = _stateFor(pattern, 'none');
      final anvilState = _stateFor(pattern, 'anvil');
      var none = 0;
      var anvil = 0;
      for (var degree = 0; degree < 360; degree += 4) {
        final direction = _directionFor(degree);
        for (var powerStep = 10; powerStep <= 50; powerStep += 5) {
          final power = powerStep / 50;
          final noneResult = resolver.resolve(
            noneState,
            ShotInput(direction: direction, power: power),
          );
          final anvilResult = resolver.resolve(
            anvilState,
            ShotInput(
              direction: direction,
              power: power,
              equippedTrait: TraitType.heavy,
            ),
          );
          if (noneResult.state.phase == GamePhase.success) none += 1;
          if (anvilResult.state.phase == GamePhase.success) anvil += 1;
        }
      }
      counts[pattern.patternId] = (none: none, anvil: anvil);
      expect(
        anvil,
        greaterThan(none),
        reason: '${pattern.patternId} 전략별 성공점 none=$none, anvil=$anvil',
      );
    }
    // QA 보고서에서 전략별 성공 영역 수를 바로 확인할 수 있게 남긴다.
    print(
      'stage_heavy 축소 격자 성공점: '
      '${counts.entries.map((entry) => '${entry.key} none=${entry.value.none}, '
          'anvil=${entry.value.anvil}').join('; ')}',
    );
    expect(counts, isNotEmpty);
  });

  test('같은 충돌 입력에서 무거움은 상자 이동량과 충격량을 바꾼다', () {
    const resolver = ShotResolver();
    for (final fixture in stageHeavyCollisionFixtures) {
      final pattern = stage.patternById(fixture.patternId);
      final noneState = _stateFor(pattern, 'none');
      final anvilState = _stateFor(pattern, 'anvil');
      final input = ShotInput(
        direction: fixture.direction,
        power: fixture.power,
      );
      final noneResult = resolver.resolve(noneState, input);
      final anvilResult = resolver.resolve(
        anvilState,
        ShotInput(
          direction: input.direction,
          power: input.power,
          equippedTrait: TraitType.heavy,
        ),
      );
      final initialCrate = pattern.objects.firstWhere(
        (object) => object.id == 'crate_a',
      );
      final noneCrate = noneResult.state.entityById('crate_a')!;
      final anvilCrate = anvilResult.state.entityById('crate_a')!;
      final noneImpact = noneResult.impacts.firstWhere(
        (impact) => impact.entityId == 'crate_a',
      );
      final anvilImpact = anvilResult.impacts.firstWhere(
        (impact) => impact.entityId == 'crate_a',
      );
      final noneDistance = noneCrate.position.distanceTo(initialCrate.position);
      final anvilDistance = anvilCrate.position.distanceTo(
        initialCrate.position,
      );
      expect(
        anvilDistance,
        greaterThan(noneDistance + 0.5),
        reason:
            '${fixture.patternId} 같은 입력의 상자 이동량 none=$noneDistance, anvil=$anvilDistance',
      );
      expect(
        anvilImpact.impulse,
        greaterThan(noneImpact.impulse),
        reason: '${fixture.patternId} 같은 입력의 충격량이 다르지 않음',
      );
    }
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
      .toLevelDefinition(stageId: 'stage_heavy', stageTitle: '1. 무거움 익히기')
      .createState(0);
  if (strategyId == 'anvil') {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(traits.selectSource(state, 'anvil'));
  }
  return state;
}

Set<String> _solutionFamiliesFor(ShotResult result) {
  final families = <String>{};
  final hasWallImpact = result.impacts.any(
    (impact) => impact.entityType == EntityType.wall,
  );
  if (hasWallImpact && result.events.contains('bounced')) {
    families.add('wall_reflection');
  }
  final hasCrateImpact = result.impacts.any(
    (impact) => impact.entityType == EntityType.crate,
  );
  if (hasCrateImpact && result.events.contains('crate_pushed')) {
    families.add('crate_push');
  }
  final hasWeightInteraction = result.impacts.any(
    (impact) =>
        impact.entityId == 'anvil' && impact.entityType == EntityType.weight,
  );
  if (hasWeightInteraction && result.events.contains('bounced')) {
    families.add('weight_interaction');
  }
  return families;
}

Vec2 _directionFor(int degree) {
  final radians = (degree % 360) * 3.141592653589793 / 180;
  return Vec2(math.cos(radians), math.sin(radians));
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

String _movableSignature(StagePattern pattern) {
  return pattern.objects
      .where((object) => object.movable)
      .map((object) => object.id)
      .toList()
      .join('|');
}

Set<String> _differenceCategories(StagePattern left, StagePattern right) {
  final differences = <String>{};
  if (left.ballSpawn != right.ballSpawn) differences.add('ballSpawn');
  if (_positionOf(left, 'hole') != _positionOf(right, 'hole')) {
    differences.add('hole');
  }
  if (_positionOf(left, 'anvil') != _positionOf(right, 'anvil')) {
    differences.add('anvil');
  }
  if (_positionOf(left, 'crate_a') != _positionOf(right, 'crate_a')) {
    differences.add('movable_position');
  }
  if (_wallSignature(left) != _wallSignature(right)) {
    differences.add('wall_structure');
  }
  if (_movableSignature(left) != _movableSignature(right)) {
    differences.add('movable_composition');
  }
  return differences;
}
