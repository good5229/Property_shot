import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'fixtures/stage9_rotating_reflector_patterns.dart';

void main() {
  const resolver = ShotResolver();
  late StageCatalog catalog;
  late StageDefinition stage;

  setUpAll(() {
    catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_rotating_reflector');
  });

  test('9단계는 안정 ID·제목·패턴 4개·파 수를 정확히 보존한다', () {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    expect(
      catalog.stages.where(
        (candidate) => candidate.stageId == 'stage_rotating_reflector',
      ),
      hasLength(1),
    );
    expect(stage.title, '9. 판을 돌려 놓아라');
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_rotating_reflector_01',
      'stage_rotating_reflector_02',
      'stage_rotating_reflector_03',
      'stage_rotating_reflector_04',
    ]);
    expect(stage.patterns.map((pattern) => pattern.parShots), [2, 2, 2, 2]);
    expect(stage.patterns.every(_hasNonForcedSolutions), isTrue);
  });

  test('모든 패턴의 반사판과 벽은 고정·고체이고 정적 Validator를 통과한다', () {
    final validator = StagePatternValidator();
    final report = validator.validate(stage);
    expect(report.isValid, isTrue, reason: '${report.issues}');
    for (final pattern in stage.patterns) {
      expect(
        pattern.objects
            .where((object) => object.type == EntityType.rotatingReflector)
            .every(
              (reflector) =>
                  reflector.active && reflector.solid && !reflector.movable,
            ),
        isTrue,
        reason: pattern.patternId,
      );
      expect(
        pattern.objects
            .where((object) => object.type == EntityType.wall)
            .every((wall) => wall.solid && !wall.movable),
        isTrue,
        reason: pattern.patternId,
      );
    }
  });

  test('모든 패턴은 실제 실행 evidence를 포함한 동적 Validator를 통과한다', () {
    final validator = StagePatternValidator();
    final probe = ShotResolverPatternRuntimeProbe();
    for (final pattern in stage.patterns) {
      final evidence = probe.probe(stage: stage, pattern: pattern);
      final report = validator.validatePatternWithRuntimeEvidence(
        stage,
        pattern,
        evidence,
      );
      expect(
        report.isValid,
        isTrue,
        reason: '${pattern.patternId}: ${report.issues}',
      );
      expect(evidence.rotatorApplicable, isTrue, reason: pattern.patternId);
      expect(
        evidence.rotatorOrderViolation,
        isFalse,
        reason: pattern.patternId,
      );
      expect(evidence.wallMoved, isFalse, reason: pattern.patternId);
      expect(evidence.nonDeterministic, isFalse, reason: pattern.patternId);
    }
  });

  for (final solution in stage9RotatingReflectorSolutions) {
    test('${solution.patternId} 첫 샷 저장 뒤 재실행해도 둘째 샷 결과가 같다', () async {
      final backend = _MemoryRunStateBackend();
      final session = StagePatternSession(
        catalog: catalog,
        store: RunStateStore(backend: backend),
        now: () => DateTime.utc(2026, 8, 7, 9),
      );
      late StagePatternDraw draw;
      for (var attempt = 0; attempt < stage.patterns.length; attempt++) {
        draw = await session.selectStage(stage.stageId);
        if (draw.patternId == solution.patternId) break;
        await session.completeCurrentStage(
          stageId: stage.stageId,
          shotCount: 1,
        );
      }
      expect(draw.patternId, solution.patternId);
      final pattern = stage.patternById(draw.patternId);
      final first = resolver.resolve(_state(pattern), solution.firstInput);
      await session.recordShot(input: solution.firstInput);

      final resumed = StagePatternSession(
        catalog: catalog,
        store: RunStateStore(backend: backend),
      );
      final restoredDraw = await resumed.selectStage(stage.stageId);
      expect(restoredDraw.patternId, draw.patternId);
      var restoredState = _state(pattern);
      for (final saved in resumed.currentShotInputs) {
        restoredState = resolver
            .resolve(
              restoredState,
              ShotInput(
                direction: saved.direction,
                power: saved.power,
                equippedTrait: saved.equippedTrait,
              ),
            )
            .state;
      }
      for (final reflector in pattern.objects.where(
        (object) => object.type == EntityType.rotatingReflector,
      )) {
        expect(
          restoredState.entityById(reflector.id)?.reflectorOrientation,
          first.state.entityById(reflector.id)?.reflectorOrientation,
        );
        expect(
          restoredState.entityById(reflector.id)?.reflectorRotationCount,
          first.state.entityById(reflector.id)?.reflectorRotationCount,
        );
      }
      final continuousSecond = resolver.resolve(
        first.state,
        solution.secondInput,
      );
      final restoredSecond = resolver.resolve(
        restoredState,
        solution.secondInput,
      );
      expect(
        shotResultFingerprint(restoredSecond),
        shotResultFingerprint(continuousSecond),
      );
    });
  }

  for (final solution in stage9RotatingReflectorSolutions) {
    test('${solution.patternId} 대표 경로와 반사판 사건 순서를 재현한다', () {
      _expectUiInput(solution.firstDegree, solution.firstPower);
      _expectUiInput(solution.secondDegree, solution.secondPower);
      _expectUiInput(solution.directDegree, solution.directPower);
      final pattern = stage.patternById(solution.patternId);
      final initial = _state(pattern);
      final first = resolver.resolve(initial, solution.firstInput);
      final second = resolver.resolve(first.state, solution.secondInput);

      expect(first.state.phase, GamePhase.planning);
      expect(second.state.phase, GamePhase.success);
      expect(
        _rotationIds(first, second),
        solution.expectedRotationOrder,
        reason: '${first.events} → ${second.events}',
      );
      if (solution.expectedSecondRotationSource != null) {
        expect(
          second.reflectorRotations.map((rotation) => rotation.sourceEntityId),
          contains(solution.expectedSecondRotationSource),
        );
      }
      if (solution.expectedFirstSlider) {
        expect(first.powerSliderActivations, isNotEmpty);
        final sliderActivationIndex = first.physicsEvents.indexWhere(
          (event) => event.kind == PhysicsEventKind.powerSliderActivation,
        );
        final reflectorRotationIndex = first.physicsEvents.indexWhere(
          (event) => event.kind == PhysicsEventKind.reflectorRotation,
        );
        expect(sliderActivationIndex, greaterThanOrEqualTo(0));
        expect(reflectorRotationIndex, greaterThan(sliderActivationIndex));
      }
      _expectRotationContracts(first);
      _expectRotationContracts(second);
      _expectImpactBeforeRotation(first);
      _expectImpactBeforeRotation(second);
      _expectWallsUnchanged(initial, second.state);

      final direct = resolver.resolve(initial, solution.directInput);
      expect(direct.state.phase, GamePhase.success);
      expect(direct.reflectorRotations, isEmpty);
      expect(
        _fingerprint(direct),
        _fingerprint(resolver.resolve(initial, solution.directInput)),
      );
    });

    test('${solution.patternId} 첫 샷 뒤 반사판 방향·회전 수가 다음 샷에 유지된다', () {
      final pattern = stage.patternById(solution.patternId);
      final initial = _state(pattern);
      final first = resolver.resolve(initial, solution.firstInput);
      final second = resolver.resolve(first.state, solution.secondInput);
      for (final reflector in pattern.objects.where(
        (object) => object.type == EntityType.rotatingReflector,
      )) {
        final before = initial.entityById(reflector.id)!;
        final afterFirst = first.state.entityById(reflector.id)!;
        final afterSecond = second.state.entityById(reflector.id)!;
        expect(
          afterFirst.reflectorRotationCount,
          greaterThanOrEqualTo(before.reflectorRotationCount),
        );
        expect(
          afterSecond.reflectorRotationCount,
          greaterThanOrEqualTo(afterFirst.reflectorRotationCount),
        );
        expect(
          afterFirst.reflectorOrientation,
          (before.reflectorOrientation +
                  2 *
                      (afterFirst.reflectorRotationCount -
                          before.reflectorRotationCount)) %
              8,
        );
        expect(
          afterSecond.reflectorOrientation,
          (before.reflectorOrientation +
                  2 *
                      (afterSecond.reflectorRotationCount -
                          before.reflectorRotationCount)) %
              8,
        );
      }
    });
  }
}

bool _hasNonForcedSolutions(StagePattern pattern) {
  return pattern.acceptedStrategyIds.contains('none') &&
      pattern.solutionFamilies.length >= 2;
}

void _expectUiInput(int degree, double power) {
  expect(degree, inInclusiveRange(0, 359));
  expect(power, greaterThanOrEqualTo(0.12));
  expect((power * 50).roundToDouble(), closeTo(power * 50, 0.0001));
}

GameState _state(StagePattern pattern) => pattern
    .toLevelDefinition(
      stageId: 'stage_rotating_reflector',
      stageTitle: '9. 판을 돌려 놓아라',
    )
    .createState(8, productRules: true);

List<String> _rotationIds(ShotResult first, ShotResult second) => [
  for (final rotation in [
    ...first.reflectorRotations,
    ...second.reflectorRotations,
  ])
    rotation.reflectorEntityId,
];

void _expectRotationContracts(ShotResult result) {
  for (final rotation in result.reflectorRotations) {
    expect(rotation.orientationAfter, (rotation.orientationBefore + 2) % 8);
    expect(rotation.rotationCountAfter, rotation.rotationCountBefore + 1);
    expect(
      rotation.velocityBefore.dot(rotation.collisionNormal),
      lessThanOrEqualTo(0.001),
    );
  }
}

void _expectImpactBeforeRotation(ShotResult result) {
  for (final rotationEvent in result.physicsEvents.where(
    (event) => event.kind == PhysicsEventKind.reflectorRotation,
  )) {
    final impactIndex = result.physicsEvents.indexWhere(
      (event) => event.eventId == rotationEvent.parentEventId,
    );
    final rotationIndex = result.physicsEvents.indexOf(rotationEvent);
    expect(impactIndex, greaterThanOrEqualTo(0));
    expect(impactIndex, lessThan(rotationIndex));
    expect(rotationEvent.parentEventId, isNotNull);
  }
}

void _expectWallsUnchanged(GameState initial, GameState result) {
  for (final wall in initial.entities.where(
    (entity) => entity.type == EntityType.wall,
  )) {
    expect(result.entityById(wall.id)?.position, wall.position);
    expect(result.entityById(wall.id)?.movable, isFalse);
  }
}

String _fingerprint(ShotResult result) {
  final entities = result.state.entities
      .map(
        (entity) =>
            '${entity.id}:${entity.position.x.toStringAsFixed(4)},${entity.position.y.toStringAsFixed(4)}:'
            '${entity.reflectorOrientation}:${entity.reflectorRotationCount}:${entity.visualState}',
      )
      .join('|');
  final events = result.physicsEvents
      .map(
        (event) => '${event.kind.name}:${event.eventId}:${event.parentEventId}',
      )
      .join('|');
  return '${result.state.phase.name}|${result.events.join(',')}|$entities|$events';
}

class _MemoryRunStateBackend implements RunStateKeyValueBackend {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
