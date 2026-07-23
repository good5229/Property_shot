import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  const shots = ShotResolver();
  const traits = TraitResolver();

  test('같은 초기 상태와 입력은 같은 최종 상태를 만든다', () {
    final state = traits.transferSelectedTrait(
      traits.selectSource(levels[0].createState(0), 'anvil'),
    );
    const input = ShotInput(
      direction: Vec2(1, -1),
      power: 0.72,
      equippedTrait: TraitType.heavy,
    );

    final first = shots.resolve(state, input).state;
    final second = shots.resolve(state, input).state;

    expect(first.shotCount, second.shotCount);
    expect(first.score, second.score);
    expect(
      first.entities.map((entity) => entity.position).toList(),
      second.entities.map((entity) => entity.position).toList(),
    );
  });

  test('무거운 공은 상자를 밀 수 있다', () {
    final state = traits.transferSelectedTrait(
      traits.selectSource(levels[0].createState(0), 'anvil'),
    );
    final result = shots.resolve(
      state.copyWith(aimDirection: const Vec2(1, -1.3), aimPower: 0.8),
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 0.8,
        equippedTrait: TraitType.heavy,
      ),
    );
    final crate = result.state.entityById('crate_a')!;

    expect(result.events, contains('crate_pushed'));
    expect(crate.visualState, 'pushed');
  });

  test('무거움 튜토리얼은 상자가 충분히 밀리도록 구성되어 있다', () {
    final state = traits.transferSelectedTrait(
      traits.selectSource(levels[0].createState(0), 'anvil'),
    );
    final result = shots.resolve(
      state,
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );
    final before = state.entityById('crate_a')!.position;
    final after = result.state.entityById('crate_a')!.position;

    expect(after.distanceTo(before), greaterThan(70));
    expect(result.moves.any((move) => move.entityId == 'crate_a'), isTrue);
  });

  test('공 이동은 초반이 빠르고 후반으로 갈수록 느려진다', () {
    final result = shots.resolve(
      _openFieldState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.95),
    );
    final early = result.path[1].distanceTo(result.path[0]);
    final late = result.path.last.distanceTo(
      result.path[result.path.length - 2],
    );

    expect(early, greaterThan(late));
  });

  test('연쇄 이동 애니메이션은 충돌 지점 이후에 시작된다', () {
    final state = traits.transferSelectedTrait(
      traits.selectSource(levels[0].createState(0), 'anvil'),
    );
    final result = shots.resolve(
      state,
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );
    final move = result.moves.firstWhere((move) => move.entityId == 'crate_a');

    expect(move.triggerPathIndex, greaterThan(0));
    expect(
      result.path[move.triggerPathIndex].distanceTo(move.from),
      lessThan(40),
    );
  });

  test('일반 공은 무게 스위치를 누르지 못한다', () {
    final state = _singleSwitchState(equippedTrait: null);
    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.4),
    );

    expect(result.events, contains('switch_rejected'));
    expect(result.state.entityById('switch')!.pressed, isFalse);
  });

  test('무거운 공은 무게 스위치를 누르고 문을 연다', () {
    final state = _singleSwitchState(equippedTrait: TraitType.heavy);
    final result = shots.resolve(
      state,
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.4,
        equippedTrait: TraitType.heavy,
      ),
    );

    expect(result.events, contains('switch_pressed'));
    expect(result.state.entityById('switch')!.pressed, isTrue);
    expect(result.state.entityById('gate')!.open, isTrue);
  });

  test('탄성 공은 벽에서 반사된다', () {
    final state = _wallState(equippedTrait: TraitType.bouncy);
    final result = shots.resolve(
      state,
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.45,
        equippedTrait: TraitType.bouncy,
      ),
    );

    expect(result.events, contains('bounced'));
    expect(result.path.last.x, lessThan(220));
  });

  test('일반 공도 벽에 맞으면 반사되고 벽은 움직이지 않는다', () {
    final state = _wallState(equippedTrait: null);
    final beforeWall = state.entityById('wall')!.position;
    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.45),
    );

    expect(result.events, contains('bounced'));
    expect(result.state.entityById('wall')!.position, beforeWall);
  });

  test('물체의 아래 면을 맞으면 아래쪽으로 반사된다', () {
    final result = shots.resolve(
      _horizontalWallState(),
      const ShotInput(direction: Vec2(1, -1), power: 0.7),
    );

    expect(result.events, contains('bounced'));
    expect(result.path.last.y, greaterThan(120));
  });

  test('움직이는 물체는 충격을 받아 다른 물체를 밀 수 있다', () {
    final result = shots.resolve(
      _momentumState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.9),
    );

    expect(result.events, contains('chain_push'));
    expect(result.state.entityById('crate_a')!.position.x, greaterThan(92));
    expect(result.state.entityById('crate_b')!.position.x, greaterThan(128));
  });

  test('무거운 공은 일반 공을 크게 밀고 자신의 진행을 크게 잃지 않는다', () {
    final result = shots.resolve(
      _heavyBallVsNormalBallState(),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.85,
        equippedTrait: TraitType.heavy,
      ),
    );

    final normalBall = result.state.entityById('spent_ball_1')!;
    final launched = result.state.entityById('spent_ball_2')!;

    expect(normalBall.position.x, greaterThan(168));
    expect(launched.position.x, greaterThan(112));
    expect(result.events, contains('momentum_transfer'));
  });

  test('빗겨 맞은 물체는 정면 충돌보다 약하게 움직인다', () {
    final headOn = shots.resolve(
      _momentumState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.9),
    );
    final glancing = shots.resolve(
      _glancingMomentumState(),
      const ShotInput(direction: Vec2(1, -0.18), power: 0.9),
    );

    final headDistance = headOn.state
        .entityById('crate_a')!
        .position
        .distanceTo(_momentumState().entityById('crate_a')!.position);
    final glanceDistance = glancing.state
        .entityById('crate_a')!
        .position
        .distanceTo(_glancingMomentumState().entityById('crate_a')!.position);

    expect(glanceDistance, lessThan(headDistance));
  });

  test('점착 공은 첫 유효 표면에 붙는다', () {
    final state = _wallState(equippedTrait: TraitType.sticky);
    final result = shots.resolve(
      state,
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.45,
        equippedTrait: TraitType.sticky,
      ),
    );

    expect(result.events, contains('sticky_attached'));
  });

  test('속성을 옮기면 원래 물체에서 제거된다', () {
    final state = traits.transferSelectedTrait(
      traits.selectSource(levels[2].createState(2), 'glue'),
    );

    expect(state.equippedTrait, TraitType.sticky);
    expect(state.entityById('glue')!.traits, isEmpty);
    expect(state.activeBall.traits, contains(TraitType.sticky));
  });

  test('속성을 복사하면 원래 물체의 속성은 유지된다', () {
    final selected = traits.selectSource(levels[0].createState(0), 'anvil');
    final copied = traits.copySelectedTrait(selected);

    expect(copied.equippedTrait, TraitType.heavy);
    expect(copied.entityById('anvil')!.traits, contains(TraitType.heavy));
    expect(copied.activeBall.traits, contains(TraitType.heavy));
  });

  test('되감기는 발사 전 상태를 복원한다', () {
    final state = traits.transferSelectedTrait(
      traits.selectSource(levels[0].createState(0), 'anvil'),
    );
    final result = shots.resolve(
      state,
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 0.8,
        equippedTrait: TraitType.heavy,
      ),
    );
    final rewound = shots.rewind(result.state);

    expect(rewound.shotCount, state.shotCount);
    expect(
      rewound.entityById('crate_a')!.position,
      state.entityById('crate_a')!.position,
    );
  });

  test('문은 열리기 전까지 공을 막는다', () {
    final blocked = shots.resolve(
      _gateLineState(open: false),
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );
    final open = shots.resolve(
      _gateLineState(open: true),
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );

    expect(blocked.events, contains('bounced'));
    expect(blocked.state.entityById('gate')!.open, isFalse);
    expect(open.state.phase, GamePhase.success);
  });

  test('홀 판정은 애니메이션 프레임에 의존하지 않는다', () {
    final state = _gateLineState(open: true);
    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('hole_entered'));
  });

  test('이전 공이 밀려 홀에 닿아도 클리어된다', () {
    final result = shots.resolve(
      _spentBallHoleState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('existing_ball_hole_entered'));
  });
}

GameState _singleSwitchState({TraitType? equippedTrait}) {
  return GameState(
    levelIndex: 99,
    levelName: '스위치 테스트',
    ballSpawn: const Vec2(40, 80),
    equippedTrait: equippedTrait,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: const Vec2(40, 80),
        size: const Vec2(24, 24),
        traits: equippedTrait == null ? const {} : {equippedTrait},
        movable: true,
      ),
      const EntityState(
        id: 'switch',
        type: EntityType.switchPad,
        position: Vec2(104, 80),
        size: Vec2(52, 26),
        solid: true,
      ),
      const EntityState(
        id: 'gate',
        type: EntityType.gate,
        position: Vec2(184, 80),
        size: Vec2(24, 72),
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(260, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _wallState({required TraitType? equippedTrait}) {
  return GameState(
    levelIndex: 98,
    levelName: '벽 테스트',
    ballSpawn: const Vec2(40, 80),
    equippedTrait: equippedTrait,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: const Vec2(40, 80),
        size: const Vec2(24, 24),
        traits: equippedTrait == null ? const {} : {equippedTrait},
        movable: true,
      ),
      const EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(128, 80),
        size: Vec2(24, 120),
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(280, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _momentumState() {
  return const GameState(
    levelIndex: 96,
    levelName: '운동량 테스트',
    ballSpawn: Vec2(40, 80),
    aimPower: 0.9,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(92, 80),
        size: Vec2(28, 28),
        movable: true,
      ),
      EntityState(
        id: 'crate_b',
        type: EntityType.crate,
        position: Vec2(128, 80),
        size: Vec2(28, 28),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(260, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _openFieldState() {
  return const GameState(
    levelIndex: 92,
    levelName: '감속 테스트',
    ballSpawn: Vec2(40, 80),
    aimPower: 0.95,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(340, 320),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _heavyBallVsNormalBallState() {
  return const GameState(
    levelIndex: 91,
    levelName: '질량 충돌 테스트',
    shotCount: 1,
    ballSpawn: Vec2(40, 80),
    equippedTrait: TraitType.heavy,
    aimPower: 0.85,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        traits: {TraitType.heavy},
        movable: true,
      ),
      EntityState(
        id: 'spent_ball_1',
        type: EntityType.ball,
        position: Vec2(104, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(330, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _glancingMomentumState() {
  return const GameState(
    levelIndex: 94,
    levelName: '빗겨치기 테스트',
    ballSpawn: Vec2(40, 92),
    aimPower: 0.9,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 92),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(92, 80),
        size: Vec2(28, 28),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(260, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _horizontalWallState() {
  return const GameState(
    levelIndex: 95,
    levelName: '반사각 테스트',
    ballSpawn: Vec2(80, 130),
    aimPower: 0.7,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(80, 130),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(128, 82),
        size: Vec2(130, 24),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(280, 220),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _gateLineState({required bool open}) {
  return GameState(
    levelIndex: 97,
    levelName: '문 테스트',
    ballSpawn: const Vec2(40, 80),
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'gate',
        type: EntityType.gate,
        position: const Vec2(142, 80),
        size: const Vec2(24, 80),
        open: open,
        solid: !open,
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(250, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _spentBallHoleState() {
  return const GameState(
    levelIndex: 93,
    levelName: '이전 공 홀 테스트',
    ballSpawn: Vec2(40, 80),
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'spent_ball_1',
        type: EntityType.ball,
        position: Vec2(100, 80),
        size: Vec2(24, 24),
        movable: true,
        visualState: 'spent',
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(158, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}
