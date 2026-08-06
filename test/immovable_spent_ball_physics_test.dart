import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();

  test('점착 샷은 고정된 spent_ball_1을 stuck 상태로 남긴다', () {
    final first = _createStickySpentBall(resolver);

    expect(first.events, contains('sticky_attached'));
    final spent = first.state.entityById('spent_ball_1')!;
    expect(spent.movable, isFalse);
    expect(spent.visualState, 'stuck');
    expect(spent.traits, contains(TraitType.sticky));
  });

  test('다음 샷은 정확한 spent ball을 맞고 법선 방향으로 반사한다', () {
    final first = _createStickySpentBall(resolver);
    final before = first.state.entityById('spent_ball_1')!;
    final result = _resolveAtFixedSpentBall(resolver, first.state);

    final impact = result.impacts.firstWhere(
      (value) => value.entityId == 'spent_ball_1',
    );
    expect(impact.sourceEntityId, 'active_ball');
    expect(result.events, contains('bounced'));
    expect(result.events, contains('spent_ball_bounced'));
    expect(result.events, isNot(contains('blocked_by_ball')));
    expect(impact.normal.x, greaterThan(0));
    expect(
      result.path
          .skip(impact.pathIndex + 1)
          .any((point) => point.x > impact.position.x),
      isTrue,
      reason: '충돌 뒤 반사된 공의 x 방향 이동이 기록되지 않았습니다.',
    );
    expect(result.chainSafetyDiagnostics, isEmpty);

    final after = result.state.entityById('spent_ball_1')!;
    expect(after.position, before.position);
    expect(after.movable, before.movable);
    expect(after.visualState, before.visualState);
    expect(after.traits, before.traits);
  });

  test('고정 spent ball 충돌 애니메이션은 위치를 옮기지 않는다', () {
    final first = _createStickySpentBall(resolver);
    final before = first.state.entityById('spent_ball_1')!;
    final result = _resolveAtFixedSpentBall(resolver, first.state);
    final move = result.moves.firstWhere(
      (value) =>
          value.entityId == 'spent_ball_1' &&
          value.visualState == 'spent_ball_hit',
    );

    expect(move.from, before.position);
    expect(move.to, before.position);
    expect(move.from, move.to);
    expect(result.state.entityById('spent_ball_1')!.position, before.position);
  });

  test('같은 상태와 입력은 고정 spent ball 반사 결과가 결정론적이다', () {
    final first = _createStickySpentBall(resolver);
    final left = _resolveAtFixedSpentBall(resolver, first.state);
    final right = _resolveAtFixedSpentBall(resolver, first.state);

    expect(_fingerprint(left), _fingerprint(right));
  });

  test('고정 spent ball 반사 뒤 벽 충돌도 처리되고 필드 밖으로 나가지 않는다', () {
    final first = _createStickySpentBall(
      resolver,
      wall: const EntityState(
        id: 'wall_after_spent',
        type: EntityType.wall,
        position: Vec2(330, 80),
        size: Vec2(24, 120),
      ),
      hole: const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(40, 300),
        size: Vec2(34, 34),
        solid: false,
      ),
    );
    final result = resolver.resolve(
      first.state,
      const ShotInput(direction: Vec2(-1, 0), power: 1),
    );

    expect(result.events, contains('spent_ball_bounced'));
    expect(result.events, contains('bounced'));
    expect(
      result.impacts.any((impact) => impact.entityId == 'wall_after_spent'),
      isTrue,
    );
    expect(result.chainSafetyDiagnostics, isEmpty);
    expect(
      result.state.entities.every(
        (entity) =>
            entity.position.x.isFinite &&
            entity.position.y.isFinite &&
            entity.size.x.isFinite &&
            entity.size.y.isFinite,
      ),
      isTrue,
    );
    expect(
      result.path.every((point) => point.x.isFinite && point.y.isFinite),
      isTrue,
    );
    expect(
      result.state.entityById('spent_ball_1')!.position,
      first.state.entityById('spent_ball_1')!.position,
    );
  });

  test('홀은 고정 spent ball 반사 뒤 같은 구간의 벽보다 먼저 포획된다', () {
    final first = _createStickySpentBall(
      resolver,
      wall: const EntityState(
        id: 'wall_behind_hole',
        type: EntityType.wall,
        position: Vec2(350, 80),
        size: Vec2(24, 120),
      ),
      hole: const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(320, 80),
        size: Vec2(34, 34),
        solid: false,
      ),
    );
    final result = _resolveAtFixedSpentBall(resolver, first.state);

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('hole_entered'));
    expect(
      result.impacts.map((impact) => impact.entityId),
      isNot(contains('wall_behind_hole')),
    );
    final holeImpact = result.impacts.firstWhere(
      (impact) => impact.entityId == 'hole',
    );
    expect(
      result.impacts.where((impact) => impact.pathIndex < holeImpact.pathIndex),
      isNotEmpty,
    );
  });

  test('움직이는 과거 공은 기존 운동량 충돌 경로를 유지한다', () {
    const state = GameState(
      levelIndex: 700,
      levelName: '움직이는 과거 공 회귀',
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
          position: Vec2(300, 300),
          size: Vec2(34, 34),
          solid: false,
        ),
      ],
    );
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.85),
    );

    expect(result.events, contains('momentum_transfer'));
    expect(result.events, isNot(contains('spent_ball_bounced')));
    expect(
      result.state.entityById('spent_ball_1')!.position.x,
      greaterThan(104),
    );
    expect(result.chainSafetyDiagnostics, isEmpty);
  });
}

ShotResult _createStickySpentBall(
  ShotResolver resolver, {
  EntityState? wall,
  EntityState? hole,
}) {
  final state = GameState(
    levelIndex: 701,
    levelName: '고정 과거 공 합성 상태',
    ballSpawn: const Vec2(280, 80),
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(280, 80),
        size: Vec2(24, 24),
        traits: {TraitType.sticky},
        movable: true,
      ),
      const EntityState(
        id: 'glue',
        type: EntityType.stickySurface,
        position: Vec2(160, 80),
        size: Vec2(34, 80),
        traits: {TraitType.sticky},
      ),
      hole ??
          const EntityState(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(320, 300),
            size: Vec2(34, 34),
            solid: false,
          ),
      ?wall,
    ],
  );
  return resolver.resolve(
    state,
    const ShotInput(
      direction: Vec2(-1, 0),
      power: 0.55,
      equippedTrait: TraitType.sticky,
    ),
  );
}

ShotResult _resolveAtFixedSpentBall(ShotResolver resolver, GameState state) {
  return resolver.resolve(
    state,
    const ShotInput(direction: Vec2(-1, 0), power: 0.9),
  );
}

String _fingerprint(ShotResult result) {
  final entities = result.state.entities
      .map(
        (entity) =>
            '${entity.id}:${entity.position.x.toStringAsFixed(6)},'
            '${entity.position.y.toStringAsFixed(6)}:${entity.movable}:'
            '${entity.visualState}:${entity.traits}',
      )
      .join('|');
  final path = result.path
      .map(
        (point) =>
            '${point.x.toStringAsFixed(6)},${point.y.toStringAsFixed(6)}',
      )
      .join('|');
  final impacts = result.impacts
      .map(
        (impact) =>
            '${impact.sourceEntityId}->${impact.entityId}:${impact.pathIndex}:'
            '${impact.normal.x.toStringAsFixed(6)},${impact.normal.y.toStringAsFixed(6)}',
      )
      .join('|');
  return '${result.state.phase}:${result.events}:$entities:$path:$impacts';
}
