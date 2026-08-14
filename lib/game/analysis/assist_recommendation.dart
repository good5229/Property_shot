import '../simulation/shot_resolver.dart';

enum AssistRecommendationAction {
  openHint,
  enablePreviousAim,
  enableCollisionOrder,
  enableCausality,
}

class AssistRecommendation {
  const AssistRecommendation({
    required this.id,
    required this.action,
    required this.title,
    required this.reason,
    required this.actionLabel,
  });

  final String id;
  final AssistRecommendationAction action;
  final String title;
  final String reason;
  final String actionLabel;
}

class AssistRecommendationContext {
  const AssistRecommendationContext({
    required this.failureCount,
    required this.latestResult,
    required this.hintAvailable,
    required this.hintConsumed,
    required this.hintLevel,
    required this.hintOpenedCount,
    required this.previousAimEnabled,
    required this.collisionOrderEnabled,
    required this.causalityEnabled,
  });

  final int failureCount;
  final ShotResult? latestResult;
  final bool hintAvailable;
  final bool hintConsumed;
  final int hintLevel;
  final int hintOpenedCount;
  final bool previousAimEnabled;
  final bool collisionOrderEnabled;
  final bool causalityEnabled;
}

class AssistRecommendationEngine {
  const AssistRecommendationEngine();

  AssistRecommendation? recommend(
    AssistRecommendationContext context, {
    Set<String> handledIds = const {},
  }) {
    if (context.failureCount < 2) return null;

    final candidates = <AssistRecommendation>[
      if (context.hintAvailable &&
          (!context.hintConsumed ||
              context.hintOpenedCount < context.hintLevel))
        AssistRecommendation(
          id: context.hintConsumed ? 'open_hint_l2' : 'open_hint_l1',
          action: AssistRecommendationAction.openHint,
          title: context.hintConsumed ? '한 단계 더 구체적인 팁' : '현재 퍼즐의 첫 단서',
          reason: context.hintConsumed
              ? '같은 지점에서 다시 막혔어요. 수치 정답 대신 다음 행동 순서를 확인할 수 있어요.'
              : '두 번의 발사 결과를 바탕으로 이 패턴에서 먼저 시험할 기믹을 알려드려요.',
          actionLabel: context.hintConsumed ? 'L2 팁 보기' : 'L1 팁 보기',
        ),
      if (!context.previousAimEnabled)
        const AssistRecommendation(
          id: 'enable_previous_aim',
          action: AssistRecommendationAction.enablePreviousAim,
          title: '직전 조준과 비교하기',
          reason: '이전 각도와 힘을 회색 표식으로 남겨 한 가지만 바꿔 볼 수 있어요.',
          actionLabel: '비교선 켜기',
        ),
      if (!context.collisionOrderEnabled &&
          (context.latestResult?.impacts.length ?? 0) >= 2)
        const AssistRecommendation(
          id: 'enable_collision_order',
          action: AssistRecommendationAction.enableCollisionOrder,
          title: '충돌 순서 확인하기',
          reason: '여러 기물에 닿았어요. 어떤 순서로 부딪혔는지 번호로 확인해 보세요.',
          actionLabel: '충돌 순서 켜기',
        ),
      if (!context.causalityEnabled)
        const AssistRecommendation(
          id: 'enable_causality',
          action: AssistRecommendationAction.enableCausality,
          title: '기믹 원인과 결과 보기',
          reason: '스위치·문·풍선처럼 연결된 사건을 선과 라벨로 확인할 수 있어요.',
          actionLabel: '인과 표시 켜기',
        ),
    ];

    for (final recommendation in candidates) {
      if (!handledIds.contains(recommendation.id)) return recommendation;
    }
    return null;
  }
}
