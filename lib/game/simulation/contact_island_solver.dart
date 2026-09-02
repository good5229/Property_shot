import '../domain/geometry.dart';

class ContactIslandBody {
  const ContactIslandBody({
    required this.entityId,
    required this.velocity,
    required this.mass,
  });

  final String entityId;
  final Vec2 velocity;
  final double mass;
}

class ContactIslandConstraint {
  const ContactIslandConstraint({
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.normal,
    required this.restitution,
  });

  final String sourceEntityId;
  final String targetEntityId;
  final Vec2 normal;
  final double restitution;
}

/// 한 프레임에 연결된 모든 동적 접촉의 속도를 함께 푸는 순차 임펄스 해석기다.
///
/// 한 쌍을 끝까지 이동시킨 뒤 다음 쌍을 처리하지 않고, 접촉군의 제약을 여러
/// 번 순회한다. 첫 순회에서만 반발을 적용하고 이후 순회는 새로 생긴 접근
/// 속도만 제거하므로 N중 추돌에서도 운동량이 뒤쪽 물체까지 같은 시간대에
/// 전달되며 반복 횟수가 에너지를 새로 만들지 않는다.
class ContactIslandSolver {
  const ContactIslandSolver({this.iterations = 8}) : assert(iterations > 0);

  final int iterations;

  Map<String, Vec2> solve({
    required Iterable<ContactIslandBody> bodies,
    required Iterable<ContactIslandConstraint> contacts,
  }) {
    final bodyById = {for (final body in bodies) body.entityId: body};
    final velocities = {
      for (final body in bodyById.values) body.entityId: body.velocity,
    };
    final ordered =
        contacts
            .where(
              (contact) =>
                  bodyById.containsKey(contact.sourceEntityId) &&
                  bodyById.containsKey(contact.targetEntityId) &&
                  contact.sourceEntityId != contact.targetEntityId,
            )
            .toList()
          ..sort((first, second) {
            final firstKey = '${first.sourceEntityId}:${first.targetEntityId}';
            final secondKey =
                '${second.sourceEntityId}:${second.targetEntityId}';
            return firstKey.compareTo(secondKey);
          });
    for (var iteration = 0; iteration < iterations; iteration++) {
      final indices = iteration.isEven
          ? Iterable<int>.generate(ordered.length)
          : Iterable<int>.generate(
              ordered.length,
              (i) => ordered.length - i - 1,
            );
      for (final index in indices) {
        final contact = ordered[index];
        final source = bodyById[contact.sourceEntityId]!;
        final target = bodyById[contact.targetEntityId]!;
        if (!_validMass(source.mass) || !_validMass(target.mass)) continue;
        final normal = _normal(contact.normal);
        final inverseSourceMass = 1 / source.mass;
        final inverseTargetMass = 1 / target.mass;
        final relative =
            velocities[source.entityId]! - velocities[target.entityId]!;
        final currentNormalSpeed = relative.dot(normal);
        if (currentNormalSpeed >= -1e-9) continue;
        // 최초 순회는 실제 충돌 반발을 적용하고, 이후 순회는 앞 접촉의
        // 전달로 다시 접근하게 된 잔여 속도만 비탄성으로 제거한다. 같은
        // 반발을 반복 적용해 에너지를 만들거나 중간 물체를 뒤로 튕기지 않는다.
        final restitution = iteration == 0
            ? contact.restitution.clamp(0.0, 1.0)
            : 0.0;
        final delta =
            -(1 + restitution) *
            currentNormalSpeed /
            (inverseSourceMass + inverseTargetMass);
        velocities[source.entityId] =
            velocities[source.entityId]! + normal * (delta * inverseSourceMass);
        velocities[target.entityId] =
            velocities[target.entityId]! - normal * (delta * inverseTargetMass);
      }
    }
    return Map<String, Vec2>.unmodifiable(velocities);
  }

  static Vec2 _normal(Vec2 normal) =>
      normal.length <= 1e-9 ? const Vec2(1, 0) : normal.normalized();

  static bool _validMass(double mass) => mass.isFinite && mass > 0;
}
