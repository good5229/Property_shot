import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main(List<String> arguments) {
  final requested = arguments.toSet();
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_bouncy');
  const resolver = ShotResolver();

  for (final pattern in stage.patterns) {
    if (requested.isNotEmpty && !requested.contains(pattern.patternId)) {
      continue;
    }
    final noneState = _stateFor(pattern, jelly: false);
    final jellyState = _stateFor(pattern, jelly: true);
    final noneInputs = <String>[];
    final jellyInputs = <String>[];
    final jellyHitInputs = <String>[];
    final jellyOnly = <String>[];
    var noneCount = 0;
    var jellyCount = 0;
    for (var degree = 0; degree < 360; degree += 2) {
      for (var powerStep = 1; powerStep <= 100; powerStep++) {
        final power = powerStep / 100;
        final direction = _directionFor(degree);
        final none = resolver.resolve(
          noneState,
          ShotInput(direction: direction, power: power),
        );
        final jelly = resolver.resolve(
          jellyState,
          ShotInput(
            direction: direction,
            power: power,
            equippedTrait: TraitType.bouncy,
          ),
        );
        final noneSuccess = none.state.phase == GamePhase.success;
        final jellySuccess = jelly.state.phase == GamePhase.success;
        if (noneSuccess) {
          noneCount++;
          if (noneInputs.length < 12) {
            noneInputs.add(
              '$degree/${power.toStringAsFixed(2)} '
              'impacts=${none.impacts.map((impact) => impact.entityId).join(",")}',
            );
          }
        }
        if (jellySuccess) {
          jellyCount++;
          if (jellyInputs.length < 12) {
            jellyInputs.add(
              '$degree/${power.toStringAsFixed(2)} '
              'impacts=${jelly.impacts.map((impact) => impact.entityId).join(",")}',
            );
          }
        }
        if ((noneSuccess || jellySuccess) &&
            jellyHitInputs.length < 12 &&
            (none.impacts.any((impact) => impact.entityId == 'jelly') ||
                jelly.impacts.any((impact) => impact.entityId == 'jelly'))) {
          jellyHitInputs.add(
            '$degree/${power.toStringAsFixed(2)} '
            'none=$noneSuccess jelly=$jellySuccess '
            'noneImpacts=${none.impacts.map((impact) => impact.entityId).join(",")} '
            'jellyImpacts=${jelly.impacts.map((impact) => impact.entityId).join(",")}',
          );
        }
        if (jellySuccess && !noneSuccess && jellyOnly.length < 24) {
          jellyOnly.add(
            '$degree/${power.toStringAsFixed(2)} '
            'impacts=${jelly.impacts.map((impact) => impact.entityId).join(",")}',
          );
        }
      }
    }
    stdout.writeln(
      '${pattern.patternId}: none=$noneCount jelly=$jellyCount '
      'ratio=${(noneCount / math.max(1, jellyCount)).toStringAsFixed(3)}',
    );
    for (final input in noneInputs) {
      stdout.writeln('  none $input');
    }
    for (final input in jellyInputs) {
      stdout.writeln('  jelly $input');
    }
    for (final input in jellyHitInputs) {
      stdout.writeln('  jelly-hit $input');
    }
    for (final input in jellyOnly) {
      stdout.writeln('  jelly-only $input');
    }
  }
}

GameState _stateFor(StagePattern pattern, {required bool jelly}) {
  var state = pattern
      .toLevelDefinition(stageId: 'stage_bouncy', stageTitle: '2. 탄성 익히기')
      .createState(0);
  if (jelly) {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(traits.selectSource(state, 'jelly'));
  }
  return state;
}

Vec2 _directionFor(int degree) {
  final radians = degree * math.pi / 180;
  return Vec2(math.cos(radians), math.sin(radians));
}
