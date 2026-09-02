import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/simulation/contact_island_solver.dart';

void main() {
  const solver = ContactIslandSolver(iterations: 12);

  test('같은 질량의 3중 정면 추돌은 마지막 물체까지 속도를 전달한다', () {
    final result = solver.solve(
      bodies: const [
        ContactIslandBody(entityId: 'a', velocity: Vec2(18, 0), mass: 1),
        ContactIslandBody(entityId: 'b', velocity: Vec2.zero, mass: 1),
        ContactIslandBody(entityId: 'c', velocity: Vec2.zero, mass: 1),
      ],
      contacts: const [
        ContactIslandConstraint(
          sourceEntityId: 'a',
          targetEntityId: 'b',
          normal: Vec2(-1, 0),
          restitution: 0.92,
        ),
        ContactIslandConstraint(
          sourceEntityId: 'b',
          targetEntityId: 'c',
          normal: Vec2(-1, 0),
          restitution: 0.92,
        ),
      ],
    );

    expect(result['c']!.x, greaterThan(result['a']!.x));
    expect(result['c']!.x, greaterThan(result['b']!.x));
    expect(
      result.values.fold(0.0, (sum, velocity) => sum + velocity.x),
      closeTo(18, 1e-6),
    );
  });

  test('빗겨 맞은 4중 접촉군도 접선 성분과 전체 운동량을 보존한다', () {
    final result = solver.solve(
      bodies: const [
        ContactIslandBody(entityId: 'a', velocity: Vec2(16, 4), mass: 1),
        ContactIslandBody(entityId: 'b', velocity: Vec2.zero, mass: 1),
        ContactIslandBody(entityId: 'c', velocity: Vec2.zero, mass: 1),
        ContactIslandBody(entityId: 'd', velocity: Vec2.zero, mass: 1),
      ],
      contacts: const [
        ContactIslandConstraint(
          sourceEntityId: 'a',
          targetEntityId: 'b',
          normal: Vec2(-1, 0),
          restitution: 0.86,
        ),
        ContactIslandConstraint(
          sourceEntityId: 'b',
          targetEntityId: 'c',
          normal: Vec2(-1, 0),
          restitution: 0.86,
        ),
        ContactIslandConstraint(
          sourceEntityId: 'c',
          targetEntityId: 'd',
          normal: Vec2(-1, 0),
          restitution: 0.86,
        ),
      ],
    );

    final momentum = result.values.fold(Vec2.zero, (sum, value) => sum + value);
    expect(momentum.x, closeTo(16, 1e-6));
    expect(momentum.y, closeTo(4, 1e-6));
    expect(result['a']!.y, closeTo(4, 1e-6));
    expect(result['d']!.x, greaterThan(0));
    final kineticEnergyAfter = result.values.fold(
      0.0,
      (sum, velocity) => sum + 0.5 * velocity.length * velocity.length,
    );
    const kineticEnergyBefore = 0.5 * (16 * 16 + 4 * 4);
    expect(
      kineticEnergyAfter,
      lessThanOrEqualTo(kineticEnergyBefore + 1e-6),
      reason: '반복 접촉 해석이 에너지를 새로 만들어서는 안 된다.',
    );
  });

  test('접촉 입력 순서가 달라도 동일한 접촉군 결과를 만든다', () {
    const bodies = [
      ContactIslandBody(entityId: 'a', velocity: Vec2(12, 0), mass: 1),
      ContactIslandBody(entityId: 'b', velocity: Vec2.zero, mass: 1),
      ContactIslandBody(entityId: 'c', velocity: Vec2.zero, mass: 1),
    ];
    const first = ContactIslandConstraint(
      sourceEntityId: 'a',
      targetEntityId: 'b',
      normal: Vec2(-1, 0),
      restitution: 0.9,
    );
    const second = ContactIslandConstraint(
      sourceEntityId: 'b',
      targetEntityId: 'c',
      normal: Vec2(-1, 0),
      restitution: 0.9,
    );

    expect(
      solver.solve(bodies: bodies, contacts: const [first, second]),
      solver.solve(bodies: bodies, contacts: const [second, first]),
    );
  });
}
