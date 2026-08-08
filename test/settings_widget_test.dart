import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('설정 메뉴는 작은 화면과 큰 글자에서 스크롤된다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 568),
          textScaler: TextScaler.linear(1.5),
        ),
        child: const PropertyShotApp(showHome: true),
      ),
    );
    await tester.pump();
    await _pumpForAsyncWork(tester);
    tester
        .widget<IconButton>(find.byKey(const Key('feedback_settings_button')))
        .onPressed!();
    await tester.pump();

    expect(find.text('효과음'), findsOneWidget);
    expect(
      find.byKey(const Key('screen_shake_strength_dropdown')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('help_reset_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('설정 메뉴에서 흔들림 강도와 도움말 초기화를 실행한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameFeedback.screenShakeStrength = 2;
    GameFeedback.helpRevision = 0;

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();
    await _pumpForAsyncWork(tester);
    tester
        .widget<IconButton>(find.byKey(const Key('feedback_settings_button')))
        .onPressed!();
    await tester.pump();

    await tester.tap(find.byKey(const Key('screen_shake_strength_dropdown')));
    await tester.pump();
    await tester.tap(find.text('강하게').last);
    await tester.pump();
    expect(GameFeedback.screenShakeStrength, 3);

    await tester.tap(find.byKey(const Key('help_reset_button')));
    await tester.pump();
    expect(GameFeedback.helpRevision, 1);
  });
}

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
