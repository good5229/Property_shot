import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const store = ProgressStore(stageCount: 4);

  test('새 저장소는 기본값을 만들고 버전을 기록한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final snapshot = await store.load();
    final preferences = await SharedPreferences.getInstance();

    expect(snapshot.unlockedLevel, 0);
    expect(snapshot.clearedLevels, isEmpty);
    expect(preferences.getInt(ProgressStore.saveVersionKey), 1);
    expect(preferences.getStringList(ProgressStore.clearedLevelsKey), isEmpty);
  });

  test('구버전 해금 키와 단계별 기록을 합쳐 4단계를 복원한다', () async {
    SharedPreferences.setMockInitialValues({
      ProgressStore.legacyUnlockedLevelKey: 2,
      ProgressStore.clearedLevelsKey: ['2', '3', '3', '잘못된 값'],
    });

    final snapshot = await store.load();

    expect(snapshot.clearedLevels, {0, 1, 2, 3});
    expect(snapshot.unlockedLevel, 3);
  });

  test('손상된 저장 값은 기본값으로 복구하고 반복 마이그레이션이 안정적이다', () async {
    SharedPreferences.setMockInitialValues({
      ProgressStore.clearedLevelsKey: 42,
      ProgressStore.unlockedLevelKey: '3',
      ProgressStore.copyCoreCountKey: '많음',
      ProgressStore.copyCoreRewardedKey: '예',
      'bonus_goal_level_0': '완료',
    });

    final first = await store.load();
    final second = await store.load();

    expect(first.unlockedLevel, 0);
    expect(first.clearedLevels, isEmpty);
    expect(first.copyCoreCount, 0);
    expect(first.copyCoreRewarded, isFalse);
    expect(second.unlockedLevel, first.unlockedLevel);
    expect(second.clearedLevels, first.clearedLevels);
  });

  test('클리어·최고 기록·보너스·복제 코어를 함께 보존한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await store.recordStageClear(0);
    await store.recordBestShot(0, 4);
    await store.recordBestShot(0, 5);
    await store.recordBonusGoal(0);
    await store.recordCopyCore(2, true);
    final snapshot = await store.load();

    expect(snapshot.clearedLevels, contains(0));
    expect(snapshot.unlockedLevel, 1);
    expect(snapshot.bestShots[0], 4);
    expect(snapshot.bonusGoals, contains(0));
    expect(snapshot.copyCoreCount, 2);
    expect(snapshot.copyCoreRewarded, isTrue);
  });

  test('앱 재실행 뒤 클리어·기록·보너스·복제 코어를 복원한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final firstRun = ProgressStore(stageCount: 4);

    await firstRun.recordStageClear(0);
    await firstRun.recordBestShot(0, 2);
    await firstRun.recordBonusGoal(0);
    await firstRun.recordCopyCore(3, true);

    final afterRestart = await ProgressStore(stageCount: 4).load();

    expect(afterRestart.clearedLevels, contains(0));
    expect(afterRestart.unlockedLevel, 1);
    expect(afterRestart.bestShots[0], 2);
    expect(afterRestart.bonusGoals, contains(0));
    expect(afterRestart.copyCoreCount, 3);
    expect(afterRestart.copyCoreRewarded, isTrue);
  });

  test('범위를 벗어난 단계 기록은 저장하지 않는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await store.recordStageClear(-1);
    await store.recordStageClear(4);
    final snapshot = await store.load();

    expect(snapshot.clearedLevels, isEmpty);
    expect(snapshot.unlockedLevel, 0);
  });

  test('개발용 전체 해금과 진행 초기화는 저장 키를 함께 정리한다', () async {
    SharedPreferences.setMockInitialValues({
      ProgressStore.copyCoreCountKey: 3,
      'best_shots_level_0': 2,
      'bonus_goal_level_0': true,
    });

    await store.unlockAll();
    expect((await store.load()).unlockedLevel, 3);

    await store.reset();
    final snapshot = await store.load();
    expect(snapshot.unlockedLevel, 0);
    expect(snapshot.clearedLevels, isEmpty);
    expect(snapshot.bestShots, isEmpty);
    expect(snapshot.bonusGoals, isEmpty);
    expect(snapshot.copyCoreCount, 0);
  });
}
