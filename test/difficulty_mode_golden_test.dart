import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final canvasLoader = FontLoader('NanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'));
    await canvasLoader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  for (final fixture in const [
    (name: '320x568', width: 320.0, height: 568.0),
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    testWidgets('쉬움 예상 첫 도착 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
          home: RepaintBoundary(
            key: const Key('difficulty_golden'),
            child: GameScreen(
              initialState: levels.first.createState(0, productRules: true),
              showStageSelector: false,
              loadGameAssets: false,
              difficulty: PlayerDifficulty.easy,
            ),
          ),
        ),
      );
      await tester.pump();
      await _game(tester).toBeLoaded();
      await _aim(tester);

      await expectLater(
        find.byKey(const Key('difficulty_golden')),
        matchesGoldenFile(
          'goldens/difficulty_easy_first_arrival_${fixture.name}.png',
        ),
      );
    });
  }
}

Future<void> _aim(WidgetTester tester) async {
  final rect = tester.getRect(find.byKey(const Key('aim_area')));
  final scale = rect.width / logicalSize.x;
  final ball = levels.first
      .createState(0, productRules: true)
      .activeBall
      .position;
  final start = rect.topLeft + Offset(ball.x * scale, ball.y * scale);
  final gesture = await tester.startGesture(start);
  await gesture.moveTo(start + const Offset(80, -45));
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 80));
}

PropertyShotGame _game(WidgetTester tester) {
  final state = tester.state<GameWidgetState<PropertyShotGame>>(
    find.byType(GameWidget<PropertyShotGame>),
  );
  return state.currentGame;
}
