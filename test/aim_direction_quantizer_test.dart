import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/input/aim_direction_quantizer.dart';

void main() {
  test('포인터 방향은 가장 가까운 1도 단위 논리 각도로 확정된다', () {
    final direction = _direction(239.6);
    final quantized = quantizeAimDirection(direction);

    expect(_degrees(quantized), closeTo(240, 0.000001));
    expect(quantized.length, closeTo(1, 0.000001));
  });

  test('같은 1도 구간의 픽셀 흔들림은 같은 방향 벡터를 만든다', () {
    final left = quantizeAimDirection(_direction(343.51));
    final right = quantizeAimDirection(_direction(344.49));

    expect(left.x, closeTo(right.x, 0.000000001));
    expect(left.y, closeTo(right.y, 0.000000001));
    expect(_degrees(left), closeTo(344, 0.000001));
  });

  test('0 벡터와 잘못된 간격을 안전하게 처리한다', () {
    expect(quantizeAimDirection(Vec2.zero), const Vec2(1, 0));
    expect(
      () => quantizeAimDirection(const Vec2(1, 0), stepDegrees: 0),
      throwsArgumentError,
    );
  });
}

Vec2 _direction(double degrees) {
  final radians = degrees * math.pi / 180;
  return Vec2(math.cos(radians), math.sin(radians));
}

double _degrees(Vec2 direction) {
  final raw = math.atan2(direction.y, direction.x) * 180 / math.pi;
  return raw < 0 ? raw + 360 : raw;
}
