enum NextGoalKind {
  clearStage,
  discoverMechanic,
  optionalChallenge,
  improvePar,
  alternateSolution,
}

class NextGoalRecommendation {
  const NextGoalRecommendation({
    required this.kind,
    required this.stageIndex,
    required this.title,
    required this.reason,
    required this.actionLabel,
  });

  final NextGoalKind kind;
  final int stageIndex;
  final String title;
  final String reason;
  final String actionLabel;
}

class NextGoalRecommendationEngine {
  const NextGoalRecommendationEngine();

  NextGoalRecommendation recommend({
    required int stageCount,
    required int unlockedLevel,
    required Set<int> clearedLevels,
    required Map<int, int> discoveryCounts,
    required Map<int, int> discoveryTotals,
    required Map<int, int> bestShots,
    required Map<int, int> parShots,
    required Set<int> bonusGoals,
    required Map<int, int> solutionCounts,
  }) {
    if (stageCount <= 0) {
      throw ArgumentError.value(stageCount, 'stageCount', '1 이상이어야 합니다.');
    }
    final available = unlockedLevel.clamp(0, stageCount - 1);

    for (var index = 0; index <= available; index++) {
      if (!clearedLevels.contains(index)) {
        return NextGoalRecommendation(
          kind: NextGoalKind.clearStage,
          stageIndex: index,
          title: '${index + 1}단계 길 열기',
          reason: index == 0
              ? '첫 발사와 속성 옮기기를 익히면 섬 복구가 시작돼요.'
              : '아직 클리어하지 않은 가장 가까운 섬이라 다음 구역을 열 수 있어요.',
          actionLabel: '이 단계 시작',
        );
      }
    }

    for (var index = 0; index <= available; index++) {
      final total = discoveryTotals[index] ?? 0;
      final found = (discoveryCounts[index] ?? 0).clamp(0, total);
      if (total > 0 && found < total) {
        return NextGoalRecommendation(
          kind: NextGoalKind.discoverMechanic,
          stageIndex: index,
          title: '${index + 1}단계 발견 ${found + 1}/$total',
          reason: '아직 확인하지 않은 물리 사건 ${total - found}개가 있어 섬 시설 복구에 가까워져요.',
          actionLabel: '발견 이어가기',
        );
      }
    }

    for (var index = 0; index <= available; index++) {
      if (clearedLevels.contains(index) && !bonusGoals.contains(index)) {
        return NextGoalRecommendation(
          kind: NextGoalKind.optionalChallenge,
          stageIndex: index,
          title: '${index + 1}단계 선택 도전',
          reason: '클리어는 끝냈지만 선택 도전이 남아 같은 기믹을 다른 방식으로 시험할 수 있어요.',
          actionLabel: '선택 도전 보기',
        );
      }
    }

    for (var index = 0; index <= available; index++) {
      final best = bestShots[index];
      final par = parShots[index];
      if (best != null && par != null && best > par) {
        return NextGoalRecommendation(
          kind: NextGoalKind.improvePar,
          stageIndex: index,
          title: '${index + 1}단계 파 줄이기',
          reason: '현재 최고 $best발에서 추천 파 $par발까지 ${best - par}발 줄일 여지가 있어요.',
          actionLabel: '기록 도전',
        );
      }
    }

    for (var index = 0; index <= available; index++) {
      final count = solutionCounts[index] ?? 0;
      if (count < 2) {
        return NextGoalRecommendation(
          kind: NextGoalKind.alternateSolution,
          stageIndex: index,
          title: '${index + 1}단계 다른 해법',
          reason: count == 0
              ? '아직 저장된 해법이 없어 첫 경로를 발견할 수 있어요.'
              : '한 경로는 찾았어요. 다른 기믹을 쓰는 두 번째 경로를 시험해 보세요.',
          actionLabel: '다른 해법 찾기',
        );
      }
    }

    return NextGoalRecommendation(
      kind: NextGoalKind.improvePar,
      stageIndex: available,
      title: '${available + 1}단계 다시 도전',
      reason: '모든 기본 목표를 마쳤어요. 가장 최근 섬에서 더 짧고 새로운 경로를 만들어 보세요.',
      actionLabel: '최근 단계 플레이',
    );
  }
}
