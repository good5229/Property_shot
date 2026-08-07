import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final store = ProgressStore(stageCount: 4);

  test('저장 API가 false를 반환하면 성공으로 처리하지 않는다', () {
    expect(
      () => requireSuccessfulProgressWrite(false, '테스트_키'),
      throwsA(isA<StateError>()),
    );
    expect(
      () => requireSuccessfulProgressWrite(true, '테스트_키'),
      returnsNormally,
    );
  });

  test('새 저장소는 기본값을 만들고 버전을 기록한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    final snapshot = await store.load();
    final preferences = await SharedPreferences.getInstance();

    expect(snapshot.unlockedLevel, 0);
    expect(snapshot.clearedLevels, isEmpty);
    expect(
      preferences.getInt(ProgressStore.saveVersionKey),
      ProgressStore.saveVersion,
    );
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
    await store.recordCopyCore(2, true, rewardedStageIds: const ['stage_2']);
    final snapshot = await store.load();

    expect(snapshot.clearedLevels, contains(0));
    expect(snapshot.unlockedLevel, 1);
    expect(snapshot.bestShots[0], 4);
    expect(snapshot.bonusGoals, contains(0));
    expect(snapshot.copyCoreCount, 2);
    expect(snapshot.copyCoreRewarded, isTrue);
    expect(snapshot.copyCoreRewardedStageIds, {'stage_2'});
  });

  test('앱 재실행 뒤 클리어·기록·보너스·복제 코어를 복원한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final firstRun = ProgressStore(stageCount: 4);

    await firstRun.recordStageClear(0);
    await firstRun.recordBestShot(0, 2);
    await firstRun.recordBonusGoal(0);
    await firstRun.recordCopyCore(
      3,
      true,
      rewardedStageIds: const ['stage_1', 'stage_3'],
    );

    final afterRestart = await ProgressStore(stageCount: 4).load();

    expect(afterRestart.clearedLevels, contains(0));
    expect(afterRestart.unlockedLevel, 1);
    expect(afterRestart.bestShots[0], 2);
    expect(afterRestart.bonusGoals, contains(0));
    expect(afterRestart.copyCoreCount, 3);
    expect(afterRestart.copyCoreRewarded, isTrue);
    expect(afterRestart.copyCoreRewardedStageIds, {'stage_1', 'stage_3'});
  });

  test('동시에 들어온 클리어와 최고 기록을 순서대로 보존한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final concurrentStore = ProgressStore(stageCount: 4);

    await Future.wait([
      concurrentStore.recordStageClear(0),
      concurrentStore.recordStageClear(1),
      concurrentStore.recordStageClear(2),
      concurrentStore.recordBestShot(0, 6),
      concurrentStore.recordBestShot(0, 3),
      concurrentStore.recordBonusGoal(1),
    ]);

    final snapshot = await concurrentStore.load();
    expect(snapshot.clearedLevels, {0, 1, 2});
    expect(snapshot.unlockedLevel, 3);
    expect(snapshot.bestShots[0], 3);
    expect(snapshot.bonusGoals, contains(1));
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
    expect(snapshot.copyCoreRewardedStageIds, isEmpty);
  });

  test('복제 코어 보상 단계는 유효한 안정 ID만 중복 없이 저장한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final stableStore = ProgressStore(
      stageCount: 3,
      stageIds: const ['stage_a', 'stage_b', 'stage_c'],
    );

    await stableStore.recordCopyCore(
      4,
      false,
      rewardedStageIds: const ['stage_b', 'stage_b', '삭제된_단계'],
    );
    final snapshot = await stableStore.load();

    expect(snapshot.copyCoreRewarded, isTrue);
    expect(snapshot.copyCoreRewardedStageIds, {'stage_b'});
  });

  test('스테이지 배열 순서가 바뀌어도 안정 ID로 최고 기록을 유지한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final original = ProgressStore(
      stageCount: 2,
      stageIds: const ['stage_a', 'stage_b'],
    );
    await original.recordStageClear(1);
    await original.recordBestShot(1, 2);

    final reordered = ProgressStore(
      stageCount: 2,
      stageIds: const ['stage_b', 'stage_a'],
    );
    final snapshot = await reordered.load();

    expect(snapshot.clearedLevels, contains(0));
    expect(snapshot.bestShots[0], 2);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList(ProgressStore.clearedStageIdsKey),
      contains('stage_b'),
    );
  });

  test('기존 숫자 저장 키를 안정 ID 저장소로 읽고 다시 보존한다', () async {
    SharedPreferences.setMockInitialValues({
      ProgressStore.clearedLevelsKey: ['1'],
      'best_shots_level_1': 3,
    });

    final store = ProgressStore(
      stageCount: 2,
      stageIds: const ['stage_a', 'stage_b'],
    );
    final snapshot = await store.load();

    expect(snapshot.clearedLevels, contains(1));
    expect(snapshot.bestShots[1], 3);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList(ProgressStore.clearedStageIdsKey), [
      'stage_b',
    ]);
    expect(preferences.getInt('best_shots_stage_stage_b'), 3);
  });

  test('기존 1~4단계 안정 ID 기록은 5단계를 해금한다', () async {
    const stageIds = [
      'stage_heavy',
      'stage_bouncy',
      'stage_chain_gate',
      'stage_balloon',
      'stage_drained',
    ];
    SharedPreferences.setMockInitialValues({
      ProgressStore.clearedStageIdsKey: stageIds.take(4).toList(),
      ProgressStore.unlockedLevelKey: 3,
    });
    final expanded = ProgressStore(stageCount: 5, stageIds: stageIds);

    final restored = await expanded.load();

    expect(restored.clearedLevels, {0, 1, 2, 3});
    expect(restored.unlockedLevel, 4);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList(ProgressStore.clearedStageIdsKey),
      stageIds.take(4).toList(),
    );
  });

  test('5단계를 모두 클리어한 기록은 앱 재시작 뒤 전체 해금을 유지한다', () async {
    const stageIds = [
      'stage_heavy',
      'stage_bouncy',
      'stage_chain_gate',
      'stage_balloon',
      'stage_drained',
    ];
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final firstRun = ProgressStore(stageCount: 5, stageIds: stageIds);
    for (var index = 0; index < stageIds.length; index++) {
      await firstRun.recordStageClear(index);
    }

    final afterRestart = await ProgressStore(
      stageCount: 5,
      stageIds: stageIds,
    ).load();

    expect(afterRestart.clearedLevels, {0, 1, 2, 3, 4});
    expect(afterRestart.unlockedLevel, 4);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getStringList(ProgressStore.clearedStageIdsKey),
      stageIds,
    );
  });
}
