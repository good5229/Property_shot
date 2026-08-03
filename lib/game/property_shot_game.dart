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
import '../ui/game_ball_painter.dart';
import '../ui/debug_labels.dart';

class PropertyShotGame extends FlameGame {
  PropertyShotGame(
    this.state, {
    this.onAnimationFinished,
    this.onAnimationImpact,
    this.onShotImpact,
    this.onPhysicsEvent,
    this.loadVisualAssets = true,
    this.reducedMotion = false,
    this.screenShake = true,
  });

  GameState state;
  final VoidCallback? onAnimationFinished;
  final ValueChanged<ShotAnimationMove>? onAnimationImpact;
  final ValueChanged<ShotImpact>? onShotImpact;
  final ValueChanged<PhysicsEvent>? onPhysicsEvent;
  final bool loadVisualAssets;
  final bool reducedMotion;
  final bool screenShake;
  bool debugHitboxes = false;
  bool debugNormals = false;
  bool debugIds = false;
  bool debugStats = false;
  double lastFrameTimeMs = 0;

  void setDebugOptions({
    bool? hitboxes,
    bool? normals,
    bool? ids,
    bool? stats,
  }) {
    debugHitboxes = hitboxes ?? debugHitboxes;
    debugNormals = normals ?? debugNormals;
    debugIds = ids ?? debugIds;
    debugStats = stats ?? debugStats;
  }

  List<Vec2> _animationPath = const [];
  List<ShotAnimationMove> _animationMoves = const [];
  List<ShotImpact> _animationImpacts = const [];
  List<PhysicsEvent> _animationPhysicsEvents = const [];
  GameState? _animationStartState;
  double _animationCursor = 0;
  int _animationUpdateCount = 0;
  TraitType? _animationTrait;
  double _pulseClock = 0;
  Timer? _animationCompletionTimer;
  final Set<String> _reportedImpactKeys = <String>{};
  final Map<EntityType, ui.Image> _objectImages = {};
  final Map<String, _StaticEntityPicture> _staticEntityPictures = {};
  static const int _runtimeAssetDecodeSize = 256;
  static const FilterQuality _runtimeFilterQuality = FilterQuality.medium;

  // 화면 전체가 같은 방향에서 비추는 듯 보이도록 광원 기준을 고정한다.
  static const Offset _lightDirection = Offset(-0.72, -0.69);
  static const Color _lightColor = Color(0xB8FFF4D6);
  static const Color _occlusionColor = Color(0x4A24352D);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (!loadVisualAssets) {
      return;
    }
    final images = await Future.wait([
      _loadUiImage('assets/generated/crate-v2.png'),
      _loadUiImage('assets/generated/stone-v2.png'),
      _loadUiImage('assets/generated/jelly-bumper-v1.png'),
    ]);
    _objectImages[EntityType.crate] = images[0];
    _objectImages[EntityType.weight] = images[1];
    _objectImages[EntityType.bumper] = images[2];
  }

  Future<ui.Image> _loadUiImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: _runtimeAssetDecodeSize,
      targetHeight: _runtimeAssetDecodeSize,
    );
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  void setStateSnapshot(
    GameState next, {
    List<Vec2> path = const [],
    GameState? transitionStart,
    List<ShotAnimationMove> moves = const [],
    List<ShotImpact> impacts = const [],
    List<PhysicsEvent> physicsEvents = const [],
    bool animationTransaction = false,
  }) {
    state = next;
    if (path.length > 1) {
      _animationPath = path;
      _animationMoves = moves;
      _animationImpacts = impacts;
      _animationPhysicsEvents = physicsEvents.isEmpty
          ? buildPhysicsEvents(
              path: path,
              impacts: impacts,
              moves: moves,
              chainSafetyDiagnostics: const [],
            )
          : physicsEvents;
      _animationStartState = transitionStart;
      _animationCursor = 0;
      _animationUpdateCount = 0;
      _reportedImpactKeys.clear();
      final spentBalls = next.entities.where(
        (entity) => entity.id.startsWith('spent_ball_'),
      );
      final traits = spentBalls.isEmpty
          ? const <TraitType>{}
          : spentBalls.last.traits;
      _animationTrait = traits.isEmpty ? next.equippedTrait : traits.first;
      _scheduleAnimationCompletion();
    } else if (animationTransaction) {
      Future<void>.microtask(() => onAnimationFinished?.call());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    lastFrameTimeMs = dt * 1000;
    if (_animationPath.isNotEmpty) {
      _animationUpdateCount += 1;
      // A background-resume frame must not skip an entire collision beat.
      // 백그라운드 복귀로 생긴 큰 시간 간격은 건너뛰지 않는다.
      // 한 프레임에 남은 충돌을 모두 소비하면 물체 이동과 타격 피드백의
      // 인과가 사라지므로, 다음 정상 프레임부터 시간축을 이어간다.
      final boundedDt = dt > 0.5 ? 0.0 : dt.clamp(0.0, 1 / 30).toDouble();
      _animationCursor += boundedDt * 34;
      _emitDueAnimationEvents();
      if (_animationCursor >= _animationEndCursor) {
        _finishAnimation();
      }
    }
    _pulseClock += dt;
  }

  void _finishAnimation() {
    if (_animationPath.isEmpty || _animationCursor < _animationEndCursor) {
      return;
    }
    _animationCompletionTimer?.cancel();
    _animationCompletionTimer = null;
    _animationPath = const [];
    _animationMoves = const [];
    _animationImpacts = const [];
    _animationPhysicsEvents = const [];
    _animationStartState = null;
    _animationTrait = null;
    onAnimationFinished?.call();
  }

  void _scheduleAnimationCompletion() {
    _animationCompletionTimer?.cancel();
    final milliseconds = math.max(
      120,
      ((_animationEndCursor / 34) * 1000 + 120).ceil(),
    );
    _animationCompletionTimer = Timer(
      Duration(milliseconds: milliseconds),
      _pollAnimationCompletion,
    );
  }

  void _pollAnimationCompletion() {
    if (_animationPath.isEmpty) {
      return;
    }
    if (_animationCursor >= _animationEndCursor) {
      _finishAnimation();
      return;
    }
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (_animationUpdateCount == 0 &&
        (lifecycleState == null ||
            lifecycleState == AppLifecycleState.resumed)) {
      // Flame이 아직 첫 프레임도 전달하지 않은 테스트 호스트에서는
      // 기존 위젯 계약을 유지하기 위해 최후 보조 완료를 허용한다.
      _animationCursor = _animationEndCursor;
      _emitDueAnimationEvents();
      _finishAnimation();
      return;
    }
    // 벽시계는 화면 시간축을 진행할 수 없으므로 Flame update가 남은 경로를
    // 그려 커서를 끝까지 옮길 때까지 확인만 반복한다.
    _animationCompletionTimer = Timer(
      const Duration(milliseconds: 80),
      _pollAnimationCompletion,
    );
  }

  void _emitDueAnimationEvents() {
    final events = [..._animationPhysicsEvents]
      ..sort((left, right) {
        final byPath = left.pathIndex.compareTo(right.pathIndex);
        if (byPath != 0) {
          return byPath;
        }
        final byKind = left.kind.index.compareTo(right.kind.index);
        if (byKind != 0) {
          return byKind;
        }
        return left.eventId.compareTo(right.eventId);
      });

    for (final event in events) {
      if (event.pathIndex > _animationCursor ||
          !_reportedImpactKeys.add(event.eventId)) {
        continue;
      }
      onPhysicsEvent?.call(event);
      final impact = event.impact;
      if (impact != null) {
        onShotImpact?.call(impact);
      } else if (event.move != null) {
        onAnimationImpact?.call(event.move!);
      }
    }
  }

  @override
  void onRemove() {
    _animationCompletionTimer?.cancel();
    for (final image in _objectImages.values) {
      image.dispose();
    }
    _objectImages.clear();
    for (final cached in _staticEntityPictures.values) {
      cached.picture.dispose();
    }
    _staticEntityPictures.clear();
    super.onRemove();
  }

  @override
  Color backgroundColor() => const Color(0xFFBFE8E3);

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
    if (_animationPath.isNotEmpty) {
      _drawScreenShake(canvas);
    }
    _drawBoard(canvas);
    final animated = _animationPath.isNotEmpty;
    final renderEntities =
        [...(animated ? _animatedEntities() : state.entities)]
          ..sort((first, second) {
            final firstIsHole = first.type == EntityType.hole;
            final secondIsHole = second.type == EntityType.hole;
            if (firstIsHole == secondIsHole) {
              return 0;
            }
            return firstIsHole ? -1 : 1;
          });
    _drawStage4Relations(canvas, renderEntities);
    if (state.phase == GamePhase.planning) _drawAimArrow(canvas);
    for (final entity in renderEntities) {
      if (animated && entity.id == 'active_ball') {
        continue;
      }
      _drawEntityWithCache(canvas, entity, false, animated: animated);
    }
    if (animated) {
      _drawAnimatedBall(canvas);
      _drawImpactFeedback(canvas);
      _drawDirectImpactFeedback(canvas);
    }
    if (debugHitboxes || debugNormals || debugIds || debugStats) {
      _drawDebugOverlay(canvas, renderEntities);
    }
    canvas.restore();
  }

  void _drawDebugOverlay(Canvas canvas, List<EntityState> entities) {
    if (debugHitboxes) {
      final hitboxPaint = Paint()
        ..color = const Color(0xCCF44336)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      for (final entity in entities.where((entity) => entity.active)) {
        final hitBounds = entity.hitBounds;
        final rect = Rect.fromLTRB(
          hitBounds.left,
          hitBounds.top,
          hitBounds.right,
          hitBounds.bottom,
        );
        if (entity.isCircle) {
          canvas.drawOval(rect, hitboxPaint);
        } else {
          canvas.drawRect(rect, hitboxPaint);
        }
      }
    }
    if (debugNormals) {
      final normalPaint = Paint()
        ..color = const Color(0xFF0D47A1)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (final event in _animationPhysicsEvents) {
        if (event.pathIndex > _animationCursor ||
            event.kind != PhysicsEventKind.impact) {
          continue;
        }
        final from = _project(event.position);
        final normal = event.normal.normalized();
        final to = from + Offset(normal.x, normal.y) * 18;
        canvas.drawLine(from, to, normalPaint);
        canvas.drawCircle(to, 2.5, normalPaint);
      }
    }
    if (debugIds) {
      for (final entity in entities.where((entity) => entity.active)) {
        final painter = TextPainter(
          text: TextSpan(
            text: debugEntityLabel(entity.id),
            style: const TextStyle(
              color: Color(0xFF4A148C),
              fontSize: 7,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 90);
        painter.paint(canvas, _project(entity.position) + const Offset(4, -5));
      }
    }
    if (debugStats) {
      final stats = TextPainter(
        text: TextSpan(
          text:
              '프레임 ${lastFrameTimeMs.toStringAsFixed(2)}ms\n물리 이벤트 ${_animationPhysicsEvents.length}개',
          style: const TextStyle(
            color: Color(0xFF263238),
            fontSize: 9,
            fontWeight: FontWeight.w800,
            backgroundColor: Color(0xCCFFFFFF),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 130);
      stats.paint(canvas, const Offset(6, 6));
    }
  }

  void _drawScreenShake(Canvas canvas) {
    if (!screenShake || reducedMotion || _animationPhysicsEvents.isEmpty) {
      return;
    }
    PhysicsEvent? latestImpact;
    for (final event in _animationPhysicsEvents) {
      if (event.kind != PhysicsEventKind.impact ||
          event.pathIndex > _animationCursor) {
        continue;
      }
      if (latestImpact == null || event.pathIndex > latestImpact.pathIndex) {
        latestImpact = event;
      }
    }
    if (latestImpact == null) {
      return;
    }
    final elapsed = _animationCursor - latestImpact.pathIndex;
    if (elapsed < 0 || elapsed > 5) {
      return;
    }
    final strength = (latestImpact.impulse / 2.4).clamp(0.0, 1.0);
    final fade = 1 - (elapsed / 5).clamp(0.0, 1.0);
    final amplitude = 0.9 + strength * 1.8;
    canvas.translate(
      math.sin(elapsed * 5.6) * amplitude * fade,
      math.cos(elapsed * 6.4) * amplitude * fade,
    );
  }

  void _drawStage4Relations(Canvas canvas, List<EntityState> entities) {
    if (state.levelIndex != 3) {
      return;
    }
    EntityState? balloon;
    EntityState? balloonSwitch;
    EntityState? gate;
    for (final entity in entities) {
      if (entity.id == 'balloon') balloon = entity;
      if (entity.id == 'balloon_switch') balloonSwitch = entity;
      if (entity.id == 'balloon_gate') gate = entity;
    }
    if (balloon == null || balloonSwitch == null || gate == null) {
      return;
    }
    if (balloonSwitch.visualState != 'revealed' &&
        balloonSwitch.visualState != 'pressed') {
      return;
    }
    final paint = Paint()
      ..color = const Color(0xB8FFF0B0)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final balloonEdge = _project(
      Vec2(balloon.position.x, balloon.position.y - balloon.size.y / 2),
    );
    final switchEdge = _project(
      Vec2(
        balloonSwitch.position.x,
        balloonSwitch.position.y + balloonSwitch.size.y / 2,
      ),
    );
    final gateEdge = _project(
      Vec2(gate.position.x, gate.position.y + gate.size.y / 2),
    );
    _drawDashedRelation(canvas, balloonEdge, switchEdge, paint);
    _drawDashedRelation(canvas, switchEdge, gateEdge, paint);
    canvas.drawCircle(switchEdge, 4, Paint()..color = const Color(0xFFFFF2A8));
  }

  void _drawDashedRelation(Canvas canvas, Offset from, Offset to, Paint paint) {
    final delta = to - from;
    final distance = delta.distance;
    if (distance <= 1) {
      return;
    }
    final direction = delta / distance;
    for (double traveled = 0; traveled < distance; traveled += 10) {
      final start = from + direction * traveled;
      final end = from + direction * math.min(traveled + 5, distance);
      canvas.drawLine(start, end, paint);
    }
  }

  void _drawBalloonBurst(Canvas canvas, Offset center, double progress) {
    final paint = Paint()
      ..color = const Color(0xFFFFB45E).withValues(alpha: 0.9 * (1 - progress))
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final from = center + Offset(math.cos(angle), math.sin(angle)) * 7;
      final to =
          center +
          Offset(math.cos(angle), math.sin(angle)) * (20 + progress * 8);
      canvas.drawLine(from, to, paint);
    }
  }

  void _drawImpactFeedback(Canvas canvas) {
    for (final move in _animationMoves) {
      final elapsed = _animationCursor - move.triggerPathIndex;
      if (elapsed < 0 || elapsed > 16) {
        continue;
      }
      final progress = reducedMotion ? 0.55 : (elapsed / 16).clamp(0.0, 1.0);
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
        EntityType.balloon => const Color(0xFFF28A78),
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
      if (move.visualState == 'popped') {
        _drawBalloonBurst(canvas, center, progress);
      }
    }
  }

  void _drawDirectImpactFeedback(Canvas canvas) {
    for (final impact in _animationImpacts) {
      final elapsed = _animationCursor - impact.pathIndex;
      if (elapsed < 0 || elapsed > 14) {
        continue;
      }
      final progress = reducedMotion ? 0.55 : (elapsed / 14).clamp(0.0, 1.0);
      final center = _project(impact.position);
      final accent = switch (impact.entityType) {
        EntityType.hole => const Color(0xFFFFD76A),
        EntityType.wall || EntityType.gate => const Color(0xFFB9E3C4),
        EntityType.bumper => const Color(0xFF7BE7CC),
        EntityType.stickySurface => const Color(0xFFC7A2E8),
        EntityType.weight => const Color(0xFFB4CAD2),
        EntityType.crate => const Color(0xFFE9B866),
        EntityType.switchPad => const Color(0xFFFFE17C),
        EntityType.ball => const Color(0xFFFFF7D1),
        EntityType.balloon => const Color(0xFFFF9A87),
        EntityType.spikeSource => const Color(0xFFFFE49B),
      };
      final ring = Paint()
        ..color = accent.withValues(alpha: 0.82 * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 + impact.strength * 2;
      canvas.drawCircle(center, 8 + progress * 20 * impact.strength, ring);
      final normal = impact.normal.normalized();
      final flash = Paint()
        ..color = accent.withValues(alpha: 0.8 * (1 - progress))
        ..strokeWidth = 2 + impact.strength * 2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        center - Offset(normal.y, -normal.x) * (8 + progress * 7),
        center + Offset(normal.y, -normal.x) * (8 + progress * 7),
        flash,
      );
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
    final distance = _pathDistance(move.path);
    if (distance <= 0.001) {
      return 12;
    }
    // 연쇄 경로는 충돌 직전·분리 직후에 짧은 점이 추가될 수 있다.
    // 포인트 개수가 아니라 실제 이동 거리로 재생 시간을 정해 시각 속도를 안정화한다.
    return math.max(1, distance / 4.0);
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
    final duration = _moveDuration(move);
    final progress = (elapsed / duration).clamp(0.0, 1.0);
    return _samplePathByDistance(points, _pathDistance(points) * progress);
  }

  Vec2 _samplePathByDistance(List<Vec2> points, double distance) {
    if (points.length < 2) {
      return points.isEmpty ? Vec2.zero : points.first;
    }
    var remaining = distance.clamp(0.0, _pathDistance(points));
    for (var index = 1; index < points.length; index++) {
      final from = points[index - 1];
      final to = points[index];
      final segment = from.distanceTo(to);
      if (segment <= 0.001) {
        continue;
      }
      if (remaining <= segment) {
        final local = remaining / segment;
        return Vec2(
          from.x + (to.x - from.x) * local,
          from.y + (to.y - from.y) * local,
        );
      }
      remaining -= segment;
    }
    return points.last;
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
    if (index >= points.length - 1) {
      return points.last;
    }
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
    final boardBounds = const Rect.fromLTWH(-8, -8, 376, 576);
    canvas.drawRect(
      boardBounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE9B5), Color(0xFFF5C978)],
        ).createShader(boardBounds),
    );
    final fieldShadow = Paint()
      ..color = const Color(0x553B2B24)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    final frame = Paint()
      ..color = const Color(0xFF2D777A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeJoin = StrokeJoin.round;
    final innerFrame = Paint()
      ..color = const Color(0xFFF5C778)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final boardPath = _pathFromPoints([
      _project(const Vec2(0, 0)),
      _project(Vec2(logicalSize.x, 0)),
      _project(Vec2(logicalSize.x, logicalSize.y)),
      _project(Vec2(0, logicalSize.y)),
    ]);
    canvas.drawPath(boardPath.shift(const Offset(0, 7)), fieldShadow);
    canvas.drawPath(boardPath, frame);
    final fieldGradient = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFE9B5), Color(0xFFF6D995), Color(0xFFEBC376)],
        stops: [0.0, 0.52, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, logicalSize.x, logicalSize.y));
    canvas.drawPath(boardPath, fieldGradient);
    canvas.save();
    canvas.clipPath(boardPath);
    final sandStripe = Paint()..color = const Color(0x16A8733A);
    for (var y = 10.0; y < logicalSize.y; y += 28) {
      canvas.drawRect(Rect.fromLTWH(0, y, logicalSize.x, 10), sandStripe);
    }
    final sun = Paint()
      ..shader = RadialGradient(
        colors: const [Color(0x55FFF7C7), Color(0x00FFF7C7)],
      ).createShader(const Rect.fromLTWH(18, 18, 180, 180));
    canvas.drawCircle(const Offset(58, 58), 92, sun);
    final pebble = Paint()..color = const Color(0x666D8C72);
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
    final island = Paint()..color = const Color(0x1F9A6B3D);
    for (final center in const [
      Offset(32, 106),
      Offset(330, 474),
      Offset(320, 72),
    ]) {
      canvas.drawOval(
        Rect.fromCenter(center: center, width: 34, height: 16),
        island,
      );
      canvas.drawCircle(center.translate(-8, -1), 3, pebble);
      canvas.drawCircle(center.translate(4, 2), 4, pebble);
    }
    canvas.restore();
    final waterMark = Paint()
      ..color = const Color(0x30649F9B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (var index = 0; index < 5; index++) {
      final y = 76.0 + index * 92;
      canvas.drawArc(
        Rect.fromLTWH(8, y, 34, 10),
        math.pi * 0.12,
        math.pi * 0.78,
        false,
        waterMark,
      );
      canvas.drawArc(
        Rect.fromLTWH(logicalSize.x - 42, y + 18, 34, 10),
        math.pi * 0.12,
        math.pi * 0.78,
        false,
        waterMark,
      );
    }
    final flower = Paint()..color = const Color(0xFFFFA46F);
    for (final dot in const [
      Vec2(44, 86),
      Vec2(318, 174),
      Vec2(72, 328),
      Vec2(286, 448),
      Vec2(184, 512),
    ]) {
      canvas.drawCircle(_project(dot), 2.6, flower);
    }
    final cornerLeaf = Paint()..color = const Color(0x886AA76D);
    for (final center in const [
      Vec2(24, 22),
      Vec2(336, 22),
      Vec2(24, 538),
      Vec2(336, 538),
    ]) {
      final c = _project(center);
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(-5, 0), width: 18, height: 8),
        cornerLeaf,
      );
      canvas.drawOval(
        Rect.fromCenter(center: c.translate(5, 4), width: 18, height: 8),
        cornerLeaf,
      );
    }
    canvas.drawPath(boardPath, innerFrame);
    canvas.drawRect(
      Rect.fromLTWH(5, 5, logicalSize.x - 10, logicalSize.y - 10),
      Paint()
        ..color = const Color(0x6672B77D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawAimArrow(Canvas canvas) {
    final ball = state.activeBall;
    final direction = state.aimDirection.normalized();
    final start = ball.position;
    final normal = Vec2(-direction.y, direction.x);
    final accent = const Color(0xFFEF765E);
    final center = _project(start);

    // 방향은 유지하되, 개발용 직선 화살표 대신 공 뒤의 큐 장력과
    // 짧은 점형 마커만 보여 최종 궤적을 예고하지 않는다.
    final cueTip = start - direction * (42 + state.aimPower * 18);
    final cueHead = start - direction * (ball.radius + 3);
    final cueShadow = Paint()
      ..color = const Color(0x443B2B24)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(_project(cueTip).dx, _project(cueTip).dy)
        ..lineTo(_project(cueHead).dx, _project(cueHead).dy),
      cueShadow,
    );
    canvas.drawLine(
      _project(cueTip),
      _project(cueHead),
      Paint()
        ..color = const Color(0xFFB8784C)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      _project(cueTip + normal * 2),
      _project(cueHead + normal * 2),
      Paint()
        ..color = const Color(0x99F7D8A5)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
    for (final offset in [-7.0, 0.0, 7.0]) {
      final grip = _project(cueTip + direction * offset);
      canvas.drawLine(
        grip - Offset(normal.x, normal.y) * 4,
        grip + Offset(normal.x, normal.y) * 4,
        Paint()
          ..color = const Color(0xFF6A4938)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round,
      );
    }

    final anchor = start - direction * (ball.radius + 1);
    final anchorLeft = anchor + normal * (ball.radius * 0.62);
    final anchorRight = anchor - normal * (ball.radius * 0.62);
    final elastic = Paint()
      ..color = const Color(0xB83B302A)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      _project(anchorLeft),
      _project(cueHead + normal * 4),
      elastic,
    );
    canvas.drawLine(
      _project(anchorRight),
      _project(cueHead - normal * 4),
      elastic,
    );

    final markerLength = 34.0 + state.aimPower * 34.0;
    for (var index = 0; index < 4; index++) {
      final progress = (index + 1) / 5;
      final point =
          start + direction * (ball.radius + 9 + markerLength * progress);
      final radius = 2.6 + state.aimPower * 1.2 - index * 0.2;
      canvas.drawCircle(
        _project(point) + const Offset(0, 2),
        radius + 1,
        Paint()..color = const Color(0x443B2B24),
      );
      canvas.drawCircle(
        _project(point),
        radius,
        Paint()..color = accent.withValues(alpha: 0.48 + progress * 0.35),
      );
    }
    final markerCenter = start + direction * (ball.radius + 9 + markerLength);
    final markerSize = 5.0 + state.aimPower * 2.0;
    final marker = Path()
      ..moveTo(
        _project(markerCenter + direction * markerSize).dx,
        _project(markerCenter + direction * markerSize).dy,
      )
      ..lineTo(
        _project(markerCenter + normal * markerSize).dx,
        _project(markerCenter + normal * markerSize).dy,
      )
      ..lineTo(
        _project(markerCenter - direction * markerSize).dx,
        _project(markerCenter - direction * markerSize).dy,
      )
      ..lineTo(
        _project(markerCenter - normal * markerSize).dx,
        _project(markerCenter - normal * markerSize).dy,
      )
      ..close();
    canvas.drawPath(
      marker.shift(const Offset(0, 2)),
      Paint()..color = const Color(0x443B2B24),
    );
    canvas.drawPath(marker, Paint()..color = accent);
    canvas.drawPath(
      marker,
      Paint()
        ..color = const Color(0x883B302A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final gaugeTrack = Paint()
      ..color = const Color(0x553B2B24)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final gaugePaint = Paint()
      ..color = accent
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final gaugeRect = Rect.fromCircle(center: center, radius: ball.radius + 12);
    canvas.drawArc(gaugeRect, -math.pi / 2, math.pi * 2, false, gaugeTrack);
    canvas.drawArc(
      gaugeRect,
      -math.pi / 2,
      state.aimPower * math.pi * 2,
      false,
      gaugePaint,
    );
    for (final fraction in const [0.33, 0.66]) {
      final angle = -math.pi / 2 + fraction * math.pi * 2;
      final marker =
          _project(start) +
          Offset(math.cos(angle), math.sin(angle)) * (ball.radius + 12);
      canvas.drawCircle(marker, 2.2, Paint()..color = const Color(0xCCFFF4D6));
    }
  }

  void _drawEntity(Canvas canvas, EntityState entity, bool highlighted) {
    if (!entity.active ||
        entity.id == 'balloon_switch' &&
            !entity.pressed &&
            entity.visualState != 'revealed') {
      return;
    }
    final stroke = Paint()
      ..color = highlighted ? const Color(0xFFFFC857) : const Color(0xFF24352D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = highlighted ? 5 : 2;

    if (entity.isCircle) {
      if (entity.type == EntityType.ball &&
          entity.visualState == 'hole_captured') {
        _drawCapturedBall(canvas, entity, _capturedMoveProgress(entity));
        return;
      }
      final center = _project(entity.position);
      if (entity.type == EntityType.balloon) {
        _drawBalloon(canvas, entity, center);
        return;
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
        _drawGoalBeacon(canvas, entity);
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
        _drawHoleFlag(canvas, entity);
      } else {
        GameBallIconPainter.drawBall(
          canvas,
          center: center,
          radius: entity.radius,
          trait: entity.traits.isEmpty ? null : entity.traits.first,
        );
        _drawBallTraitTexture(canvas, entity);
      }
    } else {
      final rect = _projectedRect(entity);
      final topPoints = _projectedEntityCorners(entity);
      final topPath = _pathFromPoints(topPoints);
      final litPaint = _materialPaint(entity, rect);
      final image = _objectImages[entity.type];
      if (entity.traits.isNotEmpty &&
          state.phase == GamePhase.planning &&
          _animationPath.isEmpty) {
        _drawSelectablePulse(canvas, entity);
      }
      if (image != null) {
        _drawMovingObjectSprite(canvas, entity, rect, image);
      } else {
        _drawContactShadow(canvas, entity, rect);
        _drawDepthFaces(canvas, entity, topPoints);
        if (entity.type == EntityType.bumper) {
          _drawJellyBody(canvas, entity, litPaint, stroke);
        } else if (entity.type == EntityType.stickySurface) {
          _drawStickySurface(canvas, entity, topPath, litPaint, stroke);
        } else if (entity.type == EntityType.switchPad) {
          _drawSwitchPad(canvas, entity, topPath, litPaint, stroke);
        } else if (entity.type == EntityType.gate &&
            entity.visualState == 'opening') {
          _drawGateOpening(canvas, entity, topPoints);
        } else if (entity.type == EntityType.spikeSource) {
          _drawSpikeSource(canvas, entity, rect);
        } else {
          canvas.drawPath(topPath, litPaint);
          canvas.drawPath(topPath, stroke);
        }
        _drawCanvasSurfaceFinish(canvas, entity, rect, topPath);
        _drawCuteBlockDetails(canvas, entity, rect, topPath);
        _drawDirectionalLight(canvas, entity, rect, topPath);
      }
      _drawTraitTexture(canvas, entity, rect);
    }

    _drawEntityIcon(canvas, entity);
  }

  void _drawEntityWithCache(
    Canvas canvas,
    EntityState entity,
    bool highlighted, {
    required bool animated,
  }) {
    if (!_canCacheEntity(
      entity,
      highlighted: highlighted,
      animated: animated,
    )) {
      _drawEntity(canvas, entity, highlighted);
      return;
    }
    final signature = _staticEntitySignature(entity);
    final previous = _staticEntityPictures[entity.id];
    final _StaticEntityPicture cached;
    if (previous != null && previous.signature == signature) {
      cached = previous;
    } else {
      cached = _recordStaticEntity(entity, signature, highlighted);
    }
    if (previous != null && !identical(previous, cached)) {
      previous.picture.dispose();
    }
    _staticEntityPictures[entity.id] = cached;
    canvas.drawPicture(cached.picture);
  }

  bool _canCacheEntity(
    EntityState entity, {
    required bool highlighted,
    required bool animated,
  }) {
    if (!loadVisualAssets || highlighted || !entity.active || entity.isCircle) {
      return false;
    }
    if (animated && _animationMoves.any((move) => move.entityId == entity.id)) {
      return false;
    }
    // Trait sources pulse during planning, while an opening gate has a
    // time-based deformation. Both must keep their live render path.
    if (entity.traits.isNotEmpty || entity.visualState == 'opening') {
      return false;
    }
    return true;
  }

  String _staticEntitySignature(EntityState entity) {
    return [
      state.phase.name,
      entity.type.name,
      entity.position.x,
      entity.position.y,
      entity.size.x,
      entity.size.y,
      entity.active,
      entity.solid,
      entity.open,
      entity.pressed,
      entity.visualState,
    ].join('|');
  }

  _StaticEntityPicture _recordStaticEntity(
    EntityState entity,
    String signature,
    bool highlighted,
  ) {
    final recorder = ui.PictureRecorder();
    final pictureCanvas = Canvas(recorder);
    _drawEntity(pictureCanvas, entity, highlighted);
    return _StaticEntityPicture(signature, recorder.endRecording());
  }

  void _drawBalloon(Canvas canvas, EntityState entity, Offset center) {
    final radius = entity.radius;
    if (entity.visualState == 'popped') {
      final burst = Paint()
        ..color = const Color(0xFFFFB45E)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var index = 0; index < 8; index++) {
        final angle = index * math.pi / 4;
        final from = center + Offset(math.cos(angle), math.sin(angle)) * 5;
        final to = center + Offset(math.cos(angle), math.sin(angle)) * 18;
        canvas.drawLine(from, to, burst);
      }
      canvas.drawCircle(
        center.translate(0, 7),
        4,
        Paint()..color = const Color(0xFFC75A62),
      );
      return;
    }
    final pressed = entity.visualState == 'pressed';
    final widthScale = pressed ? 1.12 : 1.0;
    final heightScale = pressed ? 0.78 : 1.0;
    final bodyCenter = center.translate(0, pressed ? 3 : -2);
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyCenter.translate(0, 5),
        width: radius * 1.75 * widthScale,
        height: radius * 2.05 * heightScale,
      ),
      Paint()..color = const Color(0x33414B40),
    );
    final body = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.42),
        radius: 1.0,
        colors: const [Color(0xFFFFD0A2), Color(0xFFF28A78), Color(0xFFC75A62)],
      ).createShader(Rect.fromCircle(center: bodyCenter, radius: radius));
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyCenter,
        width: radius * 1.7 * widthScale,
        height: radius * 1.95 * heightScale,
      ),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: bodyCenter,
        width: radius * 1.7 * widthScale,
        height: radius * 1.95 * heightScale,
      ),
      Paint()
        ..color = const Color(0xFF24352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-radius * 0.36, -radius * 0.48),
        width: radius * 0.32,
        height: radius * 0.58,
      ),
      Paint()..color = const Color(0xBFFFF7DD),
    );
    final knot = Path()
      ..moveTo(center.dx - 5, center.dy + radius * 0.83)
      ..lineTo(center.dx, center.dy + radius * 1.08)
      ..lineTo(center.dx + 5, center.dy + radius * 0.83)
      ..close();
    canvas.drawPath(knot, Paint()..color = const Color(0xFFB74F60));
    canvas.drawLine(
      center.translate(0, radius * 1.03),
      center.translate(3, radius * 1.55),
      Paint()
        ..color = const Color(0xFF6B4B35)
        ..strokeWidth = 1.4,
    );
  }

  void _drawSpikeSource(Canvas canvas, EntityState entity, Rect rect) {
    final center = rect.center;
    canvas.drawCircle(
      center,
      rect.shortestSide * 0.26,
      Paint()..color = const Color(0xFFF08B78),
    );
    final spikePaint = Paint()..color = const Color(0xFFFFE49B);
    for (var index = 0; index < 8; index++) {
      final angle = index * math.pi / 4;
      final start = center + Offset(math.cos(angle), math.sin(angle)) * 10;
      final tip = center + Offset(math.cos(angle), math.sin(angle)) * 22;
      final side = Offset(-math.sin(angle), math.cos(angle)) * 4;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo((tip - side).dx, (tip - side).dy)
        ..lineTo((tip + side).dx, (tip + side).dy)
        ..close();
      canvas.drawPath(path, spikePaint);
    }
    canvas.drawCircle(
      center.translate(-4, -5),
      4,
      Paint()..color = const Color(0xBBFFF7DD),
    );
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

  void _drawCanvasSurfaceFinish(
    Canvas canvas,
    EntityState entity,
    Rect rect,
    Path topPath,
  ) {
    final finish = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lightColor.withValues(alpha: 0.12),
          const Color(0x00000000),
          _occlusionColor.withValues(alpha: 0.16),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect.inflate(6));
    final edgeLight = Paint()
      ..color = _lightColor.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final edgeShade = Paint()
      ..color = _occlusionColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.clipPath(topPath);
    canvas.drawRect(rect.inflate(6), finish);
    canvas.drawLine(
      rect.topLeft.translate(3, 2),
      rect.topRight.translate(-3, 2),
      edgeLight,
    );
    canvas.drawLine(
      rect.bottomLeft.translate(3, -2),
      rect.bottomRight.translate(-3, -2),
      edgeShade,
    );
    canvas.restore();

    // Keep material identity visible on small controls without changing their hitbox.
    if (entity.type == EntityType.stickySurface) {
      final gloss = Paint()
        ..color = const Color(0x30FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      canvas.drawArc(
        Rect.fromCenter(
          center: rect.topLeft.translate(rect.width * 0.22, rect.height * 0.22),
          width: rect.width * 0.46,
          height: rect.height * 0.18,
        ),
        math.pi * 1.05,
        math.pi * 0.62,
        false,
        gloss,
      );
    }
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
      ..color = Color.lerp(
        base,
        entity.type == EntityType.wall
            ? const Color(0xFF214E50)
            : const Color(0xFF17231E),
        entity.type == EntityType.wall ? 0.38 : 0.3,
      )!;
    final end = Paint()
      ..color = Color.lerp(
        base,
        entity.type == EntityType.wall
            ? const Color(0xFF173E42)
            : const Color(0xFF17231E),
        entity.type == EntityType.wall ? 0.5 : 0.46,
      )!;
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
      final joint = Paint()
        ..color = const Color(0x3A173E42)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      canvas.save();
      canvas.clipPath(_pathFromPoints(topPoints));
      final rect = _projectedRect(entity);
      if (rect.width >= rect.height) {
        for (var x = rect.left + 42; x < rect.right; x += 42) {
          canvas.drawLine(
            Offset(x, rect.top + 4),
            Offset(x - 2, rect.bottom - 4),
            joint,
          );
        }
      } else {
        for (var y = rect.top + 34; y < rect.bottom; y += 34) {
          canvas.drawLine(
            Offset(rect.left + 4, y),
            Offset(rect.right - 4, y + 2),
            joint,
          );
        }
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
    canvas.drawCircle(
      center.translate(0, 1),
      radius + 5,
      Paint()..color = const Color(0xFF75C98C),
    );
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
        ..color = const Color(0x33FFD76A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    final target = Paint()
      ..color = const Color(0xFFFFD76A).withValues(alpha: 0.52 - pulse * 0.2)
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
    final target = entity.type == EntityType.bumper
        ? Rect.fromCenter(
            center: Offset.zero,
            width: sprite.width,
            height: sprite.height,
          )
        : Rect.fromCenter(
            center: Offset.zero,
            width: sprite.width,
            height: sprite.height,
          );
    final extrusion = switch (entity.type) {
      EntityType.weight => 8.0,
      EntityType.bumper => 4.0,
      _ => 6.0,
    };
    final extrusionPaint = Paint()
      ..colorFilter = const ColorFilter.mode(Color(0xFF17231E), BlendMode.srcIn)
      ..filterQuality = _runtimeFilterQuality;
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
      ..filterQuality = _runtimeFilterQuality;
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
      Paint()..filterQuality = _runtimeFilterQuality,
    );
    _drawRasterSurfaceFinish(canvas, entity, target);
    canvas.restore();
    if (entity.type == EntityType.bumper && motion.impact > 0.04) {
      _drawJellySpriteImpact(canvas, center, target, motion.impact);
    }
    _drawSpriteGleam(canvas, entity, target, motion);
  }

  void _drawRasterSurfaceFinish(
    Canvas canvas,
    EntityState entity,
    Rect target,
  ) {
    final radius = Radius.circular(entity.type == EntityType.weight ? 12 : 6);
    final finish = Paint()
      ..blendMode = BlendMode.srcATop
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lightColor.withValues(alpha: 0.12),
          const Color(0x00000000),
          _occlusionColor.withValues(alpha: 0.16),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(target.inflate(2));
    final edgeLight = Paint()
      ..blendMode = BlendMode.srcATop
      ..color = _lightColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final edgeShade = Paint()
      ..blendMode = BlendMode.srcATop
      ..color = _occlusionColor.withValues(alpha: 0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(target, radius));
    canvas.drawRect(target, finish);
    canvas.drawLine(
      target.topLeft.translate(2, 1),
      target.topRight.translate(-2, 1),
      edgeLight,
    );
    canvas.drawLine(
      target.bottomLeft.translate(2, -1),
      target.bottomRight.translate(-2, -1),
      edgeShade,
    );
    canvas.restore();
  }

  void _drawJellySpriteImpact(
    Canvas canvas,
    Offset center,
    Rect target,
    double impact,
  ) {
    final alpha = (impact * 0.42).clamp(0.0, 0.42);
    final pulse = math.sin(_pulseClock * math.pi * 8).abs();
    final splash = Paint()
      ..color = const Color(0xFF7BE7CC).withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 + impact * 1.6
      ..strokeCap = StrokeCap.round;
    final splashRect = Rect.fromCenter(
      center: center.translate(0, target.height * 0.34),
      width: target.width * (0.62 + impact * 0.22),
      height: target.height * (0.14 + pulse * 0.04),
    );
    canvas.drawArc(splashRect, math.pi * 0.08, math.pi * 0.84, false, splash);
    final droplet = Paint()
      ..color = const Color(0xFFB6F5E5).withValues(alpha: alpha * 0.9)
      ..style = PaintingStyle.fill;
    for (var index = 0; index < 3; index++) {
      final direction = index - 1;
      final dropCenter = center.translate(
        direction * target.width * 0.27,
        target.height * (0.34 - impact * (0.06 + index * 0.015)),
      );
      canvas.drawCircle(dropCenter, 1.7 + impact * 1.2, droplet);
    }
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
    final openingMove = _animationMoves
        .where(
          (move) => move.entityId == entity.id && move.visualState == 'opening',
        )
        .fold<ShotAnimationMove?>(
          null,
          (latest, move) =>
              latest == null || move.triggerPathIndex > latest.triggerPathIndex
              ? move
              : latest,
        );
    final openingProgress = openingMove == null
        ? 1.0
        : ((_animationCursor - openingMove.triggerPathIndex) / 12)
              .clamp(0.0, 1.0)
              .toDouble();
    final easedOpening = 1 - math.pow(1 - openingProgress, 3).toDouble();
    final width = entity.size.x;
    final height = entity.size.y;
    final gap = 6 + easedOpening * 16;
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
        0.62 + easedOpening * 0.38,
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

  double _capturedMoveProgress(EntityState entity) {
    ShotAnimationMove? captureMove;
    for (final move in _animationMoves) {
      if (move.entityId != entity.id || move.visualState != 'hole_captured') {
        continue;
      }
      if (captureMove == null ||
          move.triggerPathIndex > captureMove.triggerPathIndex) {
        captureMove = move;
      }
    }
    if (captureMove == null) {
      return 1;
    }
    return ((_animationCursor - captureMove.triggerPathIndex) /
            _moveDuration(captureMove))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  void _drawCapturedBall(Canvas canvas, EntityState entity, double progress) {
    final center = _project(entity.position);
    final eased = Curves.easeInCubic.transform(progress);
    final scale = 1 - eased * 0.58;
    final opacity = 1 - eased * 0.44;
    final bounds = Rect.fromCircle(center: center, radius: entity.radius + 20);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.translate(-center.dx, -center.dy);
    canvas.saveLayer(
      bounds,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    _drawCircularContactShadow(canvas, entity);
    GameBallIconPainter.drawBall(
      canvas,
      center: center,
      radius: entity.radius,
      trait: entity.traits.isEmpty ? null : entity.traits.first,
    );
    _drawBallTraitTexture(canvas, entity);
    canvas.restore();
    canvas.restore();

    final suction = Paint()
      ..color = const Color(0xFFFFD76A).withValues(alpha: 0.58 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(center, entity.radius + 7 + progress * 8, suction);
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
      case TraitType.sharp:
        for (var index = 0; index < 5; index++) {
          final angle = -math.pi * 0.85 + index * math.pi * 0.42;
          final base =
              center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.66;
          final tip =
              center + Offset(math.cos(angle), math.sin(angle)) * radius * 1.22;
          canvas.drawLine(
            base,
            tip,
            Paint()
              ..color = const Color(0xFFFFE49B)
              ..strokeWidth = 3
              ..strokeCap = StrokeCap.round,
          );
        }
    }
    canvas.restore();
  }

  void _drawHoleFlag(Canvas canvas, EntityState entity) {
    final center = _project(entity.position);
    final flutter = math.sin(_pulseClock * math.pi * 1.8) * 1.4;
    final pole = Paint()
      ..color = const Color(0xFF6B4B35)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center.translate(5, -4), center.translate(5, -34), pole);
    final flag = Path()
      ..moveTo(center.dx + 6, center.dy - 34)
      ..lineTo(center.dx + 25 + flutter, center.dy - 27)
      ..lineTo(center.dx + 6, center.dy - 20)
      ..close();
    canvas.drawPath(flag, Paint()..color = const Color(0xFFFFD76A));
    canvas.drawPath(
      flag,
      Paint()
        ..color = const Color(0xFF8F6A2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawLine(
      center.translate(8, -31),
      center.translate(20 + flutter * 0.55, -28),
      Paint()
        ..color = const Color(0x88FFFFFF)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEntityIcon(Canvas canvas, EntityState entity) {
    final center = _project(entity.position);
    switch (entity.type) {
      case EntityType.ball:
      case EntityType.hole:
      case EntityType.wall:
        return;
      case EntityType.balloon:
        canvas.drawCircle(
          center.translate(-5, -7),
          4,
          Paint()..color = const Color(0xCCFFF7DD),
        );
        canvas.drawLine(
          center.translate(0, 12),
          center.translate(2, 20),
          Paint()
            ..color = const Color(0xFF6B4B35)
            ..strokeWidth = 1.2,
        );
      case EntityType.spikeSource:
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
        if (_objectImages.containsKey(EntityType.bumper)) {
          return;
        }
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
        Paint()..color = const Color(0xFFF2C978),
      );
      final plankSeam = Paint()
        ..color = const Color(0x5A2D6664)
        ..strokeWidth = 1.25
        ..strokeCap = StrokeCap.round;
      if (rect.width >= rect.height) {
        for (var x = rect.left + 34; x < rect.right; x += 42) {
          canvas.drawLine(
            Offset(x, rect.top + 9),
            Offset(x - 2, rect.bottom - 3),
            plankSeam,
          );
        }
      } else {
        for (var y = rect.top + 32; y < rect.bottom; y += 34) {
          canvas.drawLine(
            Offset(rect.left + 3, y),
            Offset(rect.right - 3, y + 2),
            plankSeam,
          );
        }
      }
      canvas.restore();
      final innerEdge = Paint()
        ..color = const Color(0xA8F6D995)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      if (rect.width >= rect.height) {
        canvas.drawLine(
          rect.bottomLeft.translate(4, -3),
          rect.bottomRight.translate(-4, -3),
          innerEdge,
        );
      } else if (rect.center.dx < logicalSize.x / 2) {
        canvas.drawLine(
          rect.topRight.translate(-3, 5),
          rect.bottomRight.translate(-3, -5),
          innerEdge,
        );
      } else {
        canvas.drawLine(
          rect.topLeft.translate(3, 5),
          rect.bottomLeft.translate(3, -5),
          innerEdge,
        );
      }
      final post = Paint()..color = const Color(0xFFF2D18C);
      if (rect.width >= rect.height) {
        canvas.drawCircle(rect.topLeft.translate(8, 8), 2.5, post);
        canvas.drawCircle(rect.topRight.translate(-8, 8), 2.5, post);
      } else {
        canvas.drawCircle(rect.topLeft.translate(5, 8), 2.5, post);
        canvas.drawCircle(rect.bottomLeft.translate(5, -8), 2.5, post);
      }
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
        return const Color(0xFF6EA99D);
      case EntityType.crate:
        return const Color(0xFFB7854B);
      case EntityType.bumper:
        return const Color(0xFF6ED6B0);
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
      case EntityType.balloon:
        return const Color(0xFFF28A78);
      case EntityType.spikeSource:
        return const Color(0xFFF08B78);
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
      case TraitType.sharp:
        return const Color(0xFFE47758);
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
      case TraitType.sharp:
        for (var x = rect.left + 8; x < rect.right; x += 12) {
          canvas.drawLine(
            Offset(x, rect.bottom - 4),
            Offset(x + 5, rect.top + 5),
            texture,
          );
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
    final holeImpact = _animationImpacts
        .where(
          (impact) =>
              impact.entityType == EntityType.hole &&
              impact.sourceEntityId == 'active_ball',
        )
        .fold<ShotImpact?>(
          null,
          (latest, impact) =>
              latest == null || impact.pathIndex > latest.pathIndex
              ? impact
              : latest,
        );
    if (holeImpact == null || _animationCursor < holeImpact.pathIndex) {
      _drawEntity(canvas, entity, false);
      return;
    }
    final progress = ((_animationCursor - holeImpact.pathIndex) / 8)
        .clamp(0.0, 1.0)
        .toDouble();
    _drawCapturedBall(canvas, entity, progress);
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

class _StaticEntityPicture {
  const _StaticEntityPicture(this.signature, this.picture);

  final String signature;
  final ui.Picture picture;
}

double mathMin(double a, double b) => math.min(a, b);
