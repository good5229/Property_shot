import 'dart:math' as math;

import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../levels/levels.dart';
import '../simulation/shot_resolver.dart';
import '../simulation/trait_resolver.dart';
import '../domain/trait.dart';

/// 이전 공과 연쇄 물체가 남은 상태에서 다음 발사를 탐색하는 얕은 분석기다.
///
/// 모든 입력 조합을 무제한으로 확장하지 않고, 기획 단계에서 빠르게 비교할
/// 수 있는 각도·힘 격자를 사용한다. 실제 판정은 항상 ShotResolver에 위임한다.
class MultiShotDifficultyAnalyzer {
  const MultiShotDifficultyAnalyzer({
    this.angleStepDegrees = 20,
    this.powerSteps = 5,
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
        _SearchNode(
          state: strategy.state,
          inputs: const [],
          actions: [strategy.label],
          events: const [],
        ),
      ];
      var strategyTotal = 0;
      var strategySuccess = 0;
      var strategyCopylessSuccess = 0;
      var strategyMinimum = null as int?;
      final strategyExamples = <ShotSequencePlan>[];

      for (var depth = 1; depth <= maxShots && queue.isNotEmpty; depth++) {
        final currentDepth = List<_SearchNode>.of(queue);
        queue.clear();
        for (final node in currentDepth) {
          final actions = node.inputs.isEmpty
              ? [_Action(label: strategy.label, state: node.state)]
              : _actions(node.state);
          for (final action in actions) {
            for (final input in _inputs(action.state)) {
              strategyTotal++;
              totalSequences++;
              final result = shotResolver.resolve(action.state, input);
              final sequence = [...node.inputs, input];
              final actionSequence = node.inputs.isEmpty
                  ? node.actions
                  : [...node.actions, action.label];
              final eventSequence = [...node.events, result.events];
              if (result.state.phase == GamePhase.success) {
                strategySuccess++;
                successfulSequences++;
                strategyMinimum = strategyMinimum == null
                    ? depth
                    : math.min(strategyMinimum, depth);
                minimumShots = minimumShots == null
                    ? depth
                    : math.min(minimumShots, depth);
                final sequenceCopyless = actionSequence.every(
                  (action) => !action.contains('복제'),
                );
                if (sequenceCopyless) {
                  copylessSuccess = true;
                  strategyCopylessSuccess++;
                }
                if (strategyExamples.length < 3) {
                  strategyExamples.add(
                    ShotSequencePlan(
                      strategy: strategy.label,
                      shots: sequence,
                      actions: actionSequence,
                      events: eventSequence,
                    ),
                  );
                }
                if (examples.length < 6) {
                  examples.add(
                    ShotSequencePlan(
                      strategy: strategy.label,
                      shots: sequence,
                      actions: actionSequence,
                      events: eventSequence,
                    ),
                  );
                }
              } else if (depth < maxShots) {
                queue.add(
                  _SearchNode(
                    state: result.state,
                    inputs: sequence,
                    actions: actionSequence,
                    events: eventSequence,
                  ),
                );
              }
            }
          }
        }
      }

      strategyMetrics.add(
        SequenceStrategyMetrics(
          label: strategy.label,
          totalSequences: strategyTotal,
          successfulSequences: strategySuccess,
          copylessSuccessfulSequences: strategyCopylessSuccess,
          minimumShots: strategyMinimum,
          examples: strategyExamples,
        ),
      );
    }

    final dominantStrategyMetrics = strategyMetrics.isEmpty
        ? null
        : (List<SequenceStrategyMetrics>.of(strategyMetrics)..sort(
                (left, right) => right.successfulSequences.compareTo(
                  left.successfulSequences,
                ),
              ))
              .first;
    final dominantStrategy = dominantStrategyMetrics?.label;

    return MultiShotDifficultyMetrics(
      levelIndex: levelIndex,
      levelName: level.name,
      maxShots: maxShots,
      totalSequences: totalSequences,
      successfulSequences: successfulSequences,
      minimumShots: minimumShots,
      copylessSuccess: copylessSuccess,
      dominantStrategy: dominantStrategy,
      dominantStrategyShare: successfulSequences == 0
          ? 0
          : (dominantStrategyMetrics?.successfulSequences ?? 0) /
                successfulSequences,
      alternativeStrategyCount: math.max(
        0,
        strategyMetrics.length - (dominantStrategy == null ? 0 : 1),
      ),
      strategyMetrics: strategyMetrics,
      examples: examples,
    );
  }

  Iterable<ShotInput> _inputs(GameState state) sync* {
    for (var degree = 0; degree < 360; degree += angleStepDegrees) {
      final radians = degree * math.pi / 180;
      for (var step = 1; step <= powerSteps; step++) {
        yield ShotInput(
          direction: Vec2(math.cos(radians), math.sin(radians)),
          power: step / powerSteps,
          equippedTrait: state.equippedTrait,
        );
      }
    }
  }

  List<_Action> _actions(GameState state) {
    final actions = <_Action>[_Action(label: '유지', state: state)];
    for (final source in state.traitSources) {
      final selected = traitResolver.selectSource(state, source.id);
      actions.add(
        _Action(
          label: '${source.traits.first.label} 이전',
          state: traitResolver.transferSelectedTrait(selected),
        ),
      );
      if (state.copyCoreCount > 0) {
        actions.add(
          _Action(
            label: '${source.traits.first.label} 복제',
            state: traitResolver.copySelectedTrait(
              selected.copyWith(copyCharges: state.copyCoreCount),
            ),
          ),
        );
      }
    }
    return actions;
  }

  List<_Strategy> _strategies(int levelIndex) {
    final base = levels[levelIndex].createState(levelIndex);
    final strategies = <_Strategy>[_Strategy('무속성', base)];
    for (final source in base.traitSources) {
      final transferred = traitResolver.transferSelectedTrait(
        traitResolver.selectSource(base, source.id),
      );
      strategies.add(_Strategy('${source.traits.first.label} 이전', transferred));
      if (includeConditionalCopy) {
        final copyReady = base.copyWith(
          copyCharges: 1,
          copyChargeLimit: 1,
          copyCoreCount: 1,
        );
        final copied = traitResolver.copySelectedTrait(
          traitResolver.selectSource(copyReady, source.id),
        );
        strategies.add(_Strategy('${source.traits.first.label} 복제', copied));
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
    required this.dominantStrategy,
    required this.dominantStrategyShare,
    required this.alternativeStrategyCount,
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
  final String? dominantStrategy;
  final double dominantStrategyShare;
  final int alternativeStrategyCount;
  final List<SequenceStrategyMetrics> strategyMetrics;
  final List<ShotSequencePlan> examples;
}

class SequenceStrategyMetrics {
  const SequenceStrategyMetrics({
    required this.label,
    required this.totalSequences,
    required this.successfulSequences,
    required this.copylessSuccessfulSequences,
    required this.minimumShots,
    required this.examples,
  });

  final String label;
  final int totalSequences;
  final int successfulSequences;
  final int copylessSuccessfulSequences;
  final int? minimumShots;
  final List<ShotSequencePlan> examples;
}

class ShotSequencePlan {
  const ShotSequencePlan({
    required this.strategy,
    required this.shots,
    this.actions = const [],
    this.events = const [],
  });

  final String strategy;
  final List<ShotInput> shots;
  final List<String> actions;
  final List<List<String>> events;
}

class _Strategy {
  const _Strategy(this.label, this.state);

  final String label;
  final GameState state;
}

class _SearchNode {
  const _SearchNode({
    required this.state,
    required this.inputs,
    required this.actions,
    required this.events,
  });

  final GameState state;
  final List<ShotInput> inputs;
  final List<String> actions;
  final List<List<String>> events;
}

class _Action {
  const _Action({required this.label, required this.state});

  final String label;
  final GameState state;
}
