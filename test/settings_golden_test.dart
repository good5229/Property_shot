import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

  for (final fixture in const [
    (name: '320x568', width: 320.0, height: 568.0),
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    testWidgets('게임 설정 위·아래 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const PropertyShotApp(
          showHome: true,
          fontFamilyOverride: 'GoldenNanumGothic',
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('feedback_settings_button')));
      await tester.pumpAndSettle();

      expect(find.text('게임 설정'), findsOneWidget);
      expect(
        find.byKey(const Key('local_session_export_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('local_session_role_review_button')),
        findsOneWidget,
      );
      expect(find.textContaining('링크 생성이나 서버 전송'), findsOneWidget);
      expect(find.text('마지막 샷 슬로모션'), findsOneWidget);
      await expectLater(
        find.byType(AlertDialog),
        matchesGoldenFile('goldens/settings_top_${fixture.name}.png'),
      );

      await tester.ensureVisible(find.byKey(const Key('help_reset_button')));
      await tester.pumpAndSettle();
      expect(find.text('배경 음악'), findsOneWidget);
      await expectLater(
        find.byType(AlertDialog),
        matchesGoldenFile('goldens/settings_bottom_${fixture.name}.png'),
      );
    });
  }
}
