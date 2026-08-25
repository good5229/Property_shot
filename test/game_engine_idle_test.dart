import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/main.dart';

void main() {
  testWidgets('계획 단계의 Flame 엔진은 정적 화면을 계속 다시 그리지 않는다', (tester) async {
    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: false,
        showStageSelector: false,
        loadGameAssets: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final gameWidget =
        tester.widget(
              find.byWidgetPredicate(
                (widget) => widget is GameWidget<PropertyShotGame>,
              ),
            )
            as GameWidget<PropertyShotGame>;
    expect(gameWidget.game?.paused, isTrue);
    expect(tester.takeException(), isNull);
  });
}
