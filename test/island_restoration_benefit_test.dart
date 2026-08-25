import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/stage_discovery.dart';
import 'package:property_shot/game/analysis/island_restoration.dart';
import 'package:property_shot/game/hint/generated_hint_catalog.dart';
import 'package:property_shot/game/input/intent_assist_resolver.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/run_hint_state.dart';
import 'package:property_shot/game/run/run_reward.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameFeedback.resetForTesting();
  });
  tearDown(GameFeedback.resetForTesting);

  test('시설 보유와 이번 런의 집중 지원 사용을 구분한다', () {
    expect(
      islandRestorationSupportWasUsed(const [
        restorationBridgeSupplyMarker,
        restorationLighthouseAccessMarker,
        restorationObservatorySupportMarker,
      ]),
      isFalse,
    );
    for (final focus in const [
      restorationObservatoryFocusMarker,
      restorationLighthouseFocusMarker,
      restorationBridgeFocusMarker,
    ]) {
      expect(islandRestorationSupportWasUsed([focus]), isTrue);
    }
  });

  test('10개 스테이지에 실제 기믹별 집중 지원을 추천한다', () {
    final progress = IslandRestorationProgress(discoveryCount: 30);
    const expected = <IslandLandmark>[
      IslandLandmark.observatory,
      IslandLandmark.lighthouse,
      IslandLandmark.bridge,
      IslandLandmark.lighthouse,
      IslandLandmark.observatory,
      IslandLandmark.lighthouse,
      IslandLandmark.bridge,
      IslandLandmark.bridge,
      IslandLandmark.lighthouse,
      IslandLandmark.observatory,
    ];

    for (var index = 0; index < expected.length; index++) {
      final recommendation = recommendIslandSupportForStage(
        levelIndex: index,
        progress: progress,
      );
      expect(
        recommendation?.landmark,
        expected[index],
        reason: '${index + 1}단계',
      );
      expect(recommendation?.reason, isNotEmpty);
    }
  });

  test('복구되지 않은 시설은 추천하지 않고 잘못된 단계는 거부한다', () {
    final none = IslandRestorationProgress(discoveryCount: 0);
    expect(
      recommendIslandSupportForStage(levelIndex: 2, progress: none),
      isNull,
    );

    final observatoryOnly = IslandRestorationProgress(discoveryCount: 3);
    final fallback = recommendIslandSupportForStage(
      levelIndex: 2,
      progress: observatoryOnly,
    );
    expect(fallback?.landmark, IslandLandmark.observatory);
    expect(fallback?.reason, contains('다리 복구 전'));
    expect(
      () => recommendIslandSupportForStage(
        levelIndex: 10,
        progress: observatoryOnly,
      ),
      throwsArgumentError,
    );
  });

  test('세 복구 시설은 분석·즉시 L1·런당 복사 코어를 중복 없이 지급한다', () async {
    final backend = MemoryRunStateBackend();
    final session = _session(backend);
    await session.selectStage('stage_heavy');

    expect(
      await session.applyIslandRestorationBenefits(
        observatoryRestored: true,
        lighthouseRestored: false,
        bridgeRestored: false,
      ),
      isTrue,
    );
    expect(
      session.state!.acquiredRewards,
      contains(runRewardFailureCauseBoostId),
    );
    expect(
      RunRewardInventory(
        session.state!.acquiredRewards,
      ).failureCauseBoostEnabled,
      isTrue,
    );
    expect(session.currentHintEntitlement, isNull);
    expect(session.state!.cloneCoreCount, 0);

    expect(
      await session.applyIslandRestorationBenefits(
        observatoryRestored: true,
        lighthouseRestored: true,
        bridgeRestored: true,
      ),
      isTrue,
    );
    expect(session.state!.cloneCoreCount, 1);
    expect(
      session.state!.acquiredRewards,
      containsAll([
        restorationBridgeSupplyMarker,
        restorationLighthouseAccessMarker,
      ]),
    );
    expect(
      session.currentHintEntitlement!.sources,
      contains(HintEntitlementSource.restorationLighthouse),
    );

    expect(
      await session.applyIslandRestorationBenefits(
        observatoryRestored: true,
        lighthouseRestored: true,
        bridgeRestored: true,
      ),
      isFalse,
    );
    expect(session.state!.cloneCoreCount, 1);

    await session.completeCurrentStage(
      stageId: 'stage_heavy',
      shotCount: 1,
      optionalChallengeAchieved: false,
      nextStageId: 'stage_bouncy',
    );
    final rewards = await session.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    expect(rewards, hasLength(RunRewardCandidateGenerator.candidateCount));
    expect(
      rewards.map((reward) => reward.id),
      isNot(contains(runRewardFailureCauseBoostId)),
    );
    expect(
      rewards.map((reward) => reward.id),
      isNot(contains(runRewardNextStageHintAccessId)),
    );

    final restored = _session(backend);
    await restored.loadState();
    expect(restored.state!.cloneCoreCount, 1);
    expect(
      restored.currentHintEntitlement!.sources,
      contains(HintEntitlementSource.restorationLighthouse),
    );
  });

  test('등대 집중은 사용자 OFF를 존중하면서 표준 조준 보정만 강화한다', () {
    expect(
      effectiveIntentAssistStrength(
        configured: IntentAssistStrength.standard,
        difficulty: PlayerDifficulty.normal,
        acquiredRewards: const [restorationLighthouseAimMarker],
      ),
      IntentAssistStrength.comfortable,
    );
    expect(
      effectiveIntentAssistStrength(
        configured: IntentAssistStrength.off,
        difficulty: PlayerDifficulty.normal,
        acquiredRewards: const [restorationLighthouseAimMarker],
      ),
      IntentAssistStrength.off,
    );
  });

  test('선택 도전 3·6·9개는 복구 시설과 결합해 실전 지원을 한 번씩 보급한다', () async {
    final session = _session(MemoryRunStateBackend());
    await session.selectStage('stage_heavy');

    expect(
      await session.applyIslandRestorationBenefits(
        observatoryRestored: true,
        lighthouseRestored: true,
        bridgeRestored: true,
        optionalMasteryCount: 9,
      ),
      isTrue,
    );
    final inventory = RunRewardInventory(session.state!.acquiredRewards);
    expect(inventory.availableUseCount(runRewardFirstImpactGuideId), 1);
    expect(inventory.availableUseCount(runRewardShotCancelAssistId), 1);
    expect(session.state!.cloneCoreCount, 2);
    expect(
      session.state!.acquiredRewards,
      containsAll([
        restorationMasteryGuideMarker,
        restorationMasteryCancelMarker,
        restorationMasteryCoreMarker,
      ]),
    );

    expect(
      await session.applyIslandRestorationBenefits(
        observatoryRestored: true,
        lighthouseRestored: true,
        bridgeRestored: true,
        optionalMasteryCount: 9,
      ),
      isFalse,
    );
    expect(session.state!.cloneCoreCount, 2);
  });

  test('집중 지원은 복구 효과를 유지하며 런당 한 번만 강화한다', () async {
    final backend = MemoryRunStateBackend();

    final observatory = _session(backend);
    await observatory.selectStage('stage_heavy');
    expect(
      await observatory.applyIslandRestorationBenefits(
        observatoryRestored: true,
        lighthouseRestored: false,
        bridgeRestored: false,
        observatoryFocused: true,
      ),
      isTrue,
    );
    final observatoryInventory = RunRewardInventory(
      observatory.state!.acquiredRewards,
    );
    expect(observatoryInventory.failureCauseBoostEnabled, isTrue);
    expect(observatoryInventory.precisionChargeEnabled, isTrue);
    expect(
      await observatory.applyIslandRestorationBenefits(
        observatoryRestored: true,
        lighthouseRestored: false,
        bridgeRestored: false,
        observatoryFocused: true,
      ),
      isFalse,
    );

    final bridgeBackend = MemoryRunStateBackend();
    final bridge = _session(bridgeBackend);
    await bridge.selectStage('stage_heavy');
    await bridge.applyIslandRestorationBenefits(
      observatoryRestored: false,
      lighthouseRestored: false,
      bridgeRestored: true,
      bridgeFocused: true,
    );
    expect(bridge.state!.cloneCoreCount, 2);
    await bridge.applyIslandRestorationBenefits(
      observatoryRestored: true,
      lighthouseRestored: false,
      bridgeRestored: true,
      observatoryFocused: true,
    );
    expect(
      RunRewardInventory(bridge.state!.acquiredRewards).precisionChargeEnabled,
      isFalse,
      reason: '런 중에 지원 시설을 바꿔 강화 효과를 중복 누적하면 안 된다.',
    );
    expect(
      await bridge.applyIslandRestorationBenefits(
        observatoryRestored: false,
        lighthouseRestored: false,
        bridgeRestored: true,
        bridgeFocused: true,
      ),
      isFalse,
    );
    expect(bridge.state!.cloneCoreCount, 2);

    final lighthouseBackend = MemoryRunStateBackend();
    final lighthouse = _session(lighthouseBackend);
    await lighthouse.selectStage('stage_heavy');
    await lighthouse.applyIslandRestorationBenefits(
      observatoryRestored: false,
      lighthouseRestored: true,
      bridgeRestored: false,
      lighthouseFocused: true,
    );
    expect(lighthouse.currentHintEntitlement!.unlockedHintLevel, 2);
    expect(
      lighthouse.state!.acquiredRewards,
      contains(restorationLighthouseAimMarker),
    );
    expect(
      lighthouse.currentHintEntitlement!.sources,
      contains(HintEntitlementSource.restorationLighthouse),
    );
  });

  test('섬 지원 저장은 손상된 값을 정리하고 정상 값만 복원한다', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = IslandSupportStore(preferences);
    await preferences.setString(IslandSupportStore.storageKey, 'unknown');
    expect(store.load(), isNull);
    expect(preferences.containsKey(IslandSupportStore.storageKey), isFalse);

    await store.save(IslandLandmark.lighthouse);
    expect(IslandSupportStore(preferences).load(), IslandLandmark.lighthouse);
  });

  testWidgets('15개 발견으로 시작한 실제 게임에는 세 시설 지원이 모두 연결된다', (tester) async {
    final records = <String>[];
    for (var stageIndex = 0; stageIndex < 5; stageIndex++) {
      for (final milestoneId in stageDiscoveryMilestoneIds(stageIndex)) {
        records.add('${levels[stageIndex].id}::$milestoneId');
      }
    }
    SharedPreferences.setMockInitialValues(<String, Object>{
      ProgressStore.discoveryRecordsKey: records,
    });

    await tester.pumpWidget(
      const PropertyShotApp(showHome: true, loadGameAssets: false),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.initialState!.copyCoreCount, 1);
    expect(
      screen.initialAcquiredRewards,
      containsAll([
        runRewardFailureCauseBoostId,
        restorationBridgeSupplyMarker,
      ]),
    );
    expect(
      screen.initialHintEntitlement!.sources,
      contains(HintEntitlementSource.restorationLighthouse),
    );
  });

  testWidgets('섬 지도는 세 복구 효과를 모두 설명하고 작은 화면에서도 스크롤된다', (tester) async {
    final records = <String>[];
    for (var stageIndex = 0; stageIndex < 8; stageIndex++) {
      for (final milestoneId in stageDiscoveryMilestoneIds(stageIndex)) {
        records.add('${levels[stageIndex].id}::$milestoneId');
      }
    }
    SharedPreferences.setMockInitialValues(<String, Object>{
      ProgressStore.discoveryRecordsKey: records,
    });
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const PropertyShotApp(showHome: true, loadGameAssets: false),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('island_restoration_expand')));
    await tester.pumpAndSettle();

    for (final landmark in const ['observatory', 'lighthouse', 'bridge']) {
      final benefit = find.byKey(Key('island_benefit_$landmark'));
      expect(benefit, findsOneWidget);
      await tester.ensureVisible(benefit);
      await tester.pumpAndSettle();
    }
    final focus = find.byKey(const Key('island_focus_lighthouse'));
    expect(focus, findsOneWidget);
    await tester.ensureVisible(focus);
    await tester.tap(focus);
    await _pumpForAsyncWork(tester);
    expect(
      IslandSupportStore(await SharedPreferences.getInstance()).load(),
      IslandLandmark.lighthouse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('복구하지 않은 시설은 집중 선택지로 노출되지 않는다', (tester) async {
    final records = <String>[];
    for (var stageIndex = 0; stageIndex < 2; stageIndex++) {
      for (final milestoneId in stageDiscoveryMilestoneIds(stageIndex)) {
        records.add('${levels[stageIndex].id}::$milestoneId');
      }
    }
    SharedPreferences.setMockInitialValues(<String, Object>{
      ProgressStore.discoveryRecordsKey: records,
    });
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const PropertyShotApp(showHome: true, loadGameAssets: false),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('island_restoration_expand')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('island_focus_observatory')), findsOneWidget);
    expect(find.byKey(const Key('island_focus_lighthouse')), findsNothing);
    expect(find.byKey(const Key('island_focus_bridge')), findsNothing);
  });

  testWidgets('주간 재도전의 기믹에 맞는 지원 이유를 보여 주되 자동 선택하지 않는다', (tester) async {
    final records = <String>[];
    for (var stageIndex = 0; stageIndex < 8; stageIndex++) {
      for (final milestoneId in stageDiscoveryMilestoneIds(stageIndex)) {
        records.add('${levels[stageIndex].id}::$milestoneId');
      }
    }
    SharedPreferences.setMockInitialValues(<String, Object>{
      ProgressStore.discoveryRecordsKey: records,
    });
    await tester.binding.setSurfaceSize(const Size(800, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      PropertyShotApp(
        showHome: true,
        loadGameAssets: false,
        weeklyReferenceDate: DateTime(2026, 8, 25),
      ),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    final recommendation = find.byKey(const Key('island_focus_recommendation'));
    expect(recommendation, findsOneWidget);
    expect(
      find.descendant(
        of: recommendation,
        matching: find.textContaining('추천 ·'),
      ),
      findsOneWidget,
    );
    expect(
      IslandSupportStore(await SharedPreferences.getInstance()).load(),
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

StagePatternSession _session(RunStateKeyValueBackend backend) =>
    StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: backend),
      fixedRootSeed: 0x24681357,
      fixedRunId: 'restoration-benefit-fixture',
      fixedResolverVersion: 'shot-resolver-v1',
      hintVersionResolver: (stageId, patternId) => generatedHintCatalog
          .entryFor(stageId: stageId, patternId: patternId)
          .hintVersion,
    );

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
