// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import '../test/fixtures/stage9_rotating_reflector_patterns.dart';

const _resolver = ShotResolver();

void main() {
  final stage = generatedStageCatalog.stageById('stage_rotating_reflector');
  final pattern = stage.patternById('stage_rotating_reflector_02');
  final fixture = stage9RotatingReflectorSolutions.firstWhere(
    (solution) => solution.patternId == pattern.patternId,
  );
  final base = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(8, productRules: true);
  final candidates = <_Candidate>[];
  for (var size = 68; size <= 92; size += 8) {
    for (var x = 104; x <= 176; x += 4) {
      for (var y = 114; y <= 186; y += 4) {
        final initial = _moveHole(
          base,
          Vec2(x.toDouble(), y.toDouble()),
          size.toDouble(),
        );
        final first = _resolver.resolve(initial, fixture.firstInput);
        if (first.state.phase == GamePhase.success) continue;
        var successes = 0;
        final angles = <int>{};
        for (
          var degree = fixture.secondDegree - 4;
          degree <= fixture.secondDegree + 4;
          degree++
        ) {
          for (
            var powerStep = (fixture.secondPower * 50).round() - 4;
            powerStep <= (fixture.secondPower * 50).round() + 4;
            powerStep++
          ) {
            final second = _resolver.resolve(
              first.state,
              _input(degree, powerStep / 50),
            );
            if (_matches(first, second, fixture.expectedRotationOrder)) {
              successes++;
              angles.add(degree);
            }
          }
        }
        if (angles.length >= 2) {
          candidates.add(_Candidate(x, y, size, successes, angles.length));
        }
      }
    }
  }
  candidates.sort((left, right) {
    final success = right.successes.compareTo(left.successes);
    if (success != 0) return success;
    return right.angleCount.compareTo(left.angleCount);
  });
  for (final candidate in candidates.take(20)) {
    print(candidate);
  }
}

GameState _moveHole(GameState state, Vec2 position, double size) =>
    state.copyWith(
      entities: [
        for (final entity in state.entities)
          if (entity.id == 'hole')
            entity.copyWith(position: position, size: Vec2(size, size))
          else
            entity,
      ],
    );

bool _matches(ShotResult first, ShotResult second, List<String> expectedOrder) {
  if (second.state.phase != GamePhase.success) return false;
  final ids = [
    ...first.reflectorRotations.map((event) => event.reflectorEntityId),
    ...second.reflectorRotations.map((event) => event.reflectorEntityId),
  ];
  if (ids.length < expectedOrder.length) return false;
  for (var index = 0; index < expectedOrder.length; index++) {
    if (ids[index] != expectedOrder[index]) return false;
  }
  return true;
}

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}

class _Candidate {
  const _Candidate(this.x, this.y, this.size, this.successes, this.angleCount);

  final int x;
  final int y;
  final int size;
  final int successes;
  final int angleCount;

  @override
  String toString() =>
      'hole=($x,$y) size=$size success=$successes/81 angleBins=$angleCount';
}
