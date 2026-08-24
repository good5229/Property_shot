import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/analysis/creative_chain_score.dart';
import 'game/analysis/island_restoration.dart';
import 'game/analysis/next_goal_recommendation.dart';
import 'game/analysis/solution_mastery.dart';
import 'game/analysis/stage_chain_challenge.dart';
import 'game/analysis/stage_discovery.dart';
import 'game/domain/game_state.dart';
import 'game/domain/geometry.dart';
import 'game/domain/level_definition.dart';
import 'game/domain/shot_input.dart';
import 'game/expedition/expedition_contract.dart';
import 'game/hint/generated_hint_catalog.dart';
import 'game/hint/demo_playback_plan.dart';
import 'game/hint/pattern_hint.dart';
import 'game/input/intent_assist_resolver.dart';
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
import 'ui/app_language.dart';
import 'ui/game_screen.dart';
import 'ui/daily_challenge_screen.dart';
import 'ui/game_ball_painter.dart';
import 'ui/bonus_goal.dart';
import 'ui/core_experience_screen.dart';
import 'ui/play_telemetry.dart';
import 'ui/physics_lab_screen.dart';
import 'ui/puzzle_forge_screen.dart';
import 'ui/replay_library_screen.dart';
import 'ui/run_difficulty_attribution_store.dart';
import 'ui/tutorial_experiment.dart';

String _stageIntroMessage(int levelIndex) {
  return switch (levelIndex) {
    0 => '무거움을 옮겨 상자를 밀고 길을 만드세요',
    1 => '탄성을 옮겨 바닥과 벽의 반사를 이용하세요',
    2 => '무거움으로 스위치를 눌러 문을 여세요',
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
    this.initialLanguage = AppLanguage.korean,
    this.languageStore,
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
  final AppLanguage initialLanguage;
  final AppLanguageStore? languageStore;

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
              initialLanguage: initialLanguage,
              languageStore: languageStore,
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
    required this.initialLanguage,
    this.languageStore,
  });

  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;
  final ProgressStore? progressStore;
  final LocalPlayTelemetry? telemetry;
  final AppLanguage initialLanguage;
  final AppLanguageStore? languageStore;

  @override
  State<_PropertyShotRouter> createState() => _PropertyShotRouterState();
}

class _PropertyShotRouterState extends State<_PropertyShotRouter> {
  final GameFeedback _feedback = GameFeedback();
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
  List<SolutionMasteryEntry> _activeSolutionEntries = const [];
  bool _showRunResult = false;
  int _completedRunScore = 0;
  int _completedRunBestShots = 0;
  int _completedRunRewardCount = 0;
  bool _showStageSelect = false;
  bool _showPhysicsLab = false;
  bool _showDailyChallenge = false;
  bool _showReplayLibrary = false;
  bool _showRewardInventory = false;
  bool _showExpedition = false;
  bool _showCoreExperience = false;
  bool _showPuzzleForge = false;
  Future<Set<String>>? _rewardInventoryFuture;
  bool _selectingStage = false;
  int _copyCoreCount = 0;
  bool _copyCoreRewarded = false;
  bool _legacyCopyCoreRewarded = false;
  Set<String> _copyCoreRewardedStageIds = <String>{};
  int _unlockedLevel = 0;
  Set<int> _clearedLevels = <int>{};
  Map<int, int> _bestShots = <int, int>{};
  Set<int> _bonusGoals = <int>{};
  Map<int, Set<PersonalRecordKind>> _personalRecords =
      <int, Set<PersonalRecordKind>>{};
  Map<String, Set<String>> _discoveriesByStageId = <String, Set<String>>{};
  Map<String, int> _solutionCountsByStageId = const {};
  IslandLandmark? _islandSupportFocus;
  PlayerDifficulty _activeDifficulty = PlayerDifficulty.normal;
  late TutorialExperimentVariant _tutorialVariant = widget.tutorialVariant;
  late final ProgressStore _progressStore =
      widget.progressStore ??
      ProgressStore(
        stageCount: levels.length,
        stageIds: levels.map((level) => level.id),
      );
  late final Future<StagePatternSession> _patternSessionFuture;
  late final Future<StagePatternSession> _expeditionPatternSessionFuture;
  late final Future<ReplayLibraryStore> _replayLibraryFuture;
  late final Future<RunDifficultyAttributionStore>
  _difficultyAttributionStoreFuture;
  late final Future<ExpeditionContractStore> _expeditionStoreFuture;
  late final Future<SolutionMasteryStore> _solutionMasteryStoreFuture;
  ExpeditionContractProgress? _expeditionProgress;
  bool _activeIsExpedition = false;
  late final Future<void> _progressLoadFuture;
  late final LocalPlayTelemetry _telemetry;
  bool _runStartedRecorded = false;
  late AppLanguage _language = widget.initialLanguage;
  bool _languageChangedByUser = false;
  late final AppLanguageStore _languageStore =
      widget.languageStore ?? const AppLanguageStore();

  @override
  void initState() {
    super.initState();
    _telemetry = widget.telemetry ?? LocalPlayTelemetry();
    _patternSessionFuture = _createPatternSession();
    _expeditionPatternSessionFuture = _createPatternSession(
      namespace: 'property_shot_expedition:',
    );
    _replayLibraryFuture = _createReplayLibrary();
    _difficultyAttributionStoreFuture = _createDifficultyAttributionStore();
    _expeditionStoreFuture = _createExpeditionStore();
    _solutionMasteryStoreFuture = _createSolutionMasteryStore();
    _progressLoadFuture = _loadCopyCore();
    unawaited(_loadExpedition());
    unawaited(_loadLanguage());
  }

  Future<void> _loadLanguage() async {
    final loaded = await _languageStore.load(fallback: widget.initialLanguage);
    if (mounted && !_languageChangedByUser && loaded != _language) {
      setState(() => _language = loaded);
    }
  }

  void _changeLanguage(AppLanguage language) {
    if (language == _language) return;
    _languageChangedByUser = true;
    setState(() => _language = language);
    unawaited(_persistLanguage(language));
  }

  Future<void> _persistLanguage(AppLanguage language) async {
    try {
      await _languageStore.save(language);
    } on Object {
      if (!mounted) return;
      final message = language.pick(
        '언어 선택을 저장하지 못했습니다. 현재 화면에는 계속 적용됩니다.',
        'Could not save the language choice. It remains active for this session.',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<StagePatternSession> _createPatternSession({String? namespace}) async {
    final preferences = await SharedPreferences.getInstance();
    final sharedBackend = SharedPreferencesRunStateBackend(preferences);
    return StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: namespace == null
            ? sharedBackend
            : NamespacedRunStateBackend(
                delegate: sharedBackend,
                namespace: namespace,
              ),
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

  Future<ExpeditionContractStore> _createExpeditionStore() async {
    final preferences = await SharedPreferences.getInstance();
    return ExpeditionContractStore(preferences);
  }

  Future<SolutionMasteryStore> _createSolutionMasteryStore() async {
    final preferences = await SharedPreferences.getInstance();
    return SolutionMasteryStore(preferences);
  }

  Future<void> _loadExpedition() async {
    final progress = await (await _expeditionStoreFuture).load();
    if (mounted) setState(() => _expeditionProgress = progress);
  }

  Future<void> _startExpedition(ExpeditionContractType type) async {
    await (await _expeditionPatternSessionFuture).reset();
    final progress = await (await _expeditionStoreFuture).start(
      type: type,
      startIndex: math.min(_unlockedLevel, levels.length - 3),
      allStageIds: levels.map((level) => level.id).toList(growable: false),
    );
    if (mounted) setState(() => _expeditionProgress = progress);
  }

  Future<void> _clearExpedition() async {
    await (await _expeditionPatternSessionFuture).reset();
    await (await _expeditionStoreFuture).clear();
    if (mounted) setState(() => _expeditionProgress = null);
  }

  Future<void> _shareExpedition() async {
    final progress = _expeditionProgress;
    if (progress == null) return;
    await Clipboard.setData(
      ClipboardData(text: ExpeditionShareCodec.encode(progress)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('탐사 코드가 복사되었습니다.')));
  }

  Future<void> _importExpedition(String code) async {
    await (await _expeditionPatternSessionFuture).reset();
    final progress = await (await _expeditionStoreFuture).importCode(
      code,
      knownStageIds: levels.map((level) => level.id).toSet(),
    );
    if (mounted) setState(() => _expeditionProgress = progress);
  }

  Future<void> _recordExpeditionOutcome(ExpeditionStageOutcome outcome) async {
    final progress = await (await _expeditionStoreFuture).record(outcome);
    if (mounted && progress != null) {
      setState(() => _expeditionProgress = progress);
    }
  }

  Future<void> _playExpeditionStage(String stageId) async {
    final index = levels.indexWhere((level) => level.id == stageId);
    if (index < 0 || index > _unlockedLevel) return;
    _changeSurface(() => _showExpedition = false);
    await _startStage(index, expedition: true);
  }

  Future<StagePatternSession> get _activePatternSessionFuture =>
      _activeIsExpedition
      ? _expeditionPatternSessionFuture
      : _patternSessionFuture;

  Future<void> _loadCopyCore() async {
    await GameFeedback.loadPreferences();
    unawaited(GameFeedback.activateBackgroundMusic());
    try {
      final progress = await _progressStore.load();
      final preferences = await SharedPreferences.getInstance();
      final supportFocus = IslandSupportStore(preferences).load();
      final solutionCounts = await (await _solutionMasteryStoreFuture)
          .loadCountsByStage();
      if (!mounted) {
        return;
      }
      setState(() {
        _copyCoreCount = progress.copyCoreCount;
        _legacyCopyCoreRewarded = progress.copyCoreRewarded;
        _copyCoreRewardedStageIds = progress.copyCoreRewardedStageIds;
        _clearedLevels = progress.clearedLevels;
        _bestShots = progress.bestShots;
        _bonusGoals = progress.bonusGoals;
        _personalRecords = {
          for (final entry in progress.personalRecords.entries)
            entry.key: {...entry.value},
        };
        _unlockedLevel = progress.unlockedLevel;
        _discoveriesByStageId = {
          for (final entry in progress.discoveriesByStageId.entries)
            entry.key: {...entry.value},
        };
        _islandSupportFocus = supportFocus;
        _solutionCountsByStageId = solutionCounts;
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

  void _dismissTransientMessages() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
  }

  void _changeSurface(VoidCallback change) {
    _dismissTransientMessages();
    setState(change);
  }

  void _openRewardInventory() {
    _changeSurface(() {
      _rewardInventoryFuture = _loadRewardInventory();
      _showRewardInventory = true;
    });
  }

  Future<void> _selectIslandSupport(IslandLandmark landmark) async {
    final restoration = IslandRestorationProgress.fromDiscoveries(
      discoveriesByStageId: _discoveriesByStageId,
      stageIds: levels.map((level) => level.id).toList(growable: false),
      optionalMasteryCount: _bonusGoals.length,
    );
    if (!restoration.isRestored(landmark)) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await IslandSupportStore(preferences).save(landmark);
      if (mounted) setState(() => _islandSupportFocus = landmark);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('집중 지원 선택을 저장하지 못했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _startStage(
    int index, {
    bool allowStoredRunResume = false,
    bool expedition = false,
  }) async {
    if ((index > _unlockedLevel && !allowStoredRunResume) || _selectingStage) {
      return;
    }
    _dismissTransientMessages();
    _selectingStage = true;
    try {
      await _progressLoadFuture;
      _activeDifficulty = GameFeedback.playerDifficulty;
      final session = await (expedition
          ? _expeditionPatternSessionFuture
          : _patternSessionFuture);
      await session.loadState();
      if (!expedition) {
        await session.migrateLegacyCloneCoreReward(
          rewarded:
              _legacyCopyCoreRewarded && _copyCoreRewardedStageIds.isEmpty,
        );
        await _adoptCloneCoreState(session);
        await _recoverCompletedProgress(session);
        await _recoverPendingCopyCoreReward(session);
      }
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
      final stateBeforeSelection = session.state;
      final draw = await session.selectStage(
        levels[index].id,
        initialCloneCoreCount: expedition ? 0 : _copyCoreCount,
        initialCloneCoreRewarded:
            !expedition &&
            _legacyCopyCoreRewarded &&
            _copyCoreRewardedStageIds.isEmpty,
        initialCloneCoreRewardedStageIds: expedition
            ? const []
            : _copyCoreRewardedStageIds,
        drawPolicy: expedition
            ? null
            : CampaignStageSelectionPolicy.drawLearningWave,
      );
      final restoration = IslandRestorationProgress.fromDiscoveries(
        discoveriesByStageId: _discoveriesByStageId,
        stageIds: levels.map((level) => level.id).toList(growable: false),
        optionalMasteryCount: _bonusGoals.length,
      );
      await session.applyIslandRestorationBenefits(
        observatoryRestored: restoration.isRestored(IslandLandmark.observatory),
        lighthouseRestored: restoration.isRestored(IslandLandmark.lighthouse),
        bridgeRestored: restoration.isRestored(IslandLandmark.bridge),
        observatoryFocused: _islandSupportFocus == IslandLandmark.observatory,
        lighthouseFocused: _islandSupportFocus == IslandLandmark.lighthouse,
        bridgeFocused: _islandSupportFocus == IslandLandmark.bridge,
        optionalMasteryCount: _bonusGoals.length,
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
      if (!expedition) await _mirrorCloneCore(session);
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
          rawDirection: saved.rawDirection,
          rawPower: saved.rawPower,
          assistKind: saved.assistKind,
          assistTargetId: saved.assistTargetId,
          holeForgivenessRadius: saved.holeForgivenessRadius,
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
          expedition: expedition,
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
        if (!expedition) await _recoverPendingCopyCoreReward(session);
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
      final solutionEntries = expedition
          ? const <SolutionMasteryEntry>[]
          : await (await _solutionMasteryStoreFuture).loadFor(
              draw.stageId,
              draw.patternId,
            );
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
        _activeIsExpedition = expedition;
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
        _activeSolutionEntries = solutionEntries;
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
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
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
    _changeSurface(() {
      _activeIsExpedition = false;
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
    final session = await _activePatternSessionFuture;
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
    if (!_activeIsExpedition) {
      try {
        await _progressStore.recordCopyCore(
          _copyCoreCount,
          _copyCoreRewardedStageIds.isNotEmpty,
          rewardedStageIds: _copyCoreRewardedStageIds,
        );
      } on Object {
        // RunState가 복제 코어의 기준이며 진행 기록은 다음 저장 때 다시 동기화한다.
      }
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
    final session = await _activePatternSessionFuture;
    final completionInputs = session.currentShotInputs;
    final usedIslandSupport =
        session.state?.acquiredRewards.any(
          (reward) => reward.startsWith('island_restoration_'),
        ) ??
        false;
    var newlyRecordedPersonalRecords = <PersonalRecordKind>{};
    final attributionState = session.state;
    final completionDifficulty = attributionState == null
        ? null
        : (await _difficultyAttributionStoreFuture)
              .loadFor(attributionState)
              ?.difficulty;
    final nextIndex = levelIndex + 1;
    final expeditionStageIds = _expeditionProgress?.stageIds;
    final expeditionPosition = expeditionStageIds?.indexOf(
      levels[levelIndex].id,
    );
    final expeditionNextStageId =
        _activeIsExpedition &&
            expeditionStageIds != null &&
            expeditionPosition != null &&
            expeditionPosition >= 0 &&
            expeditionPosition + 1 < expeditionStageIds.length
        ? expeditionStageIds[expeditionPosition + 1]
        : null;
    final completion = await session.completeCurrentStage(
      stageId: levels[levelIndex].id,
      shotCount: shotCount,
      nextStageId: _activeIsExpedition
          ? expeditionNextStageId
          : levelIndex < levels.length - 1
          ? levels[levelIndex + 1].id
          : null,
      chainScore: chainScore?.totalScore,
      optionalChallengeAchieved: optionalChallengeAchieved,
      applyOptionalChallengeGuard: applyOptionalChallengeGuard,
      applyStageRecordGuard: applyStageRecordGuard,
      nextStageDrawPolicy: !_activeIsExpedition && nextIndex < levels.length
          ? CampaignStageSelectionPolicy.drawLearningWave
          : null,
    );
    await _saveCurrentReplay(session, totalScore: chainScore?.totalScore ?? 0);
    if (!_activeIsExpedition) {
      await _progressStore.recordStageClear(levelIndex);
      if (completionDifficulty == PlayerDifficulty.normal) {
        await _progressStore.recordBestShot(levelIndex, completion.shotCount);
        if (completion.optionalChallengeAchieved) {
          await _progressStore.recordBonusGoal(levelIndex);
        }
        newlyRecordedPersonalRecords = <PersonalRecordKind>{
          if (completion.optionalChallengeAchieved)
            PersonalRecordKind.gimmickMastery,
          if (completionInputs.isNotEmpty &&
              completionInputs.every(
                (input) => input.assistKind == ShotAssistKind.none,
              ))
            PersonalRecordKind.noAssistClear,
          if (!usedIslandSupport) PersonalRecordKind.noIslandSupportClear,
        };
        await _progressStore.recordPersonalRecords(
          levelIndex,
          newlyRecordedPersonalRecords,
        );
      }
      _applyClearedLevelInMemory(levelIndex);
      if (completionDifficulty == PlayerDifficulty.normal && mounted) {
        setState(() {
          final previous = _bestShots[levelIndex];
          _bestShots = {
            ..._bestShots,
            levelIndex: previous == null
                ? completion.shotCount
                : math.min(previous, completion.shotCount),
          };
          if (completion.optionalChallengeAchieved) {
            _bonusGoals = {..._bonusGoals, levelIndex};
          }
          if (newlyRecordedPersonalRecords.isNotEmpty) {
            _personalRecords = {
              ..._personalRecords,
              levelIndex: {
                ...?_personalRecords[levelIndex],
                ...newlyRecordedPersonalRecords,
              },
            };
          }
        });
      }
    }
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
    final session = await _activePatternSessionFuture;
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
    final session = await _activePatternSessionFuture;
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
    final session = await _activePatternSessionFuture;
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
    final session = await _activePatternSessionFuture;
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
    bool expedition = false,
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
      optionalChallengeAchieved = stageBonusGoalReached(
        levelIndex: levelIndex,
        shotCount: shotCount,
        results: results,
        drainedSourceMoved: _drainedSourceMoved(results),
      );
    }
    final inventory = session.rewardInventory;
    final nextIndex = levelIndex + 1;
    final expeditionStageIds = _expeditionProgress?.stageIds;
    final expeditionPosition = expeditionStageIds?.indexOf(
      levels[levelIndex].id,
    );
    final expeditionNextStageId =
        expedition &&
            expeditionStageIds != null &&
            expeditionPosition != null &&
            expeditionPosition >= 0 &&
            expeditionPosition + 1 < expeditionStageIds.length
        ? expeditionStageIds[expeditionPosition + 1]
        : null;
    final completion = await session.completeCurrentStage(
      stageId: levels[levelIndex].id,
      shotCount: shotCount,
      nextStageId: expedition
          ? expeditionNextStageId
          : levelIndex < levels.length - 1
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
      nextStageDrawPolicy: !expedition && nextIndex < levels.length
          ? CampaignStageSelectionPolicy.drawLearningWave
          : null,
    );
    if (!expedition) {
      await _progressStore.recordStageClear(levelIndex);
      if (completionDifficulty == PlayerDifficulty.normal) {
        await _progressStore.recordBestShot(levelIndex, completion.shotCount);
        if (completion.optionalChallengeAchieved) {
          await _progressStore.recordBonusGoal(levelIndex);
        }
      }
      await _recoverPendingCopyCoreReward(session);
      _applyClearedLevelInMemory(levelIndex);
    }
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
    final session = await _activePatternSessionFuture;
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
    final session = await _activePatternSessionFuture;
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
      final before = IslandRestorationProgress.fromDiscoveries(
        discoveriesByStageId: _discoveriesByStageId,
        stageIds: levels.map((level) => level.id).toList(growable: false),
        optionalMasteryCount: _bonusGoals.length,
      );
      await _progressStore.recordDiscoveries(activeStage, milestoneIds);
      if (mounted) {
        final stageId = levels[activeStage].id;
        final updated = {
          ..._discoveriesByStageId,
          stageId: {...?_discoveriesByStageId[stageId], ...milestoneIds},
        };
        final after = IslandRestorationProgress.fromDiscoveries(
          discoveriesByStageId: updated,
          stageIds: levels.map((level) => level.id).toList(growable: false),
          optionalMasteryCount: _bonusGoals.length,
        );
        IslandLandmark? restoredLandmark;
        for (final landmark in IslandLandmark.values) {
          if (!before.isRestored(landmark) && after.isRestored(landmark)) {
            restoredLandmark = landmark;
            break;
          }
        }
        setState(() {
          _discoveriesByStageId = updated;
        });
        if (restoredLandmark != null) {
          _feedback.restorationCompleted();
          unawaited(_showIslandRestorationCelebration(restoredLandmark));
        }
      }
      return true;
    } on Object {
      return false;
    }
  }

  Future<void> _showIslandRestorationCelebration(
    IslandLandmark landmark,
  ) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: buildIslandRestorationCelebrationForTesting(
          landmark: landmark,
          onContinue: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<SolutionMasteryRecordResult> _recordSolutionRoute(
    SolutionRoute route,
  ) async {
    final level = _activeLevel;
    if (level == null || _activeIsExpedition) {
      return const SolutionMasteryRecordResult(entries: [], isNew: false);
    }
    final store = await _solutionMasteryStoreFuture;
    final result = await store.record(
      stageId: level.stageId ?? level.id,
      patternId: level.patternId ?? '${level.id}_default',
      route: route,
    );
    if (mounted) {
      setState(() {
        _activeSolutionEntries = result.entries;
        _solutionCountsByStageId = {
          ..._solutionCountsByStageId,
          level.stageId ?? level.id:
              (_solutionCountsByStageId[level.stageId ?? level.id] ?? 0) +
              (result.isNew ? 1 : 0),
        };
      });
    }
    return result;
  }

  Future<RunHintEntitlement?> _recordCurrentHintFailure() async {
    final session = await _activePatternSessionFuture;
    final entitlement = await session.recordHintFailure();
    if (entitlement != null && mounted) {
      setState(() => _activeHintEntitlement = entitlement);
    }
    return entitlement;
  }

  Future<RunHintEntitlement?> _openCurrentHint({int? requestedLevel}) async {
    final session = await _activePatternSessionFuture;
    final entitlement = await session.openHint(requestedLevel: requestedLevel);
    if (entitlement != null && mounted) {
      setState(() => _activeHintEntitlement = entitlement);
    }
    return entitlement;
  }

  Future<RunHintEntitlement?> _readCurrentHintEntitlement() async {
    final session = await _activePatternSessionFuture;
    return session.currentHintEntitlement;
  }

  Future<void> _recordTraitAction(
    String sourceId,
    RunTraitAction action,
  ) async {
    final session = await _activePatternSessionFuture;
    await session.recordTraitAction(sourceId: sourceId, action: action);
    _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
    _copyCoreRewardedStageIds = _cloneCoreRewardStageIds(session);
    if (!_activeIsExpedition) {
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
  }

  Future<void> _restartStageRun() async {
    final session = await _activePatternSessionFuture;
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
    final session = await _activePatternSessionFuture;
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

  Future<bool> _markCurrentStageAssisted() async {
    final session = await _activePatternSessionFuture;
    final state = session.state;
    if (state == null || state.phase != RunPhase.playing) return false;
    final marked = await (await _difficultyAttributionStoreFuture).markAssisted(
      state,
    );
    if (marked) _activeDifficulty = PlayerDifficulty.easy;
    return marked;
  }

  Future<void> _mirrorCloneCore(StagePatternSession session) async {
    _copyCoreCount = session.state?.cloneCoreCount ?? _copyCoreCount;
    _copyCoreRewardedStageIds = _cloneCoreRewardStageIds(session);
    if (_activeIsExpedition) return;
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
    final restorationProgress = IslandRestorationProgress.fromDiscoveries(
      discoveriesByStageId: _discoveriesByStageId,
      stageIds: levels.map((level) => level.id).toList(growable: false),
      optionalMasteryCount: _bonusGoals.length,
    );
    if (_showRewardInventory) {
      return FutureBuilder<Set<String>>(
        future: _rewardInventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return _RewardInventoryScreen(
              acquiredRewards: snapshot.requireData,
              onBack: () => _changeSurface(() => _showRewardInventory = false),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    if (_showExpedition) {
      return _ExpeditionContractScreen(
        progress: _expeditionProgress,
        unlockedLevel: _unlockedLevel,
        onStart: (type) => unawaited(_startExpedition(type)),
        onPlayStage: (stageId) => unawaited(_playExpeditionStage(stageId)),
        onClear: () => unawaited(_clearExpedition()),
        onShare: () => unawaited(_shareExpedition()),
        onImport: _importExpedition,
        onBack: () => _changeSurface(() => _showExpedition = false),
      );
    }
    if (_showReplayLibrary) {
      return FutureBuilder<ReplayLibraryStore>(
        future: _replayLibraryFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ReplayLibraryScreen(
              store: snapshot.requireData,
              comparisonUnlocked: restorationProgress.isUpgraded(
                IslandLandmark.bridge,
              ),
              onBack: () => _changeSurface(() => _showReplayLibrary = false),
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
        onExit: () => _changeSurface(() => _showDailyChallenge = false),
        showDebugControls: widget.showDebugControls,
        tutorialVariant: _tutorialVariant,
        telemetry: _telemetry,
        language: _language,
      );
    }
    if (_showPhysicsLab) {
      return PhysicsLabScreen(
        showWeeklyHistory: restorationProgress.isUpgraded(
          IslandLandmark.observatory,
        ),
        onBack: () => _changeSurface(() => _showPhysicsLab = false),
      );
    }
    if (_showPuzzleForge) {
      return PuzzleForgeScreen(
        onBack: () => _changeSurface(() => _showPuzzleForge = false),
        language: _language,
      );
    }
    if (_showCoreExperience) {
      return CoreExperienceScreen(
        onExit: () => _changeSurface(() => _showCoreExperience = false),
        onContinueCampaign: () {
          _changeSurface(() => _showCoreExperience = false);
          unawaited(_startOrResume());
        },
        language: _language,
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
        initialDiscoveredMilestoneIds: _activeIsExpedition
            ? const {}
            : _discoveriesByStageId[levels[activeStage].id] ?? const {},
        initialSolutionEntries: _activeSolutionEntries,
        onSolutionDiscovered: _activeIsExpedition ? null : _recordSolutionRoute,
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
        onStageRequested: (index) =>
            _startStage(index, expedition: _activeIsExpedition),
        onShotCommitted: _recordShot,
        onHintKeyCollected: _recordHintKeyCollection,
        onHintEntitlementRead: _readCurrentHintEntitlement,
        onHintFailure: _recordCurrentHintFailure,
        onHintOpened: _openCurrentHint,
        onDiscoveriesRecorded: _activeIsExpedition ? null : _recordDiscoveries,
        onExpeditionStageCompleted: _activeIsExpedition
            ? _recordExpeditionOutcome
            : null,
        onTraitActionCommitted: _recordTraitAction,
        onStageRestarted: _restartStageRun,
        onShotRewound: _rewindStageRun,
        onPracticeAssistUsed: _markCurrentStageAssisted,
        progressStore: _progressStore,
        progressPersistencePolicy: _activeIsExpedition
            ? GameProgressPersistencePolicy.disabled
            : GameProgressPersistencePolicy.enabled,
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
        onBack: () => _changeSurface(() => _showStageSelect = false),
        onSelectStage: (index) => unawaited(_startStage(index)),
        unlockedLevel: _unlockedLevel,
        clearedLevels: _clearedLevels,
        discoveriesByStageId: _discoveriesByStageId,
        solutionCountsByStageId: _solutionCountsByStageId,
        bestShots: _bestShots,
        bonusGoals: _bonusGoals,
        personalRecords: _personalRecords,
        islandSupportFocus: _islandSupportFocus,
        onIslandSupportSelected: (landmark) =>
            unawaited(_selectIslandSupport(landmark)),
        onPhysicsLab: () => _changeSurface(() => _showPhysicsLab = true),
      );
    }
    return _HomeScreen(
      hasCompletedFirstStage: _clearedLevels.isNotEmpty,
      advancedActivitiesUnlocked: _clearedLevels.length >= 3,
      telemetry: _telemetry,
      onCoreExperience: () => _changeSurface(() => _showCoreExperience = true),
      onPuzzleForge: () => _changeSurface(() => _showPuzzleForge = true),
      onStart: () => unawaited(_startOrResume()),
      onStageSelect: () => _changeSurface(() => _showStageSelect = true),
      onRewardInventory: _openRewardInventory,
      onExpedition: () => _changeSurface(() => _showExpedition = true),
      onDailyChallenge: () => _changeSurface(() => _showDailyChallenge = true),
      onReplayLibrary: () => _changeSurface(() => _showReplayLibrary = true),
      showDebugControls: widget.showDebugControls,
      tutorialVariant: _tutorialVariant,
      onTutorialVariantChanged: (variant) {
        setState(() => _tutorialVariant = variant);
      },
      language: _language,
      onLanguageChanged: _changeLanguage,
    );
  }
}

class _ExpeditionContractScreen extends StatelessWidget {
  const _ExpeditionContractScreen({
    required this.progress,
    required this.unlockedLevel,
    required this.onStart,
    required this.onPlayStage,
    required this.onClear,
    required this.onShare,
    required this.onImport,
    required this.onBack,
  });

  final ExpeditionContractProgress? progress;
  final int unlockedLevel;
  final ValueChanged<ExpeditionContractType> onStart;
  final ValueChanged<String> onPlayStage;
  final VoidCallback onClear;
  final VoidCallback onShare;
  final Future<void> Function(String) onImport;
  final VoidCallback onBack;

  IconData _icon(ExpeditionContractType type) => switch (type) {
    ExpeditionContractType.discovery => Icons.travel_explore_rounded,
    ExpeditionContractType.precision => Icons.center_focus_strong_rounded,
    ExpeditionContractType.chain => Icons.hub_rounded,
    ExpeditionContractType.creative => Icons.auto_awesome_rounded,
    ExpeditionContractType.restoration => Icons.account_tree_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final active = progress;
    return Scaffold(
      key: const Key('expedition_contract_screen'),
      backgroundColor: const Color(0xFFBFE8E3),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('expedition_back_button'),
          onPressed: onBack,
          tooltip: '메인 메뉴로 돌아가기',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('3단계 탐사'),
        backgroundColor: const Color(0xFFFFF4CF),
        foregroundColor: const Color(0xFF173F43),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            Text(
              active == null ? '이번 탐사의 목적을 고르세요' : active.type.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF173F43),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              active == null
                  ? '같은 캠페인 스테이지를 다른 목표로 즐깁니다. 목표를 놓쳐도 진행은 막히지 않아요.'
                  : '${active.type.summary} · 진행 ${active.completedCount}/3 · 달성 ${active.achievedCount}/3',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF315E60),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            if (active == null) ...[
              OutlinedButton.icon(
                key: const Key('expedition_import_button'),
                onPressed: () => _showExpeditionImportDialog(context),
                icon: const Icon(Icons.input_rounded),
                label: const Text('받은 탐사 코드 입력'),
              ),
              const SizedBox(height: 12),
              for (final type in ExpeditionContractType.values) ...[
                _buildContractCard(context, type),
                const SizedBox(height: 10),
              ],
            ] else ...[
              LinearProgressIndicator(
                key: const Key('expedition_progress_bar'),
                value: active.completedCount / 3,
                minHeight: 10,
                borderRadius: BorderRadius.circular(99),
                color: const Color(0xFF2E8B67),
                backgroundColor: const Color(0xFFD4E9DE),
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < active.stageIds.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ExpeditionStageTile(
                    index: index,
                    stageId: active.stageIds[index],
                    completed: active.completedStageIds.contains(
                      active.stageIds[index],
                    ),
                    achieved: active.achievedStageIds.contains(
                      active.stageIds[index],
                    ),
                    unlockedLevel: unlockedLevel,
                    onPlay: onPlayStage,
                  ),
                ),
              const SizedBox(height: 6),
              if (active.isComplete)
                Container(
                  key: const Key('expedition_complete_card'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF3D5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4C8A5A)),
                  ),
                  child: Text(
                    active.type == ExpeditionContractType.restoration
                        ? '최종 복구 탐사 완료 · 목표 ${active.achievedCount}/3 달성\n'
                              '관측소·등대·다리의 지원을 속성 한방까지 연결했습니다.'
                        : '탐사 완료 · 목표 ${active.achievedCount}/3 달성\n'
                              '다른 관점의 탐사를 골라 같은 물리를 새로 시험해 보세요.',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                key: const Key('expedition_share_button'),
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text('이 탐사 코드 복사'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('expedition_change_contract_button'),
                onPressed: onClear,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(active.isComplete ? '다른 탐사 고르기' : '탐사 목표 바꾸기'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContractCard(BuildContext context, ExpeditionContractType type) {
    final enabled =
        type != ExpeditionContractType.restoration ||
        unlockedLevel >= levels.length - 1;
    final summary = enabled
        ? type.summary
        : '${type.summary}\n10단계를 해금하면 시작할 수 있어요.';
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '${type.title}. $summary',
      child: Opacity(
        opacity: enabled ? 1 : 0.62,
        child: Card(
          key: Key('expedition_contract_${type.name}'),
          color: const Color(0xFFFFF9E8),
          child: InkWell(
            onTap: enabled ? () => onStart(type) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFFFE0A8),
                    foregroundColor: const Color(0xFF7A4B1F),
                    child: Icon(_icon(type)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type.title,
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(summary),
                      ],
                    ),
                  ),
                  Icon(
                    enabled ? Icons.chevron_right_rounded : Icons.lock_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showExpeditionImportDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? error;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          key: const Key('expedition_import_dialog'),
          title: const Text('탐사 코드 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('같은 목표와 같은 3개 스테이지를 처음부터 플레이합니다.'),
              const SizedBox(height: 12),
              TextField(
                key: const Key('expedition_import_field'),
                controller: controller,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'PSX1-로 시작하는 코드',
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            FilledButton(
              key: const Key('expedition_import_confirm'),
              onPressed: () async {
                try {
                  await onImport(controller.text);
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } on FormatException catch (exception) {
                  setDialogState(() => error = exception.message);
                }
              },
              child: const Text('탐사 시작'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}

class _ExpeditionStageTile extends StatelessWidget {
  const _ExpeditionStageTile({
    required this.index,
    required this.stageId,
    required this.completed,
    required this.achieved,
    required this.unlockedLevel,
    required this.onPlay,
  });

  final int index;
  final String stageId;
  final bool completed;
  final bool achieved;
  final int unlockedLevel;
  final ValueChanged<String> onPlay;

  @override
  Widget build(BuildContext context) {
    final stageIndex = levels.indexWhere((level) => level.id == stageId);
    final unlocked = stageIndex >= 0 && stageIndex <= unlockedLevel;
    return Container(
      key: Key('expedition_stage_$index'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFE3F2E7) : const Color(0xFFFFF9E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: completed ? const Color(0xFF5B9870) : const Color(0xFF9D8258),
        ),
      ),
      child: Row(
        children: [
          Icon(
            completed
                ? achieved
                      ? Icons.verified_rounded
                      : Icons.check_circle_outline_rounded
                : unlocked
                ? Icons.flag_outlined
                : Icons.lock_outline_rounded,
            color: completed
                ? const Color(0xFF2E7D4F)
                : const Color(0xFF7A5A32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stageIndex < 0 ? stageId : levels[stageIndex].name,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  completed
                      ? achieved
                            ? '탐사 목표까지 달성'
                            : '클리어 완료 · 목표는 다음에 재도전 가능'
                      : unlocked
                      ? '지금 플레이할 수 있어요'
                      : '앞 단계를 클리어하면 열려요',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!completed && unlocked)
            FilledButton(
              key: Key('expedition_play_$index'),
              onPressed: () => onPlay(stageId),
              child: const Text('플레이'),
            ),
        ],
      ),
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
          SizedBox.square(
            dimension: 58,
            child: Image(
              image: AssetImage('assets/generated/nav-reward-satchel-v1.png'),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
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
    final iconAsset = _rewardInventoryAsset(reward.effectKind);
    return Semantics(
      container: true,
      label:
          '${reward.name}, ${reward.role.label}, ${reward.activationLabel}, $status, ${reward.description}, '
          '다음 사용 계획 ${reward.planningPrompt}, 사용 후 효과 ${reward.effectRecap}',
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
            SizedBox.square(
              dimension: 54,
              child: Image.asset(
                iconAsset,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true,
              ),
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
                  const SizedBox(height: 5),
                  Text(
                    '${reward.role.label} · ${reward.role.description}',
                    key: Key('reward_inventory_role_${reward.id}'),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF8A6527),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(reward.description),
                  const SizedBox(height: 6),
                  Text(
                    '${reward.activationLabel} · ${reward.usageHint}',
                    key: Key('reward_inventory_usage_${reward.id}'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF315E60),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '다음 사용 계획 · ${reward.planningPrompt}',
                    key: Key('reward_inventory_plan_${reward.id}'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF6D5720),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '사용하면 · ${reward.effectRecap}',
                    key: Key('reward_inventory_recap_${reward.id}'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF315E60),
                    ),
                  ),
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

String _rewardInventoryAsset(RunRewardEffectKind kind) => switch (kind) {
  RunRewardEffectKind.cloneCore =>
    'assets/generated/stage-icon-property-transfer-v1.png',
  RunRewardEffectKind.shotCancelAssist => 'assets/generated/nav-helm-v1.png',
  RunRewardEffectKind.spentBallRecovery =>
    'assets/generated/stage-icon-persistent-ball-v1.png',
  RunRewardEffectKind.firstImpactGuide =>
    'assets/generated/nav-stage-map-v1.png',
  RunRewardEffectKind.optionalChallengeGuard =>
    'assets/generated/island-lighthouse-v2.png',
  RunRewardEffectKind.failureCauseBoost => 'assets/generated/nav-replay-v1.png',
  RunRewardEffectKind.ballAppearance => 'assets/generated/ball-bouncy-v1.png',
  RunRewardEffectKind.stageRecordGuard =>
    'assets/generated/nav-activities-v1.png',
  RunRewardEffectKind.nextStageHintAccess =>
    'assets/generated/hint-lantern-v2.png',
  RunRewardEffectKind.precisionCharge => 'assets/generated/power-slider-v1.png',
};

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.hasCompletedFirstStage,
    required this.advancedActivitiesUnlocked,
    required this.telemetry,
    required this.onCoreExperience,
    required this.onPuzzleForge,
    required this.onStart,
    required this.onStageSelect,
    required this.onRewardInventory,
    required this.onExpedition,
    required this.onDailyChallenge,
    required this.onReplayLibrary,
    required this.showDebugControls,
    required this.tutorialVariant,
    required this.onTutorialVariantChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  final bool hasCompletedFirstStage;
  final bool advancedActivitiesUnlocked;
  final LocalPlayTelemetry telemetry;
  final VoidCallback onCoreExperience;
  final VoidCallback onPuzzleForge;
  final VoidCallback onStart;
  final VoidCallback onStageSelect;
  final VoidCallback onRewardInventory;
  final VoidCallback onExpedition;
  final VoidCallback onDailyChallenge;
  final VoidCallback onReplayLibrary;
  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;
  final ValueChanged<TutorialExperimentVariant> onTutorialVariantChanged;
  final AppLanguage language;
  final ValueChanged<AppLanguage> onLanguageChanged;

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
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth <= 360;
                  final tablet = constraints.maxWidth >= 700;
                  final hero = _HomeHero(
                    compact: compact,
                    emphasizeCopy: tablet,
                    language: language,
                  );
                  final actions = _HomeActions(
                    appFontFamily: appFontFamily,
                    hasCompletedFirstStage: hasCompletedFirstStage,
                    advancedActivitiesUnlocked: advancedActivitiesUnlocked,
                    onCoreExperience: onCoreExperience,
                    onStart: onStart,
                    onExpedition: onExpedition,
                    onStageSelect: onStageSelect,
                    onRewardInventory: onRewardInventory,
                    onReplayLibrary: onReplayLibrary,
                    onDailyChallenge: onDailyChallenge,
                    language: language,
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 18 : 24,
                      tablet ? 56 : 68,
                      compact ? 18 : 24,
                      28,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: tablet ? 940 : 430,
                          minHeight: math.max(0, constraints.maxHeight - 104),
                        ),
                        child: tablet
                            ? Row(
                                key: const Key('home_tablet_layout'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(child: hero),
                                  const SizedBox(width: 56),
                                  SizedBox(width: 360, child: actions),
                                ],
                              )
                            : Column(
                                key: const Key('home_mobile_layout'),
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  hero,
                                  SizedBox(height: compact ? 18 : 24),
                                  actions,
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    key: const Key('puzzle_forge_entry_button'),
                    label: language.pick('AI 제작 과정', 'AI creation process'),
                    button: true,
                    child: IconButton.filledTonal(
                      tooltip: language.pick('AI 제작 과정', 'AI creation process'),
                      onPressed: onPuzzleForge,
                      icon: Image.asset(
                        'assets/generated/stage-icon-property-transfer-v1.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  TextButton(
                    key: const Key('language_toggle_button'),
                    onPressed: () => onLanguageChanged(
                      language.isEnglish
                          ? AppLanguage.korean
                          : AppLanguage.english,
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      backgroundColor: const Color(0xCCF5F3DA),
                    ),
                    child: Text(
                      language.isEnglish ? '한국어' : 'EN',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    key: const Key('feedback_settings_button'),
                    tooltip: language.pick(
                      '소리와 진동 설정',
                      'Sound and vibration settings',
                    ),
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _FeedbackSettingsDialog(telemetry: telemetry),
                    ),
                    icon: const Icon(Icons.tune_rounded),
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

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.compact,
    required this.emphasizeCopy,
    required this.language,
  });

  final bool compact;
  final bool emphasizeCopy;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('home_hero'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _HomePlayPreview(compact: compact),
        SizedBox(height: compact ? 8 : 12),
        Container(
          padding: emphasizeCopy
              ? const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
              : EdgeInsets.zero,
          decoration: emphasizeCopy
              ? BoxDecoration(
                  color: const Color(0xDCF6F3D8),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x8A3E7773)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                )
              : null,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                language.pick('속성 한방', 'PROPERTY SHOT'),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: const Color(0xFF173F43),
                  fontWeight: FontWeight.w900,
                  fontSize: language.isEnglish && compact ? 30 : null,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                language.isEnglish
                    ? compact
                          ? 'Discover the island’s physics\nand wake its landmarks.'
                          : 'Move traits from objects into the ball, make a route,\nand restore the observatory, lighthouse, and bridge.'
                    : compact
                    ? '섬의 물리 규칙을 발견해\n멈춘 시설을 다시 깨우세요.'
                    : '주변 물체의 성질을 공에 담아 길을 만들고\n섬의 관측소·등대·다리를 다시 깨우세요.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF285C5D),
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeActions extends StatelessWidget {
  const _HomeActions({
    required this.appFontFamily,
    required this.hasCompletedFirstStage,
    required this.advancedActivitiesUnlocked,
    required this.onCoreExperience,
    required this.onStart,
    required this.onExpedition,
    required this.onStageSelect,
    required this.onRewardInventory,
    required this.onReplayLibrary,
    required this.onDailyChallenge,
    required this.language,
  });

  final String? appFontFamily;
  final bool hasCompletedFirstStage;
  final bool advancedActivitiesUnlocked;
  final VoidCallback onCoreExperience;
  final VoidCallback onStart;
  final VoidCallback onExpedition;
  final VoidCallback onStageSelect;
  final VoidCallback onRewardInventory;
  final VoidCallback onReplayLibrary;
  final VoidCallback onDailyChallenge;
  final AppLanguage language;

  Widget _secondary({
    required Key key,
    required VoidCallback onPressed,
    required IconData icon,
    String? imageAsset,
    Key? imageKey,
    required String label,
    required Color foreground,
    required Color border,
  }) => OutlinedButton.icon(
    key: key,
    onPressed: onPressed,
    icon: imageAsset == null
        ? Icon(icon, size: 19)
        : _MenuAssetImage(key: imageKey, path: imageAsset, size: 38),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      foregroundColor: foreground,
      side: BorderSide(color: border, width: 1.3),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('home_actions'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          key: const Key('core_experience_button'),
          onPressed: onCoreExperience,
          icon: const _MenuAssetImage(
            key: Key('core_experience_art'),
            path: 'assets/generated/stage-icon-property-transfer-v1.png',
            size: 42,
          ),
          label: Text(language.pick('60초 핵심 체험', '60-SECOND CORE PLAY')),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            backgroundColor: const Color(0xFF176B78),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ).copyWith(fontFamily: appFontFamily),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('start_game_button'),
          onPressed: onStart,
          icon: const _MenuAssetImage(
            key: Key('start_voyage_art'),
            path: 'assets/generated/nav-helm-v1.png',
            size: 40,
          ),
          label: Text(
            hasCompletedFirstStage
                ? language.pick('항해 시작·이어가기', 'START / CONTINUE VOYAGE')
                : language.pick('첫 스테이지 시작', 'START FIRST STAGE'),
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            backgroundColor: const Color(0xFFEF765E),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ).copyWith(fontFamily: appFontFamily),
          ),
        ),
        if (!hasCompletedFirstStage) ...[
          const SizedBox(height: 10),
          _secondary(
            key: const Key('stage_select_button'),
            onPressed: onStageSelect,
            icon: Icons.map_outlined,
            imageAsset: 'assets/generated/nav-stage-map-v1.png',
            imageKey: const Key('stage_navigation_art'),
            label: language.pick('섬 지도 둘러보기', 'EXPLORE ISLAND MAP'),
            foreground: const Color(0xFF245B60),
            border: const Color(0xFF3E7773),
          ),
        ],
        if (hasCompletedFirstStage) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _secondary(
                  key: const Key('expedition_entry_button'),
                  onPressed: onExpedition,
                  icon: Icons.explore_outlined,
                  imageAsset: 'assets/generated/nav-expedition-v1.png',
                  label: language.pick('3단계 탐사', '3-STAGE EXPEDITION'),
                  foreground: const Color(0xFF704315),
                  border: const Color(0xFF9F6529),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _secondary(
                  key: const Key('stage_select_button'),
                  onPressed: onStageSelect,
                  icon: Icons.map_outlined,
                  imageAsset: 'assets/generated/nav-stage-map-v1.png',
                  imageKey: const Key('stage_navigation_art'),
                  label: language.pick('스테이지', 'STAGES'),
                  foreground: const Color(0xFF245B60),
                  border: const Color(0xFF3E7773),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            key: const Key('advanced_activities_menu'),
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFF8CA8A1)),
              borderRadius: BorderRadius.circular(12),
            ),
            collapsedShape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFF8CA8A1)),
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xCCF7FAF3),
            collapsedBackgroundColor: const Color(0xCCF7FAF3),
            leading: const _MenuAssetImage(
              key: Key('other_activities_art'),
              path: 'assets/generated/nav-activities-v1.png',
              size: 38,
            ),
            title: Text(
              language.pick('다른 활동', 'MORE ACTIVITIES'),
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              advancedActivitiesUnlocked
                  ? language.pick(
                      '보상 · 리플레이 · 오늘의 도전',
                      'Rewards · Replays · Daily Route',
                    )
                  : language.pick(
                      '내 런 보상 · 다음 활동은 3단계 후',
                      'Run rewards · More after stage 3',
                    ),
            ),
            children: [
              if (!advancedActivitiesUnlocked) ...[
                _secondary(
                  key: const Key('reward_inventory_entry_button'),
                  onPressed: onRewardInventory,
                  icon: Icons.backpack_outlined,
                  imageAsset: 'assets/generated/nav-reward-satchel-v1.png',
                  label: language.pick('내 런 보상', 'MY RUN REWARDS'),
                  foreground: const Color(0xFF6B4B20),
                  border: const Color(0xFF946B35),
                ),
                const SizedBox(height: 8),
                Container(
                  key: const Key('advanced_activities_preview'),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xCCFFF8E6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFC49A55)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_clock_outlined, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          language.pick(
                            '3개 스테이지를 익히면 리플레이와 오늘의 도전이 열립니다.',
                            'Learn three stages to unlock replays and the daily route.',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: _secondary(
                        key: const Key('reward_inventory_entry_button'),
                        onPressed: onRewardInventory,
                        icon: Icons.backpack_outlined,
                        imageAsset:
                            'assets/generated/nav-reward-satchel-v1.png',
                        label: language.pick('보상', 'REWARDS'),
                        foreground: const Color(0xFF6B4B20),
                        border: const Color(0xFF946B35),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _secondary(
                        key: const Key('replay_library_entry_button'),
                        onPressed: onReplayLibrary,
                        icon: Icons.movie_filter_outlined,
                        imageAsset: 'assets/generated/nav-replay-v1.png',
                        imageKey: const Key('replay_navigation_art'),
                        label: language.pick('리플레이', 'REPLAYS'),
                        foreground: const Color(0xFF514B66),
                        border: const Color(0xFF70678A),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _secondary(
                        key: const Key('daily_challenge_entry_button'),
                        onPressed: onDailyChallenge,
                        icon: Icons.today_rounded,
                        imageAsset:
                            'assets/generated/nav-daily-challenge-v1.png',
                        imageKey: const Key('daily_navigation_art'),
                        label: language.pick('오늘', 'DAILY'),
                        foreground: const Color(0xFF874D2B),
                        border: const Color(0xFFB06E45),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _MenuAssetImage extends StatelessWidget {
  const _MenuAssetImage({super.key, required this.path, required this.size});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Image.asset(
      path,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    ),
  );
}

class _HomePlayPreview extends StatelessWidget {
  const _HomePlayPreview({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '공과 상자와 무거운 돌이 있는 목표 홀 보드',
      child: Container(
        height: compact ? 154 : 174,
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
                'assets/generated/stone-v3.png',
                width: 72,
                height: 54,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 146,
              top: 92,
              child: Image.asset(
                'assets/generated/crate-v3.png',
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

enum _SettingsPreset { recommended, comfortable, direct }

class _FeedbackSettingsDialog extends StatefulWidget {
  const _FeedbackSettingsDialog({required this.telemetry});

  final LocalPlayTelemetry telemetry;

  @override
  State<_FeedbackSettingsDialog> createState() =>
      _FeedbackSettingsDialogState();
}

class _FeedbackSettingsDialogState extends State<_FeedbackSettingsDialog> {
  final ScrollController _scrollController = ScrollController();
  bool _applyingPreset = false;
  bool _exportingSession = false;

  Future<void> _exportSession() async {
    if (_exportingSession) return;
    setState(() => _exportingSession = true);
    try {
      final json = await widget.telemetry.exportPrivacySafeSessionJson();
      await Clipboard.setData(ClipboardData(text: json));
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('현재 세션을 개인정보 없는 JSON으로 복사했습니다.')),
        );
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('세션을 내보내지 못했습니다. 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _exportingSession = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _applyPreset(_SettingsPreset preset) async {
    if (_applyingPreset) return;
    setState(() => _applyingPreset = true);
    final enableGuidance = preset != _SettingsPreset.direct;
    final comfortable = preset == _SettingsPreset.comfortable;
    await Future.wait([
      GameFeedback.setPlayerDifficulty(
        comfortable ? PlayerDifficulty.easy : PlayerDifficulty.normal,
      ),
      GameFeedback.setIntentAssistStrength(switch (preset) {
        _SettingsPreset.recommended => IntentAssistStrength.standard,
        _SettingsPreset.comfortable => IntentAssistStrength.comfortable,
        _SettingsPreset.direct => IntentAssistStrength.off,
      }),
      GameFeedback.setPreviousAimComparisonEnabled(enableGuidance),
      GameFeedback.setLastShotSlowMotionEnabled(enableGuidance),
      GameFeedback.setCollisionOrderEnabled(enableGuidance),
      GameFeedback.setLastContactHighlightEnabled(enableGuidance),
      GameFeedback.setNearestHoleEnabled(enableGuidance),
      GameFeedback.setTraitActivationEnabled(enableGuidance),
      GameFeedback.setGimmickCausalityEnabled(enableGuidance),
      GameFeedback.setCollisionPathIconsEnabled(enableGuidance),
      GameFeedback.setChainScoreDetailsEnabled(enableGuidance),
      GameFeedback.setReducedMotionEnabled(comfortable),
      GameFeedback.setScreenShakeEnabled(!comfortable),
    ]);
    if (!mounted) return;
    setState(() => _applyingPreset = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Text(switch (preset) {
            _SettingsPreset.recommended => '추천 도움 설정을 적용했습니다.',
            _SettingsPreset.comfortable => '편안한 플레이 설정을 적용했습니다.',
            _SettingsPreset.direct => '직접 탐색 설정을 적용했습니다.',
          }),
        ),
      );
  }

  Widget _presetChip({
    required Key key,
    required _SettingsPreset preset,
    required String label,
    required IconData icon,
  }) => ActionChip(
    key: key,
    avatar: Icon(icon, size: 18),
    label: Text(label),
    onPressed: _applyingPreset ? null : () => unawaited(_applyPreset(preset)),
  );

  Widget _sectionHeader({
    required Key key,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      key: key,
      header: true,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.secondaryContainer.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colors.onSecondaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            key: const Key('settings_scroll_view'),
            controller: _scrollController,
            padding: const EdgeInsets.only(right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _sectionHeader(
                  key: const Key('local_session_export_section'),
                  title: '내 플레이 기록',
                  description: '현재 세션만 기기 안에서 정리합니다. 링크 생성이나 서버 전송은 하지 않습니다.',
                  icon: Icons.file_download_outlined,
                ),
                ListTile(
                  key: const Key('local_session_export_button'),
                  contentPadding: EdgeInsets.zero,
                  leading: _exportingSession
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.data_object_rounded),
                  title: const Text('세션 JSON 복사'),
                  subtitle: const Text('시간·내부 ID를 제거한 분석용 기록'),
                  onTap: _exportingSession ? null : _exportSession,
                ),
                _sectionHeader(
                  key: const Key('settings_preset_section'),
                  title: '빠른 설정',
                  description: '플레이 방식부터 고른 뒤 세부 항목을 원하는 만큼 바꿀 수 있습니다.',
                  icon: Icons.tune_rounded,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      _presetChip(
                        key: const Key('settings_preset_recommended'),
                        preset: _SettingsPreset.recommended,
                        label: '추천',
                        icon: Icons.thumb_up_alt_outlined,
                      ),
                      _presetChip(
                        key: const Key('settings_preset_comfortable'),
                        preset: _SettingsPreset.comfortable,
                        label: '편안하게',
                        icon: Icons.accessibility_new_rounded,
                      ),
                      _presetChip(
                        key: const Key('settings_preset_direct'),
                        preset: _SettingsPreset.direct,
                        label: '직접 탐색',
                        icon: Icons.explore_outlined,
                      ),
                    ],
                  ),
                ),
                _sectionHeader(
                  key: const Key('aim_help_settings_section'),
                  title: '조준 도움',
                  description: '정답을 바꾸지 않고 조준을 읽기 쉽게 만듭니다.',
                  icon: Icons.adjust,
                ),
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
                  decoration: const InputDecoration(
                    labelText: '정밀 조작 도움',
                    helperText:
                        '예상 첫 도착과 각도·힘 미세 조정 버튼을 제공합니다. 사용한 단계는 경쟁 기록과 분리됩니다.',
                    helperMaxLines: 3,
                  ),
                  initialValue: GameFeedback.playerDifficulty,
                  items: const [
                    DropdownMenuItem(
                      value: PlayerDifficulty.normal,
                      child: Text('끄기 · 직접 조작'),
                    ),
                    DropdownMenuItem(
                      value: PlayerDifficulty.easy,
                      child: Text('켜기 · 미세 조정 포함'),
                    ),
                  ],
                  onChanged: (difficulty) {
                    if (difficulty == null) return;
                    setState(() => GameFeedback.playerDifficulty = difficulty);
                    unawaited(GameFeedback.setPlayerDifficulty(difficulty));
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<IntentAssistStrength>(
                  key: const Key('intent_assist_strength_dropdown'),
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: '의도 보정',
                    helperText: '가까운 목표를 살짝 빗나간 포인터 입력만 실제 물리 판정 안에서 보정합니다.',
                    helperMaxLines: 3,
                  ),
                  initialValue: GameFeedback.intentAssistStrength,
                  items: const [
                    DropdownMenuItem(
                      value: IntentAssistStrength.standard,
                      child: Text('기본 · 작은 오차만 보정'),
                    ),
                    DropdownMenuItem(
                      value: IntentAssistStrength.comfortable,
                      child: Text('편안하게 · 터치 오차 확대'),
                    ),
                    DropdownMenuItem(
                      value: IntentAssistStrength.off,
                      child: Text('끄기 · 입력 그대로'),
                    ),
                  ],
                  onChanged: (strength) {
                    if (strength == null) return;
                    setState(
                      () => GameFeedback.intentAssistStrength = strength,
                    );
                    unawaited(GameFeedback.setIntentAssistStrength(strength));
                  },
                ),
                _settingSwitch(
                  key: const Key('previous_aim_comparison_toggle'),
                  title: '직전 조준 비교',
                  subtitle: '실패 후 직전 각도와 힘을 회색선으로 남깁니다.',
                  value: GameFeedback.previousAimComparisonEnabled,
                  onChanged: GameFeedback.setPreviousAimComparisonEnabled,
                ),
                _sectionHeader(
                  key: const Key('route_memory_settings_section'),
                  title: '경로 기억',
                  description: '방금 무엇에 부딪혀 어디까지 갔는지 복기합니다.',
                  icon: Icons.route_outlined,
                ),
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
                _sectionHeader(
                  key: const Key('causality_settings_section'),
                  title: '인과 이해',
                  description: '속성과 기믹이 어떤 결과를 만들었는지 보여 줍니다.',
                  icon: Icons.hub_outlined,
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
                _sectionHeader(
                  key: const Key('sensory_settings_section'),
                  title: '화면과 소리',
                  description: '움직임·점멸·진동·소리 강도를 내게 맞춥니다.',
                  icon: Icons.tune,
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
                        const SnackBar(
                          content: Text('도움말을 다음 화면에서 다시 보여 드립니다.'),
                        ),
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
    required this.clearedLevels,
    required this.discoveriesByStageId,
    required this.solutionCountsByStageId,
    required this.bestShots,
    required this.bonusGoals,
    required this.personalRecords,
    required this.islandSupportFocus,
    required this.onIslandSupportSelected,
    this.onPhysicsLab,
  });

  final VoidCallback onBack;
  final ValueChanged<int> onSelectStage;
  final int unlockedLevel;
  final Set<int> clearedLevels;
  final Map<String, Set<String>> discoveriesByStageId;
  final Map<String, int> solutionCountsByStageId;
  final Map<int, int> bestShots;
  final Set<int> bonusGoals;
  final Map<int, Set<PersonalRecordKind>> personalRecords;
  final IslandLandmark? islandSupportFocus;
  final ValueChanged<IslandLandmark> onIslandSupportSelected;
  final VoidCallback? onPhysicsLab;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth <= 360 || constraints.maxHeight < 700;
        final wide = constraints.maxWidth >= 600;
        final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.3;
        final navigationArtSize = wide ? 52.0 : 44.0;
        final recommendation = const NextGoalRecommendationEngine().recommend(
          stageCount: levels.length,
          unlockedLevel: unlockedLevel,
          clearedLevels: clearedLevels,
          discoveryCounts: {
            for (var index = 0; index < levels.length; index++)
              index:
                  discoveriesByStageId[levels[index].id]
                      ?.intersection(stageDiscoveryMilestoneIds(index))
                      .length ??
                  0,
          },
          discoveryTotals: {
            for (var index = 0; index < levels.length; index++)
              index: stageDiscoveryMilestoneIds(index).length,
          },
          bestShots: bestShots,
          parShots: {
            for (var index = 0; index < levels.length; index++)
              index: levels[index].parShots,
          },
          bonusGoals: bonusGoals,
          solutionCounts: {
            for (var index = 0; index < levels.length; index++)
              index: solutionCountsByStageId[levels[index].id] ?? 0,
          },
        );
        return Scaffold(
          key: const Key('stage_select_screen'),
          backgroundColor: const Color(0xFFBFE8E3),
          body: Stack(
            children: [
              const Positioned.fill(child: _IslandBackdrop()),
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    key: const Key('stage_select_content_column'),
                    constraints: const BoxConstraints(maxWidth: 1180),
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
                        if (largeText)
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 48),
                            child: _NextGoalCard(
                              recommendation: recommendation,
                              detailed:
                                  _totalDiscoveryCount(discoveriesByStageId) >=
                                  IslandLandmark.lighthouse.upgradeDiscoveries,
                              onTap: () =>
                                  onSelectStage(recommendation.stageIndex),
                            ),
                          )
                        else
                          SizedBox(
                            height: 48,
                            child: _NextGoalCard(
                              recommendation: recommendation,
                              detailed:
                                  _totalDiscoveryCount(discoveriesByStageId) >=
                                  IslandLandmark.lighthouse.upgradeDiscoveries,
                              onTap: () =>
                                  onSelectStage(recommendation.stageIndex),
                            ),
                          ),
                        Material(
                          key: const Key('map_hint_card'),
                          color: const Color(0xD9E8F4D9),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            key: const Key('discovery_atlas_button'),
                            onTap: () => _showDiscoveryAtlas(context),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  _MenuAssetImage(
                                    key: const Key('discovery_navigation_art'),
                                    path:
                                        'assets/generated/nav-expedition-v1.png',
                                    size: navigationArtSize,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          compact
                                              ? '발견 ${_totalDiscoveryCount(discoveriesByStageId)} / '
                                                    '${levels.length * 3} · 눌러서 도감 보기'
                                              : '전체 발견 ${_totalDiscoveryCount(discoveriesByStageId)} / '
                                                    '${levels.length * 3} · 눌러서 발견 도감을 확인하세요.',
                                          style: const TextStyle(
                                            color: Color(0xFF52706A),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF4F8460),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: const Color(0xE6FFF7D6),
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            key: const Key('physics_lab_button'),
                            onTap: onPhysicsLab,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  _MenuAssetImage(
                                    key: const Key(
                                      'physics_lab_navigation_art',
                                    ),
                                    path:
                                        'assets/generated/nav-physics-lab-v1.png',
                                    size: navigationArtSize,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '물리 실험실',
                                          style: TextStyle(
                                            color: Color(0xFF5B4715),
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        SizedBox(height: 3),
                                        Text(
                                          '무거움·탄성·점착·뾰족함·스위치를 기록 없이 연습하세요.',
                                          style: TextStyle(
                                            color: Color(0xFF715F35),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF6D5720),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _IslandRestorationCard(
                          progress: IslandRestorationProgress.fromDiscoveries(
                            discoveriesByStageId: discoveriesByStageId,
                            stageIds: levels.map((level) => level.id).toList(),
                            optionalMasteryCount: bonusGoals.length,
                          ),
                          selectedFocus: islandSupportFocus,
                          onFocusSelected: onIslandSupportSelected,
                          compact: compact,
                          wide: wide,
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
                                  constraints.maxWidth * (narrow ? 0.94 : 0.84);
                              final cardStep = narrow ? 148.0 : 142.0;
                              final thumbnailSize = constraints.maxWidth >= 600
                                  ? 104.0
                                  : constraints.maxWidth >= 330
                                  ? 86.0
                                  : 80.0;
                              final mapHeight = math.max(
                                350.0,
                                8 + levels.length * cardStep,
                              );
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      8,
                                      0,
                                      8,
                                      4,
                                    ),
                                    child: Row(
                                      children: [
                                        const _MenuAssetImage(
                                          key: Key('first_voyage_route_art'),
                                          path:
                                              'assets/generated/nav-stage-map-v1.png',
                                          size: 28,
                                        ),
                                        const SizedBox(width: 6),
                                        if (largeText)
                                          Expanded(
                                            child: Text(
                                              '첫 항해 진행',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    color: const Color(
                                                      0xFF397372,
                                                    ),
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                            ),
                                          )
                                        else
                                          Text(
                                            '첫 항해 진행',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelLarge
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF397372,
                                                  ),
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        if (largeText)
                                          const SizedBox(width: 4)
                                        else
                                          const Spacer(),
                                        Text(
                                          '${(unlockedLevel + 1).clamp(1, levels.length)} / ${levels.length}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
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
                                              solutionStampCount:
                                                  solutionCountsByStageId[levels[index]
                                                      .id] ??
                                                  0,
                                              bestShot: bestShots[index],
                                              bonusAchieved: bonusGoals
                                                  .contains(index),
                                              personalRecords:
                                                  personalRecords[index] ??
                                                  const {},
                                              thumbnailSize: thumbnailSize,
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
                ),
              ),
            ],
          ),
        );
      },
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

  Future<void> _showDiscoveryAtlas(BuildContext context) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: const Color(0xFFFFF9E8),
        builder: (_) =>
            _DiscoveryAtlasSheet(discoveriesByStageId: discoveriesByStageId),
      );
}

class _NextGoalCard extends StatelessWidget {
  const _NextGoalCard({
    required this.recommendation,
    required this.onTap,
    this.detailed = false,
  });

  final NextGoalRecommendation recommendation;
  final VoidCallback onTap;
  final bool detailed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: detailed
          ? '다음 목표. ${recommendation.title}. 추천 이유: ${recommendation.reason}'
          : '다음 목표. ${recommendation.title}',
      child: Card(
        key: const Key('next_goal_card'),
        margin: EdgeInsets.zero,
        color: const Color(0xFFFFF1D5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.near_me_rounded, color: Color(0xFF8A5725)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '지금 해볼 만한 목표',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        detailed
                            ? '${recommendation.title} · 추천 이유: ${recommendation.reason}'
                            : '${recommendation.title} · 등대를 성장시키면 추천 이유도 볼 수 있어요.',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryAtlasSheet extends StatelessWidget {
  const _DiscoveryAtlasSheet({required this.discoveriesByStageId});

  final Map<String, Set<String>> discoveriesByStageId;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Column(
        key: const Key('discovery_atlas_sheet'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Color(0xFF315C46)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '속성 발견 도감',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  key: const Key('discovery_atlas_close'),
                  tooltip: '발견 도감 닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              '실제로 확인한 물리 사건만 기록됩니다. 스테이지를 클리어하면 이번 도전에서 찾은 규칙이 섬 복구에 반영됩니다.',
              style: TextStyle(color: Color(0xFF52706A), height: 1.35),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final stageId = levels[index].id;
                final discovered = discoveriesByStageId[stageId] ?? const {};
                final labels = stageDiscoveryMilestoneLabels(index);
                final count = discovered
                    .intersection(labels.keys.toSet())
                    .length;
                return Card(
                  key: Key('discovery_atlas_stage_$index'),
                  color: count == labels.length
                      ? const Color(0xFFE3F2E7)
                      : const Color(0xFFFFFDF3),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${index + 1}. ${levels[index].name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '$count/${labels.length}',
                              style: const TextStyle(
                                color: Color(0xFF315C46),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final entry in labels.entries)
                              Chip(
                                avatar: Icon(
                                  discovered.contains(entry.key)
                                      ? Icons.check_circle_rounded
                                      : Icons.help_outline_rounded,
                                  size: 17,
                                ),
                                label: Text(
                                  discovered.contains(entry.key)
                                      ? entry.value
                                      : '아직 발견하지 않음',
                                ),
                                backgroundColor: discovered.contains(entry.key)
                                    ? const Color(0xFFD7F0D2)
                                    : const Color(0xFFE7E4D9),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _IslandLandmarkIllustration extends StatelessWidget {
  const _IslandLandmarkIllustration({
    super.key,
    required this.landmark,
    required this.progress,
    required this.size,
  });

  final IslandLandmark landmark;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final normalized = progress.clamp(0.0, 1.0);
    final stateLabel = normalized >= 1
        ? '복구 완료'
        : normalized > 0
        ? '수리 중'
        : '폐허';
    return Semantics(
      image: true,
      label: '${landmark.label} $stateLabel',
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: 0.5,
              child: ColorFiltered(
                colorFilter: const ColorFilter.matrix(<double>[
                  .2126,
                  .7152,
                  .0722,
                  0,
                  0,
                  .2126,
                  .7152,
                  .0722,
                  0,
                  0,
                  .2126,
                  .7152,
                  .0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
                child: _landmarkAsset(landmark),
              ),
            ),
            if (normalized > 0)
              ClipRect(
                clipper: _RestorationRevealClipper(normalized),
                child: _landmarkAsset(landmark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _landmarkAsset(IslandLandmark landmark) => Image.asset(
    switch (landmark) {
      IslandLandmark.observatory =>
        'assets/generated/island-observatory-v2.png',
      IslandLandmark.lighthouse => 'assets/generated/island-lighthouse-v2.png',
      IslandLandmark.bridge => 'assets/generated/island-bridge-v2.png',
    },
    fit: BoxFit.contain,
    filterQuality: FilterQuality.medium,
    excludeFromSemantics: true,
  );
}

class _RestorationRevealClipper extends CustomClipper<Rect> {
  const _RestorationRevealClipper(this.progress);

  final double progress;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    0,
    size.height * (1 - progress.clamp(0.0, 1.0)),
    size.width,
    size.height,
  );

  @override
  bool shouldReclip(covariant _RestorationRevealClipper oldClipper) =>
      oldClipper.progress != progress;
}

@visibleForTesting
Widget buildIslandLandmarkIllustrationForTesting({
  required IslandLandmark landmark,
  required double progress,
  double size = 48,
}) => _IslandLandmarkIllustration(
  landmark: landmark,
  progress: progress,
  size: size,
);

@visibleForTesting
Widget buildIslandRestorationCelebrationForTesting({
  required IslandLandmark landmark,
  VoidCallback? onContinue,
}) => _IslandRestorationCelebration(landmark: landmark, onContinue: onContinue);

class _IslandRestorationCelebration extends StatelessWidget {
  const _IslandRestorationCelebration({
    required this.landmark,
    this.onContinue,
  });

  final IslandLandmark landmark;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = GameFeedback.reducedMotionEnabled;
    final illustration = _IslandLandmarkIllustration(
      landmark: landmark,
      progress: 1,
      size: 116,
    );
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '${landmark.label} 복구 완료. ${landmark.benefitLabel}. ${landmark.benefitDescription}',
      child: Container(
        key: Key('island_restoration_celebration_${landmark.name}'),
        constraints: const BoxConstraints(maxWidth: 390),
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF5C7), Color(0xFFD9F1DB)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF4F8A5D), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x330D4B32),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '섬이 다시 빛나기 시작했어요',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF52706A),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (reduceMotion)
              illustration
            else
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 520),
                tween: Tween(begin: 0.82, end: 1),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: illustration,
              ),
            const SizedBox(height: 8),
            Text(
              '${landmark.label} 복구 완료',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF245B43),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xEFFFFFFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '새 지원 해금 · ${landmark.benefitLabel}',
                    key: const Key('island_restoration_unlocked_benefit'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF315C46),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    landmark.benefitDescription,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF52706A),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('island_restoration_celebration_continue'),
              onPressed: onContinue,
              icon: const _MenuAssetImage(
                path: 'assets/generated/nav-helm-v1.png',
                size: 30,
              ),
              label: const Text('새 지원으로 항해 계속'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IslandRestorationCard extends StatelessWidget {
  const _IslandRestorationCard({
    required this.progress,
    required this.selectedFocus,
    required this.onFocusSelected,
    this.compact = false,
    this.wide = false,
  });

  final IslandRestorationProgress progress;
  final IslandLandmark? selectedFocus;
  final ValueChanged<IslandLandmark> onFocusSelected;
  final bool compact;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Semantics(
        container: true,
        button: true,
        label:
            '섬 복구 ${progress.restoredCount}/3. ${progress.statusText}. 자세히 보기',
        child: Material(
          key: const Key('island_restoration_card'),
          color: Colors.transparent,
          child: InkWell(
            key: const Key('island_restoration_expand'),
            onTap: () => _showDetails(context),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF4CF), Color(0xFFE7F4DE)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF92B18B)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '섬 복구 현황',
                          style: TextStyle(
                            color: Color(0xFF315C46),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${progress.restoredCount}/3',
                        style: const TextStyle(
                          color: Color(0xFF315C46),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF396A50),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      for (final landmark in IslandLandmark.values)
                        Expanded(
                          child: Column(
                            children: [
                              _IslandLandmarkIllustration(
                                key: Key(
                                  'island_landmark_art_${landmark.name}',
                                ),
                                landmark: landmark,
                                progress: progress.repairProgress(landmark),
                                size: 44,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                landmark.label,
                                style: const TextStyle(
                                  color: Color(0xFF315C46),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    progress.statusText,
                    key: const Key('island_restoration_status'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF52706A),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '선택 도전 ${progress.optionalMasteryCount}/10 · '
                    '${progress.masteryStatusText}',
                    key: const Key('island_mastery_status'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF52645A),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final reduceMotion = GameFeedback.reducedMotionEnabled;
    final landmarkArtSize = wide ? 78.0 : 58.0;
    return Semantics(
      container: true,
      label:
          '섬 복구 ${progress.restoredCount}/3. ${progress.statusText}. '
          '발견 ${progress.discoveryCount}/${progress.total}. '
          '선택 도전 ${progress.optionalMasteryCount}/10. ${progress.masteryStatusText}. '
          '${progress.restoredLandmarks.map((landmark) => '${landmark.label}: ${landmark.benefitDescription}').join(' ')}',
      child: Container(
        key: const Key('island_restoration_card'),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF4CF), Color(0xFFE7F4DE)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF92B18B)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _MenuAssetImage(
                  path: 'assets/generated/island-observatory-v2.png',
                  size: 34,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '섬 복구 현황',
                    style: TextStyle(
                      color: Color(0xFF315C46),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${progress.restoredCount}/3',
                  style: const TextStyle(
                    color: Color(0xFF315C46),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final landmark in IslandLandmark.values)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: landmark == IslandLandmark.bridge ? 0 : 6,
                      ),
                      child: TweenAnimationBuilder<double>(
                        key: Key('island_landmark_${landmark.name}'),
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 450),
                        tween: Tween(
                          begin: 0,
                          end: progress.repairProgress(landmark),
                        ),
                        builder: (context, value, _) {
                          final restored = progress.isRestored(landmark);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                const Color(0xFFE1DFD3),
                                const Color(0xFFD7F0D2),
                                value,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: restored
                                    ? const Color(0xFF4F8A5D)
                                    : const Color(0xFF9A9480),
                              ),
                            ),
                            child: Column(
                              children: [
                                _IslandLandmarkIllustration(
                                  key: Key(
                                    'island_landmark_art_${landmark.name}',
                                  ),
                                  landmark: landmark,
                                  progress: value,
                                  size: landmarkArtSize,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  landmark.label,
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  progress.isUpgraded(landmark)
                                      ? landmark.upgradeLabel
                                      : restored
                                      ? '${landmark.benefitLabel} · 성장 ${landmark.upgradeDiscoveries}개'
                                      : '${landmark.requiredDiscoveries}개',
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              progress.statusText,
              key: const Key('island_restoration_status'),
              style: const TextStyle(
                color: Color(0xFF52706A),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '선택 도전 ${progress.optionalMasteryCount}/10 · '
              '${progress.masteryStatusText}',
              key: const Key('island_mastery_status'),
              style: const TextStyle(
                color: Color(0xFF3F6653),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
            for (final landmark in progress.restoredLandmarks) ...[
              const SizedBox(height: 5),
              Text(
                '✓ ${landmark.label} · ${landmark.benefitDescription}',
                key: Key('island_benefit_${landmark.name}'),
                style: const TextStyle(
                  color: Color(0xFF315C46),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (progress.isUpgraded(landmark))
                Text(
                  '  ↳ 성장 완료 · ${landmark.upgradeDescription}',
                  key: Key('island_upgrade_${landmark.name}'),
                  style: const TextStyle(
                    color: Color(0xFF315C46),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                )
              else
                Text(
                  '  ↳ 다음 성장 ${landmark.upgradeDiscoveries}개 · ${landmark.upgradeLabel}',
                  style: const TextStyle(
                    color: Color(0xFF66766F),
                    fontSize: 10,
                  ),
                ),
            ],
            if (progress.restoredCount > 0) ...[
              const SizedBox(height: 10),
              const Text(
                '집중 지원 시설',
                style: TextStyle(
                  color: Color(0xFF315C46),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final landmark in progress.restoredLandmarks)
                    ChoiceChip(
                      key: Key('island_focus_${landmark.name}'),
                      selected: selectedFocus == landmark,
                      onSelected: (_) => onFocusSelected(landmark),
                      avatar: _IslandLandmarkIllustration(
                        landmark: landmark,
                        progress: 1,
                        size: 22,
                      ),
                      label: Text(switch (landmark) {
                        IslandLandmark.observatory => '정밀 충전',
                        IslandLandmark.lighthouse => '조준 보정 강화',
                        IslandLandmark.bridge => '코어 +1 추가',
                      }),
                    ),
                ],
              ),
              const Text(
                '기본 복구 효과는 유지됩니다. 진행 중인 런에는 처음 적용된 시설 하나가 끝까지 지원합니다.',
                style: TextStyle(fontSize: 10, color: Color(0xFF52706A)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showDetails(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: const Color(0xFFFFF9E8),
    builder: (sheetContext) => FractionallySizedBox(
      heightFactor: 0.82,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '섬 복구와 지원 기능',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  key: const Key('island_restoration_close'),
                  tooltip: '섬 복구 상세 닫기',
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            _IslandRestorationCard(
              progress: progress,
              selectedFocus: selectedFocus,
              onFocusSelected: onFocusSelected,
              wide: wide,
            ),
          ],
        ),
      ),
    ),
  );
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.index,
    required this.onTap,
    this.discoveredMilestoneIds = const {},
    this.solutionStampCount = 0,
    this.bestShot,
    this.bonusAchieved = false,
    this.personalRecords = const {},
    this.locked = false,
    this.thumbnailSize = 80,
  });

  final int index;
  final VoidCallback onTap;
  final bool locked;
  final Set<String> discoveredMilestoneIds;
  final int solutionStampCount;
  final int? bestShot;
  final bool bonusAchieved;
  final Set<PersonalRecordKind> personalRecords;
  final double thumbnailSize;

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
      'assets/generated/stage-icon-heavy-v1.png',
      'assets/generated/stage-icon-bouncy-v1.png',
      'assets/generated/stage-icon-chain-gate-v1.png',
      'assets/generated/stage-icon-sharp-balloon-v1.png',
      'assets/generated/stage-icon-property-transfer-v1.png',
      'assets/generated/stage-icon-speed-slider-v1.png',
      'assets/generated/stage-icon-persistent-ball-v1.png',
      'assets/generated/stage-icon-chain-score-v1.png',
      'assets/generated/stage-icon-rotating-reflector-v1.png',
      'assets/generated/stage-icon-finale-v1.png',
    ];
    final stageAsset = assets[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xF7FFFDF3),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          key: Key('stage_tile_$index'),
          container: true,
          button: !locked,
          label: '${index + 1}번 ${levels[index].name} 섬',
          hint: locked ? '앞 섬을 클리어하면 열립니다' : '한 번 누르면 스테이지를 시작합니다',
          child: InkWell(
            onTap: locked ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox.square(
                    key: Key('stage_icon_$index'),
                    dimension: thumbnailSize,
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
                                child: Image.asset(
                                  stageAsset,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                  excludeFromSemantics: true,
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
                        if (solutionStampCount > 0) ...[
                          Text(
                            '해법 도장 $solutionStampCount개',
                            key: Key('stage_solution_stamps_$index'),
                            style: const TextStyle(
                              color: Color(0xFF8A5B19),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (bestShot != null || personalRecords.isNotEmpty) ...[
                          Text(
                            [
                              if (bestShot != null) '최고 $bestShot회',
                              if (bonusAchieved) '선택 도전 ✓',
                              if (personalRecords.isNotEmpty)
                                '기록 ${PersonalRecordKind.values.where(personalRecords.contains).map((record) => record.label).join('·')}',
                            ].join(' · '),
                            key: Key('stage_personal_records_$index'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF315C46),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/generated/island-restoration-world-v1.webp',
          key: const Key('island_world_backdrop'),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          filterQuality: FilterQuality.medium,
          semanticLabel: '관측소와 등대와 다리가 이어진 복구 중인 섬',
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x24E8FBF7), Color(0x52BFE8E3), Color(0xA6F6D995)],
              stops: [0, 0.58, 1],
            ),
          ),
        ),
      ],
    );
  }
}
