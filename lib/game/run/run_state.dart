import 'dart:convert';

import '../domain/geometry.dart';
import '../domain/stage_pattern.dart';
import '../domain/trait.dart';
import 'stage_shuffle_bag.dart';

const int currentRunStateSchemaVersion = 1;

enum RunPhase {
  playing,
  stageCompleted,
  rewardSelectionPending,
  rewardSelectionCompleted,
  runCompleted,
}

String runPhaseToSchemaName(RunPhase phase) {
  switch (phase) {
    case RunPhase.playing:
      return 'playing';
    case RunPhase.stageCompleted:
      return 'stage_completed';
    case RunPhase.rewardSelectionPending:
      return 'reward_selection_pending';
    case RunPhase.rewardSelectionCompleted:
      return 'reward_selection_completed';
    case RunPhase.runCompleted:
      return 'run_completed';
  }
}

RunPhase runPhaseFromSchemaName(String value) {
  switch (value) {
    case 'playing':
      return RunPhase.playing;
    case 'stage_completed':
      return RunPhase.stageCompleted;
    case 'reward_selection_pending':
      return RunPhase.rewardSelectionPending;
    case 'reward_selection_completed':
      return RunPhase.rewardSelectionCompleted;
    case 'run_completed':
      return RunPhase.runCompleted;
    default:
      throw FormatException('run phase: 알 수 없는 단계 "$value"');
  }
}

/// 패턴을 뽑은 순서를 저장한다. 같은 patternId가 다른 cycle에서 다시
/// 등장할 수 있으므로 cycle과 drawIndex를 함께 보존한다.
class PatternDrawRecord {
  PatternDrawRecord({
    required this.stageId,
    required this.patternId,
    required this.patternSeed,
    required this.cycle,
    required this.drawIndex,
  }) {
    _validateId(stageId, 'stageId');
    _validateId(patternId, 'patternId');
    _validateSeed(patternSeed, 'patternSeed');
    _validateNonNegative(cycle, 'cycle');
    _validateNonNegative(drawIndex, 'drawIndex');
  }

  final String stageId;
  final String patternId;
  final int patternSeed;
  final int cycle;
  final int drawIndex;

  factory PatternDrawRecord.fromDraw(StagePatternDraw draw) {
    return PatternDrawRecord(
      stageId: draw.stageId,
      patternId: draw.patternId,
      patternSeed: draw.patternSeed,
      cycle: draw.cycle,
      drawIndex: draw.drawIndex,
    );
  }

  factory PatternDrawRecord.fromJson(Map<String, dynamic> json) {
    return PatternDrawRecord(
      stageId: _requiredString(json, 'stageId', 'pattern draw'),
      patternId: _requiredString(json, 'patternId', 'pattern draw'),
      patternSeed: _requiredSeed(json, 'patternSeed', 'pattern draw'),
      cycle: _requiredNonNegativeInt(json, 'cycle', 'pattern draw'),
      drawIndex: _requiredNonNegativeInt(json, 'drawIndex', 'pattern draw'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'patternId': patternId,
      'patternSeed': patternSeed,
      'cycle': cycle,
      'drawIndex': drawIndex,
    };
  }
}

/// 재현에 필요한 한 번의 발사 입력이다.
enum RunTraitAction { transfer, copy }

String stageCloneCoreRewardId(String stageId) => 'stage_clone_core:$stageId';

const legacyStageCloneCoreRewardId = 'stage_clone_core:legacy';
const legacyCloneCoreRewardStageId = 'stage_chain_gate';

bool hasStageCloneCoreReward(Iterable<String> rewards, String stageId) =>
    rewards.contains(stageCloneCoreRewardId(stageId));

bool hasAnyStageCloneCoreReward(Iterable<String> rewards) =>
    rewards.any((reward) => reward.startsWith('stage_clone_core:'));

Set<String> stageCloneCoreRewardStageIds(Iterable<String> rewards) => {
  for (final reward in rewards)
    if (reward.startsWith('stage_clone_core:') &&
        reward != legacyStageCloneCoreRewardId)
      reward.substring('stage_clone_core:'.length),
};

class RunTraitActionRecord {
  const RunTraitActionRecord({required this.sourceId, required this.action});

  final String sourceId;
  final RunTraitAction action;

  factory RunTraitActionRecord.fromJson(Map<String, dynamic> json) {
    final sourceId = _requiredString(json, 'sourceId', 'trait action');
    final action = _requiredString(json, 'action', 'trait action');
    try {
      return RunTraitActionRecord(
        sourceId: sourceId,
        action: RunTraitAction.values.byName(action),
      );
    } on ArgumentError {
      throw FormatException('trait action: 알 수 없는 action입니다: $action');
    }
  }

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'action': action.name,
  };
}

class RunShotInput {
  RunShotInput({
    required this.stageId,
    required this.patternId,
    this.patternSeed,
    required this.shotIndex,
    required this.direction,
    required this.power,
    this.equippedTrait,
    Iterable<RunTraitActionRecord> traitActions = const [],
  }) : traitActions = List.unmodifiable(traitActions) {
    _validateId(stageId, 'stageId');
    _validateId(patternId, 'patternId');
    if (patternSeed != null) {
      _validateSeed(patternSeed!, 'patternSeed');
    }
    _validateNonNegative(shotIndex, 'shotIndex');
    _validateVec2(direction, 'direction');
    if (!power.isFinite || power < 0 || power > 1) {
      throw ArgumentError.value(power, 'power', '0 이상 1 이하의 유한한 수여야 합니다.');
    }
    for (final action in this.traitActions) {
      _validateId(action.sourceId, 'trait action sourceId');
    }
  }

  final String stageId;
  final String patternId;
  final int? patternSeed;
  final int shotIndex;
  final Vec2 direction;
  final double power;
  final TraitType? equippedTrait;
  final List<RunTraitActionRecord> traitActions;

  factory RunShotInput.fromJson(Map<String, dynamic> json) {
    final trait = json['equippedTrait'];
    if (trait != null && trait is! String) {
      throw const FormatException('shot input: equippedTrait가 문자열이 아닙니다.');
    }
    final actions = _traitActionsFromShotJson(json);
    return RunShotInput(
      stageId: _requiredString(json, 'stageId', 'shot input'),
      patternId: _requiredString(json, 'patternId', 'shot input'),
      patternSeed: json.containsKey('patternSeed')
          ? _nullableSeed(json, 'patternSeed', 'shot input')
          : null,
      shotIndex: _requiredNonNegativeInt(json, 'shotIndex', 'shot input'),
      direction: _requiredVec2(json, 'direction', 'shot input'),
      power: _requiredFiniteDouble(json, 'power', 'shot input'),
      equippedTrait: trait == null ? null : traitTypeFromSchemaName(trait),
      traitActions: actions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'patternId': patternId,
      'patternSeed': patternSeed,
      'shotIndex': shotIndex,
      'direction': direction.toJson(),
      'power': power,
      'equippedTrait': equippedTrait == null
          ? null
          : traitTypeToSchemaName(equippedTrait!),
      'traitActions': traitActions.map((action) => action.toJson()).toList(),
    };
  }
}

List<RunTraitActionRecord> _traitActionsFromShotJson(
  Map<String, dynamic> json,
) {
  final rawActions = json['traitActions'];
  if (rawActions != null) {
    if (rawActions is! List) {
      throw const FormatException('shot input: traitActions가 목록이 아닙니다.');
    }
    return [
      for (final raw in rawActions)
        RunTraitActionRecord.fromJson(_mapValue(raw, 'shot trait action')),
    ];
  }
  final sourceId = json['traitSourceId'];
  final action = json['traitAction'];
  if (sourceId == null && action == null) return const [];
  if (sourceId is! String || action is! String) {
    throw const FormatException('shot input: 구형 속성 원본과 행동이 올바르지 않습니다.');
  }
  try {
    return [
      RunTraitActionRecord(
        sourceId: sourceId,
        action: RunTraitAction.values.byName(action),
      ),
    ];
  } on ArgumentError {
    throw FormatException('shot input: 알 수 없는 traitAction입니다: $action');
  }
}

// 이후 이름을 더 구체화해도 저장 모델의 의미를 잃지 않도록 한 별칭이다.
typedef ShotInputLogEntry = RunShotInput;
typedef PatternDrawHistoryEntry = PatternDrawRecord;

/// 진행 중인 한 번의 런을 재시작 후 그대로 복구하기 위한 불변 상태다.
class RunState {
  RunState({
    required this.schemaVersion,
    required this.runId,
    required this.rootSeed,
    required this.resolverVersion,
    required this.phase,
    required this.currentStageId,
    required this.currentPatternId,
    required this.currentPatternSeed,
    this.nextStageId,
    this.nextStagePatternId,
    this.nextStagePatternSeed,
    Iterable<PatternDrawRecord> patternDrawHistory = const [],
    Map<String, StageShuffleBagState> stageShuffleBags = const {},
    this.rewardCandidateSeed,
    Iterable<String> rewardCandidateIds = const [],
    this.selectedRewardId,
    Iterable<String> acquiredRewards = const [],
    required this.cloneCoreCount,
    Iterable<RunTraitActionRecord> pendingTraitActions = const [],
    Map<String, int> shotsPerStage = const {},
    Map<String, int> chainScoresPerStage = const {},
    Map<String, bool> optionalChallenges = const {},
    required this.totalScore,
    Map<String, String> replayReferences = const {},
    Iterable<RunShotInput> shotInputLog = const [],
    required this.startedAt,
    required this.updatedAt,
  }) : patternDrawHistory = List.unmodifiable(patternDrawHistory),
       stageShuffleBags = Map.unmodifiable(stageShuffleBags),
       rewardCandidateIds = List.unmodifiable(rewardCandidateIds),
       acquiredRewards = Set.unmodifiable(acquiredRewards),
       pendingTraitActions = List.unmodifiable(pendingTraitActions),
       shotsPerStage = Map.unmodifiable(shotsPerStage),
       chainScoresPerStage = Map.unmodifiable(chainScoresPerStage),
       optionalChallenges = Map.unmodifiable(optionalChallenges),
       replayReferences = Map.unmodifiable(replayReferences),
       shotInputLog = List.unmodifiable(shotInputLog) {
    _validateRunState(this);
  }

  final int schemaVersion;
  final String runId;
  final int rootSeed;
  final String resolverVersion;
  final RunPhase phase;

  final String? currentStageId;
  final String? currentPatternId;
  final int? currentPatternSeed;
  final String? nextStageId;
  final String? nextStagePatternId;
  final int? nextStagePatternSeed;

  final List<PatternDrawRecord> patternDrawHistory;
  final Map<String, StageShuffleBagState> stageShuffleBags;

  final int? rewardCandidateSeed;
  final List<String> rewardCandidateIds;
  final String? selectedRewardId;
  final Set<String> acquiredRewards;
  final int cloneCoreCount;
  final List<RunTraitActionRecord> pendingTraitActions;

  final Map<String, int> shotsPerStage;
  final Map<String, int> chainScoresPerStage;
  final Map<String, bool> optionalChallenges;
  final int totalScore;

  final Map<String, String> replayReferences;
  final List<RunShotInput> shotInputLog;
  final DateTime startedAt;
  final DateTime updatedAt;

  static RunState initial({
    required String runId,
    required int rootSeed,
    required String resolverVersion,
    required StagePatternDraw currentDraw,
    int cloneCoreCount = 0,
    Iterable<String> acquiredRewards = const [],
    StagePatternDraw? nextDraw,
    DateTime? now,
  }) {
    final timestamp = (now ?? DateTime.now()).toUtc();
    final drawHistory = <PatternDrawRecord>[
      PatternDrawRecord.fromDraw(currentDraw),
    ];
    final stageShuffleBags = <String, StageShuffleBagState>{
      currentDraw.stageId: currentDraw.nextState,
    };
    if (nextDraw != null) {
      drawHistory.add(PatternDrawRecord.fromDraw(nextDraw));
      stageShuffleBags[nextDraw.stageId] = nextDraw.nextState;
    }
    return RunState(
      schemaVersion: currentRunStateSchemaVersion,
      runId: runId,
      rootSeed: rootSeed,
      resolverVersion: resolverVersion,
      phase: RunPhase.playing,
      currentStageId: currentDraw.stageId,
      currentPatternId: currentDraw.patternId,
      currentPatternSeed: currentDraw.patternSeed,
      nextStageId: nextDraw?.stageId,
      nextStagePatternId: nextDraw?.patternId,
      nextStagePatternSeed: nextDraw?.patternSeed,
      patternDrawHistory: drawHistory,
      stageShuffleBags: stageShuffleBags,
      acquiredRewards: acquiredRewards,
      cloneCoreCount: cloneCoreCount,
      pendingTraitActions: const [],
      totalScore: 0,
      startedAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory RunState.fromJson(Map<String, dynamic> json) {
    try {
      final phaseValue = _requiredString(json, 'phase', 'run state');
      final stageBags = _requiredMap(json, 'stageShuffleBags', 'run state');
      final stageShuffleBags = <String, StageShuffleBagState>{};
      for (final entry in stageBags.entries) {
        stageShuffleBags[entry.key] = StageShuffleBagState.fromJson(
          _mapValue(entry.value, 'stageShuffleBags.${entry.key}'),
        );
      }

      return RunState(
        schemaVersion: _requiredNonNegativeInt(
          json,
          'schemaVersion',
          'run state',
        ),
        runId: _requiredString(json, 'runId', 'run state'),
        rootSeed: _requiredSeed(json, 'rootSeed', 'run state'),
        resolverVersion: _requiredString(json, 'resolverVersion', 'run state'),
        phase: runPhaseFromSchemaName(phaseValue),
        currentStageId: _nullableString(json, 'currentStageId', 'run state'),
        currentPatternId: _nullableString(
          json,
          'currentPatternId',
          'run state',
        ),
        currentPatternSeed: _nullableSeed(
          json,
          'currentPatternSeed',
          'run state',
        ),
        nextStageId: _nullableString(json, 'nextStageId', 'run state'),
        nextStagePatternId: _nullableString(
          json,
          'nextStagePatternId',
          'run state',
        ),
        nextStagePatternSeed: _nullableSeed(
          json,
          'nextStagePatternSeed',
          'run state',
        ),
        patternDrawHistory: _requiredList(
          json,
          'patternDrawHistory',
          'run state',
          PatternDrawRecord.fromJson,
        ),
        stageShuffleBags: stageShuffleBags,
        rewardCandidateSeed: _nullableSeed(
          json,
          'rewardCandidateSeed',
          'run state',
        ),
        rewardCandidateIds: _requiredStringList(
          json,
          'rewardCandidateIds',
          'run state',
        ),
        selectedRewardId: _nullableString(
          json,
          'selectedRewardId',
          'run state',
        ),
        acquiredRewards: _requiredStringSet(
          json,
          'acquiredRewards',
          'run state',
        ),
        cloneCoreCount: _requiredNonNegativeInt(
          json,
          'cloneCoreCount',
          'run state',
        ),
        pendingTraitActions: json.containsKey('pendingTraitActions')
            ? _requiredList(
                json,
                'pendingTraitActions',
                'run state',
                RunTraitActionRecord.fromJson,
              )
            : const [],
        shotsPerStage: _requiredNonNegativeIntMap(
          json,
          'shotsPerStage',
          'run state',
        ),
        chainScoresPerStage: _requiredNonNegativeIntMap(
          json,
          'chainScoresPerStage',
          'run state',
        ),
        optionalChallenges: _requiredBoolMap(
          json,
          'optionalChallenges',
          'run state',
        ),
        totalScore: _requiredNonNegativeInt(json, 'totalScore', 'run state'),
        replayReferences: _requiredStringMap(
          json,
          'replayReferences',
          'run state',
        ),
        shotInputLog: _requiredList(
          json,
          'shotInputLog',
          'run state',
          RunShotInput.fromJson,
        ),
        startedAt: _requiredUtcDateTime(json, 'startedAt', 'run state'),
        updatedAt: _requiredUtcDateTime(json, 'updatedAt', 'run state'),
      );
    } on FormatException {
      rethrow;
    } on ArgumentError catch (error) {
      throw FormatException('run state: ${error.message}');
    }
  }

  factory RunState.fromJsonString(String value) {
    try {
      return RunState.fromJson(_mapValue(jsonDecode(value), 'run state JSON'));
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('run state JSON을 읽을 수 없습니다: $error');
    }
  }

  Map<String, dynamic> toJson() {
    final sortedBags = <String, dynamic>{};
    for (final key in stageShuffleBags.keys.toList()..sort()) {
      sortedBags[key] = stageShuffleBags[key]!.toJson();
    }
    return {
      'schemaVersion': schemaVersion,
      'runId': runId,
      'rootSeed': rootSeed,
      'resolverVersion': resolverVersion,
      'phase': runPhaseToSchemaName(phase),
      'currentStageId': currentStageId,
      'currentPatternId': currentPatternId,
      'currentPatternSeed': currentPatternSeed,
      'nextStageId': nextStageId,
      'nextStagePatternId': nextStagePatternId,
      'nextStagePatternSeed': nextStagePatternSeed,
      'patternDrawHistory': patternDrawHistory
          .map((entry) => entry.toJson())
          .toList(),
      'stageShuffleBags': sortedBags,
      'rewardCandidateSeed': rewardCandidateSeed,
      'rewardCandidateIds': List<String>.from(rewardCandidateIds),
      'selectedRewardId': selectedRewardId,
      'acquiredRewards': acquiredRewards.toList()..sort(),
      'cloneCoreCount': cloneCoreCount,
      'pendingTraitActions': pendingTraitActions
          .map((action) => action.toJson())
          .toList(),
      'shotsPerStage': _sortedIntMap(shotsPerStage),
      'chainScoresPerStage': _sortedIntMap(chainScoresPerStage),
      'optionalChallenges': _sortedBoolMap(optionalChallenges),
      'totalScore': totalScore,
      'replayReferences': _sortedStringMap(replayReferences),
      'shotInputLog': shotInputLog.map((entry) => entry.toJson()).toList(),
      'startedAt': startedAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  String toJsonString() => jsonEncode(toJson());
}

void _validateRunState(RunState state) {
  if (state.schemaVersion != currentRunStateSchemaVersion) {
    throw ArgumentError.value(
      state.schemaVersion,
      'schemaVersion',
      '지원하지 않는 RunState schemaVersion입니다.',
    );
  }
  _validateId(state.runId, 'runId');
  _validateSeed(state.rootSeed, 'rootSeed');
  _validateId(state.resolverVersion, 'resolverVersion');
  _validateOptionalIdGroup([
    state.currentStageId,
    state.currentPatternId,
    state.currentPatternSeed,
  ], 'current pattern');
  _validateOptionalIdGroup([
    state.nextStageId,
    state.nextStagePatternId,
    state.nextStagePatternSeed,
  ], 'next pattern');

  final hasCurrent = state.currentStageId != null;
  if (state.phase != RunPhase.runCompleted && !hasCurrent) {
    throw ArgumentError('완료되지 않은 런에는 current pattern이 필요합니다.');
  }
  if (state.phase == RunPhase.playing ||
      state.phase == RunPhase.stageCompleted) {
    if (state.rewardCandidateSeed != null ||
        state.rewardCandidateIds.isNotEmpty ||
        state.selectedRewardId != null) {
      throw ArgumentError('플레이·단계 완료 단계에는 보상 후보가 없어야 합니다.');
    }
  }
  if (state.currentStageId != null &&
      state.nextStageId != null &&
      state.currentStageId == state.nextStageId) {
    throw ArgumentError('current와 next pattern은 같은 stage를 공유할 수 없습니다.');
  }
  _validatePatternTriplet(
    stageId: state.currentStageId,
    patternId: state.currentPatternId,
    patternSeed: state.currentPatternSeed,
    history: state.patternDrawHistory,
    stageShuffleBags: state.stageShuffleBags,
    label: 'current pattern',
    required:
        state.phase != RunPhase.runCompleted || state.currentStageId != null,
  );
  _validatePatternTriplet(
    stageId: state.nextStageId,
    patternId: state.nextStagePatternId,
    patternSeed: state.nextStagePatternSeed,
    history: state.patternDrawHistory,
    stageShuffleBags: state.stageShuffleBags,
    label: 'next pattern',
    required: state.nextStageId != null,
  );
  if (state.rewardCandidateIds.isEmpty) {
    if (state.rewardCandidateSeed != null || state.selectedRewardId != null) {
      throw ArgumentError('보상 후보가 없을 때 seed 또는 선택 보상을 저장할 수 없습니다.');
    }
  } else {
    if (state.rewardCandidateIds.length != 3) {
      throw ArgumentError('보상 후보는 정확히 3개여야 합니다.');
    }
    if (state.rewardCandidateSeed == null) {
      throw ArgumentError('보상 후보가 있으면 rewardCandidateSeed가 필요합니다.');
    }
    final ids = state.rewardCandidateIds.toSet();
    if (ids.length != state.rewardCandidateIds.length ||
        state.rewardCandidateIds.any((id) => id.isEmpty)) {
      throw ArgumentError('보상 후보 ID는 비어 있거나 중복될 수 없습니다.');
    }
    if (state.phase == RunPhase.rewardSelectionPending &&
        state.selectedRewardId != null) {
      throw ArgumentError('보상 선택 대기 중에는 selectedRewardId가 없어야 합니다.');
    }
    if (state.selectedRewardId != null &&
        !ids.contains(state.selectedRewardId)) {
      throw ArgumentError('selectedRewardId가 보상 후보에 없습니다.');
    }
    if ((state.phase == RunPhase.rewardSelectionCompleted ||
            state.phase == RunPhase.runCompleted) &&
        state.selectedRewardId == null) {
      throw ArgumentError('보상 선택 완료 단계에는 selectedRewardId가 필요합니다.');
    }
    if (state.phase == RunPhase.rewardSelectionCompleted &&
        !state.acquiredRewards.contains(state.selectedRewardId)) {
      throw ArgumentError('선택한 보상은 acquiredRewards에 포함되어야 합니다.');
    }
  }
  if (state.phase == RunPhase.rewardSelectionPending &&
      state.rewardCandidateIds.isEmpty) {
    throw ArgumentError('보상 선택 대기 중에는 보상 후보가 필요합니다.');
  }
  if (state.phase == RunPhase.rewardSelectionCompleted &&
      state.rewardCandidateIds.isEmpty) {
    throw ArgumentError('보상 선택 완료 단계에는 보상 후보가 필요합니다.');
  }

  _validateNonNegative(state.cloneCoreCount, 'cloneCoreCount');
  for (final action in state.pendingTraitActions) {
    _validateId(action.sourceId, 'pending trait action sourceId');
  }
  _validateNonNegative(state.totalScore, 'totalScore');
  _validateStringIntMap(state.shotsPerStage, 'shotsPerStage');
  _validateStringIntMap(state.chainScoresPerStage, 'chainScoresPerStage');
  for (final entry in state.optionalChallenges.entries) {
    _validateId(entry.key, 'optionalChallenges key');
  }
  for (final entry in state.replayReferences.entries) {
    _validateId(entry.key, 'replayReferences key');
    _validateId(entry.value, 'replayReferences value');
  }
  for (final reward in state.acquiredRewards) {
    _validateId(reward, 'acquiredRewards');
  }
  for (final entry in state.stageShuffleBags.entries) {
    _validateId(entry.key, 'stageShuffleBags key');
    if (entry.key != entry.value.stageId) {
      throw ArgumentError('stageShuffleBags key와 상태의 stageId가 다릅니다.');
    }
  }
  _validateShotInputLog(state.shotInputLog, state.patternDrawHistory);
  if (!state.startedAt.isUtc || !state.updatedAt.isUtc) {
    throw ArgumentError('날짜는 UTC여야 합니다.');
  }
  if (state.updatedAt.isBefore(state.startedAt)) {
    throw ArgumentError('updatedAt은 startedAt보다 빠를 수 없습니다.');
  }
}

void _validateShotInputLog(
  List<RunShotInput> inputs,
  List<PatternDrawRecord> history,
) {
  final grouped = <String, List<RunShotInput>>{};
  for (final input in inputs) {
    final matchingDraws = history.where(
      (record) =>
          record.stageId == input.stageId &&
          record.patternId == input.patternId &&
          (input.patternSeed == null ||
              record.patternSeed == input.patternSeed),
    );
    if (matchingDraws.isEmpty) {
      throw ArgumentError('샷 입력이 patternDrawHistory의 추첨 기록과 일치하지 않습니다.');
    }
    if (input.traitActions.isNotEmpty && input.equippedTrait == null) {
      throw ArgumentError('속성 이전·복사 기록에는 장착된 속성이 필요합니다.');
    }
    final key =
        '${input.stageId}\u0000${input.patternId}\u0000'
        '${input.patternSeed?.toString() ?? 'legacy'}';
    grouped.putIfAbsent(key, () => []).add(input);
  }
  for (final group in grouped.values) {
    group.sort((left, right) => left.shotIndex.compareTo(right.shotIndex));
    for (var index = 0; index < group.length; index++) {
      if (group[index].shotIndex != index) {
        throw ArgumentError('같은 패턴의 샷 순서는 0부터 빠짐없이 이어져야 합니다.');
      }
    }
  }
}

void _validatePatternTriplet({
  required String? stageId,
  required String? patternId,
  required int? patternSeed,
  required List<PatternDrawRecord> history,
  required Map<String, StageShuffleBagState> stageShuffleBags,
  required String label,
  bool required = true,
}) {
  final present = [
    stageId,
    patternId,
    patternSeed,
  ].where((value) => value != null).length;
  if (!required && present == 0) {
    return;
  }
  if (present != 3) {
    throw ArgumentError('$label triplet은 함께 저장되어야 합니다.');
  }

  final stage = stageId!;
  final pattern = patternId!;
  final seed = patternSeed!;
  final matches = history
      .where(
        (record) =>
            record.stageId == stage &&
            record.patternId == pattern &&
            record.patternSeed == seed,
      )
      .toList();
  if (matches.length != 1) {
    throw ArgumentError('$label triplet이 patternDrawHistory와 일치하지 않습니다.');
  }

  final bag = stageShuffleBags[stage];
  if (bag == null) {
    throw ArgumentError('$label triplet의 stageShuffleBagState가 없습니다.');
  }
  final record = matches.single;
  final expectedCycle =
      record.cycle + (bag.remainingPatternIds.isEmpty ? 1 : 0);
  if (bag.stageId != stage ||
      bag.lastPatternId != pattern ||
      bag.drawIndex != record.drawIndex + 1 ||
      bag.cycle != expectedCycle) {
    throw ArgumentError('$label triplet이 소비된 stageShuffleBagState와 일치하지 않습니다.');
  }
}

void _validateOptionalIdGroup(List<Object?> values, String name) {
  final present = values.where((value) => value != null).length;
  if (present != 0 && present != values.length) {
    throw ArgumentError('$name 필드는 함께 저장되어야 합니다.');
  }
  if (values[0] case final String value when value.isEmpty) {
    throw ArgumentError('$name ID가 비어 있습니다.');
  }
  if (values[1] case final String value when value.isEmpty) {
    throw ArgumentError('$name pattern ID가 비어 있습니다.');
  }
  if (values[2] case final int value) {
    _validateSeed(value, '$name seed');
  }
}

void _validateStringIntMap(Map<String, int> values, String name) {
  for (final entry in values.entries) {
    _validateId(entry.key, '$name key');
    _validateNonNegative(entry.value, '$name value');
  }
}

void _validateVec2(Vec2 value, String name) {
  if (!value.x.isFinite || !value.y.isFinite) {
    throw ArgumentError.value(value, name, '좌표는 유한한 수여야 합니다.');
  }
}

void _validateId(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, '비어 있을 수 없습니다.');
  }
}

void _validateSeed(int value, String name) {
  if (value < 0 || value > 0xffffffff) {
    throw ArgumentError.value(value, name, '0부터 32비트 최대값 사이여야 합니다.');
  }
}

void _validateNonNegative(int value, String name) {
  if (value < 0) {
    throw ArgumentError.value(value, name, '음수일 수 없습니다.');
  }
}

Object? _required(Map<String, dynamic> json, String key, String path) {
  if (!json.containsKey(key)) {
    throw FormatException('$path.$key 필드가 없습니다.');
  }
  return json[key];
}

String _requiredString(Map<String, dynamic> json, String key, String path) {
  final value = _required(json, key, path);
  if (value is! String) {
    throw FormatException('$path.$key가 문자열이 아닙니다.');
  }
  return value;
}

String? _nullableString(Map<String, dynamic> json, String key, String path) {
  final value = _required(json, key, path);
  if (value != null && value is! String) {
    throw FormatException('$path.$key가 문자열 또는 null이 아닙니다.');
  }
  return value as String?;
}

int _requiredInt(Map<String, dynamic> json, String key, String path) {
  final value = _required(json, key, path);
  if (value is! int) {
    throw FormatException('$path.$key가 정수가 아닙니다.');
  }
  return value;
}

int _requiredNonNegativeInt(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = _requiredInt(json, key, path);
  if (value < 0) {
    throw FormatException('$path.$key가 음수입니다.');
  }
  return value;
}

int _requiredSeed(Map<String, dynamic> json, String key, String path) {
  final value = _requiredInt(json, key, path);
  if (value < 0 || value > 0xffffffff) {
    throw FormatException('$path.$key가 32비트 seed 범위를 벗어났습니다.');
  }
  return value;
}

int? _nullableSeed(Map<String, dynamic> json, String key, String path) {
  final value = _required(json, key, path);
  if (value == null) {
    return null;
  }
  if (value is! int || value < 0 || value > 0xffffffff) {
    throw FormatException('$path.$key가 유효한 seed가 아닙니다.');
  }
  return value;
}

double _requiredFiniteDouble(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = _required(json, key, path);
  if (value is! num || !value.isFinite) {
    throw FormatException('$path.$key가 유한한 숫자가 아닙니다.');
  }
  return value.toDouble();
}

Vec2 _requiredVec2(Map<String, dynamic> json, String key, String path) {
  final map = _mapValue(_required(json, key, path), '$path.$key');
  final x = _requiredFiniteDouble(map, 'x', '$path.$key');
  final y = _requiredFiniteDouble(map, 'y', '$path.$key');
  return Vec2(x, y);
}

DateTime _requiredUtcDateTime(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = _requiredString(json, key, path);
  final parsed = DateTime.tryParse(value);
  if (parsed == null || !parsed.isUtc) {
    throw FormatException('$path.$key가 UTC ISO-8601 날짜가 아닙니다.');
  }
  return parsed;
}

List<T> _requiredList<T>(
  Map<String, dynamic> json,
  String key,
  String path,
  T Function(Map<String, dynamic>) decode,
) {
  final value = _required(json, key, path);
  if (value is! List) {
    throw FormatException('$path.$key가 배열이 아닙니다.');
  }
  return [
    for (var index = 0; index < value.length; index++)
      decode(_mapValue(value[index], '$path.$key[$index]')),
  ];
}

List<String> _requiredStringList(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final value = _required(json, key, path);
  if (value is! List) {
    throw FormatException('$path.$key가 배열이 아닙니다.');
  }
  return [
    for (var index = 0; index < value.length; index++)
      _stringValue(value[index], '$path.$key[$index]'),
  ];
}

Set<String> _requiredStringSet(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final values = _requiredStringList(json, key, path);
  if (values.toSet().length != values.length) {
    throw FormatException('$path.$key에 중복 값이 있습니다.');
  }
  return values.toSet();
}

Map<String, int> _requiredNonNegativeIntMap(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final map = _requiredMap(json, key, path);
  final result = <String, int>{};
  for (final entry in map.entries) {
    final value = entry.value;
    if (value is! int || value < 0) {
      throw FormatException('$path.$key.${entry.key}가 음수가 아닌 정수가 아닙니다.');
    }
    result[entry.key] = value;
  }
  return result;
}

Map<String, bool> _requiredBoolMap(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final map = _requiredMap(json, key, path);
  final result = <String, bool>{};
  for (final entry in map.entries) {
    if (entry.value is! bool) {
      throw FormatException('$path.$key.${entry.key}가 bool이 아닙니다.');
    }
    result[entry.key] = entry.value as bool;
  }
  return result;
}

Map<String, String> _requiredStringMap(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  final map = _requiredMap(json, key, path);
  final result = <String, String>{};
  for (final entry in map.entries) {
    result[entry.key] = _stringValue(entry.value, '$path.$key.${entry.key}');
  }
  return result;
}

Map<String, dynamic> _requiredMap(
  Map<String, dynamic> json,
  String key,
  String path,
) {
  return _mapValue(_required(json, key, path), '$path.$key');
}

Map<String, dynamic> _mapValue(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path가 Map이 아닙니다.');
  }
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path의 key가 문자열이 아닙니다.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _stringValue(Object? value, String path) {
  if (value is! String) {
    throw FormatException('$path가 문자열이 아닙니다.');
  }
  return value;
}

Map<String, int> _sortedIntMap(Map<String, int> source) {
  final keys = source.keys.toList()..sort();
  return {for (final key in keys) key: source[key]!};
}

Map<String, bool> _sortedBoolMap(Map<String, bool> source) {
  final keys = source.keys.toList()..sort();
  return {for (final key in keys) key: source[key]!};
}

Map<String, String> _sortedStringMap(Map<String, String> source) {
  final keys = source.keys.toList()..sort();
  return {for (final key in keys) key: source[key]!};
}
