// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

const _resolver = ShotResolver();

void main() {
  final stage = generatedStageCatalog.stageById('stage_rotating_reflector');
  final pattern = stage.patternById('stage_rotating_reflector_03');
  final base = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(8, productRules: true);
  final candidates = <_Candidate>[];
  for (var firstDegree = 266; firstDegree <= 274; firstDegree++) {
    for (var firstPower = 30; firstPower <= 40; firstPower++) {
      final first = _resolver.resolve(
        base,
        _input(firstDegree, firstPower / 50),
      );
      if (first.state.phase == GamePhase.success) continue;
      final secondSuccesses = <(int, int)>[];
      for (var secondDegree = 0; secondDegree < 360; secondDegree += 2) {
        for (var secondPower = 6; secondPower <= 50; secondPower++) {
          final second = _resolver.resolve(
            first.state,
            _input(secondDegree, secondPower / 50),
          );
          if (second.state.phase == GamePhase.success &&
              second.reflectorRotations.any(
                (rotation) => rotation.sourceEntityId == 'spent_ball_1',
              )) {
            secondSuccesses.add((secondDegree, secondPower));
          }
        }
      }
      if (secondSuccesses.isNotEmpty) {
        candidates.add(
          _Candidate(
            firstDegree,
            firstPower,
            secondSuccesses.length,
            secondSuccesses.first.$1,
            secondSuccesses.first.$2,
          ),
        );
      }
    }
  }
  candidates.sort((a, b) => b.successes.compareTo(a.successes));
  for (final candidate in candidates.take(20)) {
    print(candidate);
  }
}

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}

class _Candidate {
  const _Candidate(
    this.firstDegree,
    this.firstPower,
    this.successes,
    this.secondDegree,
    this.secondPower,
  );

  final int firstDegree;
  final int firstPower;
  final int successes;
  final int secondDegree;
  final int secondPower;

  @override
  String toString() =>
      'first=$firstDegree/${firstPower * 2}% secondSuccess=$successes '
      'example=$secondDegree/${secondPower * 2}%';
}
