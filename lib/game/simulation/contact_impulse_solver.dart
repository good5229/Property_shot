import 'dart:math' as math;

import '../domain/geometry.dart';

/// 두 강체의 한 접촉점에서 적용된 충격량과 충돌 직후 속도다.
///
/// [normal]은 target에서 moving을 향하는 접촉 법선이다. 따라서 접근 중인
/// 두 물체의 상대 법선 속도는 음수이고, 양의 [normalImpulse]가 moving을
/// 밀어내는 동시에 같은 크기의 반대 충격을 target에 전달한다.
class ContactImpulseResult {
  const ContactImpulseResult({
    required this.movingVelocity,
    required this.targetVelocity,
    required this.normalImpulse,
    required this.frictionImpulse,
    required this.approaching,
  });

  final Vec2 movingVelocity;
  final Vec2 targetVelocity;
  final double normalImpulse;
  final double frictionImpulse;
  final bool approaching;
}

/// 질량·상대속도·반발계수로 접촉 충격량을 계산하는 결정론적 2D 해석기다.
///
/// Box2D와 Matter.js의 접촉 해석처럼 역질량 합으로 법선 충격량을 나누고,
/// 두 물체에 크기가 같고 방향이 반대인 충격을 적용한다. 회전 강체가 없는
/// Property Shot의 원형/축정렬 물체에 맞춰 선형 속도만 다룬다.
class ContactImpulseSolver {
  const ContactImpulseSolver();

  ContactImpulseResult solve({
    required Vec2 movingVelocity,
    required Vec2 targetVelocity,
    required Vec2 normal,
    required double movingMass,
    required double targetMass,
    required double restitution,
    double friction = 0,
  }) {
    if (!_validMass(movingMass) || !_validMass(targetMass)) {
      throw ArgumentError('충돌 질량은 0보다 큰 유한 수여야 합니다.');
    }
    if (!movingVelocity.x.isFinite ||
        !movingVelocity.y.isFinite ||
        !targetVelocity.x.isFinite ||
        !targetVelocity.y.isFinite ||
        !normal.x.isFinite ||
        !normal.y.isFinite) {
      throw ArgumentError('충돌 속도와 법선은 유한 수여야 합니다.');
    }

    final n = normal.length <= 1e-9 ? const Vec2(1, 0) : normal.normalized();
    final inverseMovingMass = 1 / movingMass;
    final inverseTargetMass = 1 / targetMass;
    final inverseMassSum = inverseMovingMass + inverseTargetMass;
    final relativeVelocity = movingVelocity - targetVelocity;
    final relativeNormalSpeed = relativeVelocity.dot(n);
    if (relativeNormalSpeed >= -1e-9) {
      return ContactImpulseResult(
        movingVelocity: movingVelocity,
        targetVelocity: targetVelocity,
        normalImpulse: 0,
        frictionImpulse: 0,
        approaching: false,
      );
    }

    final pairRestitution = restitution.clamp(0.0, 1.0).toDouble();
    final normalImpulse =
        -(1 + pairRestitution) * relativeNormalSpeed / inverseMassSum;
    var movingAfter = movingVelocity + n * (normalImpulse * inverseMovingMass);
    var targetAfter = targetVelocity - n * (normalImpulse * inverseTargetMass);

    var frictionImpulse = 0.0;
    final frictionCoefficient = friction.clamp(0.0, 1.0).toDouble();
    final afterRelative = movingAfter - targetAfter;
    final tangentVelocity = afterRelative - n * afterRelative.dot(n);
    if (frictionCoefficient > 0 && tangentVelocity.length > 1e-9) {
      final tangent = tangentVelocity.normalized();
      final unconstrained = -afterRelative.dot(tangent) / inverseMassSum;
      final limit = frictionCoefficient * normalImpulse;
      frictionImpulse = unconstrained.clamp(-limit, limit).toDouble();
      movingAfter += tangent * (frictionImpulse * inverseMovingMass);
      targetAfter -= tangent * (frictionImpulse * inverseTargetMass);
    }

    return ContactImpulseResult(
      movingVelocity: _finiteOrZero(movingAfter),
      targetVelocity: _finiteOrZero(targetAfter),
      normalImpulse: math.max(0, normalImpulse),
      frictionImpulse: frictionImpulse,
      approaching: true,
    );
  }

  bool _validMass(double mass) => mass.isFinite && mass > 0;

  Vec2 _finiteOrZero(Vec2 velocity) =>
      velocity.x.isFinite && velocity.y.isFinite ? velocity : Vec2.zero;
}
