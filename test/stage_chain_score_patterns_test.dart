import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/analysis/stage_chain_challenge.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import 'fixtures/stage_chain_score_patterns.dart';

void main() {
  const resolver = ShotResolver();
  const analyzer = CreativeChainScoreAnalyzer();
  const challengeEvaluator = StageChainChallengeEvaluator();
  late StageDefinition stage;

  setUpAll(() {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_chain_score');
  });

  test('8단계는 직접 풀이와 고연쇄 풀이를 함께 제공하는 네 패턴을 가진다', () {
    expect(stage.title, '8. 세 번 이어라');
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_chain_score_01',
      'stage_chain_score_02',
      'stage_chain_score_03',
      'stage_chain_score_04',
    ]);
    expect(
      stage.patterns.where((pattern) => pattern.metadata['baseline'] == 'true'),
      hasLength(1),
    );
    expect(
      stage.patterns.every(
        (pattern) => pattern.acceptedStrategyIds.contains('none'),
      ),
      isTrue,
    );
    expect(
      stage.patterns.every((pattern) => pattern.solutionFamilies.length >= 2),
      isTrue,
    );
  });

  test('각 패턴은 과거 공을 포함해 핵심 기물 5~7종과 움직이지 않는 벽을 사용한다', () {
    for (final pattern in stage.patterns) {
      final keyTypes = {
        for (final object in pattern.objects)
          if (object.type != EntityType.hole) object.type,
        EntityType.ball,
      };
      expect(
        keyTypes.length,
        inInclusiveRange(5, 7),
        reason: '${pattern.patternId}: $keyTypes',
      );
      expect(
        pattern.objects
            .where((object) => object.type == EntityType.wall)
            .every((wall) => !wall.movable && wall.solid),
        isTrue,
      );
    }
  });

  for (final solution in stageChainScoreSolutions) {
    test('${solution.patternId} 1발 대체 경로는 벽·기물을 거쳐 성공한다', () {
      _expectUiPower(solution.directPower);
      final pattern = stage.patternById(solution.patternId);
      final result = resolver.resolve(_state(pattern), solution.directInput);
      final analysis = analyzer.analyze(
        [result],
        parShots: pattern.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
      );

      expect(
        result.state.phase,
        GamePhase.success,
        reason: '${solution.patternId}: ${result.events.join(' → ')}',
      );
      expect(analysis.clearReached, isTrue);
      expect(
        result.impacts.any((impact) => impact.entityType != EntityType.hole),
        isTrue,
        reason: '${solution.patternId}: 열린 직선 슛을 대체 경로로 두지 않는다.',
      );
      expect(analysis.breakdown.causalDepth, greaterThanOrEqualTo(1));
      expect(analysis.breakdown.pastBallCount, 0);
      expect(analysis.totalScore, greaterThan(1035));
      expect(
        challengeEvaluator.isAchieved(
          patternId: solution.patternId,
          analysis: analysis,
          results: [result],
        ),
        isFalse,
      );
    });

    test('${solution.patternId} 고연쇄 경로는 사건 순서와 점수 근거를 재현한다', () {
      _expectUiPower(solution.firstPower);
      _expectUiPower(solution.secondPower);
      final pattern = stage.patternById(solution.patternId);
      final initial = _state(pattern);
      final first = resolver.resolve(initial, solution.firstInput);
      final second = resolver.resolve(first.state, solution.secondInput);
      final analysis = analyzer.analyze(
        [first, second],
        parShots: pattern.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
      );

      expect(first.state.phase, GamePhase.planning);
      expect(first.state.entityById('spent_ball_1'), isNotNull);
      expect(
        second.state.phase,
        GamePhase.success,
        reason: '${solution.patternId}: ${second.events.join(' → ')}',
      );
      expect(
        _containsCausalTargetOrder(
          second.physicsEvents,
          analysis,
          1,
          solution.expectedTargetOrder,
        ),
        isTrue,
        reason: _targetSequence(second.physicsEvents),
      );
      expect(analysis.clearReached, isTrue);
      expect(analysis.breakdown.pastBallCount, 1);
      expect(analysis.breakdown.preparationShotCount, 1);
      expect(analysis.breakdown.qualifiedImpactCount, lessThanOrEqualTo(12));
      expect(
        analysis.totalScore,
        greaterThanOrEqualTo(solution.minimumChainScore),
      );
      expect(
        challengeEvaluator.isAchieved(
          patternId: solution.patternId,
          analysis: analysis,
          results: [first, second],
        ),
        isTrue,
      );
      expect(
        analysis.evidence.fold<int>(
          0,
          (sum, evidence) => sum + evidence.points,
        ),
        analysis.totalScore,
      );

      final direct = resolver.resolve(initial, solution.directInput);
      final directAnalysis = analyzer.analyze(
        [direct],
        parShots: pattern.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
      );
      expect(analysis.totalScore, greaterThan(directAnalysis.totalScore));

      for (final wall in initial.entities.where(
        (entity) => entity.type == EntityType.wall,
      )) {
        expect(second.state.entityById(wall.id)?.position, wall.position);
        expect(second.state.entityById(wall.id)?.movable, isFalse);
      }
    });

    test('${solution.patternId} 같은 입력은 같은 점수 서명을 만든다', () {
      final pattern = stage.patternById(solution.patternId);
      final firstRun = _resolveChain(pattern, solution);
      final secondRun = _resolveChain(pattern, solution);
      final firstAnalysis = analyzer.analyze(
        firstRun,
        parShots: pattern.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
        replayContext: solution.patternId,
      );
      final secondAnalysis = analyzer.analyze(
        secondRun,
        parShots: pattern.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
        replayContext: solution.patternId,
      );

      expect(secondAnalysis.totalScore, firstAnalysis.totalScore);
      expect(secondAnalysis.breakdown.totalPoints, firstAnalysis.totalScore);
      expect(secondAnalysis.replaySignature, firstAnalysis.replaySignature);
      expect(
        _targetSequence(secondRun.last.physicsEvents),
        _targetSequence(firstRun.last.physicsEvents),
      );
    });
  }

  test('세 번째 패턴은 힘 발판 다음 돌과 벽, 과거 공 순서를 지킨다', () {
    final pattern = stage.patternById('stage_chain_score_03');
    final solution = stageChainScoreSolutions[2];
    final results = _resolveChain(pattern, solution);
    final analysis = analyzer.analyze(
      results,
      parShots: pattern.parShots,
      optionalChallengeIds: CreativeChainChallengeId.all,
    );

    expect(analysis.breakdown.powerSliderCount, 1);
    expect(analysis.breakdown.wallReflectionCount, greaterThanOrEqualTo(2));
    expect(
      _containsCausalTargetOrder(
        results.last.physicsEvents,
        analysis,
        1,
        const ['speed_slider', 'chain_stone', 'bounce_wall', 'spent_ball_1'],
      ),
      isTrue,
    );
    expect(
      challengeEvaluator.isAchieved(
        patternId: solution.patternId,
        analysis: analysis,
        results: results,
      ),
      isTrue,
    );
  });

  test('네 번째 패턴은 네 종류 이상의 기물을 잇고도 풍선 터뜨리기를 강제하지 않는다', () {
    final pattern = stage.patternById('stage_chain_score_04');
    final solution = stageChainScoreSolutions[3];
    final results = _resolveChain(pattern, solution);
    final analysis = analyzer.analyze(
      results,
      parShots: pattern.parShots,
      optionalChallengeIds: CreativeChainChallengeId.all,
    );

    expect(analysis.breakdown.distinctEntityTypes, greaterThanOrEqualTo(4));
    expect(results.last.events, isNot(contains('balloon_popped')));
  });
}

List<ShotResult> _resolveChain(
  StagePattern pattern,
  StageChainScoreSolution solution,
) {
  const resolver = ShotResolver();
  final first = resolver.resolve(_state(pattern), solution.firstInput);
  final second = resolver.resolve(first.state, solution.secondInput);
  return [first, second];
}

bool _containsCausalTargetOrder(
  List<PhysicsEvent> events,
  CreativeChainScoreAnalysis analysis,
  int shotIndex,
  List<String> expectedOrder,
) {
  final causalIds = analysis.causalEventIds
      .where((id) => id.startsWith('$shotIndex:'))
      .map((id) => id.substring(id.indexOf(':') + 1))
      .toSet();
  var nextIndex = 0;
  for (final event in events) {
    if (!causalIds.contains(event.eventId)) continue;
    if (event.targetEntityId != expectedOrder[nextIndex]) continue;
    nextIndex++;
    if (nextIndex == expectedOrder.length) return true;
  }
  return false;
}

String _targetSequence(List<PhysicsEvent> events) => events
    .map((event) => '${event.kind.name}:${event.targetEntityId}')
    .join(' → ');

void _expectUiPower(double power) {
  expect(power, inInclusiveRange(0.12, 1));
  expect((power * 50 - (power * 50).round()).abs(), lessThan(0.000001));
}

GameState _state(StagePattern pattern) => pattern
    .toLevelDefinition(stageId: 'stage_chain_score', stageTitle: '8. 세 번 이어라')
    .createState(7, productRules: true);
