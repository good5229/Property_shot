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
    '40개 생산 패턴은 기믹 유형별 달성 우위 계약을 충족한다',
    () {
      const resolver = ShotResolver();
      const analyzer = CreativeChainScoreAnalyzer();
      final evidence = <_AdvantageEvidence>[];
      final typedEvidence = <_TypedAdvantage>[];

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
              typedEvidence.add(
                _persistentSequenceAdvantage(
                  resolver,
                  stage.stageId,
                  pattern,
                  solution,
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
              typedEvidence.add(
                _TypedAdvantage(
                  stageId: stage.stageId,
                  patternId: pattern.patternId,
                  kind: '연쇄 점수',
                  gimmick: chainAnalysis.totalScore,
                  bypass: directAnalysis.totalScore,
                  minimumRatio: 1.45,
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
              expect(
                withoutPreparation.state.phase,
                isNot(GamePhase.success),
                reason: '${pattern.patternId} 준비 전 같은 최종 입력이 홀에 바로 도달합니다.',
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
              typedEvidence.add(
                _propertySequenceAdvantage(
                  resolver,
                  stage.stageId,
                  pattern,
                  solution,
                ),
              );
            default:
              fail('기믹 우위 검증에 등록되지 않은 스테이지: ${stage.stageId}');
          }
        }
      }

      expect(evidence, hasLength(28));
      for (final item in evidence) {
        typedEvidence.add(
          _TypedAdvantage(
            stageId: item.stageId,
            patternId: item.patternId,
            kind: '한 발 성공 영역',
            gimmick: item.gimmickSuccesses,
            bypass: item.bypassSuccesses,
            // 셔플 변형 하나만 만난 플레이어에게도 기믹 풀이가 실제로
            // 유리해야 한다. 따라서 스테이지 합산이 아니라 각 패턴의
            // 성공 영역에서 40% 이상 우위를 요구한다.
            minimumRatio: 1.4,
          ),
        );
      }
      expect(typedEvidence, hasLength(40));
      final multiShotTotals = <String, ({num gimmick, num bypass})>{};
      for (final item in typedEvidence) {
        debugPrint('$item');
        expect(item.gimmick, greaterThan(0), reason: item.patternId);
        final minimumAbsoluteSuccesses = switch (item.kind) {
          '한 발 성공 영역' => 3,
          '준비 후 조건부 성공 영역' => 10,
          _ => 0,
        };
        if (minimumAbsoluteSuccesses > 0) {
          expect(
            item.gimmick,
            greaterThanOrEqualTo(minimumAbsoluteSuccesses),
            reason:
                '${item.patternId} ${item.kind}의 절대 성공 영역이 '
                '$minimumAbsoluteSuccesses/${item.gimmickSamples}보다 좁습니다.',
          );
        }
        expect(
          item.ratio,
          greaterThanOrEqualTo(item.minimumRatio),
          reason: '${item.patternId} ${item.kind}에서 기믹 우위가 부족합니다.',
        );
        if (item.stageId == 'stage_persistent' ||
            item.stageId == 'stage_property_shot') {
          final previous = multiShotTotals[item.stageId];
          multiShotTotals[item.stageId] = (
            gimmick: (previous?.gimmick ?? 0) + item.gimmick,
            bypass: (previous?.bypass ?? 0) + item.bypass,
          );
        }
      }
      for (final entry in multiShotTotals.entries) {
        final ratio = entry.value.bypass == 0
            ? double.infinity
            : entry.value.gimmick / entry.value.bypass;
        debugPrint(
          '${entry.key} multi-shot conditional total '
          '${entry.value.gimmick}/${entry.value.bypass} '
          'ratio=${ratio.toStringAsFixed(2)}',
        );
        expect(
          ratio,
          greaterThanOrEqualTo(1.4),
          reason: '${entry.key} 4개 변형 합산 조건부 기믹 우위가 40%에 못 미칩니다.',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

GameState _state(String stageId, String title, StagePattern pattern) => pattern
    .toLevelDefinition(stageId: stageId, stageTitle: title)
    // 물리 시드는 스테이지 인덱스를 포함한다. 모두 0으로 만들면 실제
    // 캠페인과 다른 반사/미세 오프셋을 검사하게 되어, 특히 10단계의
    // 정밀 우회 폭이 잘못 측정된다.
    .createState(_stageIndex(stageId), productRules: true);

int _stageIndex(String stageId) => switch (stageId) {
  'stage_heavy' => 0,
  'stage_bouncy' => 1,
  'stage_chain_gate' => 2,
  'stage_balloon' => 3,
  'stage_drained' => 4,
  'stage_speed' => 5,
  'stage_persistent' => 6,
  'stage_chain_score' => 7,
  'stage_rotating_reflector' => 8,
  'stage_property_shot' => 9,
  _ => throw ArgumentError.value(stageId, 'stageId', '알 수 없는 생산 스테이지'),
};

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

_TypedAdvantage _persistentSequenceAdvantage(
  ShotResolver resolver,
  String stageId,
  StagePattern pattern,
  StagePersistentSolution solution,
) {
  final initial = _state(stageId, '과거 공 재활용', pattern);
  final alternatives = stagePersistentAlternativeSolutions
      .where((item) => item.patternId == pattern.patternId)
      .toList(growable: false);
  final canonicalFirst = resolver.resolve(initial, solution.firstInput);
  expect(canonicalFirst.state.phase, isNot(GamePhase.success));
  expect(_isPersistentPreparation(canonicalFirst, solution), isTrue);
  final canonicalSecond = resolver.resolve(
    canonicalFirst.state,
    solution.secondInput,
  );
  expect(_isPersistentClear(canonicalSecond, solution), isTrue);
  final direct = alternatives.isEmpty
      ? null
      : resolver.resolve(initial, alternatives.first.firstInput);

  final bypass = _countGrid(
    initial,
    resolver,
    (result) => result.state.phase == GamePhase.success,
  );
  var localSetupClears = 0;
  for (final firstInput in _localInputs(solution.firstInput)) {
    final first = resolver.resolve(initial, firstInput);
    if (first.state.phase == GamePhase.success ||
        !_isPersistentPreparation(first, solution)) {
      continue;
    }
    final second = resolver.resolve(first.state, solution.secondInput);
    if (_isPersistentClear(second, solution)) localSetupClears++;
  }
  expect(
    localSetupClears,
    greaterThanOrEqualTo(3),
    reason: '${pattern.patternId} 준비 입력 근방의 유효 클리어가 부족합니다.',
  );
  final conditional = _countGrid(
    canonicalFirst.state,
    resolver,
    (result) => result.state.phase == GamePhase.success,
  );
  debugPrint(
    '$stageId/${pattern.patternId} conditional grid setup=$localSetupClears/15 '
    'success=$conditional bypass=$bypass '
    'ratio=${(conditional / math.max(1, bypass)).toStringAsFixed(2)}',
  );
  final chainScore = const CreativeChainScoreAnalyzer()
      .analyze(
        [canonicalFirst, canonicalSecond],
        parShots: pattern.parShots,
        optionalChallengeIds: const <String>{},
      )
      .totalScore;
  final directResults = direct == null
      ? const <ShotResult>[]
      : <ShotResult>[direct];
  final directScore = const CreativeChainScoreAnalyzer()
      .analyze(
        directResults,
        parShots: pattern.parShots,
        optionalChallengeIds: const <String>{},
      )
      .totalScore;
  debugPrint(
    '${pattern.patternId} sequence score=$chainScore/$directScore '
    'ratio=${(chainScore / math.max(1, directScore)).toStringAsFixed(2)}',
  );
  return _TypedAdvantage(
    stageId: stageId,
    patternId: pattern.patternId,
    kind: '준비 후 조건부 성공 영역',
    gimmick: conditional,
    gimmickSamples: 900,
    bypass: bypass,
    bypassSamples: 900,
    minimumRatio: 1.0001,
  );
}

bool _isPersistentPreparation(
  ShotResult first,
  StagePersistentSolution solution,
) {
  if (solution.expectedFirstImpactId case final impactId?) {
    if (!first.impacts.any((impact) => impact.entityId == impactId)) {
      return false;
    }
  }
  if (!solution.requireFirstFixed) return true;
  final spent = first.state.entityById('spent_ball_1');
  return spent?.visualState == 'stuck' && spent?.movable == false;
}

bool _isPersistentClear(ShotResult second, StagePersistentSolution solution) {
  if (second.state.phase != GamePhase.success) return false;
  if (solution.expectedSecondImpactId case final impactId?) {
    if (!second.impacts.any(
      (impact) =>
          impact.entityId == impactId || impact.sourceEntityId == impactId,
    )) {
      return false;
    }
  }
  if (solution.expectedSecondHoleSourceId case final sourceId?) {
    return second.impacts.any(
      (impact) =>
          impact.entityId == 'hole' && impact.sourceEntityId == sourceId,
    );
  }
  return true;
}

_TypedAdvantage _propertySequenceAdvantage(
  ShotResolver resolver,
  String stageId,
  StagePattern pattern,
  Stage10PropertyShotSolution solution,
) {
  final initial = _state(stageId, '속성 한방', pattern);
  final prepared = solution.transferTrait == null
      ? initial
      : _transfer(
          initial,
          initial.entities
              .firstWhere(
                (entity) => entity.traits.contains(solution.transferTrait),
              )
              .id,
        );
  final canonicalFirst = resolver.resolve(prepared, solution.firstInput);
  expect(canonicalFirst.state.phase, isNot(GamePhase.success));
  final canonicalSecond = resolver.resolve(
    canonicalFirst.state,
    solution.secondInput,
  );
  expect(
    _matchesPropertyContract(solution, canonicalFirst, canonicalSecond),
    isTrue,
  );
  if (solution.conditionalGateId case final gateId?) {
    final initialGate = initial.entityById(gateId)!;
    final openedGate = canonicalFirst.state.entityById(gateId)!;
    expect(initialGate.open, isFalse, reason: '$gateId 초기 닫힘 계약');
    expect(initialGate.solid, isTrue, reason: '$gateId 초기 차단 계약');
    expect(openedGate.open, isTrue, reason: '$gateId 첫 발 개방 계약');
    expect(openedGate.solid, isFalse, reason: '$gateId 개방 후 통과 계약');
  }
  final direct = resolver.resolve(initial, solution.directInput);
  final gridBypass = _countGrid(
    initial,
    resolver,
    (result) =>
        result.state.phase == GamePhase.success &&
        !_usesPropertyGimmick(solution, result),
  );
  final directIsBypass =
      direct.state.phase == GamePhase.success &&
      !_usesPropertyGimmick(solution, direct);
  final bypass = math.max(gridBypass, directIsBypass ? 1 : 0);
  var localSetupClears = 0;
  for (final firstInput in _localInputs(solution.firstInput)) {
    final first = resolver.resolve(prepared, firstInput);
    if (first.state.phase == GamePhase.success) continue;
    final second = resolver.resolve(first.state, solution.secondInput);
    if (_matchesPropertyContract(solution, first, second)) localSetupClears++;
  }
  expect(
    localSetupClears,
    greaterThanOrEqualTo(3),
    reason: '${pattern.patternId} 준비 입력 근방의 유효 클리어가 부족합니다.',
  );
  final conditional = _countGrid(
    canonicalFirst.state,
    resolver,
    (result) => solution.conditionalGateId == null
        ? _matchesPropertyContract(solution, canonicalFirst, result)
        : result.state.phase == GamePhase.success,
  );
  debugPrint(
    '$stageId/${pattern.patternId} conditional grid setup=$localSetupClears/15 '
    'success=$conditional bypass=$bypass '
    'ratio=${(conditional / math.max(1, bypass)).toStringAsFixed(2)}',
  );
  final chainScore = const CreativeChainScoreAnalyzer()
      .analyze(
        [canonicalFirst, canonicalSecond],
        parShots: pattern.parShots,
        optionalChallengeIds: const <String>{},
      )
      .totalScore;
  final directScore = const CreativeChainScoreAnalyzer()
      .analyze(
        [direct],
        parShots: pattern.parShots,
        optionalChallengeIds: const <String>{},
      )
      .totalScore;
  debugPrint(
    '${pattern.patternId} sequence score=$chainScore/$directScore '
    'ratio=${(chainScore / math.max(1, directScore)).toStringAsFixed(2)}',
  );
  return _TypedAdvantage(
    stageId: stageId,
    patternId: pattern.patternId,
    kind: '준비 후 조건부 성공 영역',
    gimmick: conditional,
    gimmickSamples: 900,
    bypass: bypass,
    bypassSamples: 900,
    minimumRatio: 1.0001,
  );
}

int _countGrid(
  GameState state,
  ShotResolver resolver,
  bool Function(ShotResult result) qualifies,
) {
  var successes = 0;
  for (final input in _gridInputs()) {
    final result = resolver.resolve(
      state,
      ShotInput(
        direction: input.direction,
        power: input.power,
        equippedTrait: state.equippedTrait,
      ),
    );
    if (qualifies(result)) successes++;
  }
  return successes;
}

Iterable<ShotInput> _localInputs(ShotInput center) sync* {
  for (final degreeDelta in [-2, 0, 2]) {
    for (final powerDelta in [-.04, -.02, 0.0, .02, .04]) {
      yield _inputAround(
        center,
        angleOffset: degreeDelta,
        powerOffset: (powerDelta * 50).round(),
      );
    }
  }
}

bool _matchesPropertyContract(
  Stage10PropertyShotSolution solution,
  ShotResult first,
  ShotResult second,
) {
  if (second.state.phase != GamePhase.success) return false;
  final impacts = [...first.impacts, ...second.impacts];
  final events = [...first.events, ...second.events];
  return switch (solution.contract) {
    'A' =>
      impacts.any(
            (impact) =>
                impact.sourceEntityId == 'a_crate' &&
                impact.entityId == 'a_switch',
          ) &&
          events.contains('switch_pressed'),
    'B' =>
      first.powerSliderActivations.isNotEmpty &&
          first.reflectorRotations.isNotEmpty &&
          events.contains('jelly_bounced') &&
          _impactBefore(second, 'b_reflector', 'b_bumper'),
    'C' =>
      first.events.contains('sticky_attached') &&
          second.events.contains('spent_ball_bounced') &&
          second.events.contains('balloon_bounced') &&
          impacts.any((impact) => impact.entityId == 'spent_ball_1') &&
          second.impacts.any(
            (impact) =>
                impact.sourceEntityId == 'c_crate' &&
                impact.entityId == 'c_balloon',
          ),
    'D' =>
      [
            ...first.powerSliderActivations,
            ...second.powerSliderActivations,
          ].isNotEmpty &&
          impacts.any((impact) => impact.entityId == 'd_stone') &&
          impacts.any((impact) => impact.entityId == 'spent_ball_1'),
    _ => false,
  };
}

/// A one-shot success that fires one of the level's teaching objects is an
/// alternate gimmick solve, not a no-gimmick bypass.  The prepared and
/// unprepared regions must therefore be compared against only shots that
/// reach the hole while avoiding that pattern's core interactions.
bool _usesPropertyGimmick(
  Stage10PropertyShotSolution solution,
  ShotResult result,
) {
  final impacts = result.impacts;
  final events = result.events;
  final touched = <String>{
    for (final impact in impacts) ...[impact.entityId, impact.sourceEntityId],
  };
  return switch (solution.contract) {
    'A' =>
      touched.contains('a_crate') ||
          touched.contains('a_switch') ||
          events.contains('crate_pushed') ||
          events.contains('switch_pressed'),
    'B' =>
      touched.contains('b_slider') ||
          touched.contains('b_reflector') ||
          touched.contains('b_bumper') ||
          events.contains('power_slider_activated') ||
          events.contains('reflector_rotated') ||
          events.contains('jelly_bounced'),
    'C' =>
      touched.contains('c_sticky_target') ||
          touched.contains('spent_ball_1') ||
          touched.contains('c_crate') ||
          touched.contains('c_balloon') ||
          events.contains('sticky_attached') ||
          events.contains('spent_ball_bounced') ||
          events.contains('balloon_bounced'),
    'D' =>
      touched.contains('d_setup_slider') ||
          touched.contains('d_slider') ||
          touched.contains('d_stone') ||
          touched.contains('d_wall') ||
          touched.contains('spent_ball_1') ||
          events.contains('power_slider_activated') ||
          events.contains('existing_ball_hole_entered'),
    _ => false,
  };
}

bool _impactBefore(ShotResult result, String firstId, String secondId) {
  final first = result.impacts.indexWhere(
    (impact) => impact.entityId == firstId,
  );
  final second = result.impacts.indexWhere(
    (impact) => impact.entityId == secondId,
  );
  return first >= 0 && second > first;
}

ShotInput _inputAround(
  ShotInput center, {
  required int angleOffset,
  required int powerOffset,
}) {
  final radians =
      (math.atan2(center.direction.y, center.direction.x) +
      angleOffset * math.pi / 180);
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: (center.power + powerOffset / 50).clamp(0.12, 1),
    equippedTrait: center.equippedTrait,
  );
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

class _TypedAdvantage {
  const _TypedAdvantage({
    required this.stageId,
    required this.patternId,
    required this.kind,
    required this.gimmick,
    this.gimmickSamples = 1,
    required this.bypass,
    this.bypassSamples = 1,
    required this.minimumRatio,
  });

  final String stageId;
  final String patternId;
  final String kind;
  final num gimmick;
  final num gimmickSamples;
  final num bypass;
  final num bypassSamples;
  final double minimumRatio;

  double get gimmickRate => gimmick / math.max(1, gimmickSamples);

  double get bypassRate => bypass / math.max(1, bypassSamples);

  double get ratio =>
      bypassRate == 0 ? double.infinity : gimmickRate / bypassRate;

  @override
  String toString() =>
      '$stageId/$patternId $kind gimmick=$gimmick/$gimmickSamples '
      'bypass=$bypass/$bypassSamples ratio=${ratio.toStringAsFixed(2)} '
      'minimum=${minimumRatio.toStringAsFixed(2)}';
}
