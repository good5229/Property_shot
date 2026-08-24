import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/weekly_research_goal.dart';
import 'package:property_shot/game/persistence/progress_store.dart';

void main() {
  test('같은 주는 진행 상태가 바뀌어도 같은 스테이지와 목표를 고른다', () {
    final before = WeeklyResearchGoal.forWeek(
      weekKey: '2026-08-24',
      cycleWeek: 2,
      stageCount: 10,
      unlockedLevel: 0,
      discoveryCount: 0,
      personalRecords: const {},
    );
    final after = WeeklyResearchGoal.forWeek(
      weekKey: '2026-08-24',
      cycleWeek: 2,
      stageCount: 10,
      unlockedLevel: 9,
      discoveryCount: 30,
      personalRecords: {
        for (var index = 0; index < 10; index++)
          index: PersonalRecordKind.values.toSet(),
      },
    );

    expect(after.stageIndex, before.stageIndex);
    expect(after.recordKind, before.recordKind);
    expect(after.landmark, before.landmark);
  });

  test('시설·스테이지·개인 기록에 따라 상태를 구분한다', () {
    WeeklyResearchGoal build({
      required int discoveries,
      required int unlocked,
      Map<int, Set<PersonalRecordKind>> records = const {},
    }) => WeeklyResearchGoal.forWeek(
      weekKey: '2026-08-24',
      cycleWeek: 4,
      stageCount: 10,
      unlockedLevel: unlocked,
      discoveryCount: discoveries,
      personalRecords: records,
    );

    final lockedFacility = build(discoveries: 14, unlocked: 9);
    expect(lockedFacility.statusLabel, '발견 15개 후 개방');

    final lockedStage = build(discoveries: 30, unlocked: 0);
    if (lockedStage.stageIndex > 0) {
      expect(
        lockedStage.statusLabel,
        '${lockedStage.stageIndex + 1}단계 해금 후 도전',
      );
    }

    final available = build(discoveries: 30, unlocked: 9);
    expect(available.statusLabel, '도전 가능');
    final achieved = build(
      discoveries: 30,
      unlocked: 9,
      records: {
        available.stageIndex: {PersonalRecordKind.noIslandSupportClear},
      },
    );
    expect(achieved.statusLabel, '기록 달성');
  });

  test('잘못된 외부 입력을 거부한다', () {
    expect(
      () => WeeklyResearchGoal.forWeek(
        weekKey: '',
        cycleWeek: 1,
        stageCount: 10,
        unlockedLevel: 0,
        discoveryCount: 0,
        personalRecords: const {},
      ),
      throwsArgumentError,
    );
    expect(
      () => WeeklyResearchGoal.forWeek(
        weekKey: '2026-08-24',
        cycleWeek: 5,
        stageCount: 0,
        unlockedLevel: 0,
        discoveryCount: 0,
        personalRecords: const {},
      ),
      throwsArgumentError,
    );
  });
}
