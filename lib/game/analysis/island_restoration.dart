import 'stage_discovery.dart';

import 'package:shared_preferences/shared_preferences.dart';

enum IslandLandmark { observatory, lighthouse, bridge }

class IslandSupportRecommendation {
  const IslandSupportRecommendation({
    required this.landmark,
    required this.reason,
  });

  final IslandLandmark landmark;
  final String reason;
}

IslandSupportRecommendation? recommendIslandSupportForStage({
  required int levelIndex,
  required IslandRestorationProgress progress,
}) {
  if (levelIndex < 0 || levelIndex >= 10) {
    throw ArgumentError.value(levelIndex, 'levelIndex', '0~9여야 합니다.');
  }
  if (progress.restoredCount == 0) return null;

  final preferred = switch (levelIndex) {
    0 || 4 || 9 => IslandLandmark.observatory,
    1 || 3 || 5 || 8 => IslandLandmark.lighthouse,
    2 || 6 || 7 => IslandLandmark.bridge,
    _ => throw StateError('도달할 수 없는 스테이지입니다.'),
  };
  final landmark = progress.isRestored(preferred)
      ? preferred
      : progress.restoredLandmarks.first;
  final reason = landmark == preferred
      ? switch (levelIndex) {
          0 => '상자 이동이 빗나가면 마지막 충돌 순서부터 확인할 수 있어요.',
          1 => '탄성 반사의 작은 조준 오차를 편안한 보정으로 줄여 줍니다.',
          2 => '첫 공을 남기는 두 발 해법에 복사 코어를 하나 더 준비합니다.',
          3 => '풍선 연쇄를 노리는 발사각의 작은 오차를 줄여 줍니다.',
          4 => '속도 소진 구간이 어긋나면 실패 원인을 자세히 보여 줍니다.',
          5 => '가속 구간을 통과하는 정밀 조준을 편안하게 보정합니다.',
          6 => '여러 발을 이어 쓰는 해법에 복사 코어를 하나 더 준비합니다.',
          7 => '연쇄 점수를 쌓는 다중 발사에 복사 코어를 하나 더 준비합니다.',
          8 => '회전 반사판의 타이밍과 각도 오차를 편안하게 보정합니다.',
          9 => '속성 배수와 연쇄가 끊긴 지점을 충돌 순서로 확인할 수 있어요.',
          _ => throw StateError('도달할 수 없는 스테이지입니다.'),
        }
      : '${preferred.label} 복구 전에는 ${landmark.label}의 ${landmark.benefitLabel} 지원이 가장 유용해요.';
  return IslandSupportRecommendation(landmark: landmark, reason: reason);
}

extension IslandLandmarkCopy on IslandLandmark {
  String get label => switch (this) {
    IslandLandmark.observatory => '관측소',
    IslandLandmark.lighthouse => '등대',
    IslandLandmark.bridge => '다리',
  };

  int get requiredDiscoveries => switch (this) {
    IslandLandmark.observatory => 3,
    IslandLandmark.lighthouse => 9,
    IslandLandmark.bridge => 15,
  };

  int get previousThreshold => switch (this) {
    IslandLandmark.observatory => 0,
    IslandLandmark.lighthouse => 3,
    IslandLandmark.bridge => 9,
  };

  String get benefitLabel => switch (this) {
    IslandLandmark.observatory => '분석 강화',
    IslandLandmark.lighthouse => 'L1 즉시',
    IslandLandmark.bridge => '코어 +1',
  };

  String get benefitDescription => switch (this) {
    IslandLandmark.observatory => '이후 런에서 실패 원인과 충돌 순서를 자세히 보여 줍니다.',
    IslandLandmark.lighthouse => '각 스테이지의 첫 번째 팁을 실패 전부터 열 수 있습니다.',
    IslandLandmark.bridge => '각 런에 속성 복사 코어 1개를 보급합니다.',
  };

  int get upgradeDiscoveries => switch (this) {
    IslandLandmark.observatory => 6,
    IslandLandmark.lighthouse => 12,
    IslandLandmark.bridge => 18,
  };

  String get upgradeLabel => switch (this) {
    IslandLandmark.observatory => '4주 실험 기록',
    IslandLandmark.lighthouse => '다음 목표 미리보기',
    IslandLandmark.bridge => '로컬 기록 비교',
  };

  String get upgradeDescription => switch (this) {
    IslandLandmark.observatory => '최근 네 번의 주간 실험 완료 기록을 한눈에 볼 수 있습니다.',
    IslandLandmark.lighthouse => '다음 스테이지에서 배울 기믹을 출발 전에 보여 줍니다.',
    IslandLandmark.bridge => '내 기기에 저장된 두 리플레이를 나란히 비교할 수 있습니다.',
  };
}

class IslandSupportStore {
  IslandSupportStore(this._preferences);
  static const storageKey = 'property_shot_island_support_focus_v1';
  final SharedPreferences _preferences;

  IslandLandmark? load() {
    final raw = _preferences.getString(storageKey);
    if (raw == null) return null;
    try {
      return IslandLandmark.values.byName(raw);
    } on ArgumentError {
      _preferences.remove(storageKey);
      return null;
    }
  }

  Future<void> save(IslandLandmark landmark) async {
    final succeeded = await _preferences.setString(storageKey, landmark.name);
    if (!succeeded) throw StateError('섬 연구 지원 선택을 저장하지 못했습니다.');
  }
}

class IslandRestorationProgress {
  IslandRestorationProgress({
    required this.discoveryCount,
    this.total = 30,
    this.optionalMasteryCount = 0,
  }) {
    if (discoveryCount < 0 ||
        total < 1 ||
        discoveryCount > total ||
        optionalMasteryCount < 0 ||
        optionalMasteryCount > 10) {
      throw ArgumentError('섬 복구 발견 수가 올바르지 않습니다.');
    }
  }

  factory IslandRestorationProgress.fromDiscoveries({
    required Map<String, Set<String>> discoveriesByStageId,
    required List<String> stageIds,
    int optionalMasteryCount = 0,
  }) {
    var count = 0;
    for (var index = 0; index < stageIds.length; index++) {
      count +=
          discoveriesByStageId[stageIds[index]]
              ?.intersection(stageDiscoveryMilestoneIds(index))
              .length ??
          0;
    }
    return IslandRestorationProgress(
      discoveryCount: count,
      total: stageIds.length * 3,
      optionalMasteryCount: optionalMasteryCount,
    );
  }

  final int discoveryCount;
  final int total;
  final int optionalMasteryCount;

  String get masteryStatusText {
    if (optionalMasteryCount >= 9) return '지원 완료: 코어 +1';
    if (optionalMasteryCount >= 6) return '9개 달성: 코어 +1';
    if (optionalMasteryCount >= 3) return '6개 달성: 발사 취소 1회';
    return '3개 달성: 첫 충돌 안내 1회';
  }

  bool isRestored(IslandLandmark landmark) =>
      discoveryCount >= landmark.requiredDiscoveries;

  bool isUpgraded(IslandLandmark landmark) =>
      discoveryCount >= landmark.upgradeDiscoveries;

  double upgradeProgress(IslandLandmark landmark) {
    final start = landmark.requiredDiscoveries;
    final span = landmark.upgradeDiscoveries - start;
    return ((discoveryCount - start) / span).clamp(0, 1);
  }

  double repairProgress(IslandLandmark landmark) {
    final start = landmark.previousThreshold;
    final span = landmark.requiredDiscoveries - start;
    return ((discoveryCount - start) / span).clamp(0, 1);
  }

  IslandLandmark? get nextLandmark {
    for (final landmark in IslandLandmark.values) {
      if (!isRestored(landmark)) return landmark;
    }
    return null;
  }

  int get restoredCount => IslandLandmark.values.where(isRestored).length;

  Iterable<IslandLandmark> get restoredLandmarks =>
      IslandLandmark.values.where(isRestored);

  String get statusText {
    final next = nextLandmark;
    if (next == null) return '섬의 관측 시설이 모두 복구됐어요.';
    final remaining = next.requiredDiscoveries - discoveryCount;
    return '${next.label} 복구까지 발견 $remaining개';
  }
}
