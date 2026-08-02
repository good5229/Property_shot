import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
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
    testWidgets('전체 플레이 화면 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('game_screen_golden'),
          child: PropertyShotApp(
            initialState: levels[0]
                .createState(0, productRules: true)
                .copyWith(message: '방향 조정 · 길게 누르기 · 손 떼기'),
            showStageSelector: false,
            fontFamilyOverride: 'GoldenNanumGothic',
            loadGameAssets: false,
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byKey(const Key('aim_area')));
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/generated/stone-v2.png',
          'assets/generated/crate-v2.png',
          'assets/generated/jelly-bumper-v1.png',
          'assets/icons/ball.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      // Flame의 onLoad와 실제 첫 렌더 프레임이 완료될 때까지 이벤트 루프를 진행한다.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
        find.byType(GameWidget<PropertyShotGame>),
      );
      await gameWidgetState.currentGame.toBeLoaded();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byKey(const Key('aim_area')), findsOneWidget);
      expect(find.byKey(const Key('compact_message')), findsOneWidget);
      expect(find.text('1. 무거움 익히기'), findsOneWidget);
      await expectLater(
        find.byKey(const Key('game_screen_golden')),
        matchesGoldenFile('goldens/game_screen_${fixture.name}.png'),
      );
    });
  }
}
