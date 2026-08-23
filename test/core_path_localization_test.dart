import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/app_language.dart';
import 'package:property_shot/ui/core_experience_screen.dart';
import 'package:property_shot/ui/daily_challenge_screen.dart';
import 'package:property_shot/ui/game_screen.dart';
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

  test('언어 저장소를 읽을 수 없으면 기본 언어로 복구한다', () async {
    final store = AppLanguageStore(
      reader: () => Future<String?>.error(const FormatException('corrupt')),
    );

    expect(
      await store.load(fallback: AppLanguage.english),
      AppLanguage.english,
    );
  });

  test('언어 저장 실패는 호출자가 처리할 수 있는 단일 오류로 정규화한다', () async {
    final rejected = AppLanguageStore(writer: (_) async => false);
    final unavailable = AppLanguageStore(
      writer: (_) => Future<bool>.error(const FormatException('unavailable')),
    );

    await expectLater(rejected.save(AppLanguage.english), throwsStateError);
    await expectLater(unavailable.save(AppLanguage.english), throwsStateError);
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

  testWidgets('언어 저장이 거부되어도 화면 전환은 유지하고 복구 안내를 보인다', (tester) async {
    await tester.pumpWidget(
      PropertyShotApp(
        showHome: true,
        languageStore: AppLanguageStore(writer: (_) async => false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('language_toggle_button')));
    await tester.pumpAndSettle();

    expect(find.text('PROPERTY SHOT'), findsOneWidget);
    expect(
      find.text(
        'Could not save the language choice. It remains active for this session.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('늦게 끝난 저장 복원은 이미 선택한 언어를 되돌리지 않는다', (tester) async {
    final delayedRead = Completer<String?>();
    await tester.pumpWidget(
      PropertyShotApp(
        showHome: true,
        languageStore: AppLanguageStore(
          reader: () => delayedRead.future,
          writer: (_) async => true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('language_toggle_button')));
    await tester.pump();
    expect(find.text('PROPERTY SHOT'), findsOneWidget);

    delayedRead.complete('ko');
    await tester.pumpAndSettle();
    expect(find.text('PROPERTY SHOT'), findsOneWidget);
    expect(find.text('속성 한방'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320x568·글자 200%에서도 홈 핵심 행동을 스크롤로 이용한다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('core_experience_button')), findsOneWidget);
    expect(find.byKey(const Key('start_game_button')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: '홈 200%');
    await tester.ensureVisible(find.byKey(const Key('stage_select_button')));
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage_select_screen')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: '지도 상단 200%');
    await tester.scrollUntilVisible(
      find.text('첫 항해 진행'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('첫 항해 진행'), findsOneWidget);
    expect(tester.takeException(), isNull, reason: '지도 경로 200%');
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
