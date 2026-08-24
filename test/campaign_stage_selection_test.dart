import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/campaign_stage_selection.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('캠페인 첫 학습 패턴 정책', () {
    testWidgets('진행 기록이 없는 캠페인 첫 시작은 stage_heavy_01을 연다', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        const PropertyShotApp(showHome: true, loadGameAssets: false),
      );
      await tester.pump();

      await tester.tap(find.byKey(const Key('start_game_button')));
      for (var index = 0; index < 20; index++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (find.byType(GameScreen).evaluate().isNotEmpty) break;
      }

      final screen = tester.widget<GameScreen>(find.byType(GameScreen));
      expect(screen.levelOverride?.patternId, 'stage_heavy_01');
    });

    test('최초 미클리어 1~10단계는 학습 파형 대상이다', () {
      for (
        var index = 0;
        index < generatedStageCatalog.stages.length;
        index++
      ) {
        expect(
          CampaignStageSelectionPolicy.shouldPreferTutorialBaseline(
            stageIndex: index,
            alreadyCleared: false,
          ),
          isTrue,
        );
        expect(
          CampaignStageSelectionPolicy.shouldPreferTutorialBaseline(
            stageIndex: index,
            alreadyCleared: true,
          ),
          isFalse,
        );
      }
    });

    test('10단계 fresh cycle은 learn→confirm→apply→mastery 순서를 따른다', () {
      for (final stage in generatedStageCatalog.stages) {
        var bag = StageShuffleBagState.initial(stage.stageId);
        final draws = <String>[];
        for (var index = 0; index < stage.patterns.length; index++) {
          final draw = CampaignStageSelectionPolicy.drawLearningWave(
            stage: stage,
            state: bag,
            rootSeed: 0x10203040,
          );
          draws.add(draw.patternId);
          expect(
            CampaignStageSelectionPolicy.roleFor(
              stageId: stage.stageId,
              patternId: draw.patternId,
            ),
            CampaignPatternRole.values[index],
          );
          bag = draw.nextState;
        }
        expect(
          draws,
          CampaignStageSelectionPolicy.learningWavePatternIds[stage.stageId],
        );
      }
    });

    test('baseline 우선 뒤에도 한 cycle의 네 패턴을 중복 없이 소비한다', () {
      final stage = generatedStageCatalog.stageById('stage_heavy');
      final first = CampaignStageSelectionPolicy.drawTutorialBaselineFirst(
        stage: stage,
        state: StageShuffleBagState.initial(stage.stageId),
        rootSeed: 77123,
      );
      final draws = <String>[first.patternId];
      var bag = first.nextState;

      for (var index = 0; index < 3; index++) {
        final next = StageShuffleBag.draw(
          stage: stage,
          state: bag,
          rootSeed: 77123,
        );
        draws.add(next.patternId);
        bag = next.nextState;
      }

      expect(
        draws.toSet(),
        stage.patterns.map((pattern) => pattern.patternId).toSet(),
      );
      expect(bag.cycle, 1);
      expect(bag.remainingPatternIds, isEmpty);
    });

    test('기존 first-cycle 중간 저장은 남은 순서를 다시 배열하지 않는다', () {
      const rootSeed = 13579;
      final stage = generatedStageCatalog.stageById('stage_balloon');
      final legacyFirst = StageShuffleBag.draw(
        stage: stage,
        state: StageShuffleBagState.initial(stage.stageId),
        rootSeed: rootSeed,
      );
      final expected = StageShuffleBag.draw(
        stage: stage,
        state: legacyFirst.nextState,
        rootSeed: rootSeed,
      );
      final actual = CampaignStageSelectionPolicy.drawLearningWave(
        stage: stage,
        state: legacyFirst.nextState,
        rootSeed: rootSeed,
      );

      expect(actual.toJson(), expected.toJson());
    });

    test('두 번째 cycle부터 공용 결정론 셔플과 완전히 동일하다', () {
      const rootSeed = 24680;
      final stage = generatedStageCatalog.stageById('stage_rotating_reflector');
      var bag = StageShuffleBagState.initial(stage.stageId);
      for (var index = 0; index < stage.patterns.length; index++) {
        bag = CampaignStageSelectionPolicy.drawLearningWave(
          stage: stage,
          state: bag,
          rootSeed: rootSeed,
        ).nextState;
      }

      final expected = StageShuffleBag.draw(
        stage: stage,
        state: bag,
        rootSeed: rootSeed,
      );
      final actual = CampaignStageSelectionPolicy.drawLearningWave(
        stage: stage,
        state: bag,
        rootSeed: rootSeed,
      );
      expect(actual.toJson(), expected.toJson());
    });

    test('재시도와 저장 재개는 이미 기록한 current draw를 유지한다', () async {
      final backend = MemoryRunStateBackend();
      final firstSession = _session(backend, rootSeed: 445566);
      final first = await firstSession.selectStage(
        'stage_heavy',
        drawPolicy: CampaignStageSelectionPolicy.drawTutorialBaselineFirst,
      );
      final retry = await firstSession.selectStage(
        'stage_heavy',
        drawPolicy: StageShuffleBag.draw,
      );
      final resumed = await _session(
        backend,
        rootSeed: 445566,
      ).selectStage('stage_heavy', drawPolicy: StageShuffleBag.draw);

      expect(retry.patternId, first.patternId);
      expect(retry.patternSeed, first.patternSeed);
      expect(resumed.patternId, first.patternId);
      expect(resumed.patternSeed, first.patternSeed);
    });

    test('클리어 후 재방문은 baseline을 다시 강제하지 않고 남은 bag을 쓴다', () async {
      final session = _session(MemoryRunStateBackend(), rootSeed: 998877);
      final first = await session.selectStage(
        'stage_heavy',
        drawPolicy: CampaignStageSelectionPolicy.drawTutorialBaselineFirst,
      );
      await session.completeCurrentStage(stageId: 'stage_heavy', shotCount: 2);
      final revisit = await session.selectStage('stage_heavy');

      expect(first.patternId, 'stage_heavy_01');
      expect(revisit.patternId, isNot(first.patternId));
      expect(revisit.drawIndex, 1);
    });

    test('다음 단계 선추첨도 baseline이며 진입 때 같은 draw를 복원한다', () async {
      final session = _session(MemoryRunStateBackend(), rootSeed: 123321);
      await session.selectStage(
        'stage_heavy',
        drawPolicy: CampaignStageSelectionPolicy.drawTutorialBaselineFirst,
      );
      await session.completeCurrentStage(
        stageId: 'stage_heavy',
        shotCount: 2,
        nextStageId: 'stage_bouncy',
        nextStageDrawPolicy:
            CampaignStageSelectionPolicy.drawTutorialBaselineFirst,
      );
      final predrawnId = session.state!.nextStagePatternId;
      final predrawnSeed = session.state!.nextStagePatternSeed;
      final opened = await session.selectStage(
        'stage_bouncy',
        drawPolicy: StageShuffleBag.draw,
      );

      expect(predrawnId, 'stage_bouncy_01');
      expect(opened.patternId, predrawnId);
      expect(opened.patternSeed, predrawnSeed);
    });

    test('정책을 넘기지 않는 일일 도전형 세션은 공용 draw와 동일하다', () async {
      const rootSeed = 20260809;
      final stage = generatedStageCatalog.stageById('stage_chain_gate');
      final expected = StageShuffleBag.draw(
        stage: stage,
        state: StageShuffleBagState.initial(stage.stageId),
        rootSeed: rootSeed,
      );
      final session = _session(MemoryRunStateBackend(), rootSeed: rootSeed);
      final actual = await session.selectStage(stage.stageId);

      expect(actual.patternId, expected.patternId);
      expect(actual.patternSeed, expected.patternSeed);
      expect(actual.nextState.toJson(), expected.nextState.toJson());
    });

    test('기존 저장 run은 새 캠페인 정책을 전달해도 current draw를 바꾸지 않는다', () async {
      final backend = MemoryRunStateBackend();
      final originalSession = _session(backend, rootSeed: 314159);
      final original = await originalSession.selectStage('stage_balloon');

      final restored = await _session(backend, rootSeed: 314159).selectStage(
        'stage_balloon',
        drawPolicy: CampaignStageSelectionPolicy.drawTutorialBaselineFirst,
      );

      expect(restored.patternId, original.patternId);
      expect(restored.patternSeed, original.patternSeed);
      expect(restored.nextState.toJson(), original.nextState.toJson());
    });
  });
}

StagePatternSession _session(
  RunStateKeyValueBackend backend, {
  required int rootSeed,
}) {
  return StagePatternSession(
    catalog: generatedStageCatalog,
    store: RunStateStore(backend: backend),
    fixedRootSeed: rootSeed,
    now: () => DateTime.utc(2026, 8, 9),
  );
}
