import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/game_ball_painter.dart';

void main() {
  testWidgets('청록·금색 공 꾸미기는 기본 공과 명확히 구분된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(240, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: RepaintBoundary(
          key: Key('ball_appearance_comparison'),
          child: ColoredBox(
            color: Color(0xFFFFF7DB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CustomPaint(painter: GameBallIconPainter(null)),
                ),
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CustomPaint(
                    painter: GameBallIconPainter(null, rewardAppearance: true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('ball_appearance_comparison')),
      matchesGoldenFile('goldens/ball_reward_appearance_comparison.png'),
    );
  });
}
