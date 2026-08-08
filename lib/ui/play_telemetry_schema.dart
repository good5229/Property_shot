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
  };
}

enum PlayTelemetryResult { continued, cleared, failed, cancelled, abandoned }

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

  Map<String, Object?> toJson() => {
    'stage_id': stageId,
    'pattern_id': patternId,
    'seed': seed,
    'resolver_version': resolverVersion,
    ...rewardState.toJson(),
    'is_replay': isReplay,
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

class TypedPlayTelemetryEvent {
  TypedPlayTelemetryEvent({
    required this.type,
    required this.context,
    this.shot,
    this.result,
  });

  final PlayTelemetryEventType type;
  final PlayTelemetryContext context;
  final PlayTelemetryShotPayload? shot;
  final PlayTelemetryResult? result;
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
