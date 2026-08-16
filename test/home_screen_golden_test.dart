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
    (name: '320x568', width: 320.0, height: 568.0),
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1024x768', width: 1024.0, height: 768.0),
    (name: '1440x900', width: 1440.0, height: 900.0),
    (name: '1920x1080', width: 1920.0, height: 1080.0),
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
          'assets/generated/stone-v3.png',
          'assets/generated/crate-v3.png',
          'assets/generated/stage-icon-heavy-v1.png',
          'assets/generated/nav-helm-v1.png',
          'assets/generated/nav-stage-map-v1.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();

      expect(find.text('속성 한방'), findsOneWidget);
      expect(find.byKey(const Key('start_game_button')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('start_voyage_art'))),
        const Size.square(40),
      );
      expect(
        tester.getSize(find.byKey(const Key('stage_navigation_art'))),
        const Size.square(38),
      );
      expect(
        tester.getSize(find.byKey(const Key('first_mission_stage_art'))),
        const Size.square(74),
      );
      await expectLater(
        find.byKey(const Key('home_screen_golden')),
        matchesGoldenFile('goldens/home_screen_${fixture.name}.png'),
      );
    });
  }

  testWidgets('320 초행 홈은 첫 임무와 시작 행동만 우선한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('start_game_button')).hitTestable(),
      findsOneWidget,
    );
    expect(find.byKey(const Key('first_mission_card')), findsOneWidget);
    expect(find.text('첫 스테이지 시작'), findsOneWidget);
    expect(find.byKey(const Key('stage_select_button')), findsOneWidget);
    expect(find.byKey(const Key('daily_challenge_entry_button')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('첫 클리어 뒤 핵심 활동을 열고 고급 활동은 3회까지 예고한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'property_shot_cleared_levels': <String>['0'],
      'property_shot_cleared_stage_ids': <String>['stage_heavy'],
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    for (final key in const [
      'expedition_entry_button',
      'stage_select_button',
      'reward_inventory_entry_button',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(
      find.byKey(const Key('advanced_activities_preview')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('replay_library_entry_button')), findsNothing);
    expect(find.byKey(const Key('daily_challenge_entry_button')), findsNothing);
    expect(find.byKey(const Key('first_mission_card')), findsNothing);
  });

  testWidgets('세 스테이지를 익히면 리플레이와 오늘의 도전을 연다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'property_shot_cleared_levels': <String>['0', '1', '2'],
      'property_shot_cleared_stage_ids': <String>[
        'stage_heavy',
        'stage_bouncy',
        'stage_chain_gate',
      ],
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('advanced_activities_preview')), findsNothing);
    expect(find.byKey(const Key('advanced_activities_menu')), findsOneWidget);
    await tester.tap(find.byKey(const Key('advanced_activities_menu')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('replay_library_entry_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('daily_challenge_entry_button')),
      findsOneWidget,
    );
  });

  testWidgets('숙련 홈은 부가 활동을 접어 핵심 진행을 우선한다 Golden', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'property_shot_cleared_levels': <String>['0', '1', '2'],
      'property_shot_cleared_stage_ids': <String>[
        'stage_heavy',
        'stage_bouncy',
        'stage_chain_gate',
      ],
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        fontFamilyOverride: 'GoldenNanumGothic',
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.byKey(const Key('home_screen_golden')));
    await tester.runAsync(() async {
      for (final asset in const [
        'assets/generated/stone-v3.png',
        'assets/generated/crate-v3.png',
        'assets/generated/nav-activities-v1.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('advanced_activities_menu')), findsOneWidget);
    expect(find.text('다른 활동'), findsOneWidget);
    expect(find.byKey(const Key('daily_challenge_entry_button')), findsNothing);
    await expectLater(
      find.byKey(const Key('home_screen_golden')),
      matchesGoldenFile('goldens/home_screen_experienced_390x844.png'),
    );
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1440x900', width: 1440.0, height: 900.0),
    (name: '1920x1080', width: 1920.0, height: 1080.0),
  ]) {
    testWidgets('숙련 홈 전체 활동 이미지 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'property_shot_cleared_levels': <String>['0', '1', '2'],
        'property_shot_cleared_stage_ids': <String>[
          'stage_heavy',
          'stage_bouncy',
          'stage_chain_gate',
        ],
      });
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
          'assets/generated/stone-v3.png',
          'assets/generated/crate-v3.png',
          'assets/generated/nav-helm-v1.png',
          'assets/generated/nav-stage-map-v1.png',
          'assets/generated/nav-expedition-v1.png',
          'assets/generated/nav-reward-satchel-v1.png',
          'assets/generated/nav-replay-v1.png',
          'assets/generated/nav-daily-challenge-v1.png',
          'assets/generated/nav-activities-v1.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('advanced_activities_menu')));
      await tester.pumpAndSettle();

      for (final key in const [
        'start_voyage_art',
        'stage_navigation_art',
        'expedition_entry_button',
        'reward_inventory_entry_button',
        'replay_library_entry_button',
        'daily_challenge_entry_button',
      ]) {
        expect(find.byKey(Key(key)), findsOneWidget, reason: key);
      }
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('home_screen_golden')),
        matchesGoldenFile(
          'goldens/home_screen_experienced_expanded_${fixture.name}.png',
        ),
      );
    });
  }

  testWidgets('태블릿 홈은 미리보기와 행동 메뉴를 2열로 사용한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_tablet_layout')), findsOneWidget);
    final hero = tester.getRect(find.byKey(const Key('home_hero')));
    final actions = tester.getRect(find.byKey(const Key('home_actions')));
    expect(hero.right, lessThan(actions.left));
    expect(actions.width, greaterThanOrEqualTo(350));
    expect(tester.takeException(), isNull);
  });
}
