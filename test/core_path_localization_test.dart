import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/app_language.dart';
import 'package:property_shot/ui/core_experience_screen.dart';
import 'package:property_shot/ui/daily_challenge_screen.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/puzzle_forge_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('언어 저장소는 ko/en만 복원하고 알 수 없는 값은 안전하게 무시한다', () async {
    const store = AppLanguageStore();
    SharedPreferences.setMockInitialValues(<String, Object>{
      AppLanguageStore.key: '../../unexpected',
    });

    expect(
      await store.load(fallback: AppLanguage.english),
      AppLanguage.english,
    );
    await store.save(AppLanguage.korean);
    expect(await store.load(), AppLanguage.korean);
  });

  testWidgets('홈의 EN 선택은 핵심 행동을 바꾸고 재시작 뒤에도 유지된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language_toggle_button')));
    await tester.pumpAndSettle();
    expect(find.text('PROPERTY SHOT'), findsOneWidget);
    expect(find.text('60-SECOND CORE PLAY'), findsOneWidget);
    expect(find.text('START FIRST STAGE'), findsOneWidget);
    expect(find.text('한국어'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();
    expect(find.text('PROPERTY SHOT'), findsOneWidget);
  });

  testWidgets('영어 홈에서 Puzzle Forge까지 영어 설명이 이어진다', (tester) async {
    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        initialLanguage: AppLanguage.english,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('puzzle_forge_entry_button')));
    await tester.pumpAndSettle();

    expect(find.text('CODEX PUZZLE FORGE'), findsOneWidget);
    expect(find.text('AI CANDIDATES DO NOT SHIP UNREVIEWED'), findsOneWidget);
    expect(find.text('REAL CANDIDATE DECISIONS'), findsOneWidget);
    expect(find.text('REJECTED'), findsNWidgets(2));
    expect(find.text('ADOPTED'), findsOneWidget);
  });

  testWidgets('60초 핵심 체험의 목표·상태·다음 행동이 영어로 제공된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CoreExperienceScreen(
          language: AppLanguage.english,
          initialSceneIndex: 2,
          loadGameAssets: false,
          onExit: () {},
          onContinueCampaign: () {},
        ),
      ),
    );
    await tester.pump();

    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(game.objectiveOverride, contains('CORE PLAY 3/3'));
    expect(game.objectiveOverride, contains('bumper or stopper'));
    expect(game.nextActionLabel, 'FINISH CORE PLAY');
    expect(game.initialState!.message, contains('missed ball stays'));
    expect(game.levelOverride!.name, 'Scene 3 · Turn Failure into a Tool');
  });

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('영어 일일 도전은 ${size.width.toInt()}px에서 겹치지 않는다', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: DailyChallengeScreen(
            language: AppLanguage.english,
            now: () => DateTime.utc(2026, 8, 8, 12),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('DAILY ROUTE'), findsOneWidget);
      expect(find.text('TRAIT FOUNDATIONS'), findsOneWidget);
      expect(find.text('START OFFICIAL RUN'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
