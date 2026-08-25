// ignore_for_file: avoid_print

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/input/aim_direction_quantizer.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import '../test/fixtures/stage9_rotating_reflector_patterns.dart';

const _resolver = ShotResolver();

void main(List<String> arguments) {
  final report = buildStage9SolutionRegionReport(verbose: true);
  final output = const JsonEncoder.withIndent('  ').convert(report);
  final file = File('harness_docs/qa/replays/stage9_solution_regions.json');
  if (arguments.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync().trim() != output.trim()) {
      stderr.writeln('9단계 성공 영역 기록이 생성 결과와 다릅니다.');
      exitCode = 1;
      return;
    }
    print('9단계 성공 영역 기록 동기화 확인');
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('$output\n');
}

Map<String, Object?> buildStage9SolutionRegionReport({bool verbose = false}) {
  final stage = generatedStageCatalog.stageById('stage_rotating_reflector');
  final records = <Map<String, Object?>>[];
  for (final solution in stage9RotatingReflectorSolutions) {
    final pattern = stage.patternById(solution.patternId);
    final direct = _directRegion(stage, pattern);
    final prepared = _preparedRegion(stage, pattern, solution);
    records.add({
      'patternId': pattern.patternId,
      'direct': direct,
      'prepared': prepared,
    });
    if (verbose) {
      print(
        '${pattern.patternId}: 직접 ${direct['successCount']}개/'
        '연결 ${direct['largestConnectedRegion']}개, '
        '반사판 ${prepared['successCount']}개/'
        '연결 ${prepared['largestConnectedRegion']}개',
      );
    }
  }

  return {
    'schemaVersion': 1,
    'directAngleStepDegrees': 2,
    'preparedAngleStepDegrees': 1,
    'aimSnapDegrees': defaultAimStepDegrees,
    'powerStepPercent': 2,
    'preparedNeighborhood': {'angleRadiusDegrees': 4, 'powerRadiusPercent': 8},
    'patterns': records,
  };
}

Map<String, Object?> _directRegion(
  StageDefinition stage,
  StagePattern pattern,
) {
  final initial = _state(stage, pattern);
  final successes = <_Grid2>{};
  for (var angleIndex = 0; angleIndex < 180; angleIndex++) {
    for (var powerIndex = 6; powerIndex <= 50; powerIndex++) {
      final result = _resolver.resolve(
        initial,
        _input(angleIndex * 2, powerIndex / 50),
      );
      if (result.state.phase == GamePhase.success &&
          result.reflectorRotations.isEmpty) {
        successes.add(_Grid2(angleIndex, powerIndex));
      }
    }
  }
  return {
    'sampleCount': 180 * 45,
    'successCount': successes.length,
    'largestConnectedRegion': _largestRegion2(successes),
  };
}

Map<String, Object?> _preparedRegion(
  StageDefinition stage,
  StagePattern pattern,
  Stage9RotatingReflectorSolution solution,
) {
  final initial = _state(stage, pattern);
  final firstAngles = _angleValues(solution.firstDegree, 4);
  final firstPowers = _indices((solution.firstPower * 50).round(), 4, 6, 50);
  final secondAngles = _angleValues(solution.secondDegree, 4);
  final secondPowers = _indices((solution.secondPower * 50).round(), 4, 6, 50);
  final successes = <_Grid4>{};
  final successfulFirst = <_Grid2>{};
  final successfulSecond = <_Grid2>{};

  for (var firstAngle = 0; firstAngle < firstAngles.length; firstAngle++) {
    for (var firstPower = 0; firstPower < firstPowers.length; firstPower++) {
      final first = _resolver.resolve(
        initial,
        _input(firstAngles[firstAngle], firstPowers[firstPower] / 50),
      );
      if (first.state.phase == GamePhase.success) continue;
      for (
        var secondAngle = 0;
        secondAngle < secondAngles.length;
        secondAngle++
      ) {
        for (
          var secondPower = 0;
          secondPower < secondPowers.length;
          secondPower++
        ) {
          final second = _resolver.resolve(
            first.state,
            _input(secondAngles[secondAngle], secondPowers[secondPower] / 50),
          );
          if (!_matchesFamily(first, second, solution)) continue;
          successes.add(
            _Grid4(firstAngle, firstPower, secondAngle, secondPower),
          );
          successfulFirst.add(_Grid2(firstAngle, firstPower));
          successfulSecond.add(_Grid2(secondAngle, secondPower));
        }
      }
    }
  }

  return {
    'sampleCount':
        firstAngles.length *
        firstPowers.length *
        secondAngles.length *
        secondPowers.length,
    'successCount': successes.length,
    'largestConnectedRegion': _largestRegion4(successes),
    'successfulFirstInputs': successfulFirst.length,
    'successfulSecondInputs': successfulSecond.length,
    'successfulFirstAngleDegrees':
        successfulFirst
            .map((point) => firstAngles[point.angle])
            .toSet()
            .toList()
          ..sort(),
    'successfulSecondAngleDegrees':
        successfulSecond
            .map((point) => secondAngles[point.angle])
            .toSet()
            .toList()
          ..sort(),
    'firstSelectableAngleBins': _consecutiveSpan(successfulFirst, true, 1) + 1,
    'secondSelectableAngleBins':
        _consecutiveSpan(successfulSecond, true, 1) + 1,
    'firstPowerSpanPercent': _consecutiveSpan(successfulFirst, false, 2),
    'secondPowerSpanPercent': _consecutiveSpan(successfulSecond, false, 2),
  };
}

bool _matchesFamily(
  ShotResult first,
  ShotResult second,
  Stage9RotatingReflectorSolution solution,
) {
  if (second.state.phase != GamePhase.success) return false;
  final rotationIds = [
    ...first.reflectorRotations.map((rotation) => rotation.reflectorEntityId),
    ...second.reflectorRotations.map((rotation) => rotation.reflectorEntityId),
  ];
  if (rotationIds.length < solution.expectedRotationOrder.length ||
      !List.generate(
        solution.expectedRotationOrder.length,
        (index) => rotationIds[index] == solution.expectedRotationOrder[index],
      ).every((matches) => matches)) {
    return false;
  }
  if (solution.expectedSecondRotationSource != null &&
      !second.reflectorRotations.any(
        (rotation) =>
            rotation.sourceEntityId == solution.expectedSecondRotationSource,
      )) {
    return false;
  }
  if (solution.expectedFirstSlider && first.powerSliderActivations.isEmpty) {
    return false;
  }
  return true;
}

GameState _state(StageDefinition stage, StagePattern pattern) => pattern
    .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
    .createState(8, productRules: true);

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}

List<int> _indices(int center, int radius, int minimum, int maximum) => [
  for (var value = center - radius; value <= center + radius; value++)
    if (value >= minimum && value <= maximum) value,
];

List<int> _angleValues(int center, int radius) => [
  for (var offset = -radius; offset <= radius; offset++)
    (center + offset) % 360,
];

int _largestRegion2(Set<_Grid2> points) {
  final remaining = points.toSet();
  var largest = 0;
  while (remaining.isNotEmpty) {
    final queue = Queue<_Grid2>()..add(remaining.first);
    remaining.remove(queue.first);
    var count = 0;
    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      count++;
      for (final neighbor in point.neighbors()) {
        if (remaining.remove(neighbor)) queue.add(neighbor);
      }
    }
    largest = math.max(largest, count);
  }
  return largest;
}

int _largestRegion4(Set<_Grid4> points) {
  final remaining = points.toSet();
  var largest = 0;
  while (remaining.isNotEmpty) {
    final queue = Queue<_Grid4>()..add(remaining.first);
    remaining.remove(queue.first);
    var count = 0;
    while (queue.isNotEmpty) {
      final point = queue.removeFirst();
      count++;
      for (final neighbor in point.neighbors()) {
        if (remaining.remove(neighbor)) queue.add(neighbor);
      }
    }
    largest = math.max(largest, count);
  }
  return largest;
}

int _consecutiveSpan(Set<_Grid2> points, bool angle, int multiplier) {
  if (points.isEmpty) return 0;
  final sorted =
      points.map((point) => angle ? point.angle : point.power).toSet().toList()
        ..sort();
  var longest = 1;
  var current = 1;
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index] == sorted[index - 1] + 1) {
      current++;
      longest = math.max(longest, current);
    } else {
      current = 1;
    }
  }
  return (longest - 1) * multiplier;
}

class _Grid2 {
  const _Grid2(this.angle, this.power);

  final int angle;
  final int power;

  Iterable<_Grid2> neighbors() sync* {
    yield _Grid2((angle + 179) % 180, power);
    yield _Grid2((angle + 1) % 180, power);
    yield _Grid2(angle, power - 1);
    yield _Grid2(angle, power + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is _Grid2 && other.angle == angle && other.power == power;

  @override
  int get hashCode => Object.hash(angle, power);
}

class _Grid4 {
  const _Grid4(
    this.firstAngle,
    this.firstPower,
    this.secondAngle,
    this.secondPower,
  );

  final int firstAngle;
  final int firstPower;
  final int secondAngle;
  final int secondPower;

  Iterable<_Grid4> neighbors() sync* {
    yield _Grid4(firstAngle - 1, firstPower, secondAngle, secondPower);
    yield _Grid4(firstAngle + 1, firstPower, secondAngle, secondPower);
    yield _Grid4(firstAngle, firstPower - 1, secondAngle, secondPower);
    yield _Grid4(firstAngle, firstPower + 1, secondAngle, secondPower);
    yield _Grid4(firstAngle, firstPower, secondAngle - 1, secondPower);
    yield _Grid4(firstAngle, firstPower, secondAngle + 1, secondPower);
    yield _Grid4(firstAngle, firstPower, secondAngle, secondPower - 1);
    yield _Grid4(firstAngle, firstPower, secondAngle, secondPower + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is _Grid4 &&
      other.firstAngle == firstAngle &&
      other.firstPower == firstPower &&
      other.secondAngle == secondAngle &&
      other.secondPower == secondPower;

  @override
  int get hashCode =>
      Object.hash(firstAngle, firstPower, secondAngle, secondPower);
}
