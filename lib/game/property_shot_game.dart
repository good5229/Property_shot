import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/material.dart' hide Image;
import 'package:flutter/services.dart';

import 'domain/entity_state.dart';
import 'domain/game_state.dart';
import 'domain/geometry.dart';
import 'domain/trait.dart';
import 'levels/levels.dart';
import 'simulation/shot_resolver.dart';

enum GameViewMode { top, quarter }

class PropertyShotGame extends FlameGame {
  PropertyShotGame(this.state);

  GameState state;
  GameViewMode viewMode = GameViewMode.top;
  List<Vec2> _animationPath = const [];
  List<ShotAnimationMove> _animationMoves = const [];
  GameState? _animationStartState;
  double _animationCursor = 0;
  TraitType? _animationTrait;
  double _pulseClock = 0;
  final Map<EntityType, ui.Image> _objectImages = {};

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _objectImages[EntityType.crate] = await _loadUiImage(
      'assets/icons/crate.png',
    );
    _objectImages[EntityType.weight] = await _loadUiImage(
      'assets/icons/stone_boulder.png',
    );
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void setViewMode(GameViewMode mode) {
    viewMode = mode;
  }

  void setStateSnapshot(
    GameState next, {
    List<Vec2> path = const [],
    GameState? transitionStart,
    List<ShotAnimationMove> moves = const [],
  }) {
    state = next;
    if (path.length > 1) {
      _animationPath = path;
      _animationMoves = moves;
      _animationStartState = transitionStart;
      _animationCursor = 0;
      final spentBalls = next.entities.where(
        (entity) => entity.id.startsWith('spent_ball_'),
      );
      final traits = spentBalls.isEmpty
          ? const <TraitType>{}
          : spentBalls.last.traits;
      _animationTrait = traits.isEmpty ? next.equippedTrait : traits.first;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_animationPath.isNotEmpty) {
      _animationCursor += dt * 34;
      if (_animationCursor >= _animationPath.length - 1) {
        _animationPath = const [];
        _animationMoves = const [];
        _animationStartState = null;
        _animationTrait = null;
      }
    }
    _pulseClock += dt;
  }

  @override
  Color backgroundColor() => const Color(0xFFEBF2EC);

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final scale = _scaleFor(size);
    canvas.save();
    canvas.translate(
      (size.x - logicalSize.x * scale) / 2,
      (size.y - logicalSize.y * scale) / 2,
    );
    canvas.scale(scale);
    _drawBoard(canvas);
    if (state.phase == GamePhase.planning) _drawAimArrow(canvas);
    final animated = _animationPath.isNotEmpty;
    final entities = animated ? _animatedEntities() : state.entities;
    for (final entity in entities) {
      if (animated && entity.id == 'active_ball') {
        continue;
      }
      _drawEntity(canvas, entity, false);
    }
    if (animated) {
      _drawAnimatedBall(canvas);
    }
    canvas.restore();
  }

  List<EntityState> _animatedEntities() {
    final start = _animationStartState;
    if (start == null) {
      return state.entities;
    }
    return [
      for (final entity in start.entities) _entityAtAnimationTime(entity),
    ];
  }

  EntityState _entityAtAnimationTime(EntityState entity) {
    var animated = entity;
    for (final move in _animationMoves.where(
      (move) => move.entityId == entity.id,
    )) {
      final local = ((_animationCursor - move.triggerPathIndex) / 12).clamp(
        0.0,
        1.0,
      );
      final eased = Curves.easeOut.transform(local);
      animated = animated.copyWith(
        position: Vec2(
          move.from.x + (move.to.x - move.from.x) * eased,
          move.from.y + (move.to.y - move.from.y) * eased,
        ),
        visualState: local > 0 ? 'pushed' : entity.visualState,
      );
    }
    return animated;
  }

  double _scaleFor(Vector2 size) {
    return mathMin(size.x / logicalSize.x, size.y / logicalSize.y);
  }

  double get _viewAngleRadians => 45 * math.pi / 180;
  double get _viewXScale => viewMode == GameViewMode.quarter ? 0.88 : 1.0;
  double get _viewYScale =>
      viewMode == GameViewMode.quarter ? math.sin(_viewAngleRadians) : 1.0;
  double get _viewYOffset => viewMode == GameViewMode.quarter
      ? (logicalSize.y - logicalSize.y * _viewYScale) / 2
      : 0;
  double get _viewShear {
    if (viewMode != GameViewMode.quarter) {
      return 0;
    }
    final strength = math.cos(_viewAngleRadians) * 0.2;
    return strength * 0.7;
  }

  Offset get _blockDepth {
    if (viewMode != GameViewMode.quarter) {
      return Offset.zero;
    }
    final height = 10 + math.cos(_viewAngleRadians) * 28;
    final width = 6 + math.cos(_viewAngleRadians) * 12;
    return Offset(-width * 0.8, height);
  }

  Offset _project(Vec2 point) {
    final yOffset = (point.y - logicalSize.y / 2) * _viewShear;
    return Offset(
      logicalSize.x / 2 + (point.x - logicalSize.x / 2) * _viewXScale + yOffset,
      point.y * _viewYScale + _viewYOffset,
    );
  }

  Rect _projectedRect(EntityState entity) {
    final center = _project(entity.position);
    return Rect.fromCenter(
      center: center,
      width: entity.size.x * _viewXScale,
      height: entity.size.y * _viewYScale,
    );
  }

  List<Offset> _projectedEntityCorners(EntityState entity) {
    final bounds = entity.bounds;
    return [
      _project(Vec2(bounds.left, bounds.top)),
      _project(Vec2(bounds.right, bounds.top)),
      _project(Vec2(bounds.right, bounds.bottom)),
      _project(Vec2(bounds.left, bounds.bottom)),
    ];
  }

  Path _pathFromPoints(List<Offset> points) {
    return Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();
  }

  void _drawBoard(Canvas canvas) {
    final field = Paint()..color = const Color(0xFFBFEEC9);
    final border = Paint()
      ..color = const Color(0xFF5D8B62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final boardPath = _pathFromPoints([
      _project(const Vec2(0, 0)),
      _project(Vec2(logicalSize.x, 0)),
      _project(Vec2(logicalSize.x, logicalSize.y)),
      _project(Vec2(0, logicalSize.y)),
    ]);
    canvas.drawPath(boardPath, field);
    final tileLine = Paint()
      ..color = const Color(0x38FFFFFF)
      ..strokeWidth = 1;
    for (var x = 24.0; x < logicalSize.x; x += 36) {
      canvas.drawLine(
        _project(Vec2(x, 0)),
        _project(Vec2(x, logicalSize.y)),
        tileLine,
      );
    }
    for (var y = 24.0; y < logicalSize.y; y += 36) {
      canvas.drawLine(
        _project(Vec2(0, y)),
        _project(Vec2(logicalSize.x, y)),
        tileLine,
      );
    }
    final flower = Paint()..color = const Color(0xFFFFF2A8);
    for (final dot in const [
      Vec2(44, 86),
      Vec2(318, 174),
      Vec2(72, 328),
      Vec2(286, 448),
      Vec2(184, 512),
    ]) {
      canvas.drawCircle(_project(dot), 2.6, flower);
    }
    canvas.drawPath(boardPath, border);
  }

  void _drawAimArrow(Canvas canvas) {
    final ball = state.activeBall;
    final direction = state.aimDirection.normalized();
    final start = ball.position;
    final length = 46 + state.aimPower * 80;
    final end = start + direction * length;
    final arrowPaint = Paint()
      ..color = const Color(0xFFE23D3D)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(_project(start), _project(end), arrowPaint);

    final left = Vec2(
      -direction.x * 0.72 - direction.y * 0.38,
      -direction.y * 0.72 + direction.x * 0.38,
    );
    final right = Vec2(
      -direction.x * 0.72 + direction.y * 0.38,
      -direction.y * 0.72 - direction.x * 0.38,
    );
    canvas.drawLine(_project(end), _project(end + left * 24), arrowPaint);
    canvas.drawLine(_project(end), _project(end + right * 24), arrowPaint);

    final gaugePaint = Paint()
      ..color = const Color(0xFFE23D3D)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: _project(start), radius: ball.radius + 12),
      -1.57,
      state.aimPower * 6.28,
      false,
      gaugePaint,
    );
  }

  void _drawEntity(Canvas canvas, EntityState entity, bool highlighted) {
    final paint = Paint()..color = _colorFor(entity);
    final stroke = Paint()
      ..color = highlighted ? const Color(0xFFFFC857) : const Color(0xFF24352D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 5 : 2;

    if (entity.isCircle) {
      final center = _project(entity.position);
      if (viewMode == GameViewMode.quarter && entity.type == EntityType.ball) {
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(5, entity.radius * 0.82),
            width: entity.radius * 1.8,
            height: entity.radius * 0.55,
          ),
          Paint()..color = const Color(0x33000000),
        );
      }
      if (entity.type == EntityType.ball &&
          state.phase == GamePhase.planning &&
          entity.id == 'active_ball' &&
          _animationPath.isEmpty) {
        _drawBallPulse(canvas, entity);
      }
      if (entity.traits.isNotEmpty &&
          state.phase == GamePhase.planning &&
          _animationPath.isEmpty) {
        _drawSelectablePulse(canvas, entity);
      }
      if (entity.type == EntityType.hole) {
        _drawHoleFlag(canvas, entity);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: (entity.radius + 6) * 2,
            height: (entity.radius + 6) * 2 * _viewYScale,
          ),
          Paint()
            ..color = const Color(0x5572C978)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      if (entity.type == EntityType.ball && entity.traits.isNotEmpty) {
        canvas.drawCircle(
          center,
          entity.radius + 7,
          Paint()
            ..color = _traitColor(entity.traits.first).withValues(alpha: 0.26)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }
      if (entity.type == EntityType.hole) {
        final oval = Rect.fromCenter(
          center: center,
          width: entity.radius * 2,
          height: entity.radius * 2 * _viewYScale,
        );
        canvas.drawOval(oval, paint);
        canvas.drawOval(oval, stroke);
      } else {
        _drawBallSphere(canvas, entity, paint, stroke);
      }
      if (entity.type == EntityType.ball) {
        _drawBallFace(canvas, entity);
      }
    } else {
      final rect = _projectedRect(entity);
      final topPoints = _projectedEntityCorners(entity);
      final topPath = _pathFromPoints(topPoints);
      canvas.drawPath(
        topPath.shift(const Offset(5, 7)),
        Paint()..color = const Color(0x3F503C2E),
      );
      if (viewMode == GameViewMode.quarter) {
        _drawBlockSide(canvas, entity, topPoints);
      }
      if (entity.traits.isNotEmpty &&
          state.phase == GamePhase.planning &&
          _animationPath.isEmpty) {
        _drawSelectablePulse(canvas, entity);
      }
      if (entity.type == EntityType.bumper && entity.visualState == 'pushed') {
        _drawJellyBounce(canvas, entity, topPath, paint, stroke);
      } else {
        canvas.drawPath(topPath, paint);
        canvas.drawPath(topPath, stroke);
      }
      if (!_drawObjectImage(canvas, entity, rect, topPath)) {
        _drawCuteBlockDetails(canvas, entity, rect, topPath);
      }
      _drawTraitTexture(canvas, entity, rect);
    }

    _drawEntityIcon(canvas, entity);
  }

  void _drawSelectablePulse(Canvas canvas, EntityState entity) {
    final pulse = (math.sin(_pulseClock * math.pi * 1.05) + 1) / 2;
    final paint = Paint()
      ..color = _traitColor(
        entity.traits.first,
      ).withValues(alpha: 0.18 + pulse * 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + pulse * 2;
    if (entity.isCircle) {
      canvas.drawCircle(
        _project(entity.position),
        entity.radius + 10 + pulse * 5,
        paint,
      );
      return;
    }
    final rect = _projectedRect(entity).inflate(7 + pulse * 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      paint,
    );
  }

  void _drawJellyBounce(
    Canvas canvas,
    EntityState entity,
    Path topPath,
    Paint paint,
    Paint stroke,
  ) {
    final center = _project(entity.position);
    final wobble = math.sin(_pulseClock * math.pi * 8).abs();
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(1.16 + wobble * 0.12, 0.78 - wobble * 0.08);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawPath(topPath, paint);
    canvas.drawPath(topPath, stroke);
    canvas.restore();

    final splash = Paint()
      ..color = const Color(0x664EAF7C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final offset in const [
      Offset(-22, -10),
      Offset(22, -8),
      Offset(-18, 12),
      Offset(18, 14),
    ]) {
      canvas.drawArc(
        Rect.fromCenter(
          center: center + offset,
          width: 14 + wobble * 8,
          height: 8 + wobble * 4,
        ),
        0.2,
        math.pi * 0.8,
        false,
        splash,
      );
    }
  }

  void _drawBallPulse(Canvas canvas, EntityState entity) {
    final center = _project(entity.position);
    final wave = (math.sin(_pulseClock * math.pi * 1.15) + 1) / 2;
    final radius = entity.radius + 10 + wave * 7;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Color.lerp(
          const Color(0x00E23D3D),
          const Color(0x55E23D3D),
          1 - wave,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawBallSphere(
    Canvas canvas,
    EntityState entity,
    Paint paint,
    Paint stroke,
  ) {
    final center = _project(entity.position);
    final radius = entity.radius;
    final gradient = RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 0.95,
      colors: [
        Colors.white.withValues(alpha: 0.95),
        paint.color,
        Color.lerp(paint.color, const Color(0xFF152018), 0.28)!,
      ],
      stops: const [0.0, 0.58, 1.0],
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
    canvas.drawCircle(center, radius, stroke);
  }

  void _drawBallFace(Canvas canvas, EntityState entity) {
    final eye = Paint()..color = const Color(0xFF3B302A);
    final blush = Paint()..color = const Color(0x44FF8EA1);
    final c = _project(entity.position);
    canvas.drawCircle(Offset(c.dx - 5, c.dy - 3), 1.8, eye);
    canvas.drawCircle(Offset(c.dx + 5, c.dy - 3), 1.8, eye);
    canvas.drawCircle(Offset(c.dx - 8, c.dy + 4), 2.6, blush);
    canvas.drawCircle(Offset(c.dx + 8, c.dy + 4), 2.6, blush);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 1), width: 8, height: 6),
      0.15,
      2.84,
      false,
      Paint()
        ..color = const Color(0xFF3B302A)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(c.dx - 5, c.dy - 7),
      3,
      Paint()..color = const Color(0x88FFFFFF),
    );
  }

  void _drawHoleFlag(Canvas canvas, EntityState entity) {
    final center = _project(entity.position);
    final pole = Paint()
      ..color = const Color(0xFF6B4B35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(5, -4), center.translate(5, -34), pole);
    final flag = Path()
      ..moveTo(center.dx + 6, center.dy - 34)
      ..lineTo(center.dx + 25, center.dy - 27)
      ..lineTo(center.dx + 6, center.dy - 20)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFF6B6B));
    canvas.drawPath(
      flag,
      Paint()
        ..color = const Color(0xFF7A3E33)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawBlockSide(Canvas canvas, EntityState entity, List<Offset> top) {
    if (entity.type == EntityType.switchPad) {
      return;
    }
    final depth = _blockDepth;
    final baseColor = _colorFor(entity);
    final faces = [
      _blockFace(top[0], top[1], depth, baseColor.withValues(alpha: 0.28)),
      _blockFace(top[1], top[2], depth, baseColor.withValues(alpha: 0.46)),
      _blockFace(top[2], top[3], depth, baseColor.withValues(alpha: 0.64)),
      _blockFace(top[3], top[0], depth, baseColor.withValues(alpha: 0.38)),
    ];
    for (final face in faces) {
      canvas.drawPath(face.path, Paint()..color = face.color);
      canvas.drawPath(
        face.path,
        Paint()
          ..color = const Color(0x553B302A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.1,
      );
    }
  }

  _BlockFace _blockFace(Offset a, Offset b, Offset depth, Color color) {
    return _BlockFace(
      Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..lineTo(b.dx + depth.dx, b.dy + depth.dy)
        ..lineTo(a.dx + depth.dx, a.dy + depth.dy)
        ..close(),
      color,
    );
  }

  bool _drawObjectImage(
    Canvas canvas,
    EntityState entity,
    Rect rect,
    Path topPath,
  ) {
    final image = _objectImages[entity.type];
    if (image == null) {
      return false;
    }
    final inset = entity.type == EntityType.weight ? 2.0 : 4.0;
    final destination = rect.deflate(inset);
    canvas.save();
    canvas.clipPath(topPath);
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
    canvas.drawPath(
      topPath,
      Paint()
        ..color = const Color(0x5524352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    return true;
  }

  void _drawEntityIcon(Canvas canvas, EntityState entity) {
    final center = _project(entity.position);
    switch (entity.type) {
      case EntityType.ball:
      case EntityType.hole:
      case EntityType.wall:
        return;
      case EntityType.crate:
        if (_objectImages.containsKey(EntityType.crate)) {
          return;
        }
        final ribbon = Paint()
          ..color = const Color(0x88FFFFFF)
          ..strokeWidth = 2;
        canvas.drawLine(
          center.translate(-11, 0),
          center.translate(11, 0),
          ribbon,
        );
        canvas.drawLine(
          center.translate(0, -11 * _viewYScale),
          center.translate(0, 11 * _viewYScale),
          ribbon,
        );
      case EntityType.weight:
        if (_objectImages.containsKey(EntityType.weight)) {
          return;
        }
        canvas.drawCircle(
          center.translate(0, -4),
          9,
          Paint()..color = const Color(0xFF3E515D),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center.translate(0, 4),
              width: 30,
              height: 18 * _viewYScale,
            ),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFF5F7582),
        );
      case EntityType.bumper:
        canvas.drawCircle(
          center,
          12,
          Paint()
            ..color = const Color(0x55FFFFFF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      case EntityType.stickySurface:
        final dot = Paint()..color = const Color(0x99FFFFFF);
        canvas.drawCircle(center.translate(-8, -4), 4, dot);
        canvas.drawCircle(center.translate(7, 5), 5, dot);
      case EntityType.switchPad:
        canvas.drawCircle(
          center,
          8,
          Paint()
            ..color = entity.pressed
                ? const Color(0xFF2F9F68)
                : const Color(0xFFFFF2A8),
        );
      case EntityType.gate:
        final gatePaint = Paint()
          ..color = entity.open
              ? const Color(0x664EAF7C)
              : const Color(0xAA7A3E33)
          ..strokeWidth = 3;
        canvas.drawLine(
          center.translate(-7, -20),
          center.translate(-7, 20),
          gatePaint,
        );
        canvas.drawLine(
          center.translate(7, -20),
          center.translate(7, 20),
          gatePaint,
        );
    }
  }

  void _drawCuteBlockDetails(
    Canvas canvas,
    EntityState entity,
    Rect rect,
    Path topPath,
  ) {
    if (entity.type == EntityType.wall ||
        entity.type == EntityType.crate ||
        entity.type == EntityType.weight) {
      canvas.save();
      canvas.clipPath(topPath);
      canvas.drawRect(
        Rect.fromLTWH(rect.left - 8, rect.top, rect.width + 16, rect.height),
        Paint()..color = const Color(0x33FFFFFF),
      );
      canvas.restore();
    }
    if (entity.type == EntityType.wall) {
      canvas.save();
      canvas.clipPath(topPath);
      canvas.drawRect(
        Rect.fromLTWH(rect.left - 8, rect.top, rect.width + 16, 7),
        Paint()..color = const Color(0xFF72C978),
      );
      canvas.restore();
    }
    if (entity.type == EntityType.crate) {
      final line = Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 1.4;
      canvas.drawLine(rect.centerLeft, rect.centerRight, line);
      canvas.drawLine(rect.topCenter, rect.bottomCenter, line);
    }
  }

  Color _colorFor(EntityState entity) {
    if (entity.visualState == 'drained') {
      return const Color(0xFFD8D4C7);
    }
    switch (entity.type) {
      case EntityType.ball:
        if (entity.traits.isEmpty) {
          return const Color(0xFFFFFFFF);
        }
        return _traitColor(entity.traits.first);
      case EntityType.hole:
        return const Color(0xFF1D1D1D);
      case EntityType.wall:
        return const Color(0xFF6E7F80);
      case EntityType.crate:
        return const Color(0xFFB7854B);
      case EntityType.bumper:
        return const Color(0xFF4EAF7C);
      case EntityType.stickySurface:
        return const Color(0xFF8E5AA9);
      case EntityType.weight:
        return const Color(0xFF4A5B66);
      case EntityType.switchPad:
        return entity.pressed
            ? const Color(0xFF4EAF7C)
            : const Color(0xFFE2C044);
      case EntityType.gate:
        return entity.open ? const Color(0x664EAF7C) : const Color(0xFFC24E3A);
    }
  }

  Color _traitColor(TraitType trait) {
    switch (trait) {
      case TraitType.heavy:
        return const Color(0xFF4D6572);
      case TraitType.bouncy:
        return const Color(0xFF2EAD74);
      case TraitType.sticky:
        return const Color(0xFF8D5BB8);
    }
  }

  void _drawTraitTexture(Canvas canvas, EntityState entity, Rect rect) {
    if (entity.traits.isEmpty || entity.visualState == 'drained') {
      return;
    }
    final trait = entity.traits.first;
    final texture = Paint()
      ..color = const Color(0xBFFFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    switch (trait) {
      case TraitType.heavy:
        for (var x = rect.left + 6; x < rect.right; x += 10) {
          canvas.drawLine(
            Offset(x, rect.top + 4),
            Offset(x - 12, rect.bottom - 4),
            texture,
          );
        }
      case TraitType.bouncy:
        for (var inset = 7.0; inset < rect.shortestSide / 2; inset += 9) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              rect.deflate(inset),
              const Radius.circular(12),
            ),
            texture,
          );
        }
      case TraitType.sticky:
        final fill = Paint()..color = const Color(0x8AFFFFFF);
        for (var y = rect.top + 9; y < rect.bottom; y += 14) {
          canvas.drawCircle(Offset(rect.left + 12, y), 3, fill);
          canvas.drawCircle(Offset(rect.right - 14, y + 5), 4, fill);
        }
    }
  }

  void _drawAnimatedBall(Canvas canvas) {
    final index = _animationCursor.floor().clamp(0, _animationPath.length - 1);
    final nextIndex = (index + 1).clamp(0, _animationPath.length - 1);
    final t = _animationCursor - index;
    final from = _animationPath[index];
    final to = _animationPath[nextIndex];
    final position = Vec2(
      from.x + (to.x - from.x) * t,
      from.y + (to.y - from.y) * t,
    );
    final trait = _animationTrait;
    final trailPaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= 4; i++) {
      final trailIndex = (index - i * 2).clamp(0, _animationPath.length - 1);
      final trail = _project(_animationPath[trailIndex]);
      canvas.drawCircle(trail, (6 - i).toDouble(), trailPaint);
    }
    _drawCueStrike(canvas, index, position);
    for (final move in _animationMoves) {
      final pulse = (_animationCursor - move.triggerPathIndex).abs();
      if (pulse < 5) {
        final impact = _project(
          _animationPath[move.triggerPathIndex.clamp(
            0,
            _animationPath.length - 1,
          )],
        );
        canvas.drawCircle(
          impact,
          18 - pulse * 2.2,
          Paint()
            ..color = const Color(0x66FFDE59)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
    final entity = EntityState(
      id: '움직이는_공',
      type: EntityType.ball,
      position: position,
      size: const Vec2(24, 24),
      traits: trait == null ? const {} : {trait},
      movable: true,
      visualState: 'moving',
    );
    _drawEntity(canvas, entity, false);
  }

  void _drawCueStrike(Canvas canvas, int index, Vec2 position) {
    if (index > 14 || _animationPath.length < 3) {
      return;
    }
    final start = _animationPath.first;
    final next = _animationPath[2];
    final direction = (next - start).normalized();
    final center = _project(position);
    final back = _project(position - direction * (48 - index * 2.4));
    final tip = _project(position - direction * 14);
    final cuePaint = Paint()
      ..color = const Color(0xFF8B5B32)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(back, tip, cuePaint);
    canvas.drawLine(
      back.translate(-2, -2),
      tip.translate(-2, -2),
      Paint()
        ..color = const Color(0xAAFFD18A)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
    final burst = Paint()
      ..color = const Color(0x88FFF2A8)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final angle in const [-0.65, 0.0, 0.65]) {
      final rotated = Vec2(
        direction.x * math.cos(angle) - direction.y * math.sin(angle),
        direction.x * math.sin(angle) + direction.y * math.cos(angle),
      );
      final from = center + Offset(rotated.x, rotated.y) * 8;
      final to = center + Offset(rotated.x, rotated.y) * (22 - index * 0.7);
      canvas.drawLine(from, to, burst);
    }
  }
}

class _BlockFace {
  const _BlockFace(this.path, this.color);

  final Path path;
  final Color color;
}

double mathMin(double a, double b) => math.min(a, b);
