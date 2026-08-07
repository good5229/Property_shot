import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/run_state.dart';
import 'package:property_shot/game/run/run_reward.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  test('진행 중인 8단계 패턴은 앱 재시작 뒤 같은 seed로 복원된다', () async {
    final backend = _MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    final firstSession = _session(store);

    final first = await firstSession.selectStage('stage_chain_score');
    final revisionAfterDraw = store.lastRevision;
    final restoredStore = RunStateStore(backend: backend);
    final restored = await _session(
      restoredStore,
    ).selectStage('stage_chain_score');

    expect(restored.patternId, first.patternId);
    expect(restored.patternSeed, first.patternSeed);
    expect(restored.drawIndex, first.drawIndex);
    expect(restored.cycle, first.cycle);
    expect(restoredStore.lastRevision, revisionAfterDraw);
  });

  test('8단계 셔플 백은 네 패턴을 중복 없이 소비하고 경계 중복을 막는다', () async {
    final store = RunStateStore(backend: _MemoryRunStateBackend());
    final session = _session(store);
    final draws = <String>[];

    for (var index = 0; index < 4; index++) {
      final draw = await session.selectStage('stage_chain_score');
      draws.add(draw.patternId);
      await session.completeCurrentStage(
        stageId: 'stage_chain_score',
        shotCount: 2,
        chainScore: 1700 + index,
        optionalChallengeAchieved: index == 0,
      );
    }

    expect(draws.toSet(), {
      'stage_chain_score_01',
      'stage_chain_score_02',
      'stage_chain_score_03',
      'stage_chain_score_04',
    });
    final nextCycle = await session.selectStage('stage_chain_score');
    expect(nextCycle.patternId, isNot(draws.last));
    expect(nextCycle.cycle, 1);
    await session.completeCurrentStage(
      stageId: 'stage_chain_score',
      shotCount: 3,
      chainScore: 1200,
    );

    final state = session.state!;
    expect(state.chainScoresPerStage['stage_chain_score'], 1703);
    expect(state.shotsPerStage['stage_chain_score'], 2);
    expect(
      state.optionalChallenges['stage_chain_score:${draws.first}'],
      isTrue,
    );
    expect(state.patternDrawHistory, hasLength(5));
  });

  test('완료 저장 뒤 재시작하면 다음 8단계 패턴을 한 번만 추첨한다', () async {
    final backend = _MemoryRunStateBackend();
    final firstStore = RunStateStore(backend: backend);
    final firstSession = _session(firstStore);
    final first = await firstSession.selectStage('stage_chain_score');
    await firstSession.completeCurrentStage(
      stageId: 'stage_chain_score',
      shotCount: 2,
      chainScore: 2022,
      optionalChallengeAchieved: true,
    );

    final secondStore = RunStateStore(backend: backend);
    final secondSession = _session(secondStore);
    final second = await secondSession.selectStage('stage_chain_score');
    final revisionAfterDraw = secondStore.lastRevision;
    final restoredStore = RunStateStore(backend: backend);
    final restored = await _session(
      restoredStore,
    ).selectStage('stage_chain_score');

    expect(second.patternId, isNot(first.patternId));
    expect(restored.patternId, second.patternId);
    expect(restored.patternSeed, second.patternSeed);
    expect(restoredStore.lastRevision, revisionAfterDraw);
  });

  test('다음 단계 패턴은 클리어 직후 선추첨하고 버튼 진입 때 재사용한다', () async {
    final backend = _MemoryRunStateBackend();
    final firstSession = _session(RunStateStore(backend: backend));
    await firstSession.selectStage('stage_heavy');
    await firstSession.completeCurrentStage(
      stageId: 'stage_heavy',
      nextStageId: 'stage_bouncy',
      shotCount: 2,
    );

    final completed = firstSession.state!;
    final predrawnPatternId = completed.nextStagePatternId;
    final predrawnPatternSeed = completed.nextStagePatternSeed;
    expect(completed.nextStageId, 'stage_bouncy');
    expect(predrawnPatternId, startsWith('stage_bouncy_'));
    expect(completed.patternDrawHistory, hasLength(2));
    await firstSession.completeCurrentStage(
      stageId: 'stage_heavy',
      nextStageId: 'stage_bouncy',
      shotCount: 1,
      chainScore: 2100,
    );
    expect(firstSession.state?.nextStagePatternId, predrawnPatternId);
    expect(firstSession.state?.nextStagePatternSeed, predrawnPatternSeed);
    expect(firstSession.state?.patternDrawHistory, hasLength(2));
    expect(firstSession.state?.shotsPerStage['stage_heavy'], 1);
    expect(firstSession.state?.chainScoresPerStage['stage_heavy'], 2100);

    final resumedSession = _session(RunStateStore(backend: backend));
    final activated = await resumedSession.selectStage('stage_bouncy');
    expect(activated.patternId, predrawnPatternId);
    expect(activated.patternSeed, predrawnPatternSeed);
    expect(resumedSession.state?.nextStageId, isNull);
    expect(resumedSession.state?.patternDrawHistory, hasLength(2));

    final restored = await _session(
      RunStateStore(backend: backend),
    ).selectStage('stage_bouncy');
    expect(restored.patternId, predrawnPatternId);
    expect(restored.patternSeed, predrawnPatternSeed);
  });

  test('발사 기록은 앱 재시작 뒤 속성 행동과 순서를 그대로 복원한다', () async {
    final backend = _MemoryRunStateBackend();
    final first = _session(RunStateStore(backend: backend));
    final draw = await first.selectStage('stage_chain_score');
    final source = draw.pattern.objects.firstWhere(
      (object) => object.traits.isNotEmpty,
    );
    final sourceId = source.id;
    await first.recordTraitAction(
      sourceId: sourceId,
      action: RunTraitAction.transfer,
    );
    await first.recordShot(
      input: ShotInput(
        direction: const Vec2(3, -4),
        power: 0.62,
        equippedTrait: source.traits.first,
      ),
    );
    await first.recordShot(
      input: const ShotInput(direction: Vec2(-1, 0), power: 0.8),
    );

    final restored = _session(RunStateStore(backend: backend));
    final restoredState = await restored.loadState();
    final inputs = restored.currentShotInputs;

    expect(restoredState?.currentPatternId, draw.patternId);
    expect(inputs, hasLength(2));
    expect(inputs.map((input) => input.shotIndex), [0, 1]);
    expect(inputs.first.patternSeed, draw.patternSeed);
    expect(inputs.first.direction.x, closeTo(0.6, 0.000001));
    expect(inputs.first.direction.y, closeTo(-0.8, 0.000001));
    expect(inputs.first.traitActions.single.sourceId, sourceId);
    expect(inputs.first.traitActions.single.action, RunTraitAction.transfer);
    expect(inputs.first.equippedTrait, source.traits.first);
  });

  test('같은 샷의 복사와 옮기기는 실제 8단계 상태와 발사 결과를 재현한다', () async {
    final backend = _MemoryRunStateBackend();
    final first = _session(RunStateStore(backend: backend));
    final draw = await _selectPattern(
      first,
      'stage_chain_score_02',
      initialCloneCoreCount: 1,
    );
    final stage = generatedStageCatalog.stageById('stage_chain_score');
    final level = draw.pattern.toLevelDefinition(
      stageId: stage.stageId,
      stageTitle: stage.title,
    );
    const actions = [
      RunTraitActionRecord(
        sourceId: 'chain_stone',
        action: RunTraitAction.copy,
      ),
      RunTraitActionRecord(
        sourceId: 'chain_stone',
        action: RunTraitAction.transfer,
      ),
    ];
    const input = ShotInput(
      direction: Vec2(-0.4, -0.9),
      power: 0.64,
      equippedTrait: TraitType.heavy,
    );

    for (final action in actions) {
      await first.recordTraitAction(
        sourceId: action.sourceId,
        action: action.action,
      );
    }
    await first.recordShot(input: input);

    final resumed = _session(RunStateStore(backend: backend));
    await resumed.loadState();
    final saved = resumed.currentShotInputs.single;
    var expectedState = level.createState(
      7,
      productRules: true,
      copyCoreCount: 1,
    );
    var replayedState = level.createState(
      7,
      productRules: true,
      copyCoreCount: resumed.replayStartingCloneCoreCount,
    );
    expectedState = _applyTraitActions(expectedState, actions);
    replayedState = _applyTraitActions(replayedState, saved.traitActions);
    final expectedResult = const ShotResolver().resolve(expectedState, input);
    final replayedResult = const ShotResolver().resolve(
      replayedState,
      ShotInput(
        direction: saved.direction,
        power: saved.power,
        equippedTrait: saved.equippedTrait,
      ),
    );

    expect(saved.traitActions.map((action) => action.action), [
      RunTraitAction.copy,
      RunTraitAction.transfer,
    ]);
    expect(resumed.replayStartingCloneCoreCount, 1);
    expect(resumed.state?.cloneCoreCount, 0);
    expect(replayedState.copyCoreCount, expectedState.copyCoreCount);
    expect(
      replayedState.entityById('chain_stone')?.traits,
      expectedState.entityById('chain_stone')?.traits,
    );
    expect(
      shotResultFingerprint(replayedResult),
      shotResultFingerprint(expectedResult),
    );
  });

  test('복제 코어는 획득·소비·되돌리기·재시작에서 한 기준으로 보존된다', () async {
    final backend = _MemoryRunStateBackend();
    final session = _session(RunStateStore(backend: backend));
    await _selectPattern(
      session,
      'stage_chain_score_02',
      initialCloneCoreCount: 1,
    );
    expect(
      await session.awardStageCloneCores(
        stageId: 'stage_chain_score',
        amount: 2,
      ),
      isTrue,
    );
    expect(
      await session.awardStageCloneCores(
        stageId: 'stage_chain_score',
        amount: 2,
      ),
      isFalse,
    );
    expect(session.state?.cloneCoreCount, 3);
    expect(
      session.state?.acquiredRewards,
      contains('stage_clone_core:stage_chain_score'),
    );

    await session.recordTraitAction(
      sourceId: 'chain_stone',
      action: RunTraitAction.copy,
    );
    await session.recordShot(
      input: const ShotInput(
        direction: Vec2(1, 0),
        power: 0.5,
        equippedTrait: TraitType.heavy,
      ),
    );
    expect(session.state?.cloneCoreCount, 2);

    await session.rewindCurrentShot();
    expect(session.state?.cloneCoreCount, 2);
    expect(
      session.state?.pendingTraitActions.single.action,
      RunTraitAction.copy,
    );

    await session.restartCurrentStage();
    expect(session.state?.cloneCoreCount, 3);
    expect(session.state?.pendingTraitActions, isEmpty);
    expect(session.currentShotInputs, isEmpty);

    final resumed = _session(RunStateStore(backend: backend));
    await resumed.loadState();
    expect(resumed.state?.cloneCoreCount, 3);
  });

  test('현재 패턴에 없거나 이미 옮긴 속성 원본 행동은 저장하지 않는다', () async {
    final session = _session(RunStateStore(backend: _MemoryRunStateBackend()));
    await _selectPattern(session, 'stage_chain_score_02');
    await expectLater(
      session.recordTraitAction(
        sourceId: '없는_원본',
        action: RunTraitAction.transfer,
      ),
      throwsA(isA<StateError>()),
    );
    await session.recordTraitAction(
      sourceId: 'chain_stone',
      action: RunTraitAction.transfer,
    );
    await expectLater(
      session.recordTraitAction(
        sourceId: 'chain_stone',
        action: RunTraitAction.transfer,
      ),
      throwsA(isA<StateError>()),
    );
    expect(session.state?.pendingTraitActions, hasLength(1));
  });

  test('되돌리기는 마지막 발사만 지우고 재시작은 현재 패턴 기록만 지운다', () async {
    final backend = _MemoryRunStateBackend();
    final session = _session(RunStateStore(backend: backend));
    await session.selectStage('stage_chain_score');
    await session.recordShot(
      input: const ShotInput(direction: Vec2(1, 0), power: 0.4),
    );
    await session.recordShot(
      input: const ShotInput(direction: Vec2(0, -1), power: 0.7),
    );

    await session.rewindCurrentShot();
    expect(session.currentShotInputs, hasLength(1));
    expect(session.currentShotInputs.single.shotIndex, 0);

    await session.restartCurrentStage();
    expect(session.currentShotInputs, isEmpty);
    expect(session.state?.phase, RunPhase.playing);

    final restored = _session(RunStateStore(backend: backend));
    await restored.loadState();
    expect(restored.currentShotInputs, isEmpty);
  });

  test('진행 중인 단계와 선추첨된 다음 단계는 지도 선택으로 교체되지 않는다', () async {
    final session = _session(RunStateStore(backend: _MemoryRunStateBackend()));
    await session.selectStage('stage_heavy');
    await expectLater(
      session.selectStage('stage_bouncy'),
      throwsA(isA<StateError>()),
    );
    await session.completeCurrentStage(
      stageId: 'stage_heavy',
      nextStageId: 'stage_bouncy',
      shotCount: 1,
    );
    final nextPatternId = session.state?.nextStagePatternId;
    final historyLength = session.state?.patternDrawHistory.length;

    await expectLater(
      session.selectStage('stage_chain_gate'),
      throwsA(isA<StateError>()),
    );
    expect(session.state?.nextStagePatternId, nextPatternId);
    expect(session.state?.patternDrawHistory, hasLength(historyLength!));
  });

  test('seed 없는 구형 샷은 같은 패턴의 다음 셔플 주기에 결합하지 않는다', () async {
    final backend = _MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    final firstSession = _session(store);
    final firstDraw = await firstSession.selectStage('stage_chain_score');
    final legacyJson = firstSession.state!.toJson();
    legacyJson['shotInputLog'] = [
      RunShotInput(
        stageId: 'stage_chain_score',
        patternId: firstDraw.patternId,
        shotIndex: 0,
        direction: const Vec2(1, 0),
        power: 0.4,
      ).toJson(),
    ];
    await store.save(RunState.fromJson(legacyJson));

    final resumed = _session(RunStateStore(backend: backend));
    await resumed.loadState();
    expect(resumed.currentShotInputs, hasLength(1));
    expect(resumed.currentShotInputs.single.patternSeed, firstDraw.patternSeed);
    final migrated = _session(RunStateStore(backend: backend));
    await migrated.loadState();
    expect(
      migrated.currentShotInputs.single.patternSeed,
      firstDraw.patternSeed,
    );
    await resumed.completeCurrentStage(
      stageId: 'stage_chain_score',
      shotCount: 1,
    );

    for (var index = 0; index < 7; index++) {
      final draw = await resumed.selectStage('stage_chain_score');
      if (draw.patternId == firstDraw.patternId) {
        expect(draw.cycle, 1);
        expect(resumed.currentShotInputs, isEmpty);
        return;
      }
      await resumed.completeCurrentStage(
        stageId: 'stage_chain_score',
        shotCount: 1,
      );
    }
    fail('다음 셔플 주기에서 같은 패턴을 찾지 못했습니다.');
  });

  test('같은 패턴이 여러 번 추첨된 구형 무시드 샷은 현재 주기에 임의 결합하지 않는다', () async {
    final backend = _MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    final firstSession = _session(store);
    final draw = await firstSession.selectStage('stage_chain_score');
    final legacyJson = firstSession.state!.toJson();
    final history = (legacyJson['patternDrawHistory']! as List<Object?>)
        .cast<Map<String, dynamic>>()
        .map((record) => Map<String, dynamic>.from(record))
        .toList();
    history.add({
      ...history.single,
      'patternSeed': draw.patternSeed + 1,
      'cycle': draw.cycle + 1,
      'drawIndex': draw.drawIndex + 4,
    });
    legacyJson['patternDrawHistory'] = history;
    legacyJson['shotInputLog'] = [
      RunShotInput(
        stageId: draw.stageId,
        patternId: draw.patternId,
        patternSeed: draw.patternSeed,
        shotIndex: 0,
        direction: const Vec2(0, -1),
        power: 0.5,
      ).toJson(),
      RunShotInput(
        stageId: draw.stageId,
        patternId: draw.patternId,
        shotIndex: 0,
        direction: const Vec2(1, 0),
        power: 0.4,
        equippedTrait: TraitType.heavy,
        traitActions: const [
          RunTraitActionRecord(
            sourceId: '구형_속성_원본',
            action: RunTraitAction.copy,
          ),
        ],
      ).toJson(),
    ];
    legacyJson['cloneCoreCount'] = 2;
    await store.save(RunState.fromJson(legacyJson));

    final resumed = _session(RunStateStore(backend: backend));
    final state = await resumed.loadState();

    expect(resumed.legacyCurrentShotHistoryAmbiguous, isTrue);
    expect(resumed.ambiguousLegacyCopyActionCount, 1);
    expect(resumed.currentShotInputs, hasLength(1));
    expect(resumed.currentShotInputs.single.patternSeed, draw.patternSeed);
    expect(state?.shotInputLog.last.patternSeed, isNull);
    expect(state?.cloneCoreCount, 2);

    await resumed.completeCurrentStage(
      stageId: draw.stageId,
      nextStageId: 'stage_heavy',
      shotCount: 1,
    );
    await resumed.selectStage('stage_heavy');
    expect(resumed.legacyCurrentShotHistoryAmbiguous, isFalse);
    expect(resumed.ambiguousLegacyCopyActionCount, 0);
  });

  test('안정 단계 ID로 저장된 복제 코어 보상은 새 RunState에 그대로 복원된다', () async {
    final session = _session(RunStateStore(backend: _MemoryRunStateBackend()));

    await session.selectStage(
      'stage_heavy',
      initialCloneCoreCount: 3,
      initialCloneCoreRewarded: true,
      initialCloneCoreRewardedStageIds: const [
        legacyCloneCoreRewardStageId,
        'stage_chain_score',
      ],
    );

    expect(session.state?.cloneCoreCount, 3);
    expect(stageCloneCoreRewardStageIds(session.state!.acquiredRewards), {
      legacyCloneCoreRewardStageId,
      'stage_chain_score',
    });
    expect(
      session.state?.acquiredRewards,
      isNot(contains(legacyStageCloneCoreRewardId)),
    );
    expect(
      await session.awardStageCloneCores(stageId: 'stage_heavy', amount: 1),
      isTrue,
    );
    expect(session.state?.cloneCoreCount, 4);
    expect(stageCloneCoreRewardStageIds(session.state!.acquiredRewards), {
      legacyCloneCoreRewardStageId,
      'stage_chain_score',
      'stage_heavy',
    });
  });

  test('중간 버전 RunState의 구형 보상 표식은 진행 불리언 없이도 과거 단계로 확정한다', () async {
    final backend = _MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    final first = _session(store);
    await first.selectStage('stage_heavy');
    final legacyJson = first.state!.toJson();
    legacyJson['acquiredRewards'] = [legacyStageCloneCoreRewardId];
    await store.save(RunState.fromJson(legacyJson));

    final resumed = _session(RunStateStore(backend: backend));
    expect(await resumed.migrateLegacyCloneCoreReward(rewarded: false), isTrue);

    expect(
      resumed.state?.acquiredRewards,
      contains(stageCloneCoreRewardId(legacyCloneCoreRewardStageId)),
    );
    expect(
      resumed.state?.acquiredRewards,
      isNot(contains(legacyStageCloneCoreRewardId)),
    );
  });

  test('기기 시계가 뒤로 가도 저장 갱신 시각과 런 복구가 깨지지 않는다', () async {
    final backend = _MemoryRunStateBackend();
    final first = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: backend),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    await first.selectStage('stage_heavy');
    final originalUpdatedAt = first.state!.updatedAt;

    final resumed = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: backend),
      now: () => DateTime.utc(2026, 8, 7, 7),
    );
    await resumed.completeCurrentStage(stageId: 'stage_heavy', shotCount: 1);

    expect(resumed.state?.phase, RunPhase.stageCompleted);
    expect(resumed.state?.updatedAt, originalUpdatedAt);
    expect(
      resumed.state!.updatedAt.isBefore(resumed.state!.startedAt),
      isFalse,
    );
  });

  test('클리어 보상 후보는 저장 뒤 재실행해도 같은 세 개를 유지한다', () async {
    final backend = _MemoryRunStateBackend();
    final firstStore = RunStateStore(backend: backend);
    final first = _session(firstStore);
    await first.selectStage('stage_heavy');
    await first.completeCurrentStage(
      stageId: 'stage_heavy',
      nextStageId: 'stage_bouncy',
      shotCount: 2,
    );

    final candidates = await first.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    final revision = firstStore.lastRevision;
    final resumedStore = RunStateStore(backend: backend);
    final resumed = _session(resumedStore);
    final restored = await resumed.prepareRewardSelection(
      stageId: 'stage_heavy',
    );

    expect(candidates, hasLength(3));
    expect(candidates.map((reward) => reward.id).toSet(), hasLength(3));
    expect(
      restored.map((reward) => reward.id),
      candidates.map((reward) => reward.id),
    );
    expect(resumed.state?.phase, RunPhase.rewardSelectionPending);
    expect(resumedStore.lastRevision, revision);
    await expectLater(
      resumed.selectStage('stage_bouncy'),
      throwsA(isA<StateError>()),
    );
  });

  test('후보 중 하나를 선택해야 다음 단계로 이동할 수 있다', () async {
    final backend = _MemoryRunStateBackend();
    final session = _session(RunStateStore(backend: backend));
    await session.selectStage('stage_heavy');
    await session.completeCurrentStage(
      stageId: 'stage_heavy',
      nextStageId: 'stage_bouncy',
      shotCount: 2,
    );
    final candidates = await session.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    final selected = await session.selectReward(candidates[1].id);

    expect(session.state?.phase, RunPhase.rewardSelectionCompleted);
    expect(session.state?.selectedRewardId, selected.id);
    expect(session.state?.acquiredRewards, contains(selected.id));
    expect(
      session.state?.acquiredRewards,
      contains(
        runRewardSelectionRecordId(
          stageId: 'stage_heavy',
          patternSeed: session.state!.currentPatternSeed!,
          rewardId: selected.id,
        ),
      ),
    );
    await expectLater(
      session.selectReward(candidates.first.id),
      throwsA(isA<StateError>()),
    );

    final next = await session.selectStage('stage_bouncy');
    expect(next.stageId, 'stage_bouncy');
    expect(session.state?.phase, RunPhase.playing);
    expect(session.state?.rewardCandidateIds, isEmpty);
    expect(session.state?.selectedRewardId, isNull);
    expect(session.state?.acquiredRewards, contains(selected.id));
  });

  test('복제 코어 후보 선택은 저장 상태의 코어를 정확히 하나 늘린다', () async {
    StagePatternSession? matched;
    List<RunReward>? matchedCandidates;
    for (var offset = 0; offset < 64; offset++) {
      final session = StagePatternSession(
        catalog: generatedStageCatalog,
        store: RunStateStore(backend: _MemoryRunStateBackend()),
        now: () => DateTime.fromMicrosecondsSinceEpoch(offset, isUtc: true),
      );
      await session.selectStage('stage_heavy', initialCloneCoreCount: 2);
      await session.completeCurrentStage(stageId: 'stage_heavy', shotCount: 1);
      final candidates = await session.prepareRewardSelection(
        stageId: 'stage_heavy',
      );
      if (candidates.any((reward) => reward.id == runRewardCloneCoreId)) {
        matched = session;
        matchedCandidates = candidates;
        break;
      }
    }
    expect(matched, isNotNull);
    expect(matchedCandidates, isNotNull);

    await matched!.selectReward(runRewardCloneCoreId);
    expect(matched.state?.cloneCoreCount, 3);
  });

  test('보상 선택 저장 실패는 후보와 대기 상태를 보존하고 다시 선택할 수 있다', () async {
    final backend = _MemoryRunStateBackend();
    final session = _session(RunStateStore(backend: backend));
    await session.selectStage('stage_heavy');
    await session.completeCurrentStage(stageId: 'stage_heavy', shotCount: 1);
    final candidates = await session.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    backend.failNextWrite = true;

    await expectLater(
      session.selectReward(candidates.first.id),
      throwsA(isA<StateError>()),
    );
    expect(session.state?.phase, RunPhase.rewardSelectionPending);
    expect(
      session.state?.rewardCandidateIds,
      candidates.map((reward) => reward.id),
    );

    final resumed = _session(RunStateStore(backend: backend));
    final restored = await resumed.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    expect(
      restored.map((reward) => reward.id),
      candidates.map((reward) => reward.id),
    );
    await resumed.selectReward(candidates.first.id);
    expect(resumed.state?.phase, RunPhase.rewardSelectionCompleted);
  });

  test('마지막 단계 보상 선택 뒤 런 완료를 저장하고 새 런을 시작한다', () async {
    final session = _session(RunStateStore(backend: _MemoryRunStateBackend()));
    await session.selectStage('stage_property_shot');
    await session.completeCurrentStage(
      stageId: 'stage_property_shot',
      shotCount: 2,
    );
    final candidates = await session.prepareRewardSelection(
      stageId: 'stage_property_shot',
    );
    await session.selectReward(candidates.last.id);
    final completedRootSeed = session.state!.rootSeed;
    await session.completeRun();
    expect(session.state?.phase, RunPhase.runCompleted);

    final first = await session.selectStage('stage_heavy');
    expect(first.stageId, 'stage_heavy');
    expect(session.state?.phase, RunPhase.playing);
    expect(session.state?.currentStageId, 'stage_heavy');
    expect(session.state?.rewardCandidateIds, isEmpty);
    expect(session.state?.selectedRewardId, isNull);
    expect(session.state?.rootSeed, isNot(completedRootSeed));
  });

  test('기록 재도전은 같은 패턴 보상을 다시 지급하지 않는다', () async {
    final session = _session(RunStateStore(backend: _MemoryRunStateBackend()));
    await session.selectStage('stage_heavy', initialCloneCoreCount: 1);
    await session.completeCurrentStage(stageId: 'stage_heavy', shotCount: 2);
    final candidates = await session.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    final selected = candidates.first;
    await session.selectReward(selected.id);
    final countAfterFirst = session.state!.cloneCoreCount;
    final acquiredAfterFirst = session.state!.acquiredRewards.length;
    await session.restartCurrentStage();
    await session.completeCurrentStage(stageId: 'stage_heavy', shotCount: 1);
    final restoredCandidates = await session.prepareRewardSelection(
      stageId: 'stage_heavy',
    );

    expect(
      restoredCandidates.map((reward) => reward.id),
      candidates.map((reward) => reward.id),
    );
    expect(session.state?.phase, RunPhase.rewardSelectionCompleted);
    expect(session.state?.selectedRewardId, selected.id);
    expect(session.state?.cloneCoreCount, countAfterFirst);
    expect(session.state?.acquiredRewards.length, acquiredAfterFirst);
  });

  test('일회성 보상은 한 번만 소모되고 재실행 뒤에도 사용 상태를 유지한다', () async {
    final backend = _MemoryRunStateBackend();
    final session = _session(RunStateStore(backend: backend));
    await session.selectStage('stage_heavy');
    await session.completeCurrentStage(
      stageId: 'stage_heavy',
      nextStageId: 'stage_bouncy',
      shotCount: 2,
    );
    final candidates = await session.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    final selected = await session.selectReward(candidates.first.id);
    await session.selectStage('stage_bouncy');

    expect(
      await session.consumeRewardUse(
        rewardId: selected.id,
        useKey: 'stage_bouncy|첫사용',
      ),
      isTrue,
    );
    expect(
      await session.consumeRewardUse(
        rewardId: selected.id,
        useKey: 'stage_bouncy|두번째사용',
      ),
      isFalse,
    );

    final resumed = _session(RunStateStore(backend: backend));
    await resumed.loadState();
    expect(resumed.rewardInventory.availableUseCount(selected.id), 0);
    expect(resumed.rewardInventory.useKeys(selected.id), ['stage_bouncy|첫사용']);
  });

  test('단계 기록 보호는 단계마다 한 번씩 사용할 수 있다', () async {
    final session = _session(RunStateStore(backend: _MemoryRunStateBackend()));
    await session.selectStage('stage_heavy');
    await session.completeCurrentStage(
      stageId: 'stage_heavy',
      nextStageId: 'stage_bouncy',
      shotCount: 2,
    );
    final candidates = await session.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    final selected = await session.selectReward(candidates.first.id);
    await session.selectStage('stage_bouncy');

    expect(
      await session.consumeStageRewardUse(
        rewardId: selected.id,
        stageId: 'stage_bouncy',
      ),
      isTrue,
    );
    expect(
      await session.consumeStageRewardUse(
        rewardId: selected.id,
        stageId: 'stage_bouncy',
      ),
      isFalse,
    );
    expect(
      await session.consumeStageRewardUse(
        rewardId: selected.id,
        stageId: 'stage_sticky',
      ),
      isTrue,
    );
  });
}

StagePatternSession _session(RunStateStore store) {
  return StagePatternSession(
    catalog: generatedStageCatalog,
    store: store,
    now: () => DateTime.utc(2026, 8, 7, 8),
  );
}

Future<StagePatternDraw> _selectPattern(
  StagePatternSession session,
  String patternId, {
  int initialCloneCoreCount = 0,
}) async {
  for (var index = 0; index < 4; index++) {
    final draw = await session.selectStage(
      'stage_chain_score',
      initialCloneCoreCount: initialCloneCoreCount,
    );
    if (draw.patternId == patternId) return draw;
    await session.completeCurrentStage(
      stageId: 'stage_chain_score',
      shotCount: 1,
    );
  }
  throw StateError('$patternId 패턴을 셔플 백에서 찾지 못했습니다.');
}

GameState _applyTraitActions(
  GameState state,
  Iterable<RunTraitActionRecord> actions,
) {
  const resolver = TraitResolver();
  var next = state;
  for (final action in actions) {
    next = resolver.selectSource(next, action.sourceId);
    next = switch (action.action) {
      RunTraitAction.copy => resolver.copySelectedTrait(next),
      RunTraitAction.transfer => resolver.transferSelectedTrait(next),
    };
  }
  return next;
}

class _MemoryRunStateBackend implements RunStateKeyValueBackend {
  final values = <String, String>{};
  bool failNextWrite = false;

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('보상 저장 실패 주입');
    }
    values[key] = value;
  }
}
