import 'dart:math' as math;

// This executable intentionally prints its search findings for manual review.
// ignore_for_file: avoid_print

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();
  final stage = generatedStageCatalog.stageById('stage_rotating_reflector');

  for (final pattern in stage.patterns) {
    final initial = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(8, productRules: true);
    final preparedStates =
        <String, ({GameState state, int degree, double power})>{};

    for (final candidate in _inputs()) {
      final first = resolver.resolve(initial, candidate.input);
      if (first.state.phase != GamePhase.planning ||
          first.reflectorRotations.isEmpty ||
          (pattern.patternId.endsWith('_04') &&
              first.powerSliderActivations.isEmpty)) {
        continue;
      }
      final key = first.state.entities
          .where((entity) => entity.type.name == 'rotatingReflector')
          .map(
            (entity) =>
                '${entity.id}:${entity.reflectorOrientation}:${entity.reflectorRotationCount}',
          )
          .join('|');
      preparedStates.putIfAbsent(
        key,
        () => (
          state: first.state,
          degree: candidate.degree,
          power: candidate.power,
        ),
      );
    }

    var initialSuccesses = 0;
    ({int degree, double power})? directRepresentative;
    for (final candidate in _inputs()) {
      if (resolver.resolve(initial, candidate.input).state.phase ==
          GamePhase.success) {
        initialSuccesses++;
        directRepresentative ??= (
          degree: candidate.degree,
          power: candidate.power,
        );
      }
    }

    ({GameState state, int degree, double power})? best;
    var bestSuccesses = -1;
    ({int degree, double power})? bestFinal;
    for (final prepared in preparedStates.values) {
      var successes = 0;
      ({int degree, double power})? preparedOnly;
      for (final candidate in _inputs()) {
        final preparedResult = resolver.resolve(
          prepared.state,
          candidate.input,
        );
        if (preparedResult.state.phase != GamePhase.success) continue;
        successes++;
        if (preparedOnly == null &&
            resolver.resolve(initial, candidate.input).state.phase !=
                GamePhase.success) {
          preparedOnly = (degree: candidate.degree, power: candidate.power);
        }
      }
      if (successes > bestSuccesses && preparedOnly != null) {
        best = prepared;
        bestSuccesses = successes;
        bestFinal = preparedOnly;
      }
    }

    print(
      '${pattern.patternId}: direct=$initialSuccesses '
      'states=${preparedStates.length} best=$bestSuccesses '
      'ratio=${(bestSuccesses / initialSuccesses).toStringAsFixed(2)} '
      'first=${best?.degree}/${best?.power.toStringAsFixed(2)} '
      'second=${bestFinal?.degree}/${bestFinal?.power.toStringAsFixed(2)} '
      'direct=${directRepresentative?.degree}/'
      '${directRepresentative?.power.toStringAsFixed(2)}',
    );

    if (pattern.patternId == 'stage_rotating_reflector_03') {
      var bestPastBallCount = -1;
      ({int degree, double power})? pastBallFirst;
      ({int degree, double power})? pastBallSecond;
      for (final firstCandidate in _inputs()) {
        final first = resolver.resolve(initial, firstCandidate.input);
        if (first.state.phase != GamePhase.planning ||
            first.state.entityById('spent_ball_1') == null ||
            first.reflectorRotations.isEmpty) {
          continue;
        }
        var qualified = 0;
        ({int degree, double power})? representative;
        for (final secondCandidate in _inputs()) {
          final second = resolver.resolve(first.state, secondCandidate.input);
          if (second.state.phase != GamePhase.success ||
              !second.reflectorRotations.any(
                (rotation) => rotation.sourceEntityId == 'spent_ball_1',
              )) {
            continue;
          }
          qualified++;
          representative ??= (
            degree: secondCandidate.degree,
            power: secondCandidate.power,
          );
        }
        if (qualified > bestPastBallCount && representative != null) {
          bestPastBallCount = qualified;
          pastBallFirst = (
            degree: firstCandidate.degree,
            power: firstCandidate.power,
          );
          pastBallSecond = representative;
        }
      }
      print(
        '${pattern.patternId} past-ball-qualified=$bestPastBallCount '
        'first=${pastBallFirst?.degree}/${pastBallFirst?.power.toStringAsFixed(2)} '
        'second=${pastBallSecond?.degree}/${pastBallSecond?.power.toStringAsFixed(2)}',
      );
    }
  }
}

Iterable<({int degree, double power, ShotInput input})> _inputs() sync* {
  for (var degree = 0; degree < 360; degree += 4) {
    final radians = degree * math.pi / 180;
    final direction = Vec2(math.cos(radians), math.sin(radians));
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final power = powerStep / 10;
      yield (
        degree: degree,
        power: power,
        input: ShotInput(direction: direction, power: power),
      );
    }
  }
}
