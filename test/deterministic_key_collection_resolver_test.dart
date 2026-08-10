import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/hint/deterministic_key_collection_resolver.dart';
import 'package:property_shot/game/hint/pattern_hint.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = DeterministicKeyCollectionResolver();
  const key = HintKeyDefinition(
    id: 'hint_key',
    position: Vec2(100, 100),
    size: Vec2(20, 20),
    version: 1,
  );
  final state = GameState(
    levelIndex: 0,
    levelName: 'test',
    ballSpawn: const Vec2(40, 100),
    entities: const [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 100),
        size: Vec2(24, 24),
      ),
      EntityState(
        id: 'crate',
        type: EntityType.crate,
        position: Vec2(10, 10),
        size: Vec2(24, 24),
      ),
    ],
  );

  test('공 경로만 sweep하고 수집은 한 번이며 state는 바꾸지 않는다', () {
    final result = ShotResult(
      state: state,
      path: const [Vec2(40, 100), Vec2(160, 100)],
      events: const [],
      moves: const [
        ShotAnimationMove(
          entityId: 'crate',
          from: Vec2(40, 100),
          to: Vec2(160, 100),
          triggerPathIndex: 0,
        ),
      ],
    );
    final events = resolver.collect(
      stateBeforeShot: state,
      result: result,
      keys: const [key],
    );
    expect(events, hasLength(1));
    expect(events.single.sourceBallId, 'active_ball');
    expect(identical(result.state, state), isTrue);
  });

  test('ball move는 수집하지만 다른 기물 move는 무시한다', () {
    final withBall = GameState(
      levelIndex: 0,
      levelName: 'test',
      ballSpawn: const Vec2(40, 200),
      entities: [
        ...state.entities,
        const EntityState(
          id: 'spent_ball_1',
          type: EntityType.ball,
          position: Vec2(40, 100),
          size: Vec2(24, 24),
        ),
      ],
    );
    final result = ShotResult(
      state: withBall,
      path: const [Vec2(40, 200), Vec2(60, 200)],
      events: const [],
      moves: const [
        ShotAnimationMove(
          entityId: 'spent_ball_1',
          from: Vec2(40, 100),
          to: Vec2(160, 100),
          triggerPathIndex: 2,
        ),
      ],
    );
    final events = resolver.collect(
      stateBeforeShot: withBall,
      result: result,
      keys: const [key],
    );
    expect(events.single.sourceBallId, 'spent_ball_1');
  });

  test('같은 열쇠는 모든 공 후보의 실제 시간 순서에서 먼저 닿은 공에 귀속된다', () {
    final withPastBall = GameState(
      levelIndex: 0,
      levelName: 'test',
      ballSpawn: const Vec2(40, 200),
      entities: [
        ...state.entities,
        const EntityState(
          id: 'spent_ball_earlier',
          type: EntityType.ball,
          position: Vec2(40, 100),
          size: Vec2(24, 24),
        ),
      ],
    );
    final result = ShotResult(
      state: withPastBall,
      path: const [
        Vec2(40, 200),
        Vec2(60, 200),
        Vec2(80, 200),
        Vec2(40, 100),
        Vec2(160, 100),
      ],
      events: const [],
      moves: const [
        ShotAnimationMove(
          entityId: 'spent_ball_earlier',
          from: Vec2(40, 100),
          to: Vec2(160, 100),
          triggerPathIndex: 1,
        ),
      ],
    );

    final events = resolver.collect(
      stateBeforeShot: withPastBall,
      result: result,
      keys: const [key],
    );

    expect(events, hasLength(1));
    expect(events.single.sourceBallId, 'spent_ball_earlier');
    expect(events.single.pathIndex, 1);
  });
}
