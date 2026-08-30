import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/simulation/contact_impulse_solver.dart';

void main() {
  const solver = ContactImpulseSolver();

  test('무거운 공이 정지 상자를 치면 상자가 공보다 큰 전진 속도를 얻는다', () {
    final result = solver.solve(
      movingVelocity: const Vec2(0, -24),
      targetVelocity: Vec2.zero,
      normal: const Vec2(0, 1),
      movingMass: 4.4,
      targetMass: 2,
      restitution: 0.72,
    );

    expect(result.approaching, isTrue);
    expect(result.normalImpulse, greaterThan(0));
    expect(result.targetVelocity.y, lessThan(result.movingVelocity.y));
    expect(
      result.targetVelocity.length,
      greaterThan(result.movingVelocity.length),
    );
    final momentumBefore = -24 * 4.4;
    final momentumAfter =
        result.movingVelocity.y * 4.4 + result.targetVelocity.y * 2;
    expect(momentumAfter, closeTo(momentumBefore, 1e-9));
    expect(
      (result.movingVelocity - result.targetVelocity).dot(const Vec2(0, 1)),
      closeTo(24 * 0.72, 1e-9),
    );
  });

  test('같은 질량의 완전 탄성 정면충돌은 속도를 교환한다', () {
    final result = solver.solve(
      movingVelocity: const Vec2(12, 0),
      targetVelocity: Vec2.zero,
      normal: const Vec2(-1, 0),
      movingMass: 1,
      targetMass: 1,
      restitution: 1,
    );

    expect(result.movingVelocity.length, closeTo(0, 1e-9));
    expect(result.targetVelocity.x, closeTo(12, 1e-9));
  });

  test('알까기식 빗겨 충돌은 법선 속도만 전달하고 접선 속도를 유지한다', () {
    final result = solver.solve(
      movingVelocity: const Vec2(12, 5),
      targetVelocity: Vec2.zero,
      normal: const Vec2(-1, 0),
      movingMass: 1,
      targetMass: 1,
      restitution: 1,
      friction: 0,
    );

    expect(result.movingVelocity.x, closeTo(0, 1e-9));
    expect(result.movingVelocity.y, closeTo(5, 1e-9));
    expect(result.targetVelocity.x, closeTo(12, 1e-9));
    expect(result.targetVelocity.y, closeTo(0, 1e-9));
    expect(result.movingVelocity + result.targetVelocity, const Vec2(12, 5));
  });

  test('순차 충격량을 적용하면 세 번째 물체까지 운동량이 전달된다', () {
    final first = solver.solve(
      movingVelocity: const Vec2(18, 0),
      targetVelocity: Vec2.zero,
      normal: const Vec2(-1, 0),
      movingMass: 4,
      targetMass: 2,
      restitution: 0.6,
    );
    final second = solver.solve(
      movingVelocity: first.targetVelocity,
      targetVelocity: Vec2.zero,
      normal: const Vec2(-1, 0),
      movingMass: 2,
      targetMass: 2,
      restitution: 0.6,
    );

    expect(first.targetVelocity.x, greaterThan(0));
    expect(second.targetVelocity.x, greaterThan(0));
    expect(second.normalImpulse, greaterThan(0));
  });

  test('이미 멀어지는 접촉에는 추가 충격량을 가하지 않는다', () {
    final result = solver.solve(
      movingVelocity: const Vec2(0, 4),
      targetVelocity: Vec2.zero,
      normal: const Vec2(0, 1),
      movingMass: 1,
      targetMass: 2,
      restitution: 0.5,
    );

    expect(result.approaching, isFalse);
    expect(result.normalImpulse, 0);
    expect(result.movingVelocity, const Vec2(0, 4));
    expect(result.targetVelocity, Vec2.zero);
  });
}
