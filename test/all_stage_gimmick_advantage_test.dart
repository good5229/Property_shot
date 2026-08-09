import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

import 'fixtures/stage10_property_shot_patterns.dart';
import 'fixtures/stage9_rotating_reflector_patterns.dart';
import 'fixtures/stage_chain_score_patterns.dart';
import 'fixtures/stage_drained_patterns.dart';
import 'fixtures/stage_persistent_patterns.dart';

void main() {
  test(
    '40개 생산 패턴은 기믹 활용 성공 영역이 무기믹 우회보다 넓다',
    () {
      const resolver = ShotResolver();
      const analyzer = CreativeChainScoreAnalyzer();
      final evidence = <_AdvantageEvidence>[];

      for (final stage in generatedStageCatalog.stages) {
        for (final pattern in stage.patterns) {
          final initial = _state(stage.stageId, stage.title, pattern);
          switch (stage.stageId) {
            case 'stage_heavy':
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  _transfer(initial, 'anvil'),
                  initial,
                ),
              );
            case 'stage_bouncy':
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  _transfer(initial, 'jelly'),
                  initial,
                ),
              );
            case 'stage_chain_gate':
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  _transfer(initial, 'steel'),
                  initial,
                ),
              );
            case 'stage_balloon':
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  _transfer(initial, 'spike_source'),
                  initial,
                ),
              );
            case 'stage_drained':
              final solution = stageDrainedRepresentativeSolutions.firstWhere(
                (item) => item.patternId == pattern.patternId,
              );
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  _transfer(initial, solution.strategyId),
                  initial,
                ),
              );
            case 'stage_speed':
              evidence.add(
                _classifySuccessfulPaths(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  initial,
                  (result) => result.powerSliderActivations.isNotEmpty,
                ),
              );
            case 'stage_persistent':
              final solution = stagePersistentRepresentativeSolutions
                  .firstWhere((item) => item.patternId == pattern.patternId);
              final first = resolver.resolve(initial, solution.firstInput);
              expect(first.state.phase, GamePhase.planning);
              final withoutPreparation = resolver.resolve(
                initial,
                solution.secondInput,
              );
              expect(
                withoutPreparation.state.phase,
                isNot(GamePhase.success),
                reason: '${pattern.patternId} 과거 공 준비 없이 같은 최종 입력이 성공합니다.',
              );
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  first.state,
                  initial,
                ),
              );
            case 'stage_chain_score':
              final solution = stageChainScoreSolutions.firstWhere(
                (item) => item.patternId == pattern.patternId,
              );
              final first = resolver.resolve(initial, solution.firstInput);
              expect(first.state.phase, GamePhase.planning);
              final second = resolver.resolve(
                first.state,
                solution.secondInput,
              );
              final chainAnalysis = analyzer.analyze(
                [first, second],
                parShots: pattern.parShots,
                optionalChallengeIds: const <String>{},
              );
              final direct = resolver.resolve(initial, solution.directInput);
              final directAnalysis = analyzer.analyze(
                [direct],
                parShots: pattern.parShots,
                optionalChallengeIds: const <String>{},
              );
              expect(second.state.phase, GamePhase.success);
              expect(
                chainAnalysis.totalScore / directAnalysis.totalScore,
                greaterThanOrEqualTo(1.45),
                reason:
                    '${pattern.patternId} 연쇄 점수=${chainAnalysis.totalScore}, '
                    '직행 점수=${directAnalysis.totalScore}',
              );
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  first.state,
                  initial,
                ),
              );
            case 'stage_rotating_reflector':
              final solution = stage9RotatingReflectorSolutions.firstWhere(
                (item) => item.patternId == pattern.patternId,
              );
              final first = resolver.resolve(initial, solution.firstInput);
              expect(first.state.phase, GamePhase.planning);
              final second = resolver.resolve(
                first.state,
                solution.secondInput,
              );
              expect(second.state.phase, GamePhase.success);
              expect([
                ...first.reflectorRotations,
                ...second.reflectorRotations,
              ], isNotEmpty);
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  first.state,
                  initial,
                ),
              );
            case 'stage_property_shot':
              final solution = stage10PropertyShotSolutions.firstWhere(
                (item) => item.patternId == pattern.patternId,
              );
              final prepared = solution.transferTrait == null
                  ? initial
                  : _transfer(
                      initial,
                      initial.entities
                          .firstWhere(
                            (entity) =>
                                entity.traits.contains(solution.transferTrait),
                          )
                          .id,
                    );
              final first = resolver.resolve(prepared, solution.firstInput);
              expect(first.state.phase, GamePhase.planning);
              final second = resolver.resolve(
                first.state,
                solution.secondInput,
              );
              final withoutPreparation = resolver.resolve(
                initial,
                solution.secondInput,
              );
              expect(second.state.phase, GamePhase.success);
              final achievedEvents = {...first.events, ...second.events};
              expect(achievedEvents, containsAll(solution.expectedEvents));
              expect(
                solution.expectedEvents.any(
                  (event) => !withoutPreparation.events.contains(event),
                ),
                isTrue,
                reason:
                    '${pattern.patternId} 준비 전 같은 최종 입력이 의도 연쇄 사건을 모두 재현합니다.',
              );
              evidence.add(
                _compareStates(
                  resolver,
                  stage.stageId,
                  pattern.patternId,
                  first.state,
                  initial,
                ),
              );
            default:
              fail('기믹 우위 검증에 등록되지 않은 스테이지: ${stage.stageId}');
          }
        }
      }

      expect(evidence, hasLength(40));
      final stageTotals = <String, ({int gimmick, int bypass})>{};
      for (final item in evidence) {
        debugPrint('$item');
        expect(item.gimmickSuccesses, greaterThan(0), reason: item.patternId);
        if (const {
          'stage_heavy',
          'stage_bouncy',
          'stage_chain_gate',
          'stage_balloon',
          'stage_drained',
          'stage_speed',
          'stage_rotating_reflector',
        }.contains(item.stageId)) {
          expect(
            item.gimmickSuccesses,
            greaterThan(item.bypassSuccesses),
            reason: '${item.patternId} 기믹 성공 영역이 우회보다 넓지 않습니다.',
          );
          final previous = stageTotals[item.stageId];
          stageTotals[item.stageId] = (
            gimmick: (previous?.gimmick ?? 0) + item.gimmickSuccesses,
            bypass: (previous?.bypass ?? 0) + item.bypassSuccesses,
          );
        }
      }
      for (final entry in stageTotals.entries) {
        final ratio = entry.value.gimmick / math.max(1, entry.value.bypass);
        debugPrint(
          '${entry.key} aggregate gimmick=${entry.value.gimmick} '
          'bypass=${entry.value.bypass} ratio=${ratio.toStringAsFixed(2)}',
        );
        expect(
          ratio,
          greaterThanOrEqualTo(1.4),
          reason: '${entry.key} 전체에서 기믹 우위가 40% 이상이 아닙니다.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

GameState _state(String stageId, String title, StagePattern pattern) => pattern
    .toLevelDefinition(stageId: stageId, stageTitle: title)
    .createState(0, productRules: true);

GameState _transfer(GameState state, String sourceId) {
  const traits = TraitResolver();
  return traits.transferSelectedTrait(traits.selectSource(state, sourceId));
}

_AdvantageEvidence _compareStates(
  ShotResolver resolver,
  String stageId,
  String patternId,
  GameState gimmickState,
  GameState bypassState,
) {
  var gimmick = 0;
  var bypass = 0;
  for (final input in _gridInputs()) {
    final gimmickInput = ShotInput(
      direction: input.direction,
      power: input.power,
      equippedTrait: gimmickState.equippedTrait,
    );
    if (resolver.resolve(gimmickState, gimmickInput).state.phase ==
        GamePhase.success) {
      gimmick++;
    }
    if (resolver.resolve(bypassState, input).state.phase == GamePhase.success) {
      bypass++;
    }
  }
  return _AdvantageEvidence(stageId, patternId, gimmick, bypass);
}

_AdvantageEvidence _classifySuccessfulPaths(
  ShotResolver resolver,
  String stageId,
  String patternId,
  GameState state,
  bool Function(ShotResult result) usesGimmick,
) {
  var gimmick = 0;
  var bypass = 0;
  for (final input in _gridInputs()) {
    final result = resolver.resolve(state, input);
    if (result.state.phase != GamePhase.success) continue;
    if (usesGimmick(result)) {
      gimmick++;
    } else {
      bypass++;
    }
  }
  return _AdvantageEvidence(stageId, patternId, gimmick, bypass);
}

Iterable<ShotInput> _gridInputs() sync* {
  for (var degree = 0; degree < 360; degree += 4) {
    final radians = degree * math.pi / 180;
    final direction = Vec2(math.cos(radians), math.sin(radians));
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      yield ShotInput(direction: direction, power: powerStep / 10);
    }
  }
}

class _AdvantageEvidence {
  const _AdvantageEvidence(
    this.stageId,
    this.patternId,
    this.gimmickSuccesses,
    this.bypassSuccesses,
  );

  final String stageId;
  final String patternId;
  final int gimmickSuccesses;
  final int bypassSuccesses;

  double get ratio => bypassSuccesses == 0
      ? double.infinity
      : gimmickSuccesses / bypassSuccesses;

  @override
  String toString() =>
      '$stageId/$patternId gimmick=$gimmickSuccesses '
      'bypass=$bypassSuccesses ratio=${ratio.toStringAsFixed(2)}';
}
