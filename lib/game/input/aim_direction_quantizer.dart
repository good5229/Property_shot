import 'dart:math' as math;

import '../domain/geometry.dart';

const double defaultAimStepDegrees = 1;

Vec2 quantizeAimDirection(
  Vec2 direction, {
  double stepDegrees = defaultAimStepDegrees,
}) {
  if (!stepDegrees.isFinite || stepDegrees <= 0 || stepDegrees > 180) {
    throw ArgumentError.value(
      stepDegrees,
      'stepDegrees',
      '0보다 크고 180 이하인 유한한 값이어야 합니다.',
    );
  }
  if (!direction.x.isFinite || !direction.y.isFinite) {
    throw ArgumentError.value(direction, 'direction', '유한한 벡터여야 합니다.');
  }
  if (direction.length == 0) return const Vec2(1, 0);
  final angle = math.atan2(direction.y, direction.x);
  final step = stepDegrees * math.pi / 180;
  final quantized = (angle / step).round() * step;
  return Vec2(math.cos(quantized), math.sin(quantized));
}
