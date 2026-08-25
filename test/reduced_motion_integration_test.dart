import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

  testWidgets('운영체제의 애니메이션 줄이기를 게임 물리 연출에도 즉시 반영한다', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: GameScreen(
            showStageSelector: false,
            loadGameAssets: false,
          ),
        ),
      ),
    );
    await tester.pump();

    final game = tester
        .state<GameWidgetState<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        )
        .currentGame;
    expect(game.reducedMotion, isTrue);
  });
}
