import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/assist_recommendation.dart';
import 'package:property_shot/ui/game_screen.dart';

void main() {
  const engine = AssistRecommendationEngine();

  test('한 번 실패했을 때는 도움을 성급하게 추천하지 않는다', () {
    expect(engine.recommend(_context(failureCount: 1)), isNull);
  });

  test('두 번 막히고 힌트가 열리면 정답 수치 대신 L1을 제안한다', () {
    final result = engine.recommend(
      _context(failureCount: 2, hintAvailable: true),
    );
    expect(result?.action, AssistRecommendationAction.openHint);
    expect(result?.id, 'open_hint_l1');
  });

  test('거절한 도움은 반복하지 않고 다음 적합한 도움을 찾는다', () {
    final result = engine.recommend(
      _context(failureCount: 3, hintAvailable: true, previousAimEnabled: false),
      handledIds: {'open_hint_l1'},
    );
    expect(result?.action, AssistRecommendationAction.enablePreviousAim);
  });

  testWidgets('추천 카드는 수락과 건너뛰기를 사용자가 직접 선택한다', (tester) async {
    var accepted = false;
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildAssistRecommendationCardForTesting(
            recommendation: const AssistRecommendation(
              id: 'test',
              action: AssistRecommendationAction.enableCausality,
              title: '기믹 원인과 결과 보기',
              reason: '연결된 사건을 확인할 수 있어요.',
              actionLabel: '인과 표시 켜기',
            ),
            onAccept: () => accepted = true,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('assist_recommendation_card')), findsOneWidget);
    await tester.tap(find.byKey(const Key('assist_recommendation_accept')));
    expect(accepted, isTrue);
    await tester.tap(find.byKey(const Key('assist_recommendation_dismiss')));
    expect(dismissed, isTrue);
  });
}

AssistRecommendationContext _context({
  required int failureCount,
  bool hintAvailable = false,
  bool hintConsumed = false,
  bool previousAimEnabled = true,
}) => AssistRecommendationContext(
  failureCount: failureCount,
  latestResult: null,
  hintAvailable: hintAvailable,
  hintConsumed: hintConsumed,
  hintLevel: hintAvailable ? 1 : 0,
  hintOpenedCount: 0,
  previousAimEnabled: previousAimEnabled,
  collisionOrderEnabled: true,
  causalityEnabled: true,
);
