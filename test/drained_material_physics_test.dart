import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const shots = ShotResolver();
  const input = ShotInput(direction: Vec2(1, 0), power: 1);

  test('활성 공은 탄성 보유 젤리에서만 젤리 반사를 받는다', () {
    final elastic = _singleSurfaceState(
      _source(EntityType.bumper, TraitType.bouncy),
    );
    final drained = _singleSurfaceState(
      _source(
        EntityType.bumper,
        TraitType.bouncy,
      ).copyWith(traits: const {}, movable: true, visualState: 'drained'),
    );

    final elasticResult = shots.resolve(elastic, input);
    final drainedResult = shots.resolve(drained, input);

    expect(elasticResult.events, contains('jelly_bounced'));
    expect(drainedResult.events, isNot(contains('jelly_bounced')));
    expect(
      drainedResult.state.entityById('surface')!.position,
      isNot(drained.entityById('surface')!.position),
    );
  });

  test('활성 공은 점착 보유 표면에서만 멈춘다', () {
    final sticky = _singleSurfaceState(
      _source(EntityType.stickySurface, TraitType.sticky),
    );
    final drained = _singleSurfaceState(
      _source(
        EntityType.stickySurface,
        TraitType.sticky,
      ).copyWith(traits: const {}, movable: true, visualState: 'drained'),
    );

    final stickyResult = shots.resolve(sticky, input);
    final drainedResult = shots.resolve(drained, input);

    expect(stickyResult.events, contains('sticky_attached'));
    expect(drainedResult.events, isNot(contains('sticky_attached')));
    expect(
      drainedResult.state.entityById('surface')!.position,
      isNot(drained.entityById('surface')!.position),
    );
  });

  test('연쇄 이동체도 탄성 보유 젤리에서만 반사된다', () {
    final elastic = _chainState(_source(EntityType.bumper, TraitType.bouncy));
    final drained = _chainState(
      _source(
        EntityType.bumper,
        TraitType.bouncy,
      ).copyWith(traits: const {}, movable: true, visualState: 'drained'),
    );

    final elasticResult = shots.resolve(elastic, input);
    final drainedResult = shots.resolve(drained, input);

    expect(elasticResult.events, contains('jelly_bounced'));
    expect(drainedResult.events, isNot(contains('jelly_bounced')));
    expect(
      drainedResult.state.entityById('surface')!.position,
      isNot(drained.entityById('surface')!.position),
    );
  });

  test('연쇄 이동체도 점착 보유 표면에서만 고정된다', () {
    final sticky = _chainState(
      _source(EntityType.stickySurface, TraitType.sticky),
    );
    final drained = _chainState(
      _source(
        EntityType.stickySurface,
        TraitType.sticky,
      ).copyWith(traits: const {}, movable: true, visualState: 'drained'),
    );

    final stickyResult = shots.resolve(sticky, input);
    final drainedResult = shots.resolve(drained, input);

    expect(stickyResult.events, contains('chain_collision_stickySurface'));
    expect(stickyResult.state.entityById('crate')!.movable, isFalse);
    expect(drainedResult.events, isNot(contains('sticky_attached')));
    expect(drainedResult.state.entityById('crate')!.movable, isTrue);
    expect(
      drainedResult.state.entityById('surface')!.position,
      isNot(drained.entityById('surface')!.position),
    );
  });
}

EntityState _source(EntityType type, TraitType trait) {
  return EntityState(
    id: 'surface',
    type: type,
    position: const Vec2(170, 280),
    size: const Vec2(50, 50),
    traits: {trait},
    solid: true,
    movable: false,
  );
}

GameState _singleSurfaceState(EntityState surface) {
  return GameState(
    levelIndex: 4,
    levelName: '재질 테스트',
    ballSpawn: const Vec2(50, 280),
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(50, 280),
        size: Vec2(24, 24),
        movable: true,
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 60),
        size: Vec2(40, 40),
        solid: false,
      ),
      surface,
    ],
  );
}

GameState _chainState(EntityState surface) {
  return GameState(
    levelIndex: 4,
    levelName: '연쇄 재질 테스트',
    ballSpawn: const Vec2(40, 280),
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 280),
        size: Vec2(24, 24),
        movable: true,
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 60),
        size: Vec2(40, 40),
        solid: false,
      ),
      const EntityState(
        id: 'crate',
        type: EntityType.crate,
        position: Vec2(105, 280),
        size: Vec2(38, 38),
        movable: true,
      ),
      surface,
    ],
  );
}
