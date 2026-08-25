// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  const resolver = ShotResolver();
  for (final pattern in catalog.stageById('stage_bouncy').patterns) {
    final none = _state(pattern, false);
    final jelly = _state(pattern, true);
    ({int degree, double power, double gain})? best;
    for (var degree = 0; degree < 360; degree += 2) {
      for (var step = 4; step <= 50; step++) {
        final power = step / 50;
        final direction = Vec2(
          math.cos(degree * math.pi / 180),
          math.sin(degree * math.pi / 180),
        );
        final plainResult = resolver.resolve(
          none,
          ShotInput(direction: direction, power: power),
        );
        final jellyResult = resolver.resolve(
          jelly,
          ShotInput(
            direction: direction,
            power: power,
            equippedTrait: TraitType.bouncy,
          ),
        );
        if (!_hasCollision(plainResult) || !_hasCollision(jellyResult)) {
          continue;
        }
        final gain =
            _pathLength(jellyResult.path) - _pathLength(plainResult.path);
        if (best == null || gain > best.gain) {
          best = (degree: degree, power: power, gain: gain);
        }
      }
    }
    print('${pattern.patternId}: $best');
  }
}

GameState _state(StagePattern pattern, bool jelly) {
  var state = pattern
      .toLevelDefinition(stageId: 'stage_bouncy', stageTitle: '2. 탄성 익히기')
      .createState(0);
  if (jelly) {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(traits.selectSource(state, 'jelly'));
  }
  return state;
}

bool _hasCollision(ShotResult result) => result.impacts.any(
  (impact) =>
      impact.entityType == EntityType.wall ||
      impact.entityType == EntityType.bumper,
);

double _pathLength(List<Vec2> path) {
  var total = 0.0;
  for (var index = 1; index < path.length; index++) {
    total += (path[index] - path[index - 1]).length;
  }
  return total;
}
