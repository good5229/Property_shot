import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/ui/game_ball_painter.dart';

void main() {
  testWidgets('청록 유광 공 꾸미기는 기본 공과 명확히 구분된다', (tester) async {
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

  testWidgets('꾸미기 본체·테두리·파티클은 모바일·태블릿·PC 표시 크기에서 구분된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 150));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: RepaintBoundary(
          key: Key('ball_appearance_responsive_sizes'),
          child: ColoredBox(
            color: Color(0xFFFFF7DB),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox.square(
                  dimension: 52,
                  child: CustomPaint(
                    painter: GameBallIconPainter(null, rewardAppearance: true),
                  ),
                ),
                SizedBox.square(
                  dimension: 76,
                  child: CustomPaint(
                    painter: GameBallIconPainter(null, rewardAppearance: true),
                  ),
                ),
                SizedBox.square(
                  dimension: 108,
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
      find.byKey(const Key('ball_appearance_responsive_sizes')),
      matchesGoldenFile('goldens/ball_reward_appearance_responsive_sizes.png'),
    );
  });

  testWidgets('모션 감소에서도 정지한 소수 파티클과 꾸미기 식별성을 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(160, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: RepaintBoundary(
          key: Key('ball_appearance_reduced_motion'),
          child: ColoredBox(
            color: Color(0xFFFFF7DB),
            child: Center(
              child: SizedBox.square(
                dimension: 92,
                child: CustomPaint(
                  painter: GameBallIconPainter(
                    null,
                    rewardAppearance: true,
                    reducedMotion: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byKey(const Key('ball_appearance_reduced_motion')),
      matchesGoldenFile('goldens/ball_reward_appearance_reduced_motion.png'),
    );
  });

  test('공 꾸미기 토글은 경로·판정·히트박스를 바꾸지 않는다', () {
    final state = levels.first.createState(0, productRules: true);
    final game = PropertyShotGame(state, loadVisualAssets: false);
    const input = ShotInput(direction: Vec2(0.82, -0.57), power: 0.64);
    const resolver = ShotResolver();
    final before = resolver.resolve(state, input);
    final radiusBefore = state.activeBall.radius;
    final sizeBefore = state.activeBall.size;

    game.setBallRewardAppearance(true);
    final after = resolver.resolve(game.state, input);

    expect(game.ballRewardAppearance, isTrue);
    expect(identical(game.state, state), isTrue);
    expect(game.state.activeBall.radius, radiusBefore);
    expect(game.state.activeBall.size, sizeBefore);
    expect(after.path, before.path);
    expect(after.events, before.events);
    expect(after.state.phase, before.state.phase);
  });
}
