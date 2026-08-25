import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/simulation/impact_metrics.dart';

void main() {
  test('충돌 충격량은 상대 법선 속도와 유효 질량으로 구분된다', () {
    final light = ImpactMetrics.normalizedImpulse(
      relativeNormalSpeed: 5,
      movingMass: 1,
      targetMass: 1,
    );
    final heavy = ImpactMetrics.normalizedImpulse(
      relativeNormalSpeed: 20,
      movingMass: 4,
      targetMass: 2,
    );

    expect(light, lessThan(heavy));
    expect(ImpactMetrics.tierFor(light), ImpactTier.tap);
    expect(ImpactMetrics.tierFor(heavy), ImpactTier.critical);
  });

  test('타격감은 시간축을 멈추지 않고 카메라 곡선으로만 표현한다', () {
    expect(ImpactMetrics.cameraShake(0.9), greaterThan(0));
    expect(ImpactMetrics.cameraShake(0.9, reducedMotion: true), 0);
  });
}
