import '../persistence/progress_store.dart';
import '../run/stable_seed.dart';
import 'island_restoration.dart';

/// 매주 섬 복구 시설이 제안하는 캠페인 숙련 목표다.
///
/// 저장할 별도 진행값을 만들지 않고 기존 개인 기록을 읽기 때문에,
/// 주가 바뀌어도 저장 데이터가 늘어나지 않으며 같은 주에는 항상 같은
/// 스테이지와 목표를 제안한다.
class WeeklyResearchGoal {
  const WeeklyResearchGoal({
    required this.weekKey,
    required this.cycleWeek,
    required this.stageIndex,
    required this.recordKind,
    required this.landmark,
    required this.facilityRestored,
    required this.stageUnlocked,
    required this.achieved,
  });

  final String weekKey;
  final int cycleWeek;
  final int stageIndex;
  final PersonalRecordKind recordKind;
  final IslandLandmark landmark;
  final bool facilityRestored;
  final bool stageUnlocked;
  final bool achieved;

  String get id => 'weekly_research_$weekKey';

  String get title => '${landmark.label} 연구 목표';

  String get statusLabel {
    if (!facilityRestored) {
      return '발견 ${landmark.requiredDiscoveries}개 후 개방';
    }
    if (!stageUnlocked) return '${stageIndex + 1}단계 해금 후 도전';
    if (achieved) return '기록 달성';
    return '도전 가능';
  }

  String stageTask(String stageName) =>
      '${stageIndex + 1}. $stageName · ${recordKind.label}';

  String get guidance => switch (recordKind) {
    PersonalRecordKind.gimmickMastery => '핵심 기믹을 수행하고 선택 도전까지 완수하세요.',
    PersonalRecordKind.noAssistClear => '조준 보정 없이 물리 규칙을 읽어 클리어하세요.',
    PersonalRecordKind.noIslandSupportClear => '복구 시설의 지원 없이 경로를 완성하세요.',
  };

  static WeeklyResearchGoal forWeek({
    required String weekKey,
    required int cycleWeek,
    required int stageCount,
    required int unlockedLevel,
    required int discoveryCount,
    required Map<int, Set<PersonalRecordKind>> personalRecords,
  }) {
    if (weekKey.trim().isEmpty) {
      throw ArgumentError.value(weekKey, 'weekKey', '비어 있을 수 없습니다.');
    }
    if (cycleWeek < 1 || cycleWeek > 4) {
      throw ArgumentError.value(cycleWeek, 'cycleWeek', '1 이상 4 이하여야 합니다.');
    }
    if (stageCount < 1) {
      throw ArgumentError.value(stageCount, 'stageCount', '1 이상이어야 합니다.');
    }
    final seed = StableSeed.hashString(
      'property-shot-weekly-research:$weekKey',
    );
    final stageIndex = seed % stageCount;
    final (recordKind, landmark) = switch (cycleWeek) {
      1 => (PersonalRecordKind.gimmickMastery, IslandLandmark.observatory),
      2 => (PersonalRecordKind.noAssistClear, IslandLandmark.lighthouse),
      3 => (PersonalRecordKind.gimmickMastery, IslandLandmark.observatory),
      4 => (PersonalRecordKind.noIslandSupportClear, IslandLandmark.bridge),
      _ => throw StateError('도달할 수 없는 주차입니다.'),
    };
    return WeeklyResearchGoal(
      weekKey: weekKey,
      cycleWeek: cycleWeek,
      stageIndex: stageIndex,
      recordKind: recordKind,
      landmark: landmark,
      facilityRestored: discoveryCount >= landmark.requiredDiscoveries,
      stageUnlocked: stageIndex <= unlockedLevel,
      achieved: personalRecords[stageIndex]?.contains(recordKind) ?? false,
    );
  }
}
