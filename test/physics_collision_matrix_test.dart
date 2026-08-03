import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

class _CollisionCase {
  const _CollisionCase(
    this.name,
    this.type,
    this.size,
    this.movable,
    this.trait,
  );

  final String name;
  final EntityType type;
  final Vec2 size;
  final bool movable;
  final TraitType? trait;
}

void main() {
  const resolver = ShotResolver();
  const cases = [
    _CollisionCase(
      '벽',
      EntityType.wall,
      Vec2(24, 120),
      false,
      TraitType.bouncy,
    ),
    _CollisionCase('상자', EntityType.crate, Vec2(42, 42), true, null),
    _CollisionCase('무거운 돌', EntityType.weight, Vec2(52, 38), false, null),
    _CollisionCase('젤리', EntityType.bumper, Vec2(58, 42), false, null),
    _CollisionCase('점착판', EntityType.stickySurface, Vec2(50, 86), false, null),
    _CollisionCase('이전 공', EntityType.ball, Vec2(24, 24), true, null),
    _CollisionCase('일반 풍선', EntityType.balloon, Vec2(52, 58), false, null),
    _CollisionCase(
      '뾰족한 풍선',
      EntityType.balloon,
      Vec2(52, 58),
      false,
      TraitType.sharp,
    ),
  ];

  test('대표 대상 타입은 모두 충돌 이벤트와 대상 ID를 남긴다', () {
    for (final collisionCase in cases) {
      final result = resolver.resolve(
        _stateFor(collisionCase),
        ShotInput(
          direction: const Vec2(1, 0),
          power: 0.92,
          equippedTrait: collisionCase.trait,
        ),
      );

      expect(
        result.impacts.any((impact) => impact.entityId == 'target'),
        isTrue,
        reason: '${collisionCase.name} 충돌이 기록되지 않음',
      );
      expect(
        result.physicsEvents.any((event) => event.targetEntityId == 'target'),
        isTrue,
        reason: '${collisionCase.name} 물리 이벤트가 기록되지 않음',
      );
    }
  });

  test('풍선은 일반 공과 뾰족한 공의 결과를 구분한다', () {
    final ordinary = resolver.resolve(
      _stateFor(cases[6]),
      const ShotInput(direction: Vec2(1, 0), power: 0.92),
    );
    final sharp = resolver.resolve(
      _stateFor(cases[7]),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.92,
        equippedTrait: TraitType.sharp,
      ),
    );

    expect(ordinary.events, contains('balloon_bounced'));
    expect(ordinary.events, isNot(contains('balloon_popped')));
    expect(sharp.events, contains('balloon_popped'));
    expect(sharp.events, contains('sharpness_consumed'));
  });
}

GameState _stateFor(_CollisionCase collisionCase) {
  return GameState(
    levelIndex: 0,
    levelName: '충돌 조합 검증',
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
        type: collisionCase.type,
        position: const Vec2(142, 280),
        size: collisionCase.size,
        movable: collisionCase.movable,
      ),
    ],
  );
}
