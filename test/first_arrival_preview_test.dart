import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();

  test('첫 고체 충돌 위치를 실제 판정 경로에서 반환한다', () {
    final state = _state([
      _ball(),
      const EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(150, 280),
        size: Vec2(24, 120),
      ),
    ]);

    final preview = resolver.firstArrival(state, _shot());

    expect(preview.kind, FirstArrivalKind.impact);
    expect(preview.entityId, 'wall');
  });

  test('홀 진입을 일반 충돌과 구분한다', () {
    final state = _state([
      _ball(),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(150, 280),
        size: Vec2(36, 36),
        solid: false,
      ),
    ]);

    final preview = resolver.firstArrival(state, _shot());

    expect(preview.kind, FirstArrivalKind.hole);
    expect(preview.entityId, 'hole');
  });

  test('충돌보다 먼저 통과하는 파워 슬라이더 진입을 반환한다', () {
    final state = _state([
      _ball(),
      const EntityState(
        id: 'slider',
        type: EntityType.powerSlider,
        position: Vec2(110, 280),
        size: Vec2(36, 64),
        solid: false,
        referenceSpeed: 30,
        allowedTargets: {EntityType.ball},
      ),
      const EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(220, 280),
        size: Vec2(24, 120),
      ),
    ]);

    final preview = resolver.firstArrival(state, _shot());

    expect(preview.kind, FirstArrivalKind.powerSlider);
    expect(preview.entityId, 'slider');
  });

  test('사건 없이 멈추면 실제 경로 끝을 반환한다', () {
    final state = _state([_ball(position: const Vec2(30, 30))]);
    const input = ShotInput(direction: Vec2(1, 1), power: 0);

    final result = resolver.resolve(state, input);
    final preview = resolver.firstArrival(state, input);

    expect(preview.kind, FirstArrivalKind.rangeEnd);
    expect(preview.position, result.path.last);
    expect(preview.pathIndex, result.path.length - 1);
  });

  test('미리보기 계산은 전달된 상태를 변경하지 않는다', () {
    final entities = <EntityState>[
      _ball(),
      const EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(150, 280),
        size: Vec2(24, 120),
      ),
    ];
    final state = _state(entities);

    resolver.firstArrival(state, _shot());

    expect(identical(state.entities, entities), isTrue);
    expect(state.shotCount, 0);
    expect(state.phase, GamePhase.planning);
    expect(state.activeBall.position, const Vec2(60, 280));
    expect(state.history, isEmpty);
  });

  test('미리보기 사용 여부는 실제 발사 결과와 점수 지문을 바꾸지 않는다', () {
    final state = _state([
      _ball(),
      const EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(150, 280),
        size: Vec2(24, 120),
      ),
    ]);
    final before = resolver.resolve(state, _shot());

    resolver.firstArrival(state, _shot());
    final after = resolver.resolve(state, _shot());

    expect(shotResultFingerprint(after), shotResultFingerprint(before));
    expect(after.state.score, before.state.score);
  });
}

ShotInput _shot() => const ShotInput(direction: Vec2(1, 0), power: 0.5);

EntityState _ball({Vec2 position = const Vec2(60, 280)}) => EntityState(
  id: 'active_ball',
  type: EntityType.ball,
  position: position,
  size: const Vec2(24, 24),
  movable: true,
);

GameState _state(List<EntityState> entities) => GameState(
  levelIndex: 0,
  levelName: '첫 도착 미리보기 시험',
  entities: entities,
  ballSpawn: entities.first.position,
);
