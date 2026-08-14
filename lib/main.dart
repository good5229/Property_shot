import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/analysis/creative_chain_score.dart';
import 'game/analysis/stage_chain_challenge.dart';
import 'game/analysis/stage_discovery.dart';
import 'game/domain/entity_state.dart';
import 'game/domain/game_state.dart';
import 'game/domain/geometry.dart';
import 'game/domain/level_definition.dart';
import 'game/domain/shot_input.dart';
import 'game/hint/generated_hint_catalog.dart';
import 'game/hint/demo_playback_plan.dart';
import 'game/hint/pattern_hint.dart';
import 'game/levels/generated_stage_catalog.dart';
import 'game/levels/levels.dart';
import 'game/persistence/progress_store.dart';
import 'game/persistence/replay_library_store.dart';
import 'game/persistence/run_state_store.dart';
import 'game/replay/replay_capture_service.dart';
import 'game/run/campaign_stage_selection.dart';
import 'game/run/stage_pattern_session.dart';
import 'game/run/run_state.dart';
import 'game/run/run_reward.dart';
import 'game/run/run_hint_state.dart';
import 'game/simulation/shot_resolver.dart';
import 'game/simulation/trait_resolver.dart';
import 'ui/game_feedback.dart';
import 'ui/game_screen.dart';
import 'ui/daily_challenge_screen.dart';
import 'ui/game_ball_painter.dart';
import 'ui/bonus_goal.dart';
import 'ui/play_telemetry.dart';
import 'ui/replay_library_screen.dart';
import 'ui/run_difficulty_attribution_store.dart';
import 'ui/tutorial_experiment.dart';

String _stageIntroMessage(int levelIndex) {
  return switch (levelIndex) {
    0 => '방향 조정 · 길게 누르기 · 손 떼기',
    1 => '방향 조정 · 길게 누르기 · 손 떼기',
    2 => '스위치 살피기 · 여러 경로로 도전',
    3 => '풍선 확인 · 여러 경로로 도전',
    4 => '공과 원본의 변화를 함께 살펴보세요',
    5 => '감속을 읽고 발판으로 속도를 되살려 보세요',
    6 => '첫 공을 남겨 다음 공의 쿠션과 스토퍼로 활용해 보세요',
    7 => '짧은 길과 여러 기물을 잇는 연쇄 길을 비교해 보세요',
    8 => '현재 면의 반사와 다음 충돌에 적용될 회전을 살펴보세요',
    9 => '배운 속성과 기물을 엮어 나만의 경로를 만들어 보세요',
    _ => '기물의 상태 변화를 살펴보며 여러 경로로 도전해 보세요',
  };
}

void main() {
  runApp(
    PropertyShotApp(
      showHome: true,
      showDebugControls: kDebugMode,
      demoPlanId: Uri.base.queryParameters['demo'],
    ),
  );
}

class PropertyShotApp extends StatelessWidget {
  const PropertyShotApp({
    super.key,
    this.initialState,
    this.showHome = false,
    this.showStageSelector = true,
    this.telemetry,
    this.fontFamilyOverride,
    this.loadGameAssets = true,
    this.showDebugControls = false,
    this.tutorialVariant = TutorialExperimentVariant.guided,
    this.progressStore,
    this.demoPlanId,
  });

  final GameState? initialState;
  final bool showHome;
  final bool showStageSelector;
  final LocalPlayTelemetry? telemetry;
  final String? fontFamilyOverride;
  final bool loadGameAssets;
  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;
  final ProgressStore? progressStore;
  final String? demoPlanId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '속성 한방',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: fontFamilyOverride ?? 'NanumGothic',
        fontFamilyFallback: const [
          'Apple SD Gothic Neo',
          'Noto Sans CJK KR',
          'Arial',
        ],
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6B7A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: demoPlanId == stageBouncy01DemoPlaybackPlan.id
          ? _DemoPlaybackScreen(loadGameAssets: loadGameAssets)
          : showHome && initialState == null
          ? _PropertyShotRouter(
              showDebugControls: showDebugControls,
              tutorialVariant: tutorialVariant,
              progressStore: progressStore,
              telemetry: telemetry,
            )
          : GameScreen(
              initialState: initialState,
              showStageSelector: showStageSelector,
              telemetry: telemetry,
              loadGameAssets: loadGameAssets,
              tutorialVariant: tutorialVariant,
              showDebugControls: showDebugControls,
            ),
    );
  }
}

/// 녹화 전용 고정 진입점이다. 캠페인 셔플·진행 저장과 완전히 분리하면서도
/// 실제 GameScreen, ShotResolver, 힌트·열쇠 UI와 로컬 telemetry를 그대로 쓴다.
class _DemoPlaybackScreen extends StatefulWidget {
  const _DemoPlaybackScreen({required this.loadGameAssets});

  final bool loadGameAssets;

  @override
  State<_DemoPlaybackScreen> createState() => _DemoPlaybackScreenState();
}

class _DemoPlaybackScreenState extends State<_DemoPlaybackScreen> {
  late final PatternHintEntry _hintEntry = generatedHintCatalog.entryFor(
    stageId: stageBouncy01DemoPlaybackPlan.stageId,
    patternId: stageBouncy01DemoPlaybackPlan.patternId,
  );
  late final LevelDefinition _level = generatedStageCatalog
      .stageById(stageBouncy01DemoPlaybackPlan.stageId)
      .patternById(stageBouncy01DemoPlaybackPlan.patternId)
      .toLevelDefinition(
        stageId: stageBouncy01DemoPlaybackPlan.stageId,
        stageTitle: '탄성',
      );
  late final LocalPlayTelemetry _telemetry = LocalPlayTelemetry(
    buildId: stageBouncy01DemoPlaybackPlan.id,
  );
  RunHintEntitlement? _entitlement;

  PlayTelemetryContext get _context => PlayTelemetryContext(
    stageIndex: 1,
    stageId: stageBouncy01DemoPlaybackPlan.stageId,
    patternId: stageBouncy01DemoPlaybackPlan.patternId,
    seed: stageBouncy01DemoPlaybackPlan.visualSeed,
    resolverVersion: 'shot-resolver-v1',
    rewardState: PlayTelemetryRewardState(),
  );

  @override
  void initState() {
    super.initState();
    _telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.runStarted,
        context: _context,
        result: PlayTelemetryResult.continued,
      ),
    );
    _telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: PlayTelemetryEventType.stagePatternDrawn,
        context: _context,
      ),
    );
  }

  Future<bool> _recordKey(String keyId, String sourceBallId, int shotIndex) {
    _entitlement ??= RunHintEntitlement(
      identity: HintIdentity(
        stageId: _hintEntry.stageId,
        patternId: _hintEntry.patternId,
        hintVersion: _hintEntry.hintVersion,
      ),
      sources: const [HintEntitlementSource.stageKey],
      acquiredAt: DateTime.now().toUtc(),
    );
    return Future<bool>.value(true);
  }

  Future<RunHintEntitlement?> _recordFailure() {
    final current = _entitlement;
    if (current != null) {
      _entitlement = current.copyWith(
        failedShotCount: current.failedShotCount + 1,
      );
    }
    return Future<RunHintEntitlement?>.value(_entitlement);
  }

  Future<RunHintEntitlement?> _openHint({int? requestedLevel}) {
    final current = _entitlement;
    if (current == null) return Future<RunHintEntitlement?>.value(null);
    final requested = requestedLevel ?? 1;
    if (requested < 1 || requested > 2) {
      return Future<RunHintEntitlement?>.error(
        ArgumentError.value(requested, 'requestedLevel'),
      );
    }
    final nextLevel = current.consumed && requested > current.unlockedHintLevel
        ? math.min(2, current.unlockedHintLevel + 1)
        : current.unlockedHintLevel;
    _entitlement = current.copyWith(
      consumed: true,
      openedCount: current.openedCount + 1,
      unlockedHintLevel: math.max(nextLevel, requested),
      failureCountAtFirstOpen: current.consumed
          ? current.failureCountAtFirstOpen
          : current.failedShotCount,
    );
    return Future<RunHintEntitlement?>.value(_entitlement);
  }

  @override
  Widget build(BuildContext context) => GameScreen(
    key: const Key('demo_bouncy_01_screen'),
    initialState: _level.createState(1, productRules: true),
    levelOverride: _level,
    showStageSelector: false,
    telemetry: _telemetry,
    loadGameAssets: widget.loadGameAssets,
    telemetryContextBuilder: () => _context,
    patternHintEntry: _hintEntry,
    onHintKeyCollected: _recordKey,
    onHintEntitlementRead: () async => _entitlement,
    onHintFailure: _recordFailure,
    onHintOpened: _openHint,
    onStageRestarted: () async {},
    difficulty: PlayerDifficulty.normal,
    demoLaunchInput: ShotInput(
      direction: Vec2(
        math.cos(48 * math.pi / 180),
        math.sin(48 * math.pi / 180),
      ),
      power: 0.90,
    ),
  );
}

class _PropertyShotRouter extends StatefulWidget {
  const _PropertyShotRouter({
    required this.showDebugControls,
    required this.tutorialVariant,
    this.progressStore,
    this.telemetry,
  });

  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;
  final ProgressStore? progressStore;
  final LocalPlayTelemetry? telemetry;

  @override
  State<_PropertyShotRouter> createState() => _PropertyShotRouterState();
}

class _PropertyShotRouterState extends State<_PropertyShotRouter> {
  int? _activeStage;
  int? _activePatternSeed;
  LevelDefinition? _activeLevel;
  GameState? _activeState;
  List<ShotResult> _activeShotResults = const [];
  List<ShotInput> _activeShotInputs = const [];
  List<RunReward> _activeRewardCandidates = const [];
  String? _activeSelectedRewardId;
  Set<String> _activeAcquiredRewards = const {};
  PatternHintEntry? _activePatternHintEntry;
  RunHintEntitlement? _activeHintEntitlement;
  Set<String> _activeCollectedHintKeyIds = const {};
  bool _showRunResult = false;
  int _completedRunScore = 0;
  int _completedRunBestShots = 0;
  int _completedRunRewardCount = 0;
  bool _showStageSelect = false;
  bool _showDailyChallenge = false;
  bool _showReplayLibrary = false;
  bool _showRewardInventory = false;
  Future<Set<String>>? _rewardInventoryFuture;
  bool _selectingStage = false;
  int _copyCoreCount = 0;
  bool _copyCoreRewarded = false;
  bool _legacyCopyCoreRewarded = false;
  Set<String> _copyCoreRewardedStageIds = <String>{};
  int _unlockedLevel = 0;
  Set<int> _clearedLevels = <int>{};
  Map<String, Set<String>> _discoveriesByStageId = <String, Set<String>>{};
  PlayerDifficulty _activeDifficulty = PlayerDifficulty.normal;
  late TutorialExperimentVariant _tutorialVariant = widget.tutorialVariant;
  late final ProgressStore _progressStore =
      widget.progressStore ??
      ProgressStore(
        stageCount: levels.length,
        stageIds: levels.map((level) => level.id),
      );
  late final Future<StagePatternSession> _patternSessionFuture;
  late final Future<ReplayLibraryStore> _replayLibraryFuture;
  late final Future<RunDifficultyAttributionStore>
  _difficultyAttributionStoreFuture;
  late final Future<void> _progressLoadFuture;
  late final LocalPlayTelemetry _telemetry;
  bool _runStartedRecorded = false;

  @override
  void initState() {
    super.initState();
    _telemetry = widget.telemetry ?? LocalPlayTelemetry();
    _patternSessionFuture = _createPatternSession();
    _replayLibraryFuture = _createReplayLibrary();
    _difficultyAttributionStoreFuture = _createDifficultyAttributionStore();
    _progressLoadFuture = _loadCopyCore();
  }

  Future<StagePatternSession> _createPatternSession() async {
    final preferences = await SharedPreferences.getInstance();
    return StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      hintVersionResolver: (stageId, patternId) => generatedHintCatalog
          .entryFor(stageId: stageId, patternId: patternId)
          .hintVersion,
    );
  }

  Future<ReplayLibraryStore> _createReplayLibrary() async {
    final preferences = await SharedPreferences.getInstance();
    return ReplayLibraryStore(
      backend: SharedPreferencesRunStateBackend(preferences),
    );
  }

  Future<RunDifficultyAttributionStore>
  _createDifficultyAttributionStore() async {
    final preferences = await SharedPreferences.getInstance();
    return RunDifficultyAttributionStore(preferences);
  }

  Future<void> _loadCopyCore() async {
    await GameFeedback.loadPreferences();
    unawaited(GameFeedback.activateBackgroundMusic());
    try {
      final progress = await _progressStore.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _copyCoreCount = progress.copyCoreCount;
        _legacyCopyCoreRewarded = progress.copyCoreRewarded;
        _copyCoreRewardedStageIds = progress.copyCoreRewardedStageIds;
        _clearedLevels = progress.clearedLevels;
        _unlockedLevel = progress.unlockedLevel;
        _discoveriesByStageId = {
          for (final entry in progress.discoveriesByStageId.entries)
            entry.key: {...entry.value},
        };
      });
    } on Object {
      // 저장소를 사용할 수 없어도 기본 진행 상태로 홈을 표시한다.
    }
  }

  Future<Set<String>> _loadRewardInventory() async {
    final session = await _patternSessionFuture;
    await session.loadState();
    return Set<String>.unmodifiable(
      session.state?.acquiredRewards ?? const <String>{},
    );
  }

  void _openRewardInventory() {
    setState(() {
      _rewardInventoryFuture = _loadRewardInventory();
      _showRewardInventory = true;
    });
  }

  Future<void> _startStage(
    int index, {
    bool allowStoredRunResume = false,
  }) async {
    if ((index > _unlockedLevel && !allowStoredRunResume) || _selectingStage) {
      return;
    }
    _selectingStage = true;
    try {
      await _progressLoadFuture;
      _activeDifficulty = GameFeedback.playerDifficulty;
      final session = await _patternSessionFuture;
      await session.loadState();
      await session.migrateLegacyCloneCoreReward(
        rewarded: _legacyCopyCoreRewarded && _copyCoreRewardedStageIds.isEmpty,
      );
      await _adoptCloneCoreState(session);
      await _recoverCompletedProgress(session);
      await _recoverPendingCopyCoreReward(session);
      final restoringCompletedStage =
          session.state?.currentStageId == levels[index].id &&
          switch (session.state?.phase) {
            RunPhase.stageCompleted ||
            RunPhase.rewardSelectionPending ||
            RunPhase.rewardSelectionCompleted => true,
            _ => false,
          };
      if (session.state?.phase == RunPhase.stageCompleted &&
          session.state?.currentStageId == levels[index].id) {
        await session.prepareRewardSelection(stageId: levels[index].id);
      }
      final preferBaseline =
          CampaignStageSelectionPolicy.shouldPreferTutorialBaseline(
            stageIndex: index,
            alreadyCleared: _clearedLevels.contains(index),
          );
      final stateBeforeSelection = session.state;
      final draw = await session.selectStage(
        levels[index].id,
        initialCloneCoreCount: _copyCoreCount,
        initialCloneCoreRewarded:
            _legacyCopyCoreRewarded && _copyCoreRewardedStageIds.isEmpty,
        initialCloneCoreRewardedStageIds: _copyCoreRewardedStageIds,
        drawPolicy: preferBaseline
            ? CampaignStageSelectionPolicy.drawTutorialBaselineFirst
            : null,
      );
      final selectedRunState = session.state;
      if (selectedRunState != null &&
          selectedRunState.phase == RunPhase.playing) {
        final attributionStore = await _difficultyAttributionStoreFuture;
        final existingAttribution = attributionStore.loadFor(selectedRunState);
        if (existingAttribution != null) {
          _activeDifficulty = existingAttribution.difficulty;
        } else if (!_sameStageIdentity(
          stateBeforeSelection,
          selectedRunState,
        )) {
          final attributed = await attributionStore.save(
            selectedRunState,
            _activeDifficulty,
          );
          final restoredAttribution = attributionStore.loadFor(
            selectedRunState,
          );
          if (!attributed || restoredAttribution == null) {
            throw StateError('단계 난이도 귀속 저장에 실패했습니다.');
          }
          _activeDifficulty = restoredAttribution.difficulty;
        }
      }
      await _mirrorCloneCore(session);
      _copyCoreRewarded = _isCloneCoreRewardedForStage(
        session.state,
        draw.stageId,
      );
      final level = draw.pattern.toLevelDefinition(
        stageId: draw.stageId,
        stageTitle: generatedStageCatalog.stageById(draw.stageId).title,
      );
      var restoredState = level.createState(
        index,
        productRules: true,
        copyCoreCount: session.replayStartingCloneCoreCount,
        copyCoreRewarded: _copyCoreRewarded,
      );
      final restoredResults = <ShotResult>[];
      final restoredInputs = <ShotInput>[];
      for (final saved in session.currentShotInputs) {
        restoredState = _restoreTraitActions(restoredState, saved.traitActions);
        final restoredInput = ShotInput(
          direction: saved.direction,
          power: saved.power,
          equippedTrait: saved.equippedTrait,
        ).normalized();
        final result = const ShotResolver().resolve(
          restoredState,
          restoredInput,
        );
        restoredInputs.add(restoredInput);
        restoredResults.add(result);
        restoredState = result.state;
      }
      restoredState = _restoreTraitActions(
        restoredState,
        session.state?.pendingTraitActions ?? const [],
      );
      final stageAttempt = runStageAttemptNumber(
        session.state?.acquiredRewards ?? const {},
        level.id,
      );
      final recoveredBallPrefix = '${level.id}|$stageAttempt|';
      final recoveredBallIds =
          RunRewardInventory(session.state?.acquiredRewards ?? const {})
              .useKeys(runRewardSpentBallRecoveryId)
              .where((key) => key.startsWith(recoveredBallPrefix))
              .map((key) => key.substring(recoveredBallPrefix.length))
              .toSet();
      if (recoveredBallIds.isNotEmpty) {
        restoredState = restoredState.copyWith(
          entities: [
            for (final entity in restoredState.entities)
              if (!recoveredBallIds.contains(entity.id)) entity,
          ],
        );
      }
      if (restoredState.phase == GamePhase.success &&
          session.state?.phase == RunPhase.playing) {
        final completion = await _recoverCompletedStage(
          session: session,
          levelIndex: index,
          level: level,
          results: restoredResults,
          shotCount: restoredState.shotCount,
        );
        restoredState = restoredState.copyWith(shotCount: completion.shotCount);
      } else if (restoringCompletedStage &&
          RunRewardInventory(
            session.state?.acquiredRewards ?? const {},
          ).wasUsedForStageAttempt(
            runRewardStageRecordGuardId,
            level.id,
            stageAttempt,
          )) {
        restoredState = restoredState.copyWith(
          shotCount: math.max(1, restoredState.shotCount - 1).toInt(),
        );
      }
      if (session.state?.phase == RunPhase.stageCompleted) {
        await _recoverPendingCopyCoreReward(session);
        await session.prepareRewardSelection(stageId: draw.stageId);
      }
      final rewardCandidates =
          session.state?.phase == RunPhase.rewardSelectionPending ||
              session.state?.phase == RunPhase.rewardSelectionCompleted
          ? await session.prepareRewardSelection(stageId: draw.stageId)
          : const <RunReward>[];
      PatternHintEntry? hintEntry;
      try {
        hintEntry = generatedHintCatalog.entryFor(
          stageId: draw.stageId,
          patternId: draw.patternId,
        );
      } on ArgumentError {
        // 과거 카탈로그 저장을 복원할 때도 플레이는 계속하고 힌트 UI만 숨긴다.
      }
      final selectedHintIdentity = hintEntry == null
          ? null
          : HintIdentity(
              stageId: draw.stageId,
              patternId: draw.patternId,
              hintVersion: hintEntry.hintVersion,
            );
      final collectedHintKeyIds = selectedHintIdentity == null
          ? const <String>{}
          : session.state!.keyCollections
                .where(
                  (record) =>
                      record.identity.storageKey ==
                      selectedHintIdentity.storageKey,
                )
                .map((record) => record.keyId)
                .toSet();
      restoredState = restoredState.copyWith(
        copyCoreCount: session.state?.cloneCoreCount ?? _copyCoreCount,
        copyCoreRewarded: _copyCoreRewarded,
        message: session.legacyCurrentShotHistoryAmbiguous
            ? '확인 가능한 ${restoredResults.length}발만 복원했습니다. '
                  '소속을 확인할 수 없는 구형 발사는 제외했습니다.'
                  '${session.ambiguousLegacyCopyActionCount > 0 ? ' 복제 코어는 기존 저장 수량을 유지했습니다.' : ''}'
            : restoredResults.isEmpty
            ? _stageIntroMessage(index)
            : '${restoredResults.length}발 진행 상태를 복원했습니다.',
      );
      if (!mounted) return;
      setState(() {
        _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
        _activeStage = index;
        _activePatternSeed = draw.patternSeed;
        _activeLevel = level;
        _activeState = restoredState;
        _activeShotResults = List.unmodifiable(restoredResults);
        _activeShotInputs = List.unmodifiable(restoredInputs);
        _activeRewardCandidates = rewardCandidates;
        _activeSelectedRewardId = session.state?.selectedRewardId;
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
        _activePatternHintEntry = hintEntry;
        _activeHintEntitlement = session.currentHintEntitlement;
        _activeCollectedHintKeyIds = collectedHintKeyIds;
      });
      final context = _normalTelemetryContext();
      if (!_runStartedRecorded) {
        _runStartedRecorded = true;
        _telemetry.recordTyped(
          TypedPlayTelemetryEvent(
            type: PlayTelemetryEventType.runStarted,
            context: context,
            result: PlayTelemetryResult.continued,
          ),
        );
      }
      _telemetry.recordTyped(
        TypedPlayTelemetryEvent(
          type: PlayTelemetryEventType.stagePatternDrawn,
          context: context,
        ),
      );
    } on StateError catch (error) {
      if (mounted) {
        final resumeRequired = _requiresCurrentRunResume(error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            content: Text(_stageSelectionErrorMessage(error)),
            action: resumeRequired
                ? SnackBarAction(
                    label: '이어하기',
                    onPressed: () => unawaited(_startOrResume()),
                  )
                : null,
          ),
        );
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('단계 정보를 불러오지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    } finally {
      _selectingStage = false;
    }
  }

  bool _requiresCurrentRunResume(StateError error) =>
      error.message == '보상을 먼저 선택해 주세요.' ||
      error.message == '진행 중인 단계를 먼저 이어서 플레이해 주세요.' ||
      error.message == '미리 준비된 다음 단계를 먼저 플레이해 주세요.';

  String _stageSelectionErrorMessage(StateError error) =>
      switch (error.message) {
        '보상을 먼저 선택해 주세요.' => '지금 스테이지의 클리어 보상을 선택해야 다른 섬으로 이동할 수 있어요.',
        '진행 중인 단계를 먼저 이어서 플레이해 주세요.' =>
          '다른 스테이지가 진행 중이어서 이 섬을 선택할 수 없어요. 현재 스테이지를 먼저 이어서 플레이해 주세요.',
        '미리 준비된 다음 단계를 먼저 플레이해 주세요.' =>
          '런의 순서를 유지하려면 미리 준비된 다음 스테이지를 먼저 플레이해야 해요.',
        _ => '단계 정보를 불러오지 못했습니다. 다시 시도해 주세요.',
      };

  bool _sameStageIdentity(RunState? left, RunState right) =>
      left != null &&
      left.runId == right.runId &&
      left.currentStageId == right.currentStageId &&
      left.currentPatternId == right.currentPatternId &&
      left.currentPatternSeed == right.currentPatternSeed;

  PlayTelemetryContext _normalTelemetryContext() {
    final stageIndex = _activeStage ?? 0;
    final level = _activeLevel ?? levels[stageIndex];
    return PlayTelemetryContext(
      stageIndex: stageIndex,
      stageId: level.stageId ?? level.id,
      patternId: level.patternId ?? '${level.id}_default',
      seed: _activePatternSeed ?? 0,
      resolverVersion: 'shot-resolver-v1',
      difficulty: _activeDifficulty == PlayerDifficulty.easy
          ? PlayTelemetryDifficulty.easy
          : PlayTelemetryDifficulty.normal,
      rewardState: PlayTelemetryRewardState(
        candidateIds: _activeRewardCandidates.map((reward) => reward.id),
        selectedId: _activeSelectedRewardId,
        acquiredIds: _activeAcquiredRewards,
        cloneCoreCount: _copyCoreCount,
      ),
    );
  }

  Future<void> _startOrResume() async {
    if (_selectingStage) return;
    try {
      final session = await _patternSessionFuture;
      final state = await session.loadState();
      if (state?.phase == RunPhase.runCompleted) {
        _showCompletedRunState(state!);
        return;
      }
      final stageId = state?.currentStageId;
      final restoredIndex = stageId == null
          ? -1
          : levels.indexWhere((level) => level.id == stageId);
      final targetIndex = restoredIndex < 0 ? 0 : restoredIndex;
      await _startStage(targetIndex, allowStoredRunResume: restoredIndex >= 0);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('진행 기록을 불러오지 못했습니다. 다시 시도해 주세요.')),
        );
      }
    }
  }

  void _returnHome() {
    setState(() {
      _activeStage = null;
      _activeLevel = null;
      _activeState = null;
      _activeShotResults = const [];
      _activeShotInputs = const [];
      _activeRewardCandidates = const [];
      _activeSelectedRewardId = null;
      _activeAcquiredRewards = const {};
      _showStageSelect = false;
    });
  }

  Future<bool> _earnCopyCore(int levelIndex, int amount) async {
    final session = await _patternSessionFuture;
    final awarded = await session.awardStageCloneCores(
      stageId: levels[levelIndex].id,
      amount: amount,
    );
    _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
    _copyCoreRewarded = _isCloneCoreRewardedForStage(
      session.state,
      levels[levelIndex].id,
    );
    _copyCoreRewardedStageIds = _cloneCoreRewardStageIds(session);
    try {
      await _progressStore.recordCopyCore(
        _copyCoreCount,
        _copyCoreRewardedStageIds.isNotEmpty,
        rewardedStageIds: _copyCoreRewardedStageIds,
      );
    } on Object {
      // RunState가 복제 코어의 기준이며 진행 기록은 다음 저장 때 다시 동기화한다.
    }
    if (mounted) {
      setState(() {});
    }
    return awarded;
  }

  Future<StageCompletionResult> _recordLevelClear(
    int levelIndex,
    CreativeChainScoreAnalysis? chainScore,
    bool optionalChallengeAchieved,
    int shotCount,
    bool applyOptionalChallengeGuard,
    bool applyStageRecordGuard,
  ) async {
    if (levelIndex < 0 || levelIndex >= levels.length) {
      return (
        optionalChallengeAchieved: optionalChallengeAchieved,
        shotCount: shotCount,
      );
    }
    final session = await _patternSessionFuture;
    final attributionState = session.state;
    final completionDifficulty = attributionState == null
        ? null
        : (await _difficultyAttributionStoreFuture)
              .loadFor(attributionState)
              ?.difficulty;
    final nextIndex = levelIndex + 1;
    final preferNextBaseline =
        nextIndex < levels.length &&
        CampaignStageSelectionPolicy.shouldPreferTutorialBaseline(
          stageIndex: nextIndex,
          alreadyCleared: _clearedLevels.contains(nextIndex),
        );
    final completion = await session.completeCurrentStage(
      stageId: levels[levelIndex].id,
      shotCount: shotCount,
      nextStageId: levelIndex < levels.length - 1
          ? levels[levelIndex + 1].id
          : null,
      chainScore: chainScore?.totalScore,
      optionalChallengeAchieved: optionalChallengeAchieved,
      applyOptionalChallengeGuard: applyOptionalChallengeGuard,
      applyStageRecordGuard: applyStageRecordGuard,
      nextStageDrawPolicy: preferNextBaseline
          ? CampaignStageSelectionPolicy.drawTutorialBaselineFirst
          : null,
    );
    await _saveCurrentReplay(session, totalScore: chainScore?.totalScore ?? 0);
    await _progressStore.recordStageClear(levelIndex);
    if (completionDifficulty == PlayerDifficulty.normal) {
      await _progressStore.recordBestShot(levelIndex, completion.shotCount);
      if (completion.optionalChallengeAchieved) {
        await _progressStore.recordBonusGoal(levelIndex);
      }
    }
    _applyClearedLevelInMemory(levelIndex);
    if (attributionState != null) {
      await (await _difficultyAttributionStoreFuture).clearFor(
        attributionState,
      );
    }
    if (mounted) {
      setState(() {
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
      });
    }
    return completion;
  }

  Future<void> _saveCurrentReplay(
    StagePatternSession session, {
    required int totalScore,
  }) async {
    final runState = session.state;
    if (runState == null) return;
    try {
      final document = const ReplayCaptureService().capture(
        runState: runState,
        catalog: generatedStageCatalog,
      );
      final store = await _replayLibraryFuture;
      final entry = await store.save(
        document: document,
        totalScore: totalScore,
      );
      await session.recordCurrentStageReplayReference(
        stageId: document.stageId,
        replayId: entry.replayId,
      );
    } on Object catch (error) {
      debugPrint('리플레이 자동 저장 실패: $error');
    }
  }

  Future<List<RunReward>> _prepareRunRewards(int levelIndex) async {
    if (levelIndex < 0 || levelIndex >= levels.length) return const [];
    final session = await _patternSessionFuture;
    final rewards = await session.prepareRewardSelection(
      stageId: levels[levelIndex].id,
    );
    if (mounted) {
      setState(() {
        _activeRewardCandidates = rewards;
        _activeSelectedRewardId = session.state?.selectedRewardId;
      });
    }
    return rewards;
  }

  Future<RunReward> _selectRunReward(String rewardId) async {
    final session = await _patternSessionFuture;
    final reward = await session.selectReward(rewardId);
    await _mirrorCloneCore(session);
    if (mounted) {
      setState(() {
        _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
        _activeSelectedRewardId = reward.id;
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
      });
    }
    return reward;
  }

  Future<bool> _consumeRunReward(
    String rewardId,
    String useKey,
    bool stageScoped,
  ) async {
    final session = await _patternSessionFuture;
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

  Future<void> _completeRun() async {
    final session = await _patternSessionFuture;
    await session.completeRun();
    _showCompletedRunState(session.state!);
  }

  void _showCompletedRunState(RunState state) {
    if (!mounted) return;
    setState(() {
      _completedRunScore = state.totalScore;
      _completedRunBestShots = state.shotsPerStage.values.fold<int>(
        0,
        (sum, shots) => sum + shots,
      );
      _completedRunRewardCount = runRewardSelectionRecords(
        state.acquiredRewards,
      ).length;
      _activeStage = null;
      _activeLevel = null;
      _activeState = null;
      _activeShotResults = const [];
      _activeShotInputs = const [];
      _activeRewardCandidates = const [];
      _activeSelectedRewardId = null;
      _activeAcquiredRewards = const {};
      _showRunResult = true;
    });
  }

  Future<void> _recoverPendingCopyCoreReward(
    StagePatternSession session,
  ) async {
    final state = session.state;
    if (state == null ||
        state.phase != RunPhase.stageCompleted ||
        _copyCoreRewarded) {
      return;
    }
    final stageId = state.currentStageId;
    final levelIndex = stageId == null
        ? -1
        : levels.indexWhere((level) => level.id == stageId);
    if (levelIndex < 0) return;
    final reward = levels[levelIndex].copyCoreReward;
    if (reward < 1) return;
    await session.awardStageCloneCores(stageId: stageId!, amount: reward);
    _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
    _copyCoreRewarded = _isCloneCoreRewardedForStage(session.state, stageId);
    _copyCoreRewardedStageIds = _cloneCoreRewardStageIds(session);
    try {
      await _progressStore.recordCopyCore(
        _copyCoreCount,
        _copyCoreRewardedStageIds.isNotEmpty,
        rewardedStageIds: _copyCoreRewardedStageIds,
      );
    } on Object {
      // 지급 표식과 수량은 RunState에 원자적으로 보존되어 재지급되지 않는다.
    }
  }

  Future<void> _recoverCompletedProgress(StagePatternSession session) async {
    final state = session.state;
    if (state == null ||
        (state.phase != RunPhase.stageCompleted &&
            state.phase != RunPhase.rewardSelectionPending &&
            state.phase != RunPhase.rewardSelectionCompleted)) {
      return;
    }
    final stageId = state.currentStageId;
    final levelIndex = stageId == null
        ? -1
        : levels.indexWhere((level) => level.id == stageId);
    if (levelIndex < 0) return;
    final completionDifficulty = (await _difficultyAttributionStoreFuture)
        .loadFor(state)
        ?.difficulty;
    await _progressStore.recordStageClear(levelIndex);
    if (completionDifficulty == PlayerDifficulty.normal) {
      final shotCount = state.shotsPerStage[stageId];
      if (shotCount != null) {
        await _progressStore.recordBestShot(levelIndex, shotCount);
      }
      final challengeKey = '$stageId:${state.currentPatternId}';
      if (state.optionalChallenges[challengeKey] == true) {
        await _progressStore.recordBonusGoal(levelIndex);
      }
    }
    _applyClearedLevelInMemory(levelIndex);
    await (await _difficultyAttributionStoreFuture).clearFor(state);
  }

  Future<void> _adoptCloneCoreState(StagePatternSession session) async {
    final state = session.state;
    if (state == null) return;
    _copyCoreCount = state.cloneCoreCount;
    _copyCoreRewarded = _isCloneCoreRewardedForStage(
      state,
      state.currentStageId,
    );
    _copyCoreRewardedStageIds = stageCloneCoreRewardStageIds(
      state.acquiredRewards,
    );
    try {
      await _progressStore.recordCopyCore(
        _copyCoreCount,
        _copyCoreRewardedStageIds.isNotEmpty,
        rewardedStageIds: _copyCoreRewardedStageIds,
      );
    } on Object {
      // RunState의 원자 저장값을 사용할 수 있으므로 게임 진입은 계속한다.
    }
  }

  Future<StageCompletionResult> _recoverCompletedStage({
    required StagePatternSession session,
    required int levelIndex,
    required LevelDefinition level,
    required List<ShotResult> results,
    required int shotCount,
  }) async {
    final attributionState = session.state;
    final completionDifficulty = attributionState == null
        ? null
        : (await _difficultyAttributionStoreFuture)
              .loadFor(attributionState)
              ?.difficulty;
    CreativeChainScoreAnalysis? analysis;
    var optionalChallengeAchieved = false;
    if (levelIndex == 7 && results.isNotEmpty) {
      analysis = const CreativeChainScoreAnalyzer().analyze(
        results,
        parShots: level.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
      );
      final patternId = level.patternId;
      optionalChallengeAchieved =
          patternId != null &&
          const StageChainChallengeEvaluator().isAchieved(
            patternId: patternId,
            analysis: analysis,
            results: results,
          );
    } else if (results.isNotEmpty) {
      optionalChallengeAchieved = bonusGoalReached(
        levelIndex: levelIndex,
        shotCount: shotCount,
        bumperHit: results.any(
          (result) => result.impacts.any(
            (impact) => impact.entityType == EntityType.bumper,
          ),
        ),
        switchPressed: results.any(
          (result) => result.events.contains('switch_pressed'),
        ),
        drainedSourceMoved: _drainedSourceMoved(results),
      );
    }
    final inventory = session.rewardInventory;
    final nextIndex = levelIndex + 1;
    final preferNextBaseline =
        nextIndex < levels.length &&
        CampaignStageSelectionPolicy.shouldPreferTutorialBaseline(
          stageIndex: nextIndex,
          alreadyCleared: _clearedLevels.contains(nextIndex),
        );
    final completion = await session.completeCurrentStage(
      stageId: levels[levelIndex].id,
      shotCount: shotCount,
      nextStageId: levelIndex < levels.length - 1
          ? levels[levelIndex + 1].id
          : null,
      chainScore: analysis?.totalScore,
      optionalChallengeAchieved: optionalChallengeAchieved,
      applyOptionalChallengeGuard:
          !optionalChallengeAchieved &&
          inventory.availableUseCount(runRewardOptionalChallengeGuardId) > 0,
      applyStageRecordGuard: inventory.canUseForStage(
        runRewardStageRecordGuardId,
        levels[levelIndex].id,
      ),
      nextStageDrawPolicy: preferNextBaseline
          ? CampaignStageSelectionPolicy.drawTutorialBaselineFirst
          : null,
    );
    await _progressStore.recordStageClear(levelIndex);
    if (completionDifficulty == PlayerDifficulty.normal) {
      await _progressStore.recordBestShot(levelIndex, completion.shotCount);
      if (completion.optionalChallengeAchieved) {
        await _progressStore.recordBonusGoal(levelIndex);
      }
    }
    await _recoverPendingCopyCoreReward(session);
    _applyClearedLevelInMemory(levelIndex);
    if (attributionState != null) {
      await (await _difficultyAttributionStoreFuture).clearFor(
        attributionState,
      );
    }
    return completion;
  }

  void _applyClearedLevelInMemory(int levelIndex) {
    if (!mounted) return;
    final clearedLevels = {..._clearedLevels, levelIndex};
    setState(() {
      _clearedLevels = clearedLevels;
      _unlockedLevel = math.max(
        _unlockedLevel,
        _progressStore.unlockedLevelFromCleared(clearedLevels),
      );
    });
  }

  bool _drainedSourceMoved(Iterable<ShotResult> results) {
    for (final result in results) {
      if (result.state.history.isEmpty) continue;
      final drainedIds = result.state.history.first.entities
          .where((entity) => entity.visualState == 'drained')
          .map((entity) => entity.id)
          .toSet();
      if (result.moves.any(
        (move) => drainedIds.contains(move.entityId) && move.from != move.to,
      )) {
        return true;
      }
    }
    return false;
  }

  Future<bool> _recordShot(
    ShotInput input,
    bool consumeFirstImpactGuide,
  ) async {
    final session = await _patternSessionFuture;
    final consumed = await session.recordShot(
      input: input,
      consumeFirstImpactGuide: consumeFirstImpactGuide,
    );
    if (mounted && consumed) {
      setState(() {
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
      });
    }
    return consumed;
  }

  Future<bool> _recordHintKeyCollection(
    String keyId,
    String sourceBallId,
    int shotIndex,
  ) async {
    final session = await _patternSessionFuture;
    final stored = await session.recordKeyCollection(
      keyId: keyId,
      sourceBallId: sourceBallId,
      shotIndex: shotIndex,
    );
    if (stored && mounted) {
      setState(() {
        _activeHintEntitlement = session.currentHintEntitlement;
        _activeCollectedHintKeyIds = {..._activeCollectedHintKeyIds, keyId};
      });
    }
    return stored;
  }

  Future<bool> _recordDiscoveries(Set<String> milestoneIds) async {
    final activeStage = _activeStage;
    if (activeStage == null || milestoneIds.isEmpty) return false;
    try {
      await _progressStore.recordDiscoveries(activeStage, milestoneIds);
      if (mounted) {
        final stageId = levels[activeStage].id;
        setState(() {
          _discoveriesByStageId = {
            ..._discoveriesByStageId,
            stageId: {...?_discoveriesByStageId[stageId], ...milestoneIds},
          };
        });
      }
      return true;
    } on Object {
      return false;
    }
  }

  Future<RunHintEntitlement?> _recordCurrentHintFailure() async {
    final session = await _patternSessionFuture;
    final entitlement = await session.recordHintFailure();
    if (entitlement != null && mounted) {
      setState(() => _activeHintEntitlement = entitlement);
    }
    return entitlement;
  }

  Future<RunHintEntitlement?> _openCurrentHint({int? requestedLevel}) async {
    final session = await _patternSessionFuture;
    final entitlement = await session.openHint(requestedLevel: requestedLevel);
    if (entitlement != null && mounted) {
      setState(() => _activeHintEntitlement = entitlement);
    }
    return entitlement;
  }

  Future<RunHintEntitlement?> _readCurrentHintEntitlement() async {
    final session = await _patternSessionFuture;
    return session.currentHintEntitlement;
  }

  Future<void> _recordTraitAction(
    String sourceId,
    RunTraitAction action,
  ) async {
    final session = await _patternSessionFuture;
    await session.recordTraitAction(sourceId: sourceId, action: action);
    _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
    _copyCoreRewardedStageIds = _cloneCoreRewardStageIds(session);
    try {
      await _progressStore.recordCopyCore(
        _copyCoreCount,
        _copyCoreRewardedStageIds.isNotEmpty,
        rewardedStageIds: _copyCoreRewardedStageIds,
      );
    } on Object {
      // 기준 RunState 저장이 성공했으므로 화면의 속성 행동은 계속 적용한다.
    }
  }

  Future<void> _restartStageRun() async {
    final session = await _patternSessionFuture;
    await session.restartCurrentStage();
    await _mirrorCloneCore(session);
    if (mounted) {
      setState(() {
        _activeRewardCandidates = const [];
        _activeSelectedRewardId = null;
        _activeAcquiredRewards = session.state?.acquiredRewards ?? const {};
      });
    }
  }

  Future<Set<String>> _rewindStageRun() async {
    final session = await _patternSessionFuture;
    await session.rewindCurrentShot();
    await _mirrorCloneCore(session);
    final acquiredRewards = session.state?.acquiredRewards ?? const <String>{};
    if (mounted) {
      setState(() {
        _activeAcquiredRewards = acquiredRewards;
      });
    }
    return acquiredRewards;
  }

  Future<void> _mirrorCloneCore(StagePatternSession session) async {
    _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
    _copyCoreRewardedStageIds = _cloneCoreRewardStageIds(session);
    try {
      await _progressStore.recordCopyCore(
        _copyCoreCount,
        _copyCoreRewardedStageIds.isNotEmpty,
        rewardedStageIds: _copyCoreRewardedStageIds,
      );
    } on Object {
      // RunState가 기준이므로 다음 성공한 미러 저장 때 다시 동기화한다.
    }
  }

  bool _isCloneCoreRewardedForStage(RunState? state, String? stageId) {
    if (state == null || stageId == null) return false;
    return hasStageCloneCoreReward(state.acquiredRewards, stageId);
  }

  Set<String> _cloneCoreRewardStageIds(StagePatternSession session) =>
      stageCloneCoreRewardStageIds(
        session.state?.acquiredRewards ?? const <String>[],
      );

  GameState _restoreTraitActions(
    GameState state,
    Iterable<RunTraitActionRecord> actions,
  ) {
    const resolver = TraitResolver();
    var restored = state;
    for (final action in actions) {
      final selected = resolver.selectSource(restored, action.sourceId);
      restored = switch (action.action) {
        RunTraitAction.transfer => resolver.transferSelectedTrait(selected),
        RunTraitAction.copy => resolver.copySelectedTrait(selected),
      };
    }
    return restored;
  }

  @override
  Widget build(BuildContext context) {
    if (_showRewardInventory) {
      return FutureBuilder<Set<String>>(
        future: _rewardInventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _RewardInventoryScreen(
              acquiredRewards: snapshot.requireData,
              onBack: () => setState(() => _showRewardInventory = false),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    if (_showReplayLibrary) {
      return FutureBuilder<ReplayLibraryStore>(
        future: _replayLibraryFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ReplayLibraryScreen(
              store: snapshot.requireData,
              onBack: () => setState(() => _showReplayLibrary = false),
              onReplayViewed: (document) {
                _telemetry.recordTyped(
                  TypedPlayTelemetryEvent(
                    type: PlayTelemetryEventType.replayViewed,
                    context: PlayTelemetryContext(
                      stageIndex: generatedStageCatalog.stages.indexWhere(
                        (stage) => stage.stageId == document.stageId,
                      ),
                      stageId: document.stageId,
                      patternId: document.patternId,
                      seed: document.patternSeed,
                      resolverVersion: document.resolverVersion,
                      rewardState: PlayTelemetryRewardState(
                        acquiredIds: document.acquiredRewardIds,
                        cloneCoreCount: document.initialCloneCoreCount,
                      ),
                      isReplay: true,
                    ),
                  ),
                );
              },
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    if (_showDailyChallenge) {
      return DailyChallengeScreen(
        key: const Key('daily_challenge_flow'),
        onExit: () => setState(() => _showDailyChallenge = false),
        showDebugControls: widget.showDebugControls,
        tutorialVariant: _tutorialVariant,
        telemetry: _telemetry,
      );
    }
    final activeStage = _activeStage;
    final activeLevel = _activeLevel;
    final activeState = _activeState;
    if (activeStage != null && activeLevel != null && activeState != null) {
      return GameScreen(
        key: ValueKey('stage_$activeStage:${activeLevel.patternId}'),
        initialState: activeState,
        initialShotResults: _activeShotResults,
        initialShotInputs: _activeShotInputs,
        initialRewardCandidates: _activeRewardCandidates,
        initialSelectedRewardId: _activeSelectedRewardId,
        initialAcquiredRewards: _activeAcquiredRewards,
        patternHintEntry: _activePatternHintEntry,
        initialHintEntitlement: _activeHintEntitlement,
        initialCollectedHintKeyIds: _activeCollectedHintKeyIds,
        initialDiscoveredMilestoneIds:
            _discoveriesByStageId[levels[activeStage].id] ?? const {},
        levelOverride: activeLevel,
        showStageSelector: false,
        onExit: _returnHome,
        telemetry: _telemetry,
        telemetryContextBuilder: _normalTelemetryContext,
        onCopyCoreEarned: _earnCopyCore,
        onRunLevelCleared: _recordLevelClear,
        onRewardSelectionPrepared: _prepareRunRewards,
        onRewardSelected: _selectRunReward,
        onRunRewardUsed: _consumeRunReward,
        onRunCompleted: _completeRun,
        onStageRequested: _startStage,
        onShotCommitted: _recordShot,
        onHintKeyCollected: _recordHintKeyCollection,
        onHintEntitlementRead: _readCurrentHintEntitlement,
        onHintFailure: _recordCurrentHintFailure,
        onHintOpened: _openCurrentHint,
        onDiscoveriesRecorded: _recordDiscoveries,
        onTraitActionCommitted: _recordTraitAction,
        onStageRestarted: _restartStageRun,
        onShotRewound: _rewindStageRun,
        progressStore: _progressStore,
        difficulty: _activeDifficulty,
        tutorialVariant: _tutorialVariant,
        showDebugControls: widget.showDebugControls,
      );
    }
    if (_showRunResult) {
      return _RunResultScreen(
        totalScore: _completedRunScore,
        totalBestShots: _completedRunBestShots,
        rewardCount: _completedRunRewardCount,
        onStartNewRun: () {
          setState(() => _showRunResult = false);
          unawaited(_startStage(0, allowStoredRunResume: true));
        },
        onHome: () => setState(() => _showRunResult = false),
      );
    }
    if (_showStageSelect) {
      return _StageSelectScreen(
        onBack: () => setState(() => _showStageSelect = false),
        onSelectStage: (index) => unawaited(_startStage(index)),
        unlockedLevel: _unlockedLevel,
        discoveriesByStageId: _discoveriesByStageId,
      );
    }
    return _HomeScreen(
      onStart: () => unawaited(_startOrResume()),
      onStageSelect: () => setState(() => _showStageSelect = true),
      onRewardInventory: _openRewardInventory,
      onDailyChallenge: () => setState(() => _showDailyChallenge = true),
      onReplayLibrary: () => setState(() => _showReplayLibrary = true),
      showDebugControls: widget.showDebugControls,
      tutorialVariant: _tutorialVariant,
      onTutorialVariantChanged: (variant) {
        setState(() => _tutorialVariant = variant);
      },
    );
  }
}

class _RunResultScreen extends StatelessWidget {
  const _RunResultScreen({
    required this.totalScore,
    required this.totalBestShots,
    required this.rewardCount,
    required this.onStartNewRun,
    required this.onHome,
  });

  final int totalScore;
  final int totalBestShots;
  final int rewardCount;
  final VoidCallback onStartNewRun;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('run_result_screen'),
      backgroundColor: const Color(0xFFBFE8E3),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _IslandBackdrop()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7DB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF503C2E),
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.emoji_events_rounded,
                          size: 54,
                          color: Color(0xFFF0AE34),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '첫 번째 섬 완주!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 18),
                        _RunResultRow(label: '총 연쇄 점수', value: '$totalScore점'),
                        _RunResultRow(
                          label: '단계별 최고 기록 합계',
                          value: '$totalBestShots회',
                        ),
                        _RunResultRow(
                          label: '선택한 런 보상',
                          value: '$rewardCount개',
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          key: const Key('new_run_button'),
                          onPressed: onStartNewRun,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('새 런 시작'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          key: const Key('run_result_home_button'),
                          onPressed: onHome,
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('메인 메뉴'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RunResultRow extends StatelessWidget {
  const _RunResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _RewardInventoryScreen extends StatelessWidget {
  const _RewardInventoryScreen({
    required this.acquiredRewards,
    required this.onBack,
  });

  final Set<String> acquiredRewards;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final inventory = RunRewardInventory(acquiredRewards);
    final grouped = <String, List<RunRewardSelectionRecord>>{};
    for (final record in inventory.selections) {
      grouped.putIfAbsent(record.rewardId, () => []).add(record);
    }
    final catalogById = {
      for (final reward in initialRunRewards) reward.id: reward,
    };
    final entries = grouped.entries
        .where((entry) => catalogById.containsKey(entry.key))
        .toList(growable: false);

    return Scaffold(
      key: const Key('reward_inventory_screen'),
      backgroundColor: const Color(0xFFBFE8E3),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('reward_inventory_back_button'),
          tooltip: '메인 메뉴로 돌아가기',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('내 런 보상'),
        backgroundColor: const Color(0xFFFFF4CF),
        foregroundColor: const Color(0xFF173F43),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Text(
              '이번 런에서 선택한 보상',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF173F43),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entries.isEmpty
                  ? '아직 선택한 보상이 없습니다. 스테이지를 클리어하면 다음 플레이를 도울 보상을 고를 수 있어요.'
                  : '보상이 어떤 도움을 주는지와 남은 사용 상태를 확인할 수 있어요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF315E60),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            if (entries.isEmpty)
              const _RewardInventoryEmptyState()
            else
              for (final entry in entries) ...[
                _RewardInventoryCard(
                  reward: catalogById[entry.key]!,
                  selectedCount: entry.value.length,
                  status: _rewardInventoryStatus(
                    catalogById[entry.key]!,
                    inventory,
                    entry.value.length,
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _RewardInventoryEmptyState extends StatelessWidget {
  const _RewardInventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFB89C64)),
      ),
      child: const Column(
        children: [
          Icon(Icons.backpack_outlined, size: 42, color: Color(0xFF8A6527)),
          SizedBox(height: 10),
          Text(
            '첫 보상을 얻으러 가볼까요?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _RewardInventoryCard extends StatelessWidget {
  const _RewardInventoryCard({
    required this.reward,
    required this.selectedCount,
    required this.status,
  });

  final RunReward reward;
  final int selectedCount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final icon = _rewardInventoryIcon(reward.effectKind);
    return Semantics(
      container: true,
      label: '${reward.name}, $status, ${reward.description}',
      child: Container(
        key: Key('reward_inventory_${reward.id}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9D8258)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: icon.background,
              foregroundColor: icon.foreground,
              child: Icon(icon.icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reward.name,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      if (selectedCount > 1)
                        Text(
                          '$selectedCount개',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(reward.description),
                  const SizedBox(height: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2E7),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Color(0xFF286343),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _rewardInventoryStatus(
  RunReward reward,
  RunRewardInventory inventory,
  int selectedCount,
) {
  return switch (reward.effectKind) {
    RunRewardEffectKind.cloneCore => '복제 코어 지급 완료',
    RunRewardEffectKind.failureCauseBoost ||
    RunRewardEffectKind.ballAppearance ||
    RunRewardEffectKind.precisionCharge => '런 동안 계속 활성',
    RunRewardEffectKind.optionalChallengeGuard ||
    RunRewardEffectKind.stageRecordGuard => '스테이지마다 자동 적용',
    RunRewardEffectKind.nextStageHintAccess => '다음 스테이지 팁 권한 지급',
    _ => '남은 사용 ${inventory.availableUseCount(reward.id)}/$selectedCount회',
  };
}

({IconData icon, Color foreground, Color background}) _rewardInventoryIcon(
  RunRewardEffectKind kind,
) => switch (kind) {
  RunRewardEffectKind.cloneCore => (
    icon: Icons.copy_all_rounded,
    foreground: const Color(0xFF236B4A),
    background: const Color(0xFFDDF3D5),
  ),
  RunRewardEffectKind.shotCancelAssist => (
    icon: Icons.undo_rounded,
    foreground: const Color(0xFF285B7D),
    background: const Color(0xFFDCEEFF),
  ),
  RunRewardEffectKind.spentBallRecovery => (
    icon: Icons.replay_circle_filled_rounded,
    foreground: const Color(0xFF704A8F),
    background: const Color(0xFFEEDFF7),
  ),
  RunRewardEffectKind.firstImpactGuide => (
    icon: Icons.center_focus_strong_rounded,
    foreground: const Color(0xFF9B5A22),
    background: const Color(0xFFFFE9C8),
  ),
  RunRewardEffectKind.optionalChallengeGuard => (
    icon: Icons.shield_rounded,
    foreground: const Color(0xFF356072),
    background: const Color(0xFFDCECF0),
  ),
  RunRewardEffectKind.failureCauseBoost => (
    icon: Icons.account_tree_rounded,
    foreground: const Color(0xFF9A3F3F),
    background: const Color(0xFFFFDDDC),
  ),
  RunRewardEffectKind.ballAppearance => (
    icon: Icons.auto_awesome_rounded,
    foreground: const Color(0xFF087F7A),
    background: const Color(0xFFFFE9A8),
  ),
  RunRewardEffectKind.stageRecordGuard => (
    icon: Icons.workspace_premium_rounded,
    foreground: const Color(0xFF8A651D),
    background: const Color(0xFFFFE8A9),
  ),
  RunRewardEffectKind.nextStageHintAccess => (
    icon: Icons.lightbulb_rounded,
    foreground: const Color(0xFF8A5B00),
    background: const Color(0xFFFFF0B8),
  ),
  RunRewardEffectKind.precisionCharge => (
    icon: Icons.slow_motion_video_rounded,
    foreground: const Color(0xFF315E8B),
    background: const Color(0xFFDDEBFF),
  ),
};

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.onStart,
    required this.onStageSelect,
    required this.onRewardInventory,
    required this.onDailyChallenge,
    required this.onReplayLibrary,
    required this.showDebugControls,
    required this.tutorialVariant,
    required this.onTutorialVariantChanged,
  });

  final VoidCallback onStart;
  final VoidCallback onStageSelect;
  final VoidCallback onRewardInventory;
  final VoidCallback onDailyChallenge;
  final VoidCallback onReplayLibrary;
  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;
  final ValueChanged<TutorialExperimentVariant> onTutorialVariantChanged;

  @override
  Widget build(BuildContext context) {
    final appFontFamily = Theme.of(context).textTheme.bodyLarge?.fontFamily;
    return Scaffold(
      key: const Key('home_screen_golden'),
      backgroundColor: const Color(0xFFBFE8E3),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _IslandBackdrop()),
            if (showDebugControls)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filledTonal(
                  key: const Key('tutorial_experiment_button'),
                  tooltip: '튜토리얼 실험 조건',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _TutorialExperimentDialog(
                      selected: tutorialVariant,
                      onSelected: onTutorialVariantChanged,
                    ),
                  ),
                  icon: const Icon(Icons.science_outlined),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                key: const Key('feedback_settings_button'),
                tooltip: '소리와 진동 설정',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _FeedbackSettingsDialog(),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const _HomePlayPreview(),
                      const SizedBox(height: 12),
                      Text(
                        '속성 한방',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: const Color(0xFF173F43),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '주변 물체의 성질을 공에 담아\n한 번의 샷으로 연쇄 반응을 완성하세요.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF285C5D),
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 26),
                      FilledButton.icon(
                        key: const Key('start_game_button'),
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('첫 섬에서 시작하기'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: const Color(0xFFEF765E),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ).copyWith(fontFamily: appFontFamily),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('reward_inventory_entry_button'),
                        onPressed: onRewardInventory,
                        icon: const Icon(Icons.backpack_outlined),
                        label: const Text('내 런 보상'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: const Color(0xFF6B4B20),
                          side: const BorderSide(color: Color(0xFFA77A3E)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('stage_select_button'),
                        onPressed: onStageSelect,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('스테이지 선택'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: const Color(0xFF245B60),
                          side: const BorderSide(color: Color(0xFF4D8580)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('replay_library_entry_button'),
                        onPressed: onReplayLibrary,
                        icon: const Icon(Icons.movie_filter_outlined),
                        label: const Text('나의 리플레이'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: const Color(0xFF5A536F),
                          side: const BorderSide(color: Color(0xFF81779B)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('daily_challenge_entry_button'),
                        onPressed: onDailyChallenge,
                        icon: const Icon(Icons.today_rounded),
                        label: const Text('오늘의 도전'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: const Color(0xFF9A5D35),
                          side: const BorderSide(color: Color(0xFFC9875A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePlayPreview extends StatelessWidget {
  const _HomePlayPreview();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '공과 상자와 무거운 돌이 있는 목표 홀 보드',
      child: Container(
        height: 174,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE3A1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF3B7776), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33406B65),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PreviewBoardPainter()),
            ),
            Positioned(
              left: 34,
              top: 40,
              child: Image.asset(
                'assets/generated/stone-v2.png',
                width: 72,
                height: 54,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 146,
              top: 92,
              child: Image.asset(
                'assets/generated/crate-v2.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
            const Positioned(right: 26, top: 28, child: _PreviewHole()),
            Positioned(
              left: 66,
              bottom: 18,
              child: CustomPaint(
                painter: const GameBallIconPainter(null),
                size: const Size(54, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHole extends StatelessWidget {
  const _PreviewHole();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 70,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF122523),
              border: Border.all(color: const Color(0xFF4EAAA5), width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6650C2B2),
                  blurRadius: 0,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          const Positioned(
            right: 3,
            top: 0,
            child: Icon(Icons.flag_rounded, color: Color(0xFFEF765E), size: 28),
          ),
        ],
      ),
    );
  }
}

class _PreviewBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x1F9B6E38)
      ..strokeWidth = 2;
    for (var y = 18.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final pebble = Paint()..color = const Color(0x559A9D73);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, 36),
        width: 18,
        height: 7,
      ),
      pebble,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.86, size.height * 0.78),
        width: 16,
        height: 6,
      ),
      pebble,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewBoardPainter oldDelegate) => false;
}

class _FeedbackSettingsDialog extends StatefulWidget {
  const _FeedbackSettingsDialog();

  @override
  State<_FeedbackSettingsDialog> createState() =>
      _FeedbackSettingsDialogState();
}

class _FeedbackSettingsDialogState extends State<_FeedbackSettingsDialog> {
  Widget _settingSwitch({
    required Key key,
    required String title,
    String? subtitle,
    required bool value,
    required Future<void> Function(bool) onChanged,
  }) {
    return SwitchListTile.adaptive(
      key: key,
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: (enabled) {
        setState(() {});
        unawaited(
          onChanged(enabled).then((_) {
            if (mounted) setState(() {});
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('게임 설정'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ChargeGaugeSide>(
                key: const Key('charge_gauge_side_dropdown'),
                decoration: const InputDecoration(labelText: '충전 게이지 위치'),
                initialValue: GameFeedback.chargeGaugeSide,
                items: const [
                  DropdownMenuItem(
                    value: ChargeGaugeSide.right,
                    child: Text('오른쪽 (기본)'),
                  ),
                  DropdownMenuItem(
                    value: ChargeGaugeSide.left,
                    child: Text('왼쪽'),
                  ),
                ],
                onChanged: (side) {
                  if (side == null) return;
                  setState(() => GameFeedback.chargeGaugeSide = side);
                  unawaited(GameFeedback.setChargeGaugeSide(side));
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PlayerDifficulty>(
                key: const Key('player_difficulty_dropdown'),
                decoration: const InputDecoration(labelText: '게임 난이도'),
                initialValue: GameFeedback.playerDifficulty,
                items: const [
                  DropdownMenuItem(
                    value: PlayerDifficulty.normal,
                    child: Text('보통'),
                  ),
                  DropdownMenuItem(
                    value: PlayerDifficulty.easy,
                    child: Text('쉬움'),
                  ),
                ],
                onChanged: (difficulty) {
                  if (difficulty == null) return;
                  setState(() => GameFeedback.playerDifficulty = difficulty);
                  unawaited(GameFeedback.setPlayerDifficulty(difficulty));
                },
              ),
              const Divider(height: 28),
              _settingSwitch(
                key: const Key('last_shot_slow_motion_toggle'),
                title: '마지막 샷 슬로모션',
                subtitle: '실패 장면을 반속도로 되돌려 봅니다.',
                value: GameFeedback.lastShotSlowMotionEnabled,
                onChanged: GameFeedback.setLastShotSlowMotionEnabled,
              ),
              _settingSwitch(
                key: const Key('collision_order_toggle'),
                title: '충돌 순서 표시',
                value: GameFeedback.collisionOrderEnabled,
                onChanged: GameFeedback.setCollisionOrderEnabled,
              ),
              _settingSwitch(
                key: const Key('last_contact_highlight_toggle'),
                title: '마지막 접촉 대상 강조',
                value: GameFeedback.lastContactHighlightEnabled,
                onChanged: GameFeedback.setLastContactHighlightEnabled,
              ),
              _settingSwitch(
                key: const Key('nearest_hole_toggle'),
                title: '홀 최근접 위치',
                value: GameFeedback.nearestHoleEnabled,
                onChanged: GameFeedback.setNearestHoleEnabled,
              ),
              _settingSwitch(
                key: const Key('trait_activation_toggle'),
                title: '속성 발동 표시',
                value: GameFeedback.traitActivationEnabled,
                onChanged: GameFeedback.setTraitActivationEnabled,
              ),
              _settingSwitch(
                key: const Key('gimmick_causality_toggle'),
                title: '기믹 인과 표시',
                value: GameFeedback.gimmickCausalityEnabled,
                onChanged: GameFeedback.setGimmickCausalityEnabled,
              ),
              _settingSwitch(
                key: const Key('collision_path_icons_toggle'),
                title: '충돌 경로 아이콘',
                value: GameFeedback.collisionPathIconsEnabled,
                onChanged: GameFeedback.setCollisionPathIconsEnabled,
              ),
              _settingSwitch(
                key: const Key('chain_score_details_toggle'),
                title: '연쇄 점수 상세 표시',
                subtitle: '끄더라도 획득한 총점은 그대로 유지됩니다.',
                value: GameFeedback.chainScoreDetailsEnabled,
                onChanged: GameFeedback.setChainScoreDetailsEnabled,
              ),
              _settingSwitch(
                key: const Key('haptics_toggle'),
                title: '진동',
                value: GameFeedback.hapticsEnabled,
                onChanged: GameFeedback.setHapticsEnabled,
              ),
              _settingSwitch(
                key: const Key('reduced_motion_toggle'),
                title: '저모션',
                subtitle: '충돌 인과는 유지하고 흔들림과 반복 효과를 줄입니다.',
                value: GameFeedback.reducedMotionEnabled,
                onChanged: GameFeedback.setReducedMotionEnabled,
              ),
              _settingSwitch(
                key: const Key('screen_shake_toggle'),
                title: '화면 흔들림',
                value: GameFeedback.screenShakeEnabled,
                onChanged: GameFeedback.setScreenShakeEnabled,
              ),
              DropdownButtonFormField<int>(
                key: const Key('screen_shake_strength_dropdown'),
                decoration: const InputDecoration(labelText: '화면 흔들림 강도'),
                initialValue: GameFeedback.screenShakeStrength,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('끔')),
                  DropdownMenuItem(value: 1, child: Text('약하게')),
                  DropdownMenuItem(value: 2, child: Text('보통')),
                  DropdownMenuItem(value: 3, child: Text('강하게')),
                ],
                onChanged: (strength) {
                  if (strength == null) return;
                  setState(() {
                    GameFeedback.screenShakeStrength = strength;
                    GameFeedback.screenShakeEnabled = strength > 0;
                  });
                  unawaited(GameFeedback.setScreenShakeStrength(strength));
                },
              ),
              _settingSwitch(
                key: const Key('strong_flash_toggle'),
                title: '강한 점멸 효과',
                subtitle: '끄면 반복 점멸을 정적인 밝기와 윤곽으로 바꿉니다.',
                value: GameFeedback.strongFlashEnabled,
                onChanged: GameFeedback.setStrongFlashEnabled,
              ),
              _settingSwitch(
                key: const Key('sound_toggle'),
                title: '효과음',
                value: GameFeedback.soundEnabled,
                onChanged: GameFeedback.setSoundEnabled,
              ),
              _settingSwitch(
                key: const Key('background_music_toggle'),
                title: '배경 음악',
                subtitle: '잔잔한 섬 테마를 반복 재생합니다.',
                value: GameFeedback.backgroundMusicEnabled,
                onChanged: GameFeedback.setBackgroundMusicEnabled,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('help_reset_button'),
                  onPressed: () async {
                    await GameFeedback.resetHelpPreferences();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('도움말을 다음 화면에서 다시 보여 드립니다.')),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('도움말 다시 보기'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _TutorialExperimentDialog extends StatefulWidget {
  const _TutorialExperimentDialog({
    required this.selected,
    required this.onSelected,
  });

  final TutorialExperimentVariant selected;
  final ValueChanged<TutorialExperimentVariant> onSelected;

  @override
  State<_TutorialExperimentDialog> createState() =>
      _TutorialExperimentDialogState();
}

class _TutorialExperimentDialogState extends State<_TutorialExperimentDialog> {
  late TutorialExperimentVariant _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('tutorial_experiment_dialog'),
      title: const Text('튜토리얼 실험 조건'),
      content: RadioGroup<TutorialExperimentVariant>(
        groupValue: _selected,
        onChanged: (next) {
          if (next == null) {
            return;
          }
          setState(() => _selected = next);
          widget.onSelected(next);
          Navigator.of(context).pop();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final variant in TutorialExperimentVariant.values)
              RadioListTile<TutorialExperimentVariant>(
                key: Key('tutorial_variant_${variant.code}'),
                contentPadding: EdgeInsets.zero,
                title: Text(variant.label),
                subtitle: Text(variant.description),
                value: variant,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _StageSelectScreen extends StatelessWidget {
  const _StageSelectScreen({
    required this.onBack,
    required this.onSelectStage,
    required this.unlockedLevel,
    required this.discoveriesByStageId,
  });

  final VoidCallback onBack;
  final ValueChanged<int> onSelectStage;
  final int unlockedLevel;
  final Map<String, Set<String>> discoveriesByStageId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('stage_select_screen'),
      backgroundColor: const Color(0xFFBFE8E3),
      body: Stack(
        children: [
          const Positioned.fill(child: _IslandBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '처음 화면',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF173F43),
                    ),
                    const Expanded(
                      child: Text(
                        '섬 지도',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF173F43),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '실험 섬을 골라 속성의 반응을 직접 확인해 보세요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF285C5D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  key: const Key('map_hint_card'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xD9E8F4D9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x6695B98C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.explore_rounded,
                        size: 28,
                        color: Color(0xFF4F8460),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '섬 물리 관측일지',
                              style: TextStyle(
                                color: Color(0xFF315C46),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '전체 발견 ${_totalDiscoveryCount(discoveriesByStageId)} / '
                              '${levels.length * 3} · 섬의 물리 규칙을 완성하세요.',
                              style: const TextStyle(
                                color: Color(0xFF52706A),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  key: const Key('stage_route_map'),
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xB8FFFDF3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0x6687B5A8),
                      width: 1.5,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 500;
                      final cardWidth =
                          constraints.maxWidth * (narrow ? 0.92 : 0.82);
                      final cardStep = narrow ? 136.0 : 120.0;
                      final mapHeight = math.max(
                        350.0,
                        8 + levels.length * cardStep,
                      );
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.route_rounded,
                                  size: 18,
                                  color: Color(0xFF397372),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '첫 항해 진행',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: const Color(0xFF397372),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(unlockedLevel + 1).clamp(1, levels.length)} / ${levels.length}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: const Color(0xFF52706A),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: mapHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _StageRoutePainter(
                                        unlockedLevel: unlockedLevel,
                                        cardStep: cardStep,
                                      ),
                                    ),
                                  ),
                                ),
                                for (
                                  var index = 0;
                                  index < levels.length;
                                  index++
                                )
                                  Positioned(
                                    top: 8 + index * cardStep,
                                    left: index.isEven ? 0 : null,
                                    right: index.isOdd ? 0 : null,
                                    width: cardWidth,
                                    child: _StageTile(
                                      index: index,
                                      locked: index > unlockedLevel,
                                      discoveredMilestoneIds:
                                          discoveriesByStageId[levels[index]
                                              .id] ??
                                          const {},
                                      onTap: () => onSelectStage(index),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _totalDiscoveryCount(Map<String, Set<String>> discoveries) {
    var total = 0;
    for (var index = 0; index < levels.length; index++) {
      total +=
          discoveries[levels[index].id]
              ?.intersection(stageDiscoveryMilestoneIds(index))
              .length ??
          0;
    }
    return total;
  }
}

class _StageBalloonPainter extends CustomPainter {
  const _StageBalloonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final body = Paint()..color = const Color(0xFFF28A78);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.5,
        height: size.height * 0.58,
      ),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.5,
        height: size.height * 0.58,
      ),
      Paint()
        ..color = const Color(0xFF24352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center.translate(-size.width * 0.1, -size.height * 0.12),
      size.width * 0.06,
      Paint()..color = const Color(0xCCFFF7DD),
    );
    canvas.drawLine(
      center.translate(0, size.height * 0.28),
      center.translate(size.width * 0.04, size.height * 0.48),
      Paint()
        ..color = const Color(0xFF6B4B35)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _StageBalloonPainter oldDelegate) => false;
}

class _StageReflectorIcon extends StatelessWidget {
  const _StageReflectorIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: -0.35,
          child: Container(
            width: 52,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFFF2B66D),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: const Color(0xFF5E4431), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x443A2A20),
                  offset: Offset(2, 3),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const Positioned(
          right: 5,
          bottom: 4,
          child: Icon(
            Icons.rotate_right_rounded,
            color: Color(0xFF397372),
            size: 24,
          ),
        ),
      ],
    );
  }
}

class _StageFinaleIcon extends StatelessWidget {
  const _StageFinaleIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: GameBallIconPainter(null)),
        ),
        for (final marker in const [
          (alignment: Alignment(-0.58, -0.55), color: Color(0xFF58636B)),
          (alignment: Alignment(0.58, -0.55), color: Color(0xFF78BFE8)),
          (alignment: Alignment(-0.58, 0.55), color: Color(0xFF8F72B6)),
          (alignment: Alignment(0.58, 0.55), color: Color(0xFFE99A78)),
        ])
          Align(
            alignment: marker.alignment,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: marker.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const SizedBox.square(dimension: 13),
            ),
          ),
      ],
    );
  }
}

class _StageScoreIcon extends StatelessWidget {
  const _StageScoreIcon();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Positioned.fill(
          child: Padding(
            padding: EdgeInsets.all(3),
            child: CustomPaint(painter: GameBallIconPainter(null)),
          ),
        ),
        const Align(
          alignment: Alignment(0.78, -0.78),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 22,
            color: Color(0xFFFFB629),
            shadows: [Shadow(color: Colors.white, blurRadius: 3)],
          ),
        ),
      ],
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.index,
    required this.onTap,
    this.discoveredMilestoneIds = const {},
    this.locked = false,
  });

  final int index;
  final VoidCallback onTap;
  final bool locked;
  final Set<String> discoveredMilestoneIds;

  @override
  Widget build(BuildContext context) {
    final knownMilestones = stageDiscoveryMilestoneIds(index);
    final discoveryCount = discoveredMilestoneIds
        .intersection(knownMilestones)
        .length;
    final descriptions = [
      '무거운 성질로 상자를 움직여 보세요.',
      '탄성 있는 반사로 방향을 바꿔 보세요.',
      '문과 스위치 사이의 연쇄를 실험해 보세요.',
      '풍선은 밀리고, 뾰족한 공에는 터집니다.',
      '공이 얻는 능력과 원본이 잃는 능력을 함께 이용해 보세요.',
      '약하게 쏜 뒤 발판에 들어가는 각도와 우회 길을 찾아 보세요.',
      '과거 공을 쿠션·스위치·스토퍼로 활용해 여러 발의 인과를 만들어 보세요.',
      '짧게 넣거나 벽과 기물을 이어 더 높은 연쇄 점수에 도전해 보세요.',
      '반사판을 돌려 다음 공이 만날 면과 방향을 바꿔 보세요.',
      '배운 속성과 기물을 엮어 나만의 경로를 완성해 보세요.',
    ];
    final assets = [
      'assets/generated/stone-v2.png',
      'assets/generated/jelly-bumper-v1.png',
      'assets/generated/crate-v2.png',
      'assets/generated/jelly-bumper-v1.png',
      'assets/generated/stone-v2.png',
      'assets/generated/jelly-bumper-v1.png',
      'assets/generated/crate-v2.png',
      'assets/generated/stone-v2.png',
      'assets/generated/crate-v2.png',
      'assets/generated/stone-v2.png',
    ];
    final stageAsset = assets[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xF7FFFDF3),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('stage_tile_$index'),
          onTap: locked ? null : onTap,
          child: Semantics(
            button: !locked,
            label: '${index + 1}번 ${levels[index].name} 섬',
            hint: locked ? '앞 섬을 클리어하면 열립니다' : '한 번 누르면 스테이지를 시작합니다',
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8AC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFDEA96B),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: ColorFiltered(
                                colorFilter: locked
                                    ? const ColorFilter.mode(
                                        Color(0x88909B94),
                                        BlendMode.saturation,
                                      )
                                    : const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.dst,
                                      ),
                                child: index == 3
                                    ? const CustomPaint(
                                        painter: _StageBalloonPainter(),
                                      )
                                    : index == 6
                                    ? const CustomPaint(
                                        painter: GameBallIconPainter(null),
                                      )
                                    : index == 7
                                    ? const _StageScoreIcon()
                                    : index == 8
                                    ? const _StageReflectorIcon()
                                    : index == 9
                                    ? const _StageFinaleIcon()
                                    : Image.asset(
                                        stageAsset,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF765E),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                locked
                                    ? Icons.lock_rounded
                                    : Icons.flag_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          levels[index].name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: locked
                                    ? const Color(0xFF718078)
                                    : const Color(0xFF244A45),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          descriptions[index],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: locked
                                    ? const Color(0xFF81918A)
                                    : const Color(0xFF52706A),
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 7),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x1F4EAAA5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              locked
                                  ? '앞 섬을 먼저 클리어하세요'
                                  : '발견 $discoveryCount/${knownMilestones.length} · '
                                        '추천 파 ${levels[index].parShots}회',
                              style: TextStyle(
                                color: locked
                                    ? const Color(0xFF718078)
                                    : const Color(0xFF397372),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock_outline_rounded : Icons.chevron_right,
                    color: const Color(0xFF5B8177),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageRoutePainter extends CustomPainter {
  const _StageRoutePainter({
    required this.unlockedLevel,
    required this.cardStep,
  });

  final int unlockedLevel;
  final double cardStep;

  @override
  void paint(Canvas canvas, Size size) {
    final points = List.generate(
      levels.length,
      (index) => Offset(
        size.width * (index.isEven ? 0.22 : 0.78),
        58 + index * cardStep,
      ),
    );
    if (points.isEmpty) {
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final midpoint = (previous.dy + current.dy) / 2;
      path.cubicTo(
        previous.dx,
        midpoint - 22,
        current.dx,
        midpoint + 22,
        current.dx,
        current.dy,
      );
    }
    final route = Paint()
      ..color = const Color(0x9C6B9D8B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final completed = Paint()
      ..color = const Color(0xE06FAE76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, route);
    if (unlockedLevel > 0) {
      final progress = Path();
      final metric = path.computeMetrics().first;
      final length =
          metric.length * (unlockedLevel / (levels.length - 1)).clamp(0.0, 1.0);
      progress.addPath(metric.extractPath(0, length), Offset.zero);
      canvas.drawPath(progress, completed);
    }
    for (var index = 0; index < levels.length; index++) {
      canvas.drawCircle(
        points[index],
        5,
        Paint()
          ..color = index <= unlockedLevel
              ? const Color(0xFF6FAE76)
              : const Color(0x8890A59A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StageRoutePainter oldDelegate) =>
      oldDelegate.unlockedLevel != unlockedLevel ||
      oldDelegate.cardStep != cardStep;
}

class _IslandBackdrop extends StatelessWidget {
  const _IslandBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _IslandBackdropPainter());
  }
}

class _IslandBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final water = Paint()..color = const Color(0xFFBFE8E3);
    canvas.drawRect(Offset.zero & size, water);
    final sand = Paint()..color = const Color(0xFFF6D995);
    final island = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.58,
        size.width * 0.63,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.84,
        size.width + 20,
        size.height * 0.66,
      )
      ..lineTo(size.width + 20, size.height + 20)
      ..lineTo(-20, size.height + 20)
      ..close();
    canvas.drawPath(island, sand);
    final wave = Paint()
      ..color = const Color(0x664EAAA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < 4; index++) {
      final y = size.height * (0.16 + index * 0.09);
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.08, y, size.width * 0.22, 14),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.72, y + 18, size.width * 0.2, 14),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
