import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/app_language.dart';
import 'package:property_shot/ui/daily_challenge_screen.dart';
import 'package:property_shot/ui/puzzle_forge_screen.dart';
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
    (name: 'narrow', size: Size(320, 568)),
    (name: 'mobile', size: Size(390, 844)),
    (name: 'pc', size: Size(1440, 900)),
  ]) {
    testWidgets('영어 홈 반응형 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(fixture.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const PropertyShotApp(
          showHome: true,
          initialLanguage: AppLanguage.english,
          fontFamilyOverride: 'GoldenNanumGothic',
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(
        find.byKey(const Key('home_screen_golden')),
      );
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/generated/stone-v3.png',
          'assets/generated/crate-v3.png',
          'assets/generated/stage-icon-property-transfer-v1.png',
          'assets/generated/nav-helm-v1.png',
          'assets/generated/nav-stage-map-v1.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('home_screen_golden')),
        matchesGoldenFile('goldens/openai_home_en_${fixture.name}.png'),
      );
    });

    if (fixture.name == 'mobile') {
      testWidgets('영어 Puzzle Forge 반응형 Golden ${fixture.name}', (tester) async {
        final summary = await loadPuzzleForgeSummary();
        await tester.binding.setSurfaceSize(fixture.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
            home: RepaintBoundary(
              key: const Key('openai_forge_golden'),
              child: PuzzleForgeScreen(
                language: AppLanguage.english,
                summary: summary,
                onBack: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('forge_role_flow')), findsOneWidget);
        await expectLater(
          find.byKey(const Key('openai_forge_golden')),
          matchesGoldenFile('goldens/openai_forge_en_${fixture.name}.png'),
        );
      });
    }

    if (fixture.name != 'narrow') {
      testWidgets('영어 일일 도전 반응형 Golden ${fixture.name}', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await tester.binding.setSurfaceSize(fixture.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
            home: RepaintBoundary(
              key: const Key('openai_daily_golden'),
              child: DailyChallengeScreen(
                language: AppLanguage.english,
                now: () => DateTime.utc(2026, 8, 8, 12),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(tester.takeException(), isNull);
        await expectLater(
          find.byKey(const Key('openai_daily_golden')),
          matchesGoldenFile('goldens/openai_daily_en_${fixture.name}.png'),
        );
      });
    }
  }
}
