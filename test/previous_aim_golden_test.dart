import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
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
  });

  testWidgets('직전 조준 비교선 Golden 390x844', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: RepaintBoundary(
          key: const Key('previous_aim_golden'),
          child: GameScreen(
            initialState: levels.first.createState(0, productRules: true),
            showStageSelector: false,
            loadGameAssets: false,
          ),
        ),
      ),
    );
    await tester.pump();
    final gameState = tester.state<GameWidgetState<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    );
    await gameState.currentGame.toBeLoaded();
    gameState.currentGame.setStateSnapshot(
      gameState.currentGame.state.copyWith(aimDirection: const Vec2(1, 0)),
    );
    gameState.currentGame.setPreviousAimInput(
      const ShotInput(direction: Vec2(0.15, -0.99), power: 0.72),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(gameState.currentGame.previousAimInput, isNotNull);
    await expectLater(
      find.byKey(const Key('previous_aim_golden')),
      matchesGoldenFile('goldens/previous_aim_retry_390x844.png'),
    );
  });

  testWidgets('직전 실패 궤적 Golden 390x844', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: RepaintBoundary(
          key: const Key('previous_path_golden'),
          child: GameScreen(
            initialState: levels.first.createState(0, productRules: true),
            showStageSelector: false,
            loadGameAssets: false,
          ),
        ),
      ),
    );
    await tester.pump();
    final gameState = tester.state<GameWidgetState<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    );
    await gameState.currentGame.toBeLoaded();
    gameState.currentGame.setPreviousAimInput(
      const ShotInput(direction: Vec2(0.72, -0.69), power: 0.68),
    );
    gameState.currentGame.setPreviousShotPath(const [
      Vec2(58, 470),
      Vec2(170, 350),
      Vec2(280, 430),
      Vec2(325, 330),
    ]);
    await tester.pump(const Duration(milliseconds: 100));

    expect(gameState.currentGame.previousShotPath, hasLength(4));
    await expectLater(
      find.byKey(const Key('previous_path_golden')),
      matchesGoldenFile('goldens/previous_path_retry_390x844.png'),
    );
  });
}
