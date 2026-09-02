// ignore_for_file: avoid_print

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/analysis/stage_chain_challenge.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/input/aim_direction_quantizer.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import '../test/fixtures/stage_chain_score_patterns.dart';

const _resolver = ShotResolver();
const _analyzer = CreativeChainScoreAnalyzer();
const _challenge = StageChainChallengeEvaluator();

void main(List<String> arguments) {
  final report = buildStage8SolutionRegionReport(verbose: true);
  final output = const JsonEncoder.withIndent('  ').convert(report);
  final file = File('harness_docs/qa/replays/stage8_solution_regions.json');
  if (arguments.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync().trim() != output.trim()) {
      stderr.writeln('8단계 성공 영역 기록이 생성 결과와 다릅니다.');
      exitCode = 1;
      return;
    }
    print('8단계 성공 영역 기록 동기화 확인');
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('$output\n');
}

Map<String, Object?> buildStage8SolutionRegionReport({bool verbose = false}) {
  final stage = generatedStageCatalog.stageById('stage_chain_score');
  final validation = StagePatternValidator().validateWithRuntimeProbe(
    stage,
    probe: ShotResolverPatternRuntimeProbe(
      representativeInputs: [
        for (final solution in stageChainScoreSolutions) ...[
          solution.directInput,
          solution.firstInput,
          solution.secondInput,
        ],
      ],
      maxProbeCount: stageChainScoreSolutions.length * 3,
      maxShots: stageChainScoreSolutions.length * 6,
    ),
  );
  if (!validation.isValid) {
    throw StateError(
      validation.issues
          .map((issue) => '${issue.codeName}: ${issue.message}')
          .join('\n'),
    );
  }
  final records = <Map<String, Object?>>[];
  for (final solution in stageChainScoreSolutions) {
    final pattern = stage.patternById(solution.patternId);
    final direct = _directRegion(stage, pattern);
    final chain = _chainRegion(stage, pattern, solution);
    records.add({
      'patternId': pattern.patternId,
      'direct': direct,
      'chain': chain,
    });
    if (verbose) {
      print(
        '${pattern.patternId}: 직접 ${direct['successCount']}개/'
        '연결 ${direct['largestConnectedRegion']}개, '
        '연쇄 ${chain['successCount']}개/연결 '
        '${chain['largestConnectedRegion']}개, 인과 서명 '
        '${chain['distinctCausalSignatureCount']}개',
      );
    }
  }
  return {
    'schemaVersion': 2,
    'directAngleStepDegrees': 2,
    'chainAngleStepDegrees': 1,
    'aimSnapDegrees': defaultAimStepDegrees,
    'powerStepPercent': 2,
    'chainNeighborhood': {'angleRadiusDegrees': 4, 'powerRadiusPercent': 8},
    'validator': {'staticAndRuntimeIssueCount': validation.issues.length},
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
      if (result.state.phase == GamePhase.success) {
        successes.add(_Grid2(angleIndex, powerIndex));
      }
    }
  }
  return {
    'sampleCount': 180 * 45,
    'successCount': successes.length,
    'largestConnectedRegion': _largestRegion2(successes),
    'angleSpanDegrees': _span(successes.map((point) => point.angle * 2)),
    'powerSpanPercent': _span(successes.map((point) => point.power * 2)),
  };
}

Map<String, Object?> _chainRegion(
  StageDefinition stage,
  StagePattern pattern,
  StageChainScoreSolution solution,
) {
  final initial = _state(stage, pattern);
  final firstAngles = _angleValues(solution.firstDegree, 4);
  final firstPowers = _indices((solution.firstPower * 50).round(), 4, 6, 50);
  final secondAngles = _angleValues(solution.secondDegree, 4);
  final secondPowers = _indices((solution.secondPower * 50).round(), 4, 6, 50);
  final successes = <_Grid4>{};
  final successesBySignature = <String, Set<_Grid4>>{};
  final signatureDetails = <String, _CausalSignature>{};
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
          if (second.state.phase != GamePhase.success) continue;
          final results = [first, second];
          final analysis = _analyzer.analyze(
            results,
            parShots: pattern.parShots,
            optionalChallengeIds: CreativeChainChallengeId.all,
          );
          if (!_challenge.isAchieved(
            patternId: pattern.patternId,
            analysis: analysis,
            results: results,
          )) {
            continue;
          }
          final point = _Grid4(
            firstAngle,
            firstPower,
            secondAngle,
            secondPower,
          );
          final signature = _causalSignature(second, analysis);
          successes.add(point);
          successesBySignature
              .putIfAbsent(signature.key, () => <_Grid4>{})
              .add(point);
          signatureDetails[signature.key] = signature;
          successfulFirst.add(_Grid2(firstAngle, firstPower));
          successfulSecond.add(_Grid2(secondAngle, secondPower));
        }
      }
    }
  }
  final sampleCount =
      firstAngles.length *
      firstPowers.length *
      secondAngles.length *
      secondPowers.length;
  final firstAngleSpan = _consecutiveSpan(successfulFirst, true, 1);
  final secondAngleSpan = _consecutiveSpan(successfulSecond, true, 1);
  final causalSignatures =
      [
        for (final entry in successesBySignature.entries)
          {
            'signature': entry.key,
            'successCount': entry.value.length,
            'largestConnectedRegion': _largestRegion4(entry.value),
            'targetOrder': signatureDetails[entry.key]!.targetOrder,
            'entityTypes': signatureDetails[entry.key]!.entityTypes,
            'wallReflectionCount':
                signatureDetails[entry.key]!.wallReflectionCount,
          },
      ]..sort((first, second) {
        final byRegion = (second['largestConnectedRegion'] as int).compareTo(
          first['largestConnectedRegion'] as int,
        );
        if (byRegion != 0) return byRegion;
        final byCount = (second['successCount'] as int).compareTo(
          first['successCount'] as int,
        );
        if (byCount != 0) return byCount;
        return (first['signature'] as String).compareTo(
          second['signature'] as String,
        );
      });
  return {
    'sampleCount': sampleCount,
    'successCount': successes.length,
    'largestConnectedRegion': _largestRegion4(successes),
    'successfulFirstInputs': successfulFirst.length,
    'successfulSecondInputs': successfulSecond.length,
    'successfulFirstAngleDegrees': _successfulAngleValues(
      successfulFirst,
      firstAngles,
    ),
    'successfulSecondAngleDegrees': _successfulAngleValues(
      successfulSecond,
      secondAngles,
    ),
    'firstAngleSpanDegrees': firstAngleSpan,
    'firstSelectableAngleBins': firstAngleSpan + 1,
    'firstPowerSpanPercent': _consecutiveSpan(successfulFirst, false, 2),
    'secondAngleSpanDegrees': secondAngleSpan,
    'secondSelectableAngleBins': secondAngleSpan + 1,
    'secondPowerSpanPercent': _consecutiveSpan(successfulSecond, false, 2),
    'distinctCausalSignatureCount': causalSignatures.length,
    'causalSignatures': causalSignatures,
  };
}

_CausalSignature _causalSignature(
  ShotResult result,
  CreativeChainScoreAnalysis analysis,
) {
  final causalEvents = result.physicsEvents
      .where((event) => analysis.causalEventIds.contains('1:${event.eventId}'))
      .where((event) => event.targetType != EntityType.hole)
      .toList(growable: false);
  final targetOrder = [for (final event in causalEvents) event.targetEntityId];
  final entityTypes = {
    for (final event in causalEvents) event.targetType.name,
  }.toList()..sort();
  final wallReflectionCount = causalEvents
      .where((event) => event.targetType == EntityType.wall)
      .length;
  final compactOrder = targetOrder.join('>');
  final typeKey = entityTypes.join('+');
  return _CausalSignature(
    key: '$compactOrder|types:$typeKey|walls:$wallReflectionCount',
    targetOrder: targetOrder,
    entityTypes: entityTypes,
    wallReflectionCount: wallReflectionCount,
  );
}

class _CausalSignature {
  const _CausalSignature({
    required this.key,
    required this.targetOrder,
    required this.entityTypes,
    required this.wallReflectionCount,
  });

  final String key;
  final List<String> targetOrder;
  final List<String> entityTypes;
  final int wallReflectionCount;
}

GameState _state(StageDefinition stage, StagePattern pattern) => pattern
    .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
    .createState(7, productRules: true);

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

int _span(Iterable<int> values) {
  if (values.isEmpty) return 0;
  final sorted = values.toList()..sort();
  return sorted.last - sorted.first;
}

int _consecutiveSpan(Set<_Grid2> points, bool angle, [int multiplier = 2]) {
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

List<int> _successfulAngleValues(Set<_Grid2> points, List<int> angles) {
  final values = points.map((point) => angles[point.angle]).toSet().toList()
    ..sort();
  return values;
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
