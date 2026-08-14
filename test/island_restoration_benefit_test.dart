import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/stage_discovery.dart';
import 'package:property_shot/game/hint/generated_hint_catalog.dart';
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

  testWidgets('24개 발견으로 시작한 실제 게임에는 세 시설 지원이 모두 연결된다', (tester) async {
    final records = <String>[];
    for (var stageIndex = 0; stageIndex < 8; stageIndex++) {
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

    for (final landmark in const ['observatory', 'lighthouse', 'bridge']) {
      final benefit = find.byKey(Key('island_benefit_$landmark'));
      expect(benefit, findsOneWidget);
      await tester.ensureVisible(benefit);
      await tester.pumpAndSettle();
    }
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
