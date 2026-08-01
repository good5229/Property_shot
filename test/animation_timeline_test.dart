import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  test('30·60·120Hz 업데이트에서 충돌 이벤트와 완료 콜백은 한 번씩만 발생한다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );

    for (final framesPerSecond in [30, 60, 120]) {
      var finished = 0;
      final impactKeys = <String>{};
      final game = PropertyShotGame(
        result.state,
        onAnimationFinished: () => finished += 1,
        onShotImpact: (impact) {
          impactKeys.add('${impact.entityId}:${impact.pathIndex}');
        },
      );
      game.setStateSnapshot(
        result.state,
        path: result.path,
        transitionStart: start,
        moves: result.moves,
        impacts: result.impacts,
        animationTransaction: true,
      );

      var frame = 0;
      while (finished == 0 && frame < 4000) {
        game.update(1 / framesPerSecond);
        frame += 1;
      }

      expect(finished, 1, reason: '$framesPerSecond Hz에서 완료되지 않음');
      expect(impactKeys.length, result.impacts.length);
      game.update(1 / framesPerSecond);
      expect(finished, 1, reason: '$framesPerSecond Hz에서 완료 콜백 중복');
    }
  });
}
