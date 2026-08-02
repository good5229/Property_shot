import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
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

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    testWidgets('홈 화면 Golden ${fixture.name}', (tester) async {
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

      final context = tester.element(
        find.byKey(const Key('home_screen_golden')),
      );
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/generated/stone-v2.png',
          'assets/generated/crate-v2.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('속성 한방'), findsOneWidget);
      expect(find.byKey(const Key('start_game_button')), findsOneWidget);
      await expectLater(
        find.byKey(const Key('home_screen_golden')),
        matchesGoldenFile('goldens/home_screen_${fixture.name}.png'),
      );
    });
  }
}
