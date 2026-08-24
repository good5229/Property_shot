import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/input/aim_direction_quantizer.dart';
import 'package:property_shot/game/input/intent_assist_resolver.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const assist = IntentAssistResolver();
  const physics = ShotResolver();

  test('기본 보정은 가까운 실제 기물을 살짝 빗나간 입력만 그 기물로 돌린다', () {
    final state = _state([_crate('target', const Vec2(260, 280))]);
    final raw = _input(9.5, 0.603);

    final before = physics.firstArrival(state, raw);
    final decision = assist.resolve(state: state, rawInput: raw);
    final after = physics.firstArrival(state, decision.appliedInput);
    expect(before.entityId, isNot('target'));
    expect(decision.targetSnapped, isTrue);
    expect(decision.targetEntityId, 'target');
    expect(decision.targetKind, IntentAssistTargetKind.physical);
    expect(decision.confidence, inInclusiveRange(0.05, 1));
    expect(decision.angleDeltaDegrees.abs(), lessThanOrEqualTo(3.0001));
    expect(decision.powerDelta.abs(), lessThanOrEqualTo(0.0201));
    expect(after.entityId, 'target');
    expect(decision.appliedInput.rawDirection, raw.direction.normalized());
    expect(decision.appliedInput.rawPower, raw.power);
  });

  test('이미 실제 기물을 맞히는 입력은 다른 더 좋은 경로로 바꾸지 않는다', () {
    final state = _state([
      _crate('target', const Vec2(260, 280)),
      _hole(const Vec2(420, 280)),
    ]);
    final raw = _input(0.3, 0.603);

    final decision = assist.resolve(state: state, rawInput: raw);
    final arrival = physics.firstArrival(state, decision.appliedInput);

    expect(arrival.entityId, 'target');
    expect(decision.targetSnapped, isFalse);
    expect(decision.targetEntityId, isNull);
    expect(decision.appliedInput.power, closeTo(0.60, 0.000001));
  });

  test('양자화가 첫 접촉 기물을 바꾸면 원시 입력을 보존한다', () {
    ShotInput? raw;
    GameState? state;
    for (var yStep = 0; yStep <= 240 && raw == null; yStep++) {
      final candidateState = _state([
        _crate('raw_target', Vec2(260, 250 + yStep * 0.25)),
      ]);
      for (var angleStep = -200; angleStep <= 200; angleStep++) {
        final candidate = _input(angleStep * 0.05, 0.603);
        final rawArrival = physics.firstArrival(candidateState, candidate);
        final stableArrival = physics.firstArrival(
          candidateState,
          ShotInput(
            direction: quantizeAimDirection(candidate.direction),
            power: 0.60,
          ),
        );
        if (rawArrival.entityId == 'raw_target' &&
            stableArrival.entityId != 'raw_target') {
          raw = candidate;
          state = candidateState;
          break;
        }
      }
    }
    expect(raw, isNotNull, reason: '첫 접촉 보존 회귀 입력을 찾지 못했습니다.');
    final resolvedState = state!;
    final resolvedRaw = raw!;
    final rawArrival = physics.firstArrival(resolvedState, resolvedRaw);
    final decision = assist.resolve(
      state: resolvedState,
      rawInput: resolvedRaw,
    );
    final appliedArrival = physics.firstArrival(
      resolvedState,
      decision.appliedInput,
    );

    expect(rawArrival.entityId, isNotNull);
    expect(appliedArrival.entityId, rawArrival.entityId);
    expect(decision.targetSnapped, isFalse);
    expect(decision.appliedInput.direction, resolvedRaw.direction.normalized());
    expect(decision.appliedInput.power, resolvedRaw.power);
  });

  test('벽 반사 입력은 가까운 기물 정답으로 재해석하지 않는다', () {
    final state = _state([_crate('near_bank', const Vec2(490, 315))]);
    final raw = _input(8, 0.9);
    final rawArrival = physics.firstArrival(state, raw);
    final decision = assist.resolve(
      state: state,
      rawInput: raw,
      policy: const IntentAssistPolicy(preserveBoundaryIntent: true),
    );
    final appliedArrival = physics.firstArrival(state, decision.appliedInput);

    expect(rawArrival.entityId, startsWith('field_boundary_'));
    expect(appliedArrival.entityId, rawArrival.entityId);
    expect(decision.targetSnapped, isFalse);
  });

  test('정밀 경로 정책은 방향과 힘을 바꾸지 않고 홀 가장자리 여유만 준다', () {
    final state = _state([_crate('target', const Vec2(260, 280))]);
    final raw = _input(9.5, 0.603);
    final decision = assist.resolve(
      state: state,
      rawInput: raw,
      policy: IntentAssistPolicy.forStage('stage_chain_score'),
    );

    expect(decision.appliedInput.direction, raw.direction.normalized());
    expect(decision.appliedInput.power, raw.power);
    expect(decision.appliedInput.holeForgivenessRadius, 6);
    expect(decision.targetSnapped, isFalse);
  });

  test('같은 오차에 서로 다른 목표가 있으면 시스템이 임의로 하나를 고르지 않는다', () {
    final state = _state([
      _crate('upper', const Vec2(260, 307)),
      _crate('lower', const Vec2(260, 253)),
    ]);
    final raw = _input(0, 0.6);

    final decision = assist.resolve(state: state, rawInput: raw);

    expect(decision.targetSnapped, isFalse);
    expect(decision.targetEntityId, isNull);
    expect(decision.appliedInput.direction, const Vec2(1, 0));
  });

  test('홀은 기믹보다 좁은 각도 범위에서만 자동 목표로 인정한다', () {
    final state = _state([
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(300, 305),
        size: Vec2(20, 20),
        solid: false,
        hitboxScale: 1,
      ),
    ]);
    final raw = _input(0, 0.6);

    final decision = assist.resolve(state: state, rawInput: raw);

    expect(decision.targetEntityId, 'hole', reason: '2도 안쪽의 홀은 근소한 오차로 인정합니다.');
    expect(decision.targetKind, IntentAssistTargetKind.hole);
    expect(decision.angleDeltaDegrees.abs(), lessThanOrEqualTo(2.0001));
  });

  test('벽과 문은 가까워도 자동 보정 목표로 선택하지 않는다', () {
    final state = _state([
      const EntityState(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(260, 280),
        size: Vec2(10, 70),
        hitboxScale: 1,
      ),
    ]);
    final raw = _input(8, 0.6);

    final decision = assist.resolve(state: state, rawInput: raw);

    expect(decision.targetSnapped, isFalse);
    expect(decision.targetEntityId, isNull);
  });

  test('홀과 일반 기물이 같은 오차에 있어도 정답처럼 홀을 우선하지 않는다', () {
    final state = _state([
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(260, 307),
        size: Vec2(20, 20),
        solid: false,
        hitboxScale: 1,
      ),
      EntityState(
        id: 'lower',
        type: EntityType.crate,
        position: const Vec2(260, 253),
        size: const Vec2(32, 32),
        movable: false,
        hitboxScale: 1,
      ),
    ]);
    final raw = _input(0, 0.6);

    final decision = assist.resolve(state: state, rawInput: raw);

    expect(decision.targetSnapped, isFalse);
    expect(decision.targetEntityId, isNull);
    expect(decision.appliedInput.direction, const Vec2(1, 0));
  });

  test('직접 탐색은 방향·힘·홀 판정 여유를 전혀 변경하지 않는다', () {
    final state = _state([_crate('target', const Vec2(260, 280))]);
    final raw = _input(9.5, 0.603);

    final decision = assist.resolve(
      state: state,
      rawInput: raw,
      strength: IntentAssistStrength.off,
      compactPointer: true,
      repeatedNearMisses: 3,
    );

    expect(decision.adjusted, isFalse);
    expect(decision.appliedInput.direction, raw.direction.normalized());
    expect(decision.appliedInput.power, raw.power);
    expect(decision.appliedInput.holeForgivenessRadius, 0);
  });

  test('편안한 터치와 반복 근접 실패는 정해진 상한 안에서만 여유를 넓힌다', () {
    final state = _state([_crate('target', const Vec2(260, 280))]);
    final raw = _input(9.5, 0.603);

    final normal = assist.resolve(state: state, rawInput: raw);
    final adaptive = assist.resolve(
      state: state,
      rawInput: raw,
      strength: IntentAssistStrength.comfortable,
      compactPointer: true,
      repeatedNearMisses: 2,
    );

    expect(normal.appliedInput.holeForgivenessRadius, 6);
    expect(adaptive.appliedInput.holeForgivenessRadius, 14);
    expect(adaptive.angleDeltaDegrees.abs(), lessThanOrEqualTo(7.0001));
    expect(adaptive.powerDelta.abs(), lessThanOrEqualTo(0.081));
  });

  test('동일 상태와 원시 입력은 반복해도 같은 보정 입력을 만든다', () {
    final state = _state([_crate('target', const Vec2(260, 280))]);
    final raw = _input(9.5, 0.603);
    final first = assist.resolve(state: state, rawInput: raw);

    for (var index = 0; index < 50; index++) {
      final next = assist.resolve(state: state, rawInput: raw);
      expect(next.appliedInput.direction, first.appliedInput.direction);
      expect(next.appliedInput.power, first.appliedInput.power);
      expect(next.targetEntityId, first.targetEntityId);
    }
  });

  test('NaN·무한대·0 방향과 과도한 홀 여유는 명시적으로 거부한다', () {
    final state = _state(const []);
    for (final input in [
      const ShotInput(direction: Vec2.zero, power: 0.5),
      const ShotInput(direction: Vec2(double.nan, 1), power: 0.5),
      const ShotInput(direction: Vec2(1, 0), power: double.infinity),
      const ShotInput(direction: Vec2(1, 0), power: 0.5, rawPower: 1.1),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.5,
        holeForgivenessRadius: 17,
      ),
    ]) {
      expect(
        () => assist.resolve(state: state, rawInput: input),
        throwsArgumentError,
      );
    }
  });
}

GameState _state(List<EntityState> objects) => GameState(
  levelIndex: 0,
  levelName: '의도 보정 시험',
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
    ...objects,
  ],
);

EntityState _crate(String id, Vec2 position) => EntityState(
  id: id,
  type: EntityType.crate,
  position: position,
  size: const Vec2(32, 32),
  movable: false,
  hitboxScale: 0.88,
);

EntityState _hole(Vec2 position) => EntityState(
  id: 'hole',
  type: EntityType.hole,
  position: position,
  size: const Vec2(30, 30),
  solid: false,
  hitboxScale: 1,
);

ShotInput _input(double degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}
