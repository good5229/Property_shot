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

/// 보상이 런에 제공할 효과의 안정적인 저장 종류다.
enum RunRewardEffectKind {
  cloneCore('clone_core'),
  shotCancelAssist('shot_cancel_assist'),
  spentBallRecovery('spent_ball_recovery'),
  firstImpactGuide('first_impact_guide'),
  optionalChallengeGuard('optional_challenge_guard'),
  failureCauseBoost('failure_cause_boost'),
  ballAppearance('ball_appearance'),
  stageRecordGuard('stage_record_guard');

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
    description: '일정 시간 동안 실패 원인과 충돌 순서를 더 선명하게 표시합니다.',
    effectKind: RunRewardEffectKind.failureCauseBoost,
  ),
  RunReward(
    id: runRewardBallAppearanceId,
    name: '공 꾸미기 묶음',
    description: '공 표정과 잔상, 충돌 링의 외형을 바꿉니다.',
    effectKind: RunRewardEffectKind.ballAppearance,
  ),
  RunReward(
    id: runRewardStageRecordGuardId,
    name: '스테이지 기록 보호',
    description: '스테이지마다 한 번씩 현재 기록이 낮아지는 것을 막습니다.',
    effectKind: RunRewardEffectKind.stageRecordGuard,
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
  }) {
    final seed = candidateSeed(
      rootSeed: rootSeed,
      stageId: stageId,
      patternSeed: patternSeed,
    );
    final shuffled = StableRandom(seed).shuffled(catalog.rewards);
    return List.unmodifiable(shuffled.take(candidateCount));
  }
}

List<RunReward> generateRunRewardCandidates({
  required int rootSeed,
  required String stageId,
  required int patternSeed,
  RunRewardCatalog? catalog,
}) {
  return RunRewardCandidateGenerator(
    catalog: catalog,
  ).generate(rootSeed: rootSeed, stageId: stageId, patternSeed: patternSeed);
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
