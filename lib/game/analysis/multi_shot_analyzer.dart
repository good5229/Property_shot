import 'dart:math' as math;

import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../levels/levels.dart';
import '../simulation/shot_resolver.dart';
import '../simulation/trait_resolver.dart';

/// 이전 공과 연쇄 물체가 남은 상태에서 다음 발사를 탐색하는 얕은 분석기다.
///
/// 모든 입력 조합을 무제한으로 확장하지 않고, 기획 단계에서 빠르게 비교할
/// 수 있는 각도·힘 격자를 사용한다. 실제 판정은 항상 ShotResolver에 위임한다.
class MultiShotDifficultyAnalyzer {
  const MultiShotDifficultyAnalyzer({
    this.angleStepDegrees = 30,
    this.powerSteps = 4,
    this.maxShots = 2,
    this.includeConditionalCopy = true,
    this.shotResolver = const ShotResolver(),
    this.traitResolver = const TraitResolver(),
  });

  final int angleStepDegrees;
  final int powerSteps;
  final int maxShots;
  final bool includeConditionalCopy;
  final ShotResolver shotResolver;
  final TraitResolver traitResolver;

  MultiShotDifficultyMetrics analyzeLevel(int levelIndex) {
    final level = levels[levelIndex];
    var totalSequences = 0;
    var successfulSequences = 0;
    var minimumShots = null as int?;
    var copylessSuccess = false;
    final strategyMetrics = <SequenceStrategyMetrics>[];
    final examples = <ShotSequencePlan>[];

    for (final strategy in _strategies(levelIndex)) {
      final queue = <_SearchNode>[
        _SearchNode(state: strategy.state, inputs: const []),
      ];
      var strategyTotal = 0;
      var strategySuccess = 0;
      var strategyMinimum = null as int?;
      final strategyExamples = <ShotSequencePlan>[];

      for (var depth = 1; depth <= maxShots && queue.isNotEmpty; depth++) {
        final currentDepth = List<_SearchNode>.of(queue);
        queue.clear();
        for (final node in currentDepth) {
          for (final input in _inputs(node.state, node.inputs.isEmpty)) {
            strategyTotal++;
            totalSequences++;
            final result = shotResolver.resolve(node.state, input);
            final sequence = [...node.inputs, input];
            if (result.state.phase == GamePhase.success) {
              strategySuccess++;
              successfulSequences++;
              strategyMinimum = strategyMinimum == null
                  ? depth
                  : math.min(strategyMinimum, depth);
              minimumShots = minimumShots == null
                  ? depth
                  : math.min(minimumShots, depth);
              if (!strategy.label.contains('복제')) {
                copylessSuccess = true;
              }
              if (strategyExamples.length < 3) {
                strategyExamples.add(
                  ShotSequencePlan(strategy: strategy.label, shots: sequence),
                );
              }
              if (examples.length < 6) {
                examples.add(
                  ShotSequencePlan(strategy: strategy.label, shots: sequence),
                );
              }
            } else if (depth < maxShots) {
              queue.add(_SearchNode(state: result.state, inputs: sequence));
            }
          }
        }
      }

      strategyMetrics.add(
        SequenceStrategyMetrics(
          label: strategy.label,
          totalSequences: strategyTotal,
          successfulSequences: strategySuccess,
          minimumShots: strategyMinimum,
          examples: strategyExamples,
        ),
      );
    }

    return MultiShotDifficultyMetrics(
      levelIndex: levelIndex,
      levelName: level.name,
      maxShots: maxShots,
      totalSequences: totalSequences,
      successfulSequences: successfulSequences,
      minimumShots: minimumShots,
      copylessSuccess: copylessSuccess,
      strategyMetrics: strategyMetrics,
      examples: examples,
    );
  }

  Iterable<ShotInput> _inputs(GameState state, bool firstShot) sync* {
    for (var degree = 0; degree < 360; degree += angleStepDegrees) {
      final radians = degree * math.pi / 180;
      for (var step = 1; step <= powerSteps; step++) {
        yield ShotInput(
          direction: Vec2(math.cos(radians), math.sin(radians)),
          power: step / powerSteps,
          equippedTrait: firstShot ? state.equippedTrait : null,
        );
      }
    }
  }

  List<_Strategy> _strategies(int levelIndex) {
    final base = levels[levelIndex].createState(levelIndex);
    final strategies = <_Strategy>[_Strategy('무속성', base)];
    for (final source in base.traitSources) {
      final transferred = traitResolver.transferSelectedTrait(
        traitResolver.selectSource(base, source.id),
      );
      strategies.add(_Strategy('${source.id} 이전', transferred));
      if (includeConditionalCopy) {
        final copyReady = base.copyWith(
          copyCharges: 1,
          copyChargeLimit: 1,
          copyCoreCount: 1,
        );
        final copied = traitResolver.copySelectedTrait(
          traitResolver.selectSource(copyReady, source.id),
        );
        strategies.add(_Strategy('${source.id} 복제', copied));
      }
    }
    return strategies;
  }
}

class MultiShotDifficultyMetrics {
  const MultiShotDifficultyMetrics({
    required this.levelIndex,
    required this.levelName,
    required this.maxShots,
    required this.totalSequences,
    required this.successfulSequences,
    required this.minimumShots,
    required this.copylessSuccess,
    required this.strategyMetrics,
    required this.examples,
  });

  final int levelIndex;
  final String levelName;
  final int maxShots;
  final int totalSequences;
  final int successfulSequences;
  final int? minimumShots;
  final bool copylessSuccess;
  final List<SequenceStrategyMetrics> strategyMetrics;
  final List<ShotSequencePlan> examples;
}

class SequenceStrategyMetrics {
  const SequenceStrategyMetrics({
    required this.label,
    required this.totalSequences,
    required this.successfulSequences,
    required this.minimumShots,
    required this.examples,
  });

  final String label;
  final int totalSequences;
  final int successfulSequences;
  final int? minimumShots;
  final List<ShotSequencePlan> examples;
}

class ShotSequencePlan {
  const ShotSequencePlan({required this.strategy, required this.shots});

  final String strategy;
  final List<ShotInput> shots;
}

class _Strategy {
  const _Strategy(this.label, this.state);

  final String label;
  final GameState state;
}

class _SearchNode {
  const _SearchNode({required this.state, required this.inputs});

  final GameState state;
  final List<ShotInput> inputs;
}
