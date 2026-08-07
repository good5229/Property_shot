import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/stage_chain_challenge.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const evaluator = StageChainChallengeEvaluator();

  test('패턴 1은 벽·과거 공의 실제 인과 순서만 인정한다', () {
    final events = [
      _impact('wall_left', EntityType.wall, 0),
      _impact('field_boundary_bottom', EntityType.wall, 1),
      _impact('spent_ball_1', EntityType.ball, 2),
      _impact('field_boundary_bottom', EntityType.wall, 3),
      _impact('wall_left', EntityType.wall, 4),
    ];

    expect(evaluator.matchesOrderedCushionPastBallSequence(events), isTrue);
  });

  test('패턴 1은 같은 대상이 있어도 역순이면 인정하지 않는다', () {
    final events = [
      _impact('spent_ball_1', EntityType.ball, 0),
      _impact('wall_left', EntityType.wall, 1),
      _impact('field_boundary_bottom', EntityType.wall, 2),
      _impact('field_boundary_bottom', EntityType.wall, 3),
      _impact('wall_left', EntityType.wall, 4),
    ];

    expect(evaluator.matchesOrderedCushionPastBallSequence(events), isFalse);
  });

  test('패턴 1은 과거 공 뒤의 벽 쿠션이 없으면 인정하지 않는다', () {
    final events = [
      _impact('wall_left', EntityType.wall, 0),
      _impact('field_boundary_bottom', EntityType.wall, 1),
      _impact('spent_ball_1', EntityType.ball, 2),
    ];

    expect(evaluator.matchesOrderedCushionPastBallSequence(events), isFalse);
  });
}

PhysicsEvent _impact(String targetId, EntityType type, int index) {
  return PhysicsEvent(
    eventId: 'impact_$index',
    kind: PhysicsEventKind.impact,
    pathIndex: index,
    sourceEntityId: 'active_ball',
    targetEntityId: targetId,
    targetType: type,
    position: const Vec2(100, 100),
    normal: const Vec2(1, 0),
    impulse: 10,
    resultingVelocity: const Vec2(4, 0),
  );
}
