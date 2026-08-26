import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/core_experience_screen.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/play_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/stage_drained_patterns.dart';
import 'fixtures/stage_persistent_patterns.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('핵심 체험은 검증된 서로 다른 세 장면을 고정 순서로 사용한다', () {
    expect(coreExperienceScenes, hasLength(3));
    expect(coreExperienceScenes.map((scene) => scene.patternId), <String>[
      'stage_heavy_01',
      'stage_drained_01',
      'stage_persistent_01',
    ]);
    expect(
      coreExperienceScenes.map((scene) => scene.patternId).toSet(),
      hasLength(3),
    );

    for (final scene in coreExperienceScenes) {
      final level = scene.createLevel();
      final state = level.createState(scene.levelIndex, productRules: true);
      final hole = state.entities.singleWhere(
        (entity) => entity.type == EntityType.hole,
      );

      expect(level.stageId, scene.stageId);
      expect(level.patternId, scene.patternId);
      expect(state.phase, GamePhase.planning);
      expect(
        state.activeBall.position.distanceTo(hole.position),
        greaterThan((state.activeBall.size.x + hole.size.x) / 2),
        reason: '${scene.patternId}은 입력 전 자동 클리어 상태여서는 안 된다.',
      );
      final blockers = state.entities.where(
        (entity) => entity.active && entity.id != state.activeBall.id,
      );
      for (final object in blockers) {
        final clearance =
            state.activeBall.position.distanceTo(
              object.hitBounds.nearestPoint(state.activeBall.position),
            ) -
            state.activeBall.hitRadius;
        expect(
          clearance,
          greaterThanOrEqualTo(defaultMinSpawnObjectClearance - 0.001),
          reason: '${scene.patternId}/${object.id}: 시작 공 주변 기물 여유 $clearance',
        );
      }
    }
  });

  test('홀 우회만으로는 장면을 완료하지 않고 각 장면의 실제 기믹 증거를 요구한다', () {
    const resolver = ShotResolver();
    const traits = TraitResolver();

    final heavyScene = coreExperienceScenes[0];
    final heavyLevel = heavyScene.createLevel();
    final heavyBase = heavyLevel.createState(
      heavyScene.levelIndex,
      productRules: true,
    );
    const heavyBypassInput = ShotInput(direction: Vec2(0, -1), power: 1);
    final heavyBypassResult = resolver.resolve(heavyBase, heavyBypassInput);
    expect(heavyBypassResult.state.phase, isNot(GamePhase.success));
    expect(
      heavyScene
          .evaluateObjective([heavyBypassResult], [heavyBypassInput])
          .satisfied,
      isFalse,
    );
    final heavyPrepared = traits.transferSelectedTrait(
      traits.selectSource(heavyBase, 'anvil'),
    );
    final heavyInput = ShotInput(
      direction: const Vec2(0, -1),
      power: 1,
      equippedTrait: heavyPrepared.equippedTrait,
    );
    final heavyResult = resolver.resolve(heavyPrepared, heavyInput);
    expect(
      heavyResult.state.phase,
      GamePhase.success,
      reason: 'events=${heavyResult.events}, path=${heavyResult.path.last}',
    );
    expect(heavyResult.events, containsAll(['crate_pushed', 'switch_pressed']));
    expect(heavyResult.state.entityById('core_weight_switch')!.pressed, isTrue);
    expect(heavyResult.state.entityById('core_gate')!.open, isTrue);
    expect(
      heavyScene.evaluateObjective([heavyResult], [heavyInput]).satisfied,
      isTrue,
    );

    final drainedScene = coreExperienceScenes[1];
    final drainedBase = drainedScene.createLevel().createState(
      drainedScene.levelIndex,
      productRules: true,
    );
    final drainedBypass = stageDrainedAlternativeSolutions.first;
    final drainedBypassInput = ShotInput(
      direction: drainedBypass.direction,
      power: drainedBypass.power,
    );
    final drainedBypassResult = resolver.resolve(
      drainedBase,
      drainedBypassInput,
    );
    expect(drainedBypassResult.state.phase, GamePhase.success);
    expect(
      drainedScene
          .evaluateObjective([drainedBypassResult], [drainedBypassInput])
          .satisfied,
      isFalse,
    );
    final drainedPrepared = traits.transferSelectedTrait(
      traits.selectSource(drainedBase, 'drain_weight'),
    );
    final drainedSolve = stageDrainedRepresentativeSolutions.first;
    final drainedInput = ShotInput(
      direction: drainedSolve.direction,
      power: drainedSolve.power,
      equippedTrait: drainedPrepared.equippedTrait,
    );
    final drainedResult = resolver.resolve(drainedPrepared, drainedInput);
    expect(drainedResult.state.phase, GamePhase.success);
    expect(
      drainedScene.evaluateObjective([drainedResult], [drainedInput]).satisfied,
      isTrue,
    );

    final persistentScene = coreExperienceScenes[2];
    final persistentBase = persistentScene.createLevel().createState(
      persistentScene.levelIndex,
      productRules: true,
    );
    final direct = stagePersistentAlternativeSolutions.first;
    final directResult = resolver.resolve(persistentBase, direct.firstInput);
    expect(directResult.state.phase, GamePhase.success);
    expect(
      persistentScene
          .evaluateObjective([directResult], [direct.firstInput])
          .satisfied,
      isFalse,
    );
    final chain = stagePersistentRepresentativeSolutions.first;
    final first = resolver.resolve(persistentBase, chain.firstInput);
    final second = resolver.resolve(first.state, chain.secondInput);
    expect(second.state.phase, GamePhase.success);
    expect(
      persistentScene
          .evaluateObjective(
            [first, second],
            [chain.firstInput, chain.secondInput],
          )
          .satisfied,
      isTrue,
    );
  });

  test('무거운 공이 같은 상자를 연속해서 밀 때 정지·순간이동·역주행이 없다', () {
    const resolver = ShotResolver();
    const traits = TraitResolver();
    final scene = coreExperienceScenes.first;
    final base = scene.createLevel().createState(
      scene.levelIndex,
      productRules: true,
    );
    final prepared = traits.transferSelectedTrait(
      traits.selectSource(base, 'anvil'),
    );
    final result = resolver.resolve(
      prepared,
      ShotInput(
        direction: scene.initialAimDirection,
        power: 1,
        equippedTrait: prepared.equippedTrait,
      ),
    );
    final crateMoves = result.moves
        .where((move) => move.entityId == 'crate_a')
        .toList();
    expect(crateMoves.length, greaterThanOrEqualTo(2));

    for (final framesPerSecond in [30, 45, 60]) {
      var finished = false;
      final game = PropertyShotGame(
        result.state,
        loadVisualAssets: false,
        onAnimationFinished: () => finished = true,
      );
      game.setStateSnapshot(
        result.state,
        path: result.path,
        transitionStart: prepared,
        moves: result.moves,
        impacts: result.impacts,
        physicsEvents: result.physicsEvents,
        animationTransaction: true,
      );
      var previous = game.animatedEntityPositionForTest('crate_a');
      var maximumFrameStep = 0.0;
      var started = false;
      var stoppedBeforeFinish = false;

      for (var frame = 0; frame < 4000 && !finished; frame++) {
        game.update(1 / framesPerSecond);
        final current = game.animatedEntityPositionForTest('crate_a');
        final step = current.distanceTo(previous);
        maximumFrameStep = math.max(maximumFrameStep, step);
        expect(
          current.y,
          lessThanOrEqualTo(previous.y + 0.05),
          reason: '$framesPerSecond FPS에서 상자가 충돌 분리 좌표로 역주행함',
        );
        if (step > 0.05) {
          expect(
            stoppedBeforeFinish,
            isFalse,
            reason: '$framesPerSecond FPS에서 멈춘 상자가 다시 움직임',
          );
          started = true;
        } else if (started &&
            current.distanceTo(result.state.entityById('crate_a')!.position) >
                0.2) {
          stoppedBeforeFinish = true;
        }
        previous = current;
      }

      expect(finished, isTrue);
      expect(maximumFrameStep, lessThanOrEqualTo(10));
      expect(
        previous.distanceTo(result.state.entityById('crate_a')!.position),
        lessThan(0.01),
      );
      game.onRemove();
    }
  });

  test('핵심 체험 첫 충돌에서 상자가 공보다 큰 전달 속도로 먼저 밀려난다', () {
    const resolver = ShotResolver();
    const traits = TraitResolver();
    final scene = coreExperienceScenes.first;
    final base = scene.createLevel().createState(
      scene.levelIndex,
      productRules: true,
    );
    final prepared = traits.transferSelectedTrait(
      traits.selectSource(base, 'anvil'),
    );
    final result = resolver.resolve(
      prepared,
      ShotInput(
        direction: scene.initialAimDirection,
        power: 1,
        equippedTrait: prepared.equippedTrait,
      ),
    );
    final crateMove = result.moves.firstWhere(
      (move) => move.entityId == 'crate_a' && move.initialVelocity.length > 0,
    );
    final crateImpact = result.impacts.firstWhere(
      (impact) =>
          impact.entityId == 'crate_a' &&
          impact.sourceEntityId == 'active_ball',
    );
    final nextPathIndex = math.min(
      crateImpact.pathIndex + 1,
      result.path.length - 1,
    );
    final ballPostImpactStep = result.path[nextPathIndex].distanceTo(
      result.path[crateImpact.pathIndex],
    );

    expect(crateMove.normalImpulse, greaterThan(0));
    expect(crateMove.initialVelocity.length, greaterThan(ballPostImpactStep));
    final moveEvent = result.physicsEvents.firstWhere(
      (event) => event.move == crateMove,
    );
    expect(moveEvent.impulse, crateMove.normalImpulse);
    expect(moveEvent.resultingVelocity, crateMove.initialVelocity);

    final game = PropertyShotGame(result.state, loadVisualAssets: false);
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: prepared,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
      animationTransaction: true,
    );
    final holeImpactCursor = game.activeBallHoleImpactCursorForTest;
    expect(holeImpactCursor, greaterThanOrEqualTo(0));
    var verifiedDelayedVisualCapture = false;
    for (
      var cursor = holeImpactCursor + 0.25;
      cursor < math.min(holeImpactCursor + 8, game.animationEndCursorForTest);
      cursor += 0.25
    ) {
      game.setAnimationCursorForReplay(cursor);
      final ballPosition = game.animatedEntityPositionForTest('active_ball');
      final holePosition = result.state.entityById('hole')!.position;
      if (ballPosition.distanceTo(holePosition) <= 0.5) continue;
      verifiedDelayedVisualCapture = true;
      expect(
        game.animatedBallCaptureProgressForTest,
        0,
        reason: '상자를 밀며 홀에 아직 도착하지 않은 공은 작아지면 안 된다.',
      );
    }
    expect(
      verifiedDelayedVisualCapture,
      isTrue,
      reason: '판정상 홀 접촉 뒤에도 상자를 미는 화면 구간을 회귀 검증해야 한다.',
    );
    game.setAnimationCursorForReplay(game.animationEndCursorForTest);
    expect(
      game.animatedEntityPositionForTest('active_ball').distanceTo(
        result.state.entityById('hole')!.position,
      ),
      lessThanOrEqualTo(0.5),
    );
    expect(
      game.animatedBallCaptureProgressForTest,
      greaterThan(0),
      reason: '공이 화면상 홀에 도착한 뒤의 포획 축소 연출은 유지해야 한다.',
    );
    game.setAnimationCursorForTest(crateMove.triggerPathIndex.toDouble());
    game.setAnimationCursorForTest(crateMove.triggerPathIndex + 0.5);
    final ballAfter = game.animatedEntityPositionForTest('active_ball');
    final crateAfter = game.animatedEntityPositionForTest('crate_a');
    final contactNormal = crateImpact.normal.normalized();
    final requiredSeparation =
        prepared.entityById('active_ball')!.hitRadius +
        prepared.entityById('crate_a')!.hitRadius;
    expect(
      (ballAfter - crateAfter).dot(contactNormal),
      greaterThanOrEqualTo(requiredSeparation - 0.2),
      reason: '접촉 직후 공은 접촉 법선의 상자 뒤쪽에 있어야 한다.',
    );
    for (
      var cursor = crateMove.triggerPathIndex.toDouble();
      cursor < game.animationEndCursorForTest;
      cursor += 0.25
    ) {
      game.setAnimationCursorForTest(cursor);
      final cratePosition = game.animatedEntityPositionForTest('crate_a');
      final ballPosition = game.animatedEntityPositionForTest('active_ball');
      game.setAnimationCursorForTest(cursor + 0.1);
      final crateNext = game.animatedEntityPositionForTest('crate_a');
      if (crateNext.distanceTo(cratePosition) <= 0.001) continue;
      final relative = ballPosition - cratePosition;
      final normalSeparation = relative.dot(contactNormal);
      final tangent = relative - contactNormal * normalSeparation;
      if (tangent.length < requiredSeparation) {
        expect(
          normalSeparation,
          greaterThanOrEqualTo(requiredSeparation - 0.2),
          reason: '상자가 움직이는 동안 공이 상자를 관통해 앞에 나오면 안 된다.',
        );
      }
    }
    game.onRemove();
  });

  test('첫 장면은 UI 전체 조준 격자에서 무속성 홀 우회를 허용하지 않는다', () {
    const resolver = ShotResolver();
    final scene = coreExperienceScenes.first;
    final initial = scene.createLevel().createState(
      scene.levelIndex,
      productRules: true,
    );
    var clearCount = 0;

    for (var degree = 0; degree < 360; degree += 2) {
      final radians = degree * math.pi / 180;
      final direction = Vec2(math.cos(radians), math.sin(radians));
      for (var powerPercent = 12; powerPercent <= 100; powerPercent += 2) {
        final result = resolver.resolve(
          initial,
          ShotInput(direction: direction, power: powerPercent / 100),
        );
        if (result.state.phase == GamePhase.success) clearCount += 1;
      }
    }

    expect(clearCount, 0);
  });

  testWidgets('홈의 최상위 핵심 체험 버튼이 저장과 분리된 실제 게임 화면을 연다', (tester) async {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    await tester.pumpWidget(
      PropertyShotApp(showHome: true, telemetry: telemetry),
    );
    await tester.pump();

    expect(find.byKey(const Key('core_experience_button')), findsOneWidget);
    expect(find.text('60초 핵심 체험'), findsOneWidget);

    await tester.tap(find.byKey(const Key('core_experience_button')));
    await tester.pump();

    expect(find.byType(CoreExperienceScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(
      game.progressPersistencePolicy,
      GameProgressPersistencePolicy.disabled,
    );
    expect(game.sequencePosition, 0);
    expect(game.sequenceLength, 3);
    expect(game.intentAssistPolicyOverride?.preserveRawTrajectory, isTrue);
    expect(game.initialState?.aimDirection, const Vec2(0, -1));
    expect(game.objectiveOverride, contains('핵심 체험 1/3'));
    expect(game.showDiscoveryHud, isFalse);
    expect(
      telemetry.events.any(
        (event) => event['event_code'] == 'judge_journey_started',
      ),
      isTrue,
    );
  });

  testWidgets('핵심 체험 완료 뒤 첫 항해와 섬 변화 순서를 이미지로 안내한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: buildJudgeJourneyStepsForTesting())),
    );
    await tester.pump();

    expect(find.byKey(const Key('judge_journey_steps')), findsOneWidget);
    expect(find.text('핵심 규칙'), findsOneWidget);
    expect(find.text('첫 항해'), findsOneWidget);
    expect(find.text('섬 변화'), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('각 핵심 장면은 현재 순서와 다음 행동을 명확히 표시한다', (tester) async {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    await tester.pumpWidget(
      MaterialApp(
        home: CoreExperienceScreen(
          initialSceneIndex: 2,
          loadGameAssets: false,
          onExit: () {},
          onContinueCampaign: () {},
          telemetry: telemetry,
        ),
      ),
    );
    await tester.pump();

    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(game.sequencePosition, 2);
    expect(game.sequenceLength, 3);
    expect(game.nextActionLabel, '체험 마치기');
    expect(game.objectiveOverride, contains('핵심 체험 3/3'));
    expect(game.objectiveOverride, contains('남겨 둔 첫 공'));
    expect(
      find.byKey(const Key('persistent_objective_banner')),
      findsOneWidget,
    );
    expect(
      telemetry.events.any(
        (event) => event['event_code'] == 'core_scene_entered',
      ),
      isTrue,
    );
  });
}
