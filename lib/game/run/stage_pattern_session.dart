import 'dart:math' as math;

import '../domain/stage_catalog.dart';
import '../domain/stage_pattern.dart';
import '../domain/shot_input.dart';
import '../persistence/replay_library_store.dart';
import '../persistence/run_state_store.dart';
import 'run_hint_state.dart';
import 'run_reward.dart';
import 'run_state.dart';
import 'stage_shuffle_bag.dart';

typedef StageCompletionResult = ({
  bool optionalChallengeAchieved,
  int shotCount,
});

typedef StagePatternDrawPolicy =
    StagePatternDraw Function({
      required StageDefinition stage,
      required StageShuffleBagState state,
      required int rootSeed,
    });

typedef HintVersionResolver = int Function(String stageId, String patternId);

const String restorationBridgeSupplyMarker =
    'island_restoration_bridge_supply_v1';
const String restorationLighthouseAccessMarker =
    'island_restoration_lighthouse_access_v1';
const String restorationObservatoryFocusMarker =
    'island_restoration_focus_observatory_v1';
const String restorationObservatorySupportMarker =
    'island_restoration_observatory_support_v1';
const String restorationLighthouseFocusMarker =
    'island_restoration_focus_lighthouse_v1';
const String restorationLighthouseAimMarker =
    'island_restoration_lighthouse_aim_v1';
const String restorationBridgeFocusMarker =
    'island_restoration_focus_bridge_v1';
const String restorationBridgeFocusSupplyMarker =
    'island_restoration_bridge_focus_supply_v1';
const String restorationMasteryGuideMarker =
    'island_restoration_mastery_guide_v1';
const String restorationMasteryCancelMarker =
    'island_restoration_mastery_cancel_v1';
const String restorationMasteryCoreMarker =
    'island_restoration_mastery_core_v1';

/// 시설을 복구해 소유한 것과 이번 런에서 집중 지원을 선택한 것을 구분한다.
bool islandRestorationSupportWasUsed(Iterable<String> acquiredRewards) {
  final rewards = acquiredRewards is Set<String>
      ? acquiredRewards
      : acquiredRewards.toSet();
  return rewards.contains(restorationObservatoryFocusMarker) ||
      rewards.contains(restorationLighthouseFocusMarker) ||
      rewards.contains(restorationBridgeFocusMarker);
}

/// 스테이지 선택 화면과 결정론 패턴 런 상태를 연결한다.
class StagePatternSession {
  StagePatternSession({
    required this.catalog,
    required this._store,
    DateTime Function()? now,
    this.fixedRootSeed,
    this.fixedRunId,
    this.fixedResolverVersion,
    this.hintVersionResolver,
  }) : _now = now ?? DateTime.now {
    if (fixedRootSeed != null &&
        (fixedRootSeed! < 0 || fixedRootSeed! > 0xffffffff)) {
      throw ArgumentError.value(
        fixedRootSeed,
        'fixedRootSeed',
        '0 이상 32비트 이하의 값이어야 합니다.',
      );
    }
    if (fixedRunId != null && fixedRunId!.trim().isEmpty) {
      throw ArgumentError.value(fixedRunId, 'fixedRunId', '비어 있을 수 없습니다.');
    }
    if (fixedResolverVersion != null && fixedResolverVersion!.trim().isEmpty) {
      throw ArgumentError.value(
        fixedResolverVersion,
        'fixedResolverVersion',
        '비어 있을 수 없습니다.',
      );
    }
  }

  final StageCatalog catalog;
  final RunStateStore _store;
  final DateTime Function() _now;
  final int? fixedRootSeed;
  final String? fixedRunId;
  final String? fixedResolverVersion;
  final HintVersionResolver? hintVersionResolver;
  RunState? _state;
  bool _loaded = false;
  Future<void> _operationTail = Future<void>.value();
  bool _legacyCurrentShotHistoryAmbiguous = false;
  int _ambiguousLegacyCopyActionCount = 0;

  RunState? get state => _state;

  bool get legacyCurrentShotHistoryAmbiguous =>
      _legacyCurrentShotHistoryAmbiguous;

  int get ambiguousLegacyCopyActionCount => _ambiguousLegacyCopyActionCount;

  int _hintVersionFor(String stageId, String patternId) {
    final version =
        hintVersionResolver?.call(stageId, patternId) ?? currentHintVersion;
    if (version <= 0) {
      throw StateError('힌트 버전은 양수여야 합니다: $stageId/$patternId v$version');
    }
    return version;
  }

  /// 현재 확정된 패턴에 사용 가능한 힌트 접근권이다.
  RunHintEntitlement? get currentHintEntitlement {
    final current = _state;
    if (current?.currentStageId == null || current?.currentPatternId == null) {
      return null;
    }
    return _hintEntitlementFor(
      current!,
      HintIdentity(
        stageId: current.currentStageId!,
        patternId: current.currentPatternId!,
        hintVersion: _hintVersionFor(
          current.currentStageId!,
          current.currentPatternId!,
        ),
      ),
    );
  }

  Future<RunState?> loadState() => _enqueueOperation(() async {
    await _loadOnce();
    return _state;
  });

  /// 이 세션이 소유한 저장 영역만 비우고 완전히 새 런으로 되돌린다.
  ///
  /// 캠페인과 별도 namespace를 쓰는 탐사 계약을 새로 시작할 때 사용한다.
  /// 다른 [StagePatternSession]의 저장 영역에는 영향을 주지 않는다.
  Future<void> reset() => _enqueueOperation(() async {
    await _store.reset();
    _state = null;
    _loaded = true;
    _legacyCurrentShotHistoryAmbiguous = false;
    _ambiguousLegacyCopyActionCount = 0;
  });

  /// 복구된 섬 시설의 영구 지원을 현재 런에 한 번씩 적용한다.
  ///
  /// 관측소는 기존 실패 분석 보상을 지속 효과로 켜고, 등대는 현재 패턴의
  /// L1 접근권을 열며, 다리는 새 런마다 복사 코어 하나를 보급한다.
  Future<bool> applyIslandRestorationBenefits({
    required bool observatoryRestored,
    required bool lighthouseRestored,
    required bool bridgeRestored,
    bool observatoryFocused = false,
    bool lighthouseFocused = false,
    bool bridgeFocused = false,
    int optionalMasteryCount = 0,
  }) => _enqueueOperation(() async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) return false;

    final acquiredRewards = {...current.acquiredRewards};
    var cloneCoreCount = current.cloneCoreCount;
    var hintEntitlements = current.hintEntitlements;
    var changed = false;
    final requestedFocus = switch ((
      observatoryRestored && observatoryFocused,
      lighthouseRestored && lighthouseFocused,
      bridgeRestored && bridgeFocused,
    )) {
      (true, false, false) => restorationObservatoryFocusMarker,
      (false, true, false) => restorationLighthouseFocusMarker,
      (false, false, true) => restorationBridgeFocusMarker,
      _ => null,
    };
    String? effectiveFocus;
    for (final reward in acquiredRewards) {
      if (reward == restorationObservatoryFocusMarker ||
          reward == restorationLighthouseFocusMarker ||
          reward == restorationBridgeFocusMarker) {
        effectiveFocus = reward;
        break;
      }
    }
    if (effectiveFocus == null && requestedFocus != null) {
      acquiredRewards.add(requestedFocus);
      effectiveFocus = requestedFocus;
      changed = true;
    }

    if (observatoryRestored &&
        acquiredRewards.add(restorationObservatorySupportMarker)) {
      changed = true;
    }
    if (observatoryRestored &&
        acquiredRewards.add(runRewardFailureCauseBoostId)) {
      changed = true;
    }
    if (observatoryRestored &&
        effectiveFocus == restorationObservatoryFocusMarker &&
        acquiredRewards.add(runRewardPrecisionChargeId)) {
      changed = true;
    }
    if (bridgeRestored && acquiredRewards.add(restorationBridgeSupplyMarker)) {
      cloneCoreCount++;
      changed = true;
    }
    if (observatoryRestored &&
        optionalMasteryCount >= 3 &&
        acquiredRewards.add(restorationMasteryGuideMarker)) {
      acquiredRewards
        ..add(runRewardFirstImpactGuideId)
        ..add(
          runRewardSelectionRecordId(
            stageId: 'island_mastery',
            patternSeed: 3,
            rewardId: runRewardFirstImpactGuideId,
          ),
        );
      changed = true;
    }
    if (lighthouseRestored &&
        optionalMasteryCount >= 6 &&
        acquiredRewards.add(restorationMasteryCancelMarker)) {
      acquiredRewards
        ..add(runRewardShotCancelAssistId)
        ..add(
          runRewardSelectionRecordId(
            stageId: 'island_mastery',
            patternSeed: 6,
            rewardId: runRewardShotCancelAssistId,
          ),
        );
      changed = true;
    }
    if (bridgeRestored &&
        optionalMasteryCount >= 9 &&
        acquiredRewards.add(restorationMasteryCoreMarker)) {
      cloneCoreCount++;
      changed = true;
    }
    if (lighthouseRestored) {
      if (acquiredRewards.add(restorationLighthouseAccessMarker)) {
        changed = true;
      }
      final identity = HintIdentity(
        stageId: current.currentStageId!,
        patternId: current.currentPatternId!,
        hintVersion: _hintVersionFor(
          current.currentStageId!,
          current.currentPatternId!,
        ),
      );
      final before = _hintEntitlementFor(current, identity);
      if (before == null ||
          !before.sources.contains(
            HintEntitlementSource.restorationLighthouse,
          )) {
        hintEntitlements = _mergeHintEntitlement(
          hintEntitlements,
          identity,
          HintEntitlementSource.restorationLighthouse,
        );
        changed = true;
      }
      if (effectiveFocus == restorationLighthouseFocusMarker) {
        if (acquiredRewards.add(restorationLighthouseAimMarker)) {
          changed = true;
        }
        hintEntitlements = [
          for (final entitlement in hintEntitlements)
            entitlement.identity.storageKey == identity.storageKey
                ? entitlement.copyWith(unlockedHintLevel: 2)
                : entitlement,
        ];
      }
    }
    if (bridgeRestored &&
        effectiveFocus == restorationBridgeFocusMarker &&
        acquiredRewards.add(restorationBridgeFocusSupplyMarker)) {
      cloneCoreCount++;
      changed = true;
    }
    if (!changed) return false;

    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      cloneCoreCount: cloneCoreCount,
      acquiredRewards: acquiredRewards,
      hintEntitlements: hintEntitlements,
    );
    await _store.save(next);
    _state = next;
    return true;
  });

  List<RunShotInput> get currentShotInputs {
    final current = _state;
    if (current == null || current.currentStageId == null) return const [];
    final inputs =
        current.shotInputLog
            .where((input) => _belongsToCurrentDraw(input, current))
            .toList()
          ..sort((left, right) => left.shotIndex.compareTo(right.shotIndex));
    return List.unmodifiable(inputs);
  }

  int get replayStartingCloneCoreCount {
    final current = _state;
    if (current == null) return 0;
    return current.cloneCoreCount +
        _copyActionCount(current.pendingTraitActions) +
        currentShotInputs.fold<int>(
          0,
          (sum, input) => sum + _copyActionCount(input.traitActions),
        );
  }

  Future<StagePatternDraw> selectStage(
    String stageId, {
    int initialCloneCoreCount = 0,
    bool initialCloneCoreRewarded = false,
    Iterable<String> initialCloneCoreRewardedStageIds = const [],
    StagePatternDrawPolicy? drawPolicy,
  }) => _enqueueOperation(
    () => _selectStage(
      stageId,
      initialCloneCoreCount: initialCloneCoreCount,
      initialCloneCoreRewarded: initialCloneCoreRewarded,
      initialCloneCoreRewardedStageIds: initialCloneCoreRewardedStageIds,
      drawPolicy: drawPolicy,
    ),
  );

  Future<StagePatternDraw> _selectStage(
    String stageId, {
    required int initialCloneCoreCount,
    required bool initialCloneCoreRewarded,
    required Iterable<String> initialCloneCoreRewardedStageIds,
    required StagePatternDrawPolicy? drawPolicy,
  }) async {
    if (initialCloneCoreCount < 0) {
      throw ArgumentError.value(
        initialCloneCoreCount,
        'initialCloneCoreCount',
        '0 이상이어야 합니다.',
      );
    }
    await _loadOnce();
    final stage = catalog.stageById(stageId);
    final current = _state;
    if (current != null &&
        current.phase == RunPhase.runCompleted &&
        fixedRunId != null) {
      throw StateError('완료된 고정 도전은 같은 시도로 다시 시작할 수 없습니다.');
    }
    if (current != null &&
        current.phase == RunPhase.playing &&
        current.currentStageId == stageId) {
      return _restoreCurrentDraw(stage, current);
    }
    if (current != null &&
        (current.phase == RunPhase.rewardSelectionPending ||
            current.phase == RunPhase.rewardSelectionCompleted) &&
        current.currentStageId == stageId) {
      return _restoreCurrentDraw(stage, current);
    }
    if (current != null &&
        (current.phase == RunPhase.stageCompleted ||
            current.phase == RunPhase.rewardSelectionCompleted) &&
        current.nextStageId == stageId) {
      final draw = _restoreNextDraw(stage, current);
      final next = _withCurrentDraw(current, draw, appendHistory: false);
      await _store.save(next);
      _state = next;
      _clearLegacyShotAmbiguity();
      return draw;
    }
    if (current != null && current.phase == RunPhase.rewardSelectionPending) {
      throw StateError('보상을 먼저 선택해 주세요.');
    }
    if (current != null &&
        current.phase == RunPhase.playing &&
        current.currentStageId != stageId) {
      throw StateError('진행 중인 단계를 먼저 이어서 플레이해 주세요.');
    }
    if (current != null &&
        current.phase == RunPhase.stageCompleted &&
        current.nextStageId != null &&
        current.nextStageId != stageId) {
      throw StateError('미리 준비된 다음 단계를 먼저 플레이해 주세요.');
    }

    final startingNewRun =
        current == null || current.phase == RunPhase.runCompleted;
    var rootSeed = startingNewRun
        ? (fixedRootSeed ?? _newRootSeed())
        : current.rootSeed;
    if (fixedRootSeed == null &&
        current?.phase == RunPhase.runCompleted &&
        rootSeed == current!.rootSeed) {
      rootSeed = (rootSeed ^ 0x9e3779b9) & 0xffffffff;
    }
    final bag =
        (startingNewRun ? null : current.stageShuffleBags[stageId]) ??
        StageShuffleBagState.initial(stageId);
    final draw = (drawPolicy ?? StageShuffleBag.draw)(
      stage: stage,
      state: bag,
      rootSeed: rootSeed,
    );
    final initialRewardStageIds = initialCloneCoreRewardedStageIds
        .where((id) => id.isNotEmpty)
        .toSet();
    final next = startingNewRun
        ? RunState.initial(
            runId: fixedRunId ?? 'run_${_now().toUtc().microsecondsSinceEpoch}',
            rootSeed: rootSeed,
            resolverVersion: fixedResolverVersion ?? 'shot-resolver-v1',
            currentDraw: draw,
            cloneCoreCount: initialCloneCoreCount,
            acquiredRewards: {
              for (final rewardedStageId in initialRewardStageIds)
                stageCloneCoreRewardId(rewardedStageId),
              if (initialCloneCoreRewarded && initialRewardStageIds.isEmpty)
                stageCloneCoreRewardId(legacyCloneCoreRewardStageId),
            },
            now: _now().toUtc(),
          )
        : _withCurrentDraw(current, draw);
    await _store.save(next);
    _state = next;
    _clearLegacyShotAmbiguity();
    return draw;
  }

  Future<StageCompletionResult> completeCurrentStage({
    required String stageId,
    required int shotCount,
    String? nextStageId,
    int? chainScore,
    bool optionalChallengeAchieved = false,
    bool applyOptionalChallengeGuard = false,
    bool applyStageRecordGuard = false,
    StagePatternDrawPolicy? nextStageDrawPolicy,
  }) => _enqueueOperation(
    () => _completeCurrentStage(
      stageId: stageId,
      shotCount: shotCount,
      nextStageId: nextStageId,
      chainScore: chainScore,
      optionalChallengeAchieved: optionalChallengeAchieved,
      applyOptionalChallengeGuard: applyOptionalChallengeGuard,
      applyStageRecordGuard: applyStageRecordGuard,
      nextStageDrawPolicy: nextStageDrawPolicy,
    ),
  );

  Future<StageCompletionResult> _completeCurrentStage({
    required String stageId,
    required int shotCount,
    String? nextStageId,
    int? chainScore,
    required bool optionalChallengeAchieved,
    required bool applyOptionalChallengeGuard,
    required bool applyStageRecordGuard,
    required StagePatternDrawPolicy? nextStageDrawPolicy,
  }) async {
    if (shotCount < 1) {
      throw ArgumentError.value(shotCount, 'shotCount', '1 이상이어야 합니다.');
    }
    if (chainScore != null && chainScore < 0) {
      throw ArgumentError.value(chainScore, 'chainScore', '0 이상이어야 합니다.');
    }
    if (nextStageId == stageId) {
      throw ArgumentError.value(nextStageId, 'nextStageId', '현재 단계와 달라야 합니다.');
    }
    await _loadOnce();
    final current = _state;
    if (current == null ||
        current.currentStageId != stageId ||
        (current.phase != RunPhase.playing &&
            current.phase != RunPhase.stageCompleted)) {
      return (
        optionalChallengeAchieved: optionalChallengeAchieved,
        shotCount: shotCount,
      );
    }
    final acquiredRewards = current.acquiredRewards.toSet();
    final inventory = RunRewardInventory(acquiredRewards);
    final stageAttempt = runStageAttemptNumber(acquiredRewards, stageId);
    var effectiveChallenge = optionalChallengeAchieved;
    var effectiveShotCount = shotCount;
    if (!effectiveChallenge && applyOptionalChallengeGuard) {
      final available = inventory.availableSelections(
        runRewardOptionalChallengeGuardId,
      );
      if (available.isNotEmpty) {
        acquiredRewards.add(
          runRewardUseRecordId(
            available.first.recordId,
            '$stageId:$shotCount:선택도전',
          ),
        );
        effectiveChallenge = true;
      }
    }
    var recordGuardApplied = inventory.wasUsedForStageAttempt(
      runRewardStageRecordGuardId,
      stageId,
      stageAttempt,
    );
    if (applyStageRecordGuard) {
      for (final selection in inventory.selections.where(
        (record) => record.rewardId == runRewardStageRecordGuardId,
      )) {
        final useRecord = runRewardStageUseRecordId(
          selection.recordId,
          '$stageId|$stageAttempt',
        );
        if (acquiredRewards.contains(useRecord)) continue;
        if (!inventory.canUseForStage(runRewardStageRecordGuardId, stageId)) {
          break;
        }
        acquiredRewards.add(useRecord);
        recordGuardApplied = true;
        break;
      }
    }
    if (recordGuardApplied) {
      effectiveShotCount = math.max(1, shotCount - 1).toInt();
    }
    final scores = Map<String, int>.from(current.chainScoresPerStage);
    if (chainScore != null) {
      scores[stageId] = math.max(scores[stageId] ?? 0, chainScore);
    }
    final shots = Map<String, int>.from(current.shotsPerStage)
      ..[stageId] = math.min(
        current.shotsPerStage[stageId] ?? effectiveShotCount,
        effectiveShotCount,
      );
    final challenges = Map<String, bool>.from(current.optionalChallenges);
    if (effectiveChallenge) {
      challenges['$stageId:${current.currentPatternId}'] = true;
    }
    StagePatternDraw? nextDraw;
    Iterable<PatternDrawRecord> history = current.patternDrawHistory;
    Map<String, StageShuffleBagState> bags = current.stageShuffleBags;
    if (nextStageId != null) {
      final nextStage = catalog.stageById(nextStageId);
      if (current.nextStageId == nextStageId) {
        nextDraw = _restoreNextDraw(nextStage, current);
      } else {
        final bag =
            current.stageShuffleBags[nextStageId] ??
            StageShuffleBagState.initial(nextStageId);
        nextDraw = (nextStageDrawPolicy ?? StageShuffleBag.draw)(
          stage: nextStage,
          state: bag,
          rootSeed: current.rootSeed,
        );
        history = [
          ...current.patternDrawHistory,
          PatternDrawRecord.fromDraw(nextDraw),
        ];
        bags = Map<String, StageShuffleBagState>.from(current.stageShuffleBags)
          ..[nextStageId] = nextDraw.nextState;
      }
    }
    final next = _copyState(
      current,
      phase: RunPhase.stageCompleted,
      nextDraw: nextDraw,
      patternDrawHistory: history,
      stageShuffleBags: bags,
      shotsPerStage: shots,
      chainScoresPerStage: scores,
      optionalChallenges: challenges,
      acquiredRewards: acquiredRewards,
      totalScore: scores.values.fold<int>(0, (sum, score) => sum + score),
    );
    await _store.save(next);
    _state = next;
    return (
      optionalChallengeAchieved:
          challenges['$stageId:${current.currentPatternId}'] ?? false,
      shotCount: effectiveShotCount,
    );
  }

  Future<List<RunReward>> prepareRewardSelection({
    required String stageId,
    bool includeNextStageHint = true,
  }) => _enqueueOperation(
    () => _prepareRewardSelection(
      stageId: stageId,
      includeNextStageHint: includeNextStageHint,
    ),
  );

  Future<List<RunReward>> _prepareRewardSelection({
    required String stageId,
    required bool includeNextStageHint,
  }) async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.currentStageId != stageId) {
      throw StateError('현재 단계의 보상 후보를 준비할 수 없습니다.');
    }
    final restoringSelection =
        current.phase == RunPhase.rewardSelectionPending ||
        current.phase == RunPhase.rewardSelectionCompleted;
    if (restoringSelection) {
      final restored = _knownRewardsByIds(current.rewardCandidateIds);
      final selectedIsKnown =
          current.selectedRewardId == null ||
          restored.any((reward) => reward.id == current.selectedRewardId);
      final restoredHintIsSupported =
          includeNextStageHint ||
          !restored.any(
            (reward) => reward.id == runRewardNextStageHintAccessId,
          );
      if (restored.length == RunRewardCandidateGenerator.candidateCount &&
          restoredHintIsSupported &&
          selectedIsKnown) {
        return restored;
      }
    } else if (current.phase != RunPhase.stageCompleted) {
      throw StateError('클리어가 저장된 뒤에만 보상 후보를 준비할 수 있습니다.');
    }
    final generator = RunRewardCandidateGenerator();
    final restorationRewardExclusions = <String>{
      if (current.acquiredRewards.contains(runRewardFailureCauseBoostId))
        runRewardFailureCauseBoostId,
      if (current.acquiredRewards.contains(runRewardPrecisionChargeId))
        runRewardPrecisionChargeId,
    };
    final lighthouseAccessRestored = current.acquiredRewards.contains(
      restorationLighthouseAccessMarker,
    );
    final rewards = generator.generate(
      rootSeed: current.rootSeed,
      stageId: stageId,
      patternSeed: current.currentPatternSeed!,
      includeNextStageHint:
          includeNextStageHint &&
          current.nextStageId != null &&
          !lighthouseAccessRestored,
      excludedRewardIds: restorationRewardExclusions,
    );
    final previousSelection = RunRewardInventory(
      current.acquiredRewards,
    ).selectionFor(stageId: stageId, patternSeed: current.currentPatternSeed!);
    final previousRewardId = previousSelection?.rewardId;
    final restoredRewardId =
        rewards.any((reward) => reward.id == previousRewardId)
        ? previousRewardId
        : null;
    final next = _copyState(
      current,
      phase: restoredRewardId == null
          ? RunPhase.rewardSelectionPending
          : RunPhase.rewardSelectionCompleted,
      nextDraw: _savedNextDraw(current),
      rewardCandidateSeed: generator.candidateSeed(
        rootSeed: current.rootSeed,
        stageId: stageId,
        patternSeed: current.currentPatternSeed!,
      ),
      rewardCandidateIds: rewards.map((reward) => reward.id),
      selectedRewardId: restoredRewardId,
    );
    await _store.save(next);
    _state = next;
    return rewards;
  }

  Future<RunReward> selectReward(String rewardId) =>
      _enqueueOperation(() => _selectReward(rewardId));

  Future<RunReward> _selectReward(String rewardId) async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.rewardSelectionPending) {
      throw StateError('선택을 기다리는 보상 후보가 없습니다.');
    }
    if (!current.rewardCandidateIds.contains(rewardId)) {
      throw StateError('현재 후보에 없는 보상은 선택할 수 없습니다.');
    }
    final reward = _rewardsByIds([rewardId]).single;
    final selectionRecord = runRewardSelectionRecordId(
      stageId: current.currentStageId!,
      patternSeed: current.currentPatternSeed!,
      rewardId: rewardId,
    );
    final alreadyAcquired = current.acquiredRewards.contains(selectionRecord);
    var entitlements = current.hintEntitlements;
    if (!alreadyAcquired &&
        reward.effectKind == RunRewardEffectKind.nextStageHintAccess) {
      final nextStageId = current.nextStageId;
      final nextPatternId = current.nextStagePatternId;
      if (nextStageId == null || nextPatternId == null) {
        throw StateError('다음 단계가 없는 런에는 다음 스테이지 팁을 선택할 수 없습니다.');
      }
      entitlements = _mergeHintEntitlement(
        entitlements,
        HintIdentity(
          stageId: nextStageId,
          patternId: nextPatternId,
          hintVersion: _hintVersionFor(nextStageId, nextPatternId),
        ),
        HintEntitlementSource.clearReward,
      );
    }
    final next = _copyState(
      current,
      phase: RunPhase.rewardSelectionCompleted,
      nextDraw: _savedNextDraw(current),
      selectedRewardId: rewardId,
      cloneCoreCount:
          current.cloneCoreCount +
          (!alreadyAcquired &&
                  reward.effectKind == RunRewardEffectKind.cloneCore
              ? 1
              : 0),
      acquiredRewards: [...current.acquiredRewards, rewardId, selectionRecord],
      hintEntitlements: entitlements,
    );
    await _store.save(next);
    _state = next;
    return reward;
  }

  /// 물리 resolver가 확정한 직접 공 접촉을 저장한다. 같은 key는 재시작·복원
  /// 뒤에도 한 번만 entitlement에 병합된다.
  Future<bool> recordKeyCollection({
    required String keyId,
    required String sourceBallId,
    required int shotIndex,
    int? hintVersion,
  }) => _enqueueOperation(
    () => _recordKeyCollection(
      keyId: keyId,
      sourceBallId: sourceBallId,
      shotIndex: shotIndex,
      hintVersion: hintVersion,
    ),
  );

  Future<bool> _recordKeyCollection({
    required String keyId,
    required String sourceBallId,
    required int shotIndex,
    required int? hintVersion,
  }) async {
    final directBall =
        sourceBallId == 'active_ball' || sourceBallId.startsWith('spent_ball_');
    if (keyId.trim().isEmpty ||
        sourceBallId.trim().isEmpty ||
        !directBall ||
        shotIndex < 0) {
      throw ArgumentError('열쇠 수집 정보가 올바르지 않습니다.');
    }
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) {
      throw StateError('플레이 중에만 열쇠를 수집할 수 있습니다.');
    }
    final resolvedHintVersion =
        hintVersion ??
        _hintVersionFor(current.currentStageId!, current.currentPatternId!);
    final identity = HintIdentity(
      stageId: current.currentStageId!,
      patternId: current.currentPatternId!,
      hintVersion: resolvedHintVersion,
    );
    final duplicate = current.keyCollections.any(
      (record) => record.storageKey == '${identity.storageKey}\u0000$keyId',
    );
    if (duplicate) return false;
    final entitlements = _mergeHintEntitlement(
      current.hintEntitlements,
      identity,
      HintEntitlementSource.stageKey,
    );
    final collections = [
      ...current.keyCollections,
      KeyCollectionRecord(
        identity: identity,
        keyId: keyId,
        sourceBallId: sourceBallId,
        shotIndex: shotIndex,
        acquiredAt: _now().toUtc(),
      ),
    ];
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      hintEntitlements: entitlements,
      keyCollections: collections,
    );
    await _store.save(next);
    _state = next;
    return true;
  }

  /// 실패한 발사만 누적한다. 단계 완료 score와 달리 현재 시도 중에도 힌트
  /// 레벨 해금에 사용할 수 있다.
  Future<RunHintEntitlement?> recordHintFailure({int? hintVersion}) =>
      _enqueueOperation(() => _recordHintFailure(hintVersion));

  Future<RunHintEntitlement?> _recordHintFailure(int? hintVersion) async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) return null;
    final resolvedHintVersion =
        hintVersion ??
        _hintVersionFor(current.currentStageId!, current.currentPatternId!);
    final identity = HintIdentity(
      stageId: current.currentStageId!,
      patternId: current.currentPatternId!,
      hintVersion: resolvedHintVersion,
    );
    final existing = _hintEntitlementFor(current, identity);
    final updated = existing == null
        ? RunHintEntitlement(
            identity: identity,
            sources: const [HintEntitlementSource.failureAssist],
            failedShotCount: 1,
            acquiredAt: _now().toUtc(),
          )
        : existing.copyWith(failedShotCount: existing.failedShotCount + 1);
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      hintEntitlements: existing == null
          ? List.unmodifiable([...current.hintEntitlements, updated])
          : _replaceHintEntitlement(current.hintEntitlements, updated),
    );
    await _store.save(next);
    _state = next;
    return updated;
  }

  /// 접근권을 소모하지 않고 열람 상태와 요청한 힌트 레벨만 저장한다.
  Future<RunHintEntitlement?> openHint({
    int? hintVersion,
    int? requestedLevel,
  }) => _enqueueOperation(
    () => _openHint(hintVersion: hintVersion, requestedLevel: requestedLevel),
  );

  Future<RunHintEntitlement?> _openHint({
    required int? hintVersion,
    required int? requestedLevel,
  }) async {
    if (requestedLevel != null && (requestedLevel < 1 || requestedLevel > 2)) {
      throw ArgumentError.value(
        requestedLevel,
        'requestedLevel',
        '현재 HintCatalog 계약의 1~2단계여야 합니다.',
      );
    }
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) return null;
    final resolvedHintVersion =
        hintVersion ??
        _hintVersionFor(current.currentStageId!, current.currentPatternId!);
    final identity = HintIdentity(
      stageId: current.currentStageId!,
      patternId: current.currentPatternId!,
      hintVersion: resolvedHintVersion,
    );
    final existing = _hintEntitlementFor(current, identity);
    if (existing == null) return null;
    final allowedByFailures = existing.failedShotCount >= 2 ? 2 : 1;
    final requested = requestedLevel ?? 1;
    // L1을 읽은 뒤의 "한 단계 더 구체적으로" 요청은 실패 횟수와 무관하게
    // 바로 다음 단계까지만 허용한다. 현재 카탈로그는 모든 패턴이 L1/L2로
    // 고정되어 있으므로 저장 계층도 존재하지 않는 L3를 만들지 않는다.
    final allowedByExplicitRequest =
        existing.consumed && requested > existing.unlockedHintLevel
        ? math.min(2, existing.unlockedHintLevel + 1)
        : existing.unlockedHintLevel;
    final allowedLevel = math.max(allowedByFailures, allowedByExplicitRequest);
    final nextLevel = math.min(
      2,
      math.max(existing.unlockedHintLevel, math.min(requested, allowedLevel)),
    );
    final updated = existing.copyWith(
      unlockedHintLevel: nextLevel,
      consumed: true,
      openedCount: existing.openedCount + 1,
      failureCountAtFirstOpen: existing.consumed
          ? existing.failureCountAtFirstOpen
          : existing.failedShotCount,
    );
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      hintEntitlements: _replaceHintEntitlement(
        current.hintEntitlements,
        updated,
      ),
    );
    await _store.save(next);
    _state = next;
    return updated;
  }

  RunRewardInventory get rewardInventory =>
      RunRewardInventory(_state?.acquiredRewards ?? const []);

  Future<bool> consumeRewardUse({
    required String rewardId,
    required String useKey,
  }) => _enqueueOperation(
    () => _consumeRewardUse(rewardId: rewardId, useKey: useKey),
  );

  Future<bool> _consumeRewardUse({
    required String rewardId,
    required String useKey,
  }) async {
    if (useKey.isEmpty) {
      throw ArgumentError.value(useKey, 'useKey', '비어 있을 수 없습니다.');
    }
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) {
      throw StateError('플레이 중에만 런 보상을 사용할 수 있습니다.');
    }
    final available = RunRewardInventory(
      current.acquiredRewards,
    ).availableSelections(rewardId);
    if (available.isEmpty) return false;
    final useRecord = runRewardUseRecordId(available.first.recordId, useKey);
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      acquiredRewards: [...current.acquiredRewards, useRecord],
    );
    await _store.save(next);
    _state = next;
    return true;
  }

  Future<bool> consumeStageRewardUse({
    required String rewardId,
    required String stageId,
  }) => _enqueueOperation(
    () => _consumeStageRewardUse(rewardId: rewardId, stageId: stageId),
  );

  Future<bool> _consumeStageRewardUse({
    required String rewardId,
    required String stageId,
  }) async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) {
      throw StateError('플레이 중에만 단계 보상을 사용할 수 있습니다.');
    }
    final inventory = RunRewardInventory(current.acquiredRewards);
    for (final selection in inventory.selections.where(
      (record) => record.rewardId == rewardId,
    )) {
      final useStageId = rewardId == runRewardStageRecordGuardId
          ? '$stageId|${runStageAttemptNumber(current.acquiredRewards, stageId)}'
          : stageId;
      final useRecord = runRewardStageUseRecordId(
        selection.recordId,
        useStageId,
      );
      if (current.acquiredRewards.contains(useRecord)) continue;
      final next = _copyState(
        current,
        phase: current.phase,
        nextDraw: _savedNextDraw(current),
        acquiredRewards: [...current.acquiredRewards, useRecord],
      );
      await _store.save(next);
      _state = next;
      return true;
    }
    return false;
  }

  Future<void> completeRun() => _enqueueOperation(_completeRun);

  Future<void> _completeRun() async {
    await _loadOnce();
    final current = _state;
    if (current == null ||
        current.phase != RunPhase.rewardSelectionCompleted ||
        current.nextStageId != null) {
      throw StateError('마지막 단계의 보상 선택 뒤에만 런을 완료할 수 있습니다.');
    }
    final next = _copyState(
      current,
      phase: RunPhase.runCompleted,
      nextDraw: null,
    );
    await _store.save(next);
    _state = next;
  }

  Future<void> recordTraitAction({
    required String sourceId,
    required RunTraitAction action,
  }) => _enqueueOperation(
    () => _recordTraitAction(sourceId: sourceId, action: action),
  );

  Future<void> _recordTraitAction({
    required String sourceId,
    required RunTraitAction action,
  }) async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) {
      throw StateError('진행 중인 패턴이 없어 속성 행동을 저장할 수 없습니다.');
    }
    final stage = catalog.stageById(current.currentStageId!);
    final pattern = stage.patternById(current.currentPatternId!);
    final sourceExists = pattern.objects.any(
      (object) => object.id == sourceId && object.traits.isNotEmpty,
    );
    if (!sourceExists) {
      throw StateError('현재 패턴에 속성을 가진 원본 $sourceId이 없습니다.');
    }
    if (current.pendingTraitActions.any(
      (pending) =>
          pending.sourceId == sourceId &&
          pending.action == RunTraitAction.transfer,
    )) {
      throw StateError('이미 속성을 옮긴 원본에서는 다시 행동할 수 없습니다.');
    }
    if (action == RunTraitAction.copy && current.cloneCoreCount < 1) {
      throw StateError('사용할 수 있는 복제 코어가 없습니다.');
    }
    final next = _copyState(
      current,
      phase: RunPhase.playing,
      nextDraw: _savedNextDraw(current),
      cloneCoreCount:
          current.cloneCoreCount - (action == RunTraitAction.copy ? 1 : 0),
      pendingTraitActions: [
        ...current.pendingTraitActions,
        RunTraitActionRecord(sourceId: sourceId, action: action),
      ],
    );
    await _store.save(next);
    _state = next;
  }

  Future<bool> awardStageCloneCores({
    required String stageId,
    required int amount,
  }) => _enqueueOperation(
    () => _awardStageCloneCores(stageId: stageId, amount: amount),
  );

  Future<bool> _awardStageCloneCores({
    required String stageId,
    required int amount,
  }) async {
    if (stageId.isEmpty) {
      throw ArgumentError.value(stageId, 'stageId', '비어 있을 수 없습니다.');
    }
    if (amount < 1) {
      throw ArgumentError.value(amount, 'amount', '1 이상이어야 합니다.');
    }
    await _loadOnce();
    final current = _state;
    if (current == null ||
        (current.phase != RunPhase.playing &&
            current.phase != RunPhase.stageCompleted)) {
      throw StateError('진행 중인 런이 없어 복제 코어를 저장할 수 없습니다.');
    }
    if (current.currentStageId != stageId) {
      throw StateError('현재 단계와 다른 단계의 복제 코어 보상은 저장할 수 없습니다.');
    }
    final rewardId = stageCloneCoreRewardId(stageId);
    if (current.acquiredRewards.contains(rewardId)) return false;
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      cloneCoreCount: current.cloneCoreCount + amount,
      acquiredRewards: [...current.acquiredRewards, rewardId],
    );
    await _store.save(next);
    _state = next;
    return true;
  }

  Future<bool> migrateLegacyCloneCoreReward({required bool rewarded}) =>
      _enqueueOperation(() => _migrateLegacyCloneCoreReward(rewarded));

  Future<bool> _migrateLegacyCloneCoreReward(bool rewarded) async {
    await _loadOnce();
    final current = _state;
    if (current == null ||
        (!rewarded &&
            !current.acquiredRewards.contains(legacyStageCloneCoreRewardId))) {
      return false;
    }
    final historicalRewardId = stageCloneCoreRewardId(
      legacyCloneCoreRewardStageId,
    );
    final rewards = current.acquiredRewards.toSet();
    final changed =
        rewards.remove(legacyStageCloneCoreRewardId) |
        rewards.add(historicalRewardId);
    if (!changed) return false;
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      acquiredRewards: rewards,
    );
    await _store.save(next);
    _state = next;
    return true;
  }

  Future<bool> recordShot({
    required ShotInput input,
    bool consumeFirstImpactGuide = false,
  }) => _enqueueOperation(
    () => _recordShot(
      input: input,
      consumeFirstImpactGuide: consumeFirstImpactGuide,
    ),
  );

  Future<bool> _recordShot({
    required ShotInput input,
    required bool consumeFirstImpactGuide,
  }) async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) {
      throw StateError('진행 중인 패턴이 없어 발사를 저장할 수 없습니다.');
    }
    final currentInputs = currentShotInputs;
    for (var index = 0; index < currentInputs.length; index++) {
      if (currentInputs[index].shotIndex != index) {
        throw StateError('저장된 발사 순서가 연속적이지 않습니다.');
      }
    }
    final normalized = input.normalized();
    final acquiredRewards = current.acquiredRewards.toSet();
    var guideConsumed = false;
    if (consumeFirstImpactGuide) {
      final available = RunRewardInventory(
        acquiredRewards,
      ).availableSelections(runRewardFirstImpactGuideId);
      if (available.isEmpty) {
        throw StateError('사용할 첫 충돌 안내 보상이 없습니다.');
      }
      acquiredRewards.add(
        runRewardUseRecordId(
          available.first.recordId,
          '${current.currentStageId}:${current.currentPatternSeed}:${currentInputs.length}:첫충돌',
        ),
      );
      guideConsumed = true;
    }
    final entry = RunShotInput(
      stageId: current.currentStageId!,
      patternId: current.currentPatternId!,
      patternSeed: current.currentPatternSeed,
      shotIndex: currentInputs.length,
      direction: normalized.direction,
      power: normalized.power,
      equippedTrait: normalized.equippedTrait,
      rawDirection: normalized.rawDirection,
      rawPower: normalized.rawPower,
      assistKind: normalized.assistKind,
      assistTargetId: normalized.assistTargetId,
      holeForgivenessRadius: normalized.holeForgivenessRadius,
      traitActions: current.pendingTraitActions,
    );
    final next = _copyState(
      current,
      phase: RunPhase.playing,
      nextDraw: _savedNextDraw(current),
      shotInputLog: [...current.shotInputLog, entry],
      pendingTraitActions: const [],
      acquiredRewards: acquiredRewards,
    );
    await _store.save(next);
    _state = next;
    return guideConsumed;
  }

  Future<void> restartCurrentStage() => _enqueueOperation(_restartCurrentStage);

  /// 라이브러리에 먼저 저장된 현재 단계 리플레이를 RunState에 연결한다.
  Future<void> recordCurrentStageReplayReference({
    required String stageId,
    required String replayId,
  }) => _enqueueOperation(
    () => _recordCurrentStageReplayReference(
      stageId: stageId,
      replayId: replayId,
    ),
  );

  Future<void> _recordCurrentStageReplayReference({
    required String stageId,
    required String replayId,
  }) async {
    if (!isReplayLibraryId(replayId)) {
      throw ArgumentError.value(
        replayId,
        'replayId',
        '리플레이 식별자 형식이 올바르지 않습니다.',
      );
    }
    await _loadOnce();
    final current = _state;
    if (current == null || current.currentStageId == null) {
      throw StateError('리플레이를 연결할 진행 중인 단계가 없습니다.');
    }
    if (current.currentStageId != stageId) {
      throw StateError('현재 단계와 리플레이 참조 단계가 일치하지 않습니다.');
    }
    if (current.replayReferences[stageId] == replayId) return;
    final references = Map<String, String>.from(current.replayReferences)
      ..[stageId] = replayId;
    final next = _copyState(
      current,
      phase: current.phase,
      replayReferences: references,
    );
    await _store.save(next);
    _state = next;
  }

  Future<void> _restartCurrentStage() async {
    await _loadOnce();
    final current = _state;
    if (current == null ||
        (current.phase != RunPhase.playing &&
            current.phase != RunPhase.stageCompleted &&
            current.phase != RunPhase.rewardSelectionCompleted)) {
      return;
    }
    final next = _copyState(
      current,
      phase: RunPhase.playing,
      nextDraw: _savedNextDraw(current),
      cloneCoreCount:
          current.cloneCoreCount +
          _copyActionCount(current.pendingTraitActions) +
          currentShotInputs.fold<int>(
            0,
            (sum, input) => sum + _copyActionCount(input.traitActions),
          ),
      pendingTraitActions: const [],
      shotInputLog: [
        for (final input in current.shotInputLog)
          if (!_belongsToCurrentDraw(input, current)) input,
      ],
      clearRewardSelection: true,
      acquiredRewards: [
        ...current.acquiredRewards,
        runStageAttemptRecordId(
          current.currentStageId!,
          runStageAttemptNumber(
                current.acquiredRewards,
                current.currentStageId!,
              ) +
              1,
        ),
      ],
    );
    await _store.save(next);
    _state = next;
  }

  Future<void> rewindCurrentShot() => _enqueueOperation(_rewindCurrentShot);

  Future<void> _rewindCurrentShot() async {
    await _loadOnce();
    final current = _state;
    if (current == null || current.phase != RunPhase.playing) return;
    final matching = currentShotInputs;
    if (matching.isEmpty) return;
    final removed = matching.last;
    final log = current.shotInputLog.toList();
    final removedIndex = log.lastIndexWhere(
      (input) => identical(input, removed),
    );
    if (removedIndex < 0) {
      throw StateError('되감을 발사 기록을 찾을 수 없습니다.');
    }
    log.removeAt(removedIndex);
    final next = _copyState(
      current,
      phase: RunPhase.playing,
      nextDraw: _savedNextDraw(current),
      cloneCoreCount:
          current.cloneCoreCount +
          _copyActionCount(current.pendingTraitActions),
      pendingTraitActions: removed.traitActions,
      shotInputLog: log,
      acquiredRewards: [
        ...current.acquiredRewards,
        runStageAttemptRecordId(
          current.currentStageId!,
          runStageAttemptNumber(
                current.acquiredRewards,
                current.currentStageId!,
              ) +
              1,
        ),
      ],
    );
    await _store.save(next);
    _state = next;
  }

  Future<void> _loadOnce() async {
    if (_loaded) return;
    _state = await _store.load();
    final current = _state;
    if (current != null) {
      if (fixedRootSeed != null && current.rootSeed != fixedRootSeed) {
        throw StateError('고정된 오늘의 도전 루트 시드와 저장 상태가 다릅니다.');
      }
      if (fixedRunId != null && current.runId != fixedRunId) {
        throw StateError('고정된 오늘의 도전 런 ID와 저장 상태가 다릅니다.');
      }
      if (fixedResolverVersion != null &&
          current.resolverVersion != fixedResolverVersion) {
        throw StateError('고정된 오늘의 도전 해석기 버전과 저장 상태가 다릅니다.');
      }
    }
    await _migrateCurrentLegacyShotSeeds();
    _loaded = true;
  }

  Future<void> _migrateCurrentLegacyShotSeeds() async {
    _clearLegacyShotAmbiguity();
    final current = _state;
    if (current == null ||
        current.phase != RunPhase.playing ||
        current.currentStageId == null ||
        current.currentPatternId == null ||
        current.currentPatternSeed == null ||
        current.shotInputLog.isEmpty) {
      return;
    }
    var suffixStart = current.shotInputLog.length;
    while (suffixStart > 0) {
      final input = current.shotInputLog[suffixStart - 1];
      if (input.patternSeed != null ||
          input.stageId != current.currentStageId ||
          input.patternId != current.currentPatternId) {
        break;
      }
      suffixStart--;
    }
    if (suffixStart == current.shotInputLog.length) return;
    final suffix = current.shotInputLog.sublist(suffixStart);
    for (var index = 0; index < suffix.length; index++) {
      if (suffix[index].shotIndex != index) {
        return;
      }
    }
    final matchingDraws = current.patternDrawHistory.where(
      (record) =>
          record.stageId == current.currentStageId &&
          record.patternId == current.currentPatternId,
    );
    if (matchingDraws.length != 1 ||
        matchingDraws.single.patternSeed != current.currentPatternSeed) {
      _legacyCurrentShotHistoryAmbiguous = true;
      _ambiguousLegacyCopyActionCount = suffix.fold<int>(
        0,
        (sum, input) => sum + _copyActionCount(input.traitActions),
      );
      return;
    }
    final migrated = [
      ...current.shotInputLog.take(suffixStart),
      for (final input in suffix)
        RunShotInput(
          stageId: input.stageId,
          patternId: input.patternId,
          patternSeed: current.currentPatternSeed,
          shotIndex: input.shotIndex,
          direction: input.direction,
          power: input.power,
          equippedTrait: input.equippedTrait,
          rawDirection: input.rawDirection,
          rawPower: input.rawPower,
          assistKind: input.assistKind,
          assistTargetId: input.assistTargetId,
          holeForgivenessRadius: input.holeForgivenessRadius,
          traitActions: input.traitActions,
        ),
    ];
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      shotInputLog: migrated,
    );
    await _store.save(next);
    _state = next;
  }

  void _clearLegacyShotAmbiguity() {
    _legacyCurrentShotHistoryAmbiguous = false;
    _ambiguousLegacyCopyActionCount = 0;
  }

  bool _belongsToCurrentDraw(RunShotInput input, RunState state) {
    if (input.stageId != state.currentStageId ||
        input.patternId != state.currentPatternId) {
      return false;
    }
    if (input.patternSeed != null) {
      return input.patternSeed == state.currentPatternSeed;
    }
    final matchingDraws = state.patternDrawHistory.where(
      (record) =>
          record.stageId == input.stageId &&
          record.patternId == input.patternId,
    );
    return matchingDraws.length == 1 &&
        matchingDraws.single.patternSeed == state.currentPatternSeed;
  }

  StagePatternDraw? _savedNextDraw(RunState state) {
    final stageId = state.nextStageId;
    if (stageId == null) return null;
    return _restoreNextDraw(catalog.stageById(stageId), state);
  }

  StagePatternDraw _restoreCurrentDraw(StageDefinition stage, RunState state) {
    return _restoreDraw(
      stage,
      state,
      patternId: state.currentPatternId!,
      patternSeed: state.currentPatternSeed!,
    );
  }

  StagePatternDraw _restoreNextDraw(StageDefinition stage, RunState state) {
    return _restoreDraw(
      stage,
      state,
      patternId: state.nextStagePatternId!,
      patternSeed: state.nextStagePatternSeed!,
    );
  }

  StagePatternDraw _restoreDraw(
    StageDefinition stage,
    RunState state, {
    required String patternId,
    required int patternSeed,
  }) {
    final records = state.patternDrawHistory.where(
      (record) =>
          record.stageId == stage.stageId &&
          record.patternId == patternId &&
          record.patternSeed == patternSeed,
    );
    if (records.length != 1) {
      throw StateError('저장된 현재 패턴의 추첨 기록을 찾을 수 없습니다.');
    }
    final record = records.single;
    return StagePatternDraw(
      stageId: stage.stageId,
      patternId: patternId,
      patternSeed: patternSeed,
      cycle: record.cycle,
      drawIndex: record.drawIndex,
      pattern: stage.patternById(patternId),
      nextState: state.stageShuffleBags[stage.stageId]!,
    );
  }

  RunHintEntitlement? _hintEntitlementFor(
    RunState state,
    HintIdentity identity,
  ) {
    for (final entitlement in state.hintEntitlements) {
      if (entitlement.identity.storageKey == identity.storageKey) {
        return entitlement;
      }
    }
    return null;
  }

  List<RunHintEntitlement> _mergeHintEntitlement(
    Iterable<RunHintEntitlement> values,
    HintIdentity identity,
    HintEntitlementSource source,
  ) {
    final existing = values
        .where(
          (entitlement) =>
              entitlement.identity.storageKey == identity.storageKey,
        )
        .toList(growable: false);
    if (existing.length > 1) {
      throw StateError('같은 패턴·버전의 힌트 접근권이 중복 저장되었습니다.');
    }
    if (existing.isEmpty) {
      return List.unmodifiable([
        ...values,
        RunHintEntitlement(
          identity: identity,
          sources: [source],
          acquiredAt: _now().toUtc(),
        ),
      ]);
    }
    final merged = existing.single.copyWith(
      sources: {...existing.single.sources, source},
    );
    return _replaceHintEntitlement(values, merged);
  }

  List<RunHintEntitlement> _replaceHintEntitlement(
    Iterable<RunHintEntitlement> values,
    RunHintEntitlement replacement,
  ) => List.unmodifiable([
    for (final value in values)
      if (value.identity.storageKey == replacement.identity.storageKey)
        replacement
      else
        value,
  ]);

  RunState _withCurrentDraw(
    RunState state,
    StagePatternDraw draw, {
    bool appendHistory = true,
  }) {
    final history = appendHistory
        ? [...state.patternDrawHistory, PatternDrawRecord.fromDraw(draw)]
        : state.patternDrawHistory;
    final bags = Map<String, StageShuffleBagState>.from(state.stageShuffleBags)
      ..[draw.stageId] = draw.nextState;
    return _copyState(
      state,
      phase: RunPhase.playing,
      currentStageId: draw.stageId,
      currentPatternId: draw.patternId,
      currentPatternSeed: draw.patternSeed,
      patternDrawHistory: history,
      stageShuffleBags: bags,
      clearRewardSelection: true,
    );
  }

  RunState _copyState(
    RunState state, {
    required RunPhase phase,
    StagePatternDraw? nextDraw,
    String? currentStageId,
    String? currentPatternId,
    int? currentPatternSeed,
    Iterable<PatternDrawRecord>? patternDrawHistory,
    Map<String, StageShuffleBagState>? stageShuffleBags,
    Map<String, int>? shotsPerStage,
    Map<String, int>? chainScoresPerStage,
    Map<String, bool>? optionalChallenges,
    int? totalScore,
    Iterable<RunShotInput>? shotInputLog,
    int? cloneCoreCount,
    Iterable<RunTraitActionRecord>? pendingTraitActions,
    Iterable<String>? acquiredRewards,
    Map<String, String>? replayReferences,
    Iterable<RunHintEntitlement>? hintEntitlements,
    Iterable<KeyCollectionRecord>? keyCollections,
    int? rewardCandidateSeed,
    Iterable<String>? rewardCandidateIds,
    String? selectedRewardId,
    bool clearRewardSelection = false,
  }) {
    final now = _now().toUtc();
    final updatedAt = now.isAfter(state.updatedAt) ? now : state.updatedAt;
    return RunState(
      schemaVersion: state.schemaVersion,
      runId: state.runId,
      rootSeed: state.rootSeed,
      resolverVersion: state.resolverVersion,
      phase: phase,
      currentStageId: currentStageId ?? state.currentStageId,
      currentPatternId: currentPatternId ?? state.currentPatternId,
      currentPatternSeed: currentPatternSeed ?? state.currentPatternSeed,
      nextStageId: nextDraw?.stageId,
      nextStagePatternId: nextDraw?.patternId,
      nextStagePatternSeed: nextDraw?.patternSeed,
      patternDrawHistory: patternDrawHistory ?? state.patternDrawHistory,
      stageShuffleBags: stageShuffleBags ?? state.stageShuffleBags,
      rewardCandidateSeed: clearRewardSelection
          ? null
          : rewardCandidateSeed ?? state.rewardCandidateSeed,
      rewardCandidateIds: clearRewardSelection
          ? const []
          : rewardCandidateIds ?? state.rewardCandidateIds,
      selectedRewardId: clearRewardSelection
          ? null
          : selectedRewardId ?? state.selectedRewardId,
      acquiredRewards: acquiredRewards ?? state.acquiredRewards,
      cloneCoreCount: cloneCoreCount ?? state.cloneCoreCount,
      pendingTraitActions: pendingTraitActions ?? state.pendingTraitActions,
      shotsPerStage: shotsPerStage ?? state.shotsPerStage,
      chainScoresPerStage: chainScoresPerStage ?? state.chainScoresPerStage,
      optionalChallenges: optionalChallenges ?? state.optionalChallenges,
      totalScore: totalScore ?? state.totalScore,
      replayReferences: replayReferences ?? state.replayReferences,
      shotInputLog: shotInputLog ?? state.shotInputLog,
      hintEntitlements: hintEntitlements ?? state.hintEntitlements,
      keyCollections: keyCollections ?? state.keyCollections,
      startedAt: state.startedAt,
      updatedAt: updatedAt,
    );
  }

  int _newRootSeed() => _now().toUtc().microsecondsSinceEpoch & 0xffffffff;

  int _copyActionCount(Iterable<RunTraitActionRecord> actions) {
    return actions
        .where((action) => action.action == RunTraitAction.copy)
        .length;
  }

  Future<T> _enqueueOperation<T>(Future<T> Function() operation) {
    final next = _operationTail.then((_) => operation());
    _operationTail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  List<RunReward> _knownRewardsByIds(Iterable<String> ids) {
    final byId = {
      for (final reward in defaultRunRewardCatalog.rewards) reward.id: reward,
    };
    final rewards = <RunReward>[];
    for (final id in ids) {
      final reward = byId[id];
      if (reward != null) rewards.add(reward);
    }
    return List.unmodifiable(rewards);
  }

  List<RunReward> _rewardsByIds(Iterable<String> ids) {
    final byId = {
      for (final reward in defaultRunRewardCatalog.rewards) reward.id: reward,
    };
    return List.unmodifiable([
      for (final id in ids)
        byId[id] ?? (throw StateError('저장된 보상 ID를 찾을 수 없습니다: $id')),
    ]);
  }
}
