import 'dart:convert';
import 'dart:math' as math;
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../game/analysis/creative_chain_score.dart';
import '../game/analysis/assist_recommendation.dart';
import '../game/analysis/counterfactual_shot_advice.dart';
import '../game/analysis/failure_replay.dart';
import '../game/analysis/stage_discovery.dart';
import '../game/analysis/solution_mastery.dart';
import '../game/analysis/stage_chain_challenge.dart';
import '../game/domain/entity_state.dart';
import '../game/domain/game_state.dart';
import '../game/domain/geometry.dart';
import '../game/domain/hidden_mechanic_state.dart';
import '../game/domain/level_definition.dart';
import '../game/domain/shot_input.dart';
import '../game/domain/trait.dart';
import '../game/expedition/expedition_contract.dart';
import '../game/hint/deterministic_key_collection_resolver.dart';
import '../game/hint/pattern_hint.dart';
import '../game/input/aim_direction_quantizer.dart';
import '../game/input/intent_assist_resolver.dart';
import '../game/levels/levels.dart';
import '../game/persistence/progress_store.dart';
import '../game/property_shot_game.dart';
import '../game/run/run_state.dart';
import '../game/run/run_hint_state.dart';
import '../game/run/run_reward.dart';
import '../game/run/stage_pattern_session.dart';
import '../game/simulation/shot_resolver.dart';
import '../game/simulation/trait_resolver.dart';
import 'game_feedback.dart';
import 'bonus_goal.dart';
import 'creative_chain_score_summary.dart';
import 'debug_menu.dart';
import 'debug_labels.dart';
import 'play_telemetry.dart';
import 'launch_input_session.dart';
import 'tutorial_experiment.dart';
import 'tutorial_failure_hint.dart';
import 'failure_replay_dialog.dart';
import 'frame_performance_tracker.dart';
import 'trait_transfer_ribbon.dart';

enum GameProgressPersistencePolicy { enabled, disabled }

@visibleForTesting
IntentAssistStrength effectiveIntentAssistStrength({
  required IntentAssistStrength configured,
  required PlayerDifficulty difficulty,
  required Iterable<String> acquiredRewards,
}) {
  if (configured == IntentAssistStrength.off) return configured;
  if (difficulty == PlayerDifficulty.easy ||
      acquiredRewards.contains(restorationLighthouseAimMarker)) {
    return IntentAssistStrength.comfortable;
  }
  return configured;
}

CreativeChainScoreAnalysis? _analyzeSuccessfulStage({
  required GameState state,
  required List<ShotResult> shotResults,
  required int parShots,
}) {
  if (state.phase != GamePhase.success || shotResults.isEmpty) {
    return null;
  }
  return const CreativeChainScoreAnalyzer().analyze(
    shotResults,
    parShots: parShots,
    optionalChallengeIds: CreativeChainChallengeId.all,
  );
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.initialState,
    this.showStageSelector = true,
    this.telemetry,
    this.telemetryContextBuilder,
    this.onExit,
    this.exitToMainMenu = false,
    this.hudScore,
    this.onCopyCoreEarned,
    this.onLevelCleared,
    this.onRunLevelCleared,
    this.onStageRequested,
    this.onShotCommitted,
    this.onTraitActionCommitted,
    this.onStageRestarted,
    this.onShotRewound,
    this.onPracticeAssistUsed,
    this.levelOverride,
    this.initialShotResults = const [],
    this.initialShotInputs = const [],
    this.initialRewardCandidates = const [],
    this.initialSelectedRewardId,
    this.initialAcquiredRewards = const {},
    this.onRewardSelectionPrepared,
    this.onRewardSelected,
    this.onRunRewardUsed,
    this.onRunCompleted,
    this.loadGameAssets = true,
    this.tutorialVariant = TutorialExperimentVariant.guided,
    this.showTutorialFailureHints = true,
    this.difficulty,
    this.intentAssistStrength,
    this.showDebugControls = false,
    this.progressStore,
    this.progressPersistencePolicy = GameProgressPersistencePolicy.enabled,
    this.patternHintEntry,
    this.initialHintEntitlement,
    this.initialCollectedHintKeyIds = const {},
    this.onHintKeyCollected,
    this.onHintEntitlementRead,
    this.onHintFailure,
    this.onHintOpened,
    this.initialDiscoveredMilestoneIds = const {},
    this.onDiscoveriesRecorded,
    this.onExpeditionStageCompleted,
    this.initialSolutionEntries = const [],
    this.onSolutionDiscovered,
    this.debugHintKeyVfxId,
    this.demoLaunchInput,
    this.objectiveOverride,
    this.showDiscoveryHud = true,
    this.exitTooltipOverride,
    this.sequencePosition,
    this.sequenceLength,
    this.nextActionLabel,
  });

  final GameState? initialState;
  final bool showStageSelector;
  final LocalPlayTelemetry? telemetry;
  final PlayTelemetryContext Function()? telemetryContextBuilder;
  final VoidCallback? onExit;
  final bool exitToMainMenu;
  final int? hudScore;
  final Future<bool> Function(int, int)? onCopyCoreEarned;
  final Future<void> Function(int, CreativeChainScoreAnalysis?, bool, int)?
  onLevelCleared;
  final Future<void> Function(int)? onStageRequested;
  final Future<bool> Function(ShotInput, bool)? onShotCommitted;
  final Future<StageCompletionResult> Function(
    int,
    CreativeChainScoreAnalysis?,
    bool,
    int,
    bool,
    bool,
  )?
  onRunLevelCleared;
  final Future<void> Function(String, RunTraitAction)? onTraitActionCommitted;
  final Future<void> Function()? onStageRestarted;
  final Future<Set<String>> Function()? onShotRewound;
  final Future<bool> Function()? onPracticeAssistUsed;
  final LevelDefinition? levelOverride;
  final List<ShotResult> initialShotResults;
  final List<ShotInput> initialShotInputs;
  final List<RunReward> initialRewardCandidates;
  final String? initialSelectedRewardId;
  final Set<String> initialAcquiredRewards;
  final Future<List<RunReward>> Function(int)? onRewardSelectionPrepared;
  final Future<RunReward> Function(String)? onRewardSelected;
  final Future<bool> Function(String, String, bool)? onRunRewardUsed;
  final Future<void> Function()? onRunCompleted;
  final bool loadGameAssets;
  final TutorialExperimentVariant tutorialVariant;
  final bool showTutorialFailureHints;
  final PlayerDifficulty? difficulty;
  final IntentAssistStrength? intentAssistStrength;
  final bool showDebugControls;
  final ProgressStore? progressStore;

  /// 캠페인의 확정된 pattern identity에만 붙는 힌트다. Daily/단독 플레이는
  /// null로 두어 런 상태를 오염시키지 않는다.
  final PatternHintEntry? patternHintEntry;
  final RunHintEntitlement? initialHintEntitlement;
  final Set<String> initialCollectedHintKeyIds;
  final Future<bool> Function(String keyId, String sourceBallId, int shotIndex)?
  onHintKeyCollected;
  final Future<RunHintEntitlement?> Function()? onHintEntitlementRead;
  final Future<RunHintEntitlement?> Function()? onHintFailure;
  final Future<RunHintEntitlement?> Function({int? requestedLevel})?
  onHintOpened;
  final Set<String> initialDiscoveredMilestoneIds;
  final Future<bool> Function(Set<String> milestoneIds)? onDiscoveriesRecorded;
  final Future<void> Function(ExpeditionStageOutcome outcome)?
  onExpeditionStageCompleted;
  final List<SolutionMasteryEntry> initialSolutionEntries;
  final Future<SolutionMasteryRecordResult> Function(SolutionRoute route)?
  onSolutionDiscovered;

  /// Golden test에서만 수집 직후의 짧은 열쇠 반짝임을 결정론적으로 고정한다.
  /// 실제 플레이의 저장·물리·타이머 흐름에는 관여하지 않는다.
  @visibleForTesting
  final String? debugHintKeyVfxId;
  final ShotInput? demoLaunchInput;
  final String? objectiveOverride;
  final bool showDiscoveryHud;
  final String? exitTooltipOverride;
  final int? sequencePosition;
  final int? sequenceLength;
  final String? nextActionLabel;

  /// 오늘의 도전처럼 일반 섬 진행을 오염시키면 안 되는 흐름은 disabled로 둔다.
  final GameProgressPersistencePolicy progressPersistencePolicy;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final _shotResolver = const ShotResolver();
  final _intentAssistResolver = const IntentAssistResolver();
  final _traitResolver = const TraitResolver();
  late final ProgressStore _progressStore;
  final _feedback = GameFeedback();
  final _launchInputSession = LaunchInputSession();
  final _aimFocusNode = FocusNode(debugLabel: 'game_board');
  bool _aimHasFocus = false;
  final _launchInputLatency = LaunchInputLatencyTracker();
  final _framePerformance = FramePerformanceTracker();
  late final LocalPlayTelemetry _telemetry;
  late final PlayerDifficulty _difficulty;
  late final IntentAssistStrength _intentAssistStrength;
  late GameState _state;
  late LevelDefinition _currentLevel;
  late PropertyShotGame _game;
  bool _showBallInfo = false;
  String? _inspectedEntityId;
  Timer? _chargeTimer;
  Timer? _pressActivationTimer;
  Timer? _chargeFeedbackTimer;
  bool _aimStartedForShot = false;
  FirstArrivalPreview? _firstArrivalPreview;
  ShotInput? _firstArrivalInputSnapshot;
  Vec2? _pendingLaunchDirection;
  List<EntityState>? _firstArrivalEntities;
  int? _firstArrivalShotCount;
  Vec2? _firstArrivalDirection;
  int? _firstArrivalPowerBucket;
  TraitType? _firstArrivalTrait;
  List<EntityState>? _previewResultEntities;
  int? _previewResultShotCount;
  Vec2? _previewResultDirection;
  double? _previewResultPower;
  TraitType? _previewResultTrait;
  double? _previewResultHoleForgivenessRadius;
  ShotResult? _previewResult;
  bool _isCharging = false;
  bool _chargeStartRecorded = false;
  ChargeGaugeState _chargeGaugeState = ChargeGaugeState.green;
  bool _chargeGaugeActive = false;
  bool _overchargeFeedbackRecorded = false;
  Duration? _lastPointerTimeStamp;
  Duration? _frameTimeStampAtLastPointer;
  bool _isAnimatingShot = false;
  GameState? _semanticAnimationStartState;
  bool _isCommittingShot = false;
  bool _isCommittingTraitAction = false;
  bool _isCommittingRewardAction = false;
  bool _isCommittingRewind = false;
  bool _isCommittingStageAction = false;
  bool _showClearPopup = false;
  bool _showFailurePopup = false;
  bool _showClearPersistenceError = false;
  String _clearPersistenceErrorTitle = '클리어 기록을 저장하지 못했습니다';
  String _clearPersistenceErrorBody = '기록 저장이 끝나야 보상과 다음 단계로 이동할 수 있습니다.';
  bool _hintWasVisible = false;
  String _failureAdvice = '';
  String? _lastFailureCauseKey;
  int _repeatedFailureCauseCount = 0;
  AssistRecommendation? _assistRecommendation;
  String? _assistRecommendationFeedback;
  final Set<String> _handledAssistRecommendationIds = <String>{};
  FailureReplayData? _failureReplay;
  bool _bestShotsLoaded = false;
  Future<void>? _bestShotsLoadFuture;
  final Map<int, int> _bestShots = {};
  final Map<int, bool> _bonusGoals = {};
  int _unlockedLevel = 0;
  late int _stageCopyCoreAtStart;
  bool _bonusBumperHit = false;
  bool _bonusSwitchPressed = false;
  bool _bonusDrainedSourceMoved = false;
  final List<bool> _bonusBumperHistory = [];
  final List<bool> _bonusSwitchHistory = [];
  final List<bool> _bonusDrainedSourceHistory = [];
  late final List<ShotResult> _stageShotResults;
  late final List<ShotInput> _stageShotInputs;
  CreativeChainScoreAnalysis? _chainScoreAnalysis;
  Future<bool>? _clearPersistenceFuture;
  Future<bool> Function()? _clearPersistenceRetry;
  bool _bonusChallengeAchieved = false;
  late List<RunReward> _rewardCandidates;
  String? _selectedRewardId;
  bool _isSelectingReward = false;
  String? _rewardSelectionError;
  late Set<String> _acquiredRewards;
  String? _guidedImpactLabel;
  bool _challengeGuardAppliedForClear = false;
  bool _recordGuardAppliedForClear = false;
  PlayTelemetryShotPayload? _lastTypedShot;
  String? _traitEffectFeedback;
  TraitTransferFeedback? _traitTransferFeedback;
  Timer? _traitTransferFeedbackTimer;
  late PatternHintEntry? _patternHintEntry;
  RunHintEntitlement? _hintEntitlement;
  late Set<String> _collectedHintKeyIds;
  String? _keyCollectionVfxId;
  Timer? _keyCollectionVfxTimer;
  bool _keySpawnRecorded = false;
  bool _hintAvailableRecorded = false;
  final Set<String> _discoveredMilestoneIds = <String>{};
  ShotInput? _previousAimInput;
  late final Set<String> _persistedMilestoneIds;
  late List<SolutionMasteryEntry> _solutionEntries;
  bool _newSolutionStamp = false;
  bool _successAimGhostActive = false;

  RunRewardInventory get _rewardInventory =>
      RunRewardInventory(_acquiredRewards);
  late TutorialExperimentVariant _activeTutorialVariant;
  final List<PhysicsEvent> _debugPhysicsEvents = [];
  bool _debugShowHitboxes = false;
  bool _debugShowNormals = false;
  bool _debugShowIds = false;
  bool _debugShowStats = false;
  bool _debugRecordReplay = false;
  GameState? _debugReplayStartState;
  ShotInput? _debugReplayInput;
  IntentAssistDecision? _pendingIntentAssistDecision;
  int _repeatedNearMisses = 0;
  String? _lastNearMissTargetId;
  List<ShotResult> _debugReplayPriorShotResults = const [];
  bool _debugReplayPriorBumperHit = false;
  bool _debugReplayPriorSwitchPressed = false;
  bool _debugReplayPriorDrainedSourceMoved = false;
  List<bool> _debugReplayPriorBumperHistory = const [];
  List<bool> _debugReplayPriorSwitchHistory = const [];
  List<bool> _debugReplayPriorDrainedHistory = const [];

  double get _lastDebugSpeed {
    for (final event in _debugPhysicsEvents.reversed) {
      if (event.kind == PhysicsEventKind.impact) {
        return event.resultingVelocity.length;
      }
    }
    return 0;
  }

  String? get _lastDebugCollisionId {
    for (final event in _debugPhysicsEvents.reversed) {
      if (event.kind == PhysicsEventKind.impact) {
        return event.eventId;
      }
    }
    return null;
  }

  String _currentBallTelemetryId() {
    final active = _state.entityById('active_ball');
    if (active != null) {
      return active.id;
    }
    for (final entity in _state.entities.reversed) {
      if (entity.type == EntityType.ball) {
        return entity.id;
      }
    }
    return 'active_ball';
  }

  @override
  void initState() {
    super.initState();
    _framePerformance.start();
    _progressStore =
        widget.progressStore ??
        ProgressStore(
          stageCount: levels.length,
          stageIds: levels.map((level) => level.id),
        );
    WidgetsBinding.instance.addObserver(this);
    _telemetry = widget.telemetry ?? LocalPlayTelemetry();
    _difficulty = widget.difficulty ?? GameFeedback.playerDifficulty;
    final configuredAssist =
        widget.intentAssistStrength ?? GameFeedback.intentAssistStrength;
    _intentAssistStrength = effectiveIntentAssistStrength(
      configured: configuredAssist,
      difficulty: _difficulty,
      acquiredRewards: widget.initialAcquiredRewards,
    );
    _state =
        widget.initialState ??
        levels.first
            .createState(0, productRules: true)
            .copyWith(message: _levelIntroMessage(0));
    _currentLevel = widget.levelOverride ?? levels[_state.levelIndex];
    _stageShotResults = List.of(widget.initialShotResults);
    _stageShotInputs = List.of(widget.initialShotInputs);
    if (_stageShotInputs.isNotEmpty &&
        _stageShotResults.length != _stageShotInputs.length) {
      throw ArgumentError(
        '복원된 발사 결과와 입력 수가 일치해야 합니다: '
        '${_stageShotResults.length}/${_stageShotInputs.length}',
      );
    }
    _rewardCandidates = List.of(widget.initialRewardCandidates);
    _selectedRewardId = widget.initialSelectedRewardId;
    _acquiredRewards = Set.of(widget.initialAcquiredRewards);
    _patternHintEntry = widget.patternHintEntry;
    _hintEntitlement = widget.initialHintEntitlement;
    _collectedHintKeyIds = Set.of(widget.initialCollectedHintKeyIds);
    _solutionEntries = List.of(widget.initialSolutionEntries);
    _persistedMilestoneIds = Set.of(widget.initialDiscoveredMilestoneIds);
    _discoveredMilestoneIds.addAll(_persistedMilestoneIds);
    _captureDiscoveries(_state);
    _restoreStageOutcomeHistory();
    _chainScoreAnalysis = _analyzeSuccessfulStage(
      state: _state,
      shotResults: _stageShotResults,
      parShots: _currentLevel.parShots,
    );
    _stageCopyCoreAtStart = _state.copyCoreCount;
    _activeTutorialVariant = widget.tutorialVariant;
    _telemetry.sessionStart(
      stage: _state.levelIndex,
      experimentVariant: widget.tutorialVariant.code,
    );
    if (widget.initialState != null) {
      _unlockedLevel = levels.length - 1;
    }
    _game = PropertyShotGame(
      _state,
      onAnimationFinished: _onAnimationFinished,
      onAnimationImpact: _onAnimationImpact,
      onShotImpact: _onShotImpact,
      onPhysicsEvent: _onPhysicsEvent,
      loadVisualAssets: widget.loadGameAssets,
      reducedMotion: GameFeedback.reducedMotionEnabled,
      screenShake: GameFeedback.screenShakeEnabled,
      screenShakeStrength: GameFeedback.screenShakeStrength,
      strongFlash: GameFeedback.strongFlashEnabled,
      ballRewardAppearance: _rewardInventory.ballAppearanceEnabled,
    );
    _game.setDebugOptions(
      hitboxes: _debugShowHitboxes,
      normals: _debugShowNormals,
      ids: _debugShowIds,
      stats: _debugShowStats,
    );
    if (_solutionEntries.isNotEmpty &&
        _stageShotInputs.isEmpty &&
        GameFeedback.previousAimComparisonEnabled) {
      final ghost = _solutionEntries.last;
      _successAimGhostActive = true;
      _setPreviousAimInput(
        ShotInput(
          direction: Vec2(ghost.firstDirectionX, ghost.firstDirectionY),
          power: ghost.firstPower,
        ).normalized(),
      );
    }
    _showClearPopup = _state.phase == GamePhase.success;
    _bestShotsLoadFuture = _loadBestShots();
    _telemetry.record('단계 시작', stage: _state.levelIndex);
    _recordTyped(PlayTelemetryEventType.stageEntered);
    _recordPassiveRewardActivations();
    _recordKeySpawnIfNeeded();
    _recordHintAvailableIfNeeded();
    _recordHintExposureIfNeeded();
    unawaited(_showRequestedHelp());
  }

  PlayTelemetryContext _telemetryContext() {
    final supplied = widget.telemetryContextBuilder?.call();
    if (supplied != null) {
      return supplied.copyWith(
        difficulty: _difficulty == PlayerDifficulty.easy
            ? PlayTelemetryDifficulty.easy
            : PlayTelemetryDifficulty.normal,
      );
    }
    return PlayTelemetryContext(
      stageIndex: _state.levelIndex,
      stageId: _currentLevel.stageId ?? _currentLevel.id,
      patternId: _currentLevel.patternId ?? '${_currentLevel.id}_default',
      seed: 0,
      resolverVersion: 'shot-resolver-v1',
      difficulty: _difficulty == PlayerDifficulty.easy
          ? PlayTelemetryDifficulty.easy
          : PlayTelemetryDifficulty.normal,
      rewardState: PlayTelemetryRewardState(
        candidateIds: _rewardCandidates.map((reward) => reward.id),
        selectedId: _selectedRewardId,
        acquiredIds: _acquiredRewards,
        cloneCoreCount: _state.copyCoreCount,
      ),
    );
  }

  void _recordTyped(
    PlayTelemetryEventType type, {
    PlayTelemetryShotPayload? shot,
    PlayTelemetryResult? result,
    PlayTelemetryHintPayload? hint,
    PlayTelemetryKeyPayload? key,
    PlayTelemetryStageOutcomePayload? stageOutcome,
    PlayTelemetryPowerGaugePayload? powerGauge,
    PlayTelemetryRewardUsePayload? rewardUse,
  }) {
    _telemetry.recordTyped(
      TypedPlayTelemetryEvent(
        type: type,
        context: _telemetryContext(),
        shot: shot,
        result: result,
        hint: hint,
        key: key,
        stageOutcome: stageOutcome,
        powerGauge: powerGauge,
        rewardUse: rewardUse,
      ),
    );
  }

  RunRewardSelectionRecord? _rewardUseSelection(
    String rewardId, {
    required String useKey,
    required bool stageScoped,
  }) => stageScoped
      ? _rewardInventory.availableSelectionForStage(rewardId, useKey)
      : _rewardInventory.availableSelections(rewardId).firstOrNull;

  int? _rewardStageDistance(RunRewardSelectionRecord? selection) {
    if (selection == null) return null;
    final selectedAt = levels.indexWhere(
      (level) => level.id == selection.stageId,
    );
    if (selectedAt < 0) return null;
    return math.max(0, _state.levelIndex - selectedAt).toInt();
  }

  void _recordRewardUse({
    required String rewardId,
    required String useKey,
    required bool stageScoped,
    required PlayTelemetryRewardTrigger trigger,
    RunRewardSelectionRecord? selection,
  }) {
    _recordTyped(
      PlayTelemetryEventType.rewardUsed,
      result: PlayTelemetryResult.continued,
      rewardUse: PlayTelemetryRewardUsePayload(
        rewardId: rewardId,
        useKey: useKey,
        trigger: trigger,
        stageScoped: stageScoped,
        selectionRecordId: selection?.recordId,
        stageDistance: _rewardStageDistance(selection),
      ),
    );
    if (trigger != PlayTelemetryRewardTrigger.passive) {
      _showRewardUseRecap(rewardId);
    }
  }

  void _showRewardUseRecap(String rewardId) {
    if (!mounted) return;
    final reward = initialRunRewards
        .where((item) => item.id == rewardId)
        .firstOrNull;
    if (reward == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          content: Semantics(
            liveRegion: true,
            label: '보상 사용 결과. ${reward.effectRecap}',
            child: Text(
              '보상 적용 · ${reward.effectRecap}',
              key: const Key('reward_use_recap'),
            ),
          ),
        ),
      );
  }

  void _recordPassiveRewardActivations() {
    final seen = <String>{};
    for (final selection in _rewardInventory.selections) {
      if (!seen.add(selection.rewardId)) continue;
      final reward = initialRunRewards
          .where((item) => item.id == selection.rewardId)
          .firstOrNull;
      if (reward?.activationKind != RunRewardActivationKind.passive) continue;
      _recordRewardUse(
        rewardId: selection.rewardId,
        useKey:
            '${_currentLevel.id}:${_currentLevel.patternId ?? 'default'}:passive',
        stageScoped: true,
        trigger: PlayTelemetryRewardTrigger.passive,
        selection: selection,
      );
    }
  }

  String? get _stageRewardGuide {
    const priority = [
      runRewardFirstImpactGuideId,
      runRewardShotCancelAssistId,
      runRewardSpentBallRecoveryId,
      runRewardPrecisionChargeId,
      runRewardFailureCauseBoostId,
      runRewardOptionalChallengeGuardId,
      runRewardStageRecordGuardId,
      runRewardBallAppearanceId,
    ];
    for (final rewardId in priority) {
      final reward = initialRunRewards
          .where((item) => item.id == rewardId)
          .firstOrNull;
      final owned = switch (rewardId) {
        runRewardFailureCauseBoostId =>
          _rewardInventory.failureCauseBoostEnabled,
        runRewardPrecisionChargeId => _rewardInventory.precisionChargeEnabled,
        _ => _rewardInventory.has(rewardId),
      };
      if (reward == null || !owned) continue;
      final available = switch (reward.activationKind) {
        RunRewardActivationKind.manual || RunRewardActivationKind.automatic =>
          rewardId == runRewardStageRecordGuardId
              ? _rewardInventory.canUseForStage(rewardId, _currentLevel.id)
              : _rewardInventory.availableUseCount(rewardId) > 0,
        RunRewardActivationKind.passive => true,
        RunRewardActivationKind.immediate => false,
      };
      if (available) return '${reward.name} · ${reward.stageGuide}';
    }
    return null;
  }

  HintKeyDefinition? get _currentHintKey => _patternHintEntry?.key;

  bool get _hintAvailable => _hintEntitlement != null;

  PlayTelemetryHintSource _hintSourceFor(RunHintEntitlement entitlement) =>
      entitlement.sources.contains(HintEntitlementSource.stageKey)
      ? PlayTelemetryHintSource.stageKey
      : entitlement.sources.contains(HintEntitlementSource.clearReward)
      ? PlayTelemetryHintSource.clearReward
      : entitlement.sources.contains(
          HintEntitlementSource.restorationLighthouse,
        )
      ? PlayTelemetryHintSource.restorationLighthouse
      : PlayTelemetryHintSource.failureAssist;

  PlayTelemetryHintLevel _hintLevelFor(int level) => switch (level) {
    1 => PlayTelemetryHintLevel.one,
    2 => PlayTelemetryHintLevel.two,
    _ => throw StateError('현재 HintCatalog에는 L1/L2만 존재합니다: $level'),
  };

  PlayTelemetryHintPayload _hintTelemetryPayload(
    RunHintEntitlement entitlement, {
    required int level,
    bool clearedAfterOpen = false,
  }) => PlayTelemetryHintPayload(
    source: _hintSourceFor(entitlement),
    level: _hintLevelFor(level),
    openedCount: entitlement.openedCount,
    failureCountBeforeOpen:
        entitlement.failureCountAtFirstOpen ?? entitlement.failedShotCount,
    clearedAfterOpen: clearedAfterOpen,
  );

  void _recordKeySpawnIfNeeded() {
    final key = _currentHintKey;
    if (key == null ||
        _collectedHintKeyIds.contains(key.id) ||
        _keySpawnRecorded) {
      return;
    }
    _keySpawnRecorded = true;
    _recordTyped(
      PlayTelemetryEventType.keySpawned,
      key: PlayTelemetryKeyPayload(
        keyId: key.id,
        shotId: _state.shotCount,
        collected: false,
      ),
    );
  }

  void _recordHintAvailableIfNeeded() {
    final entitlement = _hintEntitlement;
    if (entitlement == null || _hintAvailableRecorded) return;
    _hintAvailableRecorded = true;
    _recordTyped(
      PlayTelemetryEventType.hintAvailable,
      hint: _hintTelemetryPayload(
        entitlement,
        level: entitlement.unlockedHintLevel,
      ),
    );
  }

  Future<void> _recordHintFailureIfEligible(ShotResult result) async {
    if (result.state.phase == GamePhase.success ||
        widget.onHintFailure == null) {
      return;
    }
    try {
      final updated = await widget.onHintFailure!.call();
      if (updated != null && mounted) {
        setState(() => _hintEntitlement = updated);
        _recordHintAvailableIfNeeded();
        _refreshAssistRecommendation();
      }
    } on Object {
      // 힌트의 실패 횟수 기록은 플레이 결과를 되돌리지 않는다.
    }
  }

  void _refreshAssistRecommendation() {
    if (!mounted || !_showFailurePopup) return;
    final failures = _stageShotResults
        .where((result) => result.state.phase != GamePhase.success)
        .toList(growable: false);
    final entitlement = _hintEntitlement;
    final next = const AssistRecommendationEngine().recommend(
      AssistRecommendationContext(
        failureCount: failures.length,
        latestResult: failures.lastOrNull,
        hintAvailable: entitlement != null,
        hintConsumed: entitlement?.consumed ?? false,
        hintLevel: entitlement?.unlockedHintLevel ?? 0,
        hintOpenedCount: entitlement?.openedCount ?? 0,
        previousAimEnabled: GameFeedback.previousAimComparisonEnabled,
        collisionOrderEnabled: GameFeedback.collisionOrderEnabled,
        causalityEnabled: GameFeedback.gimmickCausalityEnabled,
      ),
      handledIds: _handledAssistRecommendationIds,
    );
    if (next?.id == _assistRecommendation?.id) return;
    setState(() => _assistRecommendation = next);
    if (next != null) {
      _telemetry.record(
        '도움 추천 표시',
        stage: _state.levelIndex,
        attempt: _state.shotCount,
        eventCode: 'assist_recommendation_presented',
        action: next.id,
      );
    }
  }

  Future<void> _acceptAssistRecommendation() async {
    final recommendation = _assistRecommendation;
    if (recommendation == null) return;
    _handledAssistRecommendationIds.add(recommendation.id);
    _telemetry.record(
      '도움 추천 수락',
      stage: _state.levelIndex,
      attempt: _state.shotCount,
      eventCode: 'assist_recommendation_accepted',
      action: recommendation.id,
    );
    if (recommendation.action == AssistRecommendationAction.openHint) {
      setState(() {
        _showFailurePopup = false;
        _assistRecommendation = null;
      });
      await _showPatternHintSheet();
      return;
    }
    switch (recommendation.action) {
      case AssistRecommendationAction.enablePreviousAim:
        await GameFeedback.setPreviousAimComparisonEnabled(true);
      case AssistRecommendationAction.enableCollisionOrder:
        await GameFeedback.setCollisionOrderEnabled(true);
      case AssistRecommendationAction.enableCausality:
        await GameFeedback.setGimmickCausalityEnabled(true);
      case AssistRecommendationAction.openHint:
        break;
    }
    if (!mounted) return;
    setState(() {
      _assistRecommendation = null;
      _assistRecommendationFeedback = '${recommendation.title} 도움을 켰어요.';
    });
  }

  void _dismissAssistRecommendation() {
    final recommendation = _assistRecommendation;
    if (recommendation == null) return;
    _handledAssistRecommendationIds.add(recommendation.id);
    _telemetry.record(
      '도움 추천 건너뜀',
      stage: _state.levelIndex,
      attempt: _state.shotCount,
      eventCode: 'assist_recommendation_dismissed',
      action: recommendation.id,
    );
    setState(() => _assistRecommendation = null);
  }

  bool _isDirectClear(Iterable<ShotResult> results) {
    final all = results.toList(growable: false);
    if (all.length != 1) return false;
    final result = all.single;
    // "직선 즉시"는 첫/유일 샷이 홀만 접촉해 끝난 경우로 보수적으로
    // 정의한다. 벽·기물·속성 충돌이 하나라도 있으면 기믹 경로다.
    final usedTrait =
        _stageShotInputs.length == 1 &&
        _stageShotInputs.single.equippedTrait != null;
    final emittedOnlyHole = result.events.every(
      (event) => event == 'hole_entered',
    );
    final physicsTraits =
        result.impacts.any((impact) => impact.sourceTraits.isNotEmpty) ||
        result.physicsEvents.any((event) => event.sourceTraits.isNotEmpty);
    return !usedTrait &&
        !physicsTraits &&
        emittedOnlyHole &&
        result.powerSliderActivations.isEmpty &&
        result.reflectorRotations.isEmpty &&
        result.state.phase == GamePhase.success &&
        result.impacts.isNotEmpty &&
        result.impacts.every((impact) => impact.entityType == EntityType.hole);
  }

  Set<String> get _stageGimmickTypes {
    final types = <String>{};
    for (final input in _stageShotInputs) {
      final trait = input.equippedTrait;
      if (trait != null) types.add(trait.name);
    }
    for (final result in _stageShotResults) {
      for (final impact in result.impacts) {
        if (impact.entityType != EntityType.hole) {
          types.add(impact.entityType.name);
        }
        types.addAll(impact.sourceTraits.map((trait) => trait.name));
        if (impact.entityType == EntityType.wall) {
          types.add('wall_reflection');
        }
      }
      for (final event in result.physicsEvents) {
        types.addAll(event.sourceTraits.map((trait) => trait.name));
        if (event.kind == PhysicsEventKind.powerSliderActivation) {
          types.add('power_slider');
        }
        if (event.targetType == EntityType.wall) {
          types.add('wall_reflection');
        }
      }
      if (result.powerSliderActivations.isNotEmpty) {
        types.add('power_slider');
      }
      if (result.reflectorRotations.isNotEmpty) {
        types.add('rotating_reflector');
      }
      for (final event in result.events) {
        if (event == 'hole_entered') continue;
        types.add(event);
        if (event == 'bounced' || event == 'spent_ball_bounced') {
          types.add('wall_reflection');
        }
        if (event == 'jelly_bounced') types.add('bouncy');
      }
    }
    return types;
  }

  List<StageDiscoveryMilestone> get _discoveryMilestones {
    final current = stageDiscoveryMilestones(
      state: _state,
      shotInputs: _stageShotInputs,
      shotResults: _stageShotResults,
    );
    return [
      for (final milestone in current)
        StageDiscoveryMilestone(
          id: milestone.id,
          label: milestone.label,
          achieved:
              milestone.achieved ||
              _discoveredMilestoneIds.contains(milestone.id),
        ),
    ];
  }

  void _captureDiscoveries(GameState state) {
    final milestones = stageDiscoveryMilestones(
      state: state,
      shotInputs: _stageShotInputs,
      shotResults: _stageShotResults,
    );
    final achievedIds = milestones
        .where((item) => item.achieved)
        .map((item) => item.id)
        .toSet();
    final changed = achievedIds.difference(_discoveredMilestoneIds).isNotEmpty;
    if (changed) _feedback.discoveryMilestone();
    _discoveredMilestoneIds.addAll(achievedIds);
  }

  Future<bool> _persistDiscoveriesAfterClear() async {
    if (_state.phase != GamePhase.success) return true;
    if (widget.progressPersistencePolicy ==
        GameProgressPersistencePolicy.disabled) {
      return true;
    }
    final pending = _discoveredMilestoneIds.difference(_persistedMilestoneIds);
    if (pending.isEmpty) return true;
    try {
      final writer = widget.onDiscoveriesRecorded;
      final stored = writer == null
          ? await (() async {
              await _progressStore.recordDiscoveries(
                _state.levelIndex,
                pending,
              );
              return true;
            })()
          : await writer(Set<String>.unmodifiable(pending));
      if (stored) _persistedMilestoneIds.addAll(pending);
      return stored;
    } on Object {
      return false;
    }
  }

  PlayTelemetryStageOutcomePayload _stageOutcomePayload() {
    final entitlement = _hintEntitlement;
    final currentFailures = entitlement?.failedShotCount ?? 0;
    final failureBaseline = entitlement?.consumed == true
        ? entitlement!.failureCountAtFirstOpen ?? currentFailures
        : 0;
    return PlayTelemetryStageOutcomePayload(
      keyCollected:
          _currentHintKey != null &&
          _collectedHintKeyIds.contains(_currentHintKey!.id),
      directClear: _isDirectClear(_stageShotResults),
      hintUsedBeforeClear: entitlement?.consumed ?? false,
      failureCountBeforeHint: failureBaseline,
      failureCountAfterHint: entitlement?.consumed == true
          ? math.max(0, currentFailures - failureBaseline).toInt()
          : 0,
      effectiveChainScore: _chainScoreAnalysis?.totalScore ?? 0,
      gimmickTypes: _stageGimmickTypes,
    );
  }

  Future<void> _recordCollectedKeys({
    required GameState stateBeforeShot,
    required ShotResult result,
  }) async {
    final key = _currentHintKey;
    final onCollected = widget.onHintKeyCollected;
    if (key == null ||
        onCollected == null ||
        _collectedHintKeyIds.contains(key.id)) {
      return;
    }
    final events = const DeterministicKeyCollectionResolver().collect(
      stateBeforeShot: stateBeforeShot,
      result: result,
      keys: [key],
    );
    for (final event in events) {
      if (_collectedHintKeyIds.contains(event.keyId)) continue;
      bool stored;
      try {
        stored = await onCollected(
          event.keyId,
          event.sourceBallId,
          stateBeforeShot.shotCount,
        );
      } on Object {
        continue;
      }
      if (!stored || !mounted) continue;
      final updated = <String>{..._collectedHintKeyIds, event.keyId};
      setState(() {
        _collectedHintKeyIds = updated;
        _keyCollectionVfxId = event.keyId;
      });
      _keyCollectionVfxTimer?.cancel();
      _keyCollectionVfxTimer = Timer(const Duration(milliseconds: 620), () {
        if (mounted && _keyCollectionVfxId == event.keyId) {
          setState(() => _keyCollectionVfxId = null);
        }
      });
      // Session callback writes entitlement before this point; UI/VFX is only
      // acknowledged once durable state has accepted the non-physical event.
      final entitlement = await _hintEntitlementAfterKeyStored();
      if (!mounted) return;
      setState(() => _hintEntitlement = entitlement ?? _hintEntitlement);
      _recordTyped(
        PlayTelemetryEventType.keyCollected,
        key: PlayTelemetryKeyPayload(
          keyId: event.keyId,
          shotId: stateBeforeShot.shotCount + 1,
          collected: true,
          shotsUntilCollected: stateBeforeShot.shotCount + 1,
        ),
      );
      if (entitlement != null) {
        _recordHintAvailableIfNeeded();
      }
    }
  }

  /// The key save callback intentionally remains bool-shaped so existing
  /// RunState serialization is the source of truth. The UI receives the
  /// durable entitlement through this optional read callback in campaign mode.
  Future<RunHintEntitlement?> _hintEntitlementAfterKeyStored() async {
    final read = widget.onHintEntitlementRead;
    if (read != null) return read();
    return _hintEntitlement;
  }

  Future<void> _showPatternHintSheet() async {
    final entry = _patternHintEntry;
    final openHint = widget.onHintOpened;
    if (entry == null || openHint == null || _hintEntitlement == null) return;
    RunHintEntitlement? entitlement;
    try {
      entitlement = await openHint();
    } on Object {
      return;
    }
    if (entitlement == null || !mounted) return;
    setState(() => _hintEntitlement = entitlement);
    _recordTyped(
      PlayTelemetryEventType.hintOpened,
      hint: _hintTelemetryPayload(entitlement, level: 1),
    );
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 500),
          child: _PatternHintSheet(
            entry: entry,
            entitlement: entitlement!,
            onMore: (currentLevel) async {
              final updated = await openHint(requestedLevel: currentLevel + 1);
              if (updated == null) return null;
              if (mounted) setState(() => _hintEntitlement = updated);
              _recordTyped(
                PlayTelemetryEventType.hintLevelOpened,
                hint: _hintTelemetryPayload(
                  updated,
                  level: updated.unlockedHintLevel,
                ),
              );
              return updated;
            },
          ),
        ),
      ),
    );
  }

  PlayTelemetryShotPayload _typedShotPayload({
    required ShotInput input,
    required ShotResult result,
    required GameState startState,
    required double inputLatencyMs,
  }) {
    final impacts = result.impacts;
    final distinctTypes = impacts.map((impact) => impact.entityType).toSet();
    final distinctObjects = impacts.map((impact) => impact.entityId).toSet();
    final holePositions = startState.entities
        .where((entity) => entity.type == EntityType.hole)
        .map((entity) => entity.position)
        .toList(growable: false);
    var nearestHoleDistance = double.maxFinite;
    for (final point in result.path) {
      for (final hole in holePositions) {
        nearestHoleDistance = math.min(
          nearestHoleDistance,
          point.distanceTo(hole),
        );
      }
    }
    if (nearestHoleDistance == double.maxFinite) nearestHoleDistance = 0;
    final score = _chainScoreAnalysis;
    return PlayTelemetryShotPayload(
      shotId: startState.shotCount + 1,
      angle: math.atan2(input.direction.y, input.direction.x),
      power: input.power,
      ballTraits: input.equippedTrait == null
          ? const []
          : [input.equippedTrait!.name],
      causalChain: [
        for (var index = 0; index < impacts.length; index++)
          impacts[index].contactId ?? '${impacts[index].entityId}:$index',
      ],
      causalDepth: impacts.length,
      effectiveChainLength: score?.causalEventIds.length ?? impacts.length,
      distinctObjectTypeCount: distinctTypes.length,
      distinctObjectCount: distinctObjects.length,
      wallUseCount: impacts
          .where((impact) => impact.entityType == EntityType.wall)
          .length,
      ballUseCount: impacts
          .where((impact) => impact.entityType == EntityType.ball)
          .length,
      objectUseCount: impacts
          .where(
            (impact) =>
                impact.entityType != EntityType.wall &&
                impact.entityType != EntityType.ball &&
                impact.entityType != EntityType.hole,
          )
          .length,
      scoreDamped: (score?.breakdown.dampedImpactCount ?? 0) > 0,
      nearestHoleDistance: nearestHoleDistance,
      frameDurationMs: _framePerformance.latestProcessingDurationMilliseconds,
      inputLatencyMs: inputLatencyMs,
      rawAngle: input.rawDirection == null
          ? null
          : math.atan2(input.rawDirection!.y, input.rawDirection!.x),
      rawPower: input.rawPower,
      assistKind: input.wasAssisted ? input.assistKind.name : null,
      assistTargetId: input.assistTargetId,
      holeForgivenessRadius: input.holeForgivenessRadius,
      result: result.state.phase == GamePhase.success
          ? PlayTelemetryResult.cleared
          : PlayTelemetryResult.continued,
    );
  }

  Future<void> _showRequestedHelp() async {
    final requested = await GameFeedback.consumeHelpReplayRequest();
    if (!requested || !mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('game_help_dialog'),
        title: const Text('게임 도움말'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _currentLevel.name,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_state.message),
              const SizedBox(height: 12),
              const Text('방향을 정한 뒤 공을 길게 눌러 힘을 모으면 자동으로 발사됩니다.'),
              const SizedBox(height: 8),
              const Text('공이나 물체를 누르면 속성과 현재 상태를 확인할 수 있습니다.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            key: const Key('game_help_close_button'),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant GameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!setEquals(
      oldWidget.initialAcquiredRewards,
      widget.initialAcquiredRewards,
    )) {
      _acquiredRewards = Set.of(widget.initialAcquiredRewards);
      _game.setBallRewardAppearance(_rewardInventory.ballAppearanceEnabled);
    }
    if (!listEquals(
      oldWidget.initialRewardCandidates,
      widget.initialRewardCandidates,
    )) {
      _rewardCandidates = List.of(widget.initialRewardCandidates);
    }
    if (oldWidget.initialSelectedRewardId != widget.initialSelectedRewardId) {
      _selectedRewardId = widget.initialSelectedRewardId;
    }
  }

  void _restoreStageOutcomeHistory() {
    for (final result in _stageShotResults) {
      _bonusBumperHistory.insert(0, _bonusBumperHit);
      _bonusSwitchHistory.insert(0, _bonusSwitchPressed);
      _bonusDrainedSourceHistory.insert(0, _bonusDrainedSourceMoved);
      _bonusBumperHit =
          _bonusBumperHit ||
          result.impacts.any(
            (impact) => impact.entityType == EntityType.bumper,
          );
      _bonusSwitchPressed =
          _bonusSwitchPressed || result.events.contains('switch_pressed');
      final beforeShot = result.state.history.isEmpty
          ? null
          : result.state.history.first;
      final drainedSourceIds = beforeShot?.entities
          .where((entity) => entity.visualState == 'drained')
          .map((entity) => entity.id)
          .toSet();
      _bonusDrainedSourceMoved =
          _bonusDrainedSourceMoved ||
          (drainedSourceIds != null &&
              result.moves.any(
                (move) =>
                    drainedSourceIds.contains(move.entityId) &&
                    move.from != move.to,
              ));
    }
  }

  Future<void> _loadBestShots() async {
    if (widget.progressPersistencePolicy ==
        GameProgressPersistencePolicy.disabled) {
      _bestShotsLoaded = true;
      return;
    }
    try {
      final progress = await _progressStore.load();
      if (!mounted) {
        return;
      }
      final loaded = progress.bestShots;
      final loadedBonusGoals = <int, bool>{
        for (final index in progress.bonusGoals) index: true,
      };
      _unlockedLevel = math.max(_unlockedLevel, progress.unlockedLevel).toInt();
      setState(
        () => _bestShots
          ..clear()
          ..addAll(loaded),
      );
      _bonusGoals
        ..clear()
        ..addAll(loadedBonusGoals);
      _bonusChallengeAchieved = _bonusGoals[_state.levelIndex] ?? false;
    } on Object {
      // 클리어 시 실제 기록 저장을 다시 시도할 수 있도록 초기 로드는 안전하게 끝낸다.
    } finally {
      _bestShotsLoaded = true;
    }
  }

  Future<void> _recordBonusGoal(int levelIndex) async {
    if (widget.progressPersistencePolicy ==
            GameProgressPersistencePolicy.disabled ||
        _difficulty == PlayerDifficulty.easy) {
      return;
    }
    if (_bonusGoals[levelIndex] == true) {
      return;
    }
    await _progressStore.recordBonusGoal(levelIndex);
    if (!mounted) return;
    _bonusGoals[levelIndex] = true;
    setState(() => _bonusChallengeAchieved = true);
  }

  Future<void> _recordBestShot(int levelIndex, int shotCount) async {
    if (widget.progressPersistencePolicy ==
            GameProgressPersistencePolicy.disabled ||
        _difficulty == PlayerDifficulty.easy) {
      return;
    }
    if (!_bestShotsLoaded) {
      _bestShotsLoadFuture ??= _loadBestShots();
      await _bestShotsLoadFuture;
      if (!mounted) {
        return;
      }
    }
    final current = _bestShots[levelIndex];
    if (current != null && current <= shotCount) {
      return;
    }
    await _progressStore.recordBestShot(levelIndex, shotCount);
    if (!mounted) return;
    setState(() => _bestShots[levelIndex] = shotCount);
  }

  Future<void> _unlockNextLevel(int levelIndex) async {
    if (widget.progressPersistencePolicy ==
        GameProgressPersistencePolicy.disabled) {
      return;
    }
    final next = math.min(levels.length - 1, levelIndex + 1);
    await _progressStore.recordStageClear(levelIndex);
    if (next > _unlockedLevel && mounted) {
      setState(() => _unlockedLevel = next);
    }
  }

  void _setState(
    GameState next, {
    List<Vec2> path = const [],
    GameState? transitionStart,
    List<ShotAnimationMove> moves = const [],
    List<ShotImpact> impacts = const [],
    List<PhysicsEvent> physicsEvents = const [],
  }) {
    setState(() {
      _state = next;
      if (next.phase != GamePhase.success) {
        _showClearPopup = false;
      }
      _game.setStateSnapshot(
        next,
        path: path,
        transitionStart: transitionStart,
        moves: moves,
        impacts: impacts,
        physicsEvents: physicsEvents,
        animationTransaction: path.isNotEmpty,
      );
      _syncFirstArrivalPreview();
    });
    _recordHintExposureIfNeeded();
  }

  void _setPreviousAimInput(ShotInput? input, {Iterable<Vec2>? path}) {
    _previousAimInput = input;
    _game.setPreviousAimInput(input);
    _game.setPreviousShotPath(input == null ? const [] : path ?? const []);
  }

  void _selectLevel(int index) {
    if (_isAnimatingShot || index > _unlockedLevel) {
      return;
    }
    final sameStage = index == _state.levelIndex;
    _showBallInfo = false;
    _inspectedEntityId = null;
    _showClearPopup = false;
    _showFailurePopup = false;
    _semanticAnimationStartState = null;
    _failureReplay = null;
    _lastFailureCauseKey = null;
    _repeatedFailureCauseCount = 0;
    _successAimGhostActive = false;
    _setPreviousAimInput(null);
    _aimStartedForShot = false;
    _pendingLaunchDirection = null;
    _showClearPersistenceError = false;
    _clearPersistenceErrorTitle = '클리어 기록을 저장하지 못했습니다';
    _clearPersistenceErrorBody = '기록 저장이 끝나야 보상과 다음 단계로 이동할 수 있습니다.';
    _resetChargeGauge();
    _bonusBumperHit = false;
    _bonusSwitchPressed = false;
    _bonusDrainedSourceMoved = false;
    _bonusBumperHistory.clear();
    _bonusSwitchHistory.clear();
    _bonusDrainedSourceHistory.clear();
    _stageShotResults.clear();
    _stageShotInputs.clear();
    if (!sameStage) {
      _discoveredMilestoneIds.clear();
      _persistedMilestoneIds.clear();
    }
    _chainScoreAnalysis = null;
    _clearPersistenceFuture = null;
    _clearPersistenceRetry = null;
    _bonusChallengeAchieved = _bonusGoals[index] ?? false;
    _rewardCandidates = const [];
    _selectedRewardId = null;
    _rewardSelectionError = null;
    _guidedImpactLabel = null;
    _traitEffectFeedback = null;
    _traitTransferFeedbackTimer?.cancel();
    _traitTransferFeedback = null;
    _challengeGuardAppliedForClear = false;
    _recordGuardAppliedForClear = false;
    if (sameStage && _state.shotCount > 0) {
      _telemetry.record(
        '재시도',
        stage: _state.levelIndex,
        attempt: _state.shotCount + 1,
        result: '단계 다시 시작',
        eventCode: 'retry_pressed',
      );
      _recordTyped(
        PlayTelemetryEventType.stageRetried,
        result: PlayTelemetryResult.continued,
      );
    }
    final availableCores = sameStage
        ? _stageCopyCoreAtStart
        : _state.copyCoreCount;
    final selectedLevel =
        index == _state.levelIndex && widget.levelOverride != null
        ? widget.levelOverride!
        : levels[index];
    _currentLevel = selectedLevel;
    final next = selectedLevel
        .createState(
          index,
          productRules: !widget.showStageSelector,
          copyCoreCount: availableCores,
          copyCoreRewarded: _state.copyCoreRewarded,
        )
        .copyWith(message: _levelIntroMessage(index));
    _stageCopyCoreAtStart = next.copyCoreCount;
    _setState(next);
    _telemetry.record('단계 시작', stage: index);
  }

  Future<void> _goNextLevel() async {
    if (_isCommittingStageAction) return;
    _isCommittingStageAction = true;
    try {
      final persisted = await (_clearPersistenceFuture ?? Future.value(true));
      if (!persisted || !mounted) return;
      _telemetry.record(
        '단계 종료',
        stage: _state.levelIndex,
        result: '다음 단계 선택',
        eventCode: 'stage_exit',
      );
      final sequenceFinished =
          widget.sequencePosition != null &&
          widget.sequenceLength != null &&
          widget.sequencePosition! >= widget.sequenceLength! - 1;
      if (sequenceFinished && widget.onRunCompleted != null) {
        _recordTyped(
          PlayTelemetryEventType.runCompleted,
          result: PlayTelemetryResult.cleared,
        );
        await widget.onRunCompleted!();
        return;
      }
      if (_state.levelIndex >= levels.length - 1) {
        if (widget.onRunCompleted != null) {
          _recordTyped(
            PlayTelemetryEventType.runCompleted,
            result: PlayTelemetryResult.cleared,
          );
          await widget.onRunCompleted!();
          return;
        }
        if (widget.onStageRequested != null) {
          await widget.onStageRequested!(0);
          return;
        }
        _selectLevel(0);
        _setState(_state.copyWith(message: '모든 단계를 완료했습니다. 기록을 다시 도전하세요.'));
        return;
      }
      if (widget.onStageRequested != null) {
        await widget.onStageRequested!(_state.levelIndex + 1);
        return;
      }
      await _unlockNextLevel(_state.levelIndex);
      _selectLevel(_state.levelIndex + 1);
    } on Object {
      if (mounted) {
        _setState(
          _state.copyWith(message: '다음 단계 기록을 저장하지 못했습니다. 다시 시도해 주세요.'),
        );
      }
    } finally {
      _isCommittingStageAction = false;
    }
  }

  Future<void> _selectRunReward(String rewardId) async {
    if (_isSelectingReward ||
        _selectedRewardId != null ||
        _isCommittingStageAction) {
      return;
    }
    setState(() {
      _isSelectingReward = true;
      _rewardSelectionError = null;
    });
    try {
      final fallback = _rewardCandidates.firstWhere(
        (reward) => reward.id == rewardId,
      );
      final selected =
          await widget.onRewardSelected?.call(rewardId) ?? fallback;
      if (!mounted) return;
      setState(() {
        _selectedRewardId = selected.id;
        _isSelectingReward = false;
        // 저장 콜백과 같은 프레임에 현재 화면의 순수 시각 효과를 갱신한다.
        _acquiredRewards = {..._acquiredRewards, selected.id};
        if (selected.effectKind == RunRewardEffectKind.ballAppearance) {
          _game.setBallRewardAppearance(true);
        }
        if (selected.effectKind == RunRewardEffectKind.cloneCore) {
          _state = _state.copyWith(
            copyCharges: _state.copyCharges + 1,
            copyChargeLimit: _state.copyChargeLimit + 1,
            copyCoreCount: _state.copyCoreCount + 1,
            message: '복제 코어 1개를 런 보상으로 얻었습니다.',
          );
          _stageCopyCoreAtStart = _state.copyCoreCount;
          _feedback.copyCoreAwarded(1);
        }
        if (selected.effectKind == RunRewardEffectKind.precisionCharge) {
          _state = _state.copyWith(message: '정밀 충전 조절 활성 · 충전 속도가 25% 느려집니다.');
        }
      });
      _recordTyped(
        PlayTelemetryEventType.rewardSelected,
        result: PlayTelemetryResult.continued,
      );
      if (selected.effectKind == RunRewardEffectKind.nextStageHintAccess) {
        _recordTyped(
          PlayTelemetryEventType.hintRewardSelected,
          hint: PlayTelemetryHintPayload(
            source: PlayTelemetryHintSource.clearReward,
            level: PlayTelemetryHintLevel.one,
          ),
        );
      }
    } on Object {
      if (!mounted) return;
      setState(() {
        _isSelectingReward = false;
        _rewardSelectionError = '보상을 저장하지 못했습니다. 다시 선택해 주세요.';
      });
    }
  }

  Future<bool> _consumeRunReward(
    String rewardId,
    String useKey, {
    bool stageScoped = false,
    PlayTelemetryRewardTrigger trigger = PlayTelemetryRewardTrigger.manual,
  }) async {
    final callback = widget.onRunRewardUsed;
    if (callback == null) return false;
    final selection = _rewardUseSelection(
      rewardId,
      useKey: useKey,
      stageScoped: stageScoped,
    );
    try {
      final used = await callback(rewardId, useKey, stageScoped);
      if (used) {
        _feedback.rewardActivated();
        _recordRewardUse(
          rewardId: rewardId,
          useKey: useKey,
          stageScoped: stageScoped,
          trigger: trigger,
          selection: selection,
        );
      }
      return used;
    } on Object {
      if (mounted) {
        _setState(_state.copyWith(message: '런 보상 사용을 저장하지 못했습니다. 다시 시도해 주세요.'));
      }
      return false;
    }
  }

  Future<void> _cancelLaunchWithReward() async {
    if (_isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction ||
        !_isCharging ||
        _rewardInventory.availableUseCount(runRewardShotCancelAssistId) < 1) {
      return;
    }
    _isCommittingRewardAction = true;
    _pressActivationTimer?.cancel();
    _chargeFeedbackTimer?.cancel();
    _chargeFeedbackTimer = null;
    _chargeTimer?.cancel();
    _pressActivationTimer = null;
    _chargeTimer = null;
    _launchInputSession.cancel();
    _isCharging = false;
    _chargeStartRecorded = false;
    _setChargeGauge(ChargeGaugeState.green, active: false);
    try {
      final used = await _consumeRunReward(
        runRewardShotCancelAssistId,
        '${_state.levelIndex}:${_state.shotCount}:발사취소',
      );
      if (!used || !mounted) return;
      _recordTyped(
        PlayTelemetryEventType.chargeCancelled,
        result: PlayTelemetryResult.cancelled,
      );
      _recordTyped(
        PlayTelemetryEventType.powerGaugeCancelled,
        powerGauge: PlayTelemetryPowerGaugePayload(
          chargeStage: 4,
          power: LaunchInputSession.maximumPower,
          cancelled: true,
        ),
      );
      _setState(_state.copyWith(message: '발사 취소 보조를 사용해 다시 조준할 수 있습니다.'));
    } finally {
      _isCommittingRewardAction = false;
    }
  }

  Future<void> _recoverPastBallWithReward() async {
    if (_isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction ||
        _isCommittingShot ||
        _isCommittingTraitAction) {
      return;
    }
    final spentBalls = _state.entities
        .where(
          (entity) =>
              entity.type == EntityType.ball &&
              entity.id.startsWith('spent_ball_'),
        )
        .toList();
    if (spentBalls.isEmpty ||
        _rewardInventory.availableUseCount(runRewardSpentBallRecoveryId) < 1) {
      return;
    }
    _isCommittingRewardAction = true;
    try {
      final target = spentBalls.last;
      final stageAttempt = runStageAttemptNumber(
        _acquiredRewards,
        _currentLevel.id,
      );
      final used = await _consumeRunReward(
        runRewardSpentBallRecoveryId,
        '${_currentLevel.id}|$stageAttempt|${target.id}',
      );
      if (!used || !mounted) return;
      _showFailurePopup = false;
      _setState(
        _state.copyWith(
          entities: [
            for (final entity in _state.entities)
              if (entity.id != target.id) entity,
          ],
          message:
              '과거 공 ${target.id.substring('spent_ball_'.length)}번을 회수했습니다.',
        ),
      );
    } finally {
      _isCommittingRewardAction = false;
    }
  }

  String _impactTargetLabel(ShotImpact impact) {
    final entity = _state.entityById(impact.entityId);
    if (entity != null) return _entityName(entity);
    if (impact.entityId.startsWith('field_boundary_') ||
        impact.entityId.startsWith('wall_')) {
      return '벽';
    }
    return switch (impact.entityType) {
      EntityType.wall => '벽',
      EntityType.hole => '홀',
      EntityType.ball => '과거 공',
      EntityType.crate => '상자',
      EntityType.weight => '무거운 돌',
      EntityType.bumper => '탄성 물체',
      EntityType.balloon => '풍선',
      EntityType.powerSlider => '파워 슬라이더',
      EntityType.rotatingReflector => '회전 반사판',
      _ => '물체',
    };
  }

  String? _previewFirstImpact(Vec2 direction, double power) {
    if (_rewardInventory.availableUseCount(runRewardFirstImpactGuideId) < 1) {
      return null;
    }
    final preview = _previewShotResult(
      ShotInput(
        direction: direction,
        power: power,
        equippedTrait: _state.equippedTrait,
      ).normalized(),
    );
    return preview.impacts.isEmpty
        ? null
        : _impactTargetLabel(preview.impacts.first);
  }

  String _chargeMessageWithImpactGuide(
    ChargeGaugeState gaugeState,
    double power,
  ) {
    _guidedImpactLabel = _previewFirstImpact(
      _pendingLaunchDirection ?? _state.aimDirection,
      power,
    );
    final guide = _guidedImpactLabel;
    return guide == null
        ? _chargeGaugeMessage(gaugeState)
        : '${_chargeGaugeMessage(gaugeState)} · 첫 충돌 $guide';
  }

  GameState _withoutRecoveredPastBalls(GameState state) {
    final stageAttempt = runStageAttemptNumber(
      _acquiredRewards,
      _currentLevel.id,
    );
    final prefix = '${_currentLevel.id}|$stageAttempt|';
    final recoveredIds = _rewardInventory
        .useKeys(runRewardSpentBallRecoveryId)
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length))
        .toSet();
    if (recoveredIds.isEmpty) return state;
    return state.copyWith(
      entities: [
        for (final entity in state.entities)
          if (!recoveredIds.contains(entity.id)) entity,
      ],
    );
  }

  void _selectTraitSource(String sourceId) {
    _feedback.traitSelected();
    _showBallInfo = false;
    _inspectedEntityId = sourceId;
    final next = _traitResolver.selectSource(_state, sourceId);
    _setState(
      _state.levelIndex == 0
          ? next.copyWith(message: '추천 경로 설명을 읽고 속성 옮기기를 시도해 보세요.')
          : next,
    );
  }

  void _transferTrait() {
    if (_isCommittingTraitAction ||
        _isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction) {
      return;
    }
    unawaited(_transferTraitAfterCommit());
  }

  Future<void> _transferTraitAfterCommit() async {
    final sourceId = _inspectedEntityId;
    final source = sourceId == null ? null : _state.entityById(sourceId);
    if (sourceId == null || source == null || source.traits.isEmpty) return;
    final sourceTrait = source.traits.first;
    _isCommittingTraitAction = true;
    try {
      await widget.onTraitActionCommitted?.call(
        sourceId,
        RunTraitAction.transfer,
      );
    } on Object {
      _isCommittingTraitAction = false;
      if (mounted) {
        _setState(
          _state.copyWith(message: '속성 옮기기 기록을 저장하지 못했습니다. 다시 시도해 주세요.'),
        );
      }
      return;
    }
    if (!mounted || _state.entityById(sourceId) != source) {
      _isCommittingTraitAction = false;
      return;
    }
    _feedback.traitTransferred();
    _traitEffectFeedback = null;
    _showBallInfo = false;
    _inspectedEntityId = null;
    final next = _traitResolver
        .transferSelectedTrait(_state)
        .copyWith(
          message: _state.levelIndex == 0
              ? '추천 경로를 준비했습니다. 공을 길게 눌렀다 손을 떼면 자동 발사됩니다.'
              : '${sourceTrait.label} 능력은 공으로 옮겨지고 원본에서는 사라졌습니다. '
                    '${source.movableWhenDrained ? '원본은 이제 움직일 수 있습니다.' : '원본의 위치와 형태는 남습니다.'}',
        );
    _traitTransferFeedbackTimer?.cancel();
    _traitTransferFeedback = TraitTransferFeedback(
      sourceName: _entityName(source),
      sourceType: source.type,
      trait: sourceTrait,
      sourceEffect: traitLossConsequence(source, sourceTrait),
    );
    _telemetry.record(
      '속성 이전',
      stage: _state.levelIndex,
      trait: next.equippedTrait?.label,
      action: '이전',
      eventCode: 'attribute_transferred',
      objectId: sourceId,
      objectType: source.type.name,
      attributeBefore: sourceTrait.label,
      attributeAfter: next.equippedTrait?.label,
    );
    _recordTyped(PlayTelemetryEventType.propertyTransferred);
    _isCommittingTraitAction = false;
    _setState(next);
    _traitTransferFeedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _traitTransferFeedback = null);
    });
  }

  void _copyTrait() {
    if (_isCommittingTraitAction ||
        _isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction) {
      return;
    }
    unawaited(_copyTraitAfterCommit());
  }

  Future<void> _copyTraitAfterCommit() async {
    final sourceId = _inspectedEntityId;
    final source = sourceId == null ? null : _state.entityById(sourceId);
    if (sourceId == null || source == null || source.traits.isEmpty) return;
    final sourceTrait = source.traits.first;
    _isCommittingTraitAction = true;
    try {
      await widget.onTraitActionCommitted?.call(sourceId, RunTraitAction.copy);
    } on Object {
      _isCommittingTraitAction = false;
      if (mounted) {
        _setState(
          _state.copyWith(message: '속성 복사 기록을 저장하지 못했습니다. 다시 시도해 주세요.'),
        );
      }
      return;
    }
    if (!mounted || _state.entityById(sourceId) != source) {
      _isCommittingTraitAction = false;
      return;
    }
    _feedback.traitCopied();
    _traitEffectFeedback = null;
    _traitTransferFeedbackTimer?.cancel();
    _traitTransferFeedback = null;
    _showBallInfo = false;
    _inspectedEntityId = null;
    final next = _traitResolver.copySelectedTrait(_state);
    final remaining = _state.copyCoreCount > 0
        ? '복제 코어 ${next.copyCoreCount}개 남음'
        : '복사 ${next.copyCharges}회 남음';
    _isCommittingTraitAction = false;
    _setState(
      next.copyWith(
        message:
            '원본에 속성을 남기고 공에 복사했습니다. $remaining. 길게 눌러 힘을 모은 뒤 손을 떼면 자동 발사됩니다.',
      ),
    );
    _telemetry.record(
      '속성 복사',
      stage: _state.levelIndex,
      trait: next.equippedTrait?.label,
      action: '복제 코어',
      eventCode: 'attribute_copied',
      objectId: sourceId,
      objectType: source.type.name,
      attributeBefore: sourceTrait.label,
      attributeAfter: next.equippedTrait?.label,
    );
    _recordTyped(PlayTelemetryEventType.propertyCopied);
  }

  void _launch({
    ShotInput? inputOverride,
    bool isReplay = false,
    Duration? inputReleasedAt,
  }) {
    if (!_shotResolver.canLaunch(_state) ||
        _isAnimatingShot ||
        _isCommittingShot ||
        _isCommittingTraitAction ||
        _isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction) {
      return;
    }
    _isCommittingShot = true;
    final latencyStartedAt =
        inputReleasedAt ?? _launchInputLatency.markRelease();
    unawaited(
      _launchAfterCommit(
        inputOverride: inputOverride,
        isReplay: isReplay,
        inputReleasedAt: latencyStartedAt,
      ),
    );
  }

  void _launchVerifiedDemoShot() {
    final preset = widget.demoLaunchInput;
    if (preset == null) return;
    _launch(
      inputOverride: ShotInput(
        direction: preset.direction,
        power: preset.power,
        equippedTrait: _state.equippedTrait,
      ),
    );
  }

  Future<void> _launchAfterCommit({
    ShotInput? inputOverride,
    required bool isReplay,
    required Duration inputReleasedAt,
  }) async {
    final input =
        inputOverride ??
        ShotInput(
          direction: _state.aimDirection,
          power: _state.aimPower,
          equippedTrait: _state.equippedTrait,
        );
    final normalizedInput = input.normalized();
    final shouldConsumeImpactGuide =
        !isReplay &&
        _guidedImpactLabel != null &&
        _rewardInventory.availableUseCount(runRewardFirstImpactGuideId) > 0;
    if (!isReplay && widget.onShotCommitted != null) {
      try {
        final impactGuideSelection = shouldConsumeImpactGuide
            ? _rewardUseSelection(
                runRewardFirstImpactGuideId,
                useKey: '${_state.levelIndex}:${_state.shotCount}:첫충돌',
                stageScoped: false,
              )
            : null;
        final consumed = await widget.onShotCommitted!(
          normalizedInput,
          shouldConsumeImpactGuide,
        );
        if (shouldConsumeImpactGuide && !consumed) {
          throw StateError('첫 충돌 안내 사용을 저장하지 못했습니다.');
        }
        if (shouldConsumeImpactGuide && consumed) {
          _recordRewardUse(
            rewardId: runRewardFirstImpactGuideId,
            useKey: '${_state.levelIndex}:${_state.shotCount}:첫충돌',
            stageScoped: false,
            trigger: PlayTelemetryRewardTrigger.automatic,
            selection: impactGuideSelection,
          );
        }
      } on Object {
        _isCommittingShot = false;
        if (mounted) {
          _setState(_state.copyWith(message: '발사 기록을 저장하지 못했습니다. 다시 시도해 주세요.'));
        }
        return;
      }
      if (!mounted || _state.phase != GamePhase.planning) {
        _isCommittingShot = false;
        return;
      }
    }
    if (shouldConsumeImpactGuide && widget.onShotCommitted == null) {
      final consumed = await _consumeRunReward(
        runRewardFirstImpactGuideId,
        '${_state.levelIndex}:${_state.shotCount}:첫충돌',
        trigger: PlayTelemetryRewardTrigger.automatic,
      );
      if (!consumed) {
        _isCommittingShot = false;
        return;
      }
      if (!mounted || _state.phase != GamePhase.planning) {
        _isCommittingShot = false;
        return;
      }
      _guidedImpactLabel = null;
    }
    if (shouldConsumeImpactGuide) {
      _guidedImpactLabel = null;
    }
    if (widget.showDebugControls && _debugRecordReplay && !isReplay) {
      _debugReplayStartState = _state;
      _debugReplayInput = input;
      _debugReplayPriorShotResults = List.of(_stageShotResults);
      _debugReplayPriorBumperHit = _bonusBumperHit;
      _debugReplayPriorSwitchPressed = _bonusSwitchPressed;
      _debugReplayPriorDrainedSourceMoved = _bonusDrainedSourceMoved;
      _debugReplayPriorBumperHistory = List.of(_bonusBumperHistory);
      _debugReplayPriorSwitchHistory = List.of(_bonusSwitchHistory);
      _debugReplayPriorDrainedHistory = List.of(_bonusDrainedSourceHistory);
    }
    _bonusBumperHistory.insert(0, _bonusBumperHit);
    _bonusSwitchHistory.insert(0, _bonusSwitchPressed);
    _bonusDrainedSourceHistory.insert(0, _bonusDrainedSourceMoved);
    final shotStartState = _state;
    final result = _shotResolver.resolve(shotStartState, normalizedInput);
    final assistDecision = _pendingIntentAssistDecision;
    _pendingIntentAssistDecision = null;
    _updateIntentAssistStreak(
      shotStartState: shotStartState,
      result: result,
      decision: assistDecision,
    );
    _traitEffectFeedback = _traitEffectFeedbackFor(normalizedInput, result);
    final inputLatencyMs = _launchInputLatency.elapsedMillisecondsSince(
      inputReleasedAt,
    );
    if (result.state.phase != GamePhase.success) {
      _failureReplay = FailureReplayData(
        beforeState: shotStartState,
        input: normalizedInput,
        result: result,
      );
    } else {
      _failureReplay = null;
      _lastFailureCauseKey = null;
      _repeatedFailureCauseCount = 0;
      _setPreviousAimInput(null);
    }
    _stageShotResults.add(result);
    _stageShotInputs.add(normalizedInput);
    _captureDiscoveries(result.state);
    _chainScoreAnalysis = _analyzeSuccessfulStage(
      state: result.state,
      shotResults: _stageShotResults,
      parShots: _currentLevel.parShots,
    );
    _lastTypedShot = _typedShotPayload(
      input: normalizedInput,
      result: result,
      startState: shotStartState,
      inputLatencyMs: inputLatencyMs,
    );
    _recordTyped(PlayTelemetryEventType.shotReleased, shot: _lastTypedShot);
    if (!isReplay) {
      // Key/failure writes are queued immediately behind the already-durable
      // shot commit, but never hold the animation path hostage. The key VFX
      // and hint button still change only after the key save resolves true.
      unawaited(
        _recordCollectedKeys(stateBeforeShot: shotStartState, result: result),
      );
      unawaited(_recordHintFailureIfEligible(result));
    }
    _telemetry.record(
      '발사',
      stage: _state.levelIndex,
      attempt: _state.shotCount + 1,
      angle: math.atan2(
        normalizedInput.direction.y,
        normalizedInput.direction.x,
      ),
      power: normalizedInput.power,
      trait: normalizedInput.equippedTrait?.label,
      eventCode: 'shot_fired',
      shotId: _state.shotCount + 1,
      objectId: _state.activeBall.id,
      objectType: _state.activeBall.type.name,
      speed: 8 + normalizedInput.power * 16,
      isReplay: isReplay,
    );
    _feedback.shotLaunched();
    _showBallInfo = false;
    _inspectedEntityId = null;
    _showFailurePopup = false;
    final replay = _failureReplay;
    if (replay != null) {
      final advice = const FailureActionAdvisor().analyze(replay);
      _repeatedFailureCauseCount = _lastFailureCauseKey == advice.causeKey
          ? (_repeatedFailureCauseCount + 1).clamp(0, 9).toInt()
          : 1;
      _lastFailureCauseKey = advice.causeKey;
      _failureAdvice = advice.messageForAttempt(_repeatedFailureCauseCount);
      final causal = widget.showTutorialFailureHints
          ? tutorialCausalHintForStage(result.state.levelIndex)
          : null;
      if (causal != null) _failureAdvice = '$_failureAdvice $causal';
    } else {
      _failureAdvice = '';
    }
    if (_rewardInventory.failureCauseBoostEnabled &&
        result.state.phase != GamePhase.success &&
        result.impacts.isNotEmpty) {
      final collisionOrder = result.impacts
          .take(5)
          .map(_impactTargetLabel)
          .join(' → ');
      _failureAdvice = '충돌 순서: $collisionOrder. $_failureAdvice';
    }
    _bonusBumperHit =
        _bonusBumperHit ||
        result.impacts.any((impact) => impact.entityType == EntityType.bumper);
    _bonusSwitchPressed =
        _bonusSwitchPressed || result.events.contains('switch_pressed');
    final drainedSourceIds = _state.entities
        .where((entity) => entity.visualState == 'drained')
        .map((entity) => entity.id)
        .toSet();
    _bonusDrainedSourceMoved =
        _bonusDrainedSourceMoved ||
        result.moves.any(
          (move) =>
              drainedSourceIds.contains(move.entityId) && move.from != move.to,
        );
    _aimStartedForShot = false;
    _pendingLaunchDirection = null;
    _semanticAnimationStartState = shotStartState;
    _isAnimatingShot = true;
    final assistedState = _stateWithIntentAssistFeedback(
      result.state,
      result,
      assistDecision,
    );
    _setState(
      assistedState,
      path: result.animationPath.isEmpty ? result.path : result.animationPath,
      transitionStart: shotStartState,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
    );
    if (result.state.phase == GamePhase.success) {
      final analysis = _chainScoreAnalysis;
      final bonusAchieved = _bonusGoalReached(result);
      final persistence = _persistClearResult(result, analysis, bonusAchieved);
      _clearPersistenceFuture = persistence;
      _clearPersistenceRetry = () =>
          _persistClearResult(result, analysis, bonusAchieved);
      unawaited(persistence);
    }
    _isCommittingShot = false;
  }

  GameState _stateWithIntentAssistFeedback(
    GameState state,
    ShotResult result,
    IntentAssistDecision? decision,
  ) {
    if (result.events.contains('hole_lip_in_assist')) {
      return state.copyWith(message: '홀 가장자리에서 안쪽 흐름을 살려 들어갔습니다.');
    }
    if (decision == null || !decision.targetSnapped) return state;
    final target = decision.targetEntityId == null
        ? null
        : _state.entityById(decision.targetEntityId!);
    final label = target == null ? '가까운 목표' : _entityName(target);
    return state.copyWith(message: '조준 의도 보정 · $label 쪽 작은 오차를 다듬었습니다.');
  }

  void _updateIntentAssistStreak({
    required GameState shotStartState,
    required ShotResult result,
    required IntentAssistDecision? decision,
  }) {
    if (result.state.phase == GamePhase.success) {
      _repeatedNearMisses = 0;
      _lastNearMissTargetId = null;
      return;
    }
    final hole = shotStartState.entities
        .where((entity) => entity.type == EntityType.hole)
        .firstOrNull;
    final ball = shotStartState.entityById('active_ball');
    var nearHole = false;
    if (hole != null && ball != null && result.path.isNotEmpty) {
      var nearest = double.infinity;
      for (final point in result.path) {
        nearest = math.min(nearest, point.distanceTo(hole.position));
      }
      final edgeMiss = nearest - hole.hitRadius - ball.hitRadius;
      nearHole = edgeMiss > 0 && edgeMiss <= 24;
    }
    final targetId = nearHole ? hole?.id : decision?.targetEntityId;
    if (targetId == null) {
      _repeatedNearMisses = 0;
      _lastNearMissTargetId = null;
      return;
    }
    _repeatedNearMisses = _lastNearMissTargetId == targetId
        ? (_repeatedNearMisses + 1).clamp(0, 3).toInt()
        : 1;
    _lastNearMissTargetId = targetId;
  }

  String? _traitEffectFeedbackFor(ShotInput input, ShotResult result) {
    final trait = input.equippedTrait;
    if (trait == null) return null;
    return switch (trait) {
      TraitType.heavy =>
        result.events.contains('switch_pressed') ||
                result.events.contains('crate_pushed')
            ? '무거움 발동 · 무게를 이용한 상호작 성공'
            : '무거움 사용 · 상자나 무게 스위치를 노려보세요',
      TraitType.bouncy => () {
        final wallBounces = result.impacts
            .where(
              (impact) =>
                  impact.sourceEntityId == 'active_ball' &&
                  (impact.entityType == EntityType.wall ||
                      impact.entityType == EntityType.gate),
            )
            .length;
        return wallBounces == 0
            ? '탄성 사용 · 벽에 닿으면 반사할 때마다 효과가 유지됩니다'
            : '탄성 유지 · 벽·문 $wallBounces회 강한 반사';
      }(),
      TraitType.sticky =>
        result.events.contains('sticky_attached')
            ? '점착 발동 · 첫 유효 표면에 공이 고정됨'
            : '점착 미발동 · 붙을 수 있는 표면을 노려보세요',
      TraitType.sharp =>
        result.events.contains('sharpness_consumed')
            ? '뾰족함 발동 · 풍선을 터뜨리고 속성 소모'
            : '뾰족함 미발동 · 풍선에 닿아야 발동합니다',
    };
  }

  Future<bool> _persistClearResult(
    ShotResult result,
    CreativeChainScoreAnalysis? analysis,
    bool bonusAchieved,
  ) async {
    final levelIndex = result.state.levelIndex;
    var effectiveBonusAchieved =
        bonusAchieved || _challengeGuardAppliedForClear;
    var effectiveShotCount = result.state.shotCount;
    final requestChallengeGuard =
        !effectiveBonusAchieved &&
        _rewardInventory.availableUseCount(runRewardOptionalChallengeGuardId) >
            0;
    final requestRecordGuard =
        !_recordGuardAppliedForClear &&
        _rewardInventory.canUseForStage(
          runRewardStageRecordGuardId,
          _currentLevel.id,
        );
    try {
      final runClearCallback = widget.onRunLevelCleared;
      if (runClearCallback != null) {
        final challengeUseKey =
            '${_currentLevel.id}:${result.state.shotCount}:선택도전';
        final challengeSelection = requestChallengeGuard
            ? _rewardUseSelection(
                runRewardOptionalChallengeGuardId,
                useKey: challengeUseKey,
                stageScoped: false,
              )
            : null;
        final recordSelection = requestRecordGuard
            ? _rewardUseSelection(
                runRewardStageRecordGuardId,
                useKey: _currentLevel.id,
                stageScoped: true,
              )
            : null;
        final completion = await runClearCallback(
          levelIndex,
          analysis,
          bonusAchieved,
          result.state.shotCount,
          requestChallengeGuard,
          requestRecordGuard,
        );
        effectiveBonusAchieved = completion.optionalChallengeAchieved;
        effectiveShotCount = completion.shotCount;
        _challengeGuardAppliedForClear =
            effectiveBonusAchieved && !bonusAchieved;
        _recordGuardAppliedForClear =
            effectiveShotCount < result.state.shotCount;
        if (_challengeGuardAppliedForClear) {
          _recordRewardUse(
            rewardId: runRewardOptionalChallengeGuardId,
            useKey: challengeUseKey,
            stageScoped: false,
            trigger: PlayTelemetryRewardTrigger.automatic,
            selection: challengeSelection,
          );
        }
        if (_recordGuardAppliedForClear) {
          _recordRewardUse(
            rewardId: runRewardStageRecordGuardId,
            useKey: _currentLevel.id,
            stageScoped: true,
            trigger: PlayTelemetryRewardTrigger.automatic,
            selection: recordSelection,
          );
        }
      } else {
        if (requestChallengeGuard) {
          final used = await _consumeRunReward(
            runRewardOptionalChallengeGuardId,
            '${_currentLevel.id}:${result.state.shotCount}:선택도전',
            trigger: PlayTelemetryRewardTrigger.automatic,
          );
          if (used) {
            _challengeGuardAppliedForClear = true;
            effectiveBonusAchieved = true;
          }
        }
        if (requestRecordGuard) {
          _recordGuardAppliedForClear = await _consumeRunReward(
            runRewardStageRecordGuardId,
            _currentLevel.id,
            stageScoped: true,
            trigger: PlayTelemetryRewardTrigger.automatic,
          );
        }
        if (_recordGuardAppliedForClear) {
          effectiveShotCount = math.max(1, result.state.shotCount - 1).toInt();
        }
        await widget.onLevelCleared?.call(
          levelIndex,
          analysis,
          effectiveBonusAchieved,
          effectiveShotCount,
        );
      }
    } on Object {
      if (mounted) {
        setState(() {
          _clearPersistenceErrorTitle = '클리어 기록을 저장하지 못했습니다';
          _clearPersistenceErrorBody = '기록 저장이 끝나야 보상과 다음 단계로 이동할 수 있습니다.';
          _state = _state.copyWith(message: '클리어 기록을 저장하지 못했습니다. 다시 시도해 주세요.');
        });
      }
      return false;
    }
    if (mounted && _state.shotCount != effectiveShotCount) {
      setState(() {
        _state = _state.copyWith(
          shotCount: effectiveShotCount,
          message: '기록 보호로 발사 횟수 1회를 줄였습니다.',
        );
      });
    }
    try {
      if (widget.onRunLevelCleared == null) {
        await _unlockNextLevel(levelIndex);
        if (effectiveBonusAchieved) {
          await _recordBonusGoal(levelIndex);
        }
        await _recordBestShot(levelIndex, effectiveShotCount);
      } else if (mounted) {
        setState(() {
          _unlockedLevel = math.max(
            _unlockedLevel,
            math.min(levelIndex + 1, levels.length - 1),
          );
          if (_difficulty == PlayerDifficulty.normal) {
            final previousBest = _bestShots[levelIndex];
            _bestShots[levelIndex] = previousBest == null
                ? effectiveShotCount
                : math.min(previousBest, effectiveShotCount);
            if (effectiveBonusAchieved) {
              _bonusGoals[levelIndex] = true;
              _bonusChallengeAchieved = true;
            }
          }
        });
      }
    } on Object {
      if (mounted) {
        setState(() {
          _clearPersistenceErrorTitle = '클리어 기록을 저장하지 못했습니다';
          _clearPersistenceErrorBody = '기록 저장이 끝나야 보상과 다음 단계로 이동할 수 있습니다.';
          _state = _state.copyWith(
            message: '클리어했지만 기록 저장이 지연되고 있어요. 잠시 후 다시 확인해 주세요.',
          );
        });
      }
      return false;
    }
    final expeditionCallback = widget.onExpeditionStageCompleted;
    final route = deriveSolutionRoute(
      inputs: _stageShotInputs,
      results: _stageShotResults,
    );
    final solutionCallback = widget.onSolutionDiscovered;
    if (route != null && solutionCallback != null) {
      try {
        final recorded = await solutionCallback(route);
        if (mounted) {
          setState(() {
            _solutionEntries = recorded.entries;
            _newSolutionStamp = recorded.isNew;
          });
        }
      } on Object {
        // 해법 도감 저장 실패가 이미 저장된 클리어·보상을 되돌리지는 않는다.
      }
    }
    if (expeditionCallback != null) {
      try {
        await expeditionCallback(
          ExpeditionStageOutcome(
            stageId: _currentLevel.stageId ?? _currentLevel.id,
            shotCount: result.state.shotCount,
            parShots: _currentLevel.parShots,
            discoveryCount: _discoveryMilestones
                .where((milestone) => milestone.achieved)
                .length,
            gimmickCount: _stageGimmickTypes.length,
            chainScore: analysis?.totalScore ?? 0,
          ),
        );
      } on Object {
        // 탐사 목표는 캠페인 클리어와 보상 저장을 되돌리지 않는다.
      }
    }
    return true;
  }

  Future<void> _showClearPopupAfterPersistence() async {
    final persisted = await (_clearPersistenceFuture ?? Future.value(true));
    if (!persisted) return;
    if (!mounted || _state.phase != GamePhase.success) return;
    setState(() => _showClearPopup = true);
  }

  Future<void> _shareSolution(SolutionMasteryEntry entry) async {
    final code = SolutionShareCardCodec.encode(entry);
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('해법 카드 코드를 복사했습니다. 친구와 같은 접근을 비교할 수 있어요.')),
    );
  }

  Future<void> _retryAfterClear() async {
    if (_isCommittingStageAction) return;
    _isCommittingStageAction = true;
    try {
      final persisted = await (_clearPersistenceFuture ?? Future.value(true));
      if (!persisted) return;
      await widget.onStageRestarted?.call();
    } on Object {
      if (mounted) {
        _setState(_state.copyWith(message: '재도전 상태를 저장하지 못했습니다. 다시 시도해 주세요.'));
      }
      return;
    } finally {
      _isCommittingStageAction = false;
    }
    if (mounted) _selectLevel(_state.levelIndex);
  }

  void _retryClearPersistence() {
    final retry = _clearPersistenceRetry;
    if (retry == null || _isAnimatingShot) return;
    final persistence = retry();
    _clearPersistenceFuture = persistence;
    setState(() {
      _semanticAnimationStartState = null;
      _showClearPersistenceError = false;
      _isAnimatingShot = true;
    });
    unawaited(_finishAnimationAfterPersistence());
  }

  void _restartCurrentStage() {
    unawaited(_restartCurrentStageAfterPersist());
  }

  Future<void> _restartCurrentStageAfterPersist() async {
    if (_isAnimatingShot ||
        _isCommittingShot ||
        _isCommittingTraitAction ||
        _isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction) {
      return;
    }
    _isCommittingStageAction = true;
    try {
      await widget.onStageRestarted?.call();
    } on Object {
      if (mounted) {
        _setState(_state.copyWith(message: '단계 초기화를 저장하지 못했습니다. 다시 시도해 주세요.'));
      }
      return;
    } finally {
      _isCommittingStageAction = false;
    }
    if (mounted) {
      _selectLevel(_state.levelIndex);
    }
  }

  bool _bonusGoalReached(ShotResult result) {
    if (result.state.levelIndex == 7) {
      final analysis = _chainScoreAnalysis;
      final patternId = _currentLevel.patternId;
      return analysis != null &&
          patternId != null &&
          const StageChainChallengeEvaluator().isAchieved(
            patternId: patternId,
            analysis: analysis,
            results: _stageShotResults,
          );
    }
    return stageBonusGoalReached(
      levelIndex: result.state.levelIndex,
      shotCount: result.state.shotCount,
      results: _stageShotResults,
      drainedSourceMoved: _bonusDrainedSourceMoved,
    );
  }

  void _onAnimationFinished() {
    unawaited(_finishAnimationAfterPersistence());
  }

  Future<void> _finishAnimationAfterPersistence() async {
    if (!mounted || !_isAnimatingShot) {
      return;
    }
    final cleared = _state.phase == GamePhase.success;
    if (cleared) {
      final persisted = await (_clearPersistenceFuture ?? Future.value(true));
      if (!mounted || !_isAnimatingShot) return;
      if (!persisted) {
        setState(() {
          _isAnimatingShot = false;
          _showClearPopup = false;
          _showFailurePopup = false;
          _showClearPersistenceError = true;
        });
        return;
      }
      // 홀 진입 애니메이션과 클리어 저장이 모두 끝난 뒤에만 발견을 영구
      // 기록한다. 따라서 관측소·등대·다리 복구 연출이 공보다 먼저 뜨지 않는다.
      final discoveriesPersisted = await _persistDiscoveriesAfterClear();
      if (!mounted || !_isAnimatingShot) return;
      if (!discoveriesPersisted) {
        _clearPersistenceRetry = _persistDiscoveriesAfterClear;
        setState(() {
          _clearPersistenceErrorTitle = '섬 복구 기록을 저장하지 못했습니다';
          _clearPersistenceErrorBody =
              '발견 기록 저장이 끝나야 클리어 결과와 섬 복구를 확인할 수 있습니다.';
          _state = _state.copyWith(message: '섬 복구 기록을 저장하지 못했습니다. 다시 시도해 주세요.');
          _isAnimatingShot = false;
          _showClearPopup = false;
          _showFailurePopup = false;
          _showClearPersistenceError = true;
        });
        return;
      }
    }
    final awardedStars = cleared
        ? _starsForShot(_state.shotCount, _currentLevel.parShots)
        : 0;
    if (cleared &&
        !widget.showStageSelector &&
        !_state.copyCoreRewarded &&
        _currentLevel.copyCoreReward > 0) {
      final reward = _currentLevel.copyCoreReward;
      var newlyAwarded = true;
      try {
        newlyAwarded =
            await widget.onCopyCoreEarned?.call(_state.levelIndex, reward) ??
            true;
      } on Object {
        if (mounted) {
          setState(() {
            _clearPersistenceErrorTitle = '복제 코어 보상을 저장하지 못했습니다';
            _clearPersistenceErrorBody = '보상 저장이 끝나야 다음 단계로 이동할 수 있습니다.';
            _state = _state.copyWith(
              message: '복제 코어 보상을 저장하지 못했습니다. 다시 시도해 주세요.',
            );
            _isAnimatingShot = false;
            _showClearPopup = false;
            _showFailurePopup = false;
            _showClearPersistenceError = true;
          });
        }
        return;
      }
      if (!mounted || !_isAnimatingShot) return;
      _state = _state.copyWith(
        copyCharges: _state.copyCharges + (newlyAwarded ? reward : 0),
        copyChargeLimit: _state.copyChargeLimit + (newlyAwarded ? reward : 0),
        copyCoreCount: _state.copyCoreCount + (newlyAwarded ? reward : 0),
        copyCoreRewarded: true,
        message: '섬의 보상으로 복제 코어 $reward개를 얻었습니다.',
      );
      _stageCopyCoreAtStart = _state.copyCoreCount;
      _feedback.copyCoreAwarded(reward);
    }
    if (cleared &&
        _rewardCandidates.isEmpty &&
        widget.onRewardSelectionPrepared != null) {
      try {
        _rewardCandidates = await widget.onRewardSelectionPrepared!(
          _state.levelIndex,
        );
        _recordTyped(PlayTelemetryEventType.rewardOffered);
        if (_rewardCandidates.any(
          (reward) =>
              reward.effectKind == RunRewardEffectKind.nextStageHintAccess,
        )) {
          _recordTyped(
            PlayTelemetryEventType.hintRewardOffered,
            hint: PlayTelemetryHintPayload(
              source: PlayTelemetryHintSource.clearReward,
              level: PlayTelemetryHintLevel.one,
            ),
          );
        }
      } on Object {
        if (mounted) {
          setState(() {
            _clearPersistenceErrorTitle = '보상 후보를 저장하지 못했습니다';
            _clearPersistenceErrorBody = '보상 후보 저장이 끝나야 클리어 결과를 확인할 수 있습니다.';
            _state = _state.copyWith(message: '보상 후보를 저장하지 못했습니다. 다시 시도해 주세요.');
            _isAnimatingShot = false;
            _showClearPersistenceError = true;
          });
        }
        return;
      }
    }
    if (cleared) {
      _clearPersistenceRetry = null;
    }
    setState(() {
      _isAnimatingShot = false;
      _semanticAnimationStartState = null;
      _showClearPopup = false;
      _showFailurePopup = !cleared;
    });
    if (!cleared) {
      _refreshAssistRecommendation();
      unawaited(_refreshCounterfactualAdvice());
    }
    if (cleared) {
      final key = _currentHintKey;
      if (key != null && !_collectedHintKeyIds.contains(key.id)) {
        _recordTyped(
          PlayTelemetryEventType.keyIgnored,
          key: PlayTelemetryKeyPayload(
            keyId: key.id,
            shotId: _state.shotCount,
            collected: false,
          ),
        );
      }
      unawaited(_showClearPopupAfterPersistence());
      _recordTyped(
        PlayTelemetryEventType.collisionChainCompleted,
        shot: _lastTypedShot,
      );
      if (_bonusChallengeAchieved) {
        _recordTyped(PlayTelemetryEventType.optionalChallengeCompleted);
      }
      _recordTyped(
        PlayTelemetryEventType.stageCleared,
        shot: _lastTypedShot,
        result: PlayTelemetryResult.cleared,
        stageOutcome: _lastTypedShot == null ? null : _stageOutcomePayload(),
        hint: _hintEntitlement?.consumed == true
            ? _hintTelemetryPayload(
                _hintEntitlement!,
                level: _hintEntitlement!.unlockedHintLevel,
                clearedAfterOpen: true,
              )
            : null,
      );
      final directClear = _isDirectClear(_stageShotResults);
      if (directClear &&
          _patternHintEntry?.directClearPolicy.demoPreferred == true) {
        _recordTyped(
          PlayTelemetryEventType.demoDirectClearDetected,
          stageOutcome: _stageOutcomePayload(),
        );
      }
      _feedback.shotCleared();
      _feedback.medalAwarded(awardedStars);
    } else {
      _telemetry.record(
        '실패',
        stage: _state.levelIndex,
        attempt: _state.shotCount,
        result: '재도전 가능',
      );
      _recordTyped(
        PlayTelemetryEventType.collisionChainCompleted,
        shot: _lastTypedShot,
        result: PlayTelemetryResult.failed,
      );
      _feedback.shotFailed();
    }
  }

  Future<void> _refreshCounterfactualAdvice() async {
    final failure = _failureReplay;
    if (failure == null) return;
    // 실패 팝업을 먼저 그린 뒤 주변 후보를 계산한다. 느린 기기에서는 기존
    // 인과 조언을 유지해 이 분석이 재시도 UI를 붙잡지 않게 한다.
    await Future<void>.delayed(Duration.zero);
    final stopwatch = Stopwatch()..start();
    final counterfactual = CounterfactualShotCoach().analyze(
      stageId: _currentLevel.stageId ?? _currentLevel.id,
      failure: failure,
    );
    stopwatch.stop();
    if (!mounted || !_showFailurePopup || !identical(_failureReplay, failure)) {
      return;
    }
    if (counterfactual == null || stopwatch.elapsedMilliseconds > 12) {
      return;
    }
    final causal = widget.showTutorialFailureHints
        ? tutorialCausalHintForStage(_state.levelIndex)
        : null;
    setState(() {
      _failureAdvice = causal == null
          ? counterfactual.message
          : '${counterfactual.message} $causal';
    });
  }

  void _onAnimationImpact(ShotAnimationMove move) {
    if (!mounted || !_isAnimatingShot) {
      return;
    }
    if (move.visualState == 'pressed') {
      _feedback.switchOpened();
    } else if (move.visualState == HiddenMechanicState.opening) {
      _feedback.mysteryRevealed();
    } else if (move.visualState == 'opening') {
      _feedback.gateOpened();
    } else if (move.visualState == 'popped') {
      _feedback.balloonPopped();
    }
    final entity = _state.entityById(move.entityId);
    final objectType = entity?.type.name;
    if (move.visualState == HiddenMechanicState.opening) {
      _telemetry.record(
        '미스터리 상자 개방',
        stage: _state.levelIndex,
        target: move.entityId,
        result: HiddenMechanicState.revealed,
        eventCode: 'hidden_mechanic_revealed',
        objectId: move.entityId,
        objectType: objectType,
        position: move.impactPosition,
        collisionNormal: move.impactNormal,
      );
    } else if (move.visualState == 'pressed' &&
        entity?.type == EntityType.switchPad) {
      _telemetry.record(
        '스위치 작동',
        stage: _state.levelIndex,
        target: move.entityId,
        result: move.visualState,
        objectId: move.entityId,
        objectType: objectType,
        position: move.impactPosition,
        collisionNormal: move.impactNormal,
      );
    } else if (move.visualState == 'pressed' &&
        entity?.type == EntityType.balloon) {
      _telemetry.record(
        '풍선 변형',
        stage: _state.levelIndex,
        target: move.entityId,
        result: move.visualState,
        objectId: move.entityId,
        objectType: objectType,
        position: move.impactPosition,
        collisionNormal: move.impactNormal,
      );
    } else if (move.visualState == 'opening' &&
        entity?.type == EntityType.gate) {
      _telemetry.record(
        '문 열림',
        stage: _state.levelIndex,
        target: move.entityId,
        result: move.visualState,
        objectId: move.entityId,
        objectType: objectType,
        position: move.impactPosition,
        collisionNormal: move.impactNormal,
      );
    } else if (move.visualState == 'popped' &&
        entity?.type == EntityType.balloon) {
      _telemetry.record(
        '풍선 터짐',
        stage: _state.levelIndex,
        target: move.entityId,
        result: move.visualState,
        objectId: move.entityId,
        objectType: objectType,
        position: move.impactPosition,
        collisionNormal: move.impactNormal,
      );
      _telemetry.record(
        '속성 소모',
        stage: _state.levelIndex,
        target: '뾰족함',
        result: '풍선 충돌로 소모',
        objectId: _currentBallTelemetryId(),
        objectType: EntityType.ball.name,
        attributeBefore: '뾰족함',
      );
    } else if (move.visualState == 'stuck') {
      _telemetry.record(
        '점착 정지',
        stage: _state.levelIndex,
        target: move.entityId,
        result: move.visualState,
        objectId: move.entityId,
        objectType: objectType,
        position: move.impactPosition,
        collisionNormal: move.impactNormal,
      );
      _telemetry.record(
        '물체 정지',
        stage: _state.levelIndex,
        target: move.entityId,
        result: move.visualState,
        objectId: move.entityId,
        objectType: objectType,
        position: move.to,
      );
    }
    if (move.from.distanceTo(move.to) <= 0.001 &&
        move.visualState != 'stuck' &&
        move.visualState != 'hole_captured') {
      return;
    }
    _telemetry.record(
      '연쇄 이동',
      stage: _state.levelIndex,
      target: move.entityId,
      result: move.visualState,
      eventCode: 'object_started_moving',
      objectId: move.entityId,
      position: move.impactPosition,
    );
  }

  void _onShotImpact(ShotImpact impact) {
    if (!mounted || !_isAnimatingShot) {
      return;
    }
    _feedback.collision(
      impact.entityType,
      emphasizeJelly: impact.entityType == EntityType.bumper,
      impactStrength: impact.impulse,
    );
    _telemetry.record(
      '충돌',
      stage: _state.levelIndex,
      target: impact.entityType.name,
      eventCode: 'collision_resolved',
      shotId: _state.shotCount,
      objectId: impact.entityId,
      objectType: impact.entityType.name,
      position: impact.position,
      collisionNormal: impact.normal,
      speed: impact.relativeNormalSpeed,
      impulse: impact.impulse,
    );
    if (impact.entityType == EntityType.hole) {
      _telemetry.record(
        '홀 진입',
        stage: _state.levelIndex,
        target: impact.entityId,
        result: '공 포획',
        objectId: impact.sourceEntityId,
        objectType: EntityType.ball.name,
        position: impact.position,
        collisionNormal: impact.normal,
        speed: impact.relativeNormalSpeed,
        impulse: impact.impulse,
      );
      _telemetry.record(
        '물체 정지',
        stage: _state.levelIndex,
        target: impact.sourceEntityId,
        result: '홀 안에서 정지',
        objectId: impact.sourceEntityId,
        objectType: EntityType.ball.name,
        position: impact.position,
      );
    }
  }

  void _onPhysicsEvent(PhysicsEvent event) {
    if (mounted) {
      _debugPhysicsEvents.add(event);
      if (_debugPhysicsEvents.length > 100) {
        _debugPhysicsEvents.removeAt(0);
      }
    }
    if (mounted &&
        _isAnimatingShot &&
        event.kind == PhysicsEventKind.powerSliderActivation &&
        event.powerSlider != null) {
      final activation = event.powerSlider!;
      _feedback.powerSliderActivated();
      _telemetry.record(
        '파워 슬라이더 작동',
        stage: _state.levelIndex,
        target: activation.sliderEntityId,
        result: '진행 방향 유지',
        eventCode: 'power_slider_activated',
        shotId: _state.shotCount,
        objectId: activation.sourceEntityId,
        objectType: EntityType.powerSlider.name,
        contactId: activation.contactId,
        position: activation.position,
        velocity: activation.velocityAfter,
        speed: activation.speedAfter,
        speedBefore: activation.speedBefore,
        speedAfter: activation.speedAfter,
        referenceSpeed: activation.referenceSpeed,
      );
    }
    if (mounted &&
        _isAnimatingShot &&
        event.kind == PhysicsEventKind.reflectorRotation &&
        event.reflectorRotation != null) {
      final rotation = event.reflectorRotation!;
      _feedback.reflectorRotated();
      _telemetry.record(
        '회전 반사판 회전',
        stage: _state.levelIndex,
        target: rotation.reflectorEntityId,
        result:
            '${rotation.orientationBefore}에서 ${rotation.orientationAfter}로 회전',
        eventCode: 'reflector_rotated',
        shotId: _state.shotCount,
        objectId: rotation.sourceEntityId,
        objectType: EntityType.rotatingReflector.name,
        contactId: rotation.contactId,
        position: event.position,
        velocity: rotation.velocityAfter,
        speedBefore: rotation.velocityBefore.length,
        speedAfter: rotation.velocityAfter.length,
        collisionNormal: rotation.collisionNormal,
      );
    }
    if (!mounted ||
        !_isAnimatingShot ||
        event.kind != PhysicsEventKind.chainSafetyStop) {
      return;
    }
    _telemetry.record(
      '연쇄 안전 중단',
      stage: _state.levelIndex,
      target: event.targetEntityId,
      result:
          '반복 ${event.iterations ?? 0}회·잔여 속도 ${(event.remainingSpeed ?? 0).toStringAsFixed(2)}',
    );
  }

  void _openDebugMenu() {
    if (!kDebugMode || !widget.showDebugControls) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DebugMenu(
        state: _state,
        recentEvents: _debugPhysicsEvents,
        showHitboxes: _debugShowHitboxes,
        showNormals: _debugShowNormals,
        showIds: _debugShowIds,
        showStats: _debugShowStats,
        activeMass: ShotResolver.massOf(_state.activeBall),
        activeSpeed: _lastDebugSpeed,
        activeMomentum:
            ShotResolver.massOf(_state.activeBall) * _lastDebugSpeed,
        lastCollisionId: _lastDebugCollisionId,
        recordingReplay: _debugRecordReplay,
        hasReplay: _debugReplayInput != null && _debugReplayStartState != null,
        soundEnabled: GameFeedback.soundEnabled,
        hapticsEnabled: GameFeedback.hapticsEnabled,
        tutorialVariant: _activeTutorialVariant,
        inputLatencyReport: _telemetry.inputLatencyReport,
        framePerformanceReport: _framePerformance.report,
        onSelectStage: _debugSelectStage,
        onRestartStage: _restartCurrentStage,
        onResetProgress: _debugResetProgress,
        onUnlockAll: _debugUnlockAll,
        onSetCopyCore: _debugSetCopyCore,
        onForceTrait: _debugForceTrait,
        onRemoveTrait: _debugRemoveTrait,
        onRestoreTrait: _debugRestoreTrait,
        onToggleHitboxes: (value) {
          setState(() => _debugShowHitboxes = value);
          _game.setDebugOptions(hitboxes: value);
        },
        onToggleNormals: (value) {
          setState(() => _debugShowNormals = value);
          _game.setDebugOptions(normals: value);
        },
        onToggleIds: (value) {
          setState(() => _debugShowIds = value);
          _game.setDebugOptions(ids: value);
        },
        onToggleStats: (value) {
          setState(() => _debugShowStats = value);
          _game.setDebugOptions(stats: value);
        },
        onTutorialVariantChanged: (value) {
          setState(() => _activeTutorialVariant = value);
          _telemetry.record(
            '튜토리얼 조건 변경',
            stage: _state.levelIndex,
            result: value.code,
          );
        },
        onCopyState: _copyDebugState,
        onCopyEvents: _copyDebugEvents,
        onCopyInputLatencyReport: _copyInputLatencyReport,
        onCopyFramePerformanceReport: _copyFramePerformanceReport,
        onToggleReplayRecording: (value) {
          setState(() => _debugRecordReplay = value);
        },
        onPlayReplay: _debugPlayReplay,
        onToggleSound: (value) {
          unawaited(GameFeedback.setSoundEnabled(value));
        },
        onToggleHaptics: (value) {
          unawaited(GameFeedback.setHapticsEnabled(value));
        },
      ),
    );
  }

  void _debugSelectStage(int index) {
    if (_isAnimatingShot || index < 0 || index >= levels.length) {
      return;
    }
    setState(() => _unlockedLevel = levels.length - 1);
    _selectLevel(index);
  }

  Future<void> _debugResetProgress() async {
    if (widget.progressPersistencePolicy ==
        GameProgressPersistencePolicy.disabled) {
      return;
    }
    try {
      await _progressStore.reset();
    } on Object {
      if (mounted) {
        _setState(_state.copyWith(message: '진행 초기화를 저장하지 못했습니다. 다시 시도해 주세요.'));
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _unlockedLevel = 0);
    _selectLevel(0);
  }

  Future<void> _debugUnlockAll() async {
    if (widget.progressPersistencePolicy ==
        GameProgressPersistencePolicy.disabled) {
      return;
    }
    try {
      await _progressStore.unlockAll();
    } on Object {
      if (mounted) {
        _setState(
          _state.copyWith(message: '전체 단계 해금을 저장하지 못했습니다. 다시 시도해 주세요.'),
        );
      }
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _unlockedLevel = levels.length - 1);
  }

  Future<void> _debugSetCopyCore(int count) async {
    if (widget.progressPersistencePolicy ==
        GameProgressPersistencePolicy.disabled) {
      return;
    }
    final normalized = count.clamp(0, 999);
    try {
      await _progressStore.recordCopyCore(normalized, normalized > 0);
    } on Object {
      if (mounted) {
        _setState(
          _state.copyWith(message: '복제 코어 설정을 저장하지 못했습니다. 다시 시도해 주세요.'),
        );
      }
      return;
    }
    if (!mounted) return;
    _setState(
      _state.copyWith(
        copyCoreCount: normalized,
        copyCharges: normalized,
        copyChargeLimit: math.max(_state.copyChargeLimit, normalized),
        message: '복제 코어 $normalized개를 설정했습니다.',
      ),
    );
  }

  void _debugForceTrait(String sourceId) {
    if (_isAnimatingShot) {
      return;
    }
    final source = _state.entityById(sourceId);
    if (source == null || source.traits.isEmpty) {
      return;
    }
    _selectTraitSource(sourceId);
    _transferTrait();
  }

  void _debugRemoveTrait(String sourceId) {
    if (_isAnimatingShot || _state.entityById(sourceId) == null) {
      return;
    }
    _setState(
      _state.copyWith(
        entities: [
          for (final entity in _state.entities)
            entity.id == sourceId
                ? entity.copyWith(
                    drainedTraits: {...entity.drainedTraits, ...entity.traits},
                    traits: const {},
                    visualState: 'drained',
                  )
                : entity,
        ],
        clearSelection: true,
        message: '${debugEntityLabel(sourceId)} 원본 속성을 제거했습니다.',
      ),
    );
  }

  void _debugRestoreTrait(String sourceId) {
    if (_isAnimatingShot) {
      return;
    }
    final base = _currentLevel
        .createState(_state.levelIndex)
        .entityById(sourceId);
    if (base == null) {
      return;
    }
    _setState(
      _state.copyWith(
        entities: [
          for (final entity in _state.entities)
            entity.id == sourceId
                ? entity.copyWith(
                    traits: base.traits,
                    drainedTraits: const {},
                    visualState: base.visualState,
                  )
                : entity,
        ],
        clearSelection: true,
        message: '${debugEntityLabel(sourceId)} 원본 속성을 복원했습니다.',
      ),
    );
  }

  void _debugPlayReplay() {
    final start = _debugReplayStartState;
    final input = _debugReplayInput;
    if (_isAnimatingShot || start == null || input == null) {
      return;
    }
    _stageShotResults
      ..clear()
      ..addAll(_debugReplayPriorShotResults);
    _bonusBumperHit = _debugReplayPriorBumperHit;
    _bonusSwitchPressed = _debugReplayPriorSwitchPressed;
    _bonusDrainedSourceMoved = _debugReplayPriorDrainedSourceMoved;
    _bonusBumperHistory
      ..clear()
      ..addAll(_debugReplayPriorBumperHistory);
    _bonusSwitchHistory
      ..clear()
      ..addAll(_debugReplayPriorSwitchHistory);
    _bonusDrainedSourceHistory
      ..clear()
      ..addAll(_debugReplayPriorDrainedHistory);
    _chainScoreAnalysis = null;
    _setState(start.copyWith(message: '저장한 리플레이를 재생합니다.'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _launch(inputOverride: input, isReplay: true);
      }
    });
  }

  void _copyDebugState() {
    final payload = {
      '단계': _state.levelIndex + 1,
      '상태': debugPhaseLabel(_state.phase.name),
      '발사횟수': _state.shotCount,
      '공': {
        '위치': _state.activeBall.position.toJson(),
        '속성': _state.activeBall.traits.map((trait) => trait.label).toList(),
      },
      '물체': [
        for (final entity in _state.entities)
          {
            '이름': debugEntityLabel(entity.id),
            '종류': debugEntityTypeLabel(entity.type.name),
            '위치': entity.position.toJson(),
            '속성': entity.traits.map((trait) => trait.label).toList(),
            '활성': entity.active,
          },
      ],
    };
    Clipboard.setData(ClipboardData(text: jsonEncode(payload)));
  }

  void _copyDebugEvents() {
    final payload = [
      for (final event in _debugPhysicsEvents)
        {
          '사건번호': event.eventId,
          '사건종류': debugPhysicsEventLabel(event.kind.name),
          '출발물체': debugEntityLabel(event.sourceEntityId),
          '대상물체': debugEntityLabel(event.targetEntityId),
          '위치': event.position.toJson(),
          '충돌방향': event.normal.toJson(),
          '경로순서': event.pathIndex,
          '충격량': event.impulse,
        },
    ];
    Clipboard.setData(ClipboardData(text: jsonEncode(payload)));
  }

  void _copyInputLatencyReport() {
    Clipboard.setData(
      ClipboardData(text: _telemetry.exportInputLatencyReportJson()),
    );
  }

  void _copyFramePerformanceReport() {
    Clipboard.setData(
      ClipboardData(text: _framePerformance.exportReportJson()),
    );
  }

  void _rewind() {
    unawaited(_rewindAfterPersist());
  }

  Future<void> _rewindAfterPersist({
    String? resultMessage,
    String telemetryResult = '되감기',
  }) async {
    if (_isAnimatingShot ||
        _isCommittingShot ||
        _isCommittingTraitAction ||
        _isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction) {
      return;
    }
    _isCommittingRewind = true;
    try {
      if (_state.history.isNotEmpty) {
        final acquiredRewards = await widget.onShotRewound?.call();
        if (acquiredRewards != null) {
          _acquiredRewards = Set.unmodifiable(acquiredRewards);
        }
      }
      if (!mounted) return;
      _showFailurePopup = false;
      _traitEffectFeedback = null;
      _setPreviousAimInput(null);
      _telemetry.record(
        '재시도',
        stage: _state.levelIndex,
        attempt: _state.shotCount + 1,
        result: telemetryResult,
        eventCode: 'retry_pressed',
      );
      if (_state.history.isNotEmpty) {
        _bonusBumperHit = _bonusBumperHistory.isEmpty
            ? false
            : _bonusBumperHistory.removeAt(0);
        _bonusSwitchPressed = _bonusSwitchHistory.isEmpty
            ? false
            : _bonusSwitchHistory.removeAt(0);
        _bonusDrainedSourceMoved = _bonusDrainedSourceHistory.isEmpty
            ? false
            : _bonusDrainedSourceHistory.removeAt(0);
        if (_stageShotResults.isNotEmpty) {
          _stageShotResults.removeLast();
        }
        if (_stageShotInputs.isNotEmpty) {
          _stageShotInputs.removeLast();
        }
        _chainScoreAnalysis = null;
      }
      final rewound = _withoutRecoveredPastBalls(_shotResolver.rewind(_state));
      _setState(
        resultMessage == null
            ? rewound
            : rewound.copyWith(message: resultMessage),
      );
    } on Object {
      if (mounted) {
        _setState(_state.copyWith(message: '되감기 기록을 저장하지 못했습니다. 다시 시도해 주세요.'));
      }
    } finally {
      _isCommittingRewind = false;
    }
  }

  void _togglePause() {
    if (_isAnimatingShot) {
      return;
    }
    if (_state.phase == GamePhase.paused) {
      _feedback.paused(false);
      _setState(
        _state.copyWith(phase: GamePhase.planning, message: '계획을 계속하세요.'),
      );
    } else if (_state.phase == GamePhase.planning) {
      _feedback.paused(true);
      _setState(_state.copyWith(phase: GamePhase.paused, message: '일시정지'));
    }
  }

  void _updateAim(Vec2 logical) {
    if (!_shotResolver.canLaunch(_state) || _isAnimatingShot) {
      return;
    }
    final aim = logical - _state.activeBall.position;
    final aimWasStarted = _aimStartedForShot;
    if (!aimWasStarted) {
      _aimStartedForShot = true;
      _recordTyped(PlayTelemetryEventType.aimStarted);
    }
    final quantizedAim = quantizeAimDirection(aim);
    _pendingLaunchDirection = aim.length == 0
        ? _state.aimDirection.normalized()
        : aim.normalized();
    // Pointer move는 1도 bucket 안에서 수십 번 들어올 수 있다. 실제 발사에는
    // 위의 정밀 방향을 보존하되, 표시·예측·telemetry는 bucket이 바뀔 때만
    // 갱신해 전체 GameScreen rebuild와 중복 ShotResolver 실행을 막는다.
    if (aimWasStarted && quantizedAim == _state.aimDirection) {
      return;
    }
    final guidedImpactLabel = _previewFirstImpact(
      _pendingLaunchDirection ?? quantizedAim,
      _state.aimPower,
    );
    _guidedImpactLabel = guidedImpactLabel;
    _telemetry.record(
      '조준 방향 변경',
      stage: _state.levelIndex,
      eventCode: 'aim_direction_changed',
      angle: math.atan2(quantizedAim.y, quantizedAim.x),
    );
    _setState(
      _state.copyWith(
        aimDirection: quantizedAim,
        message: guidedImpactLabel == null
            ? '방향 설정 완료 · 공을 길게 눌러 힘을 모으세요'
            : '첫 충돌 안내 · $guidedImpactLabel',
      ),
    );
  }

  void _nudgeAim(double radians) {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
      return;
    }
    final current = math.atan2(_state.aimDirection.y, _state.aimDirection.x);
    final next = current + radians;
    _aimStartedForShot = true;
    _pendingLaunchDirection = Vec2(math.cos(next), math.sin(next)).normalized();
    _setState(
      _state.copyWith(
        aimDirection: Vec2(math.cos(next), math.sin(next)),
        message: '접근성 조준 방향 조정',
      ),
    );
  }

  void _adjustPower(double delta) {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
      return;
    }
    final nextPower = (_state.aimPower + delta).clamp(0.12, 1.0);
    _setState(
      _state.copyWith(
        aimPower: nextPower,
        message: _guidedImpactLabel == null
            ? '힘 ${(nextPower * 100).round()}%'
            : '힘 ${(nextPower * 100).round()}% · 첫 충돌 $_guidedImpactLabel',
      ),
    );
  }

  void _syncFirstArrivalPreview({
    ShotInput? inputOverride,
    bool force = false,
  }) {
    if (_difficulty != PlayerDifficulty.easy ||
        !_aimStartedForShot ||
        _state.phase != GamePhase.planning ||
        _isAnimatingShot) {
      _clearFirstArrivalPreview();
      return;
    }
    final input =
        inputOverride ??
        ShotInput(
          direction: _pendingLaunchDirection ?? _state.aimDirection,
          power: _state.aimPower,
          equippedTrait: _state.equippedTrait,
        );
    final normalizedInput = input.normalized();
    final directionBucket = quantizeAimDirection(normalizedInput.direction);
    final powerBucket = (normalizedInput.power * 100).round();
    if (!force &&
        identical(_firstArrivalEntities, _state.entities) &&
        _firstArrivalShotCount == _state.shotCount &&
        _firstArrivalDirection == directionBucket &&
        _firstArrivalPowerBucket == powerBucket &&
        _firstArrivalTrait == _state.equippedTrait) {
      return;
    }
    final preview = _shotResolver.firstArrivalFromResult(
      _previewShotResult(normalizedInput),
    );
    _firstArrivalPreview = preview;
    _firstArrivalInputSnapshot = normalizedInput;
    _firstArrivalEntities = _state.entities;
    _firstArrivalShotCount = _state.shotCount;
    _firstArrivalDirection = directionBucket;
    _firstArrivalPowerBucket = powerBucket;
    _firstArrivalTrait = _state.equippedTrait;
    _game.setFirstArrivalPreview(preview);
  }

  ShotResult _previewShotResult(ShotInput normalizedInput) {
    if (identical(_previewResultEntities, _state.entities) &&
        _previewResultShotCount == _state.shotCount &&
        _previewResultDirection == normalizedInput.direction &&
        _previewResultPower == normalizedInput.power &&
        _previewResultTrait == normalizedInput.equippedTrait &&
        _previewResultHoleForgivenessRadius ==
            normalizedInput.holeForgivenessRadius &&
        _previewResult != null) {
      return _previewResult!;
    }
    final result = _shotResolver.resolve(_state, normalizedInput);
    _previewResultEntities = _state.entities;
    _previewResultShotCount = _state.shotCount;
    _previewResultDirection = normalizedInput.direction;
    _previewResultPower = normalizedInput.power;
    _previewResultTrait = normalizedInput.equippedTrait;
    _previewResultHoleForgivenessRadius = normalizedInput.holeForgivenessRadius;
    _previewResult = result;
    return result;
  }

  void _clearFirstArrivalPreview() {
    if (_firstArrivalPreview == null) return;
    _firstArrivalPreview = null;
    _firstArrivalInputSnapshot = null;
    _firstArrivalEntities = null;
    _firstArrivalShotCount = null;
    _firstArrivalDirection = null;
    _firstArrivalPowerBucket = null;
    _firstArrivalTrait = null;
    _game.setFirstArrivalPreview(null);
  }

  String? get _firstArrivalSemanticsValue {
    final preview = _firstArrivalPreview;
    if (preview == null) return null;
    final destination = switch (preview.kind) {
      FirstArrivalKind.hole => '홀',
      FirstArrivalKind.powerSlider => '파워 슬라이더',
      FirstArrivalKind.impact => '첫 충돌',
      FirstArrivalKind.rangeEnd => '사거리 끝',
    };
    return '쉬움 모드, 예상 첫 도착 $destination';
  }

  void _handleSemanticEntity(String entityId) {
    if (_isAnimatingShot) {
      return;
    }
    if (entityId == _state.activeBall.id) {
      _recordInspection(_state.activeBall);
      setState(() {
        _showBallInfo = true;
        _inspectedEntityId = null;
      });
      return;
    }
    final entity = _state.entityById(entityId);
    if (entity == null || !entity.active) {
      return;
    }
    _recordInspection(entity);
    if (entity.type != EntityType.ball && entity.traits.isNotEmpty) {
      _selectTraitSource(entity.id);
    }
    setState(() {
      _showBallInfo = false;
      _inspectedEntityId = entity.id;
    });
  }

  String _semanticEntityLabel(EntityState entity) {
    if (_isHiddenMechanic(entity)) {
      return '미스터리 상자, 조건 달성 전';
    }
    final name = _entityName(entity);
    final state = switch (entity.type) {
      EntityType.ball =>
        entity.id == 'active_ball'
            ? entity.traits.isEmpty
                  ? '현재 속성 없음'
                  : '${entity.traits.first.label} 속성 보유'
            : _ballStatusLabel(entity),
      EntityType.hole => '목표 홀',
      EntityType.switchPad => entity.pressed ? '눌림' : '누르기 전',
      EntityType.gate => entity.open ? '열림' : '닫힘',
      EntityType.balloon => entity.visualState == 'popped' ? '터짐' : '풍선',
      EntityType.spikeSource => '뾰족함 공급 물체',
      EntityType.powerSlider => '기준 속력 · 진행 방향 유지 · 접촉 중 한 번',
      EntityType.rotatingReflector => '충돌 방향 반사 · 다음 충돌부터 90도 방향 변경',
      EntityType.wall => '움직이지 않는 장애물',
      _ =>
        entity.traits.isEmpty
            ? '상호작용 가능한 물체'
            : '${entity.traits.first.label} 속성 보유',
    };
    return '$name, $state';
  }

  List<EntityState> get _semanticEntities {
    return _playerVisibleState.entities;
  }

  GameState get _playerVisibleState =>
      _isAnimatingShot && _semanticAnimationStartState != null
      ? _semanticAnimationStartState!
      : _state;

  Vec2 _toLogicalPosition(Offset localPosition, Size fieldSize) {
    final scale =
        (fieldSize.width / logicalSize.x < fieldSize.height / logicalSize.y)
        ? fieldSize.width / logicalSize.x
        : fieldSize.height / logicalSize.y;
    final origin = Offset(
      (fieldSize.width - logicalSize.x * scale) / 2,
      (fieldSize.height - logicalSize.y * scale) / 2,
    );
    final projectedX = (localPosition.dx - origin.dx) / scale;
    final projectedY = (localPosition.dy - origin.dy) / scale;
    return Vec2(projectedX, projectedY);
  }

  bool _entityContainsTap(EntityState entity, Vec2 logical) {
    if (entity.isCircle) {
      return logical.distanceTo(entity.position) <= entity.radius + 10;
    }
    if (!entity.isRotatingReflector) {
      return entity.bounds.intersectsCircle(logical, 10);
    }
    final axes = _reflectorAxes(entity);
    final delta = logical - entity.position;
    return delta.dot(axes.tangent).abs() <= entity.size.x / 2 + 10 &&
        delta.dot(axes.normal).abs() <= entity.size.y / 2 + 10;
  }

  Rect _semanticEntityRect(EntityState entity, double scale) {
    var logicalWidth = entity.size.x;
    var logicalHeight = entity.size.y;
    if (entity.isRotatingReflector) {
      final axes = _reflectorAxes(entity);
      final halfTangent = entity.size.x / 2;
      final halfNormal = entity.size.y / 2;
      logicalWidth =
          2 *
          (axes.tangent.x.abs() * halfTangent +
              axes.normal.x.abs() * halfNormal);
      logicalHeight =
          2 *
          (axes.tangent.y.abs() * halfTangent +
              axes.normal.y.abs() * halfNormal);
    }
    return Rect.fromCenter(
      center: Offset(entity.position.x * scale, entity.position.y * scale),
      width: math.max(44, logicalWidth * scale),
      height: math.max(44, logicalHeight * scale),
    );
  }

  ({Vec2 tangent, Vec2 normal}) _reflectorAxes(EntityState entity) {
    final angle = -math.pi / 2 + entity.reflectorOrientation * math.pi / 4;
    final normal = Vec2(math.cos(angle), math.sin(angle));
    return (tangent: Vec2(-normal.y, normal.x), normal: normal);
  }

  void _dismissInfo() {
    if (_showBallInfo || _inspectedEntityId != null) {
      _telemetry.record(
        '속성 행동 취소',
        stage: _state.levelIndex,
        target: _inspectedEntityId ?? _state.activeBall.id,
        result: '정보 팝업 닫기',
        eventCode: 'attribute_action_cancelled',
      );
    }
    setState(() {
      _showBallInfo = false;
      _inspectedEntityId = null;
    });
  }

  void _handleSystemBack() {
    if (_showBallInfo || _inspectedEntityId != null) {
      _dismissInfo();
      return;
    }
    if (_showClearPopup) {
      _showClearPopup = false;
      _setState(
        _state.copyWith(phase: GamePhase.planning, message: '다시 조준할 수 있습니다.'),
      );
      return;
    }
    if (_showFailurePopup) {
      setState(() {
        _showFailurePopup = false;
      });
    }
  }

  void _exitStage() {
    if (widget.onExit == null) {
      return;
    }
    _telemetry.record(
      '단계 종료',
      stage: _state.levelIndex,
      result: '섬 지도 복귀',
      eventCode: 'stage_exit',
    );
    _recordTyped(
      PlayTelemetryEventType.stageAbandoned,
      result: PlayTelemetryResult.abandoned,
    );
    widget.onExit!();
  }

  Future<void> _confirmExitStage() async {
    if (widget.onExit == null || !mounted) return;
    final destination =
        widget.exitTooltipOverride ??
        (widget.exitToMainMenu ? '메인 메뉴' : '섬 지도');
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        key: const Key('stage_abandon_dialog'),
        title: const Text('이 스테이지를 포기할까요?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            '현재 시도는 여기서 끝나고 $destination로 돌아갑니다. '
            '이미 저장된 발견과 보상은 사라지지 않아요.',
          ),
        ),
        actions: [
          TextButton(
            key: const Key('stage_abandon_cancel_button'),
            autofocus: true,
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('계속 도전'),
          ),
          FilledButton.tonal(
            key: const Key('stage_abandon_confirm_button'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('포기하고 나가기'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) _exitStage();
  }

  void _recordHintExposureIfNeeded() {
    final target = _tutorialTarget;
    final visible = target != null;
    if (visible && !_hintWasVisible) {
      _telemetry.record(
        '힌트 노출',
        stage: _state.levelIndex,
        target: target.id,
        result: _tutorialHint,
        eventCode: 'hint_exposed',
        objectId: target.id,
        objectType: target.type.name,
      );
    }
    _hintWasVisible = visible;
  }

  void _handleFieldTap(Offset localPosition, Size fieldSize) {
    if (_isAnimatingShot) {
      return;
    }
    final logical = _toLogicalPosition(localPosition, fieldSize);
    if (logical.distanceTo(_state.activeBall.position) <= 34) {
      _recordInspection(_state.activeBall);
      setState(() {
        _showBallInfo = true;
        _inspectedEntityId = null;
      });
      return;
    }
    for (final entity in _state.entities) {
      if (entity.id == _state.activeBall.id || !entity.active) {
        continue;
      }
      final hit = _entityContainsTap(entity, logical);
      if (hit) {
        _recordInspection(entity);
        if (entity.type != EntityType.ball && entity.traits.isNotEmpty) {
          _selectTraitSource(entity.id);
        }
        setState(() {
          _showBallInfo = false;
          _inspectedEntityId = entity.id;
        });
        return;
      }
    }
    setState(() {
      _showBallInfo = false;
      _inspectedEntityId = null;
    });
  }

  void _recordInspection(EntityState entity) {
    final trait = entity.traits.isEmpty ? null : entity.traits.first;
    _telemetry.record(
      '속성 확인',
      stage: _state.levelIndex,
      target: entity.id,
      result: trait?.label ?? _entityName(entity),
      objectId: entity.id,
      objectType: entity.type.name,
      trait: trait?.label,
    );
    _recordTyped(PlayTelemetryEventType.propertyPopupOpened);
    if (trait != null) {
      _telemetry.record(
        '속성 이전 열기',
        stage: _state.levelIndex,
        target: entity.id,
        result: trait.label,
        objectId: entity.id,
        objectType: entity.type.name,
        attributeBefore: trait.label,
      );
    }
  }

  Duration _currentMonotonicTimeStamp() {
    final frameTimeStamp =
        SchedulerBinding.instance.currentSystemFrameTimeStamp;
    final lastPointerTimeStamp = _lastPointerTimeStamp;
    final frameAtPointer = _frameTimeStampAtLastPointer;
    if (lastPointerTimeStamp == null || frameAtPointer == null) {
      return frameTimeStamp;
    }
    final frameElapsed = frameTimeStamp - frameAtPointer;
    if (frameElapsed.isNegative) {
      return lastPointerTimeStamp;
    }
    return lastPointerTimeStamp + frameElapsed;
  }

  Duration _effectivePointerTimeStamp(Duration eventTimeStamp) {
    final lastPointerTimeStamp = _lastPointerTimeStamp;
    if (lastPointerTimeStamp != null && eventTimeStamp < lastPointerTimeStamp) {
      return lastPointerTimeStamp;
    }
    return eventTimeStamp;
  }

  void _handlePointerDown(
    int pointer,
    Offset localPosition,
    Size fieldSize,
    Duration timeStamp,
  ) {
    _aimFocusNode.requestFocus();
    if (!_shotResolver.canLaunch(_state) ||
        _isAnimatingShot ||
        _isCommittingShot ||
        _isCommittingTraitAction ||
        _isCommittingRewardAction ||
        _isCommittingRewind ||
        _isCommittingStageAction) {
      return;
    }
    timeStamp = _effectivePointerTimeStamp(timeStamp);
    final logical = _toLogicalPosition(localPosition, fieldSize);
    final onBall = logical.distanceTo(_state.activeBall.position) <= 42;
    _launchInputSession.chargeRateScale =
        _rewardInventory.precisionChargeEnabled ? 0.75 : 1.0;
    if (!_launchInputSession.begin(
      pointer: pointer,
      logicalPosition: logical,
      timeStamp: timeStamp,
      onBall: onBall,
    )) {
      return;
    }
    _chargeFeedbackTimer?.cancel();
    _chargeFeedbackTimer = null;
    _lastPointerTimeStamp = timeStamp;
    _frameTimeStampAtLastPointer =
        SchedulerBinding.instance.currentSystemFrameTimeStamp;
    _pressActivationTimer?.cancel();
    _chargeStartRecorded = false;
    _overchargeFeedbackRecorded = false;
    _setChargeGauge(ChargeGaugeState.green, active: false);
    if (onBall) {
      _setState(_state.copyWith(message: '공을 길게 눌러 힘을 모으세요'));
      _pressActivationTimer = Timer(const Duration(milliseconds: 450), () {
        if (!mounted || !_launchInputSession.isActive) {
          return;
        }
        _startPowerCharge();
      });
    }
  }

  void _handlePointerMove(
    int pointer,
    Offset localPosition,
    Size fieldSize,
    Duration timeStamp,
  ) {
    if (pointer != _launchInputSession.activePointer) {
      return;
    }
    if (_isAnimatingShot) {
      return;
    }
    timeStamp = _effectivePointerTimeStamp(timeStamp);
    final logical = _toLogicalPosition(localPosition, fieldSize);
    _lastPointerTimeStamp = timeStamp;
    _frameTimeStampAtLastPointer =
        SchedulerBinding.instance.currentSystemFrameTimeStamp;
    if (!_launchInputSession.move(
      pointer: pointer,
      logicalPosition: logical,
      timeStamp: timeStamp,
    )) {
      return;
    }
    if (_launchInputSession.isChargingAt(timeStamp)) {
      if (!_isCharging) {
        _startPowerCharge();
      }
      _setChargeGauge(
        _launchInputSession.gaugeStateAt(timeStamp),
        active: true,
      );
    } else if (!_isCharging && _launchInputSession.chargeCancelled) {
      _pressActivationTimer?.cancel();
      _pressActivationTimer = null;
      _setChargeGauge(ChargeGaugeState.green, active: false);
    }
    _updateAim(logical);
  }

  void _handlePointerUp(
    int pointer,
    Offset localPosition,
    Size fieldSize,
    Duration timeStamp,
  ) {
    if (pointer != _launchInputSession.activePointer) {
      return;
    }
    final inputReleasedAt = _launchInputLatency.markRelease();
    timeStamp = _effectivePointerTimeStamp(timeStamp);
    _lastPointerTimeStamp = timeStamp;
    final logical = _toLogicalPosition(localPosition, fieldSize);
    final release = _launchInputSession.release(
      pointer: pointer,
      logicalPosition: logical,
      timeStamp: timeStamp,
    );
    _pressActivationTimer?.cancel();
    _pressActivationTimer = null;
    _chargeTimer?.cancel();
    _chargeTimer = null;
    _isCharging = false;
    final overchargeCancelled =
        release.kind == LaunchInputReleaseKind.overchargeCancelled;
    if (overchargeCancelled) {
      _showOverchargeFeedback();
      _chargeStartRecorded = false;
      _telemetry.record(
        '과충전 취소',
        stage: _state.levelIndex,
        eventCode: 'charge_cancelled_overcharge',
        power: LaunchInputSession.maximumPower,
      );
      _recordTyped(
        PlayTelemetryEventType.chargeCancelled,
        result: PlayTelemetryResult.cancelled,
      );
      _recordTyped(
        PlayTelemetryEventType.powerGaugeCancelled,
        powerGauge: PlayTelemetryPowerGaugePayload(
          chargeStage: _chargeGaugeState.index,
          power: _state.aimPower,
          cancelled: true,
        ),
      );
      if (mounted && _state.phase == GamePhase.planning) {
        _setState(
          _state.copyWith(message: '과충전되어 발사를 취소했습니다. 새로 눌러 다시 시작하세요.'),
        );
      }
      return;
    }
    _setChargeGauge(ChargeGaugeState.green, active: false);
    if (release.shouldLaunch) {
      final power = release.power ?? LaunchInputSession.minimumPower;
      if (!_chargeStartRecorded && release.chargeStartedAt != null) {
        _recordChargeStarted(release.chargeStartedAt!);
      }
      _telemetry.record(
        '충전 종료',
        stage: _state.levelIndex,
        eventCode: 'charge_released',
        power: power,
      );
      _chargeStartRecorded = false;
      final lastPosition = release.lastLogicalPosition;
      final aim = lastPosition == null
          ? _state.aimDirection
          : lastPosition - _state.activeBall.position;
      final direction = aim.length == 0
          ? _state.aimDirection
          : aim.normalized();
      final rawLaunchInput = ShotInput(
        direction: direction,
        power: power,
        equippedTrait: _state.equippedTrait,
      ).normalized();
      final decision = _intentAssistResolver.resolve(
        state: _state,
        rawInput: rawLaunchInput,
        strength: _intentAssistStrength,
        compactPointer: MediaQuery.sizeOf(context).shortestSide < 600,
        repeatedNearMisses: _repeatedNearMisses,
        policy: IntentAssistPolicy.forStage(_currentLevel.stageId),
      );
      var launchInput = decision.appliedInput;
      _pendingIntentAssistDecision = decision;
      if (decision.adjusted) {
        _telemetry.record(
          '조준 의도 보정',
          stage: _state.levelIndex,
          eventCode: 'intent_assist_applied',
          angle: math.atan2(launchInput.direction.y, launchInput.direction.x),
          power: launchInput.power,
          target: decision.targetEntityId,
          result:
              '각도 ${decision.angleDeltaDegrees.toStringAsFixed(2)}도 · '
              '힘 ${(decision.powerDelta * 100).toStringAsFixed(1)}% · '
              '${decision.targetKind?.name ?? 'stabilized'} '
              '${(decision.confidence * 100).toStringAsFixed(0)}%',
        );
      }
      if (_difficulty == PlayerDifficulty.easy) {
        _syncFirstArrivalPreview(inputOverride: launchInput, force: true);
        launchInput = _firstArrivalInputSnapshot ?? launchInput;
      }
      _launch(inputOverride: launchInput, inputReleasedAt: inputReleasedAt);
      return;
    }
    if (release.kind == LaunchInputReleaseKind.tap) {
      _handleFieldTap(localPosition, fieldSize);
    } else if (_state.phase == GamePhase.planning && !_isAnimatingShot) {
      _setState(
        _state.copyWith(
          message: _guidedImpactLabel == null
              ? '조준 고정'
              : '첫 충돌 안내 · $_guidedImpactLabel',
        ),
      );
    }
  }

  void _handlePointerCancel({bool showCancellation = true, int? pointer}) {
    if (pointer != null && pointer != _launchInputSession.activePointer) {
      return;
    }
    final hadPointer = _launchInputSession.isActive;
    _pressActivationTimer?.cancel();
    _pressActivationTimer = null;
    _chargeTimer?.cancel();
    _chargeTimer = null;
    _launchInputSession.cancel(pointer: pointer);
    final wasCharging = _isCharging;
    final cancelledGaugeStage = _chargeGaugeState.index;
    _isCharging = false;
    _chargeStartRecorded = false;
    _setChargeGauge(ChargeGaugeState.green, active: false);
    if (wasCharging) {
      _recordTyped(
        PlayTelemetryEventType.chargeCancelled,
        result: PlayTelemetryResult.cancelled,
      );
      _recordTyped(
        PlayTelemetryEventType.powerGaugeCancelled,
        powerGauge: PlayTelemetryPowerGaugePayload(
          chargeStage: cancelledGaugeStage,
          power: _state.aimPower,
          cancelled: true,
        ),
      );
      if (showCancellation) {
        _feedback.cancelled();
      }
      if (mounted && showCancellation && _state.phase == GamePhase.planning) {
        _setState(_state.copyWith(message: '발사를 취소했습니다'));
      }
    } else if (hadPointer &&
        showCancellation &&
        _state.phase == GamePhase.planning) {
      _setState(_state.copyWith(message: '발사를 취소했습니다'));
    }
  }

  void _recordChargeStarted(Duration timeStamp) {
    if (_chargeStartRecorded) {
      return;
    }
    _chargeStartRecorded = true;
    _feedback.aimChargeStarted();
    _telemetry.record(
      '충전 시작',
      stage: _state.levelIndex,
      eventCode: 'charge_started',
      power: LaunchInputSession.minimumPower,
    );
    _recordTyped(
      PlayTelemetryEventType.powerGaugeChargeStarted,
      powerGauge: PlayTelemetryPowerGaugePayload(
        chargeStage: 0,
        power: LaunchInputSession.minimumPower,
        cancelled: false,
      ),
    );
  }

  void _startPowerCharge() {
    if (_state.phase != GamePhase.planning ||
        _isAnimatingShot ||
        !_launchInputSession.isActive) {
      return;
    }
    final chargeStartedAt = _launchInputSession.chargeStartedAt;
    if (chargeStartedAt == null) {
      return;
    }
    final timeStamp =
        _currentMonotonicTimeStamp().compareTo(chargeStartedAt) < 0
        ? chargeStartedAt
        : _currentMonotonicTimeStamp();
    if (!_launchInputSession.isChargingAt(timeStamp)) {
      return;
    }
    _pressActivationTimer?.cancel();
    _pressActivationTimer = null;
    _isCharging = true;
    _recordChargeStarted(chargeStartedAt);
    final initialGaugeState = _launchInputSession.gaugeStateAt(timeStamp);
    _setChargeGauge(initialGaugeState, active: true);
    _setState(
      _state.copyWith(
        aimPower: _launchInputSession.powerAt(timeStamp),
        message: _chargeMessageWithImpactGuide(
          initialGaugeState,
          _launchInputSession.powerAt(timeStamp),
        ),
      ),
    );
    _chargeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted ||
          !_isCharging ||
          !_launchInputSession.isActive ||
          _launchInputSession.chargeStartedAt == null) {
        return;
      }
      final displayTimeStamp = _currentMonotonicTimeStamp();
      final nextPower = _launchInputSession.powerAt(displayTimeStamp);
      final nextGaugeState = _launchInputSession.gaugeStateAt(displayTimeStamp);
      _setChargeGauge(nextGaugeState, active: true);
      _setState(
        _state.copyWith(
          aimPower: nextPower,
          message: _chargeMessageWithImpactGuide(nextGaugeState, nextPower),
        ),
      );
    });
  }

  @override
  void didChangeMetrics() {
    if (_launchInputSession.isActive) {
      _handlePointerCancel(showCancellation: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _handlePointerCancel(showCancellation: false);
    }
  }

  @override
  void dispose() {
    _framePerformance.stop();
    _telemetry.sessionEnd(stage: _state.levelIndex);
    unawaited(_telemetry.close());
    WidgetsBinding.instance.removeObserver(this);
    _chargeTimer?.cancel();
    _pressActivationTimer?.cancel();
    _chargeFeedbackTimer?.cancel();
    _keyCollectionVfxTimer?.cancel();
    _traitTransferFeedbackTimer?.cancel();
    _launchInputSession.reset();
    _aimFocusNode.dispose();
    super.dispose();
  }

  void _resetChargeGauge() {
    _chargeFeedbackTimer?.cancel();
    _chargeFeedbackTimer = null;
    _chargeGaugeState = ChargeGaugeState.green;
    _chargeGaugeActive = false;
    _overchargeFeedbackRecorded = false;
  }

  void _showOverchargeFeedback() {
    _chargeFeedbackTimer?.cancel();
    _setChargeGauge(ChargeGaugeState.cancelledGray, active: true);
    _chargeFeedbackTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _launchInputSession.isActive) return;
      _chargeFeedbackTimer = null;
      _setChargeGauge(ChargeGaugeState.green, active: false);
    });
  }

  void _setChargeGauge(ChargeGaugeState next, {required bool active}) {
    final changed = _chargeGaugeState != next || _chargeGaugeActive != active;
    _chargeGaugeState = next;
    _chargeGaugeActive = active;
    if (changed && active) {
      _recordTyped(PlayTelemetryEventType.chargeStageChanged);
    }
    if (next == ChargeGaugeState.cancelledGray &&
        !_overchargeFeedbackRecorded) {
      _overchargeFeedbackRecorded = true;
      _feedback.overchargeCancelled();
    }
    if (changed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerVisibleState = _playerVisibleState;
    final inspectedEntity = _inspectedEntityId == null
        ? null
        : _state.entityById(_inspectedEntityId!);
    final clearPopupOpen = _state.phase == GamePhase.success && _showClearPopup;
    final failurePopupOpen =
        _showFailurePopup && !_showBallInfo && inspectedEntity == null;
    final persistentTutorialHint = widget.showTutorialFailureHints
        ? persistentTutorialHintFor(
            levelIndex: _state.levelIndex,
            failedShots: _state.phase == GamePhase.success
                ? 0
                : _state.shotCount,
          )
        : null;
    final persistenceErrorOpen = _showClearPersistenceError;
    final popupOpen =
        _showBallInfo ||
        inspectedEntity != null ||
        failurePopupOpen ||
        persistenceErrorOpen ||
        clearPopupOpen;
    final tutorialTarget = _tutorialTarget;
    final inputBlocked = popupOpen || _isAnimatingShot;
    return PopScope<void>(
      canPop: !popupOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && popupOpen) {
          _handleSystemBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFBFE8E3),
        appBar: widget.showStageSelector
            ? AppBar(
                title: const Text('속성 한방'),
                backgroundColor: const Color(0xFF24352D),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    key: const Key('pause_button'),
                    tooltip: _state.phase == GamePhase.paused ? '계속' : '멈춤',
                    onPressed: popupOpen ? null : _togglePause,
                    icon: Icon(
                      _state.phase == GamePhase.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                    ),
                  ),
                ],
              )
            : null,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, safeConstraints) {
              // `SafeArea` 이후의 실제 제약을 기준으로만 HUD와 월드를
              // 배치한다. 전체 MediaQuery 높이를 다시 강제하면 홈 인디케이터
              // 또는 브라우저 하단 영역에서 보드와 제어 패널이 잘릴 수 있다.
              final safeSize = safeConstraints.biggest;
              final compactLayout =
                  safeSize.width <= 800 || safeSize.height < 700;
              // 320x568급은 제어 정보를 한 줄로 줄이되, 기물을 가리지 않도록
              // 보드 밖 Safe bottom interaction band를 계속 사용한다.
              final denseCompact = safeSize.height < 600;
              // 넓은 화면에서는 HUD가 세로 보드 폭(760px)에 묶이면 제목과
              // 상태 아이콘이 서로 밀어낸다. 보드는 기존 비율로 가운데 두되
              // 정보 영역은 일반 PC·대형 모니터에서 충분한 가로 폭을 쓴다.
              final contentWidth = compactLayout
                  ? safeSize.width
                  : math.min(safeSize.width * 0.86, 1120.0);
              return Stack(
                children: [
                  const Positioned.fill(child: _GameplayBackdrop()),
                  ExcludeFocus(
                    excluding: inputBlocked,
                    child: AbsorbPointer(
                      absorbing: inputBlocked,
                      child: ExcludeSemantics(
                        excluding: inputBlocked,
                        child: Center(
                          child: SizedBox(
                            width: contentWidth,
                            height: safeSize.height,
                            child: Column(
                              children: [
                                if (!compactLayout)
                                  _Hud(
                                    tutorialActive: tutorialTarget != null,
                                    state: playerVisibleState,
                                    discoveryMilestones: _discoveryMilestones,
                                    rewardGuide: _stageRewardGuide,
                                    unlockedLevel: _unlockedLevel,
                                    onSelectLevel: _selectLevel,
                                    showStageSelector: widget.showStageSelector,
                                    onPause: _togglePause,
                                    onExit: widget.onExit == null
                                        ? null
                                        : _confirmExitStage,
                                    exitToMainMenu: widget.exitToMainMenu,
                                    hudScore: widget.hudScore,
                                    onDebug: widget.showDebugControls
                                        ? _openDebugMenu
                                        : null,
                                    objectiveOverride: widget.objectiveOverride,
                                    showDiscovery: widget.showDiscoveryHud,
                                    exitTooltipOverride:
                                        widget.exitTooltipOverride,
                                    hintAvailable: _hintAvailable,
                                    hintVisible: _patternHintEntry != null,
                                    hintKeyAvailable:
                                        _currentHintKey != null &&
                                        !_collectedHintKeyIds.contains(
                                          _currentHintKey!.id,
                                        ),
                                    onHint: _patternHintEntry == null
                                        ? null
                                        : _hintAvailable
                                        ? _showPatternHintSheet
                                        : null,
                                  ),
                                if (compactLayout)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      6,
                                      6,
                                      6,
                                      0,
                                    ),
                                    child: _Hud(
                                      compact: true,
                                      dense: denseCompact,
                                      tutorialActive: tutorialTarget != null,
                                      state: playerVisibleState,
                                      discoveryMilestones: _discoveryMilestones,
                                      rewardGuide: _stageRewardGuide,
                                      unlockedLevel: _unlockedLevel,
                                      onSelectLevel: _selectLevel,
                                      showStageSelector:
                                          widget.showStageSelector,
                                      onPause: _togglePause,
                                      onExit: widget.onExit == null
                                          ? null
                                          : _confirmExitStage,
                                      exitToMainMenu: widget.exitToMainMenu,
                                      hudScore: widget.hudScore,
                                      onDebug: widget.showDebugControls
                                          ? _openDebugMenu
                                          : null,
                                      objectiveOverride:
                                          widget.objectiveOverride,
                                      showDiscovery: widget.showDiscoveryHud,
                                      exitTooltipOverride:
                                          widget.exitTooltipOverride,
                                      hintAvailable: _hintAvailable,
                                      hintVisible: _patternHintEntry != null,
                                      hintKeyAvailable:
                                          _currentHintKey != null &&
                                          !_collectedHintKeyIds.contains(
                                            _currentHintKey!.id,
                                          ),
                                      onHint: _patternHintEntry == null
                                          ? null
                                          : _hintAvailable
                                          ? _showPatternHintSheet
                                          : null,
                                    ),
                                  ),
                                if (persistentTutorialHint != null)
                                  PersistentTutorialHintCard(
                                    text: persistentTutorialHint,
                                  ),
                                if (_traitTransferFeedback != null)
                                  TraitTransferRibbon(
                                    feedback: _traitTransferFeedback!,
                                  ),
                                Expanded(
                                  child: AbsorbPointer(
                                    absorbing: inputBlocked,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: compactLayout ? 0 : 12,
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          final semanticLaunch =
                                              CustomSemanticsAction(
                                                label: '공 발사',
                                              );
                                          final semanticAimRight =
                                              CustomSemanticsAction(
                                                label: '시계 방향으로 조준',
                                              );
                                          final semanticAimLeft =
                                              CustomSemanticsAction(
                                                label: '반시계 방향으로 조준',
                                              );
                                          final fieldSize = constraints.biggest;
                                          final scale = math.min(
                                            fieldSize.width / logicalSize.x,
                                            fieldSize.height / logicalSize.y,
                                          );
                                          final boardSize = Size(
                                            logicalSize.x * scale,
                                            logicalSize.y * scale,
                                          );
                                          return Align(
                                            alignment: Alignment.topCenter,
                                            child: SizedBox(
                                              width: boardSize.width,
                                              height: boardSize.height,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  Positioned(
                                                    left: 0,
                                                    top: 0,
                                                    width: boardSize.width,
                                                    height: boardSize.height,
                                                    child: Focus(
                                                      key: const Key(
                                                        'aim_keyboard_focus',
                                                      ),
                                                      onFocusChange: (focused) {
                                                        if (mounted) {
                                                          setState(
                                                            () => _aimHasFocus =
                                                                focused &&
                                                                FocusManager
                                                                        .instance
                                                                        .highlightMode ==
                                                                    FocusHighlightMode
                                                                        .traditional,
                                                          );
                                                        }
                                                      },
                                                      focusNode: _aimFocusNode,
                                                      onKeyEvent: (node, event) {
                                                        if (event
                                                                is KeyRepeatEvent ||
                                                            event
                                                                is! KeyDownEvent) {
                                                          return KeyEventResult
                                                              .ignored;
                                                        }
                                                        if (!_aimHasFocus &&
                                                            mounted) {
                                                          setState(
                                                            () => _aimHasFocus =
                                                                true,
                                                          );
                                                        }
                                                        final key =
                                                            event.logicalKey;
                                                        if (key ==
                                                            LogicalKeyboardKey
                                                                .arrowLeft) {
                                                          _nudgeAim(
                                                            -math.pi / 180,
                                                          );
                                                        } else if (key ==
                                                            LogicalKeyboardKey
                                                                .arrowRight) {
                                                          _nudgeAim(
                                                            math.pi / 180,
                                                          );
                                                        } else if (key ==
                                                                LogicalKeyboardKey
                                                                    .arrowUp ||
                                                            key ==
                                                                LogicalKeyboardKey
                                                                    .add ||
                                                            key ==
                                                                LogicalKeyboardKey
                                                                    .pageUp) {
                                                          _adjustPower(0.02);
                                                        } else if (key ==
                                                                LogicalKeyboardKey
                                                                    .arrowDown ||
                                                            key ==
                                                                LogicalKeyboardKey
                                                                    .minus ||
                                                            key ==
                                                                LogicalKeyboardKey
                                                                    .pageDown) {
                                                          _adjustPower(-0.02);
                                                        } else if (key ==
                                                            LogicalKeyboardKey
                                                                .space) {
                                                          _launch();
                                                        } else if (key ==
                                                                LogicalKeyboardKey
                                                                    .escape &&
                                                            _isCharging) {
                                                          _handlePointerCancel();
                                                        } else {
                                                          return KeyEventResult
                                                              .ignored;
                                                        }
                                                        return KeyEventResult
                                                            .handled;
                                                      },
                                                      child: DecoratedBox(
                                                        key: const Key(
                                                          'aim_focus_indicator',
                                                        ),
                                                        position:
                                                            DecorationPosition
                                                                .foreground,
                                                        decoration: BoxDecoration(
                                                          border: _aimHasFocus
                                                              ? Border.all(
                                                                  color: const Color(
                                                                    0xFF176B78,
                                                                  ),
                                                                  width: 3,
                                                                )
                                                              : null,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: Listener(
                                                          key: const Key(
                                                            'aim_area',
                                                          ),
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onPointerDown: (event) =>
                                                              _handlePointerDown(
                                                                event.pointer,
                                                                event
                                                                    .localPosition,
                                                                boardSize,
                                                                event.timeStamp,
                                                              ),
                                                          onPointerMove: (event) =>
                                                              _handlePointerMove(
                                                                event.pointer,
                                                                event
                                                                    .localPosition,
                                                                boardSize,
                                                                event.timeStamp,
                                                              ),
                                                          onPointerUp: (event) =>
                                                              _handlePointerUp(
                                                                event.pointer,
                                                                event
                                                                    .localPosition,
                                                                boardSize,
                                                                event.timeStamp,
                                                              ),
                                                          onPointerCancel: (event) =>
                                                              _handlePointerCancel(
                                                                pointer: event
                                                                    .pointer,
                                                              ),
                                                          child: Semantics(
                                                            container: true,
                                                            label:
                                                                '공을 조준하는 게임 화면',
                                                            value:
                                                                _chargeGaugeActive
                                                                ? '충전 상태 ${_chargeGaugeStateLabel(_chargeGaugeState)}'
                                                                : [
                                                                    '힘 ${(_state.aimPower * 100).round()}퍼센트',
                                                                    ?_firstArrivalSemanticsValue,
                                                                  ].join(', '),
                                                            increasedValue:
                                                                _chargeGaugeActive
                                                                ? '충전 상태 ${_chargeGaugeStateLabel(_chargeGaugeState)}'
                                                                : '힘 ${((_state.aimPower + 0.02).clamp(0.0, 1.0) * 100).round()}퍼센트',
                                                            decreasedValue:
                                                                _chargeGaugeActive
                                                                ? '충전 상태 ${_chargeGaugeStateLabel(_chargeGaugeState)}'
                                                                : '힘 ${((_state.aimPower - 0.02).clamp(0.0, 1.0) * 100).round()}퍼센트',
                                                            hint:
                                                                _chargeGaugeActive
                                                                ? '현재 ${_chargeGaugeStateLabel(_chargeGaugeState)}. 손을 떼면 발사하거나 과충전 시 취소됩니다.'
                                                                : _difficulty ==
                                                                      PlayerDifficulty
                                                                          .easy
                                                                ? '증감 동작은 힘을 조절하고, 사용자 지정 동작으로 방향을 조절하면 마름모와 예상 라벨로 첫 도착 위치를 안내합니다'
                                                                : '증감 동작은 힘을 조절하고, 사용자 지정 동작으로 방향을 조절하세요',
                                                            onIncrease: () =>
                                                                _adjustPower(
                                                                  0.02,
                                                                ),
                                                            onDecrease: () =>
                                                                _adjustPower(
                                                                  -0.02,
                                                                ),
                                                            customSemanticsActions: {
                                                              semanticLaunch:
                                                                  _launch,
                                                              semanticAimRight:
                                                                  () =>
                                                                      _nudgeAim(
                                                                        math.pi /
                                                                            180,
                                                                      ),
                                                              semanticAimLeft:
                                                                  () => _nudgeAim(
                                                                    -math.pi /
                                                                        180,
                                                                  ),
                                                            },
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                              child: GameWidget(
                                                                game: _game,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  if (tutorialTarget != null)
                                                    Positioned(
                                                      left:
                                                          tutorialTarget
                                                                  .position
                                                                  .x >
                                                              logicalSize.x / 2
                                                          ? null
                                                          : math.min(
                                                              math.max(
                                                                6.0,
                                                                (tutorialTarget
                                                                            .position
                                                                            .x -
                                                                        58) *
                                                                    scale,
                                                              ),
                                                              math.max(
                                                                6.0,
                                                                boardSize
                                                                        .width -
                                                                    150,
                                                              ),
                                                            ),
                                                      right:
                                                          tutorialTarget
                                                                  .position
                                                                  .x >
                                                              logicalSize.x / 2
                                                          ? 6
                                                          : null,
                                                      top: math.min(
                                                        math.max(
                                                          6.0,
                                                          (tutorialTarget
                                                                      .position
                                                                      .y -
                                                                  66) *
                                                              scale,
                                                        ),
                                                        math.max(
                                                          6.0,
                                                          boardSize.height - 54,
                                                        ),
                                                      ),
                                                      child: IgnorePointer(
                                                        child: SizedBox(
                                                          width: math.min(
                                                            300,
                                                            math.max(
                                                              0,
                                                              boardSize.width -
                                                                  12,
                                                            ),
                                                          ),
                                                          child:
                                                              _TutorialCoachMark(
                                                                text:
                                                                    _tutorialHint,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (widget.showDiscoveryHud &&
                                                      tutorialTarget == null &&
                                                      !popupOpen &&
                                                      _discoveryMilestones.any(
                                                        (item) => item.achieved,
                                                      ))
                                                    Positioned(
                                                      left: 8,
                                                      right: 8,
                                                      top: 8,
                                                      child: IgnorePointer(
                                                        child: Align(
                                                          alignment: Alignment
                                                              .topCenter,
                                                          child: _CausalRibbon(
                                                            milestones:
                                                                _discoveryMilestones,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  for (final entity
                                                      in _semanticEntities)
                                                    if (entity.active)
                                                      Positioned(
                                                        left:
                                                            _semanticEntityRect(
                                                              entity,
                                                              scale,
                                                            ).left,
                                                        top:
                                                            _semanticEntityRect(
                                                              entity,
                                                              scale,
                                                            ).top,
                                                        width:
                                                            _semanticEntityRect(
                                                              entity,
                                                              scale,
                                                            ).width,
                                                        height:
                                                            _semanticEntityRect(
                                                              entity,
                                                              scale,
                                                            ).height,
                                                        child: Semantics(
                                                          container: true,
                                                          button: true,
                                                          label:
                                                              _semanticEntityLabel(
                                                                entity,
                                                              ),
                                                          hint:
                                                              entity
                                                                  .traits
                                                                  .isNotEmpty
                                                              ? '선택하면 속성 정보를 확인할 수 있습니다'
                                                              : '선택하면 물체 정보를 확인할 수 있습니다',
                                                          onTap: () =>
                                                              _handleSemanticEntity(
                                                                entity.id,
                                                              ),
                                                          child:
                                                              const SizedBox.expand(),
                                                        ),
                                                      ),
                                                  if (_currentHintKey
                                                      case final key?
                                                      when !_collectedHintKeyIds
                                                              .contains(
                                                                key.id,
                                                              ) ||
                                                          (widget.debugHintKeyVfxId ??
                                                                  _keyCollectionVfxId) ==
                                                              key.id)
                                                    Positioned(
                                                      left:
                                                          (key.position.x -
                                                              key.size.x / 2) *
                                                          scale,
                                                      top:
                                                          (key.position.y -
                                                              key.size.y / 2) *
                                                          scale,
                                                      width: key.size.x * scale,
                                                      height:
                                                          key.size.y * scale,
                                                      child: Semantics(
                                                        container: true,
                                                        label: '힌트 열쇠',
                                                        value:
                                                            '공으로 닿으면 현재 스테이지 팁을 해금합니다',
                                                        child: IgnorePointer(
                                                          child: _HintKeyOverlay(
                                                            vfxActive:
                                                                (widget.debugHintKeyVfxId ??
                                                                    _keyCollectionVfxId) ==
                                                                key.id,
                                                            reducedMotion:
                                                                GameFeedback
                                                                    .reducedMotionEnabled,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (widget.demoLaunchInput !=
                                                      null)
                                                    Positioned(
                                                      top: 0,
                                                      left:
                                                          boardSize.width / 2 -
                                                          22,
                                                      child: Semantics(
                                                        button: true,
                                                        label:
                                                            '검증된 48도 90퍼센트 시연 발사',
                                                        child: GestureDetector(
                                                          key: const Key(
                                                            'verified_demo_launch',
                                                          ),
                                                          behavior:
                                                              HitTestBehavior
                                                                  .opaque,
                                                          onTap:
                                                              _launchVerifiedDemoShot,
                                                          child: Opacity(
                                                            opacity: 0.01,
                                                            child: Container(
                                                              width: 44,
                                                              height: 44,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  if (_previousAimInput != null)
                                                    Positioned(
                                                      left: 0,
                                                      top: 0,
                                                      child: Semantics(
                                                        key: const Key(
                                                          'previous_aim_semantics',
                                                        ),
                                                        label:
                                                            _successAimGhostActive
                                                            ? '직전 성공 조준이 회색으로 표시됨'
                                                            : _game
                                                                  .previousShotPath
                                                                  .isNotEmpty
                                                            ? '직전 발사 궤적과 조준이 회색 점선으로 표시됨'
                                                            : '직전 조준 비교선이 회색으로 표시됨',
                                                        child: const SizedBox(
                                                          width: 1,
                                                          height: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  if (_chargeGaugeActive)
                                                    _FloatingChargeGauge(
                                                      boardSize: boardSize,
                                                      scale: scale,
                                                      state: _state,
                                                      hintKey: _currentHintKey,
                                                      gaugeState:
                                                          _chargeGaugeState,
                                                      power: _state.aimPower,
                                                      side: GameFeedback
                                                          .chargeGaugeSide,
                                                      reducedMotion: GameFeedback
                                                          .reducedMotionEnabled,
                                                      strongFlash: GameFeedback
                                                          .strongFlashEnabled,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                if (compactLayout)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      6,
                                      4,
                                      6,
                                      6,
                                    ),
                                    child: _ControlPanel(
                                      compact: true,
                                      dense: denseCompact,
                                      showPrecisionControls:
                                          _difficulty == PlayerDifficulty.easy,
                                      tutorialActive:
                                          tutorialTarget != null &&
                                          _state.equippedTrait == null,
                                      state: _state,
                                      effectFeedback: _traitEffectFeedback,
                                      onRewind: _rewind,
                                      onReset: _restartCurrentStage,
                                      onAimCounterClockwise: () =>
                                          _nudgeAim(-math.pi / 180),
                                      onAimClockwise: () =>
                                          _nudgeAim(math.pi / 180),
                                      onPowerDecrease: () =>
                                          _adjustPower(-0.02),
                                      onPowerIncrease: () => _adjustPower(0.02),
                                      canCancelReward:
                                          _isCharging &&
                                          _rewardInventory.availableUseCount(
                                                runRewardShotCancelAssistId,
                                              ) >
                                              0,
                                      onCancelReward: () =>
                                          unawaited(_cancelLaunchWithReward()),
                                    ),
                                  ),
                                if (!compactLayout)
                                  _ControlPanel(
                                    state: _state,
                                    showPrecisionControls:
                                        _difficulty == PlayerDifficulty.easy,
                                    effectFeedback: _traitEffectFeedback,
                                    onRewind: _rewind,
                                    onReset: _restartCurrentStage,
                                    onAimCounterClockwise: () =>
                                        _nudgeAim(-math.pi / 180),
                                    onAimClockwise: () =>
                                        _nudgeAim(math.pi / 180),
                                    onPowerDecrease: () => _adjustPower(-0.02),
                                    onPowerIncrease: () => _adjustPower(0.02),
                                    canCancelReward:
                                        _isCharging &&
                                        _rewardInventory.availableUseCount(
                                              runRewardShotCancelAssistId,
                                            ) >
                                            0,
                                    onCancelReward: () =>
                                        unawaited(_cancelLaunchWithReward()),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_showBallInfo)
                    _InfoPopup(
                      semanticLabel: '공 정보',
                      onClose: _dismissInfo,
                      child: _BallInfoPanel(state: _state),
                    ),
                  if (!_showBallInfo && inspectedEntity != null)
                    _InfoPopup(
                      semanticLabel: '${_entityName(inspectedEntity)} 정보',
                      onClose: _dismissInfo,
                      child: _EntityInfoPanel(
                        entity: inspectedEntity,
                        copyCharges: _state.copyCharges,
                        copyCoreCount: _state.copyCoreCount,
                        onTransfer:
                            inspectedEntity.type == EntityType.ball ||
                                inspectedEntity.traits.isEmpty ||
                                _isCommittingTraitAction
                            ? null
                            : _transferTrait,
                        onCopy:
                            inspectedEntity.type == EntityType.ball ||
                                inspectedEntity.traits.isEmpty ||
                                _state.copyCharges <= 0 ||
                                _isCommittingTraitAction
                            ? null
                            : _copyTrait,
                      ),
                    ),
                  if (failurePopupOpen)
                    _FailurePopup(
                      state: _state,
                      advice: _failureAdvice,
                      discoveries: widget.showDiscoveryHud
                          ? _discoveryMilestones
                          : const [],
                      failureReplay: _failureReplay,
                      assistRecommendation: _assistRecommendation,
                      assistFeedback: _assistRecommendationFeedback,
                      onAcceptAssist: () =>
                          unawaited(_acceptAssistRecommendation()),
                      onDismissAssist: _dismissAssistRecommendation,
                      onReplay: _openFailureReplay,
                      onRetry: _resumeAfterFailure,
                      onRetryFromPreparedState: _canRetryFromPreparedState
                          ? () => unawaited(_retryFromPreparedState())
                          : null,
                      onRewind: _rewind,
                      onRecoverPastBall:
                          _state.entities.any(
                                (entity) =>
                                    entity.type == EntityType.ball &&
                                    entity.id.startsWith('spent_ball_'),
                              ) &&
                              _rewardInventory.availableUseCount(
                                    runRewardSpentBallRecoveryId,
                                  ) >
                                  0
                          ? () => unawaited(_recoverPastBallWithReward())
                          : null,
                      onReset: () {
                        _showFailurePopup = false;
                        _restartCurrentStage();
                      },
                    ),
                  if (persistenceErrorOpen)
                    _ClearPersistenceErrorPopup(
                      title: _clearPersistenceErrorTitle,
                      body: _clearPersistenceErrorBody,
                      onRetry: _retryClearPersistence,
                    ),
                  if (clearPopupOpen)
                    ClearResultPopup(
                      state: _state,
                      level: _currentLevel,
                      discoveries: widget.showDiscoveryHud
                          ? _discoveryMilestones
                          : const [],
                      solutionEntries: _solutionEntries,
                      solutionTargetCount: math.min(
                        2,
                        math.max(1, _currentLevel.solutionFamilies.length),
                      ),
                      newSolutionStamp: _newSolutionStamp,
                      onShareSolution: _solutionEntries.isEmpty
                          ? null
                          : () => _shareSolution(_solutionEntries.last),
                      chainScoreAnalysis: _chainScoreAnalysis,
                      bestShot: _bestShots[_state.levelIndex],
                      bonusAchieved: _bonusChallengeAchieved,
                      rewardCandidates: _rewardCandidates,
                      selectedRewardId: _selectedRewardId,
                      isSelectingReward: _isSelectingReward,
                      rewardSelectionError: _rewardSelectionError,
                      onRewardSelected: (rewardId) =>
                          unawaited(_selectRunReward(rewardId)),
                      onNext: () => unawaited(_goNextLevel()),
                      onRetry: () => unawaited(_retryAfterClear()),
                      isFinal:
                          widget.sequencePosition != null &&
                              widget.sequenceLength != null
                          ? widget.sequencePosition! >=
                                widget.sequenceLength! - 1
                          : _state.levelIndex >= levels.length - 1,
                      sequencePosition: widget.sequencePosition,
                      sequenceLength: widget.sequenceLength,
                      nextActionLabel: widget.nextActionLabel,
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _openFailureReplay() {
    final replay = _failureReplay;
    if (replay == null || !mounted || _isAnimatingShot) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FailureReplayDialog(data: replay),
    );
  }

  void _resumeAfterFailure() {
    final replay = _failureReplay;
    if (replay == null || !mounted || _isAnimatingShot) return;
    final showPreviousAim = GameFeedback.previousAimComparisonEnabled;
    setState(() {
      _showFailurePopup = false;
      _successAimGhostActive = false;
      _setPreviousAimInput(
        showPreviousAim ? replay.input : null,
        path: showPreviousAim ? replay.result.path : null,
      );
      _state = _state.copyWith(
        message: showPreviousAim
            ? '직전 조준이 회색으로 남아 있습니다. 한 가지만 바꿔 다시 시도해 보세요.'
            : '각도나 힘 한 가지만 바꿔 다시 시도해 보세요.',
      );
    });
    _telemetry.record(
      '재시도',
      stage: _state.levelIndex,
      attempt: _state.shotCount + 1,
      result: showPreviousAim ? '직전 조준 비교' : '비교선 없음',
      eventCode: 'retry_pressed',
    );
    SemanticsService.sendAnnouncement(
      View.of(context),
      showPreviousAim
          ? '직전 조준이 회색으로 표시됩니다. 각도나 힘 한 가지만 바꿔 다시 시도해 보세요.'
          : '각도나 힘 한 가지만 바꿔 다시 시도해 보세요.',
      TextDirection.ltr,
    );
  }

  bool get _canRetryFromPreparedState {
    final replay = _failureReplay;
    return replay != null &&
        replay.beforeState.shotCount > 0 &&
        widget.onPracticeAssistUsed != null &&
        _discoveryMilestones.any((milestone) => milestone.achieved);
  }

  Future<void> _retryFromPreparedState() async {
    if (!_canRetryFromPreparedState || _isCommittingRewind) return;
    final marked = await widget.onPracticeAssistUsed?.call() ?? false;
    if (!marked || !mounted) {
      if (mounted) {
        setState(() {
          _assistRecommendationFeedback = '연습 기록 분리를 저장하지 못했습니다. 다시 시도해 주세요.';
        });
      }
      return;
    }
    await _rewindAfterPersist(
      resultMessage: '아이디어를 만든 준비 상태로 돌아왔습니다. 이 단계의 최고 기록은 연습 기록으로 분리됩니다.',
      telemetryResult: '인과 준비 상태 연습',
    );
  }

  EntityState? get _tutorialTarget {
    if (_activeTutorialVariant == TutorialExperimentVariant.silent) {
      return null;
    }
    if (_state.levelIndex > 2 ||
        _state.shotCount != 0 ||
        _state.phase != GamePhase.planning ||
        _state.selectedSourceId != null) {
      return null;
    }
    if (_state.equippedTrait == null) {
      final preferredId = switch (_state.levelIndex) {
        0 => 'anvil',
        1 => 'jelly',
        2 => 'steel',
        _ => null,
      };
      return _state.traitSources
              .where((entity) => entity.id == preferredId)
              .firstOrNull ??
          _state.traitSources.firstOrNull;
    }
    return _state.activeBall;
  }

  String get _tutorialHint {
    if (_activeTutorialVariant == TutorialExperimentVariant.action) {
      if (_state.equippedTrait == null) return '빛나는 속성 물체를 눌러 공에 옮겨요';
      return switch (_state.levelIndex) {
        0 => '상자 방향으로 조준하고 공을 길게 눌러요',
        1 => '홀 직행 대신 바닥 반사를 먼저 만들어요',
        2 => '홀보다 스위치를 먼저 향해 문을 열어요',
        _ => '공을 길게 눌러 힘을 모으고 손을 떼요',
      };
    }
    if (_state.equippedTrait == null) {
      return switch (_state.levelIndex) {
        0 => '바위를 눌러 무거움을 골라요',
        1 => '젤리를 눌러 탄성을 골라요',
        2 => '쇳덩이를 눌러 무거움을 골라요',
        _ => '속성 물체를 눌러 능력을 골라요',
      };
    }
    return switch (_state.levelIndex) {
      0 => '상자를 밀도록 조준해 발사해요',
      1 => '바닥을 먼저 향해 반사 경로를 만들어요',
      2 => '스위치를 먼저 눌러 문을 열어요',
      _ => '공을 길게 눌러 발사해요',
    };
  }
}

class _GameplayBackdrop extends StatelessWidget {
  const _GameplayBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: GameplayBackdropPainter());
  }
}

/// 독자적으로 그린 청동 열쇠다. 속성 아이콘/홀 깃발과 형태를 분리했고,
/// GameState에 들어가지 않는 선택 수집물이라 물리·리플레이를 바꾸지 않는다.
class _HintKeyOverlay extends StatelessWidget {
  const _HintKeyOverlay({required this.vfxActive, required this.reducedMotion});

  final bool vfxActive;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _HintKeyPainter(
      vfxActive: vfxActive,
      reducedMotion: reducedMotion,
    ),
    child: const SizedBox.expand(),
  );
}

class _HintKeyPainter extends CustomPainter {
  const _HintKeyPainter({required this.vfxActive, required this.reducedMotion});

  final bool vfxActive;
  final bool reducedMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final unit = math.min(size.width, size.height);
    final halo = Paint()..color = const Color(0x385B9F86);
    canvas.drawCircle(center, unit * .48, halo);
    canvas.drawCircle(
      center,
      unit * .43,
      Paint()
        ..color = const Color(0xFFC77D32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, unit * .075),
    );
    final bronze = Paint()
      ..color = const Color(0xFFC9873B)
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = const Color(0xFF6D3D1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, unit * .065)
      ..strokeJoin = StrokeJoin.round;
    final bowRadius = unit * .19;
    final bow = Offset(center.dx - unit * .11, center.dy - unit * .1);
    canvas.drawCircle(bow, bowRadius, bronze);
    canvas.drawCircle(bow, bowRadius, outline);
    canvas.drawCircle(
      bow,
      bowRadius * .43,
      Paint()..color = const Color(0xFFFFE1A3),
    );
    final shaft = Path()
      ..moveTo(bow.dx + bowRadius * .58, bow.dy + bowRadius * .55)
      ..lineTo(center.dx + unit * .32, center.dy + unit * .34)
      ..lineTo(center.dx + unit * .22, center.dy + unit * .44)
      ..lineTo(center.dx + unit * .12, center.dy + unit * .35)
      ..lineTo(center.dx + unit * .03, center.dy + unit * .44)
      ..lineTo(center.dx - unit * .07, center.dy + unit * .34)
      ..lineTo(bow.dx + bowRadius * .37, bow.dy + bowRadius * .39)
      ..close();
    canvas.drawPath(shaft, bronze);
    canvas.drawPath(shaft, outline);
    if (vfxActive) {
      final sparkle = Paint()
        ..color = const Color(0xFFFFF3B0)
        ..strokeWidth = math.max(1.4, unit * .07)
        ..strokeCap = StrokeCap.round;
      for (final angle in [0.0, math.pi / 2, math.pi, math.pi * 1.5]) {
        final from =
            center + Offset(math.cos(angle), math.sin(angle)) * unit * .28;
        final to =
            center + Offset(math.cos(angle), math.sin(angle)) * unit * .49;
        canvas.drawLine(from, to, sparkle);
      }
    } else if (!reducedMotion) {
      canvas.drawCircle(
        Offset(center.dx + unit * .33, center.dy - unit * .28),
        math.max(1.2, unit * .045),
        Paint()..color = const Color(0xFFFFED9A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HintKeyPainter oldDelegate) =>
      oldDelegate.vfxActive != vfxActive ||
      oldDelegate.reducedMotion != reducedMotion;
}

class _HintAccessButton extends StatelessWidget {
  const _HintAccessButton({
    required this.available,
    required this.keyAvailable,
    required this.onPressed,
    this.compact = false,
  });

  final bool available;
  final bool keyAvailable;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = available ? '팁 보기' : '팁 잠김';
    final reason = keyAvailable
        ? '열쇠를 공으로 건드리면 현재 스테이지 팁을 사용할 수 있습니다'
        : '이 스테이지의 힌트 접근권이 아직 없습니다';
    return Semantics(
      container: true,
      button: true,
      enabled: available,
      label: label,
      hint: reason,
      onTap: onPressed,
      child: ExcludeSemantics(
        child: compact
            ? IconButton(
                key: const Key('pattern_hint_button'),
                tooltip: '$label · $reason',
                onPressed: onPressed,
                icon: SizedBox.square(
                  dimension: 34,
                  child: Image.asset(
                    available
                        ? 'assets/generated/hint-lantern-v2.png'
                        : 'assets/generated/hint-key-v1.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 44,
                  height: 44,
                ),
                padding: const EdgeInsets.all(4),
              )
            : SizedBox(
                height: 44,
                child: FilledButton.tonalIcon(
                  key: const Key('pattern_hint_button'),
                  onPressed: onPressed,
                  icon: SizedBox.square(
                    dimension: 30,
                    child: Image.asset(
                      available
                          ? 'assets/generated/hint-lantern-v2.png'
                          : 'assets/generated/hint-key-v1.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                  label: Text(label),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    backgroundColor: available
                        ? const Color(0xFFFDF0B4)
                        : const Color(0xFFE8E2D3),
                    foregroundColor: available
                        ? const Color(0xFF5A4825)
                        : const Color(0xFF6C665B),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Bottom-sheet content preview used by Golden tests without a Navigator route.
/// The production flow always opens this through [_showPatternHintSheet].
@visibleForTesting
Widget buildPatternHintSheetForTesting({
  required PatternHintEntry entry,
  required RunHintEntitlement entitlement,
  required Future<RunHintEntitlement?> Function(int currentLevel) onMore,
}) => _PatternHintSheet(entry: entry, entitlement: entitlement, onMore: onMore);

class _PatternHintSheet extends StatefulWidget {
  const _PatternHintSheet({
    required this.entry,
    required this.entitlement,
    required this.onMore,
  });

  final PatternHintEntry entry;
  final RunHintEntitlement entitlement;
  final Future<RunHintEntitlement?> Function(int currentLevel) onMore;

  @override
  State<_PatternHintSheet> createState() => _PatternHintSheetState();
}

class _PatternHintSheetState extends State<_PatternHintSheet> {
  late RunHintEntitlement _entitlement = widget.entitlement;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final displayLevel = math.min(
      _entitlement.unlockedHintLevel,
      widget.entry.hints.length,
    );
    final hint = widget.entry.hints.firstWhere(
      (candidate) => candidate.level == displayLevel,
      orElse: () => widget.entry.hints.last,
    );
    final canMore = displayLevel < widget.entry.hints.length && !_loading;
    // showModalBottomSheet(useSafeArea: true)의 제약을 그대로 사용한다.
    // 여기서 SafeArea를 한 번 더 감싸면 compact 뷰포트에서 sheet가 보드 밖
    // 아래로 밀릴 수 있으므로, sheet 자체는 주어진 높이 안에서만 그린다.
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = math.min(constraints.maxHeight, 500.0);
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            key: const Key('pattern_hint_sheet'),
            constraints: BoxConstraints(maxWidth: 480, maxHeight: maxHeight),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7DB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 18)],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFB6A985),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      SizedBox.square(
                        dimension: 36,
                        child: Image.asset(
                          'assets/generated/hint-lantern-v2.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '현재 스테이지 팁 · $displayLevel단계',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF403923),
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(hint.text, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 14),
                  Text(
                    canMore
                        ? '다음 단계는 정확한 각도나 힘 대신, 다음에 시험할 기믹과 순서를 알려줍니다.'
                        : '이 팁은 언제든 다시 열어 볼 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF665F4E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (canMore)
                    FilledButton.icon(
                      key: const Key('pattern_hint_more_button'),
                      onPressed: () async {
                        setState(() => _loading = true);
                        final updated = await widget.onMore(displayLevel);
                        if (!mounted) return;
                        setState(() {
                          _loading = false;
                          if (updated != null) _entitlement = updated;
                        });
                      },
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : SizedBox.square(
                              dimension: 26,
                              child: Image.asset(
                                'assets/generated/hint-lantern-v2.png',
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                excludeFromSemantics: true,
                              ),
                            ),
                      label: const Text('더 구체적으로'),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class GameplayBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFBFE8E3),
    );

    final sand = Paint()..color = const Color(0xFFF6D995);
    final shore = Path()
      ..moveTo(-20, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.72,
        size.width * 0.58,
        size.height * 0.81,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.9,
        size.width + 20,
        size.height * 0.76,
      )
      ..lineTo(size.width + 20, size.height + 20)
      ..lineTo(-20, size.height + 20)
      ..close();
    canvas.drawPath(shore, sand);

    final shoreEdge = Path()
      ..moveTo(-20, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.72,
        size.width * 0.58,
        size.height * 0.81,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.9,
        size.width + 20,
        size.height * 0.76,
      );
    canvas.drawPath(
      shoreEdge,
      Paint()
        ..color = const Color(0x559E743B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final sandTexture = Paint()
      ..color = const Color(0x1F9E743B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var index = 0; index < 4; index++) {
      final y = size.height * (0.84 + index * 0.045);
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.08, y, size.width * 0.18, 10),
        math.pi * 0.12,
        math.pi * 0.72,
        false,
        sandTexture,
      );
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.68, y + 5, size.width * 0.2, 10),
        math.pi * 0.12,
        math.pi * 0.72,
        false,
        sandTexture,
      );
    }

    final wave = Paint()
      ..color = const Color(0x664EAAA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < 3; index++) {
      final y = size.height * (0.08 + index * 0.09);
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.04, y, size.width * 0.18, 12),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.78, y + 16, size.width * 0.18, 12),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
    }

    final shell = Paint()
      ..color = const Color(0x99EF765E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final point in [
      Offset(size.width * 0.12, size.height * 0.9),
      Offset(size.width * 0.82, size.height * 0.93),
      Offset(size.width * 0.68, size.height * 0.86),
    ]) {
      canvas.drawArc(
        Rect.fromCenter(center: point, width: 16, height: 10),
        math.pi,
        math.pi,
        false,
        shell,
      );
      for (var ray = -1; ray <= 1; ray++) {
        canvas.drawLine(
          point.translate(ray * 3.5, 0),
          point.translate(ray * 2.2, -4),
          shell,
        );
      }
    }

    _drawTidePool(canvas, size);
    _drawBeachLeaves(canvas, size);
    _drawStarfish(canvas, size);
  }

  void _drawTidePool(Canvas canvas, Size size) {
    final pool = Rect.fromLTWH(
      size.width * 0.68,
      size.height * 0.865,
      size.width * 0.22,
      size.height * 0.058,
    );
    canvas.drawOval(pool, Paint()..color = const Color(0x6685CEC7));
    canvas.drawArc(
      pool.deflate(4),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..color = const Color(0x779EE3D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final glint = Paint()..color = const Color(0x88FFFFFF);
    canvas.drawOval(
      Rect.fromLTWH(
        pool.left + pool.width * 0.2,
        pool.top + pool.height * 0.28,
        pool.width * 0.18,
        2.5,
      ),
      glint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        pool.left + pool.width * 0.58,
        pool.top + pool.height * 0.58,
        pool.width * 0.12,
        2,
      ),
      glint,
    );
  }

  void _drawBeachLeaves(Canvas canvas, Size size) {
    final base = Offset(size.width * 0.15, size.height * 0.91);
    canvas.drawOval(
      Rect.fromCenter(
        center: base.translate(0, 5),
        width: size.width * 0.15,
        height: 7,
      ),
      Paint()..color = const Color(0x223B5F48),
    );
    final leaf = Paint()..color = const Color(0xAA62A86B);
    final vein = Paint()
      ..color = const Color(0x66507F5B)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final entry in const [
      (angle: -2.15, width: 18.0, height: 7.0),
      (angle: -1.42, width: 21.0, height: 8.0),
      (angle: -0.78, width: 16.0, height: 7.0),
    ]) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(entry.angle);
      final leafRect = Rect.fromCenter(
        center: Offset(entry.width * 0.34, 0),
        width: entry.width,
        height: entry.height,
      );
      canvas.drawOval(leafRect, leaf);
      canvas.drawLine(Offset.zero, Offset(entry.width * 0.66, 0), vein);
      canvas.restore();
    }
  }

  void _drawStarfish(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.935);
    final path = Path();
    for (var index = 0; index < 10; index++) {
      final radius = index.isEven ? 9.0 : 3.8;
      final angle = -math.pi / 2 + index * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xB5EF765E));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x558C5544)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final dot = Paint()..color = const Color(0x99FFE4A5);
    canvas.drawCircle(center.translate(0, -1), 1.4, dot);
    canvas.drawCircle(center.translate(-3, 3), 1, dot);
    canvas.drawCircle(center.translate(3, 3), 1, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ClearResultPopup extends StatelessWidget {
  const ClearResultPopup({
    super.key,
    required this.state,
    required this.level,
    this.discoveries = const [],
    required this.onNext,
    required this.onRetry,
    required this.isFinal,
    required this.bonusAchieved,
    this.chainScoreAnalysis,
    this.bestShot,
    this.rewardCandidates = const [],
    this.selectedRewardId,
    this.isSelectingReward = false,
    this.rewardSelectionError,
    this.onRewardSelected,
    this.solutionEntries = const [],
    this.solutionTargetCount = 1,
    this.newSolutionStamp = false,
    this.onShareSolution,
    this.sequencePosition,
    this.sequenceLength,
    this.nextActionLabel,
  });

  final GameState state;
  final LevelDefinition level;
  final List<StageDiscoveryMilestone> discoveries;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final bool isFinal;
  final bool bonusAchieved;
  final CreativeChainScoreAnalysis? chainScoreAnalysis;
  final int? bestShot;
  final List<RunReward> rewardCandidates;
  final String? selectedRewardId;
  final bool isSelectingReward;
  final String? rewardSelectionError;
  final ValueChanged<String>? onRewardSelected;
  final List<SolutionMasteryEntry> solutionEntries;
  final int solutionTargetCount;
  final bool newSolutionStamp;
  final VoidCallback? onShareSolution;
  final int? sequencePosition;
  final int? sequenceLength;
  final String? nextActionLabel;

  @override
  Widget build(BuildContext context) {
    final stars = _starsForShot(state.shotCount, level.parShots);
    final rewardSelectionPending =
        rewardCandidates.isNotEmpty && selectedRewardId == null;
    return FocusScope(
      autofocus: true,
      child: Semantics(
        container: true,
        namesRoute: true,
        label: '클리어 결과 팝업',
        child: Container(
          key: const Key('clear_popup'),
          color: const Color(0x88000000),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final panelHeight = math
                    .min(620.0, math.max(1, constraints.maxHeight - 48))
                    .toDouble();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.96, end: 1),
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: SizedBox(
                          width: double.infinity,
                          height: panelHeight,
                          child: Container(
                            key: const Key('clear_panel'),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7DB),
                              borderRadius: BorderRadius.circular(18),
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
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    14,
                                    18,
                                    6,
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '클리어!',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall,
                                      ),
                                      Text('${state.shotCount}번 · 별 $stars/3'),
                                      Row(
                                        key: const Key('clear_stars'),
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          for (
                                            var index = 0;
                                            index < 3;
                                            index++
                                          )
                                            Icon(
                                              index < stars
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              color: index < stars
                                                  ? const Color(0xFFF0AE34)
                                                  : const Color(0xFFB7B6A9),
                                              size: 26,
                                            ),
                                        ],
                                      ),
                                      Text(
                                        '파 ${level.parShots}회',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: const Color(0xFF6A5947),
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Stack(
                                    children: [
                                      Scrollbar(
                                        child: SingleChildScrollView(
                                          key: const Key('clear_result_scroll'),
                                          padding: const EdgeInsets.fromLTRB(
                                            18,
                                            18,
                                            18,
                                            8,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (discoveries.isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                _DiscoveryResultCard(
                                                  milestones: discoveries,
                                                  cleared: true,
                                                ),
                                              ],
                                              if (solutionEntries
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Container(
                                                  key: const Key(
                                                    'solution_mastery_card',
                                                  ),
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFE4F3EA,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF79A98C,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        newSolutionStamp
                                                            ? '새 해법 도장 획득!'
                                                            : '해법 도감 ${solutionEntries.length}/$solutionTargetCount',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w900,
                                                          color: Color(
                                                            0xFF236B4A,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      for (final entry
                                                          in solutionEntries.take(
                                                            solutionTargetCount,
                                                          ))
                                                        Text(
                                                          '✓ ${entry.label}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                              ),
                                                        ),
                                                      if (solutionEntries
                                                              .length <
                                                          solutionTargetCount)
                                                        const Text(
                                                          '○ 다른 충돌 순서로 클리어해 새 도장을 찾아보세요.',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      if (onShareSolution !=
                                                          null)
                                                        TextButton.icon(
                                                          key: const Key(
                                                            'share_solution_card_button',
                                                          ),
                                                          onPressed:
                                                              onShareSolution,
                                                          icon: const Icon(
                                                            Icons
                                                                .ios_share_rounded,
                                                            size: 17,
                                                          ),
                                                          label: const Text(
                                                            '해법 카드 복사',
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              if (rewardCandidates
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 10),
                                                Container(
                                                  key: const Key(
                                                    'run_reward_selection',
                                                  ),
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFEAF4FF,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF7BA4C7,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        selectedRewardId == null
                                                            ? '런 보상 하나 선택'
                                                            : '런 보상 선택 완료',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color:
                                                                  const Color(
                                                                    0xFF285B7D,
                                                                  ),
                                                            ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      for (final reward
                                                          in rewardCandidates) ...[
                                                        Semantics(
                                                          button: true,
                                                          selected:
                                                              selectedRewardId ==
                                                              reward.id,
                                                          label: reward.name,
                                                          hint:
                                                              '${reward.role.label}. ${reward.description} ${reward.activationLabel}. ${reward.usageHint}',
                                                          child: Tooltip(
                                                            message:
                                                                '${reward.description}\n${reward.activationLabel} · ${reward.usageHint}',
                                                            child: OutlinedButton(
                                                              key: Key(
                                                                'run_reward_${reward.id}',
                                                              ),
                                                              autofocus:
                                                                  rewardSelectionPending &&
                                                                  reward ==
                                                                      rewardCandidates
                                                                          .first,
                                                              onPressed:
                                                                  selectedRewardId ==
                                                                          null &&
                                                                      !isSelectingReward
                                                                  ? () => onRewardSelected
                                                                        ?.call(
                                                                          reward
                                                                              .id,
                                                                        )
                                                                  : null,
                                                              style: OutlinedButton.styleFrom(
                                                                minimumSize:
                                                                    const Size(
                                                                      double
                                                                          .infinity,
                                                                      56,
                                                                    ),
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          10,
                                                                      vertical:
                                                                          8,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        8,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  ExcludeSemantics(
                                                                    child: _RunRewardIcon(
                                                                      reward:
                                                                          reward,
                                                                      selected:
                                                                          selectedRewardId ==
                                                                          reward
                                                                              .id,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 10,
                                                                  ),
                                                                  Expanded(
                                                                    child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          reward
                                                                              .name,
                                                                          style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w800,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          reward
                                                                              .activationLabel,
                                                                          key: Key(
                                                                            'run_reward_role_${reward.id}',
                                                                          ),
                                                                          style:
                                                                              Theme.of(
                                                                                context,
                                                                              ).textTheme.labelSmall?.copyWith(
                                                                                color: const Color(
                                                                                  0xFF8A6527,
                                                                                ),
                                                                                fontWeight: FontWeight.w800,
                                                                              ),
                                                                        ),
                                                                        Offstage(
                                                                          key: Key(
                                                                            'run_reward_usage_${reward.id}',
                                                                          ),
                                                                          child: Text(
                                                                            reward.usageHint,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 6,
                                                        ),
                                                      ],
                                                      if (isSelectingReward)
                                                        const Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      if (rewardSelectionError !=
                                                          null)
                                                        Text(
                                                          rewardSelectionError!,
                                                          key: const Key(
                                                            'run_reward_error',
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFFB3261E,
                                                                ),
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 10),
                                              Container(
                                                key: const Key(
                                                  'bonus_goal_status',
                                                ),
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: bonusAchieved
                                                      ? const Color(0xFFDDF3D5)
                                                      : const Color(0xFFF7EAC0),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      bonusAchieved
                                                          ? Icons.emoji_events
                                                          : Icons.flag_outlined,
                                                      size: 20,
                                                      color: bonusAchieved
                                                          ? const Color(
                                                              0xFF2F8A62,
                                                            )
                                                          : const Color(
                                                              0xFF8B6E35,
                                                            ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            bonusAchieved
                                                                ? '추가 도전 달성'
                                                                : '추가 도전',
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .labelLarge
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  color:
                                                                      bonusAchieved
                                                                      ? const Color(
                                                                          0xFF236B4A,
                                                                        )
                                                                      : const Color(
                                                                          0xFF6A5947,
                                                                        ),
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            level.bonusGoal,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                                  color: const Color(
                                                                    0xFF5D6657,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (chainScoreAnalysis !=
                                                  null) ...[
                                                const SizedBox(height: 10),
                                                CreativeChainScoreSummary(
                                                  analysis: chainScoreAnalysis!,
                                                  showDetails: GameFeedback
                                                      .chainScoreDetailsEnabled,
                                                  collapsibleDetails: true,
                                                ),
                                              ],
                                              if (sequencePosition != null &&
                                                  sequenceLength != null) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '핵심 체험 ${sequencePosition! + 1}/$sequenceLength 완료',
                                                  key: const Key(
                                                    'sequence_progress_label',
                                                  ),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF236B4A,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ] else if (!isFinal) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${state.levelIndex + 2}단계가 열렸습니다.',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall
                                                      ?.copyWith(
                                                        color: const Color(
                                                          0xFF236B4A,
                                                        ),
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ],
                                              if (bestShot != null) ...[
                                                const SizedBox(height: 4),
                                                Text('내 최고 기록 $bestShot회'),
                                              ],
                                              const SizedBox(height: 10),
                                            ],
                                          ),
                                        ),
                                      ),
                                      IgnorePointer(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            key: const Key('clear_scroll_fade'),
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Color(0x00FFF7DB),
                                                  Color(0xFFFFF7DB),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFDF3D0),
                                    border: Border(
                                      top: BorderSide(color: Color(0x33A47842)),
                                    ),
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    8,
                                    18,
                                    18,
                                  ),
                                  child: Column(
                                    children: [
                                      FilledButton.icon(
                                        key: const Key('next_stage_button'),
                                        autofocus: !rewardSelectionPending,
                                        onPressed: rewardSelectionPending
                                            ? null
                                            : onNext,
                                        icon: const Icon(Icons.arrow_forward),
                                        label: Text(
                                          nextActionLabel ??
                                              (isFinal ? '런 결과 보기' : '다음'),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        key: const Key('retry_stage_button'),
                                        onPressed: rewardSelectionPending
                                            ? null
                                            : onRetry,
                                        icon: const Icon(Icons.refresh),
                                        label: Text(
                                          solutionEntries.isEmpty
                                              ? '기록 다시 도전'
                                              : solutionEntries.length <
                                                    solutionTargetCount
                                              ? '다른 해법 찾기'
                                              : '내 기록 다시 도전',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _RunRewardIcon extends StatelessWidget {
  const _RunRewardIcon({required this.reward, required this.selected});

  final RunReward reward;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final visual = _runRewardIconVisual(reward.effectKind);
    return SizedBox(
      key: Key('run_reward_icon_${reward.id}'),
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: visual.background,
                shape: BoxShape.circle,
                border: Border.all(color: visual.foreground, width: 1.5),
              ),
              child: Icon(visual.icon, color: visual.foreground, size: 25),
            ),
          ),
          if (selected)
            const Positioned(
              right: -3,
              bottom: -3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF236B4A),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

({IconData icon, Color foreground, Color background}) _runRewardIconVisual(
  RunRewardEffectKind kind,
) {
  switch (kind) {
    case RunRewardEffectKind.cloneCore:
      return (
        icon: Icons.copy_all_rounded,
        foreground: const Color(0xFF236B4A),
        background: const Color(0xFFDDF3D5),
      );
    case RunRewardEffectKind.shotCancelAssist:
      return (
        icon: Icons.undo_rounded,
        foreground: const Color(0xFF285B7D),
        background: const Color(0xFFDCEEFF),
      );
    case RunRewardEffectKind.spentBallRecovery:
      return (
        icon: Icons.replay_circle_filled_rounded,
        foreground: const Color(0xFF704A8F),
        background: const Color(0xFFEEDFF7),
      );
    case RunRewardEffectKind.firstImpactGuide:
      return (
        icon: Icons.center_focus_strong_rounded,
        foreground: const Color(0xFF9B5A22),
        background: const Color(0xFFFFE9C8),
      );
    case RunRewardEffectKind.optionalChallengeGuard:
      return (
        icon: Icons.shield_rounded,
        foreground: const Color(0xFF356072),
        background: const Color(0xFFDCECF0),
      );
    case RunRewardEffectKind.failureCauseBoost:
      return (
        icon: Icons.account_tree_rounded,
        foreground: const Color(0xFF9A3F3F),
        background: const Color(0xFFFFDDDC),
      );
    case RunRewardEffectKind.ballAppearance:
      return (
        icon: Icons.auto_awesome_rounded,
        foreground: const Color(0xFF087F7A),
        background: const Color(0xFFFFE9A8),
      );
    case RunRewardEffectKind.stageRecordGuard:
      return (
        icon: Icons.workspace_premium_rounded,
        foreground: const Color(0xFF8A651D),
        background: const Color(0xFFFFE8A9),
      );
    case RunRewardEffectKind.nextStageHintAccess:
      return (
        icon: Icons.lightbulb_rounded,
        foreground: const Color(0xFF8A5B00),
        background: const Color(0xFFFFF0B8),
      );
    case RunRewardEffectKind.precisionCharge:
      return (
        icon: Icons.slow_motion_video_rounded,
        foreground: const Color(0xFF315E8B),
        background: const Color(0xFFDDEBFF),
      );
  }
}

class _ClearPersistenceErrorPopup extends StatelessWidget {
  const _ClearPersistenceErrorPopup({
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: Semantics(
        container: true,
        namesRoute: true,
        label: title,
        child: Container(
          key: const Key('clear_persistence_error_popup'),
          color: const Color(0x66000000),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20),
          child: SafeArea(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Material(
                color: const Color(0xFFF7FAF3),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_off, color: Color(0xFFB34B36)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(body),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        key: const Key('clear_persistence_retry_button'),
                        autofocus: true,
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('저장 다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiscoveryResultCard extends StatelessWidget {
  const _DiscoveryResultCard({required this.milestones, required this.cleared});

  final List<StageDiscoveryMilestone> milestones;
  final bool cleared;

  @override
  Widget build(BuildContext context) {
    final achieved = milestones.where((item) => item.achieved).toList();
    final pending = milestones.where((item) => !item.achieved).toList();
    final next = pending.isEmpty ? null : pending.first;
    return Container(
      key: Key(
        cleared ? 'clear_discovery_summary' : 'failure_discovery_summary',
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F4E9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF83B998)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cleared ? '이번 탐사 기록' : '클리어하면 이번 발견이 기록돼요',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF236B4A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            achieved.isEmpty
                ? '아직 확인한 반응이 없어요.'
                : achieved.map((item) => '✓ ${item.label}').join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!cleared && next != null) ...[
            const SizedBox(height: 3),
            Text(
              '다음 한 가지: ${next.label}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF466557),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FailurePopup extends StatelessWidget {
  const _FailurePopup({
    required this.state,
    required this.advice,
    required this.discoveries,
    required this.failureReplay,
    required this.assistRecommendation,
    required this.assistFeedback,
    required this.onAcceptAssist,
    required this.onDismissAssist,
    required this.onReplay,
    required this.onRetry,
    required this.onRetryFromPreparedState,
    required this.onRewind,
    required this.onReset,
    this.onRecoverPastBall,
  });

  final GameState state;
  final String advice;
  final List<StageDiscoveryMilestone> discoveries;
  final FailureReplayData? failureReplay;
  final AssistRecommendation? assistRecommendation;
  final String? assistFeedback;
  final VoidCallback onAcceptAssist;
  final VoidCallback onDismissAssist;
  final VoidCallback onReplay;
  final VoidCallback onRetry;
  final VoidCallback? onRetryFromPreparedState;
  final VoidCallback onRewind;
  final VoidCallback onReset;
  final VoidCallback? onRecoverPastBall;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: Semantics(
        container: true,
        namesRoute: true,
        label: '발사 실패 결과 팝업',
        child: Container(
          key: const Key('failure_popup'),
          color: const Color(0x55000000),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(context).height - 150,
              ),
              child: Material(
                color: const Color(0xFFF7FAF3),
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_golf,
                            color: Color(0xFFB34B36),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '이번 발사 결과',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text('${state.shotCount}회'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(state.message),
                      const SizedBox(height: 8),
                      const Text(
                        '이번에 바꿀 것',
                        key: Key('failure_change_heading'),
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        advice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF46584E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (discoveries.isNotEmpty || failureReplay != null) ...[
                        const SizedBox(height: 6),
                        ExpansionTile(
                          key: const Key('failure_details_tile'),
                          tilePadding: EdgeInsets.zero,
                          childrenPadding: const EdgeInsets.only(bottom: 6),
                          title: const Text(
                            '실험 결과 자세히',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          children: [
                            if (discoveries.any((item) => item.achieved))
                              _DiscoveryResultCard(
                                milestones: discoveries,
                                cleared: false,
                              ),
                            if (discoveries.any((item) => !item.achieved))
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '다음 실험: ${discoveries.firstWhere((item) => !item.achieved).label}',
                                    key: const Key('failure_next_experiment'),
                                    style: const TextStyle(
                                      color: Color(0xFF285B7D),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            if (failureReplay != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '멈춘 원인: ${const FailureReplayAnalyzer().analyze(failureReplay!).title}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF8B402D),
                                        ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (assistRecommendation != null) ...[
                        const SizedBox(height: 8),
                        _AssistRecommendationCard(
                          recommendation: assistRecommendation!,
                          onAccept: onAcceptAssist,
                          onDismiss: onDismissAssist,
                        ),
                      ] else if (assistFeedback != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          assistFeedback!,
                          key: const Key('assist_recommendation_feedback'),
                          style: const TextStyle(
                            color: Color(0xFF286343),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          FilledButton.icon(
                            key: const Key('failure_retry_button'),
                            autofocus: true,
                            onPressed: onRetry,
                            icon: const Icon(Icons.ads_click, size: 16),
                            label: const Text('바로 다시 조준'),
                          ),
                          if (onRetryFromPreparedState != null)
                            OutlinedButton.icon(
                              key: const Key('failure_prepared_retry_button'),
                              onPressed: onRetryFromPreparedState,
                              icon: const Icon(Icons.restore_rounded, size: 16),
                              label: const Text('준비 상태에서 연습'),
                            ),
                          if (failureReplay != null)
                            OutlinedButton.icon(
                              key: const Key('failure_replay_button'),
                              onPressed: onReplay,
                              icon: const Icon(Icons.replay, size: 16),
                              label: const Text('인과 재생'),
                            ),
                          if (onRetryFromPreparedState == null)
                            OutlinedButton.icon(
                              key: const Key('failure_rewind_button'),
                              onPressed: onRewind,
                              icon: const Icon(Icons.undo, size: 16),
                              label: const Text('되감기'),
                            ),
                          if (onRecoverPastBall != null)
                            OutlinedButton.icon(
                              key: const Key('recover_past_ball_button'),
                              onPressed: onRecoverPastBall,
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                size: 16,
                              ),
                              label: const Text('과거 공 회수'),
                            ),
                          TextButton.icon(
                            key: const Key('failure_reset_button'),
                            onPressed: onReset,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('단계 처음부터'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
Widget buildAssistRecommendationCardForTesting({
  required AssistRecommendation recommendation,
  required VoidCallback onAccept,
  required VoidCallback onDismiss,
}) => _AssistRecommendationCard(
  recommendation: recommendation,
  onAccept: onAccept,
  onDismiss: onDismiss,
);

class _AssistRecommendationCard extends StatelessWidget {
  const _AssistRecommendationCard({
    required this.recommendation,
    required this.onAccept,
    required this.onDismiss,
  });

  final AssistRecommendation recommendation;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '선택형 도움 추천. ${recommendation.title}. ${recommendation.reason}',
      child: Container(
        key: const Key('assist_recommendation_card'),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F2FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6D91B2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 19,
                  color: Color(0xFF315E8B),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(recommendation.reason),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  key: const Key('assist_recommendation_accept'),
                  onPressed: onAccept,
                  child: Text(recommendation.actionLabel),
                ),
                const SizedBox(width: 6),
                TextButton(
                  key: const Key('assist_recommendation_dismiss'),
                  onPressed: onDismiss,
                  child: const Text('지금은 괜찮아요'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

int _starsForShot(int shotCount, int parShots) {
  if (shotCount <= parShots) {
    return 3;
  }
  if (shotCount <= parShots + 2) {
    return 2;
  }
  return 1;
}

String? _levelProgressHint(GameState state) {
  if (state.levelIndex == 9) {
    return state.shotCount == 0
        ? '짧은 직접 길과 여러 기물을 잇는 길이 함께 열려 있습니다. 원하는 전략으로 시도해 보세요.'
        : '${state.shotCount}번의 결과가 보드에 남았습니다. 과거 공과 바뀐 기물 상태를 다음 샷에 활용할 수 있어요.';
  }
  if (state.levelIndex == 8) {
    final reflectors = state.entities.where(
      (entity) => entity.type == EntityType.rotatingReflector,
    );
    final rotationCount = reflectors.fold<int>(
      0,
      (sum, entity) => sum + entity.reflectorRotationCount,
    );
    return rotationCount == 0
        ? '반사판은 지금 보이는 면으로 먼저 튕긴 뒤 돌아갑니다. 직접 길과 준비 샷을 모두 시도할 수 있어요.'
        : '반사판이 모두 $rotationCount회 돌았습니다. 바뀐 면은 다음 공의 충돌부터 적용됩니다.';
  }
  if (state.levelIndex == 7) {
    final spentBalls = state.entities.where(
      (entity) => entity.type == EntityType.ball && entity.id != 'active_ball',
    );
    return spentBalls.isEmpty
        ? '직접 홀을 노려도 성공합니다. 첫 공을 남기면 더 긴 연쇄에도 도전할 수 있어요.'
        : '과거 공과 벽·기물을 이어 보세요. 최종 홀까지 이어진 충돌만 연쇄 점수에 반영됩니다.';
  }
  if (state.levelIndex == 5) {
    return state.shotCount > 0
        ? '발판과 벽의 결과를 확인했어요. 같은 각도와 우회 길도 비교해 보세요.'
        : '공은 충돌할수록 느려져요. 약한 발사로 발판 진입 각도를 찾아 보세요.';
  }
  if (state.levelIndex == 6) {
    final spentBalls = state.entities.where(
      (entity) => entity.type == EntityType.ball && entity.id != 'active_ball',
    );
    if (spentBalls.isEmpty) {
      return '첫 공도 사라지지 않아요. 쿠션·스위치·스토퍼로 남겨 보세요.';
    }
    final fixed = spentBalls.where((entity) => !entity.movable).length;
    return fixed > 0
        ? '고정된 과거 공도 클릭해 순번과 속성을 확인할 수 있어요.'
        : '남은 공의 위치를 보고 다음 공으로 맞혀 연쇄를 이어 가세요.';
  }
  if (state.levelIndex == 4) {
    final drained = state.entities.where(
      (entity) => entity.visualState == 'drained',
    );
    if (drained.isNotEmpty) {
      return '원본은 능력을 잃고 움직일 수 있게 됐어요. 공과 원본의 충돌을 함께 이용해 보세요.';
    }
    return '어떤 능력을 얻을지뿐 아니라 어느 원본을 비울지도 살펴보세요.';
  }
  if (state.levelIndex == 3) {
    final balloon = state.entityById('balloon');
    final balloonSwitch = state.entityById('balloon_switch');
    if (balloonSwitch?.pressed == true) {
      return '문이 열렸어요. 열린 길을 지나 홀에 들어가 보세요.';
    }
    if (balloon?.active == false) {
      return '풍선이 터졌어요. 드러난 스위치를 맞혀 문을 열어 보세요.';
    }
    final activeBall = state.entityById('active_ball');
    if (activeBall?.traits.contains(TraitType.sharp) == true) {
      return '뾰족한 공으로 풍선을 터뜨리면 ? 상자 속 기믹이 드러나요.';
    }
    return '일반 공은 풍선을 튕겨 냅니다. 풍선 뒤 ? 상자는 터뜨리면 정체가 드러나요.';
  }
  if (state.levelIndex != 2) {
    return null;
  }
  final hasAnchor = state.entities.any(
    (entity) =>
        entity.type == EntityType.ball &&
        entity.visualState == 'stuck' &&
        !entity.movable,
  );
  if (!hasAnchor) {
    return '추천 경로: 무거움으로 스위치를 누르는 길을 살펴보세요. 점착은 공을 고정합니다.';
  }
  final hasHeavy =
      state.entityById('active_ball')?.traits.contains(TraitType.heavy) == true;
  if (!hasHeavy) {
    return '점착 공이 고정되었습니다. 다음 공에 무거움을 옮기거나 다른 길을 찾아보세요.';
  }
  return '무거운 공으로 스위치를 누르고 열린 문을 지나 홀로 가 보세요.';
}

String? _compactLevelProgressHint(GameState state) {
  if (state.levelIndex == 9) {
    return state.shotCount == 0
        ? '직접 성공 · 속성 · 연쇄 모두 가능'
        : '남은 공과 기물 상태로 다음 경로 만들기';
  }
  if (state.levelIndex == 8) {
    final rotationCount = state.entities
        .where((entity) => entity.type == EntityType.rotatingReflector)
        .fold<int>(0, (sum, entity) => sum + entity.reflectorRotationCount);
    return rotationCount == 0
        ? '현재 면 반사 · 충돌 뒤 90도 회전'
        : '반사판 $rotationCount회 회전 · 다음 충돌에 적용';
  }
  if (state.levelIndex == 7) {
    final hasSpentBall = state.entities.any(
      (entity) => entity.type == EntityType.ball && entity.id != 'active_ball',
    );
    return hasSpentBall ? '과거 공 · 벽 · 기물 이어 보기' : '직접 성공 · 연쇄 도전 모두 가능';
  }
  if (state.levelIndex == 5) {
    return state.shotCount > 0 ? '발판 결과 · 우회 길 비교' : '감속 읽기 · 진입 각도 찾기';
  }
  if (state.levelIndex == 6) {
    final spent = state.entities.where(
      (entity) => entity.type == EntityType.ball && entity.id != 'active_ball',
    );
    return spent.isEmpty ? '첫 공을 남기기' : '과거 공 ${spent.length}개 · 다음 충돌 준비';
  }
  if (state.levelIndex == 4) {
    return state.entities.any((entity) => entity.visualState == 'drained')
        ? '공은 능력 획득 · 원본은 이동 가능'
        : '공의 변화 · 원본의 변화 함께 보기';
  }
  if (state.levelIndex == 3) {
    final balloonSwitch = state.entityById('balloon_switch');
    return balloonSwitch?.pressed == true
        ? '문 열림 · 열린 길 → 홀'
        : state.entityById('balloon')?.active == false
        ? '풍선 터짐 · 스위치 → 문'
        : state.entityById('active_ball')?.traits.contains(TraitType.sharp) ==
              true
        ? '뾰족함 장착 · 풍선 → ? 상자'
        : '풍선 뒤 ? 상자 · 터뜨리면 기믹 공개';
  }
  if (state.levelIndex != 2) {
    return null;
  }
  final hasAnchor = state.entities.any(
    (entity) =>
        entity.type == EntityType.ball &&
        entity.visualState == 'stuck' &&
        !entity.movable,
  );
  if (!hasAnchor) {
    return '무거움은 스위치 · 점착은 공 고정';
  }
  final hasHeavy =
      state.entityById('active_ball')?.traits.contains(TraitType.heavy) == true;
  if (!hasHeavy) {
    return '고정한 공을 발판으로 무거움 옮기기';
  }
  return '무거운 공으로 스위치 → 열린 문 → 홀';
}

String _levelIntroMessage(int levelIndex) {
  return switch (levelIndex) {
    0 => '방향 조정 · 길게 누르기 · 손 떼기',
    1 => '방향 조정 · 길게 누르기 · 손 떼기',
    2 => '스위치 살피기 · 여러 경로로 도전',
    3 => '풍선 확인 · 여러 경로로 도전',
    4 => '공과 원본의 변화를 함께 살펴보세요',
    5 => '감속 · 발판 진입 각도 · 여러 경로로 도전',
    6 => '과거 공 · 쿠션 · 여러 발의 연쇄 경로',
    7 => '직접 경로 · 벽과 기물 · 연쇄 점수 비교',
    8 => '현재 면 반사 · 충돌 뒤 회전 · 다음 샷 준비',
    9 => '배운 속성 · 기물 상태 · 나만의 경로',
    _ => '기물 상태 살피기 · 여러 경로로 도전',
  };
}

String _chargeGaugeStateLabel(ChargeGaugeState state) {
  return switch (state) {
    ChargeGaugeState.green => '초록 · 약한 힘',
    ChargeGaugeState.yellow => '노랑 · 보통 힘',
    ChargeGaugeState.red => '빨강 · 강한 힘',
    ChargeGaugeState.warningRed => '경고 빨강 · 과충전 직전',
    ChargeGaugeState.cancelledGray => '회색 · 발사 취소',
  };
}

String _chargeGaugeMessage(ChargeGaugeState state) {
  if (state == ChargeGaugeState.cancelledGray) {
    return '${_chargeGaugeStateLabel(state)} · 손을 떼고 새로 누르세요';
  }
  return '${_chargeGaugeStateLabel(state)} · 손을 떼면 발사됩니다';
}

/// 월드 좌표를 바꾸지 않고 화면상의 공 위치와 게이지를 연결한다.
///
/// 보드 안에서만 clamp하므로 홈 인디케이터 등의 Safe Area 침범은 상위
/// 레이아웃이 맡고, 이 위젯은 홀·풍선처럼 시선이 필요한 기물을 가리지
/// 않도록 결정론적인 대체 위치를 고른다.
class _FloatingChargeGauge extends StatelessWidget {
  const _FloatingChargeGauge({
    required this.boardSize,
    required this.scale,
    required this.state,
    this.hintKey,
    required this.gaugeState,
    required this.power,
    required this.side,
    required this.reducedMotion,
    required this.strongFlash,
  });

  static const _gaugeWidth = 38.0;
  static const _edgeInset = 8.0;
  static const _anchorGap = 64.0;

  final Size boardSize;
  final double scale;
  final GameState state;

  /// GameState 밖에 존재하는 비물리 수집물도 시각상 핵심 기물이므로
  /// 레일 배치 후보에서 함께 피한다.
  final HintKeyDefinition? hintKey;
  final ChargeGaugeState gaugeState;
  final double power;
  final ChargeGaugeSide side;
  final bool reducedMotion;
  final bool strongFlash;

  @override
  Widget build(BuildContext context) {
    final placement = _placement();
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            CustomPaint(
              painter: _ChargeGaugeAnchorPainter(
                from: placement.ballCenter,
                to: placement.anchorEnd,
              ),
              child: const SizedBox.expand(),
            ),
            Positioned.fromRect(
              rect: placement.rect,
              child: SizedBox(
                key: Key('charge_gauge_${side.name}'),
                child: _ChargeGaugeRail(
                  state: gaugeState,
                  power: power,
                  side: side,
                  reducedMotion: reducedMotion,
                  strongFlash: strongFlash,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _GaugePlacement _placement() {
    final height = math.min(180.0, math.max(132.0, boardSize.height * 0.28));
    final ball = state.activeBall;
    final ballCenter = Offset(ball.position.x * scale, ball.position.y * scale);
    final boardCenter = Offset(boardSize.width / 2, boardSize.height / 2);
    final towardCenter = boardCenter - ballCenter;
    final distance = towardCenter.distance;
    final unit = distance < 0.001
        ? const Offset(1, 0)
        : towardCenter / distance;
    final ballRadius = math.max(10.0, ball.radius * scale);
    final preferredCenter =
        ballCenter + unit * (ballRadius + _anchorGap + height / 2);

    Rect at(Offset center) => _clampRect(
      Rect.fromCenter(center: center, width: _gaugeWidth, height: height),
    );
    final opposite = -unit;
    final sideX = side == ChargeGaugeSide.right
        ? boardSize.width - _edgeInset - _gaugeWidth / 2
        : _edgeInset + _gaugeWidth / 2;
    // 기본 side 설정은 중앙 공에서도 실제 배치 차이를 만들어야 한다. 공이
    // 가장자리에 있을 때만 아래 fallback이 안전한 반대 위치를 선택한다.
    final sideDirection = side == ChargeGaugeSide.right
        ? const Offset(1, 0)
        : const Offset(-1, 0);
    final sidePreferredCenter =
        ballCenter + sideDirection * (ballRadius + _anchorGap + height / 2);
    final candidates = <Rect>[
      at(sidePreferredCenter),
      at(preferredCenter),
      at(ballCenter + opposite * (ballRadius + _anchorGap + height / 2)),
      at(Offset(sideX, ballCenter.dy)),
      at(Offset(boardSize.width - sideX, ballCenter.dy)),
    ];
    const protectedEntityTypes = <EntityType>{
      EntityType.ball,
      EntityType.hole,
      EntityType.balloon,
      EntityType.crate,
      EntityType.bumper,
      EntityType.stickySurface,
      EntityType.weight,
      EntityType.switchPad,
      EntityType.gate,
      EntityType.spikeSource,
      EntityType.powerSlider,
      EntityType.rotatingReflector,
    };
    final blocked = [
      for (final entity in state.entities)
        if (entity.active && protectedEntityTypes.contains(entity.type))
          _entityRect(entity).inflate(8),
      if (hintKey != null) _hintKeyRect(hintKey!).inflate(8),
    ];
    double overlapArea(Rect candidate) =>
        blocked.fold<double>(0, (total, obstacle) {
          final intersection = candidate.intersect(obstacle);
          if (intersection.width <= 0 || intersection.height <= 0) return total;
          return total + intersection.width * intersection.height;
        });

    Rect? clearCandidate;
    for (final candidate in candidates) {
      if (overlapArea(candidate) == 0) {
        clearCandidate = candidate;
        break;
      }
    }
    // 모든 후보가 막힌 밀집 배치에서도 임의의 마지막 후보를 고르지 않고
    // 핵심 기물과의 실제 겹침 면적이 가장 작은 위치를 택한다.
    final rect =
        clearCandidate ??
        candidates.reduce(
          (best, candidate) =>
              overlapArea(candidate) < overlapArea(best) ? candidate : best,
        );
    final closest = Offset(
      ballCenter.dx.clamp(rect.left, rect.right),
      ballCenter.dy.clamp(rect.top, rect.bottom),
    );
    final vector = closest - ballCenter;
    final anchorEnd = vector.distance <= 30
        ? closest
        : ballCenter + vector / vector.distance * 30;
    return _GaugePlacement(
      rect: rect,
      ballCenter: ballCenter,
      anchorEnd: anchorEnd,
    );
  }

  Rect _entityRect(EntityState entity) {
    final bounds = entity.bounds;
    return Rect.fromLTRB(
      bounds.left * scale,
      bounds.top * scale,
      bounds.right * scale,
      bounds.bottom * scale,
    );
  }

  Rect _hintKeyRect(HintKeyDefinition key) {
    final bounds = key.bounds;
    return Rect.fromLTRB(
      bounds.left * scale,
      bounds.top * scale,
      bounds.right * scale,
      bounds.bottom * scale,
    );
  }

  Rect _clampRect(Rect rect) {
    final maxLeft = math.max(
      _edgeInset,
      boardSize.width - _edgeInset - rect.width,
    );
    final maxTop = math.max(
      _edgeInset,
      boardSize.height - _edgeInset - rect.height,
    );
    return Rect.fromLTWH(
      rect.left.clamp(_edgeInset, maxLeft),
      rect.top.clamp(_edgeInset, maxTop),
      rect.width,
      rect.height,
    );
  }
}

class _GaugePlacement {
  const _GaugePlacement({
    required this.rect,
    required this.ballCenter,
    required this.anchorEnd,
  });

  final Rect rect;
  final Offset ballCenter;
  final Offset anchorEnd;
}

class _ChargeGaugeAnchorPainter extends CustomPainter {
  const _ChargeGaugeAnchorPainter({required this.from, required this.to});

  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    if ((to - from).distance < 2) return;
    final paint = Paint()
      ..color = const Color(0xB824352D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(from, to, paint);
    canvas.drawCircle(from, 2.5, Paint()..color = const Color(0xFFEAF6E9));
    canvas.drawCircle(
      from,
      2.5,
      Paint()
        ..color = const Color(0xB824352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant _ChargeGaugeAnchorPainter oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}

class _ChargeGaugeRail extends StatefulWidget {
  const _ChargeGaugeRail({
    required this.state,
    required this.power,
    required this.side,
    required this.reducedMotion,
    required this.strongFlash,
  });

  final ChargeGaugeState state;
  final double power;
  final ChargeGaugeSide side;
  final bool reducedMotion;
  final bool strongFlash;

  @override
  State<_ChargeGaugeRail> createState() => _ChargeGaugeRailState();
}

class _ChargeGaugeRailState extends State<_ChargeGaugeRail>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flashController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
    value: 1,
  );

  bool get _shouldFlash =>
      widget.state == ChargeGaugeState.warningRed &&
      !widget.reducedMotion &&
      widget.strongFlash;

  @override
  void initState() {
    super.initState();
    _syncFlash();
  }

  @override
  void didUpdateWidget(covariant _ChargeGaugeRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state ||
        oldWidget.reducedMotion != widget.reducedMotion ||
        oldWidget.strongFlash != widget.strongFlash) {
      _syncFlash();
    }
  }

  void _syncFlash() {
    if (_shouldFlash) {
      _flashController.repeat(reverse: true, min: 0.35, max: 1);
    } else {
      _flashController
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _chargeGaugeColor(widget.state);
    final icon = switch (widget.state) {
      ChargeGaugeState.green => Icons.eco,
      ChargeGaugeState.yellow => Icons.bolt,
      ChargeGaugeState.red => Icons.local_fire_department,
      ChargeGaugeState.warningRed => Icons.warning_amber_rounded,
      ChargeGaugeState.cancelledGray => Icons.close,
    };
    final shortLabel = switch (widget.state) {
      ChargeGaugeState.green => '약',
      ChargeGaugeState.yellow => '중',
      ChargeGaugeState.red => '강',
      ChargeGaugeState.warningRed => '주의',
      ChargeGaugeState.cancelledGray => '취소',
    };
    final percent = widget.state == ChargeGaugeState.cancelledGray
        ? 100
        : (widget.power.clamp(0.0, 1.0) * 100).round();
    final sideLabel = widget.side == ChargeGaugeSide.right ? '오른쪽' : '왼쪽';

    return Stack(
      fit: StackFit.expand,
      children: [
        Semantics(
          key: const Key('charge_gauge_live_state'),
          container: true,
          liveRegion: true,
          label: '충전 상태',
          value: _chargeGaugeStateLabel(widget.state),
          child: const SizedBox.expand(),
        ),
        Semantics(
          key: const Key('charge_gauge_rail'),
          container: true,
          label: '충전 게이지',
          value: '$sideLabel, 힘 $percent퍼센트',
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xB8FFF8E8),
                border: Border.all(color: const Color(0xD924352D), width: 1),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x2924352D),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(3, 5, 3, 6),
                child: Column(
                  children: [
                    Icon(icon, size: 17, color: color),
                    const SizedBox(height: 2),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _flashController,
                        builder: (context, _) => Opacity(
                          key: const Key('charge_gauge_flash_opacity'),
                          opacity: _flashController.value,
                          child: CustomPaint(
                            key: const Key('charge_gauge_fill'),
                            painter: _ChargeGaugeRailPainter(
                              power:
                                  widget.state == ChargeGaugeState.cancelledGray
                                  ? 1
                                  : widget.power,
                              color: color,
                              fillOpacity: 1,
                              cancelled:
                                  widget.state ==
                                  ChargeGaugeState.cancelledGray,
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shortLabel,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF24352D),
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$percent%',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Color(0xFF24352D),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Color _chargeGaugeColor(ChargeGaugeState state) {
  return switch (state) {
    ChargeGaugeState.green => const Color(0xFF16784C),
    ChargeGaugeState.yellow => const Color(0xFF9B6C00),
    ChargeGaugeState.red => const Color(0xFFB3261E),
    ChargeGaugeState.warningRed => const Color(0xFFD21F18),
    ChargeGaugeState.cancelledGray => const Color(0xFF59615E),
  };
}

class _ChargeGaugeRailPainter extends CustomPainter {
  const _ChargeGaugeRailPainter({
    required this.power,
    required this.color,
    required this.fillOpacity,
    required this.cancelled,
  });

  final double power;
  final Color color;
  final double fillOpacity;
  final bool cancelled;

  @override
  void paint(Canvas canvas, Size size) {
    const railWidth = 10.0;
    final rail = RRect.fromRectAndRadius(
      Rect.fromLTWH((size.width - railWidth) / 2, 0, railWidth, size.height),
      const Radius.circular(5),
    );
    canvas.drawRRect(rail, Paint()..color = const Color(0xFFD7DED8));
    canvas.drawRRect(
      rail,
      Paint()
        ..color = const Color(0xFF24352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final progress = power.clamp(0.0, 1.0);
    final fillHeight = size.height * progress;
    canvas.save();
    canvas.clipRRect(rail);
    canvas.drawRect(
      Rect.fromLTWH(
        rail.outerRect.left,
        size.height - fillHeight,
        railWidth,
        fillHeight,
      ),
      Paint()..color = color.withValues(alpha: fillOpacity),
    );
    canvas.restore();

    final tickPaint = Paint()
      ..color = const Color(0xFFFDF8E6)
      ..strokeWidth = 2;
    for (final threshold in const [0.40, 0.70, 0.90]) {
      final y = size.height * (1 - threshold);
      canvas.drawLine(
        Offset(rail.outerRect.left - 3, y),
        Offset(rail.outerRect.right + 3, y),
        tickPaint,
      );
    }

    if (cancelled) {
      final center = rail.outerRect.center;
      final cancelPaint = Paint()
        ..color = const Color(0xFFFDF8E6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center + const Offset(-5, -5),
        center + const Offset(5, 5),
        cancelPaint,
      );
      canvas.drawLine(
        center + const Offset(5, -5),
        center + const Offset(-5, 5),
        cancelPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChargeGaugeRailPainter oldDelegate) {
    return oldDelegate.power != power ||
        oldDelegate.color != color ||
        oldDelegate.fillOpacity != fillOpacity ||
        oldDelegate.cancelled != cancelled;
  }
}

class _CausalRibbon extends StatelessWidget {
  const _CausalRibbon({required this.milestones});

  final List<StageDiscoveryMilestone> milestones;

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();
    final achievedCount = milestones.where((item) => item.achieved).length;
    final nextIndex = achievedCount.clamp(0, milestones.length - 1);
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          '기믹 흐름 ${milestones.map((item) => '${item.label} ${item.achieved ? '완료' : '대기'}').join(', ')}',
      child: ExcludeSemantics(
        child: Container(
          key: const Key('causal_ribbon'),
          constraints: const BoxConstraints(maxWidth: 330),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xEAF8F2D9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xAA765B31)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < milestones.length; index++) ...[
                if (index > 0)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: Color(0xFF806D4A),
                    ),
                  ),
                Flexible(
                  child: DecoratedBox(
                    key: Key('causal_step_$index'),
                    decoration: BoxDecoration(
                      color: milestones[index].achieved
                          ? const Color(0xFFD5F1DC)
                          : index == nextIndex
                          ? const Color(0xFFFFE5A8)
                          : const Color(0xFFE8E5D9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: milestones[index].achieved
                            ? const Color(0xFF3B9463)
                            : index == nextIndex
                            ? const Color(0xFFD58C22)
                            : const Color(0xFFAAA492),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            milestones[index].achieved
                                ? Icons.check_rounded
                                : index == nextIndex
                                ? Icons.play_arrow_rounded
                                : Icons.circle_outlined,
                            size: 12,
                            color: const Color(0xFF365549),
                          ),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              milestones[index].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    fontSize: 10,
                                    fontWeight: index == nextIndex
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

@visibleForTesting
Widget buildCausalRibbonForTesting({
  required List<StageDiscoveryMilestone> milestones,
}) => _CausalRibbon(milestones: milestones);

class _CompactHudDetails extends StatelessWidget {
  const _CompactHudDetails({
    required this.objective,
    required this.message,
    required this.tutorialActive,
    required this.milestones,
    this.condensed = false,
    this.spacious = false,
    this.progressHint,
    this.rewardGuide,
  });

  final String objective;
  final String message;
  final bool tutorialActive;
  final List<StageDiscoveryMilestone> milestones;
  final bool condensed;
  final bool spacious;
  final String? progressHint;
  final String? rewardGuide;

  @override
  Widget build(BuildContext context) {
    final discoveryText = milestones.isEmpty
        ? '이 스테이지에는 별도의 발견 기록이 없습니다.'
        : milestones
              .map((item) => '${item.achieved ? '완료' : '대기'} · ${item.label}')
              .join('\n');
    final entries = <_HudDetailEntry>[
      _HudDetailEntry(
        id: 'objective',
        title: '이번 스테이지 목표',
        message: objective,
        assetPath: 'assets/generated/nav-stage-map-v1.png',
      ),
      if (milestones.isNotEmpty)
        _HudDetailEntry(
          id: 'discovery',
          title:
              '발견 ${milestones.where((item) => item.achieved).length}/${milestones.length}',
          message: discoveryText,
          assetPath: 'assets/generated/nav-activities-v1.png',
        ),
      if (rewardGuide != null)
        _HudDetailEntry(
          id: 'reward',
          title: '이번 단계 보상',
          message: rewardGuide!,
          assetPath: 'assets/generated/nav-reward-satchel-v1.png',
        ),
      _HudDetailEntry(
        id: 'status',
        title: tutorialActive ? '현재 안내' : '플레이 상태',
        message: message,
        assetPath: 'assets/generated/hint-lantern-v2.png',
      ),
      if (progressHint != null)
        _HudDetailEntry(
          id: 'progress',
          title: '진행 상황',
          message: progressHint!,
          assetPath: 'assets/generated/nav-expedition-v1.png',
        ),
    ];
    return Stack(
      key: const Key('hud_info_actions'),
      alignment: Alignment.center,
      children: [
        Semantics(
          key: const Key('compact_objective'),
          container: true,
          label: objective,
          child: ExcludeSemantics(
            child: Opacity(
              opacity: 0,
              child: SizedBox(width: 0, height: 0, child: Text(objective)),
            ),
          ),
        ),
        Semantics(
          key: const Key('compact_message'),
          container: true,
          liveRegion: true,
          label: '게임 안내: $message',
          child: ExcludeSemantics(
            child: Opacity(
              opacity: 0,
              child: SizedBox(width: 0, height: 0, child: Text(message)),
            ),
          ),
        ),
        if (progressHint != null)
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 0,
              height: 0,
              child: Text(progressHint!, key: const Key('level_progress')),
            ),
          ),
        if (rewardGuide != null)
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 0,
              height: 0,
              child: Text(rewardGuide!, key: const Key('active_reward_guide')),
            ),
          ),
        PopupMenuButton<_HudDetailEntry>(
          key: const Key('hud_details_menu'),
          tooltip: '스테이지 정보 더 보기',
          onSelected: (entry) => _showHudDetailDialog(context, entry),
          itemBuilder: (context) => [
            for (final entry in entries)
              PopupMenuItem<_HudDetailEntry>(
                key: Key('hud_${entry.id}_button'),
                value: entry,
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 30,
                      child: Image.asset(
                        entry.assetPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(entry.title)),
                  ],
                ),
              ),
          ],
          icon: SizedBox.square(
            dimension: condensed
                ? 34
                : spacious
                ? 42
                : 36,
            child: Image.asset(
              'assets/generated/nav-stage-map-v1.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _HudDetailEntry {
  const _HudDetailEntry({
    required this.id,
    required this.title,
    required this.message,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String message;
  final String assetPath;
}

void _showHudDetailDialog(BuildContext context, _HudDetailEntry entry) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: Key('hud_${entry.id}_dialog'),
      title: Row(
        children: [
          SizedBox.square(
            dimension: 42,
            child: Image.asset(
              entry.assetPath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.title)),
        ],
      ),
      content: ConstrainedBox(
        key: const Key('hud_info_dialog_content'),
        constraints: const BoxConstraints(maxWidth: 340),
        child: Text(entry.message),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('확인'),
        ),
      ],
    ),
  );
}

class _Hud extends StatelessWidget {
  const _Hud({
    this.compact = false,
    this.dense = false,
    this.tutorialActive = false,
    required this.state,
    required this.discoveryMilestones,
    this.rewardGuide,
    required this.unlockedLevel,
    required this.onSelectLevel,
    this.showStageSelector = true,
    required this.onPause,
    this.onExit,
    this.exitToMainMenu = false,
    this.hudScore,
    this.onDebug,
    this.objectiveOverride,
    this.showDiscovery = true,
    this.exitTooltipOverride,
    this.hintVisible = false,
    this.hintAvailable = false,
    this.hintKeyAvailable = false,
    this.onHint,
  });

  final bool compact;
  final bool dense;
  final bool tutorialActive;
  final GameState state;
  final List<StageDiscoveryMilestone> discoveryMilestones;
  final String? rewardGuide;
  final int unlockedLevel;
  final ValueChanged<int> onSelectLevel;
  final bool showStageSelector;
  final VoidCallback onPause;
  final VoidCallback? onExit;
  final bool exitToMainMenu;
  final int? hudScore;
  final VoidCallback? onDebug;
  final String? objectiveOverride;
  final bool showDiscovery;
  final String? exitTooltipOverride;
  final bool hintVisible;
  final bool hintAvailable;
  final bool hintKeyAvailable;
  final VoidCallback? onHint;

  @override
  Widget build(BuildContext context) {
    final exitLabel = exitTooltipOverride ?? '스테이지 포기';
    final progressHint = showDiscovery ? _levelProgressHint(state) : null;
    final compactProgressHint = showDiscovery
        ? _compactLevelProgressHint(state)
        : null;
    final discoveries = discoveryMilestones
        .where((milestone) => milestone.achieved)
        .length;
    if (compact) {
      return Container(
        key: const Key('compact_hud'),
        padding: EdgeInsets.fromLTRB(8, dense ? 2 : 6, 8, dense ? 2 : 6),
        decoration: BoxDecoration(
          color: const Color(0xE6F7FAF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xAA708278)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: showStageSelector && dense
                      ? Stack(
                          fit: StackFit.passthrough,
                          children: [
                            Text(
                              state.levelName,
                              key: const Key('dense_stage_title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            for (var index = 0; index < levels.length; index++)
                              Positioned.fill(
                                child: Semantics(
                                  container: true,
                                  label: index <= unlockedLevel
                                      ? '${index + 1}단계 선택'
                                      : '${index + 1}단계 잠김. ${unlockedLevel + 1}단계 클리어 후 열림',
                                  button: index <= unlockedLevel,
                                  selected: state.levelIndex == index,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                          ],
                        )
                      : Text(
                          state.levelName,
                          maxLines: 2,
                          softWrap: true,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(width: 6),
                _HudMetric(
                  assetPath: 'assets/generated/nav-replay-v1.png',
                  tooltip: '시도 횟수 ${state.shotCount}',
                  value: '시도 ${state.shotCount}',
                  iconOnly: true,
                ),
                const SizedBox(width: 6),
                _HudMetric(
                  assetPath: 'assets/generated/stage-icon-chain-score-v1.png',
                  tooltip: '현재 점수 ${hudScore ?? state.score}',
                  value: '점수 ${hudScore ?? state.score}',
                  iconOnly: true,
                ),
                _CompactHudDetails(
                  objective:
                      objectiveOverride ??
                      '발견 $discoveries/${discoveryMilestones.length} · '
                          '${stageDiscoveryCompactPath(state.levelIndex)}',
                  message: state.message,
                  tutorialActive: tutorialActive,
                  milestones: discoveryMilestones,
                  condensed: dense,
                  progressHint: compactProgressHint,
                  rewardGuide: rewardGuide,
                ),
                if (hintVisible)
                  _HintAccessButton(
                    available: hintAvailable,
                    keyAvailable: hintKeyAvailable,
                    onPressed: onHint,
                    compact: true,
                  ),
                if (!showStageSelector && onExit != null)
                  Semantics(
                    key: const Key('stage_abandon_button'),
                    button: true,
                    label: exitLabel,
                    child: IconButton(
                      key: const Key('home_button'),
                      tooltip: exitLabel,
                      onPressed: onExit,
                      icon: Image.asset(
                        'assets/generated/nav-stage-map-v1.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                    ),
                  ),
                if (!showStageSelector)
                  IconButton(
                    key: const Key('pause_button'),
                    tooltip: state.phase == GamePhase.paused ? '계속' : '멈춤',
                    onPressed: onPause,
                    icon: Icon(
                      state.phase == GamePhase.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                  ),
                if (onDebug != null)
                  IconButton(
                    key: const Key('debug_menu_button'),
                    tooltip: '개발 진단 메뉴',
                    onPressed: onDebug,
                    icon: const Icon(Icons.bug_report_outlined),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                  ),
              ],
            ),
            if (!dense) const SizedBox(height: 2),
            if (showStageSelector && !dense)
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < levels.length; i++)
                      Semantics(
                        label: i <= unlockedLevel
                            ? '${i + 1}단계 선택'
                            : '${i + 1}단계 잠김. ${unlockedLevel + 1}단계 클리어 후 열림',
                        button: i <= unlockedLevel,
                        selected: state.levelIndex == i,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            key: Key('level_$i'),
                            label: Text('${i + 1}'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            selected: state.levelIndex == i,
                            onSelected: i <= unlockedLevel
                                ? (_) => onSelectLevel(i)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.levelName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              _HudMetric(
                assetPath: 'assets/generated/nav-replay-v1.png',
                tooltip: '시도 횟수 ${state.shotCount}',
                value: '시도 ${state.shotCount}',
                spacious: true,
              ),
              _CompactHudDetails(
                objective:
                    objectiveOverride ??
                    stageDiscoveryQuestion(state.levelIndex),
                message: state.message,
                tutorialActive: tutorialActive,
                milestones: showDiscovery ? discoveryMilestones : const [],
                progressHint: progressHint,
                rewardGuide: rewardGuide,
                spacious: true,
              ),
              if (hintVisible)
                _HintAccessButton(
                  available: hintAvailable,
                  keyAvailable: hintKeyAvailable,
                  onPressed: onHint,
                ),
              const SizedBox(width: 12),
              _HudMetric(
                assetPath: 'assets/generated/stage-icon-chain-score-v1.png',
                tooltip: '현재 점수 ${hudScore ?? state.score}',
                value: '점수 ${hudScore ?? state.score}',
                spacious: true,
              ),
              if (!showStageSelector && onExit != null)
                Semantics(
                  key: const Key('stage_abandon_button'),
                  button: true,
                  label: exitLabel,
                  child: IconButton(
                    key: const Key('home_button'),
                    tooltip: exitLabel,
                    onPressed: onExit,
                    icon: SizedBox.square(
                      dimension: 38,
                      child: Image.asset(
                        'assets/generated/nav-stage-map-v1.png',
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                    padding: const EdgeInsets.all(5),
                    constraints: const BoxConstraints.tightFor(
                      width: 52,
                      height: 52,
                    ),
                  ),
                ),
              if (!showStageSelector)
                IconButton(
                  key: const Key('pause_button'),
                  tooltip: state.phase == GamePhase.paused ? '계속' : '멈춤',
                  onPressed: onPause,
                  icon: Icon(
                    state.phase == GamePhase.paused
                        ? Icons.play_arrow
                        : Icons.pause,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              if (onDebug != null)
                IconButton(
                  key: const Key('debug_menu_button'),
                  tooltip: '개발 진단 메뉴',
                  onPressed: onDebug,
                  icon: const Icon(Icons.bug_report_outlined),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (showStageSelector)
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < levels.length; i++)
                        Semantics(
                          label: i <= unlockedLevel
                              ? '${i + 1}단계 선택'
                              : '${i + 1}단계 잠김. ${unlockedLevel + 1}단계 클리어 후 열림',
                          button: i <= unlockedLevel,
                          selected: state.levelIndex == i,
                          child: ChoiceChip(
                            key: Key('level_$i'),
                            label: Text('${i + 1}'),
                            selected: state.levelIndex == i,
                            onSelected: i <= unlockedLevel
                                ? (_) => onSelectLevel(i)
                                : null,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _HudMetric extends StatelessWidget {
  const _HudMetric({
    required this.assetPath,
    required this.tooltip,
    required this.value,
    this.iconOnly = false,
    this.spacious = false,
  });

  final String assetPath;
  final String tooltip;
  final String value;
  final bool iconOnly;
  final bool spacious;

  @override
  Widget build(BuildContext context) {
    final imageExtent = spacious ? 36.0 : 28.0;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                assetPath,
                width: imageExtent,
                height: imageExtent,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              if (!iconOnly) ...[
                const SizedBox(width: 2),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialCoachMark extends StatelessWidget {
  const _TutorialCoachMark({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.max(
      160.0,
      math.min(MediaQuery.sizeOf(context).width - 24, 300.0),
    );
    return Semantics(
      liveRegion: true,
      label: '튜토리얼 안내: $text',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          key: const Key('tutorial_coach_mark'),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xF9FFF5D9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7B45A), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x443B2B24),
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.touch_app_rounded,
                size: 17,
                color: Color(0xFFB56B34),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  text,
                  softWrap: true,
                  style: const TextStyle(
                    color: Color(0xFF62462D),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    this.compact = false,
    this.dense = false,
    this.tutorialActive = false,
    this.showPrecisionControls = false,
    required this.state,
    this.effectFeedback,
    required this.onRewind,
    required this.onReset,
    this.onAimCounterClockwise,
    this.onAimClockwise,
    this.onPowerDecrease,
    this.onPowerIncrease,
    this.canCancelReward = false,
    this.onCancelReward,
  });

  final bool compact;
  final bool dense;
  final bool tutorialActive;
  final bool showPrecisionControls;
  final GameState state;
  final String? effectFeedback;
  final VoidCallback onRewind;
  final VoidCallback onReset;
  final VoidCallback? onAimCounterClockwise;
  final VoidCallback? onAimClockwise;
  final VoidCallback? onPowerDecrease;
  final VoidCallback? onPowerIncrease;
  final bool canCancelReward;
  final VoidCallback? onCancelReward;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPrecisionControls)
            _PrecisionAimControls(
              compact: true,
              power: state.aimPower,
              onAimCounterClockwise: onAimCounterClockwise!,
              onAimClockwise: onAimClockwise!,
              onPowerDecrease: onPowerDecrease!,
              onPowerIncrease: onPowerIncrease!,
            ),
          Container(
            key: const Key('compact_control_panel'),
            padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
            decoration: BoxDecoration(
              color: const Color(0xE6F7FAF3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xAA708278)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (effectFeedback != null || (!tutorialActive && !dense))
                  Expanded(
                    child: Semantics(
                      key: const Key('trait_effect_feedback_semantics'),
                      container: true,
                      liveRegion: effectFeedback != null,
                      label: effectFeedback,
                      excludeSemantics: effectFeedback != null,
                      child: Text(
                        effectFeedback ??
                            (state.equippedTrait != null
                                ? '공을 길게 눌러 힘 모으기'
                                : state.selectedTrait == null
                                ? state.traitSources.isEmpty
                                      ? '공을 길게 눌러 힘 모으기'
                                      : '물체를 눌러 속성 고르기'
                                : '선택: ${state.selectedTrait!.label}'),
                        key: const Key('trait_effect_feedback'),
                        maxLines: 2,
                        softWrap: true,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  )
                else if (state.equippedTrait != null)
                  Expanded(
                    child: Text(
                      '공을 길게 눌러 힘을 모으세요',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  const Spacer(),
                Flexible(
                  child: Text(
                    state.equippedTrait == null
                        ? '공 속성: 없음'
                        : '공 속성: ${state.equippedTrait!.label} · '
                              '${state.equippedTrait!.compactEffect}',
                    maxLines: dense ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: !dense,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('rewind_button'),
                  tooltip: '되감기',
                  visualDensity: VisualDensity.compact,
                  onPressed: onRewind,
                  icon: const Icon(Icons.undo, size: 20),
                ),
                if (canCancelReward)
                  IconButton(
                    key: const Key('cancel_launch_reward_button'),
                    tooltip: '발사 취소 보조 사용',
                    visualDensity: VisualDensity.compact,
                    onPressed: onCancelReward,
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                  ),
                IconButton(
                  key: const Key('reset_button'),
                  tooltip: '단계 다시 시작',
                  visualDensity: VisualDensity.compact,
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh, size: 20),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showPrecisionControls) ...[
            _PrecisionAimControls(
              power: state.aimPower,
              onAimCounterClockwise: onAimCounterClockwise!,
              onAimClockwise: onAimClockwise!,
              onPowerDecrease: onPowerDecrease!,
              onPowerIncrease: onPowerIncrease!,
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(
                child: Semantics(
                  key: const Key('trait_effect_feedback_semantics'),
                  container: true,
                  liveRegion: effectFeedback != null,
                  label: effectFeedback,
                  excludeSemantics: effectFeedback != null,
                  child: Text(
                    effectFeedback ??
                        (state.equippedTrait != null
                            ? '공을 길게 눌러 힘 모으기'
                            : state.selectedTrait == null
                            ? state.traitSources.isEmpty
                                  ? '공을 길게 눌러 힘 모으기'
                                  : '물체를 눌러 속성 고르기'
                            : '선택: ${state.selectedTrait!.label}'),
                    key: const Key('trait_effect_feedback'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  state.equippedTrait == null
                      ? '공 속성: 없음'
                      : '공 속성: ${state.equippedTrait!.label} · '
                            '${state.equippedTrait!.compactEffect}',
                ),
              ),
              IconButton(
                key: const Key('rewind_button'),
                tooltip: '되감기',
                onPressed: onRewind,
                icon: const Icon(Icons.undo),
              ),
              if (canCancelReward)
                IconButton(
                  key: const Key('cancel_launch_reward_button'),
                  tooltip: '발사 취소 보조 사용',
                  onPressed: onCancelReward,
                  icon: const Icon(Icons.cancel_outlined),
                ),
              IconButton(
                key: const Key('reset_button'),
                tooltip: '단계 다시 시작',
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrecisionAimControls extends StatelessWidget {
  const _PrecisionAimControls({
    this.compact = false,
    required this.power,
    required this.onAimCounterClockwise,
    required this.onAimClockwise,
    required this.onPowerDecrease,
    required this.onPowerIncrease,
  });

  final bool compact;
  final double power;
  final VoidCallback onAimCounterClockwise;
  final VoidCallback onAimClockwise;
  final VoidCallback onPowerDecrease;
  final VoidCallback onPowerIncrease;

  @override
  Widget build(BuildContext context) {
    Widget control({
      required Key key,
      required String tooltip,
      required IconData icon,
      required VoidCallback onPressed,
    }) => IconButton(
      key: key,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: BoxConstraints.tightFor(
        width: compact ? 40 : 44,
        height: compact ? 36 : 44,
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: compact ? 19 : 21),
    );

    return Semantics(
      key: const Key('precision_aim_controls'),
      container: true,
      label: '정밀 조작 도움. 현재 힘 ${(power * 100).round()}퍼센트',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!compact)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text(
                '정밀 조작',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          if (compact)
            const Text(
              '각도',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          control(
            key: const Key('precision_aim_counter_clockwise'),
            tooltip: '조준을 반시계 방향으로 조금 이동',
            icon: Icons.rotate_left,
            onPressed: onAimCounterClockwise,
          ),
          control(
            key: const Key('precision_aim_clockwise'),
            tooltip: '조준을 시계 방향으로 조금 이동',
            icon: Icons.rotate_right,
            onPressed: onAimClockwise,
          ),
          const SizedBox(width: 4),
          if (compact)
            const Text(
              '힘',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          control(
            key: const Key('precision_power_decrease'),
            tooltip: '힘을 한 칸 줄이기',
            icon: Icons.remove_circle_outline,
            onPressed: onPowerDecrease,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '${(power * 100).round()}%',
              key: const Key('precision_power_value'),
              style: TextStyle(
                fontSize: compact ? 11 : 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          control(
            key: const Key('precision_power_increase'),
            tooltip: '힘을 한 칸 늘리기',
            icon: Icons.add_circle_outline,
            onPressed: onPowerIncrease,
          ),
        ],
      ),
    );
  }
}

class _InfoPopup extends StatelessWidget {
  const _InfoPopup({
    required this.child,
    required this.onClose,
    required this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onClose;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: FocusScope(
        autofocus: true,
        child: Stack(
          children: [
            const ModalBarrier(
              color: Color(0x22000000),
              dismissible: false,
              semanticsLabel: '정보 팝업이 열려 있습니다',
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 128,
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 420,
                      maxHeight: MediaQuery.sizeOf(context).height - 180,
                    ),
                    child: SingleChildScrollView(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Semantics(
                            container: true,
                            namesRoute: true,
                            label: semanticLabel,
                            child: Material(
                              color: Colors.transparent,
                              child: child,
                            ),
                          ),
                          Positioned(
                            top: -10,
                            right: -10,
                            child: IconButton.filled(
                              key: const Key('info_close_button'),
                              autofocus: true,
                              tooltip: '닫기',
                              onPressed: onClose,
                              icon: const Icon(Icons.close, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF24352D),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(48, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
                              ),
                            ),
                          ),
                        ],
                      ),
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

class _EntityInfoPanel extends StatelessWidget {
  const _EntityInfoPanel({
    required this.entity,
    required this.copyCharges,
    required this.copyCoreCount,
    this.onTransfer,
    this.onCopy,
  });

  final EntityState entity;
  final int copyCharges;
  final int copyCoreCount;
  final VoidCallback? onTransfer;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final trait = entity.traits.isEmpty ? null : entity.traits.first;
    final hasCopyCore = copyCoreCount > 0;
    final canManageTrait = onTransfer != null || onCopy != null;
    return Container(
      key: const Key('entity_info_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF59685F), width: 2),
      ),
      child: Row(
        children: [
          _EntityThumbnail(entity: entity),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entityName(entity),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  trait == null
                      ? _entityDescription(entity)
                      : '${trait.label}: ${trait.description}',
                ),
                if (entity.drainedTraits.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    key: const Key('drained_trait_status'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2E5D4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF9B6B4B)),
                    ),
                    child: Text(
                      '잃은 속성 · ${entity.drainedTraits.map((item) => item.label).join(' · ')}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF6C3F2B),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                if (entity.type == EntityType.ball) ...[
                  const SizedBox(height: 4),
                  Text(
                    _ballStatusDescription(entity),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF405D52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (entity.type == EntityType.rotatingReflector) ...[
                  const SizedBox(height: 4),
                  Text(
                    '현재 ${_reflectorDirectionLabel(entity.reflectorOrientation)} · '
                    '${entity.reflectorRotationCount}회 회전',
                    key: const Key('reflector_state_label'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF405D52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (trait != null && canManageTrait) ...[
                  const SizedBox(height: 4),
                  Text(
                    entity.movableWhenDrained
                        ? '옮기면 공은 ${trait.label} 능력을 얻고, 이 물체는 능력을 잃은 뒤 움직일 수 있습니다.'
                        : '옮기면 공은 ${trait.label} 능력을 얻고, 이 물체에서는 능력이 사라집니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF405D52),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (copyCharges > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      hasCopyCore
                          ? '옮기기: 원본에서 사라짐 · 복제 코어: 원본에 유지됨'
                          : '옮기기: 원본에서 사라짐 · 복사: 원본에 유지됨',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF59685F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCopyCore
                          ? '복제 코어 $copyCoreCount개 남음'
                          : '복사 $copyCharges회 남음',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF59685F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      Semantics(
                        label: '선택한 ${trait.label} 속성을 공으로 옮기기',
                        button: true,
                        child: FilledButton.icon(
                          key: const Key('transfer_button'),
                          onPressed: onTransfer,
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text('속성 옮기기'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      if (copyCharges > 0)
                        Semantics(
                          label: hasCopyCore
                              ? '선택한 ${trait.label} 속성을 복제 코어로 공에 복사하기'
                              : '선택한 ${trait.label} 속성을 원본에 남기고 공으로 복사하기',
                          button: true,
                          child: OutlinedButton.icon(
                            key: const Key('copy_button'),
                            onPressed: onCopy,
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(
                              hasCopyCore ? '복제 코어로 공에 담기' : '원본에 남기고 공에 복사하기',
                            ),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BallInfoPanel extends StatelessWidget {
  const _BallInfoPanel({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final trait = state.equippedTrait;
    return Container(
      key: const Key('ball_info_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF24352D), width: 2),
      ),
      child: Row(
        children: [
          _BallThumbnail(trait: trait),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trait == null ? '공 속성 없음' : '공 속성: ${trait.label}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(trait?.description ?? '속성 물체를 선택한 뒤 공으로 옮기세요.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityThumbnail extends StatelessWidget {
  const _EntityThumbnail({required this.entity});

  final EntityState entity;

  @override
  Widget build(BuildContext context) {
    final assetPath = _assetPath(entity);
    return Semantics(
      image: true,
      label: '${_entityName(entity)} 아이콘',
      child: _ThumbnailFrame(
        child: assetPath == null
            ? CustomPaint(
                painter: _EntityIconPainter(entity),
                size: const Size(44, 44),
              )
            : Padding(
                padding: const EdgeInsets.all(1),
                child: Image.asset(
                  assetPath,
                  key: Key('entity_thumbnail_${entity.type.name}'),
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
      ),
    );
  }
}

class _BallThumbnail extends StatelessWidget {
  const _BallThumbnail({required this.trait});

  final TraitType? trait;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: trait == null ? '공 아이콘' : '${trait!.label} 공 아이콘',
      child: _ThumbnailFrame(
        child: Image.asset(
          _ballAssetPath(trait),
          key: const Key('ball_thumbnail_asset'),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _ThumbnailFrame extends StatelessWidget {
  const _ThumbnailFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _EntityIconPainter extends CustomPainter {
  const _EntityIconPainter(this.entity);

  final EntityState entity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outline = Paint()
      ..color = const Color(0xFF24352D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    switch (entity.type) {
      case EntityType.hole:
        canvas.drawCircle(
          center.translate(-1, 3),
          9,
          Paint()..color = Colors.black87,
        );
        canvas.drawLine(
          center.translate(7, 3),
          center.translate(7, -12),
          Paint()
            ..color = const Color(0xFF6B4B35)
            ..strokeWidth = 2,
        );
        final flag = Path()
          ..moveTo(center.dx + 8, center.dy - 12)
          ..lineTo(center.dx + 21, center.dy - 8)
          ..lineTo(center.dx + 8, center.dy - 4)
          ..close();
        canvas.drawPath(flag, Paint()..color = const Color(0xFFFF6B6B));
      case EntityType.wall:
        final brick = Paint()..color = const Color(0xFF798A8C);
        for (var y = 7.0; y < 29; y += 9) {
          for (var x = y == 16 ? 1.0 : 6.0; x < 31; x += 13) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 11, 7),
                const Radius.circular(2),
              ),
              brick,
            );
          }
        }
      case EntityType.bumper:
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 26, height: 20),
          Paint()..color = const Color(0xFF4EAF7C),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(-3, -3),
            width: 12,
            height: 7,
          ),
          Paint()..color = const Color(0xAAFFFFFF),
        );
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 26, height: 20),
          outline,
        );
      case EntityType.stickySurface:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 26, height: 22),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFF8E5AA9),
        );
        final dot = Paint()..color = const Color(0xAAFFFFFF);
        canvas.drawCircle(center.translate(-7, -4), 3, dot);
        canvas.drawCircle(center.translate(5, 4), 4, dot);
        canvas.drawCircle(center.translate(9, -6), 2, dot);
      case EntityType.switchPad:
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 26, height: 16),
          const Radius.circular(7),
        );
        canvas.drawRRect(
          body,
          Paint()
            ..color = entity.pressed
                ? const Color(0xFF4EAF7C)
                : const Color(0xFFE2C044),
        );
        canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFFFF2A8));
        canvas.drawRRect(body, outline);
      case EntityType.gate:
        final gatePaint = Paint()
          ..color = entity.open
              ? const Color(0x884EAF7C)
              : const Color(0xFFC24E3A)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          center.translate(-6, -11),
          center.translate(-6, 11),
          gatePaint,
        );
        canvas.drawLine(
          center.translate(6, -11),
          center.translate(6, 11),
          gatePaint,
        );
        canvas.drawLine(
          center.translate(-11, -8),
          center.translate(11, -8),
          outline,
        );
        canvas.drawLine(
          center.translate(-11, 8),
          center.translate(11, 8),
          outline,
        );
      case EntityType.balloon:
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(0, -2),
            width: 22,
            height: 28,
          ),
          Paint()..color = const Color(0xFFF28A78),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(0, -2),
            width: 22,
            height: 28,
          ),
          outline,
        );
        canvas.drawCircle(
          center.translate(-4, -8),
          3,
          Paint()..color = const Color(0xCCFFF7DD),
        );
        canvas.drawLine(
          center.translate(0, 12),
          center.translate(2, 20),
          outline,
        );
      case EntityType.spikeSource:
        canvas.drawCircle(center, 7, Paint()..color = const Color(0xFFF08B78));
        for (var index = 0; index < 6; index++) {
          final angle = index * math.pi / 3;
          canvas.drawLine(
            center + Offset(math.cos(angle), math.sin(angle)) * 6,
            center + Offset(math.cos(angle), math.sin(angle)) * 13,
            Paint()
              ..color = const Color(0xFFFFE49B)
              ..strokeWidth = 2.5,
          );
        }
      case EntityType.powerSlider:
        final visualDirection =
            entity.direction.x.isFinite &&
                entity.direction.y.isFinite &&
                entity.direction.length > 0.0001
            ? entity.direction.normalized()
            : const Vec2(1, 0);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.atan2(visualDirection.y, visualDirection.x));
        final slider = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 28, height: 18),
          const Radius.circular(6),
        );
        canvas.drawRRect(slider, Paint()..color = const Color(0xFF6EA8E0));
        canvas.drawLine(const Offset(-8, 0), const Offset(8, 0), outline);
        canvas.drawLine(const Offset(3, -4), const Offset(8, 0), outline);
        canvas.drawLine(const Offset(3, 4), const Offset(8, 0), outline);
        canvas.restore();
      case EntityType.rotatingReflector:
        final angle = -math.pi / 2 + entity.reflectorOrientation * math.pi / 4;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle + math.pi / 2);
        final panel = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 28, height: 8),
          const Radius.circular(3),
        );
        canvas.drawRRect(panel, Paint()..color = const Color(0xFFE0A45D));
        canvas.drawRRect(panel, outline);
        canvas.restore();
      case EntityType.ball:
      case EntityType.crate:
      case EntityType.weight:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _EntityIconPainter oldDelegate) =>
      oldDelegate.entity.type != entity.type ||
      oldDelegate.entity.open != entity.open ||
      oldDelegate.entity.pressed != entity.pressed ||
      oldDelegate.entity.direction != entity.direction ||
      oldDelegate.entity.reflectorOrientation != entity.reflectorOrientation ||
      oldDelegate.entity.reflectorRotationCount !=
          entity.reflectorRotationCount;
}

String? _assetPath(EntityState entity) {
  if (_isHiddenMechanic(entity)) {
    return 'assets/generated/mystery-crate-v1.png';
  }
  return switch (entity.type) {
    EntityType.ball => _ballAssetPath(
      entity.traits.isEmpty ? null : entity.traits.first,
    ),
    EntityType.hole => 'assets/generated/hole-flag-v1.png',
    EntityType.wall => 'assets/generated/wall-segment-v1.png',
    EntityType.crate => 'assets/generated/crate-v3.png',
    EntityType.weight => 'assets/generated/stone-v3.png',
    EntityType.bumper => 'assets/generated/jelly-bumper-v2.png',
    EntityType.stickySurface => 'assets/generated/sticky-pad-v1.png',
    EntityType.switchPad => 'assets/generated/switch-pad-v1.png',
    EntityType.gate => 'assets/generated/gate-closed-v1.png',
    EntityType.balloon => 'assets/generated/balloon-v1.png',
    EntityType.spikeSource => 'assets/generated/spike-source-v1.png',
    EntityType.powerSlider => 'assets/generated/power-slider-v1.png',
    EntityType.rotatingReflector =>
      'assets/generated/rotating-reflector-v1.png',
  };
}

String _ballAssetPath(TraitType? trait) => switch (trait) {
  TraitType.heavy => 'assets/generated/ball-heavy-v1.png',
  TraitType.bouncy => 'assets/generated/ball-bouncy-v1.png',
  TraitType.sticky => 'assets/generated/ball-sticky-v1.png',
  TraitType.sharp => 'assets/generated/ball-sharp-v1.png',
  null => 'assets/generated/ball-base-v1.png',
};

String _entityName(EntityState entity) {
  if (_isHiddenMechanic(entity)) {
    return '미스터리 상자';
  }
  switch (entity.type) {
    case EntityType.ball:
      return _ballDisplayName(entity);
    case EntityType.hole:
      return '홀';
    case EntityType.wall:
      return '벽';
    case EntityType.crate:
      return '상자';
    case EntityType.bumper:
      return '젤리';
    case EntityType.stickySurface:
      return '점착판';
    case EntityType.weight:
      return '무거운 돌';
    case EntityType.switchPad:
      return '스위치';
    case EntityType.gate:
      return '문';
    case EntityType.balloon:
      return '풍선';
    case EntityType.spikeSource:
      return '가시 성게';
    case EntityType.powerSlider:
      return '파워 슬라이더';
    case EntityType.rotatingReflector:
      return '회전 반사판';
  }
}

String _ballDisplayName(EntityState entity) {
  if (entity.id == 'active_ball') {
    return '공';
  }
  final match = RegExp(r'^spent_ball_(\d+)$').firstMatch(entity.id);
  final number = match == null ? null : int.tryParse(match.group(1)!);
  const ordinalNames = [
    '첫 번째',
    '두 번째',
    '세 번째',
    '네 번째',
    '다섯 번째',
    '여섯 번째',
    '일곱 번째',
    '여덟 번째',
  ];
  if (number != null && number >= 1 && number <= ordinalNames.length) {
    return '${ordinalNames[number - 1]} 공';
  }
  return '과거 공';
}

String _ballStatusLabel(EntityState entity) {
  final trait = entity.traits.isEmpty ? '속성 없음' : entity.traits.first.label;
  final mobility = entity.movable
      ? '다음 충돌에서 움직일 수 있음'
      : entity.visualState == 'stuck'
      ? '점착으로 고정됨'
      : '고정됨';
  return '$trait · $mobility';
}

String _ballStatusDescription(EntityState entity) {
  final mobility = entity.movable
      ? '다음 충돌에서 움직일 수 있음'
      : entity.visualState == 'stuck'
      ? '점착으로 고정됨'
      : '고정됨';
  final state = entity.id == 'active_ball'
      ? '발사를 준비하는 공입니다.'
      : entity.visualState == 'stuck'
      ? '점착으로 멈춰 다음 공의 충돌 기준점이 됩니다.'
      : '발사된 뒤에도 필드에 남아 다음 공과 충돌할 수 있습니다.';
  return '$mobility. $state';
}

String _entityDescription(EntityState entity) {
  if (_isHiddenMechanic(entity)) {
    return '주변 조건을 달성하면 안에 숨은 기믹이 드러납니다.';
  }
  if (entity.visualState == 'drained') {
    final lostTrait = entity.drainedTraits.isEmpty
        ? null
        : entity.drainedTraits.first;
    if (lostTrait != null) {
      return '${lostTrait.label}을 잃었습니다. '
          '${traitLossConsequence(entity, lostTrait)}. 물체 형태와 충돌 판정은 남습니다.';
    }
    return '속성을 잃었지만 물체 형태와 충돌 판정은 남아 있습니다.';
  }
  switch (entity.type) {
    case EntityType.ball:
      return '다음 발사와 충돌할 수 있는 공입니다.';
    case EntityType.hole:
      return '공이 들어가야 하는 목표 지점입니다.';
    case EntityType.wall:
      return '움직이지 않는 고정 벽입니다. 공은 맞고 튕깁니다.';
    case EntityType.crate:
      return '충격을 받으면 밀릴 수 있는 상자입니다.';
    case EntityType.bumper:
      return '탄성을 가진 젤리 물체입니다.';
    case EntityType.stickySurface:
      return '부딪힌 공을 붙잡아 멈추게 하는 표면입니다.';
    case EntityType.weight:
      return '무거움 속성을 가진 돌입니다.';
    case EntityType.switchPad:
      return '무거운 공만 누를 수 있습니다. 누르면 반짝이며 문이 열립니다.';
    case EntityType.gate:
      return entity.open ? '열려 있는 문입니다.' : '닫힌 문입니다. 공은 맞고 튕깁니다.';
    case EntityType.balloon:
      return '일반 공에는 밀리고 뾰족한 공에는 터지는 풍선입니다.';
    case EntityType.spikeSource:
      return '공에 옮기면 풍선을 터뜨릴 수 있는 뾰족함을 줍니다.';
    case EntityType.powerSlider:
      return '기물을 기준 속력까지 올립니다. 진행 방향은 유지되고 같은 접촉에는 한 번만 적용됩니다.';
    case EntityType.rotatingReflector:
      return '맞은 방향으로 공을 반사한 뒤 90도 회전합니다. 다음 충돌부터 새 방향을 사용합니다.';
  }
}

bool _isHiddenMechanic(EntityState entity) =>
    HiddenMechanicState.masksIdentity(entity.visualState);

String _reflectorDirectionLabel(int orientation) {
  return switch (orientation % 4) {
    0 => '가로 방향',
    1 => '왼쪽 위에서 오른쪽 아래 대각선',
    2 => '세로 방향',
    _ => '오른쪽 위에서 왼쪽 아래 대각선',
  };
}
