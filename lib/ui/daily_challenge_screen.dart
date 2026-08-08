import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/analysis/creative_chain_score.dart';
import '../game/domain/game_state.dart';
import '../game/domain/level_definition.dart';
import '../game/domain/shot_input.dart';
import '../game/domain/stage_catalog.dart';
import '../game/levels/generated_stage_catalog.dart';
import '../game/persistence/daily_challenge_record_store.dart';
import '../game/persistence/run_state_store.dart';
import '../game/run/daily_challenge.dart';
import '../game/run/run_reward.dart';
import '../game/run/run_state.dart';
import '../game/run/stage_pattern_session.dart';
import '../game/run/stage_shuffle_bag.dart';
import '../game/simulation/trait_resolver.dart';
import '../game/simulation/shot_resolver.dart';
import 'game_screen.dart';
import 'tutorial_experiment.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

enum _DailyScreenView { overview, playing, result }

const List<String> dailyChallengeExpectedStageOrder = [
  'stage_heavy',
  'stage_bouncy',
  'stage_chain_gate',
  'stage_balloon',
  'stage_drained',
  'stage_speed',
  'stage_persistent',
  'stage_chain_score',
  'stage_rotating_reflector',
  'stage_property_shot',
];

void validateDailyChallengeStageOrder(StageCatalog catalog) {
  final actual = catalog.stages
      .map((stage) => stage.stageId)
      .toList(growable: false);
  if (!listEquals(actual, dailyChallengeExpectedStageOrder)) {
    throw StateError('오늘의 도전 생성 카탈로그 순서가 제품 계약과 다릅니다.');
  }
}

void validateDailyChallengeRunCompletable(RunState state) {
  final hasEveryShot = dailyChallengeExpectedStageOrder.every(
    state.shotsPerStage.containsKey,
  );
  final hasEveryDraw = dailyChallengeExpectedStageOrder.every(
    (stageId) =>
        state.patternDrawHistory.any((draw) => draw.stageId == stageId),
  );
  if (!hasEveryShot || !hasEveryDraw) {
    throw StateError('열 단계가 모두 완료된 오늘의 도전만 결과로 확정할 수 있습니다.');
  }
}

/// 날짜·모드·시도 단위로 일반 섬 진행과 분리된 오늘의 도전 화면이다.
class DailyChallengeScreen extends StatefulWidget {
  const DailyChallengeScreen({
    super.key,
    this.onExit,
    this.now,
    this.loadPreferences,
    this.showDebugControls = false,
    this.tutorialVariant = TutorialExperimentVariant.guided,
  });

  final VoidCallback? onExit;
  final DateTime Function()? now;
  final SharedPreferencesLoader? loadPreferences;
  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;

  @override
  State<DailyChallengeScreen> createState() => _DailyChallengeScreenState();
}

class _DailyChallengeScreenState extends State<DailyChallengeScreen>
    with WidgetsBindingObserver {
  late final DateTime Function() _now;
  late final SharedPreferencesLoader _loadPreferences;
  late DailyChallengeDefinition _definition;
  DailyChallengeRecordStore? _recordStore;
  DailyChallengeRecord _record = DailyChallengeRecord.empty(
    DailyChallengeDefinition.fromDateKey('2000-01-01'),
  );
  DailyChallengeRunStateStorage? _runStorage;
  StagePatternSession? _session;
  DailyChallengeMode? _activeMode;
  DailyChallengeMode _completedMode = DailyChallengeMode.official;
  _DailyScreenView _view = _DailyScreenView.overview;
  bool _loading = true;
  bool _busy = false;
  Future<void> _transitionTail = Future<void>.value();
  int? _activeStage;
  LevelDefinition? _activeLevel;
  GameState? _activeState;
  List<ShotResult> _activeShotResults = const [];
  List<RunReward> _activeRewardCandidates = const [];
  String? _activeSelectedRewardId;
  Set<String> _activeAcquiredRewards = const {};
  int _activeTotalScore = 0;
  int _completedScore = 0;
  int _completedShots = 0;
  int _completedRewardCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _now = widget.now ?? DateTime.now;
    _loadPreferences = widget.loadPreferences ?? SharedPreferences.getInstance;
    WidgetsBinding.instance.addObserver(this);
    unawaited(_enqueueTransition(() => _refreshDateUnqueued(force: true)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshDate());
    }
  }

  Future<T> _enqueueTransition<T>(Future<T> Function() operation) {
    final next = _transitionTail.then((_) => operation());
    _transitionTail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<void> _refreshDate({bool force = false}) =>
      _enqueueTransition(() => _refreshDateUnqueued(force: force));

  Future<void> _refreshDateUnqueued({bool force = false}) async {
    final next = DailyChallengeDefinition.fromDateTime(_now());
    if (!force && next.dateKey == _definition.dateKey) {
      return;
    }
    if (mounted) {
      setState(() {
        _definition = next;
        _recordStore = null;
        _runStorage = null;
        _session = null;
        _activeMode = null;
        _activeStage = null;
        _activeLevel = null;
        _activeState = null;
        _activeShotResults = const [];
        _activeRewardCandidates = const [];
        _activeSelectedRewardId = null;
        _activeAcquiredRewards = const {};
        _activeTotalScore = 0;
        _view = _DailyScreenView.overview;
        _loading = true;
        _error = null;
      });
    } else {
      _definition = next;
    }
    try {
      _validateStageCatalogOrder();
      final preferences = await _loadPreferences();
      final store = DailyChallengeRecordStore(
        backend: SharedPreferencesRunStateBackend(preferences),
        definition: _definition,
        now: _now,
      );
      final record = await store.load();
      if (!mounted) return;
      setState(() {
        _recordStore = store;
        _record = record;
        _loading = false;
      });
      await _restoreSavedOfficialRun(record);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '오늘의 도전 정보를 불러오지 못했습니다.';
      });
      debugPrint('오늘의 도전 초기화 실패: $error');
    }
  }

  void _validateStageCatalogOrder() {
    validateDailyChallengeStageOrder(generatedStageCatalog);
  }

  Future<void> _restoreSavedOfficialRun(DailyChallengeRecord record) async {
    final attemptId = record.activeAttemptId ?? record.completedAttemptId;
    if (attemptId == null) return;
    final mode = DailyChallengeMode.official;
    final storage = await _createStorage(mode, attemptId: attemptId);
    final session = storage.createSession(
      catalog: generatedStageCatalog,
      now: _now,
    );
    try {
      final state = await session.loadState();
      if (state?.phase == RunPhase.runCompleted) {
        final reconciled = await _reconcileOfficialIfNeeded(
          storage: storage,
          record: record,
        );
        await _showCompletedRun(session, record: reconciled, mode: mode);
      }
    } on Object catch (error) {
      debugPrint('오늘의 도전 완료 상태 복구 실패: $error');
    }
  }

  Future<DailyChallengeRunStateStorage> _createStorage(
    DailyChallengeMode mode, {
    String? attemptId,
  }) async {
    if (mode == DailyChallengeMode.practice) {
      return DailyChallengeRunStateStorage.practice(definition: _definition);
    }
    final preferences = await _loadPreferences();
    return DailyChallengeRunStateStorage.official(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: _definition,
      attemptId: attemptId!,
    );
  }

  Future<void> _beginOfficial() {
    if (_busy || _recordStore == null) return Future<void>.value();
    final current = _record;
    if (current.activeAttemptId != null) {
      return _resumeOfficial();
    }
    _busy = true;
    return _enqueueTransition(() async {
      try {
        final attemptId = 'attempt_${current.officialAttemptCount + 1}';
        final record = await _recordStore!.beginOfficialAttempt(
          attemptId: attemptId,
          runId: _definition.officialRunId(attemptId),
        );
        await _startMode(
          DailyChallengeMode.official,
          attemptId: attemptId,
          record: record,
        );
      } on Object catch (error) {
        _showError('정식 도전을 시작하지 못했습니다.');
        debugPrint('정식 도전 시작 실패: $error');
      } finally {
        _busy = false;
      }
    });
  }

  Future<void> _resumeOfficial() {
    final attemptId = _record.activeAttemptId;
    if (_busy || attemptId == null) return Future<void>.value();
    _busy = true;
    return _enqueueTransition(() async {
      try {
        await _startMode(
          DailyChallengeMode.official,
          attemptId: attemptId,
          record: _record,
        );
      } on Object catch (error) {
        _showError('정식 도전을 이어 불러오지 못했습니다.');
        debugPrint('정식 도전 이어하기 실패: $error');
      } finally {
        _busy = false;
      }
    });
  }

  Future<void> _beginPractice() {
    if (_busy) return Future<void>.value();
    _busy = true;
    return _enqueueTransition(() async {
      try {
        await _startMode(DailyChallengeMode.practice);
      } on Object catch (error) {
        _showError('연습을 시작하지 못했습니다.');
        debugPrint('오늘의 도전 연습 시작 실패: $error');
      } finally {
        _busy = false;
      }
    });
  }

  Future<void> _startMode(
    DailyChallengeMode mode, {
    String? attemptId,
    DailyChallengeRecord? record,
  }) async {
    final storage = await _createStorage(mode, attemptId: attemptId);
    final session = storage.createSession(
      catalog: generatedStageCatalog,
      now: _now,
    );
    _activeMode = mode;
    await session.loadState();
    if (session.state?.phase == RunPhase.runCompleted) {
      final reconciled = await _reconcileOfficialIfNeeded(
        storage: storage,
        record: record ?? _record,
      );
      await _showCompletedRun(session, record: reconciled, mode: mode);
      return;
    }
    if (mounted) {
      setState(() {
        _record = record ?? _record;
        _runStorage = storage;
        _session = session;
      });
    }
    final stageIndex = _stageIndexForState(session.state) ?? 0;
    await _openStageUnqueued(stageIndex);
  }

  Future<DailyChallengeRecord> _reconcileOfficialIfNeeded({
    required DailyChallengeRunStateStorage storage,
    required DailyChallengeRecord record,
  }) async {
    if (storage.mode != DailyChallengeMode.official) return record;
    final store = _recordStore;
    if (store == null) throw StateError('오늘의 도전 기록 저장소가 없습니다.');
    final reconciled = await store.reconcileCompletedRun(
      runStateStorage: storage,
    );
    if (mounted) setState(() => _record = reconciled);
    return reconciled;
  }

  int? _stageIndexForState(RunState? state) {
    final stageId = state?.currentStageId;
    if (stageId == null) return null;
    final index = generatedStageCatalog.stages.indexWhere(
      (stage) => stage.stageId == stageId,
    );
    return index < 0 ? null : index;
  }

  Future<void> _openStage(int index) =>
      _enqueueTransition(() => _openStageUnqueued(index));

  Future<void> _openStageUnqueued(int index) async {
    _validateStageCatalogOrder();
    final session = _session;
    if (session == null ||
        index < 0 ||
        index >= generatedStageCatalog.stages.length) {
      return;
    }
    final stageId = generatedStageCatalog.stages[index].stageId;
    var state = await session.loadState();
    if (state == null && index != 0) {
      throw StateError('오늘의 도전은 첫 단계부터 시작해야 합니다.');
    }
    if (state?.phase == RunPhase.stageCompleted &&
        state?.currentStageId == stageId) {
      await session.prepareRewardSelection(stageId: stageId);
      state = await session.loadState();
    }
    StagePatternDraw draw;
    if (state == null) {
      draw = await session.selectStage(stageId);
    } else if (state.currentStageId == stageId) {
      draw = await session.selectStage(stageId);
    } else if (state.nextStageId == stageId) {
      draw = await session.selectStage(stageId);
    } else {
      throw StateError('오늘의 도전 단계 순서를 복원할 수 없습니다.');
    }
    final stage = generatedStageCatalog.stageById(draw.stageId);
    final level = draw.pattern.toLevelDefinition(
      stageId: draw.stageId,
      stageTitle: stage.title,
    );
    var restored = level.createState(
      index,
      productRules: true,
      copyCoreCount: session.replayStartingCloneCoreCount,
      copyCoreRewarded: false,
    );
    final results = <ShotResult>[];
    for (final saved in session.currentShotInputs) {
      restored = _restoreTraitActions(restored, saved.traitActions);
      final result = const ShotResolver().resolve(
        restored,
        ShotInput(
          direction: saved.direction,
          power: saved.power,
          equippedTrait: saved.equippedTrait,
        ),
      );
      results.add(result);
      restored = result.state;
    }
    restored = _restoreTraitActions(
      restored,
      session.state?.pendingTraitActions ?? const [],
    );
    final rewards =
        session.state?.phase == RunPhase.rewardSelectionPending ||
            session.state?.phase == RunPhase.rewardSelectionCompleted
        ? await session.prepareRewardSelection(stageId: draw.stageId)
        : const <RunReward>[];
    if (!mounted) return;
    setState(() {
      _activeStage = index;
      _activeLevel = level;
      _activeState = restored.copyWith(
        copyCoreCount: session.state?.cloneCoreCount ?? restored.copyCoreCount,
        message: results.isEmpty
            ? '방향을 정하고 공을 길게 눌러 힘을 모아 보세요.'
            : '${results.length}발 진행 상태를 복원했습니다.',
      );
      _activeShotResults = List.unmodifiable(results);
      _activeRewardCandidates = List.unmodifiable(rewards);
      _activeSelectedRewardId = session.state?.selectedRewardId;
      _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
      _activeTotalScore = session.state?.totalScore ?? 0;
      _view = _DailyScreenView.playing;
    });
  }

  GameState _restoreTraitActions(
    GameState state,
    Iterable<RunTraitActionRecord> actions,
  ) {
    const resolver = TraitResolver();
    var restored = state;
    for (final action in actions) {
      final selected = resolver.selectSource(restored, action.sourceId);
      restored = action.action == RunTraitAction.transfer
          ? resolver.transferSelectedTrait(selected)
          : resolver.copySelectedTrait(selected);
    }
    return restored;
  }

  Future<StageCompletionResult> _recordStageClear(
    int levelIndex,
    CreativeChainScoreAnalysis? analysis,
    bool optionalChallengeAchieved,
    int shotCount,
    bool applyOptionalChallengeGuard,
    bool applyStageRecordGuard,
  ) => _enqueueTransition(
    () => _recordStageClearUnqueued(
      levelIndex,
      analysis,
      optionalChallengeAchieved,
      shotCount,
      applyOptionalChallengeGuard,
      applyStageRecordGuard,
    ),
  );

  Future<StageCompletionResult> _recordStageClearUnqueued(
    int levelIndex,
    CreativeChainScoreAnalysis? analysis,
    bool optionalChallengeAchieved,
    int shotCount,
    bool applyOptionalChallengeGuard,
    bool applyStageRecordGuard,
  ) async {
    final session = _session;
    if (session == null) {
      throw StateError('오늘의 도전 세션이 없습니다.');
    }
    _validateStageCatalogOrder();
    if (levelIndex < 0 ||
        levelIndex >= dailyChallengeExpectedStageOrder.length ||
        levelIndex != _activeStage) {
      throw StateError('현재 단계와 다른 단계는 완료할 수 없습니다.');
    }
    final current = await session.loadState();
    if (current?.currentStageId !=
        dailyChallengeExpectedStageOrder[levelIndex]) {
      throw StateError('오늘의 도전 현재 단계와 완료 요청이 일치하지 않습니다.');
    }
    final stageId = generatedStageCatalog.stages[levelIndex].stageId;
    final completion = await session.completeCurrentStage(
      stageId: stageId,
      shotCount: shotCount,
      nextStageId: levelIndex + 1 < generatedStageCatalog.stages.length
          ? generatedStageCatalog.stages[levelIndex + 1].stageId
          : null,
      chainScore: analysis?.totalScore,
      optionalChallengeAchieved: optionalChallengeAchieved,
      applyOptionalChallengeGuard: applyOptionalChallengeGuard,
      applyStageRecordGuard: applyStageRecordGuard,
    );
    if (mounted) {
      setState(() {
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
        _activeTotalScore = session.state?.totalScore ?? 0;
      });
    }
    return completion;
  }

  Future<bool> _earnCopyCore(int levelIndex, int amount) =>
      _enqueueTransition(() async {
        final session = _session;
        if (session == null ||
            levelIndex < 0 ||
            levelIndex >= dailyChallengeExpectedStageOrder.length) {
          return false;
        }
        final awarded = await session.awardStageCloneCores(
          stageId: dailyChallengeExpectedStageOrder[levelIndex],
          amount: amount,
        );
        if (mounted) {
          setState(
            () => _activeAcquiredRewards =
                session.state?.acquiredRewards ?? const {},
          );
        }
        return awarded;
      });

  Future<List<RunReward>> _prepareRewards(int levelIndex) =>
      _enqueueTransition(() => _prepareRewardsUnqueued(levelIndex));

  Future<List<RunReward>> _prepareRewardsUnqueued(int levelIndex) async {
    final session = _session;
    if (session == null) return const [];
    final stageId = generatedStageCatalog.stages[levelIndex].stageId;
    final rewards = await session.prepareRewardSelection(stageId: stageId);
    if (mounted) {
      setState(() {
        _activeRewardCandidates = List.unmodifiable(rewards);
        _activeSelectedRewardId = session.state?.selectedRewardId;
      });
    }
    return rewards;
  }

  Future<RunReward> _selectReward(String rewardId) =>
      _enqueueTransition(() => _selectRewardUnqueued(rewardId));

  Future<RunReward> _selectRewardUnqueued(String rewardId) async {
    final session = _session;
    if (session == null) throw StateError('오늘의 도전 세션이 없습니다.');
    final reward = await session.selectReward(rewardId);
    if (mounted) {
      setState(() {
        _activeSelectedRewardId = reward.id;
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
      });
    }
    return reward;
  }

  Future<bool> _consumeReward(
    String rewardId,
    String useKey,
    bool stageScoped,
  ) => _enqueueTransition(
    () => _consumeRewardUnqueued(rewardId, useKey, stageScoped),
  );

  Future<bool> _consumeRewardUnqueued(
    String rewardId,
    String useKey,
    bool stageScoped,
  ) async {
    final session = _session;
    if (session == null) return false;
    final used = stageScoped
        ? await session.consumeStageRewardUse(
            rewardId: rewardId,
            stageId: useKey,
          )
        : await session.consumeRewardUse(rewardId: rewardId, useKey: useKey);
    if (used && mounted) {
      setState(() {
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
      });
    }
    return used;
  }

  Future<void> _completeRun() => _enqueueTransition(_completeRunUnqueued);

  Future<void> _completeRunUnqueued() async {
    final session = _session;
    if (session == null) throw StateError('오늘의 도전 세션이 없습니다.');
    _validateStageCatalogOrder();
    final current = await session.loadState();
    if (current == null) {
      throw StateError('완료할 오늘의 도전 런이 없습니다.');
    }
    validateDailyChallengeRunCompletable(current);
    await session.completeRun();
    final store = _recordStore;
    final storage = _runStorage;
    if (store != null &&
        storage != null &&
        storage.mode == DailyChallengeMode.official) {
      _record = await store.reconcileCompletedRun(runStateStorage: storage);
    }
    await _showCompletedRun(
      session,
      record: _record,
      mode: _activeMode ?? DailyChallengeMode.official,
    );
  }

  Future<void> _showCompletedRun(
    StagePatternSession session, {
    required DailyChallengeRecord record,
    required DailyChallengeMode mode,
  }) async {
    final state = session.state ?? await session.loadState();
    if (state == null || state.phase != RunPhase.runCompleted) return;
    if (!mounted) return;
    setState(() {
      _completedScore = state.totalScore;
      _completedShots = state.shotsPerStage.values.fold<int>(
        0,
        (sum, value) => sum + value,
      );
      _completedRewardCount = runRewardSelectionRecords(
        state.acquiredRewards,
      ).length;
      _record = record;
      _completedMode = mode;
      _view = _DailyScreenView.result;
      _activeStage = null;
      _activeLevel = null;
      _activeState = null;
    });
  }

  Future<bool> _recordShot(ShotInput input, bool consumeFirstImpactGuide) =>
      _enqueueTransition(
        () => _recordShotUnqueued(input, consumeFirstImpactGuide),
      );

  Future<bool> _recordShotUnqueued(
    ShotInput input,
    bool consumeFirstImpactGuide,
  ) async {
    final session = _session;
    if (session == null) return false;
    final consumed = await session.recordShot(
      input: input,
      consumeFirstImpactGuide: consumeFirstImpactGuide,
    );
    if (mounted) {
      setState(
        () =>
            _activeAcquiredRewards = session.state?.acquiredRewards ?? const {},
      );
    }
    return consumed;
  }

  Future<void> _recordTraitAction(String sourceId, RunTraitAction action) =>
      _enqueueTransition(() => _recordTraitActionUnqueued(sourceId, action));

  Future<void> _recordTraitActionUnqueued(
    String sourceId,
    RunTraitAction action,
  ) async {
    final session = _session;
    if (session == null) return;
    await session.recordTraitAction(sourceId: sourceId, action: action);
    if (mounted) {
      setState(
        () =>
            _activeAcquiredRewards = session.state?.acquiredRewards ?? const {},
      );
    }
  }

  Future<void> _restartStage() => _enqueueTransition(_restartStageUnqueued);

  Future<void> _restartStageUnqueued() async {
    final session = _session;
    if (session == null) return;
    await session.restartCurrentStage();
    await _openStageUnqueued(_activeStage ?? 0);
  }

  Future<Set<String>> _rewindShot() => _enqueueTransition(_rewindShotUnqueued);

  Future<Set<String>> _rewindShotUnqueued() async {
    final session = _session;
    if (session == null) return const {};
    await session.rewindCurrentShot();
    final acquired = session.state?.acquiredRewards ?? const <String>{};
    if (mounted) setState(() => _activeAcquiredRewards = acquired);
    return acquired;
  }

  void _showError(String message) {
    if (mounted) setState(() => _error = message);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        key: Key('daily_challenge_loading'),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_view == _DailyScreenView.playing &&
        _activeState != null &&
        _activeLevel != null &&
        _activeStage != null) {
      return GameScreen(
        key: ValueKey(
          'daily_stage_${_activeStage}_${_activeLevel!.patternId}',
        ),
        initialState: _activeState,
        initialShotResults: _activeShotResults,
        initialRewardCandidates: _activeRewardCandidates,
        initialSelectedRewardId: _activeSelectedRewardId,
        initialAcquiredRewards: _activeAcquiredRewards,
        levelOverride: _activeLevel,
        showStageSelector: false,
        onExit: _exitToMainMenu,
        exitToMainMenu: true,
        hudScore: _activeTotalScore,
        onCopyCoreEarned: _earnCopyCore,
        onRunLevelCleared: _recordStageClear,
        onRewardSelectionPrepared: _prepareRewards,
        onRewardSelected: _selectReward,
        onRunRewardUsed: _consumeReward,
        onRunCompleted: _completeRun,
        onStageRequested: _openStage,
        onShotCommitted: _recordShot,
        onTraitActionCommitted: _recordTraitAction,
        onStageRestarted: _restartStage,
        onShotRewound: _rewindShot,
        progressPersistencePolicy: GameProgressPersistencePolicy.disabled,
        tutorialVariant: widget.tutorialVariant,
        showDebugControls: false,
      );
    }
    if (_view == _DailyScreenView.result) {
      return DailyChallengeResultView(
        score: _completedScore,
        shots: _completedShots,
        rewards: _completedRewardCount,
        mode: _completedMode,
        record: _record,
        onNewAttempt: _newAttemptFromResult,
        onBack: _returnToOverview,
      );
    }
    return _DailyOverviewView(
      definition: _definition,
      record: _record,
      hasActiveOfficialRun: _record.activeAttemptId != null,
      busy: _busy,
      error: _error,
      onOfficial: _record.activeAttemptId == null
          ? _beginOfficial
          : _resumeOfficial,
      onPractice: _beginPractice,
      onBack: widget.onExit,
      onRefresh: () => _refreshDate(force: true),
    );
  }

  void _returnToOverview() {
    if (!mounted) return;
    setState(() {
      _view = _DailyScreenView.overview;
      _activeStage = null;
      _activeLevel = null;
      _activeState = null;
      _activeShotResults = const [];
      _activeRewardCandidates = const [];
      _activeSelectedRewardId = null;
      _activeTotalScore = 0;
    });
  }

  void _exitToMainMenu() {
    final onExit = widget.onExit;
    if (onExit != null) {
      onExit();
      return;
    }
    _returnToOverview();
  }

  Future<void> _newAttemptFromResult() async {
    if (!mounted) return;
    final mode = _completedMode;
    setState(() => _view = _DailyScreenView.overview);
    if (mode == DailyChallengeMode.practice) {
      await _beginPractice();
    } else {
      await _beginOfficial();
    }
  }
}

class _DailyOverviewView extends StatelessWidget {
  const _DailyOverviewView({
    required this.definition,
    required this.record,
    required this.hasActiveOfficialRun,
    required this.busy,
    required this.error,
    required this.onOfficial,
    required this.onPractice,
    required this.onBack,
    required this.onRefresh,
  });

  final DailyChallengeDefinition definition;
  final DailyChallengeRecord record;
  final bool hasActiveOfficialRun;
  final bool busy;
  final String? error;
  final VoidCallback onOfficial;
  final VoidCallback onPractice;
  final VoidCallback? onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('daily_challenge_overview'),
      backgroundColor: const Color(0xFFD8F0E8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      key: const Key('daily_back_button'),
                      tooltip: '메인 메뉴',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const Expanded(
                      child: Text(
                        '오늘의 도전',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('daily_refresh_button'),
                      tooltip: '오늘 날짜 다시 확인',
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DailyHeader(definition: definition),
                const SizedBox(height: 12),
                _DailyRecordPanel(record: record),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    error!,
                    key: const Key('daily_error'),
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const Key('daily_official_button'),
                  onPressed: busy ? null : onOfficial,
                  icon: const Icon(Icons.flag_rounded),
                  label: Text(hasActiveOfficialRun ? '정식 도전 이어하기' : '정식 도전'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('daily_practice_button'),
                  onPressed: busy ? null : onPractice,
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('연습'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  '정식 도전은 오늘의 기록에 반영되고, 연습은 앱을 닫으면 사라집니다.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF37655E),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyHeader extends StatelessWidget {
  const _DailyHeader({required this.definition});

  final DailyChallengeDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('daily_header'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDEAA4E), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            definition.displayDate,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.vpn_key_rounded,
                size: 20,
                color: Color(0xFF94662E),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '시드 코드 ${definition.seedCode}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          const Text('오늘은 열 단계가 같은 순서로 열립니다.', style: TextStyle(height: 1.3)),
        ],
      ),
    );
  }
}

class _DailyRecordPanel extends StatelessWidget {
  const _DailyRecordPanel({required this.record});

  final DailyChallengeRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('daily_record_panel'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8CB9A9)),
      ),
      child: Column(
        children: [
          _DailyMetric(
            label: '정식 시도 수',
            value: '${record.officialAttemptCount}회',
          ),
          _DailyMetric(label: '완료', value: record.completed ? '완료' : '진행 전'),
          _DailyMetric(
            label: '최고 총점',
            value: record.bestTotalScore > 0
                ? '${record.bestTotalScore}점'
                : '기록 없음',
          ),
          _DailyMetric(
            label: '최소 발사 합계',
            value: record.bestShotSum == null
                ? '기록 없음'
                : '${record.bestShotSum}회',
          ),
        ],
      ),
    );
  }
}

class _DailyMetric extends StatelessWidget {
  const _DailyMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class DailyChallengeResultView extends StatelessWidget {
  const DailyChallengeResultView({
    super.key,
    required this.score,
    required this.shots,
    required this.rewards,
    required this.mode,
    required this.record,
    required this.onNewAttempt,
    required this.onBack,
  });

  final int score;
  final int shots;
  final int rewards;
  final DailyChallengeMode mode;
  final DailyChallengeRecord record;
  final VoidCallback onNewAttempt;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isOfficial = mode == DailyChallengeMode.official;
    return Scaffold(
      key: const Key('daily_run_result'),
      backgroundColor: const Color(0xFFD8F0E8),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7DB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF6C9E8E), width: 2),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 54,
                      color: Color(0xFFE0A43E),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isOfficial ? '오늘의 도전 완료!' : '연습 완료!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DailyMetric(label: '총점', value: '$score점'),
                    _DailyMetric(label: '발사 합계', value: '$shots회'),
                    _DailyMetric(label: '선택 보상', value: '$rewards개'),
                    if (isOfficial)
                      _DailyMetric(
                        label: '오늘의 최고 총점',
                        value: '${record.bestTotalScore}점',
                      ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      key: const Key('daily_new_attempt_button'),
                      onPressed: onNewAttempt,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(isOfficial ? '새 정식 시도' : '다시 연습'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      key: const Key('daily_result_back_button'),
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('오늘의 도전 개요'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
