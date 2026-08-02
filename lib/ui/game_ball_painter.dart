import 'package:flutter/material.dart';

import '../game/domain/trait.dart';

class GameBallIconPainter extends CustomPainter {
  const GameBallIconPainter(this.trait);

  final TraitType? trait;

  static void drawBall(
    Canvas canvas, {
    required Offset center,
    required double radius,
    TraitType? trait,
    bool drawShadow = false,
  }) {
    final baseColor = trait == null ? Colors.white : _traitBallColor(trait);
    final gradient = RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 0.96,
      colors: [
        Colors.white.withValues(alpha: 0.98),
        baseColor,
        Color.lerp(baseColor, const Color(0xFF152018), 0.22)!,
      ],
      stops: const [0.0, 0.58, 1.0],
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
        ..color = const Color(0xFF24352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.075,
    );

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

  @override
  void paint(Canvas canvas, Size size) {
    drawBall(
      canvas,
      center: Offset(size.width / 2, size.height / 2),
      radius: size.shortestSide * 0.42,
      trait: trait,
      drawShadow: true,
    );
  }

  @override
  bool shouldRepaint(covariant GameBallIconPainter oldDelegate) =>
      oldDelegate.trait != trait;
}

Color _traitBallColor(TraitType trait) {
  switch (trait) {
    case TraitType.heavy:
      return const Color(0xFF4D6572);
    case TraitType.bouncy:
      return const Color(0xFF2EAD74);
    case TraitType.sticky:
      return const Color(0xFF8D5BB8);
  }
}
