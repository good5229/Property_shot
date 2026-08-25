// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main(List<String> arguments) {
  const resolver = ShotResolver();
  final stage = generatedStageCatalog.stageById('stage_rotating_reflector');
  final stage4 = arguments.contains('--stage4');
  final pattern = stage.patternById(
    stage4 ? 'stage_rotating_reflector_04' : 'stage_rotating_reflector_02',
  );
  final initial = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(8, productRules: true);
  if (arguments.contains('--hole-search')) {
    _searchHolePositions(resolver, initial);
    return;
  }
  final first = resolver.resolve(
    initial,
    stage4 ? _input(200, 0.80) : _input(74, 0.12),
  );
  print('first=${first.events} rotations=${first.reflectorRotations.length}');
  if (arguments.contains('--trace')) {
    final second = resolver.resolve(
      first.state,
      stage4 ? _input(72, 0.50) : _input(330, 0.90),
    );
    print('first-path=${_pathBins(first.path)}');
    print('second-path=${_pathBins(second.path)}');
    print('second-phase=${second.state.phase} events=${second.events}');
  }
  final counts = <String, ({int direct, int prepared})>{};
  var directCount = 0;
  var preparedCount = 0;
  for (var degree = 0; degree < 360; degree += 4) {
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final input = _input(degree, powerStep / 10);
      final direct = resolver.resolve(initial, input);
      final prepared = resolver.resolve(first.state, input);
      if (direct.state.phase == GamePhase.success) {
        directCount++;
        _countPath(counts, direct.path, direct: true);
      }
      if (prepared.state.phase == GamePhase.success) {
        preparedCount++;
        _countPath(counts, prepared.path, direct: false);
      }
    }
  }
  final ranked = counts.entries.toList()
    ..sort((left, right) {
      final leftScore = left.value.direct * 3 - left.value.prepared;
      final rightScore = right.value.direct * 3 - right.value.prepared;
      return rightScore.compareTo(leftScore);
    });
  print('direct=$directCount prepared=$preparedCount');
  for (final entry in ranked.take(30)) {
    print('${entry.key}\t${entry.value.direct}\t${entry.value.prepared}');
  }
}

String _pathBins(List<Vec2> path) {
  final bins = <String>[];
  String? previous;
  for (final point in path) {
    final bin = '${(point.x / 10).round() * 10},${(point.y / 10).round() * 10}';
    if (bin == previous) continue;
    bins.add(bin);
    previous = bin;
  }
  return bins.join(' ');
}

void _searchHolePositions(ShotResolver resolver, GameState base) {
  final candidates = <({Vec2 position, int direct, int prepared})>[];
  for (var x = 60; x <= 300; x += 20) {
    for (var y = 70; y <= 190; y += 20) {
      final initial = _moveHole(base, Vec2(x.toDouble(), y.toDouble()));
      final first = resolver.resolve(initial, _input(74, 0.12));
      if (first.state.phase == GamePhase.success ||
          first.reflectorRotations.isEmpty) {
        continue;
      }
      var direct = 0;
      var prepared = 0;
      for (var degree = 0; degree < 360; degree += 4) {
        for (var powerStep = 1; powerStep <= 10; powerStep++) {
          final input = _input(degree, powerStep / 10);
          if (resolver.resolve(initial, input).state.phase ==
              GamePhase.success) {
            direct++;
          }
          if (resolver.resolve(first.state, input).state.phase ==
              GamePhase.success) {
            prepared++;
          }
        }
      }
      if (prepared >= 10 && prepared / math.max(1, direct) >= 1.4) {
        candidates.add((
          position: Vec2(x.toDouble(), y.toDouble()),
          direct: direct,
          prepared: prepared,
        ));
      }
    }
  }
  candidates.sort((left, right) {
    final ratio = (right.prepared / math.max(1, right.direct)).compareTo(
      left.prepared / math.max(1, left.direct),
    );
    if (ratio != 0) return ratio;
    return right.prepared.compareTo(left.prepared);
  });
  for (final candidate in candidates.take(30)) {
    print(
      'hole=${candidate.position.x.toInt()},${candidate.position.y.toInt()} '
      'direct=${candidate.direct} prepared=${candidate.prepared} '
      'ratio=${(candidate.prepared / math.max(1, candidate.direct)).toStringAsFixed(2)}',
    );
  }
}

GameState _moveHole(GameState state, Vec2 position) => state.copyWith(
  entities: [
    for (final entity in state.entities)
      if (entity.id == 'hole') entity.copyWith(position: position) else entity,
  ],
);

void _countPath(
  Map<String, ({int direct, int prepared})> counts,
  List<Vec2> path, {
  required bool direct,
}) {
  final visited = <String>{};
  for (final point in path) {
    final key = '${(point.x / 20).round() * 20},${(point.y / 20).round() * 20}';
    if (!visited.add(key)) continue;
    final current = counts[key] ?? (direct: 0, prepared: 0);
    counts[key] = (
      direct: current.direct + (direct ? 1 : 0),
      prepared: current.prepared + (direct ? 0 : 1),
    );
  }
}

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}
