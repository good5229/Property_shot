import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/daily_challenge_screen.dart';
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
    (name: '320x700', width: 320.0, height: 700.0, largeText: false),
    (name: '390x844', width: 390.0, height: 844.0, largeText: false),
    (name: '768x1024', width: 768.0, height: 1024.0, largeText: false),
    (name: '390x844_large_text', width: 390.0, height: 844.0, largeText: true),
  ]) {
    testWidgets('오늘의 도전 개요 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('daily_challenge_golden'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
            home: MediaQuery(
              data: MediaQueryData(
                textScaler: fixture.largeText
                    ? const TextScaler.linear(1.35)
                    : const TextScaler.linear(1.0),
              ),
              child: DailyChallengeScreen(
                now: () => DateTime.utc(2026, 8, 8, 12),
                onExit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('daily_challenge_overview')), findsOneWidget);
      await expectLater(
        find.byKey(const Key('daily_challenge_golden')),
        matchesGoldenFile('goldens/daily_challenge_${fixture.name}.png'),
      );
    });
  }
}
