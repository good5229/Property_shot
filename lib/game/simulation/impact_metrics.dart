enum ImpactTier { tap, light, heavy, critical }

class ImpactMetrics {
  const ImpactMetrics._();

  static ImpactTier tierFor(double impulse) {
    final value = impulse.clamp(0.0, 1.0);
    if (value < 0.2) return ImpactTier.tap;
    if (value < 0.48) return ImpactTier.light;
    if (value < 0.78) return ImpactTier.heavy;
    return ImpactTier.critical;
  }

  static double normalizedImpulse({
    required double relativeNormalSpeed,
    required double movingMass,
    required double targetMass,
  }) {
    final massFactor = (movingMass * targetMass / (movingMass + targetMass))
        .clamp(0.08, 8.0);
    return (relativeNormalSpeed.abs() * massFactor / 28).clamp(0.0, 1.0);
  }

  static int hitStopMilliseconds(double impulse, {bool reducedMotion = false}) {
    if (reducedMotion) return 0;
    return switch (tierFor(impulse)) {
      ImpactTier.tap => 0,
      ImpactTier.light => 20,
      ImpactTier.heavy => 32,
      ImpactTier.critical => 46,
    };
  }

  static double cameraShake(double impulse, {bool reducedMotion = false}) {
    if (reducedMotion) return 0;
    return (impulse.clamp(0.0, 1.0) * 3.2).clamp(0.0, 3.2);
  }
}
