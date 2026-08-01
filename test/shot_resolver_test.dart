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

    final firstResult = shots.resolve(state, input);
    final secondResult = shots.resolve(state, input);
    final first = firstResult.state;
    final second = secondResult.state;

    expect(first.shotCount, second.shotCount);
    expect(first.score, second.score);
    expect(
      first.entities.map((entity) => entity.position).toList(),
      second.entities.map((entity) => entity.position).toList(),
    );
    expect(firstResult.path, secondResult.path);
    expect(firstResult.events, secondResult.events);
    expect(
      firstResult.moves
          .map((move) => '${move.entityId}:${move.triggerPathIndex}')
          .toList(),
      secondResult.moves
          .map((move) => '${move.entityId}:${move.triggerPathIndex}')
          .toList(),
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

  test('1라운드는 같은 대표 조준에서 무거움 없이는 홀에 도달하지 못한다', () {
    const input = ShotInput(direction: Vec2(1, -1.3), power: 1);
    final normal = shots.resolve(levels[0].createState(0), input);
    final heavyState = traits.transferSelectedTrait(
      traits.selectSource(levels[0].createState(0), 'anvil'),
    );
    final heavy = shots.resolve(
      heavyState,
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );

    expect(heavy.state.phase, GamePhase.success);
    expect(heavy.events, contains('crate_pushed'));
    expect(normal.state.phase, isNot(GamePhase.success));
    expect(normal.events, isNot(contains('hole_entered')));
    expect(
      normal.state.entityById('crate_a')!.position.y,
      greaterThan(heavy.state.entityById('crate_a')!.position.y),
    );
  });

  test('2라운드는 탄성 속성으로 벽 반사 경로를 제공한다', () {
    final state = traits.transferSelectedTrait(
      traits.selectSource(levels[1].createState(1), 'jelly'),
    );
    final aimed = state.copyWith(
      aimDirection: const Vec2(1, -1.5),
      aimPower: 1,
    );
    final result = shots.resolve(
      aimed,
      const ShotInput(
        direction: Vec2(1, -1.5),
        power: 1,
        equippedTrait: TraitType.bouncy,
      ),
    );
    final preview = shots.preview(aimed);

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('bounced'));
    expect(result.events, contains('hole_entered'));
    expect(preview.reflection, isNotNull);
  });

  test('2라운드의 현재 물리 규칙은 일반 공의 벽 반사 대체 풀이도 허용한다', () {
    final result = shots.resolve(
      levels[1].createState(1),
      const ShotInput(direction: Vec2(1, -1.5), power: 1),
    );

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('bounced'));
  });

  test('3라운드는 무거움으로 스위치를 누르고 일반 공은 거절된다', () {
    final normal = shots.resolve(
      levels[2].createState(2),
      const ShotInput(direction: Vec2(1, -1.3), power: 1),
    );
    final heavyState = traits.transferSelectedTrait(
      traits.selectSource(levels[2].createState(2), 'steel'),
    );
    final heavy = shots.resolve(
      heavyState,
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );

    expect(heavy.state.phase, GamePhase.success);
    expect(heavy.events, contains('switch_pressed'));
    expect(heavy.events, contains('hole_entered'));
    expect(normal.events, contains('switch_rejected'));
    expect(normal.state.entityById('gate')!.open, isFalse);
    expect(normal.state.phase, isNot(GamePhase.success));
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

  test('고속 공도 이동 선분 안의 작은 공을 건너뛰지 않는다', () {
    final result = shots.resolve(
      _thinBallState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(result.events, contains('momentum_transfer'));
    expect(result.path.any((point) => point.x > 80 && point.x < 100), isTrue);
    expect(result.path.any((point) => (point.x - 87.57).abs() < 0.2), isTrue);
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
    expect(result.events, isNot(contains('switch_pressed')));
    expect(result.state.entityById('switch')!.pressed, isFalse);
    expect(result.state.entityById('gate')!.open, isFalse);
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
    expect(result.path.last.x, lessThan(106));
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
    expect(result.state.entityById('spent_ball_1')!.position.x, lessThan(106));
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

  test('연쇄된 다음 물체는 앞선 충돌 이후에 움직이기 시작한다', () {
    final result = shots.resolve(
      _momentumState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.9),
    );
    final first = result.moves.firstWhere((move) => move.entityId == 'crate_a');
    final second = result.moves.firstWhere(
      (move) => move.entityId == 'crate_b',
    );

    expect(second.triggerPathIndex, greaterThan(first.triggerPathIndex));
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

  test('밀려난 공도 벽 충돌 판정을 받아 필드 밖으로 나가지 않는다', () {
    final result = shots.resolve(
      _pushedBallWallState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.85),
    );

    final pushedBall = result.state.entityById('spent_ball_1')!;
    final pushedMove = result.moves.firstWhere(
      (move) => move.entityId == 'spent_ball_1',
    );

    expect(result.events, contains('chain_collision_wall'));
    expect(pushedBall.position.x + pushedBall.hitRadius, lessThan(242));
    expect(pushedMove.path.length, greaterThan(3));
    expect(
      pushedMove.path.first,
      _pushedBallWallState().entityById('spent_ball_1')!.position,
    );
    expect(pushedMove.path.last, pushedMove.to);
    for (var index = 1; index < pushedMove.path.length; index++) {
      expect(
        pushedMove.path[index - 1].distanceTo(pushedMove.path[index]),
        lessThan(16),
      );
    }
  });

  test('초기 히트박스 겹침은 t=0에서 분리되어 벽 안에 남지 않는다', () {
    final result = shots.resolve(
      _initialOverlapWallState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.7),
    );
    final wall = result.state.entityById('wall')!;
    final spent = result.state.entityById('spent_ball_1')!;

    expect(result.events, contains('bounced'));
    expect(
      wall.hitBounds.intersectsCircle(spent.position, spent.hitRadius),
      isFalse,
    );
  });

  test('빗겨 맞은 물체는 정면 충돌보다 약하게 움직인다', () {
    final headOn = shots.resolve(
      _singleCrateMomentumState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.9),
    );
    final glancing = shots.resolve(
      _glancingMomentumState(),
      const ShotInput(direction: Vec2(1, -0.18), power: 0.9),
    );

    final headDistance = headOn.state
        .entityById('crate_a')!
        .position
        .distanceTo(
          _singleCrateMomentumState().entityById('crate_a')!.position,
        );
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

  test('점착판은 공을 튕기지 않고 붙잡는다', () {
    final result = shots.resolve(
      _stickyPadState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.55),
    );

    expect(result.events, contains('sticky_attached'));
    expect(result.events, isNot(contains('bounced')));
    expect(result.path.last.x, lessThan(150));
    expect(result.state.entityById('glue')!.visualState, 'stuck');
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

  test('상용 감사: 엔티티 배열 순서를 바꿔도 최초 연쇄 충돌 결과가 같다', () {
    final original = _orderedChainAuditState();
    final reversed = original.copyWith(
      entities: original.entities.reversed.toList(),
    );
    const input = ShotInput(direction: Vec2(1, 0), power: 0.95);

    final first = shots.resolve(original, input);
    final second = shots.resolve(reversed, input);
    final firstEntities = [...first.state.entities]
      ..sort((a, b) => a.id.compareTo(b.id));
    final secondEntities = [...second.state.entities]
      ..sort((a, b) => a.id.compareTo(b.id));

    expect(second.events, first.events);
    expect(
      second.moves.map((move) => '${move.entityId}:${move.triggerPathIndex}'),
      first.moves.map((move) => '${move.entityId}:${move.triggerPathIndex}'),
    );
    expect(second.path, first.path);
    expect(
      secondEntities.map((entity) => '${entity.id}:${entity.position}'),
      firstEntities.map((entity) => '${entity.id}:${entity.position}'),
    );
  });

  test('상용 감사: 다단계 연쇄는 임의의 네 번째 단계에서 끊기지 않는다', () {
    final result = shots.resolve(
      _longChainAuditState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(
      result.events.where((event) => event == 'chain_push').length,
      greaterThanOrEqualTo(4),
    );
    expect(result.moves.map((move) => move.entityId), contains('crate_e'));
    expect(result.state.entityById('crate_e')!.position.x, greaterThan(120));
  });

  test('상용 감사: 연쇄 이동 경로가 충돌 순간에 점멸하지 않고 연속적이다', () {
    final result = shots.resolve(
      _longChainAuditState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    for (final move in result.moves.where((move) => move.path.length > 1)) {
      expect(move.triggerPathIndex, greaterThan(0));
      expect(move.path.first, move.from);
      for (var index = 1; index < move.path.length; index++) {
        expect(
          move.path[index - 1].distanceTo(move.path[index]),
          lessThanOrEqualTo(4.01),
          reason: '${move.entityId} 이동 경로가 한 프레임에 순간이동함',
        );
      }
    }
  });

  test('상용 감사: 동일 샷의 물리 경로가 실행 프레임에 따라 달라지지 않는다', () {
    final state = _longChainAuditState();
    const input = ShotInput(direction: Vec2(1, 0), power: 1);
    final first = shots.resolve(state, input);
    final second = shots.resolve(state, input);

    expect(second.path, first.path);
    expect(second.events, first.events);
    expect(
      second.moves.map((move) => _moveAuditSignature(move)),
      first.moves.map((move) => _moveAuditSignature(move)),
    );
  });

  test('상용 감사: 밀려난 공은 벽의 충돌 경계를 통과하지 않는다', () {
    final state = _pushedBallWallAuditState();
    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final wall = result.state.entityById('wall')!;

    expect(result.events, contains('chain_collision_wall'));
    for (final move in result.moves.where(
      (move) => move.entityId == 'spent_ball_1',
    )) {
      var sawContact = false;
      var passedContact = false;
      for (final point in move.path) {
        final intersects = wall.hitBounds.intersectsCircle(point, 12 * 0.88);
        if (intersects) {
          expect(passedContact, isFalse, reason: '벽 안에서 접촉점이 반복됨: $point');
          sawContact = true;
        } else {
          if (sawContact) {
            passedContact = true;
          }
        }
      }
      expect(sawContact, isTrue, reason: '연쇄 경로에 벽 접촉점이 기록되지 않음');
    }
    expect(
      result.state.entityById('spent_ball_1')!.position.x,
      lessThan(wall.hitBounds.left - 10),
    );
  });
  test('하단 필드 경계는 공을 밖으로 내보내지 않고 반사한다', () {
    const state = GameState(
      levelIndex: 204,
      levelName: '하단 경계 감사',
      ballSpawn: Vec2(180, 500),
      entities: [
        EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(180, 500),
          size: Vec2(24, 24),
          movable: true,
        ),
        EntityState(
          id: 'hole',
          type: EntityType.hole,
          position: Vec2(40, 80),
          size: Vec2(34, 34),
          solid: false,
        ),
      ],
    );
    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(0, 1), power: 1),
    );

    expect(result.events, contains('bounced'));
    expect(result.state.activeBall.position.y, lessThanOrEqualTo(548));
    expect(
      result.state.entities.any(
        (entity) => entity.id.startsWith('field_boundary_'),
      ),
      isFalse,
    );
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

GameState _initialOverlapWallState() {
  return const GameState(
    levelIndex: 87,
    levelName: '초기 겹침 테스트',
    ballSpawn: Vec2(116, 80),
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(116, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(128, 80),
        size: Vec2(24, 120),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 250),
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

GameState _singleCrateMomentumState() {
  return const GameState(
    levelIndex: 88,
    levelName: '정면 밀기 테스트',
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

GameState _thinBallState() {
  return const GameState(
    levelIndex: 90,
    levelName: '고속 충돌 테스트',
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
        size: Vec2(2, 2),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 300),
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

GameState _pushedBallWallState() {
  return const GameState(
    levelIndex: 89,
    levelName: '연쇄 벽 충돌 테스트',
    shotCount: 1,
    ballSpawn: Vec2(40, 80),
    aimPower: 0.85,
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
        position: Vec2(106, 80),
        size: Vec2(24, 24),
        movable: true,
        visualState: 'spent',
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(210, 80),
        size: Vec2(24, 140),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(330, 250),
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

GameState _stickyPadState() {
  return const GameState(
    levelIndex: 90,
    levelName: '점착판 테스트',
    ballSpawn: Vec2(40, 80),
    aimPower: 0.55,
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'glue',
        type: EntityType.stickySurface,
        position: Vec2(130, 80),
        size: Vec2(34, 80),
        traits: {TraitType.sticky},
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

GameState _orderedChainAuditState() {
  return const GameState(
    levelIndex: 201,
    levelName: '배열 순서 충돌 감사',
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
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(92, 80),
        size: Vec2(28, 28),
        movable: true,
      ),
      EntityState(
        id: 'crate_b',
        type: EntityType.crate,
        position: Vec2(132, 80),
        size: Vec2(28, 28),
        movable: true,
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(188, 80),
        size: Vec2(24, 120),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(330, 260),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _longChainAuditState() {
  return const GameState(
    levelIndex: 202,
    levelName: '다단계 연쇄 감사',
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
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(60, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_b',
        type: EntityType.crate,
        position: Vec2(75, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_c',
        type: EntityType.crate,
        position: Vec2(90, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_d',
        type: EntityType.crate,
        position: Vec2(105, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_e',
        type: EntityType.crate,
        position: Vec2(120, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(360, 260),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _pushedBallWallAuditState() {
  return const GameState(
    levelIndex: 203,
    levelName: '연쇄 벽 관통 감사',
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
        position: Vec2(106, 80),
        size: Vec2(24, 24),
        movable: true,
        visualState: 'spent',
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(210, 80),
        size: Vec2(24, 140),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(360, 260),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

String _moveAuditSignature(ShotAnimationMove move) {
  return [
    move.entityId,
    move.triggerPathIndex.toString(),
    move.from.toString(),
    move.to.toString(),
    move.path.join('|'),
  ].join(':');
}
