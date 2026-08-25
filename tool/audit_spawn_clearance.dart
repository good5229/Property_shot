// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';

const _ballRadius = 12 * 0.88;
const _minimumClearance = 72.0;
const _boardSize = Vec2(360, 560);

void main() {
  final catalog = StageCatalog.fromJson(
    jsonDecode(File('assets/stages/chapter_1.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  for (final stage in catalog.stages) {
    for (final pattern in stage.patterns) {
      final current = _minimumAt(pattern.ballSpawn, pattern.objects);
      if (current.clearance >= _minimumClearance) continue;
      final candidate = _nearestCandidate(pattern.ballSpawn, pattern.objects);
      print(
        '${pattern.patternId}\t${pattern.ballSpawn.x},${pattern.ballSpawn.y}'
        '\t${current.entityId}:${current.clearance.toStringAsFixed(1)}'
        '\t${candidate == null ? 'NONE' : '${candidate.position.x},${candidate.position.y} ${candidate.entityId}:${candidate.clearance.toStringAsFixed(1)}'}',
      );
    }
  }
}

({Vec2 position, String entityId, double clearance})? _nearestCandidate(
  Vec2 origin,
  List<PatternObjectDefinition> objects,
) {
  ({Vec2 position, String entityId, double clearance})? best;
  var bestDistance = double.infinity;
  for (var y = 12.0; y <= _boardSize.y - 12; y += 4) {
    for (var x = 12.0; x <= _boardSize.x - 12; x += 4) {
      final position = Vec2(x, y);
      final minimum = _minimumAt(position, objects);
      if (minimum.clearance < _minimumClearance) continue;
      final distance = position.distanceTo(origin);
      if (distance + 0.001 < bestDistance) {
        bestDistance = distance;
        best = (
          position: position,
          entityId: minimum.entityId,
          clearance: minimum.clearance,
        );
      }
    }
  }
  return best;
}

({String entityId, double clearance}) _minimumAt(
  Vec2 position,
  List<PatternObjectDefinition> objects,
) {
  var minimum = double.infinity;
  var entityId = 'board';
  for (final object in objects) {
    final entity = object.toEntityState();
    if (!entity.active) continue;
    final clearance =
        position.distanceTo(entity.hitBounds.nearestPoint(position)) -
        _ballRadius;
    if (clearance < minimum) {
      minimum = clearance;
      entityId = entity.id;
    }
  }
  return (entityId: entityId, clearance: minimum);
}
