import 'stage_discovery.dart';

import 'package:shared_preferences/shared_preferences.dart';

enum IslandLandmark { observatory, lighthouse, bridge }

extension IslandLandmarkCopy on IslandLandmark {
  String get label => switch (this) {
    IslandLandmark.observatory => '관측소',
    IslandLandmark.lighthouse => '등대',
    IslandLandmark.bridge => '다리',
  };

  int get requiredDiscoveries => switch (this) {
    IslandLandmark.observatory => 3,
    IslandLandmark.lighthouse => 12,
    IslandLandmark.bridge => 24,
  };

  int get previousThreshold => switch (this) {
    IslandLandmark.observatory => 0,
    IslandLandmark.lighthouse => 3,
    IslandLandmark.bridge => 12,
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
  IslandRestorationProgress({required this.discoveryCount, this.total = 30}) {
    if (discoveryCount < 0 || total < 1 || discoveryCount > total) {
      throw ArgumentError('섬 복구 발견 수가 올바르지 않습니다.');
    }
  }

  factory IslandRestorationProgress.fromDiscoveries({
    required Map<String, Set<String>> discoveriesByStageId,
    required List<String> stageIds,
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
    );
  }

  final int discoveryCount;
  final int total;

  bool isRestored(IslandLandmark landmark) =>
      discoveryCount >= landmark.requiredDiscoveries;

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
