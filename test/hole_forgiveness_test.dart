import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();

  test('저속·안쪽 진행의 홀 가장자리 근접 입력만 자연스럽게 포획한다', () {
    final state = _state(holeY: 305);
    const raw = ShotInput(direction: Vec2(1, 0), power: 0.30);
    const assisted = ShotInput(
      direction: Vec2(1, 0),
      power: 0.30,
      holeForgivenessRadius: 8,
      assistKind: ShotAssistKind.stabilized,
    );

    final miss = resolver.resolve(state, raw);
    final captured = resolver.resolve(state, assisted);

    expect(miss.state.phase, isNot(GamePhase.success));
    expect(captured.state.phase, GamePhase.success);
    expect(
      captured.events,
      containsAll(['hole_entered', 'hole_lip_in_assist']),
    );
    expect(captured.path.last, const Vec2(220, 305));
  });

  test('고속으로 홀 옆을 스치면 관용 반경이 있어도 자석처럼 끌지 않는다', () {
    final result = resolver.resolve(
      _state(holeX: 130, holeY: 305, stopAfterHole: true),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 1,
        holeForgivenessRadius: 12,
        assistKind: ShotAssistKind.targetSnap,
      ),
    );

    expect(result.state.phase, isNot(GamePhase.success));
    expect(result.events, isNot(contains('hole_lip_in_assist')));
  });

  test('거의 접선으로 스치는 입력은 저속이어도 홀 관용을 적용하지 않는다', () {
    final result = resolver.resolve(
      _state(holeY: 307.5),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.30,
        holeForgivenessRadius: 8,
        assistKind: ShotAssistKind.stabilized,
      ),
    );

    expect(result.state.phase, isNot(GamePhase.success));
    expect(result.events, isNot(contains('hole_lip_in_assist')));
  });

  test('홀 관용 입력도 같은 초기 상태에서 완전히 결정론적이다', () {
    final state = _state(holeY: 305);
    const input = ShotInput(
      direction: Vec2(1, 0),
      power: 0.30,
      holeForgivenessRadius: 8,
      assistKind: ShotAssistKind.stabilized,
    );
    final first = resolver.resolve(state, input);

    for (var index = 0; index < 20; index++) {
      final next = resolver.resolve(state, input);
      expect(next.events, first.events);
      expect(next.path, first.path);
      expect(next.state.phase, first.state.phase);
    }
  });
}

GameState _state({
  double holeX = 220,
  required double holeY,
  bool stopAfterHole = false,
}) => GameState(
  levelIndex: 0,
  levelName: '홀 관용 시험',
  ballSpawn: const Vec2(100, 280),
  entities: [
    const EntityState(
      id: 'active_ball',
      type: EntityType.ball,
      position: Vec2(100, 280),
      size: Vec2(20, 20),
      movable: true,
      hitboxScale: 1,
    ),
    EntityState(
      id: 'hole',
      type: EntityType.hole,
      position: Vec2(holeX, holeY),
      size: const Vec2(20, 20),
      solid: false,
      hitboxScale: 1,
    ),
    if (stopAfterHole)
      const EntityState(
        id: 'stop_surface',
        type: EntityType.stickySurface,
        position: Vec2(175, 280),
        size: Vec2(20, 120),
        hitboxScale: 1,
      ),
  ],
);
