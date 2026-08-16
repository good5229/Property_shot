import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/domain/trait.dart';

class GameBallIconPainter extends CustomPainter {
  const GameBallIconPainter(
    this.trait, {
    this.rewardAppearance = false,
    this.reducedMotion = false,
  });

  final TraitType? trait;
  final bool rewardAppearance;
  final bool reducedMotion;

  static void drawBall(
    Canvas canvas, {
    required Offset center,
    required double radius,
    TraitType? trait,
    bool drawShadow = false,
    bool rewardAppearance = false,
  }) {
    final traitColor = trait == null ? Colors.white : _traitBallColor(trait);
    final baseColor = rewardAppearance
        ? Color.lerp(traitColor, const Color(0xFF19BDB5), 0.82)!
        : traitColor;
    final gradient = RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 0.96,
      colors: [
        rewardAppearance
            ? const Color(0xFFFFF8CC)
            : Colors.white.withValues(alpha: 0.98),
        if (rewardAppearance) const Color(0xFF79EFE2),
        baseColor,
        Color.lerp(
          baseColor,
          rewardAppearance ? const Color(0xFF034F55) : const Color(0xFF152018),
          rewardAppearance ? 0.62 : 0.22,
        )!,
      ],
      stops: rewardAppearance
          ? const [0.0, 0.24, 0.62, 1.0]
          : const [0.0, 0.58, 1.0],
    );
    if (drawShadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(radius * 0.13, radius * 0.72),
          width: radius * 1.6,
          height: radius * 0.42,
        ),
        Paint()..color = const Color(0x24000000),
      );
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = rewardAppearance
            ? const Color(0xFFFFC857)
            : const Color(0xFF24352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * (rewardAppearance ? 0.14 : 0.075),
    );

    if (rewardAppearance) {
      canvas.drawCircle(
        center,
        radius * 0.88,
        Paint()
          ..color = const Color(0x5526E3D2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, radius * 0.055),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        -math.pi * 0.9,
        math.pi * 1.48,
        false,
        Paint()
          ..color = const Color(0xAAE9FFFB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, radius * 0.08)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(-radius * 0.27, -radius * 0.34),
          width: radius * 0.43,
          height: radius * 0.2,
        ),
        Paint()..color = const Color(0xB8FFFFFF),
      );
    }

    final scale = radius / 23;
    final eye = Paint()..color = const Color(0xFF3B302A);
    final blush = Paint()..color = const Color(0x44FF8EA1);
    canvas.drawCircle(
      center.translate(-4.2 * scale, -2.6 * scale),
      1.45 * scale,
      eye,
    );
    canvas.drawCircle(
      center.translate(4.2 * scale, -2.6 * scale),
      1.45 * scale,
      eye,
    );
    canvas.drawCircle(
      center.translate(-6.4 * scale, 3.6 * scale),
      2.2 * scale,
      blush,
    );
    canvas.drawCircle(
      center.translate(6.4 * scale, 3.6 * scale),
      2.2 * scale,
      blush,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: center.translate(0, scale),
        width: 7 * scale,
        height: 5 * scale,
      ),
      0.15,
      2.84,
      false,
      Paint()
        ..color = const Color(0xFF3B302A)
        ..strokeWidth = 1.2 * scale
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center.translate(-4.2 * scale, -6.3 * scale),
      2.6 * scale,
      Paint()..color = const Color(0x88FFFFFF),
    );
  }

  /// 런 보상으로 얻는 공 외형을 공 본체와 분리해 그린다.
  /// 물리 속성·반지름·충돌 판정에는 관여하지 않는 순수 시각 효과다.
  static void drawRewardAppearance(
    Canvas canvas, {
    required Offset center,
    required double radius,
    double phase = 0,
    bool reducedMotion = false,
  }) {
    final ringRadius = radius + math.max(3.6, radius * 0.25);
    canvas.drawCircle(
      center,
      ringRadius + 1.4,
      Paint()
        ..color = const Color(0x5527A8A1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2.4, radius * 0.14)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      -math.pi * 0.9,
      math.pi * 0.82,
      false,
      ring..color = const Color(0xFF27A8A1),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ringRadius),
      math.pi * 0.08,
      math.pi * 0.82,
      false,
      ring..color = const Color(0xFFFFC857),
    );
    final sparkleCenter =
        center + Offset(ringRadius * 0.72, -ringRadius * 0.72);
    final sparkleRadius = math.max(2.4, radius * 0.14);
    final sparkle = Paint()..color = const Color(0xFFFFD96A);
    canvas.drawPath(
      Path()
        ..moveTo(sparkleCenter.dx, sparkleCenter.dy - sparkleRadius * 1.8)
        ..lineTo(
          sparkleCenter.dx + sparkleRadius * 0.55,
          sparkleCenter.dy - sparkleRadius * 0.5,
        )
        ..lineTo(sparkleCenter.dx + sparkleRadius * 1.8, sparkleCenter.dy)
        ..lineTo(
          sparkleCenter.dx + sparkleRadius * 0.55,
          sparkleCenter.dy + sparkleRadius * 0.5,
        )
        ..lineTo(sparkleCenter.dx, sparkleCenter.dy + sparkleRadius * 1.8)
        ..lineTo(
          sparkleCenter.dx - sparkleRadius * 0.55,
          sparkleCenter.dy + sparkleRadius * 0.5,
        )
        ..lineTo(sparkleCenter.dx - sparkleRadius * 1.8, sparkleCenter.dy)
        ..lineTo(
          sparkleCenter.dx - sparkleRadius * 0.55,
          sparkleCenter.dy - sparkleRadius * 0.5,
        )
        ..close(),
      sparkle,
    );
    canvas.drawCircle(
      center + Offset(-ringRadius * 0.78, ringRadius * 0.5),
      math.max(1.0, radius * 0.061),
      sparkle,
    );

    // 꾸미기 파티클은 물리 엔티티와 무관한 결정론적 장식이다. 모션 감소 시
    // 회전·맥동 없이 세 점만 남겨 외형 식별성은 보존한다.
    final particleCount = reducedMotion ? 3 : 7;
    final particlePhase = reducedMotion ? 0.0 : phase * 0.24;
    for (var index = 0; index < particleCount; index++) {
      final angle =
          -math.pi * 0.7 + index * math.pi * 2 / particleCount + particlePhase;
      final wave = reducedMotion ? 0.0 : math.sin(phase * 1.8 + index) * 1.4;
      final distance = ringRadius + math.max(3.2, radius * 0.18) + wave;
      final particleCenter =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final particleRadius = math.max(
        1.1,
        radius * (index.isEven ? 0.055 : 0.04),
      );
      canvas.drawCircle(
        particleCenter,
        particleRadius,
        Paint()
          ..color =
              (index.isEven ? const Color(0xFFFFD86B) : const Color(0xFF83FFF0))
                  .withValues(alpha: reducedMotion ? 0.72 : 0.86),
      );
    }
  }

  /// 생성 스프라이트 위에도 본체 색과 유광 재질을 적용한다.
  /// 원의 반지름은 렌더에만 쓰이며 게임 엔티티의 크기·히트박스를 바꾸지 않는다.
  static void drawRewardMaterialOverlay(
    Canvas canvas, {
    required Offset center,
    required double radius,
  }) {
    final bodyRadius = radius * 0.91;
    final bounds = Rect.fromCircle(center: center, radius: bodyRadius);
    canvas.save();
    canvas.clipPath(Path()..addOval(bounds));
    canvas.drawCircle(
      center,
      bodyRadius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.42, -0.52),
          radius: 1.05,
          colors: [Color(0x66F6FFCE), Color(0x9A24D7CA), Color(0xB8056669)],
          stops: [0.0, 0.58, 1.0],
        ).createShader(bounds),
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: bodyRadius * 0.7),
      -math.pi * 0.93,
      math.pi * 1.2,
      false,
      Paint()
        ..color = const Color(0xD6E8FFFA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, radius * 0.075)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawBall(
      canvas,
      center: Offset(size.width / 2, size.height / 2),
      radius: size.shortestSide * 0.42,
      trait: trait,
      drawShadow: true,
      rewardAppearance: rewardAppearance,
    );
    if (rewardAppearance) {
      drawRewardAppearance(
        canvas,
        center: Offset(size.width / 2, size.height / 2),
        radius: size.shortestSide * 0.42,
        reducedMotion: reducedMotion,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GameBallIconPainter oldDelegate) =>
      oldDelegate.trait != trait ||
      oldDelegate.rewardAppearance != rewardAppearance ||
      oldDelegate.reducedMotion != reducedMotion;
}

Color _traitBallColor(TraitType trait) {
  switch (trait) {
    case TraitType.heavy:
      return const Color(0xFF4D6572);
    case TraitType.bouncy:
      return const Color(0xFF2EAD74);
    case TraitType.sticky:
      return const Color(0xFF8D5BB8);
    case TraitType.sharp:
      return const Color(0xFFE47758);
  }
}
