import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/tutorial_experiment.dart';

void main() {
  test('튜토리얼 실험 조건은 한글 표시와 안정적인 내부 코드를 함께 가진다', () {
    expect(TutorialExperimentVariant.values.map((variant) => variant.label), [
      '안내형',
      '행동 유도형',
      '무설명형',
    ]);
    expect(TutorialExperimentVariant.values.map((variant) => variant.code), [
      'guided',
      'action',
      'silent',
    ]);
    expect(
      TutorialExperimentVariant.values.every(
        (variant) => variant.description.isNotEmpty,
      ),
      isTrue,
    );
  });

  testWidgets('개발 표시를 켜면 튜토리얼 조건 선택기가 한글로 열린다', (tester) async {
    await tester.pumpWidget(
      const PropertyShotApp(showHome: true, showDebugControls: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tutorial_experiment_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('tutorial_experiment_dialog')), findsOneWidget);
    expect(find.text('안내형'), findsOneWidget);
    expect(find.text('행동 유도형'), findsOneWidget);
    expect(find.text('무설명형'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial_variant_silent')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tutorial_experiment_dialog')), findsNothing);
  });
}
