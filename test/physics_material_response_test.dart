import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();

  test('벽은 고정된 채 충돌 법선 반대 방향으로 공을 반사한다', () {
    final state = _singleTargetState(
      EntityType.wall,
      targetSize: const Vec2(24, 120),
    );
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.95),
    );
    final impact = _impactOn(result, 'target');

    expect(impact.normal.x, closeTo(-1, 0.08));
    expect(impact.resultingVelocity.x, lessThan(0));
    expect(
      result.state.entityById('target')!.position,
      state.entityById('target')!.position,
    );
    expect(result.state.entityById('target')!.movable, isFalse);
  });

  test('젤리는 충돌 법선 방향으로 공을 다시 밀어낸다', () {
    final result = resolver.resolve(
      _singleTargetState(EntityType.bumper, targetSize: const Vec2(58, 42)),
      const ShotInput(direction: Vec2(1, 0), power: 0.95),
    );
    final impact = _impactOn(result, 'target');

    expect(result.events, contains('jelly_bounced'));
    expect(impact.impulse, greaterThan(0));
    expect(impact.resultingVelocity.dot(impact.normal), greaterThan(0));
  });

  test('점착판은 반사하지 않고 공을 정지 상태로 만든다', () {
    final result = resolver.resolve(
      _singleTargetState(
        EntityType.stickySurface,
        targetSize: const Vec2(50, 86),
      ),
      const ShotInput(direction: Vec2(1, 0), power: 0.95),
    );

    expect(result.events, contains('sticky_attached'));
    expect(
      result.physicsEvents
          .where(
            (event) =>
                event.kind == PhysicsEventKind.move &&
                event.targetEntityId == 'target',
          )
          .any((event) => event.visualState == 'stuck'),
      isTrue,
    );
    expect(
      result.physicsEvents
          .where((event) => event.targetEntityId == 'target')
          .any((event) => event.resultingVelocity.length <= 0.001),
      isTrue,
    );
  });

  test('무거운 공은 같은 충돌에서 일반 공보다 큰 운동량을 전달한다', () {
    final normal = resolver.resolve(
      _singleTargetState(EntityType.crate, targetSize: const Vec2(42, 42)),
      const ShotInput(direction: Vec2(1, 0), power: 0.95),
    );
    final heavy = resolver.resolve(
      _singleTargetState(EntityType.crate, targetSize: const Vec2(42, 42)),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.95,
        equippedTrait: TraitType.heavy,
      ),
    );
    final normalDistance = normal.state
        .entityById('target')!
        .position
        .distanceTo(const Vec2(142, 280));
    final heavyDistance = heavy.state
        .entityById('target')!
        .position
        .distanceTo(const Vec2(142, 280));

    expect(normal.events, contains('crate_pushed'));
    expect(heavy.events, contains('crate_pushed'));
    expect(heavyDistance, greaterThan(normalDistance));
  });

  test('모든 대표 충돌은 유한한 법선·충격량·결과 속도를 기록한다', () {
    for (final type in [
      EntityType.wall,
      EntityType.crate,
      EntityType.weight,
      EntityType.bumper,
      EntityType.stickySurface,
      EntityType.ball,
    ]) {
      final result = resolver.resolve(
        _singleTargetState(type, targetSize: const Vec2(42, 42)),
        const ShotInput(direction: Vec2(1, 0), power: 0.95),
      );
      final impact = _impactOn(result, 'target');

      expect(impact.normal.x.isFinite && impact.normal.y.isFinite, isTrue);
      expect(impact.impulse.isFinite, isTrue);
      expect(
        impact.resultingVelocity.x.isFinite &&
            impact.resultingVelocity.y.isFinite,
        isTrue,
      );
    }
  });
}

PhysicsEvent _impactOn(ShotResult result, String targetId) {
  return result.physicsEvents.firstWhere(
    (event) =>
        event.kind == PhysicsEventKind.impact &&
        event.targetEntityId == targetId,
  );
}

GameState _singleTargetState(EntityType type, {required Vec2 targetSize}) {
  return GameState(
    levelIndex: 0,
    levelName: '물리 수치 검증',
    ballSpawn: const Vec2(56, 280),
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(56, 280),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'target',
        type: type,
        position: const Vec2(142, 280),
        size: targetSize,
        traits: switch (type) {
          EntityType.bumper => const {TraitType.bouncy},
          EntityType.stickySurface => const {TraitType.sticky},
          EntityType.weight => const {TraitType.heavy},
          _ => const {},
        },
        movable: type == EntityType.crate || type == EntityType.ball,
      ),
    ],
  );
}
