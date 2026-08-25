// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main(List<String> arguments) {
  if (arguments.length != 3) {
    throw ArgumentError('stageId patternId sourceId 순서로 지정하세요.');
  }
  final stage = generatedStageCatalog.stageById(arguments[0]);
  final pattern = stage.patternById(arguments[1]);
  final sourceId = arguments[2];
  final none = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(0, productRules: true);
  const traits = TraitResolver();
  final gimmick = traits.transferSelectedTrait(
    traits.selectSource(none, sourceId),
  );
  const resolver = ShotResolver();
  final counts = <String, ({int bypass, int gimmick})>{};
  var bypassSuccesses = 0;
  var gimmickSuccesses = 0;
  for (var degree = 0; degree < 360; degree += 4) {
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final input = _input(degree, powerStep / 10);
      final bypass = resolver.resolve(none, input);
      final achieved = resolver.resolve(
        gimmick,
        ShotInput(
          direction: input.direction,
          power: input.power,
          equippedTrait: gimmick.equippedTrait,
        ),
      );
      if (bypass.state.phase == GamePhase.success) {
        bypassSuccesses++;
        _countPath(counts, bypass.path, bypass: true);
      }
      if (achieved.state.phase == GamePhase.success) {
        gimmickSuccesses++;
        _countPath(counts, achieved.path, bypass: false);
      }
    }
  }
  final ranked = counts.entries.toList()
    ..sort((left, right) {
      final leftScore = left.value.bypass * 3 - left.value.gimmick;
      final rightScore = right.value.bypass * 3 - right.value.gimmick;
      return rightScore.compareTo(leftScore);
    });
  print(
    '${arguments[1]} gimmick=$gimmickSuccesses bypass=$bypassSuccesses '
    'ratio=${(gimmickSuccesses / math.max(1, bypassSuccesses)).toStringAsFixed(2)}',
  );
  for (final entry in ranked.take(30)) {
    print('${entry.key}\t${entry.value.bypass}\t${entry.value.gimmick}');
  }
}

void _countPath(
  Map<String, ({int bypass, int gimmick})> counts,
  List<Vec2> path, {
  required bool bypass,
}) {
  final visited = <String>{};
  for (final point in path) {
    final key = '${(point.x / 20).round() * 20},${(point.y / 20).round() * 20}';
    if (!visited.add(key)) continue;
    final current = counts[key] ?? (bypass: 0, gimmick: 0);
    counts[key] = (
      bypass: current.bypass + (bypass ? 1 : 0),
      gimmick: current.gimmick + (bypass ? 0 : 1),
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
