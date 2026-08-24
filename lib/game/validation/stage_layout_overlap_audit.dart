import 'dart:math' as math;

import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';

class StageLayoutOverlap {
  const StageLayoutOverlap({
    required this.stageId,
    required this.patternId,
    required this.firstId,
    required this.secondId,
    required this.depth,
  });

  final String stageId;
  final String patternId;
  final String firstId;
  final String secondId;
  final double depth;

  @override
  String toString() =>
      '$stageId/$patternId: $firstId + $secondId, '
      '겹침=${depth.toStringAsFixed(1)}';
}

List<StageLayoutOverlap> findInitialStageLayoutOverlaps({
  required StageDefinition stage,
  required StagePattern pattern,
}) {
  final elements = <_LayoutElement>[
    _LayoutElement.ball(pattern.ballSpawn),
    for (final object in pattern.objects)
      if (object.active) _LayoutElement.object(object),
  ];
  final overlaps = <StageLayoutOverlap>[];
  for (var firstIndex = 0; firstIndex < elements.length; firstIndex++) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < elements.length;
      secondIndex++
    ) {
      final first = elements[firstIndex];
      final second = elements[secondIndex];
      if (_isAllowedBoardCorner(first, second)) continue;
      final depth = _overlapDepth(first, second);
      if (depth <= 0.01) continue;
      overlaps.add(
        StageLayoutOverlap(
          stageId: stage.stageId,
          patternId: pattern.patternId,
          firstId: first.id,
          secondId: second.id,
          depth: depth,
        ),
      );
    }
  }
  return overlaps;
}

class _LayoutElement {
  const _LayoutElement({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    required this.isCircle,
  });

  factory _LayoutElement.ball(Vec2 position) => _LayoutElement(
    id: 'active_ball',
    type: EntityType.ball,
    position: position,
    size: const Vec2(24, 24),
    isCircle: true,
  );

  factory _LayoutElement.object(PatternObjectDefinition object) =>
      _LayoutElement(
        id: object.id,
        type: object.type,
        position: object.position,
        size: object.size,
        isCircle:
            object.type == EntityType.ball ||
            object.type == EntityType.hole ||
            object.type == EntityType.balloon ||
            object.type == EntityType.bumper,
      );

  final String id;
  final EntityType type;
  final Vec2 position;
  final Vec2 size;
  final bool isCircle;

  double get radius => math.min(size.x, size.y) / 2;
  double get left => position.x - size.x / 2;
  double get right => position.x + size.x / 2;
  double get top => position.y - size.y / 2;
  double get bottom => position.y + size.y / 2;
}

double _overlapDepth(_LayoutElement first, _LayoutElement second) {
  if (first.isCircle && second.isCircle) {
    return first.radius +
        second.radius -
        first.position.distanceTo(second.position);
  }
  if (first.isCircle) return _circleRectangleDepth(first, second);
  if (second.isCircle) return _circleRectangleDepth(second, first);
  final horizontal =
      math.min(first.right, second.right) - math.max(first.left, second.left);
  final vertical =
      math.min(first.bottom, second.bottom) - math.max(first.top, second.top);
  return math.min(horizontal, vertical);
}

double _circleRectangleDepth(_LayoutElement circle, _LayoutElement rectangle) {
  final nearestX = circle.position.x.clamp(rectangle.left, rectangle.right);
  final nearestY = circle.position.y.clamp(rectangle.top, rectangle.bottom);
  final distance = circle.position.distanceTo(Vec2(nearestX, nearestY));
  if (distance > 0) return circle.radius - distance;
  final horizontalDepth = math.min(
    circle.position.x - rectangle.left,
    rectangle.right - circle.position.x,
  );
  final verticalDepth = math.min(
    circle.position.y - rectangle.top,
    rectangle.bottom - circle.position.y,
  );
  return circle.radius + math.min(horizontalDepth, verticalDepth);
}

bool _isAllowedBoardCorner(_LayoutElement first, _LayoutElement second) {
  if (first.type != EntityType.wall || second.type != EntityType.wall) {
    return false;
  }
  final firstTouchesHorizontalEdge = first.top <= 0 || first.bottom >= 560;
  final firstTouchesVerticalEdge = first.left <= 0 || first.right >= 360;
  final secondTouchesHorizontalEdge = second.top <= 0 || second.bottom >= 560;
  final secondTouchesVerticalEdge = second.left <= 0 || second.right >= 360;
  return (firstTouchesHorizontalEdge && secondTouchesVerticalEdge) ||
      (firstTouchesVerticalEdge && secondTouchesHorizontalEdge);
}
