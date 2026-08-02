import 'dart:math' as math;

import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../domain/trait.dart';
import '../levels/levels.dart';
import '../simulation/shot_resolver.dart';
import '../simulation/trait_resolver.dart';

class DifficultyMetrics {
  const DifficultyMetrics({
    required this.levelIndex,
    required this.levelName,
    required this.totalInputs,
    required this.successInputs,
    required this.successRate,
    required this.widestAngleDegrees,
    required this.widestPowerRange,
    required this.largestConnectedRegion,
    required this.minimumShots,
    required this.recommendedParShots,
    required this.successfulStrategies,
    required this.copylessSuccess,
    required this.strategyMetrics,
  });

  final int levelIndex;
  final String levelName;
  final int totalInputs;
  final int successInputs;
  final double successRate;
  final double widestAngleDegrees;
  final double widestPowerRange;
  final int largestConnectedRegion;
  final int? minimumShots;
  final int? recommendedParShots;
  final List<String> successfulStrategies;
  final bool copylessSuccess;
  final List<StrategyDifficultyMetrics> strategyMetrics;
}

class StrategyDifficultyMetrics {
  const StrategyDifficultyMetrics({
    required this.label,
    required this.totalInputs,
    required this.successInputs,
    required this.successRate,
    required this.widestAngleDegrees,
    required this.widestPowerRange,
    required this.largestConnectedRegion,
    required this.minimumShots,
  });

  final String label;
  final int totalInputs;
  final int successInputs;
  final double successRate;
  final double widestAngleDegrees;
  final double widestPowerRange;
  final int largestConnectedRegion;
  final int? minimumShots;
}

class DifficultyAnalyzer {
  const DifficultyAnalyzer({
    this.angleStepDegrees = 10,
    this.powerSteps = 20,
    this.shotResolver = const ShotResolver(),
    this.traitResolver = const TraitResolver(),
  });

  final int angleStepDegrees;
  final int powerSteps;
  final ShotResolver shotResolver;
  final TraitResolver traitResolver;

  List<DifficultyMetrics> analyzeAll() {
    return [
      for (var index = 0; index < levels.length; index++) analyzeLevel(index),
    ];
  }

  DifficultyMetrics analyzeLevel(int levelIndex) {
    final level = levels[levelIndex];
    final strategies = <_Strategy>[
      _Strategy('무속성', level.createState(levelIndex)),
    ];
    for (final source in level.createState(levelIndex).traitSources) {
      final selected = traitResolver.selectSource(
        level.createState(levelIndex),
        source.id,
      );
      strategies.add(
        _Strategy(
          '${source.id} (${source.traits.first.label})',
          traitResolver.transferSelectedTrait(selected),
        ),
      );
    }

    var totalInputs = 0;
    var successInputs = 0;
    var minimumShots = null as int?;
    var widestAngle = 0.0;
    var widestPower = 0.0;
    var largestRegion = 0;
    final successfulStrategies = <String>[];
    final strategyMetrics = <StrategyDifficultyMetrics>[];
    var copylessSuccess = false;

    for (final strategy in strategies) {
      final successes = <_InputCell>{};
      var strategySuccessInputs = 0;
      var strategyMinimumShots = null as int?;
      for (var degree = 0; degree < 360; degree += angleStepDegrees) {
        final radians = degree * math.pi / 180;
        for (var powerStep = 1; powerStep <= powerSteps; powerStep++) {
          totalInputs++;
          final result = shotResolver.resolve(
            strategy.state,
            ShotInput(
              direction: Vec2(math.cos(radians), math.sin(radians)),
              power: powerStep / powerSteps,
              equippedTrait: strategy.state.equippedTrait,
            ),
          );
          if (result.state.phase != GamePhase.success) {
            continue;
          }
          successInputs++;
          strategySuccessInputs++;
          copylessSuccess = true;
          successes.add(
            _InputCell(
              degreeIndex: degree ~/ angleStepDegrees,
              powerStep: powerStep,
            ),
          );
          minimumShots = minimumShots == null
              ? result.state.shotCount
              : math.min(minimumShots, result.state.shotCount);
          strategyMinimumShots = strategyMinimumShots == null
              ? result.state.shotCount
              : math.min(strategyMinimumShots, result.state.shotCount);
        }
      }
      if (successes.isEmpty) {
        continue;
      }
      successfulStrategies.add(strategy.label);
      final strategyWidestAngle =
          _widestCircularRun(successes, _angleCount) * angleStepDegrees;
      final strategyWidestPower = _widestPowerRun(successes) / powerSteps;
      final strategyLargestRegion = _largestConnectedRegion(
        successes,
        _angleCount,
      );
      strategyMetrics.add(
        StrategyDifficultyMetrics(
          label: strategy.label,
          totalInputs: _angleCount * powerSteps,
          successInputs: strategySuccessInputs,
          successRate: strategySuccessInputs / (_angleCount * powerSteps),
          widestAngleDegrees: strategyWidestAngle,
          widestPowerRange: strategyWidestPower,
          largestConnectedRegion: strategyLargestRegion,
          minimumShots: strategyMinimumShots,
        ),
      );
      widestAngle = math.max(
        widestAngle,
        strategyWidestAngle / angleStepDegrees,
      );
      widestPower = math.max(widestPower, strategyWidestPower * powerSteps);
      largestRegion = math.max(largestRegion, strategyLargestRegion);
    }

    return DifficultyMetrics(
      levelIndex: levelIndex,
      levelName: level.name,
      totalInputs: totalInputs,
      successInputs: successInputs,
      successRate: totalInputs == 0 ? 0 : successInputs / totalInputs,
      widestAngleDegrees: widestAngle * angleStepDegrees,
      widestPowerRange: widestPower * (1 / powerSteps),
      largestConnectedRegion: largestRegion,
      minimumShots: minimumShots,
      recommendedParShots: recommendedParShotsFor(
        minimumShots: minimumShots,
        successRate: totalInputs == 0 ? 0 : successInputs / totalInputs,
      ),
      successfulStrategies: successfulStrategies,
      copylessSuccess: copylessSuccess,
      strategyMetrics: strategyMetrics,
    );
  }

  int get _angleCount => (360 / angleStepDegrees).round();
}

/// 최소 샷을 그대로 파로 쓰지 않고, 분석된 성공군의 폭에 따라
/// 첫 클리어와 기록 개선 사이에 한 단계의 여유를 둔다.
int? recommendedParShotsFor({
  required int? minimumShots,
  required double successRate,
}) {
  if (minimumShots == null) {
    return null;
  }
  final cushion = successRate < 0.05 ? 2 : 1;
  return (minimumShots + cushion).clamp(1, 5).toInt();
}

class _Strategy {
  const _Strategy(this.label, this.state);

  final String label;
  final GameState state;
}

class _InputCell {
  const _InputCell({required this.degreeIndex, required this.powerStep});

  final int degreeIndex;
  final int powerStep;

  @override
  bool operator ==(Object other) {
    return other is _InputCell &&
        other.degreeIndex == degreeIndex &&
        other.powerStep == powerStep;
  }

  @override
  int get hashCode => Object.hash(degreeIndex, powerStep);
}

double _widestCircularRun(Set<_InputCell> cells, int angleCount) {
  final degrees = cells.map((cell) => cell.degreeIndex).toSet();
  var longest = 0;
  var current = 0;
  for (var index = 0; index < angleCount * 2; index++) {
    if (degrees.contains(index % angleCount)) {
      current++;
      longest = math.max(longest, current);
    } else {
      current = 0;
    }
  }
  return math.min(longest, angleCount).toDouble();
}

double _widestPowerRun(Set<_InputCell> cells) {
  final powers = cells.map((cell) => cell.powerStep).toSet().toList()..sort();
  if (powers.isEmpty) {
    return 0;
  }
  var longest = 1;
  var current = 1;
  for (var index = 1; index < powers.length; index++) {
    if (powers[index] == powers[index - 1] + 1) {
      current++;
      longest = math.max(longest, current);
    } else {
      current = 1;
    }
  }
  return math.max(0, longest - 1).toDouble();
}

int _largestConnectedRegion(Set<_InputCell> cells, int angleCount) {
  final remaining = Set<_InputCell>.of(cells);
  var largest = 0;
  while (remaining.isNotEmpty) {
    final start = remaining.first;
    final queue = <_InputCell>[start];
    remaining.remove(start);
    var size = 0;
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      size++;
      final neighbors = [
        _InputCell(
          degreeIndex: (cell.degreeIndex + 1) % angleCount,
          powerStep: cell.powerStep,
        ),
        _InputCell(
          degreeIndex: (cell.degreeIndex - 1 + angleCount) % angleCount,
          powerStep: cell.powerStep,
        ),
        _InputCell(
          degreeIndex: cell.degreeIndex,
          powerStep: cell.powerStep + 1,
        ),
        _InputCell(
          degreeIndex: cell.degreeIndex,
          powerStep: cell.powerStep - 1,
        ),
      ];
      for (final neighbor in neighbors) {
        if (remaining.remove(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    largest = math.max(largest, size);
  }
  return largest;
}
