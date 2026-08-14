import 'stable_seed.dart';

const int _maxUint32 = 0xffffffff;

const String runRewardCloneCoreId = 'clone_core_once';
const String runRewardShotCancelAssistId = 'shot_cancel_assist_once';
const String runRewardSpentBallRecoveryId = 'spent_ball_recovery_once';
const String runRewardFirstImpactGuideId = 'first_impact_guide_once';
const String runRewardOptionalChallengeGuardId =
    'optional_challenge_guard_once';
const String runRewardFailureCauseBoostId = 'failure_cause_boost';
const String runRewardBallAppearanceId = 'ball_appearance_set';
const String runRewardStageRecordGuardId = 'stage_record_guard_once';
const String runRewardNextStageHintAccessId = 'next_stage_hint_access';
const String runRewardPrecisionChargeId = 'precision_charge_control';
const String _selectionPrefix = 'run_reward:';
const String _usedPrefix = 'run_reward_used:';
const String _stageUsedPrefix = 'run_reward_stage_used:';
const String _stageAttemptPrefix = 'run_stage_attempt:';

/// 보상이 런에 제공할 효과의 안정적인 저장 종류다.
enum RunRewardEffectKind {
  cloneCore('clone_core'),
  shotCancelAssist('shot_cancel_assist'),
  spentBallRecovery('spent_ball_recovery'),
  firstImpactGuide('first_impact_guide'),
  optionalChallengeGuard('optional_challenge_guard'),
  failureCauseBoost('failure_cause_boost'),
  ballAppearance('ball_appearance'),
  stageRecordGuard('stage_record_guard'),
  nextStageHintAccess('next_stage_hint_access'),
  precisionCharge('precision_charge');

  const RunRewardEffectKind(this.schemaName);

  final String schemaName;

  static RunRewardEffectKind fromSchemaName(String value) {
    for (final kind in values) {
      if (kind.schemaName == value) return kind;
    }
    throw FormatException('알 수 없는 보상 효과 종류입니다: $value');
  }
}

/// 핵심 물리값과 분리해 저장하는 런 보상 메타데이터다.
class RunReward {
  RunReward({
    required this.id,
    required this.name,
    required this.description,
    required this.effectKind,
  }) {
    _requireText(id, '보상 ID');
    _requireText(name, '보상 이름');
    _requireText(description, '보상 설명');
  }

  final String id;
  final String name;
  final String description;
  final RunRewardEffectKind effectKind;

  factory RunReward.fromJson(Map<String, dynamic> json) {
    final id = _requiredString(json, 'id');
    final name = _requiredString(json, 'name');
    final description = _requiredString(json, 'description');
    final effectKind = _requiredString(json, 'effectKind');
    return RunReward(
      id: id,
      name: name,
      description: description,
      effectKind: RunRewardEffectKind.fromSchemaName(effectKind),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'effectKind': effectKind.schemaName,
    };
  }
}

final List<RunReward> initialRunRewards = List.unmodifiable([
  RunReward(
    id: runRewardCloneCoreId,
    name: '복제 코어 1개',
    description: '속성을 원본에 남긴 채 공에 한 번 복사할 수 있습니다.',
    effectKind: RunRewardEffectKind.cloneCore,
  ),
  RunReward(
    id: runRewardShotCancelAssistId,
    name: '발사 취소 보조 1회',
    description: '조준을 마친 발사를 한 번 취소하고 다시 준비할 수 있습니다.',
    effectKind: RunRewardEffectKind.shotCancelAssist,
  ),
  RunReward(
    id: runRewardSpentBallRecoveryId,
    name: '과거 공 1회 회수',
    description: '필드에 남은 과거 공 하나를 한 번 회수할 수 있습니다.',
    effectKind: RunRewardEffectKind.spentBallRecovery,
  ),
  RunReward(
    id: runRewardFirstImpactGuideId,
    name: '첫 충돌 대상 표시 1회',
    description: '다음 발사에서 가장 먼저 부딪힐 대상 하나를 표시합니다.',
    effectKind: RunRewardEffectKind.firstImpactGuide,
  ),
  RunReward(
    id: runRewardOptionalChallengeGuardId,
    name: '선택 도전 실패 1회 무효화',
    description: '선택 도전의 실패 판정을 한 번 무효화합니다.',
    effectKind: RunRewardEffectKind.optionalChallengeGuard,
  ),
  RunReward(
    id: runRewardFailureCauseBoostId,
    name: '실패 인과 표시 강화',
    description: '런 동안 실패 원인과 충돌 순서를 더 선명하게 표시합니다.',
    effectKind: RunRewardEffectKind.failureCauseBoost,
  ),
  RunReward(
    id: runRewardBallAppearanceId,
    name: '공 꾸미기 묶음',
    description: '공 본체를 청록 그라데이션·금색 외곽선·반짝임으로 꾸밉니다.',
    effectKind: RunRewardEffectKind.ballAppearance,
  ),
  RunReward(
    id: runRewardStageRecordGuardId,
    name: '스테이지 기록 보호',
    description: '스테이지마다 한 번, 클리어 발사 횟수를 1회 줄여 기록합니다.',
    effectKind: RunRewardEffectKind.stageRecordGuard,
  ),
  RunReward(
    id: runRewardNextStageHintAccessId,
    name: '다음 스테이지 팁 확보',
    description: '다음에 확정된 패턴의 단계별 클리어 팁을 필요할 때 볼 수 있습니다.',
    effectKind: RunRewardEffectKind.nextStageHintAccess,
  ),
  RunReward(
    id: runRewardPrecisionChargeId,
    name: '정밀 충전 조절',
    description: '런 동안 충전 속도를 25% 늦춰 원하는 힘에서 손을 떼기 쉽게 만듭니다.',
    effectKind: RunRewardEffectKind.precisionCharge,
  ),
]);

/// 비어 있거나 중복된 보상 ID가 후보 생성에 들어오지 않도록 막는다.
class RunRewardCatalog {
  RunRewardCatalog(Iterable<RunReward> rewards)
    : rewards = List.unmodifiable(rewards) {
    if (this.rewards.length < RunRewardCandidateGenerator.candidateCount) {
      throw ArgumentError('보상 카탈로그에는 세 종류 이상이 필요합니다.');
    }
    final ids = <String>{};
    for (final reward in this.rewards) {
      _requireText(reward.id, '보상 ID');
      if (!ids.add(reward.id)) {
        throw ArgumentError.value(reward.id, '보상 ID', '중복될 수 없습니다.');
      }
    }
  }

  final List<RunReward> rewards;
}

final RunRewardCatalog defaultRunRewardCatalog = RunRewardCatalog(
  initialRunRewards,
);

/// 런과 패턴 seed로 보상 세 개를 재현 가능하게 뽑는다.
class RunRewardCandidateGenerator {
  RunRewardCandidateGenerator({RunRewardCatalog? catalog})
    : catalog = catalog ?? defaultRunRewardCatalog;

  static const int candidateCount = 3;

  final RunRewardCatalog catalog;

  int candidateSeed({
    required int rootSeed,
    required String stageId,
    required int patternSeed,
  }) {
    _requireUint32(rootSeed, '루트 시드');
    _requireUint32(patternSeed, '패턴 시드');
    _requireText(stageId, '스테이지 ID');
    return StableSeed.deriveSeed(
      rootSeed: rootSeed,
      stageId: stageId,
      cycle: 0,
      drawIndex: patternSeed,
      purpose: 'run_reward_candidates',
    );
  }

  List<RunReward> generate({
    required int rootSeed,
    required String stageId,
    required int patternSeed,
    bool includeNextStageHint = false,
  }) {
    final seed = candidateSeed(
      rootSeed: rootSeed,
      stageId: stageId,
      patternSeed: patternSeed,
    );
    final hintReward = catalog.rewards
        .where((reward) => reward.id == runRewardNextStageHintAccessId)
        .toList(growable: false);
    // 기존 후보 생성의 seed/순서를 보존하기 위해 새 필수 보상은 일반 pool에
    // 섞지 않는다. 다음 단계가 있을 때만 아래에서 명시적으로 추가한다.
    final selectable = catalog.rewards.where(
      (reward) => reward.id != runRewardNextStageHintAccessId,
    );
    final shuffled = StableRandom(seed).shuffled(selectable).toList();
    final tactical = <String>{
      runRewardCloneCoreId,
      runRewardSpentBallRecoveryId,
      runRewardFirstImpactGuideId,
      runRewardPrecisionChargeId,
    };
    final safety = <String>{
      runRewardShotCancelAssistId,
      runRewardOptionalChallengeGuardId,
      runRewardStageRecordGuardId,
    };
    final growth = <String>{
      runRewardFailureCauseBoostId,
      runRewardBallAppearanceId,
    };
    final chosen = <RunReward>[];

    void chooseFrom(Set<String> ids) {
      final match = shuffled
          .where((reward) => ids.contains(reward.id))
          .firstOrNull;
      if (match == null) return;
      chosen.add(match);
      shuffled.remove(match);
    }

    // 매 선택지에 전략 확장·안전망·지속 효과가 하나씩 들어오게 해
    // 외형 보상만 모이거나 점수 보호만 모이는 무의미한 후보 조합을 피한다.
    chooseFrom(tactical);
    chooseFrom(safety);
    if (!includeNextStageHint) chooseFrom(growth);
    for (final reward in shuffled) {
      if (chosen.length >= (includeNextStageHint ? 2 : candidateCount)) break;
      chosen.add(reward);
    }
    if (!includeNextStageHint) {
      return List.unmodifiable(chosen.take(candidateCount));
    }
    if (hintReward.length != 1) {
      throw StateError('다음 스테이지 팁 보상이 카탈로그에 정확히 하나 필요합니다.');
    }
    return List.unmodifiable([
      hintReward.single,
      ...chosen.take(candidateCount - 1),
    ]);
  }
}

List<RunReward> generateRunRewardCandidates({
  required int rootSeed,
  required String stageId,
  required int patternSeed,
  RunRewardCatalog? catalog,
  bool includeNextStageHint = false,
}) {
  return RunRewardCandidateGenerator(catalog: catalog).generate(
    rootSeed: rootSeed,
    stageId: stageId,
    patternSeed: patternSeed,
    includeNextStageHint: includeNextStageHint,
  );
}

String runRewardSelectionRecordId({
  required String stageId,
  required int patternSeed,
  required String rewardId,
}) => '$_selectionPrefix$stageId:$patternSeed:$rewardId';

String runRewardUseRecordId(String selectionRecordId, String useKey) =>
    '$_usedPrefix$selectionRecordId:$useKey';

String runRewardStageUseRecordId(String selectionRecordId, String stageId) =>
    '$_stageUsedPrefix$selectionRecordId:$stageId';

String runStageAttemptRecordId(String stageId, int attempt) =>
    '$_stageAttemptPrefix$stageId:$attempt';

int runStageAttemptNumber(Iterable<String> acquiredRewards, String stageId) {
  final prefix = '$_stageAttemptPrefix$stageId:';
  var latest = 0;
  for (final value in acquiredRewards) {
    if (!value.startsWith(prefix)) continue;
    final attempt = int.tryParse(value.substring(prefix.length));
    if (attempt != null && attempt > latest) latest = attempt;
  }
  return latest;
}

class RunRewardSelectionRecord {
  const RunRewardSelectionRecord({
    required this.recordId,
    required this.stageId,
    required this.patternSeed,
    required this.rewardId,
  });

  final String recordId;
  final String stageId;
  final int patternSeed;
  final String rewardId;
}

List<RunRewardSelectionRecord> runRewardSelectionRecords(
  Iterable<String> acquiredRewards,
) {
  final records = <RunRewardSelectionRecord>[];
  for (final value in acquiredRewards) {
    if (!value.startsWith(_selectionPrefix) ||
        value.startsWith(_usedPrefix) ||
        value.startsWith(_stageUsedPrefix)) {
      continue;
    }
    final parts = value.split(':');
    if (parts.length != 4) continue;
    final patternSeed = int.tryParse(parts[2]);
    if (parts[1].isEmpty || patternSeed == null || parts[3].isEmpty) continue;
    records.add(
      RunRewardSelectionRecord(
        recordId: value,
        stageId: parts[1],
        patternSeed: patternSeed,
        rewardId: parts[3],
      ),
    );
  }
  records.sort((left, right) => left.recordId.compareTo(right.recordId));
  return List.unmodifiable(records);
}

class RunRewardInventory {
  RunRewardInventory(Iterable<String> acquiredRewards)
    : acquiredRewards = Set.unmodifiable(acquiredRewards),
      selections = runRewardSelectionRecords(acquiredRewards);

  final Set<String> acquiredRewards;
  final List<RunRewardSelectionRecord> selections;

  bool has(String rewardId) =>
      selections.any((record) => record.rewardId == rewardId);

  /// 현재 런에서 공 외형을 그릴 수 있는지 반환한다.
  /// 이전 버전이나 부분 복원 데이터의 ID-only 보상도 허용한다.
  bool get ballAppearanceEnabled =>
      acquiredRewards.contains(runRewardBallAppearanceId) ||
      has(runRewardBallAppearanceId);

  RunRewardSelectionRecord? selectionFor({
    required String stageId,
    required int patternSeed,
  }) {
    for (final record in selections) {
      if (record.stageId == stageId && record.patternSeed == patternSeed) {
        return record;
      }
    }
    return null;
  }

  List<RunRewardSelectionRecord> availableSelections(String rewardId) =>
      List.unmodifiable(
        selections.where(
          (record) =>
              record.rewardId == rewardId &&
              !acquiredRewards.any(
                (value) => value.startsWith('$_usedPrefix${record.recordId}:'),
              ),
        ),
      );

  int availableUseCount(String rewardId) =>
      availableSelections(rewardId).length;

  bool canUseForStage(String rewardId, String stageId) => selections.any(
    (record) =>
        record.rewardId == rewardId &&
        !acquiredRewards.any(
          (value) =>
              value == runRewardStageUseRecordId(record.recordId, stageId) ||
              value.startsWith(
                '${runRewardStageUseRecordId(record.recordId, stageId)}|',
              ),
        ),
  );

  bool wasUsedForStageAttempt(String rewardId, String stageId, int attempt) =>
      selections.any(
        (record) =>
            record.rewardId == rewardId &&
            acquiredRewards.contains(
              runRewardStageUseRecordId(record.recordId, '$stageId|$attempt'),
            ),
      );

  Iterable<String> useKeys(String rewardId) sync* {
    for (final record in selections.where(
      (record) => record.rewardId == rewardId,
    )) {
      final prefix = '$_usedPrefix${record.recordId}:';
      for (final value in acquiredRewards) {
        if (value.startsWith(prefix)) yield value.substring(prefix.length);
      }
    }
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key 값이 비어 있거나 문자열이 아닙니다.');
  }
  return value;
}

void _requireText(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '비어 있을 수 없습니다.');
  }
}

void _requireUint32(int value, String name) {
  if (value < 0 || value > _maxUint32) {
    throw ArgumentError.value(value, name, '32비트 부호 없는 정수여야 합니다.');
  }
}
