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

void main() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_chain_gate');
  if (Platform.environment['SINGLE_ONLY'] == 'true') {
    _searchSingleShotSteel(stage);
    return;
  }
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

void _searchSingleShotSteel(StageDefinition stage) {
  const resolver = ShotResolver();
  const traits = TraitResolver();
  for (final pattern in stage.patterns) {
    final initial = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(2);
    final steel = traits.transferSelectedTrait(
      traits.selectSource(initial, 'steel'),
    );
    final successes = <(int, int)>{};
    for (var degree = 0; degree < 360; degree += 2) {
      for (var powerStep = 10; powerStep <= 50; powerStep++) {
        final result = resolver.resolve(
          steel,
          _input(degree, powerStep / 50, steel.equippedTrait),
        );
        if (result.state.phase == GamePhase.success &&
            result.events.contains('switch_pressed') &&
            result.events.contains('hole_entered') &&
            result.chainSafetyDiagnostics.isEmpty) {
          successes.add((degree, powerStep));
        }
      }
    }
    (int, int)? best;
    var bestNeighbors = -1;
    for (final candidate in successes) {
      var neighbors = 0;
      for (final degreeDelta in [-2, 0, 2]) {
        for (final powerDelta in [-2, -1, 0, 1, 2]) {
          if (successes.contains((
            (candidate.$1 + degreeDelta) % 360,
            candidate.$2 + powerDelta,
          ))) {
            neighbors++;
          }
        }
      }
      if (neighbors > bestNeighbors) {
        best = candidate;
        bestNeighbors = neighbors;
      }
    }
    stdout.writeln(
      '${pattern.patternId}: successes=${successes.length} '
      'best=${best == null ? "none" : "${best.$1}/${(best.$2 / 50).toStringAsFixed(2)}"} '
      'neighbors=$bestNeighbors',
    );
  }
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
