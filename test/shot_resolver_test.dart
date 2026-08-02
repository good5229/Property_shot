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
    expect(
      firstResult.physicsEvents.map((event) => event.eventId).toList(),
      secondResult.physicsEvents.map((event) => event.eventId).toList(),
    );
  });

  test('물리 이벤트 스트림은 충돌·이동의 인과와 관찰된 결과 속도를 보존한다', () {
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

    final eventIds = result.physicsEvents
        .map((event) => event.eventId)
        .toList();
    expect(eventIds, hasLength(result.impacts.length + result.moves.length));
    expect(eventIds.toSet(), hasLength(eventIds.length));
    expect(
      result.physicsEvents
          .where((event) => event.kind == PhysicsEventKind.impact)
          .map((event) => event.impact),
      everyElement(isNotNull),
    );
    expect(
      result.physicsEvents
          .where((event) => event.kind == PhysicsEventKind.move)
          .map((event) => event.move),
      everyElement(isNotNull),
    );
    expect(
      result.physicsEvents.map((event) => event.pathIndex).toList(),
      [...result.physicsEvents.map((event) => event.pathIndex)]..sort(),
    );
    expect(
      result.physicsEvents
          .where((event) => event.kind == PhysicsEventKind.impact)
          .any((event) => event.resultingVelocity.length > 0),
      isTrue,
    );
    for (final event in result.physicsEvents) {
      final parentId = event.parentEventId;
      if (parentId == null) {
        continue;
      }
      expect(
        eventIds.indexOf(parentId),
        lessThan(eventIds.indexOf(event.eventId)),
      );
    }
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

  test('힘 게이지가 높을수록 상자 이동량이 커진다', () {
    final low = shots.resolve(
      _singleCrateMomentumState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.55),
    );
    final high = shots.resolve(
      _singleCrateMomentumState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final start = _singleCrateMomentumState().entityById('crate_a')!.position;
    final lowDistance = low.state
        .entityById('crate_a')!
        .position
        .distanceTo(start);
    final highDistance = high.state
        .entityById('crate_a')!
        .position
        .distanceTo(start);

    expect(low.events, contains('crate_pushed'));
    expect(high.events, contains('crate_pushed'));
    expect(highDistance, greaterThan(lowDistance));
  });

  test('힘 게이지가 높을수록 움직이는 돌 이동량도 커진다', () {
    final low = shots.resolve(
      _movableWeightPowerState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.55),
    );
    final high = shots.resolve(
      _movableWeightPowerState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final start = _movableWeightPowerState().entityById('weight')!.position;
    final lowDistance = low.state
        .entityById('weight')!
        .position
        .distanceTo(start);
    final highDistance = high.state
        .entityById('weight')!
        .position
        .distanceTo(start);

    expect(low.events, contains('momentum_transfer'));
    expect(high.events, contains('momentum_transfer'));
    expect(highDistance, greaterThan(lowDistance));
  });

  test('충돌 대상의 반발값이 상자 연쇄 이동량에 반영된다', () {
    final low = shots.resolve(
      _restitutionCrateState(0.2),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final high = shots.resolve(
      _restitutionCrateState(0.92),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final start = _restitutionCrateState(0.2).entityById('crate')!.position;

    expect(low.events, contains('crate_pushed'));
    expect(high.events, contains('crate_pushed'));
    expect(
      high.state.entityById('crate')!.position.distanceTo(start),
      greaterThan(low.state.entityById('crate')!.position.distanceTo(start)),
    );
  });

  test('비정사각형 원형 요소의 히트박스는 짧은 축을 따른다', () {
    const entity = EntityState(
      id: '타원형_공',
      type: EntityType.ball,
      position: Vec2(40, 40),
      size: Vec2(30, 18),
    );

    expect(entity.radius, 9);
    expect(entity.hitRadius, 7.92);
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

  test('2라운드는 일반 공의 반사 에너지가 부족해 탄성을 가르친다', () {
    final result = shots.resolve(
      levels[1].createState(1),
      const ShotInput(direction: Vec2(1, -1.5), power: 1),
    );

    expect(result.events, contains('bounced'));
    expect(result.state.phase, isNot(GamePhase.success));
  });

  test('미리보기에서도 상태가 비고체인 벽을 실제 장애물로 본다', () {
    final initial = _wallState(equippedTrait: null);
    final state = initial.copyWith(
      entities: [
        for (final entity in initial.entities)
          entity.type == EntityType.wall
              ? entity.copyWith(solid: false)
              : entity,
      ],
    );
    final preview = shots.preview(
      state.copyWith(aimDirection: const Vec2(1, 0), aimPower: 0.5),
    );

    expect(preview.points.last.x, lessThan(128));
  });

  test('2라운드는 홀 직선 조준 우회를 막고 탄성 반사 풀이를 남긴다', () {
    final result = shots.resolve(
      levels[1].createState(1),
      const ShotInput(direction: Vec2(42, -352), power: 1),
    );

    expect(result.state.phase, isNot(GamePhase.success));
    expect(result.events, contains('bounced'));
  });

  test('홀 가장자리에 걸친 공은 성공하고 충분히 떨어진 공은 실패한다', () {
    final edge = shots.resolve(
      _edgeHoleState(const Vec2(100, 80)),
      const ShotInput(direction: Vec2(1, 0), power: 0.45),
    );
    final miss = shots.resolve(
      _edgeHoleState(const Vec2(100, 30)),
      const ShotInput(direction: Vec2(1, 0), power: 0.45),
    );

    expect(edge.events, contains('hole_entered'));
    expect(edge.state.phase, GamePhase.success);
    expect(miss.events, isNot(contains('hole_entered')));
    expect(miss.state.phase, isNot(GamePhase.success));
  });

  test('홀 포획은 홀 뒤의 벽 충돌보다 먼저 처리된다', () {
    const state = GameState(
      levelIndex: 208,
      levelName: '홀 포획 우선순위 감사',
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
          id: 'hole',
          type: EntityType.hole,
          position: Vec2(132, 80),
          size: Vec2(34, 34),
          solid: false,
        ),
        EntityState(
          id: 'wall_behind_hole',
          type: EntityType.wall,
          position: Vec2(220, 80),
          size: Vec2(24, 120),
        ),
      ],
    );

    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('hole_entered'));
    expect(
      result.state.entityById('spent_ball_1')!.position,
      const Vec2(132, 80),
    );
    expect(result.events, isNot(contains('bounced')));
  });

  test('공이 홀 가장자리에 닿아도 뒤 벽으로 진행하지 않고 포획된다', () {
    const state = GameState(
      levelIndex: 209,
      levelName: '홀 가장자리 포획 감사',
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
          id: 'hole',
          type: EntityType.hole,
          position: Vec2(132, 91),
          size: Vec2(34, 34),
          solid: false,
        ),
        EntityState(
          id: 'wall_behind_hole',
          type: EntityType.wall,
          position: Vec2(220, 80),
          size: Vec2(24, 120),
        ),
      ],
    );

    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('hole_entered'));
    expect(result.events, isNot(contains('bounced')));
  });

  test('실패한 저파워 발사는 힘 부족 원인을 기록한다', () {
    const state = GameState(
      levelIndex: 210,
      levelName: '저파워 피드백 감사',
      ballSpawn: Vec2(40, 80),
      entities: [
        EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(40, 80),
          size: Vec2(24, 24),
          movable: true,
        ),
      ],
    );

    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.2),
    );

    expect(result.state.phase, GamePhase.planning);
    expect(result.events, contains('power_low'));
  });

  test('실패한 고파워 발사는 힘 과다 원인을 기록한다', () {
    const state = GameState(
      levelIndex: 211,
      levelName: '고파워 피드백 감사',
      ballSpawn: Vec2(40, 80),
      entities: [
        EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(40, 80),
          size: Vec2(24, 24),
          movable: true,
        ),
      ],
    );

    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(result.state.phase, GamePhase.planning);
    expect(result.events, contains('power_high'));
  });

  test('직접 충돌은 위치·법선·대상·경로 시점을 기록한다', () {
    const state = GameState(
      levelIndex: 212,
      levelName: '충돌 이벤트 감사',
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
          id: 'wall',
          type: EntityType.wall,
          position: Vec2(120, 80),
          size: Vec2(24, 120),
        ),
      ],
    );

    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );

    expect(result.impacts, isNotEmpty);
    final impact = result.impacts.first;
    expect(impact.entityType, EntityType.wall);
    expect(impact.position.x, lessThan(120));
    expect(impact.normal.x, lessThan(0));
    expect(impact.pathIndex, greaterThan(0));
  });

  test('3라운드는 무거움으로 스위치를 누르고 일반 공은 거절된다', () {
    final normal = shots.resolve(
      levels[2].createState(2),
      const ShotInput(direction: Vec2(1, -1.3), power: 1),
    );
    final heavyWithoutAnchor = shots.resolve(
      traits.transferSelectedTrait(
        traits.selectSource(levels[2].createState(2), 'steel'),
      ),
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );
    final stickyState = traits.transferSelectedTrait(
      traits.selectSource(levels[2].createState(2), 'glue'),
    );
    final sticky = shots.resolve(
      stickyState,
      const ShotInput(
        direction: Vec2(1, -0.54),
        power: 1,
        equippedTrait: TraitType.sticky,
      ),
    );
    final heavyState = traits.transferSelectedTrait(
      traits.selectSource(sticky.state, 'steel'),
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
    expect(heavyWithoutAnchor.events, contains('switch_pressed'));
    expect(heavyWithoutAnchor.state.entityById('gate')!.open, isTrue);
    expect(sticky.events, contains('sticky_attached'));
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
    final wallHit = result.moves.firstWhere(
      (move) => move.visualState == 'wall_hit',
    );
    expect(wallHit.impactNormal, isNotNull);
    expect(wallHit.impactPosition, isNotNull);
    final wallImpact = result.impacts.firstWhere(
      (impact) => impact.entityType == EntityType.wall,
    );
    expect(wallHit.impactPosition, wallImpact.position);
  });

  test('벽은 상태가 비고체여도 물리 장애물로 반사된다', () {
    final initial = _wallState(equippedTrait: null);
    final state = initial.copyWith(
      entities: [
        for (final entity in initial.entities)
          entity.type == EntityType.wall
              ? entity.copyWith(solid: false)
              : entity,
      ],
    );
    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.45),
    );

    expect(result.events, contains('bounced'));
    expect(result.events, isNot(contains('blocked_by_wall')));
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

  test('상자에서 젤리로 이어지는 혼합 재질 연쇄가 순서대로 재생된다', () {
    final result = shots.resolve(
      _mixedMaterialChainState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final crateMove = result.moves.firstWhere(
      (move) => move.entityId == 'crate_a',
    );
    final jellyImpact = result.moves.firstWhere(
      (move) => move.entityId == 'jelly',
    );

    expect(result.events, contains('chain_collision_bumper'));
    expect(result.events, contains('jelly_bounced'));
    expect(
      jellyImpact.triggerPathIndex,
      greaterThan(crateMove.triggerPathIndex),
    );
    expect(crateMove.path.length, greaterThan(2));
    for (final move in result.moves.where((move) => move.path.length > 1)) {
      for (var index = 1; index < move.path.length; index++) {
        expect(move.path[index - 1].distanceTo(move.path[index]), lessThan(16));
      }
    }
  });

  test('돌에서 상자를 거쳐 벽까지 충돌 이벤트가 순서대로 계산된다', () {
    final result = shots.resolve(
      _weightCrateWallChainState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    final weightMove = result.moves.firstWhere(
      (move) => move.entityId == 'weight',
    );
    final crateMove = result.moves.firstWhere(
      (move) => move.entityId == 'crate_a',
    );
    expect(result.events, contains('chain_collision_crate'));
    expect(result.events, contains('chain_collision_wall'));
    expect(
      result.events.indexOf('chain_collision_wall'),
      greaterThan(result.events.indexOf('chain_collision_crate')),
    );
    expect(
      crateMove.triggerPathIndex,
      greaterThan(weightMove.triggerPathIndex),
    );
    expect(weightMove.to.x, greaterThan(110));
    expect(
      result.moves
          .where((move) => move.path.length > 1)
          .every(
            (move) => move.path.every(
              (point) => point.x >= 0 && point.x <= logicalSize.x,
            ),
          ),
      isTrue,
    );
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

  test('동일 질량 공의 정면 충돌은 발사 공을 뒤로 튕기지 않는다', () {
    final result = shots.resolve(
      _equalMassBallState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final pushed = result.state.entityById('spent_ball_1')!;
    final launched = result.state.entityById('spent_ball_2')!;

    expect(result.events, contains('equal_mass_exchange'));
    expect(pushed.position.x, greaterThan(104));
    expect(launched.position.x, greaterThan(70));
    expect(launched.position.x, lessThan(104));
  });

  test('일반 공의 상자 연쇄는 무게 스위치를 우회하지 못한다', () {
    final result = shots.resolve(
      _chainedSwitchState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(result.events, contains('switch_rejected'));
    expect(result.events, isNot(contains('switch_pressed')));
    expect(result.state.entityById('gate')!.open, isFalse);
  });

  test('무거운 충격이 전달된 상자 연쇄는 스위치를 누를 수 있다', () {
    final result = shots.resolve(
      _chainedSwitchState(heavy: true),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );

    expect(result.events, contains('switch_pressed'));
    expect(result.state.entityById('gate')!.open, isTrue);
  });

  test('무거운 상자 연쇄는 점착 없이도 스위치를 누를 수 있다', () {
    final result = shots.resolve(
      _chainedSwitchState(heavy: true),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );

    expect(result.events, contains('switch_pressed'));
    expect(result.events, isNot(contains('switch_rejected_sticky')));
    expect(result.state.entityById('gate')!.open, isTrue);
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
    expect(pushedMove.impactNormal, isNotNull);
    expect(pushedMove.impactNormal!.x, lessThan(0));
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

  test('연쇄로 밀린 상자도 벽에서 분리되고 반사된 경로를 남긴다', () {
    final initial = _pushedCrateWallState();
    final result = shots.resolve(
      initial,
      const ShotInput(direction: Vec2(1, 0), power: 0.95),
    );
    final crate = result.state.entityById('crate_a')!;
    final move = result.moves.firstWhere((item) => item.entityId == 'crate_a');
    final wall = result.state.entityById('wall')!;

    expect(result.events, contains('chain_collision_wall'));
    expect(
      wall.hitBounds.intersectsCircle(crate.position, crate.size.x / 2),
      isFalse,
    );
    expect(move.path.length, greaterThan(3));
    expect(move.path.any((point) => point.x < move.path.first.x), isTrue);
  });

  test('벽 모서리 대각선 충돌도 공을 필드 안에 남긴다', () {
    const directions = [
      Vec2(1, 0.24),
      Vec2(-1, 0.24),
      Vec2(1, -0.24),
      Vec2(-1, -0.24),
    ];

    for (final direction in directions) {
      final result = shots.resolve(
        levels[0].createState(0),
        ShotInput(direction: direction, power: 1),
      );
      for (final entity in result.state.entities.where(
        (entity) => entity.type == EntityType.ball,
      )) {
        expect(entity.position.x - entity.hitRadius, greaterThanOrEqualTo(0));
        expect(
          entity.position.x + entity.hitRadius,
          lessThanOrEqualTo(logicalSize.x),
        );
        expect(entity.position.y - entity.hitRadius, greaterThanOrEqualTo(0));
        expect(
          entity.position.y + entity.hitRadius,
          lessThanOrEqualTo(logicalSize.y),
        );
      }
    }
  });

  test('정확히 겹친 벽 모서리는 한쪽 면이 아닌 대각선 법선을 사용한다', () {
    final result = shots.resolve(
      _exactCornerOverlapState(),
      const ShotInput(direction: Vec2(1, 1), power: 0.7),
    );
    final wallHit = result.moves.firstWhere(
      (move) => move.visualState == 'wall_hit',
    );
    final normal = wallHit.impactNormal!;

    expect(normal.x, closeTo(-0.707, 0.03));
    expect(normal.y, closeTo(-0.707, 0.03));
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
    expect(result.state.entityById('spent_ball_1')!.movable, isFalse);
    expect(result.state.entityById('spent_ball_1')!.visualState, 'stuck');
  });

  test('연쇄로 이동한 물체도 점착판에 닿으면 고정된다', () {
    final result = shots.resolve(
      _chainedStickyState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final crate = result.state.entityById('crate_a')!;

    expect(result.events, contains('chain_collision_stickySurface'));
    expect(crate.visualState, 'stuck');
    expect(crate.movable, isFalse);
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
    final selected = traits.selectSource(
      levels[0].createState(0, productRules: true, copyCoreCount: 1),
      'anvil',
    );
    final copied = traits.copySelectedTrait(selected);

    expect(copied.equippedTrait, TraitType.heavy);
    expect(copied.entityById('anvil')!.traits, contains(TraitType.heavy));
    expect(copied.activeBall.traits, contains(TraitType.heavy));
    expect(copied.copyCharges, 0);
  });

  test('복사권을 모두 쓰면 추가 복사가 되지 않는다', () {
    final selected = traits.selectSource(
      levels[0].createState(0, productRules: true, copyCoreCount: 1),
      'anvil',
    );
    final copied = traits.copySelectedTrait(selected);
    final selectedAgain = traits.selectSource(copied, 'anvil');
    final exhausted = traits.copySelectedTrait(selectedAgain);

    expect(exhausted.copyCharges, 0);
    expect(exhausted.activeBall.traits, contains(TraitType.heavy));
    expect(exhausted.message, contains('모두 사용했습니다'));
  });

  test('복사하지 못한 선택에서는 복사권이 줄지 않는다', () {
    final state = levels[0].createState(0);
    final result = traits.copySelectedTrait(state);

    expect(result.copyCharges, state.copyCharges);
    expect(result.message, contains('먼저 속성 물체를 선택하세요'));
  });

  test('스테이지 시작에는 복제 코어 없이 복사권이 없다', () {
    expect(levels[0].createState(0).copyCharges, 0);
    expect(levels[1].createState(1).copyCharges, 0);
    expect(levels[2].createState(2).copyCharges, 0);
  });

  test('제품 규칙의 첫 챕터는 복제 코어 없이 시작한다', () {
    for (var index = 0; index < levels.length; index++) {
      final state = levels[index].createState(index, productRules: true);
      expect(state.copyCharges, 0);
      expect(state.copyCoreCount, 0);
      expect(state.copyCoreRewarded, isFalse);
    }
    expect(levels[2].copyCoreReward, 1);
  });

  test('복제 코어를 사용하면 원본은 유지되고 코어가 줄어든다', () {
    final state = levels[0].createState(
      0,
      productRules: true,
      copyCoreCount: 1,
    );
    final selected = traits.selectSource(state, 'anvil');
    final copied = traits.copySelectedTrait(selected);

    expect(copied.entityById('anvil')!.traits, contains(TraitType.heavy));
    expect(copied.activeBall.traits, contains(TraitType.heavy));
    expect(copied.copyCharges, 0);
    expect(copied.copyCoreCount, 0);
    expect(copied.message, contains('복제 코어 0개 남음'));
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
    expect(rewound.copyCharges, state.copyCharges);
  });

  test('복사 후 발사한 샷을 되감으면 발사 전 코어 상태를 유지한다', () {
    final copied = traits.copySelectedTrait(
      traits.selectSource(
        levels[0].createState(0, productRules: true, copyCoreCount: 1),
        'anvil',
      ),
    );
    final result = shots.resolve(
      copied,
      const ShotInput(direction: Vec2(1, 0), power: 0.5),
    );

    expect(result.state.copyCharges, 0);
    final rewound = shots.rewind(result.state);
    expect(rewound.copyCharges, copied.copyCharges);
    expect(rewound.copyCoreCount, copied.copyCoreCount);
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

  test('속성 없는 과거 공도 홀에 닿으면 클리어된다', () {
    final result = shots.resolve(
      _spentBallHoleWithContractState(),
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('existing_ball_hole_entered'));
  });

  test('움직이지 않는 상자는 crate_pushed로 기록되지 않는다', () {
    final result = shots.resolve(
      _fixedCrateContractState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(result.events, isNot(contains('crate_pushed')));
    expect(result.events, contains('crate_blocked'));
    expect(result.state.phase, isNot(GamePhase.success));
  });

  test('점착 공은 젤리와 돌에도 첫 충돌 후 붙는다', () {
    for (final targetId in ['jelly', 'weight']) {
      final result = shots.resolve(
        _stickyMaterialState(targetId),
        const ShotInput(
          direction: Vec2(1, 0),
          power: 0.8,
          equippedTrait: TraitType.sticky,
        ),
      );

      expect(result.events, contains('sticky_attached'));
      expect(result.state.activeBall.visualState, 'ready');
      expect(
        result.state.entities.any(
          (entity) =>
              entity.id == 'spent_ball_1' && entity.visualState == 'stuck',
        ),
        isTrue,
      );
    }
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

  test('상용 감사: 연쇄 충돌도 이전 공과 벽의 접촉 이벤트를 기록한다', () {
    final result = shots.resolve(
      _pushedBallWallAuditState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(
      result.impacts.map((impact) => impact.entityType),
      contains(EntityType.ball),
    );
    expect(
      result.impacts.map((impact) => impact.entityType),
      contains(EntityType.wall),
    );
    expect(result.impacts.every((impact) => impact.pathIndex >= 0), isTrue);
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

  test('상용 감사: 연쇄 공이 홀에 먼저 들어가면 뒤 벽과 충돌하지 않는다', () {
    final result = shots.resolve(
      _chainedBallHoleWallState(),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(result.events, contains('chain_hole_entered'));
    expect(result.events, contains('existing_ball_hole_entered'));
    expect(result.events, isNot(contains('chain_collision_wall')));
    final holeImpact = result.impacts.firstWhere(
      (impact) => impact.entityType == EntityType.hole,
    );
    expect(holeImpact.entityId, 'hole');
    expect(holeImpact.sourceEntityId, 'spent_ball_1');
    expect(
      result.impacts.any(
        (impact) =>
            impact.entityType == EntityType.wall &&
            impact.entityId == 'wall_behind_hole',
      ),
      isFalse,
    );
    expect(
      result.state.entityById('spent_ball_1')!.position,
      const Vec2(164, 80),
    );
    final capturedMove = result.moves.firstWhere(
      (move) =>
          move.entityId == 'spent_ball_1' &&
          move.visualState == 'hole_captured',
    );
    expect(capturedMove.to, const Vec2(164, 80));
  });

  test('상용 감사: 밀려난 공은 벽의 충돌 경계를 통과하지 않는다', () {
    final state = _pushedBallWallAuditState();
    final result = shots.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final wall = result.state.entityById('wall')!;

    expect(result.events, contains('chain_collision_wall'));
    var sawAnyContact = false;
    for (final move in result.moves.where(
      (move) => move.entityId == 'spent_ball_1',
    )) {
      var sawContact = false;
      var passedContact = false;
      for (final point in move.path) {
        final intersects = wall.hitBounds.intersectsCircle(
          point,
          12 * 0.88 + 2,
        );
        if (intersects) {
          expect(passedContact, isFalse, reason: '벽 안에서 접촉점이 반복됨: $point');
          sawContact = true;
        } else {
          if (sawContact) {
            passedContact = true;
          }
        }
      }
      sawAnyContact = sawAnyContact || sawContact;
    }
    expect(sawAnyContact, isTrue, reason: '연쇄 경로에 벽 접촉점이 기록되지 않음');
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

GameState _exactCornerOverlapState() {
  return const GameState(
    levelIndex: 207,
    levelName: '정확한 벽 모서리 테스트',
    ballSpawn: Vec2(40, 40),
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 40),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(52, 52),
        size: Vec2(24, 24),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 280),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _chainedSwitchState({bool heavy = false}) {
  final ballTraits = heavy ? {TraitType.heavy} : <TraitType>{};
  return GameState(
    levelIndex: 100,
    levelName: '연쇄 스위치 조건 테스트',
    ballSpawn: const Vec2(40, 80),
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: const Vec2(40, 80),
        size: const Vec2(24, 24),
        traits: ballTraits,
        movable: true,
      ),
      const EntityState(
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(92, 80),
        size: Vec2(28, 28),
        movable: true,
      ),
      const EntityState(
        id: 'switch',
        type: EntityType.switchPad,
        position: Vec2(154, 80),
        size: Vec2(48, 24),
      ),
      const EntityState(
        id: 'gate',
        type: EntityType.gate,
        position: Vec2(224, 80),
        size: Vec2(24, 72),
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 300),
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

GameState _mixedMaterialChainState() {
  return const GameState(
    levelIndex: 204,
    levelName: '혼합 재질 연쇄 테스트',
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
        id: 'jelly',
        type: EntityType.bumper,
        position: Vec2(142, 80),
        size: Vec2(36, 36),
        restitution: 0.9,
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(220, 80),
        size: Vec2(24, 140),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(330, 280),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _weightCrateWallChainState() {
  return const GameState(
    levelIndex: 205,
    levelName: '돌 상자 벽 연쇄 감사',
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
        id: 'weight',
        type: EntityType.weight,
        position: Vec2(86, 80),
        size: Vec2(32, 32),
        movable: true,
      ),
      EntityState(
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(124, 80),
        size: Vec2(28, 28),
        movable: true,
      ),
      EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(180, 80),
        size: Vec2(24, 140),
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(350, 280),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _movableWeightPowerState() {
  return const GameState(
    levelIndex: 91,
    levelName: '돌 힘 테스트',
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
        id: 'weight',
        type: EntityType.weight,
        position: Vec2(92, 80),
        size: Vec2(32, 32),
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

GameState _restitutionCrateState(double restitution) {
  return GameState(
    levelIndex: 93,
    levelName: '재질 반발 테스트',
    ballSpawn: const Vec2(40, 80),
    aimPower: 1,
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'crate',
        type: EntityType.crate,
        position: const Vec2(92, 80),
        size: const Vec2(28, 28),
        movable: true,
        restitution: restitution,
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 300),
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

GameState _edgeHoleState(Vec2 holePosition) {
  return GameState(
    levelIndex: 91,
    levelName: '홀 경계 테스트',
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
        id: 'hole',
        type: EntityType.hole,
        position: holePosition,
        size: const Vec2(34, 34),
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

GameState _equalMassBallState() {
  return const GameState(
    levelIndex: 93,
    levelName: '동일 질량 공 충돌 테스트',
    shotCount: 1,
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
        position: Vec2(104, 80),
        size: Vec2(24, 24),
        movable: true,
        visualState: 'spent',
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(330, 300),
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

GameState _chainedBallHoleWallState() {
  return const GameState(
    levelIndex: 211,
    levelName: '연쇄 홀 포획 종결 테스트',
    shotCount: 1,
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
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(164, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
      EntityState(
        id: 'wall_behind_hole',
        type: EntityType.wall,
        position: Vec2(230, 80),
        size: Vec2(24, 140),
      ),
    ],
  );
}

GameState _pushedCrateWallState() {
  return const GameState(
    levelIndex: 90,
    levelName: '연쇄 상자 벽 충돌 테스트',
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
        position: Vec2(168, 80),
        size: Vec2(38, 38),
        movable: true,
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

GameState _chainedStickyState() {
  return const GameState(
    levelIndex: 101,
    levelName: '연쇄 점착 고정 테스트',
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
        id: 'glue',
        type: EntityType.stickySurface,
        position: Vec2(154, 80),
        size: Vec2(42, 42),
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

GameState _spentBallHoleWithContractState() {
  return const GameState(
    levelIndex: 205,
    levelName: '과거 공 계약 감사',
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
        position: Vec2(100, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

GameState _fixedCrateContractState() {
  return const GameState(
    levelIndex: 206,
    levelName: '고정 상자 계약 감사',
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

GameState _stickyMaterialState(String targetId) {
  final target = targetId == 'jelly'
      ? const EntityState(
          id: 'jelly',
          type: EntityType.bumper,
          position: Vec2(92, 80),
          size: Vec2(34, 34),
        )
      : const EntityState(
          id: 'weight',
          type: EntityType.weight,
          position: Vec2(92, 80),
          size: Vec2(34, 34),
        );
  return GameState(
    levelIndex: 207,
    levelName: '점착 재질 감사',
    ballSpawn: const Vec2(40, 80),
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      target,
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(260, 260),
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
