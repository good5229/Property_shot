import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../simulation/shot_resolver.dart';
import 'pattern_hint.dart';

/// 확정된 물리 결과에만 의존하는 열쇠 획득 이벤트다.
///
/// 이 값은 `GameState`를 바꾸지 않는다. UI·저장 계층은 이 이벤트를 받아
/// 해당 stageId/patternId의 Hint entitlement를 기록한다.
class KeyCollectedEvent {
  const KeyCollectedEvent({
    required this.keyId,
    required this.sourceBallId,
    required this.pathIndex,
    required this.segmentIndex,
    required this.position,
  });

  final String keyId;
  final String sourceBallId;
  final int pathIndex;
  final int segmentIndex;
  final Vec2 position;
}

/// 물리 resolver 결과의 공 경로만 sweep하여 수집 이벤트를 안정적으로 만든다.
/// 다른 기물의 `ShotAnimationMove`는 의도적으로 무시한다.
class DeterministicKeyCollectionResolver {
  const DeterministicKeyCollectionResolver({this.ballHitRadius = 12 * 0.88});

  final double ballHitRadius;

  List<KeyCollectedEvent> collect({
    required GameState stateBeforeShot,
    required ShotResult result,
    required Iterable<HintKeyDefinition> keys,
  }) {
    final keyList = keys.toList(growable: false);
    final ballIds = <String>{
      for (final entity in stateBeforeShot.entities)
        if (entity.type == EntityType.ball) entity.id,
      for (final entity in result.state.entities)
        if (entity.type == EntityType.ball) entity.id,
    };
    final candidates = <({KeyCollectedEvent event, double t})>[];

    void sweep(String ballId, List<Vec2> points, int pathIndexBase) {
      if (!ballIds.contains(ballId) || points.length < 2) return;
      for (var segmentIndex = 1; segmentIndex < points.length; segmentIndex++) {
        final from = points[segmentIndex - 1];
        final to = points[segmentIndex];
        final hits = <({HintKeyDefinition key, double t, Vec2 point})>[];
        for (final key in keyList) {
          final t = _segmentHitT(from, to, key.bounds, ballHitRadius);
          if (t == null) continue;
          hits.add((
            key: key,
            t: t,
            point: Vec2(
              from.x + (to.x - from.x) * t,
              from.y + (to.y - from.y) * t,
            ),
          ));
        }
        hits.sort((left, right) {
          final byT = left.t.compareTo(right.t);
          return byT != 0 ? byT : left.key.id.compareTo(right.key.id);
        });
        for (final hit in hits) {
          candidates.add((
            event: KeyCollectedEvent(
              keyId: hit.key.id,
              sourceBallId: ballId,
              pathIndex: pathIndexBase + segmentIndex - 1,
              segmentIndex: segmentIndex - 1,
              position: hit.point,
            ),
            t: hit.t,
          ));
        }
      }
    }

    sweep('active_ball', result.path, 0);
    final moves = result.moves.toList()
      ..sort((left, right) {
        final byIndex = left.triggerPathIndex.compareTo(right.triggerPathIndex);
        return byIndex != 0 ? byIndex : left.entityId.compareTo(right.entityId);
      });
    for (final move in moves) {
      final points = move.path.length >= 2 ? move.path : [move.from, move.to];
      sweep(move.entityId, points, move.triggerPathIndex);
    }
    candidates.sort((left, right) {
      final byPath = left.event.pathIndex.compareTo(right.event.pathIndex);
      if (byPath != 0) return byPath;
      final bySegment = left.event.segmentIndex.compareTo(
        right.event.segmentIndex,
      );
      if (bySegment != 0) return bySegment;
      final byT = left.t.compareTo(right.t);
      if (byT != 0) return byT;
      final bySource = left.event.sourceBallId.compareTo(
        right.event.sourceBallId,
      );
      if (bySource != 0) return bySource;
      return left.event.keyId.compareTo(right.event.keyId);
    });
    final collectedKeyIds = <String>{};
    return List.unmodifiable([
      for (final candidate in candidates)
        if (collectedKeyIds.add(candidate.event.keyId)) candidate.event,
    ]);
  }
}

/// 선분이 열쇠의 확장 hitbox에 처음 닿는 비율을 반환한다.
double? _segmentHitT(Vec2 from, Vec2 to, Bounds bounds, double radius) {
  final expanded = Bounds(
    left: bounds.left - radius,
    top: bounds.top - radius,
    width: bounds.width + radius * 2,
    height: bounds.height + radius * 2,
  );
  final delta = to - from;
  var entry = 0.0;
  var exit = 1.0;
  bool clip(double position, double direction, double min, double max) {
    if (direction.abs() < 0.0000001) return position >= min && position <= max;
    final first = (min - position) / direction;
    final second = (max - position) / direction;
    entry = math.max(entry, math.min(first, second));
    exit = math.min(exit, math.max(first, second));
    return entry <= exit;
  }

  if (!clip(from.x, delta.x, expanded.left, expanded.right) ||
      !clip(from.y, delta.y, expanded.top, expanded.bottom) ||
      exit < 0 ||
      entry > 1) {
    return null;
  }
  return entry.clamp(0, 1).toDouble();
}
