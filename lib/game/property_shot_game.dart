import 'dart:async';
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

class PropertyShotGame extends FlameGame {
  PropertyShotGame(
    this.state, {
    this.onAnimationFinished,
    this.onAnimationImpact,
  });

  GameState state;
  final VoidCallback? onAnimationFinished;
  final ValueChanged<ShotAnimationMove>? onAnimationImpact;
  List<Vec2> _animationPath = const [];
  List<ShotAnimationMove> _animationMoves = const [];
  GameState? _animationStartState;
  double _animationCursor = 0;
  TraitType? _animationTrait;
  double _pulseClock = 0;
  Timer? _animationCompletionTimer;
  final Set<String> _reportedImpactKeys = <String>{};
  final Map<EntityType, ui.Image> _objectImages = {};

  // 화면 전체가 같은 방향에서 비추는 듯 보이도록 광원 기준을 고정한다.
  static const Offset _lightDirection = Offset(-0.72, -0.69);
  static const Color _lightColor = Color(0xB8FFF4D6);
  static const Color _occlusionColor = Color(0x4A24352D);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _objectImages[EntityType.crate] = await _loadUiImage(
      'assets/generated/crate-v2.png',
    );
    _objectImages[EntityType.weight] = await _loadUiImage(
      'assets/generated/stone-v2.png',
    );
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void setStateSnapshot(
    GameState next, {
    List<Vec2> path = const [],
    GameState? transitionStart,
    List<ShotAnimationMove> moves = const [],
    bool animationTransaction = false,
  }) {
    state = next;
    if (path.length > 1) {
      _animationCompletionTimer?.cancel();
      _animationPath = path;
      _animationMoves = moves;
      _animationStartState = transitionStart;
      _animationCursor = 0;
      _reportedImpactKeys.clear();
      final spentBalls = next.entities.where(
        (entity) => entity.id.startsWith('spent_ball_'),
      );
      final traits = spentBalls.isEmpty
          ? const <TraitType>{}
          : spentBalls.last.traits;
      _animationTrait = traits.isEmpty ? next.equippedTrait : traits.first;
      _animationCompletionTimer = Timer(
        Duration(
          milliseconds: ((_animationEndCursor / 34) * 1000 + 120).ceil(),
        ),
        _finishAnimation,
      );
    } else if (animationTransaction) {
      Future<void>.microtask(() => onAnimationFinished?.call());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_animationPath.isNotEmpty) {
      // A background-resume frame must not skip an entire collision beat.
      final boundedDt = dt > 0.5
          ? (_animationEndCursor - _animationCursor) / 34
          : dt.clamp(0.0, 1 / 30).toDouble();
      _animationCursor += boundedDt * 34;
      for (var index = 0; index < _animationMoves.length; index++) {
        final move = _animationMoves[index];
        final key = '$index:${move.entityId}:${move.triggerPathIndex}';
        if (move.triggerPathIndex <= _animationCursor &&
            _reportedImpactKeys.add(key)) {
          onAnimationImpact?.call(move);
        }
      }
      if (_animationCursor >= _animationEndCursor) {
        _finishAnimation();
      }
    }
    _pulseClock += dt;
  }

  void _finishAnimation() {
    if (_animationPath.isEmpty) {
      return;
    }
    _animationCompletionTimer?.cancel();
    _animationCompletionTimer = null;
    _animationPath = const [];
    _animationMoves = const [];
    _animationStartState = null;
    _animationTrait = null;
    onAnimationFinished?.call();
  }

  @override
  void onRemove() {
    _animationCompletionTimer?.cancel();
    super.onRemove();
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
      _drawImpactFeedback(canvas);
    }
    canvas.restore();
  }

  void _drawImpactFeedback(Canvas canvas) {
    for (final move in _animationMoves) {
      final elapsed = _animationCursor - move.triggerPathIndex;
      if (elapsed < 0 || elapsed > 16) {
        continue;
      }
      final progress = (elapsed / 16).clamp(0.0, 1.0);
      final center = _project(move.impactPosition ?? move.from);
      final target = _animationStartState?.entities.where(
        (entity) => entity.id == move.entityId,
      );
      final targetType = target == null || target.isEmpty
          ? EntityType.ball
          : target.first.type;
      final accent = switch (targetType) {
        EntityType.bumper => const Color(0xFF4EAF7C),
        EntityType.stickySurface => const Color(0xFF8E5AA9),
        EntityType.crate => const Color(0xFFC4864E),
        EntityType.weight => const Color(0xFF6E8794),
        EntityType.switchPad => const Color(0xFFE2C044),
        EntityType.gate => const Color(0xFFE36B5D),
        EntityType.wall => const Color(0xFF7A9693),
        _ => const Color(0xFFFFF2A8),
      };
      final ring = Paint()
        ..color = Color.lerp(
          accent.withValues(alpha: 0.88),
          accent.withValues(alpha: 0),
          progress,
        )!
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            (targetType == EntityType.stickySurface ? 5 : 3.5) *
                (1 - progress) +
            1;
      canvas.drawCircle(center, 8 + progress * 24, ring);
      final spark = Paint()
        ..color = accent.withValues(alpha: 0.7)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      final sparkCount = targetType == EntityType.stickySurface ? 6 : 4;
      final impactNormal = move.impactNormal?.normalized();
      final baseAngle = impactNormal == null
          ? -math.pi / 2
          : math.atan2(impactNormal.y, impactNormal.x);
      for (var index = 0; index < sparkCount; index++) {
        final angle = baseAngle + (index - (sparkCount - 1) / 2) * 0.42;
        final inner = center + Offset(math.cos(angle), math.sin(angle)) * 9;
        final outer =
            center +
            Offset(math.cos(angle), math.sin(angle)) * (14 + progress * 12);
        canvas.drawLine(inner, outer, spark);
      }
      if (move.visualState == 'wall_hit' && impactNormal != null) {
        final tangent = Offset(-impactNormal.y, impactNormal.x);
        final flash = Paint()
          ..color = accent.withValues(alpha: 0.82 * (1 - progress))
          ..strokeWidth = 4 * (1 - progress) + 1
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          center - tangent * (18 + progress * 8),
          center + tangent * (18 + progress * 8),
          flash,
        );
      }
      if (targetType == EntityType.crate || targetType == EntityType.weight) {
        final shard = Paint()
          ..color = accent.withValues(alpha: 0.72 * (1 - progress))
          ..style = PaintingStyle.fill;
        for (var index = 0; index < 3; index++) {
          final angle = index * math.pi * 0.7 - 0.8;
          final shardCenter =
              center +
              Offset(math.cos(angle), math.sin(angle)) * (16 + progress * 10);
          canvas.drawRect(
            Rect.fromCenter(center: shardCenter, width: 3, height: 3),
            shard,
          );
        }
      }
    }
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
    final moves =
        _animationMoves.where((move) => move.entityId == entity.id).toList()
          ..sort(
            (first, second) =>
                first.triggerPathIndex.compareTo(second.triggerPathIndex),
          );
    for (final move in moves) {
      final elapsed = _animationCursor - move.triggerPathIndex;
      if (elapsed < 0) {
        continue;
      }
      final duration = _moveDuration(move);
      final local = (elapsed / duration).clamp(0.0, 1.0);
      final position = _sampleMovePath(move, elapsed);
      animated = animated.copyWith(
        position: position,
        visualState: local > 0 ? move.visualState : entity.visualState,
      );
    }
    return animated;
  }

  double _moveDuration(ShotAnimationMove move) {
    if (move.path.length < 2) {
      return 12;
    }
    // Each path sample represents one simulation step. This keeps
    // triggerPathIndex as the shared physical clock for every moving entity.
    return math.max(1, move.path.length - 1).toDouble();
  }

  double get _animationEndCursor {
    var end = math.max(0, _animationPath.length - 1).toDouble();
    for (final move in _animationMoves) {
      end = math.max(end, move.triggerPathIndex + _moveDuration(move));
    }
    return end;
  }

  Vec2 _sampleMovePath(ShotAnimationMove move, double elapsed) {
    final points = move.path.length >= 2 ? move.path : [move.from, move.to];
    final clock = points.length == 2 ? elapsed / _moveDuration(move) : elapsed;
    return _samplePathAtTime(points, clock);
  }

  Vec2 _samplePathAtTime(List<Vec2> points, double elapsed) {
    if (points.length == 2) {
      final from = points.first;
      final to = points.last;
      final progress = elapsed.clamp(0.0, 1.0);
      return Vec2(
        from.x + (to.x - from.x) * progress,
        from.y + (to.y - from.y) * progress,
      );
    }
    final sample = elapsed.clamp(0.0, points.length - 1.0);
    final index = sample.floor();
    final local = sample - index;
    final from = points[index];
    final to = points[index + 1];
    return Vec2(
      from.x + (to.x - from.x) * local,
      from.y + (to.y - from.y) * local,
    );
  }

  double _pathDistance(List<Vec2> points) {
    var distance = 0.0;
    for (var index = 1; index < points.length; index++) {
      distance += points[index - 1].distanceTo(points[index]);
    }
    return distance;
  }

  double _scaleFor(Vector2 size) {
    return mathMin(size.x / logicalSize.x, size.y / logicalSize.y);
  }

  Offset _project(Vec2 point) {
    return Offset(point.x, point.y);
  }

  Rect _projectedRect(EntityState entity) {
    final center = _project(entity.position);
    return Rect.fromCenter(
      center: center,
      width: entity.size.x,
      height: entity.size.y,
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
    final fieldShadow = Paint()..color = const Color(0x25503C2E);
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
    canvas.drawPath(boardPath.shift(const Offset(0, 5)), fieldShadow);
    final fieldGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFD8F5D8), Color(0xFFB8E8C8), Color(0xFFA9DEC0)],
        stops: [0.0, 0.56, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, logicalSize.x, logicalSize.y));
    canvas.drawPath(boardPath, fieldGradient);
    canvas.save();
    canvas.clipPath(boardPath);
    final lawnStripe = Paint()..color = const Color(0x120F8A54);
    for (var y = 10.0; y < logicalSize.y; y += 28) {
      canvas.drawRect(Rect.fromLTWH(0, y, logicalSize.x, 12), lawnStripe);
    }
    final pebble = Paint()..color = const Color(0x22658E70);
    for (final dot in const [
      Vec2(28, 42),
      Vec2(338, 64),
      Vec2(42, 286),
      Vec2(330, 360),
      Vec2(154, 520),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: _project(dot), width: 10, height: 5),
        pebble,
      );
    }
    canvas.restore();
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
    final cornerLeaf = Paint()..color = const Color(0x6656A66A);
    for (final center in const [
      Vec2(18, 18),
      Vec2(342, 18),
      Vec2(18, 542),
      Vec2(342, 542),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: _project(center), width: 16, height: 7),
        cornerLeaf,
      );
    }
    canvas.drawPath(boardPath, border);
    canvas.drawRect(
      Rect.fromLTWH(5, 5, logicalSize.x - 10, logicalSize.y - 10),
      Paint()
        ..color = const Color(0x5572B77D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
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
        _drawGoalBeacon(canvas, entity);
        _drawHoleFlag(canvas, entity);
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: (entity.radius + 6) * 2,
            height: (entity.radius + 6) * 2,
          ),
          Paint()
            ..color = const Color(0x5572C978)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4,
        );
      }
      _drawCircularContactShadow(canvas, entity);
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
        _drawHoleSurface(canvas, entity, stroke);
      } else {
        _drawBallSphere(canvas, entity, paint, stroke);
        _drawBallTraitTexture(canvas, entity);
      }
      if (entity.type == EntityType.ball) {
        _drawBallFace(canvas, entity);
      }
    } else {
      final rect = _projectedRect(entity);
      final topPoints = _projectedEntityCorners(entity);
      final topPath = _pathFromPoints(topPoints);
      final litPaint = _materialPaint(entity, rect);
      final image = _objectImages[entity.type];
      if (image != null) {
        _drawMovingObjectSprite(canvas, entity, rect, image);
      } else {
        _drawContactShadow(canvas, entity, rect);
        _drawDepthFaces(canvas, entity, topPoints);
        if (entity.traits.isNotEmpty &&
            state.phase == GamePhase.planning &&
            _animationPath.isEmpty) {
          _drawSelectablePulse(canvas, entity);
        }
        if (entity.type == EntityType.bumper) {
          _drawJellyBody(canvas, entity, litPaint, stroke);
        } else if (entity.type == EntityType.stickySurface) {
          _drawStickySurface(canvas, entity, topPath, litPaint, stroke);
        } else if (entity.type == EntityType.switchPad) {
          _drawSwitchPad(canvas, entity, topPath, litPaint, stroke);
        } else if (entity.type == EntityType.gate &&
            entity.visualState == 'opening') {
          _drawGateOpening(canvas, entity, topPoints);
        } else {
          canvas.drawPath(topPath, litPaint);
          canvas.drawPath(topPath, stroke);
        }
        _drawCuteBlockDetails(canvas, entity, rect, topPath);
        _drawDirectionalLight(canvas, entity, rect, topPath);
      }
      _drawTraitTexture(canvas, entity, rect);
    }

    _drawEntityIcon(canvas, entity);
  }

  Paint _materialPaint(EntityState entity, Rect rect) {
    final base = _colorFor(entity);
    final highlight = Color.lerp(base, Colors.white, 0.24)!;
    final shade = Color.lerp(base, const Color(0xFF17231E), 0.24)!;
    return Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [highlight, base, shade],
        stops: const [0.0, 0.46, 1.0],
      ).createShader(rect.inflate(8));
  }

  void _drawContactShadow(Canvas canvas, EntityState entity, Rect rect) {
    final motion = _motionVisual(entity);
    final lift = math.max(0.0, -motion.bob);
    final shadow = Paint()
      ..color = Color.fromRGBO(48, 52, 42, 0.18 + motion.impact * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: rect.center.translate(0, rect.height * 0.47),
        width: rect.width * (0.72 + motion.impact * 0.08),
        height: math.max(3, rect.height * (0.16 - lift * 0.012)),
      ),
      shadow,
    );
  }

  void _drawCircularContactShadow(Canvas canvas, EntityState entity) {
    if (entity.type == EntityType.hole) {
      return;
    }
    final center = _project(entity.position);
    final shadow = Paint()
      ..color = const Color(0x3D30362E)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(2, entity.radius * 0.78),
        width: entity.radius * 1.65,
        height: math.max(3, entity.radius * 0.42),
      ),
      shadow,
    );
  }

  void _drawDepthFaces(
    Canvas canvas,
    EntityState entity,
    List<Offset> topPoints,
  ) {
    final depth = switch (entity.type) {
      EntityType.wall => 9.0,
      EntityType.gate => 8.0,
      EntityType.crate => 6.0,
      EntityType.weight => 6.0,
      EntityType.bumper => 4.0,
      EntityType.stickySurface => 3.0,
      EntityType.switchPad => 3.0,
      _ => 2.0,
    };
    final down = Offset(0, depth);
    final base = _colorFor(entity);
    final side = Paint()
      ..color = Color.lerp(base, const Color(0xFF17231E), 0.3)!;
    final end = Paint()
      ..color = Color.lerp(base, const Color(0xFF17231E), 0.46)!;
    final leftFace = Path()
      ..moveTo(topPoints[0].dx, topPoints[0].dy)
      ..lineTo(topPoints[3].dx, topPoints[3].dy)
      ..lineTo((topPoints[3] + down).dx, (topPoints[3] + down).dy)
      ..lineTo((topPoints[0] + down).dx, (topPoints[0] + down).dy)
      ..close();
    final rightFace = Path()
      ..moveTo(topPoints[1].dx, topPoints[1].dy)
      ..lineTo(topPoints[2].dx, topPoints[2].dy)
      ..lineTo((topPoints[2] + down).dx, (topPoints[2] + down).dy)
      ..lineTo((topPoints[1] + down).dx, (topPoints[1] + down).dy)
      ..close();
    canvas.drawPath(leftFace, side);
    canvas.drawPath(rightFace, end);
    canvas.drawLine(
      topPoints[3] + down,
      topPoints[2] + down,
      Paint()
        ..color = const Color(0x6624352D)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      topPoints[0] + down,
      topPoints[1] + down,
      Paint()
        ..color = const Color(0x4424352D)
        ..strokeWidth = 1.2,
    );
    if (entity.type == EntityType.wall) {
      final mortar = Paint()
        ..color = const Color(0x44505F5C)
        ..strokeWidth = 1.2;
      canvas.save();
      canvas.clipPath(_pathFromPoints(topPoints));
      for (var y = topPoints[0].dy + 10; y < topPoints[3].dy; y += 12) {
        canvas.drawLine(
          Offset(topPoints[0].dx, y),
          Offset(topPoints[1].dx, y),
          mortar,
        );
      }
      canvas.restore();
    }
  }

  void _drawDirectionalLight(
    Canvas canvas,
    EntityState entity,
    Rect rect,
    Path topPath,
  ) {
    final highlight = Paint()
      ..color = _lightColor.withValues(
        alpha: entity.type == EntityType.gate ? 0.36 : 0.28,
      )
      ..strokeWidth = entity.type == EntityType.wall ? 3 : 2
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()
      ..color = _occlusionColor.withValues(
        alpha: entity.type == EntityType.gate ? 0.5 : 0.34,
      )
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.clipPath(topPath);
    final lightOffset = Offset(
      _lightDirection.dx * rect.width * 0.08,
      _lightDirection.dy * rect.height * 0.08,
    );
    canvas.drawLine(
      rect.topLeft.translate(3, 3) + lightOffset,
      rect.topRight.translate(-3, 3) + lightOffset,
      highlight,
    );
    canvas.drawLine(
      rect.bottomLeft.translate(3, -3),
      rect.bottomRight.translate(-3, -3),
      shadow,
    );
    canvas.restore();
  }

  void _drawHoleSurface(Canvas canvas, EntityState entity, Paint stroke) {
    final center = _project(entity.position);
    final radius = entity.radius;
    final outer = Rect.fromCircle(center: center, radius: radius + 1);
    final inner = Rect.fromCircle(
      center: center.translate(0, 1.5),
      radius: radius - 2,
    );
    canvas.drawOval(
      outer,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.55),
          radius: 1,
          colors: const [
            Color(0xFF55605B),
            Color(0xFF1D2521),
            Color(0xFF050807),
          ],
          stops: const [0.0, 0.38, 1.0],
        ).createShader(outer),
    );
    canvas.drawOval(inner, Paint()..color = const Color(0xFF090D0B));
    canvas.drawArc(
      outer,
      math.pi * 1.03,
      math.pi * 0.92,
      false,
      Paint()
        ..color = const Color(0xB8FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(outer, stroke);
  }

  void _drawGoalBeacon(Canvas canvas, EntityState entity) {
    final center = _project(entity.position);
    final pulse = (math.sin(_pulseClock * math.pi * 1.4) + 1) / 2;
    canvas.drawCircle(
      center,
      entity.radius + 13 + pulse * 4,
      Paint()
        ..color = const Color(0x2257B96B)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final target = Paint()
      ..color = const Color(0x6657B96B).withValues(alpha: 0.4 - pulse * 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, entity.radius + 9 + pulse * 5, target);
    for (var index = 0; index < 4; index++) {
      final angle = index * math.pi / 2 + math.pi / 4;
      final from =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (entity.radius + 14);
      final to =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (entity.radius + 19 + pulse * 3);
      canvas.drawLine(from, to, target);
    }
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

  void _drawJellyBody(
    Canvas canvas,
    EntityState entity,
    Paint paint,
    Paint stroke,
  ) {
    final center = _project(entity.position);
    final motion = _motionVisual(entity);
    final wobble = motion.impact > 0 || entity.visualState == 'stuck'
        ? (math.sin(_pulseClock * math.pi * 8).abs())
        : 0.0;
    final width = entity.size.x * (1.0 + motion.impact * 0.18);
    final height = entity.size.y * (1.0 - motion.impact * 0.16);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(motion.rotation * 0.25);
    final blob = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(0, motion.bob),
        width: width,
        height: height,
      ),
      Radius.circular(math.min(width, height) * 0.38),
    );
    canvas.drawRRect(blob, paint);
    final inner = blob.deflate(math.min(width, height) * 0.08);
    canvas.drawRRect(
      inner,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: const [
            Color(0x66FFFFFF),
            Color(0x120FFFFF),
            Color(0x3D261832),
          ],
          stops: const [0.0, 0.42, 1.0],
        ).createShader(inner.outerRect),
    );
    final shine = Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(-width * 0.14, -height * 0.2 + motion.bob),
        width: width * 0.52,
        height: height * 0.42,
      ),
      math.pi * 1.05,
      math.pi * 0.62,
      false,
      shine,
    );
    canvas.drawRRect(blob, stroke);
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
          center: center + offset + Offset(0, motion.bob),
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

  void _drawMovingObjectSprite(
    Canvas canvas,
    EntityState entity,
    Rect rect,
    ui.Image image,
  ) {
    final center = _project(entity.position);
    final motion = _motionVisual(entity);
    final shadow = Paint()
      ..color = Color.fromRGBO(48, 52, 42, 0.22 + motion.impact * 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(0, entity.size.y * 0.44),
        width: entity.size.x * 0.86,
        height: entity.size.y * 0.22,
      ),
      shadow,
    );
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final sprite = rect.inflate(entity.type == EntityType.weight ? 2 : 1);
    canvas.save();
    canvas.translate(center.dx, center.dy + motion.bob);
    canvas.rotate(motion.rotation);
    canvas.scale(motion.scaleX, motion.scaleY);
    final target = Rect.fromCenter(
      center: Offset.zero,
      width: sprite.width,
      height: sprite.height,
    );
    final extrusion = entity.type == EntityType.weight ? 8.0 : 6.0;
    final extrusionPaint = Paint()
      ..colorFilter = const ColorFilter.mode(Color(0xFF17231E), BlendMode.srcIn)
      ..filterQuality = FilterQuality.high;
    for (var depth = extrusion; depth >= 2; depth -= 2) {
      canvas.drawImageRect(
        image,
        source,
        target.shift(Offset(0, depth)),
        extrusionPaint,
      );
    }
    final outlinePaint = Paint()
      ..colorFilter = const ColorFilter.mode(Color(0xFF24352D), BlendMode.srcIn)
      ..filterQuality = FilterQuality.high;
    for (final offset in const [
      Offset(-1.5, 0),
      Offset(1.5, 0),
      Offset(0, -1.5),
      Offset(0, 1.5),
    ]) {
      canvas.drawImageRect(image, source, target.shift(offset), outlinePaint);
    }
    canvas.drawImageRect(
      image,
      source,
      target,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        target,
        Radius.circular(entity.type == EntityType.weight ? 12 : 6),
      ),
    );
    canvas.drawRect(
      target,
      Paint()
        ..blendMode = BlendMode.srcATop
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF), Color(0x3D101A16)],
          stops: [0.0, 0.42, 1.0],
        ).createShader(target),
    );
    canvas.restore();
    canvas.restore();
    _drawSpriteGleam(canvas, entity, target, motion);
  }

  void _drawSpriteGleam(
    Canvas canvas,
    EntityState entity,
    Rect target,
    _MotionVisual motion,
  ) {
    if (entity.type == EntityType.weight) {
      return;
    }
    final center = _project(entity.position).translate(0, motion.bob);
    final gleam = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = entity.type == EntityType.weight ? 2.4 : 1.8
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(motion.rotation);
    canvas.scale(motion.scaleX, motion.scaleY);
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: target.width,
          height: target.height,
        ),
        Radius.circular(entity.type == EntityType.weight ? 12 : 6),
      ),
    );
    canvas.drawLine(
      Offset(-target.width * 0.34, -target.height * 0.34),
      Offset(target.width * 0.18, -target.height * 0.34),
      gleam,
    );
    canvas.restore();
  }

  _MotionVisual _motionVisual(EntityState entity) {
    final isCollisionState =
        entity.visualState == 'pushed' ||
        entity.visualState == 'wall_bounced' ||
        entity.visualState == 'stuck';
    if (_animationPath.isEmpty || !entity.movable) {
      if (!isCollisionState) {
        return const _MotionVisual();
      }
      final pulse = (math.sin(_pulseClock * math.pi * 2.2).abs());
      return _materialMotion(entity, pulse, 0, 0);
    }
    if (!entity.movable && !isCollisionState) {
      return const _MotionVisual();
    }
    ShotAnimationMove? move;
    for (final candidate in _animationMoves) {
      if (candidate.entityId != entity.id ||
          candidate.path.length < 2 ||
          candidate.triggerPathIndex > _animationCursor) {
        continue;
      }
      if (move == null || candidate.triggerPathIndex > move.triggerPathIndex) {
        move = candidate;
      }
    }
    if (move == null || move.path.length < 2) {
      return const _MotionVisual();
    }
    final duration = _moveDuration(move);
    final local = ((_animationCursor - move.triggerPathIndex) / duration).clamp(
      0.0,
      1.0,
    );
    if (local <= 0 || local >= 1) {
      return const _MotionVisual();
    }
    // Keep visual deformation on the same physical timeline as position;
    // easing here would make the sprite arrive before its collision sample.
    final progress = local;
    final delta = move.to - move.from;
    final distance = _pathDistance(move.path);
    final direction = delta.normalized();
    final angle = math.atan2(direction.y, direction.x);
    final roll =
        distance / math.max(entity.size.x, 1) * (direction.x < 0 ? -1 : 1);
    final elapsed = _animationCursor - move.triggerPathIndex;
    final previous = _samplePathAtTime(move.path, elapsed - 0.8);
    final current = _samplePathAtTime(move.path, elapsed);
    final speedRatio = ((current - previous).length / 4.0).clamp(0.0, 1.0);
    final impact = (math.sin(progress * math.pi) * 0.72 + speedRatio * 0.28)
        .clamp(0.0, 1.0);
    return _materialMotion(entity, impact, roll, angle);
  }

  _MotionVisual _materialMotion(
    EntityState entity,
    double impact,
    double roll,
    double angle,
  ) {
    switch (entity.type) {
      case EntityType.bumper:
        return _MotionVisual(
          rotation: angle * 0.12,
          scaleX: 1 + impact * 0.18,
          scaleY: 1 - impact * 0.16,
          bob: -impact * 2.8,
          impact: impact,
        );
      case EntityType.weight:
        return _MotionVisual(
          rotation: roll * 0.58,
          scaleX: 1 + impact * 0.035,
          scaleY: 1 - impact * 0.025,
          bob: -impact * 1.3,
          impact: impact,
        );
      case EntityType.crate:
        return _MotionVisual(
          rotation: roll * 0.32,
          scaleX: 1 + impact * 0.09,
          scaleY: 1 - impact * 0.07,
          bob: -impact * 2.1,
          impact: impact,
        );
      default:
        return _MotionVisual(
          rotation: angle * 0.08,
          scaleX: 1 + impact * 0.06,
          scaleY: 1 - impact * 0.045,
          bob: -impact * 2.5,
          impact: impact,
        );
    }
  }

  void _drawStickySurface(
    Canvas canvas,
    EntityState entity,
    Path topPath,
    Paint paint,
    Paint stroke,
  ) {
    final rect = _projectedRect(entity);
    final center = _project(entity.position);
    final pulse = (math.sin(_pulseClock * math.pi * 1.6) + 1) / 2;
    canvas.drawPath(topPath, paint);
    canvas.save();
    canvas.clipPath(topPath);
    final shine = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0x99FFFFFF),
          const Color(0x18FFFFFF),
          const Color(0x440D0712),
        ],
      ).createShader(rect);
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-rect.width * 0.16, -rect.height * 0.18),
        width: rect.width * 0.62,
        height: rect.height * 0.3,
      ),
      shine,
    );
    final droplet = Paint()
      ..color = const Color(0xBFFFFFFF)
      ..style = PaintingStyle.fill;
    for (var index = 0; index < 5; index++) {
      final x = rect.left + rect.width * (0.2 + index * 0.16);
      final y = rect.top + rect.height * (0.26 + (index.isEven ? 0.12 : 0.42));
      canvas.drawCircle(Offset(x, y), 2.2 + (index % 3) * 0.8, droplet);
    }
    canvas.restore();
    canvas.drawPath(topPath, stroke);
    if (entity.visualState == 'stuck') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect.inflate(5 + pulse * 2),
          const Radius.circular(12),
        ),
        Paint()
          ..color = const Color(0xA8F3D7FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 + pulse,
      );
    }
  }

  void _drawSwitchPad(
    Canvas canvas,
    EntityState entity,
    Path topPath,
    Paint paint,
    Paint stroke,
  ) {
    final center = _project(entity.position);
    final pressed = entity.pressed || entity.visualState == 'pressed';
    final pulse = pressed ? math.sin(_pulseClock * math.pi * 7).abs() : 0.0;
    canvas.drawPath(
      topPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pressed
              ? const [Color(0xFF8EE0A7), Color(0xFF318E5D)]
              : const [Color(0xFFFFE98D), Color(0xFFC79627)],
        ).createShader(_projectedRect(entity)),
    );
    canvas.drawPath(topPath, stroke);
    final plate = Paint()
      ..color = pressed ? const Color(0xFF2B7D52) : const Color(0xFF9E7420)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center.translate(0, pressed ? 3 : 0), 13, plate);
    canvas.drawCircle(
      center.translate(0, pressed ? 4 : 0),
      8 + pulse * 2,
      Paint()
        ..color = pressed ? const Color(0xFFB9FFD0) : const Color(0xFFFFF2A8),
    );
    canvas.drawCircle(
      center.translate(-3, -3 + (pressed ? 3 : 0)),
      2.2,
      Paint()..color = const Color(0xCCFFFFFF),
    );
  }

  void _drawGateOpening(
    Canvas canvas,
    EntityState entity,
    List<Offset> topPoints,
  ) {
    final center = _project(entity.position);
    final pulse = (math.sin(_pulseClock * math.pi * 5).abs());
    final width = entity.size.x;
    final height = entity.size.y;
    final gap = 6 + pulse * 12;
    final rail = Paint()
      ..color = const Color(0x66596B60)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(topPoints[0], topPoints[1], rail);
    canvas.drawLine(topPoints[3], topPoints[2], rail);
    final doorPaint = Paint()
      ..color = Color.lerp(
        const Color(0xFFC24E3A),
        const Color(0x774EAF7C),
        0.62 + pulse * 0.38,
      )!;
    final leftDoor = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(-gap, 0),
        width: width * 0.34,
        height: height,
      ),
      const Radius.circular(5),
    );
    final rightDoor = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(gap, 0),
        width: width * 0.34,
        height: height,
      ),
      const Radius.circular(5),
    );
    canvas.drawRRect(leftDoor, doorPaint);
    canvas.drawRRect(rightDoor, doorPaint);
    canvas.drawRRect(
      leftDoor,
      Paint()
        ..color = const Color(0x663B302A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawRRect(
      rightDoor,
      Paint()
        ..color = const Color(0x663B302A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final hinge = Paint()
      ..color = const Color(0xAA3B302A)
      ..style = PaintingStyle.fill;
    final leftHingeX = leftDoor.left;
    final rightHingeX = rightDoor.right;
    final upperHingeY = leftDoor.top + leftDoor.height * 0.22;
    final lowerHingeY = leftDoor.bottom - leftDoor.height * 0.22;
    canvas.drawCircle(Offset(leftHingeX, upperHingeY), 2.5, hinge);
    canvas.drawCircle(Offset(leftHingeX, lowerHingeY), 2.5, hinge);
    canvas.drawCircle(Offset(rightHingeX, upperHingeY), 2.5, hinge);
    canvas.drawCircle(Offset(rightHingeX, lowerHingeY), 2.5, hinge);
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

  void _drawBallTraitTexture(Canvas canvas, EntityState entity) {
    if (entity.traits.isEmpty) {
      return;
    }
    final center = _project(entity.position);
    final radius = entity.radius - 1.5;
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
    final pattern = Paint()
      ..color = const Color(0xBFFFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    switch (entity.traits.first) {
      case TraitType.heavy:
        for (var offset = -radius * 1.8; offset < radius * 1.8; offset += 9) {
          canvas.drawLine(
            center + Offset(offset - radius, -radius),
            center + Offset(offset + radius, radius),
            pattern,
          );
        }
      case TraitType.bouncy:
        for (var inset = 5.0; inset < radius; inset += 7) {
          canvas.drawCircle(center, radius - inset, pattern);
        }
      case TraitType.sticky:
        final drops = Paint()..color = const Color(0xBFFFFFFF);
        for (var index = 0; index < 5; index++) {
          final angle = index * math.pi * 0.48;
          canvas.drawCircle(
            center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.55),
            2.3,
            drops,
          );
        }
    }
    canvas.restore();
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
          center.translate(0, -11),
          center.translate(0, 11),
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
              height: 18,
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
        if (entity.visualState == 'stuck') {
          canvas.drawCircle(
            center,
            16,
            Paint()
              ..color = const Color(0x88FFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        }
      case EntityType.switchPad:
        final pulse = entity.pressed || entity.visualState == 'pressed'
            ? (math.sin(_pulseClock * math.pi * 7).abs())
            : 0.0;
        canvas.drawCircle(
          center,
          8 + pulse * 4,
          Paint()
            ..color = entity.pressed || entity.visualState == 'pressed'
                ? const Color(0xFF2F9F68)
                : const Color(0xFFFFF2A8),
        );
      case EntityType.gate:
        if (entity.visualState == 'opening') {
          return;
        }
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
    if (entity.type == EntityType.gate && entity.visualState != 'opening') {
      final detail = Paint()
        ..color = const Color(0x663B302A)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(rect.centerLeft, rect.centerRight, detail);
      canvas.drawCircle(
        rect.center,
        4,
        Paint()..color = const Color(0xCCFFE49B),
      );
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
    if (entity.type == EntityType.weight ||
        entity.traits.isEmpty ||
        entity.visualState == 'drained') {
      return;
    }
    final trait = entity.traits.first;
    final texture = Paint()
      ..color = const Color(0xBFFFFFFF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(entity.type == EntityType.weight ? 12 : 6),
      ),
    );
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
    canvas.restore();
  }

  void _drawAnimatedBall(Canvas canvas) {
    final index = _animationCursor.floor().clamp(0, _animationPath.length - 1);
    final position = _samplePathAtTime(_animationPath, _animationCursor);
    final trait = _animationTrait;
    final previous = _samplePathAtTime(_animationPath, _animationCursor - 1);
    final speedRatio = ((position - previous).length / 8.0).clamp(0.0, 1.0);
    final trailCount = 3 + (speedRatio * 4).round();
    final trailPaint = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i <= trailCount; i++) {
      final trail = _project(
        _samplePathAtTime(
          _animationPath,
          _animationCursor - i * (1.5 + speedRatio),
        ),
      );
      canvas.drawCircle(
        trail,
        math.max(1.3, 6 - i * 0.72),
        trailPaint
          ..color = const Color(
            0x55FFFFFF,
          ).withValues(alpha: (0.44 - i * 0.045).clamp(0.08, 0.44)),
      );
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

class _MotionVisual {
  const _MotionVisual({
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.bob = 0,
    this.impact = 0,
  });

  final double rotation;
  final double scaleX;
  final double scaleY;
  final double bob;
  final double impact;
}

double mathMin(double a, double b) => math.min(a, b);
