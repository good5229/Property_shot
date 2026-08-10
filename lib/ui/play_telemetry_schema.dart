enum PlayTelemetryEventType {
  runStarted,
  stagePatternDrawn,
  stageEntered,
  propertyPopupOpened,
  propertyTransferred,
  propertyCopied,
  aimStarted,
  chargeStageChanged,
  chargeCancelled,
  shotReleased,
  collisionChainCompleted,
  rewardOffered,
  rewardSelected,
  optionalChallengeCompleted,
  stageCleared,
  stageRetried,
  stageAbandoned,
  replayViewed,
  dailyChallengeStarted,
  runCompleted,
  hintRewardOffered,
  hintRewardSelected,
  hintAvailable,
  hintOpened,
  hintLevelOpened,
  keySpawned,
  keyCollected,
  keyIgnored,
  demoDirectClearDetected,
  powerGaugeChargeStarted,
  powerGaugeCancelled,
}

extension PlayTelemetryEventTypeMetadata on PlayTelemetryEventType {
  String get code => switch (this) {
    PlayTelemetryEventType.runStarted => 'run_started',
    PlayTelemetryEventType.stagePatternDrawn => 'stage_pattern_drawn',
    PlayTelemetryEventType.stageEntered => 'stage_entered',
    PlayTelemetryEventType.propertyPopupOpened => 'property_popup_opened',
    PlayTelemetryEventType.propertyTransferred => 'property_transferred',
    PlayTelemetryEventType.propertyCopied => 'property_copied',
    PlayTelemetryEventType.aimStarted => 'aim_started',
    PlayTelemetryEventType.chargeStageChanged => 'charge_stage_changed',
    PlayTelemetryEventType.chargeCancelled => 'charge_cancelled',
    PlayTelemetryEventType.shotReleased => 'shot_released',
    PlayTelemetryEventType.collisionChainCompleted =>
      'collision_chain_completed',
    PlayTelemetryEventType.rewardOffered => 'reward_offered',
    PlayTelemetryEventType.rewardSelected => 'reward_selected',
    PlayTelemetryEventType.optionalChallengeCompleted =>
      'optional_challenge_completed',
    PlayTelemetryEventType.stageCleared => 'stage_cleared',
    PlayTelemetryEventType.stageRetried => 'stage_retried',
    PlayTelemetryEventType.stageAbandoned => 'stage_abandoned',
    PlayTelemetryEventType.replayViewed => 'replay_viewed',
    PlayTelemetryEventType.dailyChallengeStarted => 'daily_challenge_started',
    PlayTelemetryEventType.runCompleted => 'run_completed',
    PlayTelemetryEventType.hintRewardOffered => 'hint_reward_offered',
    PlayTelemetryEventType.hintRewardSelected => 'hint_reward_selected',
    PlayTelemetryEventType.hintAvailable => 'hint_available',
    PlayTelemetryEventType.hintOpened => 'hint_opened',
    PlayTelemetryEventType.hintLevelOpened => 'hint_level_opened',
    PlayTelemetryEventType.keySpawned => 'key_spawned',
    PlayTelemetryEventType.keyCollected => 'key_collected',
    PlayTelemetryEventType.keyIgnored => 'key_ignored',
    PlayTelemetryEventType.demoDirectClearDetected =>
      'demo_direct_clear_detected',
    PlayTelemetryEventType.powerGaugeChargeStarted =>
      'power_gauge_charge_started',
    PlayTelemetryEventType.powerGaugeCancelled => 'power_gauge_cancelled',
  };

  String get displayName => switch (this) {
    PlayTelemetryEventType.runStarted => '런 시작',
    PlayTelemetryEventType.stagePatternDrawn => '단계 패턴 추첨',
    PlayTelemetryEventType.stageEntered => '단계 진입',
    PlayTelemetryEventType.propertyPopupOpened => '속성 정보 열기',
    PlayTelemetryEventType.propertyTransferred => '속성 이전',
    PlayTelemetryEventType.propertyCopied => '속성 복사',
    PlayTelemetryEventType.aimStarted => '조준 시작',
    PlayTelemetryEventType.chargeStageChanged => '충전 단계 변경',
    PlayTelemetryEventType.chargeCancelled => '충전 취소',
    PlayTelemetryEventType.shotReleased => '발사 완료',
    PlayTelemetryEventType.collisionChainCompleted => '충돌 연쇄 완료',
    PlayTelemetryEventType.rewardOffered => '보상 제시',
    PlayTelemetryEventType.rewardSelected => '보상 선택',
    PlayTelemetryEventType.optionalChallengeCompleted => '선택 도전 완료',
    PlayTelemetryEventType.stageCleared => '단계 클리어',
    PlayTelemetryEventType.stageRetried => '단계 재시도',
    PlayTelemetryEventType.stageAbandoned => '단계 포기',
    PlayTelemetryEventType.replayViewed => '리플레이 보기',
    PlayTelemetryEventType.dailyChallengeStarted => '오늘의 도전 시작',
    PlayTelemetryEventType.runCompleted => '런 완료',
    PlayTelemetryEventType.hintRewardOffered => '다음 단계 팁 보상 제시',
    PlayTelemetryEventType.hintRewardSelected => '다음 단계 팁 보상 선택',
    PlayTelemetryEventType.hintAvailable => '팁 사용 가능',
    PlayTelemetryEventType.hintOpened => '팁 열기',
    PlayTelemetryEventType.hintLevelOpened => '팁 단계 열기',
    PlayTelemetryEventType.keySpawned => '열쇠 생성',
    PlayTelemetryEventType.keyCollected => '열쇠 획득',
    PlayTelemetryEventType.keyIgnored => '열쇠 미획득',
    PlayTelemetryEventType.demoDirectClearDetected => '시연 직선 클리어 감지',
    PlayTelemetryEventType.powerGaugeChargeStarted => '파워 게이지 충전 시작',
    PlayTelemetryEventType.powerGaugeCancelled => '파워 게이지 취소',
  };
}

enum PlayTelemetryResult { continued, cleared, failed, cancelled, abandoned }

enum PlayTelemetryDifficulty { normal, easy }

/// 힌트 접근권을 부여한 경로다. 저장 모델의 schemaName과 동일하게 유지한다.
enum PlayTelemetryHintSource {
  clearReward('clear_reward'),
  stageKey('stage_key');

  const PlayTelemetryHintSource(this.code);

  final String code;
}

/// 힌트 전문의 노출 단계를 닫힌 값으로 기록한다.
enum PlayTelemetryHintLevel {
  one(1),
  two(2);

  const PlayTelemetryHintLevel(this.value);

  final int value;
}

extension PlayTelemetryResultMetadata on PlayTelemetryResult {
  String get code => switch (this) {
    PlayTelemetryResult.continued => 'continued',
    PlayTelemetryResult.cleared => 'cleared',
    PlayTelemetryResult.failed => 'failed',
    PlayTelemetryResult.cancelled => 'cancelled',
    PlayTelemetryResult.abandoned => 'abandoned',
  };

  String get displayName => switch (this) {
    PlayTelemetryResult.continued => '계속',
    PlayTelemetryResult.cleared => '성공',
    PlayTelemetryResult.failed => '실패',
    PlayTelemetryResult.cancelled => '취소',
    PlayTelemetryResult.abandoned => '포기',
  };
}

class PlayTelemetryRewardState {
  PlayTelemetryRewardState({
    Iterable<String> candidateIds = const [],
    this.selectedId,
    Iterable<String> acquiredIds = const [],
    this.cloneCoreCount = 0,
  }) : candidateIds = List.unmodifiable(candidateIds),
       acquiredIds = List.unmodifiable(acquiredIds) {
    _requireIds(this.candidateIds, '보상 후보');
    _requireIds(this.acquiredIds, '획득 보상');
    if (selectedId != null) _requireId(selectedId!, '선택 보상');
    _requireNonNegative(cloneCoreCount, '복제 코어 수');
  }

  final List<String> candidateIds;
  final String? selectedId;
  final List<String> acquiredIds;
  final int cloneCoreCount;

  Map<String, Object?> toJson() => {
    'reward_candidate_ids': candidateIds,
    if (selectedId != null) 'reward_selected_id': selectedId,
    'reward_acquired_ids': acquiredIds,
    'clone_core_count': cloneCoreCount,
  };
}

class PlayTelemetryContext {
  PlayTelemetryContext({
    required this.stageIndex,
    required this.stageId,
    required this.patternId,
    required this.seed,
    required this.resolverVersion,
    required this.rewardState,
    this.isReplay = false,
    this.difficulty = PlayTelemetryDifficulty.normal,
  }) {
    _requireNonNegative(stageIndex, '단계 인덱스');
    if (seed < 0 || seed > 0xffffffff) {
      throw ArgumentError.value(seed, 'seed', '시드는 부호 없는 32비트 범위여야 합니다.');
    }
    _requireId(stageId, '단계 ID');
    _requireId(patternId, '패턴 ID');
    _requireId(resolverVersion, '판정기 버전');
  }

  final int stageIndex;
  final String stageId;
  final String patternId;
  final int seed;
  final String resolverVersion;
  final PlayTelemetryRewardState rewardState;
  final bool isReplay;
  final PlayTelemetryDifficulty difficulty;
  bool get aimAssistEnabled => difficulty == PlayTelemetryDifficulty.easy;

  PlayTelemetryContext copyWith({PlayTelemetryDifficulty? difficulty}) =>
      PlayTelemetryContext(
        stageIndex: stageIndex,
        stageId: stageId,
        patternId: patternId,
        seed: seed,
        resolverVersion: resolverVersion,
        rewardState: rewardState,
        isReplay: isReplay,
        difficulty: difficulty ?? this.difficulty,
      );

  Map<String, Object?> toJson() => {
    'stage_id': stageId,
    'pattern_id': patternId,
    'seed': seed,
    'resolver_version': resolverVersion,
    ...rewardState.toJson(),
    'is_replay': isReplay,
    'difficulty_mode': difficulty.name,
    'aim_assist_enabled': aimAssistEnabled,
  };
}

class PlayTelemetryShotPayload {
  PlayTelemetryShotPayload({
    required this.shotId,
    required this.angle,
    required this.power,
    Iterable<String> ballTraits = const [],
    Iterable<String> causalChain = const [],
    required this.causalDepth,
    required this.effectiveChainLength,
    required this.distinctObjectTypeCount,
    required this.distinctObjectCount,
    required this.wallUseCount,
    required this.ballUseCount,
    required this.objectUseCount,
    required this.scoreDamped,
    required this.nearestHoleDistance,
    required this.frameDurationMs,
    required this.inputLatencyMs,
    required this.result,
  }) : ballTraits = List.unmodifiable(ballTraits),
       causalChain = List.unmodifiable(causalChain) {
    _requireNonNegative(shotId, '발사 ID');
    _requireFinite(angle, '각도');
    _requireFinite(power, '힘');
    if (power < 0 || power > 1) {
      throw ArgumentError.value(power, 'power', '힘은 0 이상 1 이하여야 합니다.');
    }
    _requireIds(this.ballTraits, '공 속성');
    _requireIds(this.causalChain, '충돌 인과 사슬');
    _requireNonNegative(causalDepth, '인과 깊이');
    _requireNonNegative(effectiveChainLength, '유효 연쇄 길이');
    _requireNonNegative(distinctObjectTypeCount, '서로 다른 기물 타입 수');
    _requireNonNegative(distinctObjectCount, '개별 기물 수');
    _requireNonNegative(wallUseCount, '벽 활용 수');
    _requireNonNegative(ballUseCount, '공 활용 수');
    _requireNonNegative(objectUseCount, '기물 활용 수');
    _requireFiniteNonNegative(nearestHoleDistance, '홀 최근접 거리');
    _requireFiniteNonNegative(frameDurationMs, '프레임 시간');
    _requireFiniteNonNegative(inputLatencyMs, '입력 지연');
  }

  final int shotId;
  final double angle;
  final double power;
  final List<String> ballTraits;
  final List<String> causalChain;
  final int causalDepth;
  final int effectiveChainLength;
  final int distinctObjectTypeCount;
  final int distinctObjectCount;
  final int wallUseCount;
  final int ballUseCount;
  final int objectUseCount;
  final bool scoreDamped;
  final double nearestHoleDistance;
  final double frameDurationMs;
  final double inputLatencyMs;
  final PlayTelemetryResult result;

  Map<String, Object?> toJson() => {
    'shot_id': shotId,
    '각도': angle,
    '힘': power,
    'ball_traits': ballTraits,
    'causal_chain': causalChain,
    'causal_depth': causalDepth,
    'effective_chain_length': effectiveChainLength,
    'distinct_object_type_count': distinctObjectTypeCount,
    'distinct_object_count': distinctObjectCount,
    'wall_use_count': wallUseCount,
    'ball_use_count': ballUseCount,
    'object_use_count': objectUseCount,
    'score_damped': scoreDamped,
    'nearest_hole_distance': nearestHoleDistance,
    'frame_duration_ms': frameDurationMs,
    'input_latency_ms': inputLatencyMs,
    'telemetry_result': result.code,
  };
}

/// 힌트 접근권과 실제 열람을 함께 분석할 수 있는 보조 payload다.
///
/// HintIdentity 자체의 문구는 기록하지 않는다. 패턴을 식별하는 공통 문맥과
/// source/level만 남겨 개인정보나 정답 궤적 없이 효과를 비교할 수 있다.
class PlayTelemetryHintPayload {
  PlayTelemetryHintPayload({
    required this.source,
    required this.level,
    this.openedCount = 0,
    this.failureCountBeforeOpen = 0,
    this.clearedAfterOpen = false,
  }) {
    _requireNonNegative(openedCount, '힌트 열람 횟수');
    _requireNonNegative(failureCountBeforeOpen, '힌트 열람 전 실패 횟수');
  }

  final PlayTelemetryHintSource source;
  final PlayTelemetryHintLevel level;
  final int openedCount;
  final int failureCountBeforeOpen;
  final bool clearedAfterOpen;

  Map<String, Object?> toJson() => {
    'hint_source': source.code,
    'hint_level': level.value,
    'hint_opened_count': openedCount,
    'hint_failure_count_before_open': failureCountBeforeOpen,
    'hint_cleared_after_open': clearedAfterOpen,
  };
}

/// 열쇠의 생성·획득·미획득을 동일한 ID와 발사 기준으로 남기는 payload다.
class PlayTelemetryKeyPayload {
  PlayTelemetryKeyPayload({
    required this.keyId,
    required this.shotId,
    required this.collected,
    this.shotsUntilCollected,
  }) {
    _requireId(keyId, '열쇠 ID');
    _requireNonNegative(shotId, '열쇠 이벤트 발사 ID');
    if (shotsUntilCollected != null) {
      _requireNonNegative(shotsUntilCollected!, '열쇠 획득까지 발사 수');
    }
    if (collected != (shotsUntilCollected != null)) {
      throw ArgumentError('열쇠 획득 이벤트에만 획득까지 발사 수를 기록해야 합니다.');
    }
  }

  final String keyId;
  final int shotId;
  final bool collected;
  final int? shotsUntilCollected;

  Map<String, Object?> toJson() => {
    'key_id': keyId,
    'key_shot_id': shotId,
    'key_collected': collected,
    if (shotsUntilCollected != null)
      'key_shots_until_collected': shotsUntilCollected,
  };
}

/// 스테이지 완료 시 힌트·열쇠·직선 클리어·기믹 효과를 같이 분석하는 payload다.
class PlayTelemetryStageOutcomePayload {
  PlayTelemetryStageOutcomePayload({
    required this.keyCollected,
    required this.directClear,
    required this.hintUsedBeforeClear,
    required this.failureCountBeforeHint,
    required this.failureCountAfterHint,
    required this.effectiveChainScore,
    Iterable<String> gimmickTypes = const [],
  }) : gimmickTypes = List.unmodifiable(gimmickTypes) {
    _requireNonNegative(failureCountBeforeHint, '힌트 전 실패 횟수');
    _requireNonNegative(failureCountAfterHint, '힌트 후 실패 횟수');
    _requireNonNegative(effectiveChainScore, '유효 연쇄 점수');
    _requireIds(this.gimmickTypes, '사용 기믹 타입');
  }

  final bool keyCollected;
  final bool directClear;
  final bool hintUsedBeforeClear;
  final int failureCountBeforeHint;
  final int failureCountAfterHint;
  final int effectiveChainScore;
  final List<String> gimmickTypes;

  Map<String, Object?> toJson() => {
    'key_collected_before_clear': keyCollected,
    'direct_clear': directClear,
    'hint_used_before_clear': hintUsedBeforeClear,
    'failure_count_before_hint': failureCountBeforeHint,
    'failure_count_after_hint': failureCountAfterHint,
    'gimmick_types': gimmickTypes,
    'effective_chain_score': effectiveChainScore,
  };
}

/// HUD 파워 게이지의 시작·취소 상태를 수치와 함께 기록한다.
class PlayTelemetryPowerGaugePayload {
  PlayTelemetryPowerGaugePayload({
    required this.chargeStage,
    required this.power,
    required this.cancelled,
  }) {
    _requireNonNegative(chargeStage, '파워 게이지 충전 단계');
    if (chargeStage > 4) {
      throw ArgumentError.value(
        chargeStage,
        'chargeStage',
        '충전 단계는 green~cancelledGray의 0~4여야 합니다.',
      );
    }
    _requireFinite(power, '파워 게이지 힘');
    if (power < 0 || power > 1) {
      throw ArgumentError.value(power, 'power', '힘은 0 이상 1 이하여야 합니다.');
    }
  }

  final int chargeStage;
  final double power;
  final bool cancelled;

  Map<String, Object?> toJson() => {
    'power_gauge_charge_stage': chargeStage,
    'power_gauge_power': power,
    'power_gauge_cancelled': cancelled,
  };
}

class TypedPlayTelemetryEvent {
  TypedPlayTelemetryEvent({
    required this.type,
    required this.context,
    this.shot,
    this.result,
    this.hint,
    this.key,
    this.stageOutcome,
    this.powerGauge,
  }) {
    switch (type) {
      case PlayTelemetryEventType.hintRewardOffered:
      case PlayTelemetryEventType.hintRewardSelected:
      case PlayTelemetryEventType.hintAvailable:
      case PlayTelemetryEventType.hintOpened:
      case PlayTelemetryEventType.hintLevelOpened:
        if (hint == null) {
          throw ArgumentError('힌트 관련 이벤트에는 hint payload가 필요합니다.');
        }
        if ((type == PlayTelemetryEventType.hintRewardOffered ||
                type == PlayTelemetryEventType.hintRewardSelected) &&
            hint!.source != PlayTelemetryHintSource.clearReward) {
          throw ArgumentError('힌트 보상 이벤트의 source는 clear_reward여야 합니다.');
        }
        break;
      case PlayTelemetryEventType.keySpawned:
      case PlayTelemetryEventType.keyCollected:
      case PlayTelemetryEventType.keyIgnored:
        if (key == null) {
          throw ArgumentError('열쇠 관련 이벤트에는 key payload가 필요합니다.');
        }
        if ((type == PlayTelemetryEventType.keySpawned ||
                type == PlayTelemetryEventType.keyIgnored) &&
            key!.collected) {
          throw ArgumentError('생성·미획득 열쇠 이벤트는 collected=false여야 합니다.');
        }
        if (type == PlayTelemetryEventType.keyCollected && !key!.collected) {
          throw ArgumentError('열쇠 획득 이벤트는 collected=true여야 합니다.');
        }
        break;
      case PlayTelemetryEventType.demoDirectClearDetected:
        if (stageOutcome == null || !stageOutcome!.directClear) {
          throw ArgumentError('직선 클리어 감지에는 directClear outcome이 필요합니다.');
        }
        break;
      case PlayTelemetryEventType.stageCleared:
        if (result != PlayTelemetryResult.cleared || stageOutcome == null) {
          throw ArgumentError('단계 클리어 이벤트에는 cleared 결과와 stage outcome이 필요합니다.');
        }
        break;
      case PlayTelemetryEventType.powerGaugeChargeStarted:
        if (powerGauge == null || powerGauge!.cancelled) {
          throw ArgumentError('파워 충전 시작에는 취소되지 않은 gauge payload가 필요합니다.');
        }
        break;
      case PlayTelemetryEventType.powerGaugeCancelled:
        if (powerGauge == null || !powerGauge!.cancelled) {
          throw ArgumentError('파워 게이지 취소에는 cancelled gauge payload가 필요합니다.');
        }
        break;
      default:
        break;
    }
  }

  final PlayTelemetryEventType type;
  final PlayTelemetryContext context;
  final PlayTelemetryShotPayload? shot;
  final PlayTelemetryResult? result;
  final PlayTelemetryHintPayload? hint;
  final PlayTelemetryKeyPayload? key;
  final PlayTelemetryStageOutcomePayload? stageOutcome;
  final PlayTelemetryPowerGaugePayload? powerGauge;
}

void _requireId(String value, String label) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, label, '$label 값은 비어 있을 수 없습니다.');
  }
}

void _requireIds(Iterable<String> values, String label) {
  for (final value in values) {
    _requireId(value, label);
  }
}

void _requireNonNegative(int value, String label) {
  if (value < 0) {
    throw ArgumentError.value(value, label, '$label 값은 음수일 수 없습니다.');
  }
}

void _requireFinite(double value, String label) {
  if (!value.isFinite) {
    throw ArgumentError.value(value, label, '$label 값은 유한해야 합니다.');
  }
}

void _requireFiniteNonNegative(double value, String label) {
  _requireFinite(value, label);
  if (value < 0) {
    throw ArgumentError.value(value, label, '$label 값은 음수일 수 없습니다.');
  }
}
