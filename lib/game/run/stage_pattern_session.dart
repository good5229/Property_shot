import 'dart:math' as math;

import '../domain/stage_catalog.dart';
import '../domain/stage_pattern.dart';
import '../domain/shot_input.dart';
import '../persistence/run_state_store.dart';
import 'run_state.dart';
import 'stage_shuffle_bag.dart';

/// 스테이지 선택 화면과 결정론 패턴 런 상태를 연결한다.
class StagePatternSession {
  StagePatternSession({
    required this.catalog,
    required this.store,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final StageCatalog catalog;
  final RunStateStore store;
  final DateTime Function() _now;
  RunState? _state;
  bool _loaded = false;
  bool _legacyCurrentShotHistoryAmbiguous = false;
  int _ambiguousLegacyCopyActionCount = 0;

  RunState? get state => _state;

  bool get legacyCurrentShotHistoryAmbiguous =>
      _legacyCurrentShotHistoryAmbiguous;

  int get ambiguousLegacyCopyActionCount => _ambiguousLegacyCopyActionCount;

  Future<RunState?> loadState() async {
    await _loadOnce();
    return _state;
  }

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
        current.phase == RunPhase.playing &&
        current.currentStageId == stageId) {
      return _restoreCurrentDraw(stage, current);
    }
    if (current != null &&
        current.phase == RunPhase.stageCompleted &&
        current.nextStageId == stageId) {
      final draw = _restoreNextDraw(stage, current);
      final next = _withCurrentDraw(current, draw, appendHistory: false);
      await store.save(next);
      _state = next;
      _clearLegacyShotAmbiguity();
      return draw;
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

    final rootSeed = current?.rootSeed ?? _newRootSeed();
    final bag =
        current?.stageShuffleBags[stageId] ??
        StageShuffleBagState.initial(stageId);
    final draw = StageShuffleBag.draw(
      stage: stage,
      state: bag,
      rootSeed: rootSeed,
    );
    final initialRewardStageIds = initialCloneCoreRewardedStageIds
        .where((id) => id.isNotEmpty)
        .toSet();
    final next = current == null
        ? RunState.initial(
            runId: 'run_${_now().toUtc().microsecondsSinceEpoch}',
            rootSeed: rootSeed,
            resolverVersion: 'shot-resolver-v1',
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
    await store.save(next);
    _state = next;
    _clearLegacyShotAmbiguity();
    return draw;
  }

  Future<void> completeCurrentStage({
    required String stageId,
    required int shotCount,
    String? nextStageId,
    int? chainScore,
    bool optionalChallengeAchieved = false,
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
      return;
    }
    final scores = Map<String, int>.from(current.chainScoresPerStage);
    if (chainScore != null) {
      scores[stageId] = math.max(scores[stageId] ?? 0, chainScore);
    }
    final shots = Map<String, int>.from(current.shotsPerStage)
      ..[stageId] = math.min(
        current.shotsPerStage[stageId] ?? shotCount,
        shotCount,
      );
    final challenges = Map<String, bool>.from(current.optionalChallenges);
    if (optionalChallengeAchieved) {
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
        nextDraw = StageShuffleBag.draw(
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
      totalScore: scores.values.fold<int>(0, (sum, score) => sum + score),
    );
    await store.save(next);
    _state = next;
  }

  Future<void> recordTraitAction({
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
    await store.save(next);
    _state = next;
  }

  Future<bool> awardStageCloneCores({
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
    await store.save(next);
    _state = next;
    return true;
  }

  Future<bool> migrateLegacyCloneCoreReward({required bool rewarded}) async {
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
    await store.save(next);
    _state = next;
    return true;
  }

  Future<RunShotInput> recordShot({required ShotInput input}) async {
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
    final entry = RunShotInput(
      stageId: current.currentStageId!,
      patternId: current.currentPatternId!,
      patternSeed: current.currentPatternSeed,
      shotIndex: currentInputs.length,
      direction: normalized.direction,
      power: normalized.power,
      equippedTrait: normalized.equippedTrait,
      traitActions: current.pendingTraitActions,
    );
    final next = _copyState(
      current,
      phase: RunPhase.playing,
      nextDraw: _savedNextDraw(current),
      shotInputLog: [...current.shotInputLog, entry],
      pendingTraitActions: const [],
    );
    await store.save(next);
    _state = next;
    return entry;
  }

  Future<void> restartCurrentStage() async {
    await _loadOnce();
    final current = _state;
    if (current == null ||
        (current.phase != RunPhase.playing &&
            current.phase != RunPhase.stageCompleted)) {
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
    );
    await store.save(next);
    _state = next;
  }

  Future<void> rewindCurrentShot() async {
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
    );
    await store.save(next);
    _state = next;
  }

  Future<void> _loadOnce() async {
    if (_loaded) return;
    _state = await store.load();
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
          traitActions: input.traitActions,
        ),
    ];
    final next = _copyState(
      current,
      phase: current.phase,
      nextDraw: _savedNextDraw(current),
      shotInputLog: migrated,
    );
    await store.save(next);
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
      rewardCandidateSeed: null,
      rewardCandidateIds: const [],
      selectedRewardId: null,
      acquiredRewards: acquiredRewards ?? state.acquiredRewards,
      cloneCoreCount: cloneCoreCount ?? state.cloneCoreCount,
      pendingTraitActions: pendingTraitActions ?? state.pendingTraitActions,
      shotsPerStage: shotsPerStage ?? state.shotsPerStage,
      chainScoresPerStage: chainScoresPerStage ?? state.chainScoresPerStage,
      optionalChallenges: optionalChallenges ?? state.optionalChallenges,
      totalScore: totalScore ?? state.totalScore,
      replayReferences: state.replayReferences,
      shotInputLog: shotInputLog ?? state.shotInputLog,
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
}
