import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);
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
    for (final label in const [
      '마지막 샷 슬로모션',
      '충돌 순서 표시',
      '마지막 접촉 대상 강조',
      '홀 최근접 위치',
      '속성 발동 표시',
      '기믹 인과 표시',
      '충돌 경로 아이콘',
      '연쇄 점수 상세 표시',
      '진동',
      '저모션',
      '화면 흔들림',
      '강한 점멸 효과',
      '배경 음악',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
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

    await tester.ensureVisible(
      find.byKey(const Key('screen_shake_strength_dropdown')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('screen_shake_strength_dropdown')));
    await tester.pump();
    await tester.tap(find.text('강하게').last);
    await tester.pump();
    expect(GameFeedback.screenShakeStrength, 3);

    await tester.ensureVisible(find.byKey(const Key('help_reset_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('help_reset_button')));
    await tester.pump();
    expect(GameFeedback.helpRevision, 1);
  });

  testWidgets('도움말 다시 보기는 다음 플레이에서 한 번만 열린다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameFeedback.helpRevisionPreferenceKey: 1,
      GameFeedback.helpAcknowledgedRevisionPreferenceKey: 0,
    });
    GameFeedback.helpRevision = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: levels.first.createState(0, productRules: true),
          loadGameAssets: false,
          showStageSelector: false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('game_help_dialog')), findsOneWidget);
    expect(find.text('게임 도움말'), findsOneWidget);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getInt(GameFeedback.helpAcknowledgedRevisionPreferenceKey),
      1,
    );
    await tester.tap(find.byKey(const Key('game_help_close_button')));
    await tester.pump();
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
