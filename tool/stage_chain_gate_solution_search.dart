import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_chain_gate');
  final pattern = stage.patternById('stage_chain_gate_02');
  final initial = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(2);
  const resolver = ShotResolver();
  const traits = TraitResolver();
  final glue = traits.transferSelectedTrait(
    traits.selectSource(initial, 'glue'),
  );
  var found = 0;
  for (var firstDegree = 0; firstDegree <= 12; firstDegree++) {
    for (var firstPowerIndex = 0; firstPowerIndex <= 4; firstPowerIndex++) {
      final firstPower = _tick(firstPowerIndex);
      final first = resolver.resolve(
        glue,
        _input(firstDegree, firstPower, glue.equippedTrait),
      );
      if (!first.events.contains('sticky_attached')) continue;
      final armed = traits.transferSelectedTrait(
        traits.selectSource(first.state, 'steel'),
      );
      var paired = false;
      for (
        var secondDegree = 0;
        secondDegree < 360 && !paired;
        secondDegree++
      ) {
        for (
          var secondPowerIndex = 0;
          secondPowerIndex <= 16;
          secondPowerIndex++
        ) {
          final secondPower = _tick(secondPowerIndex);
          final second = resolver.resolve(
            armed,
            _input(secondDegree, secondPower, armed.equippedTrait),
          );
          final ids = second.impacts.map((impact) => impact.entityId).toList();
          final spentIndex = ids.indexOf('spent_ball_1');
          final switchIndex = ids.indexOf('switch');
          final holeIndex = ids.indexOf('hole');
          if (second.state.phase == GamePhase.success &&
              second.events.contains('spent_ball_bounced') &&
              second.events.contains('switch_pressed') &&
              spentIndex >= 0 &&
              switchIndex > spentIndex &&
              holeIndex > switchIndex) {
            stdout.writeln(
              'first=$firstDegree/${firstPower.toStringAsFixed(3)} '
              'second=$secondDegree/${secondPower.toStringAsFixed(3)} '
              'impacts=${ids.join(",")}',
            );
            found++;
            paired = true;
            break;
          }
        }
      }
    }
  }
  stdout.writeln('found=$found');
}

double _tick(int index) => (0.12 + 0.055 * index).clamp(0.12, 1.0).toDouble();

ShotInput _input(int degree, double power, [TraitType? equippedTrait]) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
    equippedTrait: equippedTrait,
  );
}
