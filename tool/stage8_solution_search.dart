// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/analysis/stage_chain_challenge.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

const _resolver = ShotResolver();
const _analyzer = CreativeChainScoreAnalyzer();
const _challenge = StageChainChallengeEvaluator();

void main() {
  final stage = generatedStageCatalog.stageById('stage_chain_score');
  final requested = Platform.environment['STAGE8_PATTERN'];
  final firstDegreeStep = _environmentInt('STAGE8_FIRST_DEGREE_STEP', 20);
  final firstPowerStep = _environmentInt('STAGE8_FIRST_POWER_STEP', 4);
  final secondDegreeStep = _environmentInt('STAGE8_SECOND_DEGREE_STEP', 4);
  final secondPowerStep = _environmentInt('STAGE8_SECOND_POWER_STEP', 4);
  final firstDegree = int.tryParse(
    Platform.environment['STAGE8_FIRST_DEGREE'] ?? '',
  );
  final firstPower = int.tryParse(
    Platform.environment['STAGE8_FIRST_POWER'] ?? '',
  );
  final secondDegree = int.tryParse(
    Platform.environment['STAGE8_SECOND_DEGREE'] ?? '',
  );
  final secondPower = int.tryParse(
    Platform.environment['STAGE8_SECOND_POWER'] ?? '',
  );
  final requiredTargets =
      (Platform.environment['STAGE8_REQUIRED_TARGETS'] ?? '')
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
  final requiredOrder = (Platform.environment['STAGE8_REQUIRED_ORDER'] ?? '')
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  final requireChallenge =
      Platform.environment['STAGE8_REQUIRE_CHALLENGE'] == 'true';
  final requireAngleNeighbors =
      Platform.environment['STAGE8_REQUIRE_ANGLE_NEIGHBORS'] == 'true';

  for (final pattern in stage.patterns.where(
    (pattern) => requested == null || pattern.patternId == requested,
  )) {
    print('\n${pattern.patternId}');
    if (Platform.environment['STAGE8_SKIP_DIRECT'] != 'true') {
      final direct = _findDirect(stage, pattern);
      if (direct == null) {
        print('  직접 해법: 찾지 못함');
      } else {
        print(
          '  직접 해법: ${direct.degree}도/${_percent(direct.power)}, '
          '점수=${direct.score}, 사건=${direct.result.events.join(' → ')}',
        );
      }
    }

    final chains = _findChains(
      stage,
      pattern,
      firstDegreeStep: firstDegreeStep,
      firstPowerStep: firstPowerStep,
      secondDegreeStep: secondDegreeStep,
      secondPowerStep: secondPowerStep,
      requiredTargets: requiredTargets,
      requiredOrder: requiredOrder,
      firstDegree: firstDegree,
      firstPower: firstPower,
      secondDegree: secondDegree,
      secondPower: secondPower,
      requireChallenge: requireChallenge,
      requireAngleNeighbors: requireAngleNeighbors,
    );
    if (chains.isEmpty) {
      print('  연쇄 해법: 찾지 못함');
      continue;
    }
    for (var index = 0; index < chains.length; index++) {
      final candidate = chains[index];
      final spent = candidate.first.state.entityById('spent_ball_1');
      final breakdown = candidate.analysis.breakdown;
      final causalEvents = _causalEvents(candidate.second, candidate.analysis);
      final challengeAchieved = const StageChainChallengeEvaluator().isAchieved(
        patternId: pattern.patternId,
        analysis: candidate.analysis,
        results: [candidate.first, candidate.second],
      );
      print(
        '  연쇄 ${index + 1}: 첫 ${candidate.firstDegree}도/'
        '${_percent(candidate.firstPower)} → 둘째 ${candidate.secondDegree}도/'
        '${_percent(candidate.secondPower)}, 점수=${candidate.analysis.totalScore}',
      );
      print(
        '    첫 공=${spent?.position.x.toStringAsFixed(1)},'
        '${spent?.position.y.toStringAsFixed(1)} '
        '상태=${spent?.visualState} 이동=${spent?.movable}',
      );
      print('    첫 사건=${candidate.first.events.join(' → ')}');
      print('    첫 물리=${_eventSequence(candidate.first.physicsEvents)}');
      print('    둘째 사건=${candidate.second.events.join(' → ')}');
      print('    전체=${_eventSequence(candidate.second.physicsEvents)}');
      print(
        '    인과=${_eventSequence(causalEvents)} '
        '홀 발사=${candidate.analysis.holeShotIndex} '
        '깊이=${breakdown.causalDepth} 벽=${breakdown.wallReflectionCount} '
        '과거 공=${breakdown.pastBallCount} 발판=${breakdown.powerSliderCount} '
        '이동=${breakdown.movedEntityCount} 준비=${breakdown.preparationShotCount} '
        '추가 도전=$challengeAchieved',
      );
    }
  }
}

_DirectCandidate? _findDirect(StageDefinition stage, StagePattern pattern) {
  final base = _state(stage, pattern);
  _DirectCandidate? best;
  for (var degree = 0; degree < 360; degree += 2) {
    for (var step = 6; step <= 50; step++) {
      final result = _resolver.resolve(base, _input(degree, step / 50));
      if (result.state.phase != GamePhase.success) continue;
      final analysis = _analyzer.analyze([result], parShots: pattern.parShots);
      final candidate = _DirectCandidate(
        degree: degree,
        power: step / 50,
        result: result,
        score: analysis.totalScore,
      );
      if (best == null || candidate.score < best.score) best = candidate;
    }
  }
  return best;
}

List<_ChainCandidate> _findChains(
  StageDefinition stage,
  StagePattern pattern, {
  required int firstDegreeStep,
  required int firstPowerStep,
  required int secondDegreeStep,
  required int secondPowerStep,
  required Set<String> requiredTargets,
  required List<String> requiredOrder,
  required int? firstDegree,
  required int? firstPower,
  required int? secondDegree,
  required int? secondPower,
  required bool requireChallenge,
  required bool requireAngleNeighbors,
}) {
  final base = _state(stage, pattern);
  final best = <_ChainCandidate>[];
  for (
    var firstDegreeValue = firstDegree ?? 0;
    firstDegreeValue < (firstDegree == null ? 360 : firstDegree + 1);
    firstDegreeValue += firstDegree == null ? firstDegreeStep : 360
  ) {
    for (
      var firstStep = firstPower ?? 6;
      firstStep <= (firstPower ?? 50);
      firstStep += firstPower == null ? firstPowerStep : 51
    ) {
      final first = _resolver.resolve(
        base,
        _input(firstDegreeValue, firstStep / 50),
      );
      if (first.state.phase == GamePhase.success ||
          first.state.entityById('spent_ball_1') == null) {
        continue;
      }
      for (
        var secondDegreeValue = secondDegree ?? 0;
        secondDegreeValue < (secondDegree == null ? 360 : secondDegree + 1);
        secondDegreeValue += secondDegree == null ? secondDegreeStep : 360
      ) {
        for (
          var secondStep = secondPower ?? 6;
          secondStep <= (secondPower ?? 50);
          secondStep += secondPower == null ? secondPowerStep : 51
        ) {
          final second = _resolver.resolve(
            first.state,
            _input(secondDegreeValue, secondStep / 50),
          );
          if (second.state.phase != GamePhase.success) continue;
          final analysis = _analyzer.analyze(
            [first, second],
            parShots: pattern.parShots,
            // 우위 계약과 동일하게 선택 도전 보너스를 제외한 기본 점수로
            // 후보를 정렬한다. 보너스로 약한 연쇄가 강해 보이는 오판을 막는다.
            optionalChallengeIds: const <String>{},
          );
          final causalEvents = _causalEvents(second, analysis);
          final targetIds = {
            for (final event in causalEvents) event.targetEntityId,
          };
          if (!targetIds.containsAll(requiredTargets)) continue;
          if (!_containsTargetOrder(causalEvents, requiredOrder)) {
            continue;
          }
          final challengeAchieved = _challenge.isAchieved(
            patternId: pattern.patternId,
            analysis: analysis,
            results: [first, second],
          );
          if (requireChallenge && !challengeAchieved) continue;
          if (requireAngleNeighbors &&
              !_hasAngleNeighbors(
                stage,
                pattern,
                firstDegreeValue,
                firstStep / 50,
                secondDegreeValue,
                secondStep / 50,
              )) {
            continue;
          }
          final candidate = _ChainCandidate(
            firstDegree: firstDegreeValue,
            firstPower: firstStep / 50,
            secondDegree: secondDegreeValue,
            secondPower: secondStep / 50,
            first: first,
            second: second,
            analysis: analysis,
          );
          _insertCandidate(best, candidate);
        }
      }
    }
  }
  return best;
}

bool _hasAngleNeighbors(
  StageDefinition stage,
  StagePattern pattern,
  int firstDegree,
  double firstPower,
  int secondDegree,
  double secondPower,
) {
  bool succeeds(int firstAngle, int secondAngle) {
    final first = _resolver.resolve(
      _state(stage, pattern),
      _input(firstAngle % 360, firstPower),
    );
    if (first.state.phase == GamePhase.success) return false;
    final second = _resolver.resolve(
      first.state,
      _input(secondAngle % 360, secondPower),
    );
    if (second.state.phase != GamePhase.success) return false;
    final results = [first, second];
    final analysis = _analyzer.analyze(
      results,
      parShots: pattern.parShots,
      optionalChallengeIds: CreativeChainChallengeId.all,
    );
    return _challenge.isAchieved(
      patternId: pattern.patternId,
      analysis: analysis,
      results: results,
    );
  }

  final firstNeighbor =
      succeeds(firstDegree - 1, secondDegree) ||
      succeeds(firstDegree + 1, secondDegree);
  if (!firstNeighbor) return false;
  return succeeds(firstDegree, secondDegree - 1) ||
      succeeds(firstDegree, secondDegree + 1);
}

List<PhysicsEvent> _causalEvents(
  ShotResult result,
  CreativeChainScoreAnalysis analysis,
) {
  final ids = analysis.causalEventIds
      .where((id) => id.startsWith('1:'))
      .map((id) => id.substring(2))
      .toSet();
  return [
    for (final event in result.physicsEvents)
      if (ids.contains(event.eventId)) event,
  ];
}

bool _containsTargetOrder(
  List<PhysicsEvent> events,
  List<String> requiredOrder,
) {
  if (requiredOrder.isEmpty) return true;
  var nextIndex = 0;
  for (final event in events) {
    if (event.targetEntityId != requiredOrder[nextIndex]) continue;
    nextIndex++;
    if (nextIndex == requiredOrder.length) return true;
  }
  return false;
}

void _insertCandidate(List<_ChainCandidate> best, _ChainCandidate candidate) {
  final signature =
      '${candidate.firstDegree}:${candidate.firstPower}:'
      '${candidate.secondDegree}:${candidate.secondPower};';
  if (best.any((item) => item.signature == signature)) return;
  best.add(candidate);
  best.sort((left, right) {
    final score = right.analysis.totalScore.compareTo(left.analysis.totalScore);
    if (score != 0) return score;
    return right.analysis.breakdown.causalDepth.compareTo(
      left.analysis.breakdown.causalDepth,
    );
  });
  if (best.length > 5) best.removeLast();
}

GameState _state(StageDefinition stage, StagePattern pattern) => pattern
    .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
    .createState(6, productRules: true);

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}

int _environmentInt(String name, int fallback) {
  final value = int.tryParse(Platform.environment[name] ?? '') ?? fallback;
  if (value <= 0) {
    throw ArgumentError.value(value, name, '1 이상이어야 합니다.');
  }
  return value;
}

String _eventSequence(List<PhysicsEvent> events) => events
    .where(
      (event) =>
          event.kind == PhysicsEventKind.impact ||
          event.kind == PhysicsEventKind.powerSliderActivation ||
          event.kind == PhysicsEventKind.stateChange ||
          event.kind == PhysicsEventKind.move,
    )
    .map(
      (event) =>
          '${event.kind.name}:${event.targetEntityId}'
          '@${event.position.x.toStringAsFixed(1)},'
          '${event.position.y.toStringAsFixed(1)}',
    )
    .join(' → ');

String _percent(double power) => '${(power * 100).round()}%';

class _DirectCandidate {
  const _DirectCandidate({
    required this.degree,
    required this.power,
    required this.result,
    required this.score,
  });

  final int degree;
  final double power;
  final ShotResult result;
  final int score;
}

class _ChainCandidate {
  const _ChainCandidate({
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
    required this.first,
    required this.second,
    required this.analysis,
  });

  final int firstDegree;
  final double firstPower;
  final int secondDegree;
  final double secondPower;
  final ShotResult first;
  final ShotResult second;
  final CreativeChainScoreAnalysis analysis;

  String get signature =>
      '$firstDegree:$firstPower:'
      '$secondDegree:$secondPower;';
}
