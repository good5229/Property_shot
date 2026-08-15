import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/next_goal_recommendation.dart';

void main() {
  const engine = NextGoalRecommendationEngine();

  NextGoalRecommendation recommend({
    Set<int> cleared = const {},
    Map<int, int> discovery = const {},
    Set<int> bonus = const {},
    Map<int, int> best = const {},
    Map<int, int> solutions = const {},
  }) => engine.recommend(
    stageCount: 3,
    unlockedLevel: 2,
    clearedLevels: cleared,
    discoveryCounts: discovery,
    discoveryTotals: const {0: 3, 1: 3, 2: 3},
    bestShots: best,
    parShots: const {0: 2, 1: 3, 2: 3},
    bonusGoals: bonus,
    solutionCounts: solutions,
  );

  test('미클리어 단계가 다른 숙련 목표보다 먼저 추천된다', () {
    final result = recommend(cleared: {0}, best: {0: 4});
    expect(result.kind, NextGoalKind.clearStage);
    expect(result.stageIndex, 1);
    expect(result.reason, contains('아직 클리어하지 않은'));
  });

  test('클리어 뒤에는 발견·선택 도전·파·다른 해법 순으로 추천한다', () {
    const allCleared = {0, 1, 2};
    expect(
      recommend(cleared: allCleared, discovery: const {0: 2}).kind,
      NextGoalKind.discoverMechanic,
    );
    expect(
      recommend(cleared: allCleared, discovery: const {0: 3, 1: 3, 2: 3}).kind,
      NextGoalKind.optionalChallenge,
    );
    expect(
      recommend(
        cleared: allCleared,
        discovery: const {0: 3, 1: 3, 2: 3},
        bonus: allCleared,
        best: const {0: 4, 1: 3, 2: 3},
      ).kind,
      NextGoalKind.improvePar,
    );
    final alternate = recommend(
      cleared: allCleared,
      discovery: const {0: 3, 1: 3, 2: 3},
      bonus: allCleared,
      best: const {0: 2, 1: 3, 2: 3},
      solutions: const {0: 1, 1: 2, 2: 2},
    );
    expect(alternate.kind, NextGoalKind.alternateSolution);
    expect(alternate.reason, contains('두 번째 경로'));
  });

  test('손상된 범위와 빈 카탈로그 입력을 안전하게 처리한다', () {
    final result = engine.recommend(
      stageCount: 1,
      unlockedLevel: 999,
      clearedLevels: const {},
      discoveryCounts: const {},
      discoveryTotals: const {0: 3},
      bestShots: const {},
      parShots: const {0: 2},
      bonusGoals: const {},
      solutionCounts: const {},
    );
    expect(result.stageIndex, 0);
    expect(
      () => engine.recommend(
        stageCount: 0,
        unlockedLevel: 0,
        clearedLevels: const {},
        discoveryCounts: const {},
        discoveryTotals: const {},
        bestShots: const {},
        parShots: const {},
        bonusGoals: const {},
        solutionCounts: const {},
      ),
      throwsArgumentError,
    );
  });
}
