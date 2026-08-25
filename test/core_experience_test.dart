import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
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
        (entity) =>
            entity.active &&
            ((entity.type == EntityType.wall &&
                    !stageBoundaryWallIds.contains(entity.id)) ||
                (entity.type == EntityType.gate && !entity.open)),
      );
      for (final wall in blockers) {
        final clearance =
            state.activeBall.position.distanceTo(
              wall.hitBounds.nearestPoint(state.activeBall.position),
            ) -
            state.activeBall.hitRadius;
        expect(
          clearance,
          greaterThanOrEqualTo(defaultMinSpawnWallClearance - 0.001),
          reason: '${scene.patternId}/${wall.id}: 시작 공 주변 벽 여유 $clearance',
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
