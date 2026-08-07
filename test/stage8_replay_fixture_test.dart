import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/analysis/stage_chain_challenge.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import '../tool/generate_stage8_replay_fixtures.dart' as stage8_fixtures;

void main() {
  test('8단계 네 패턴의 직접·고연쇄 리플레이가 점수와 인과를 재현한다', () {
    final root =
        jsonDecode(
              File(
                'harness_docs/qa/replays/stage8_chain_score_fixtures.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final records = (root['fixtures'] as List).cast<Map>();
    final stage = generatedStageCatalog.stageById('stage_chain_score');

    expect(root['schemaVersion'], 1);
    expect(root['stageId'], stage.stageId);
    expect(records, hasLength(8));
    for (final pattern in stage.patterns) {
      final patternRecords = records.where(
        (record) => record['patternId'] == pattern.patternId,
      );
      expect(patternRecords, hasLength(2));
      expect(patternRecords.map((record) => record['routeKind']).toSet(), {
        'direct',
        'chain',
      });
    }

    for (final raw in records) {
      final record = Map<String, Object?>.from(raw);
      final patternId = record['patternId'] as String;
      final pattern = stage.patternById(patternId);
      final fixture = ReplayFixture.fromJson(
        Map<String, Object?>.from(record['fixture'] as Map),
      );
      final initial = pattern
          .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
          .createState(7, productRules: true);
      var state = initial;
      final results = <ShotResult>[];
      for (var index = 0; index < fixture.shots.length; index++) {
        final result = const ShotResolver().resolve(
          state,
          fixture.shots[index].toInput(),
        );
        expect(
          shotResultFingerprint(result),
          fixture.expectedFingerprints[index],
          reason: fixture.id,
        );
        results.add(result);
        state = result.state;
      }
      expect(state.phase.name, fixture.expectedPhase, reason: fixture.id);

      final analysis = const CreativeChainScoreAnalyzer().analyzeReplay(
        fixture,
        results,
        parShots: pattern.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
      );
      expect(analysis.replayMatchesFixture, isTrue, reason: fixture.id);
      expect(analysis.totalScore, record['expectedScore'], reason: fixture.id);
      expect(
        analysis.replaySignature,
        record['expectedReplaySignature'],
        reason: fixture.id,
      );
      expect(
        const StageChainChallengeEvaluator().isAchieved(
          patternId: patternId,
          analysis: analysis,
          results: results,
        ),
        record['expectedChallengeAchieved'],
        reason: fixture.id,
      );
      expect(
        _breakdown(analysis.breakdown),
        Map<String, Object?>.from(record['expectedBreakdown'] as Map),
        reason: fixture.id,
      );
      final repeated = <ShotResult>[];
      var repeatedState = initial;
      for (final shot in fixture.shots) {
        final result = const ShotResolver().resolve(
          repeatedState,
          shot.toInput(),
        );
        repeated.add(result);
        repeatedState = result.state;
      }
      final safety = stage8_fixtures.stage8ReplaySafety(
        initial: initial,
        shots: fixture.shots,
        results: results,
        repeated: repeated,
      );
      expect(
        safety,
        Map<String, Object?>.from(record['expectedSafety'] as Map),
        reason: '${fixture.id} 다중샷 안전성',
      );
      for (final key in const [
        'deterministic',
        'finite',
        'noChainSafetyStop',
        'wallsUnchanged',
        'uniqueEntityIds',
        'dynamicObjectsInField',
        'initialNoForbiddenOverlaps',
        'terminalNoForbiddenOverlaps',
        'noHighSpeedTunneling',
        'capturedBallsHaveNoFollowUp',
        'nonSuccessShotsHaveActiveBall',
        'multiShotNoSoftlock',
        'terminalSuccess',
      ]) {
        expect(safety[key], isTrue, reason: '${fixture.id} 안전성: $key');
      }
    }
  });

  test('다음 대표 입력이 결과와 다르면 소프트락 안전 증거가 실패한다', () {
    final root =
        jsonDecode(
              File(
                'harness_docs/qa/replays/stage8_chain_score_fixtures.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final raw = (root['fixtures'] as List).cast<Map>().firstWhere(
      (record) => record['routeKind'] == 'chain',
    );
    final patternId = raw['patternId'] as String;
    final fixture = ReplayFixture.fromJson(
      Map<String, Object?>.from(raw['fixture'] as Map),
    );
    final stage = generatedStageCatalog.stageById('stage_chain_score');
    final initial = stage
        .patternById(patternId)
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(7, productRules: true);
    final results = <ShotResult>[];
    var state = initial;
    for (final shot in fixture.shots) {
      final result = const ShotResolver().resolve(state, shot.toInput());
      results.add(result);
      state = result.state;
    }
    final tamperedShots = [
      fixture.shots.first,
      ReplayShotFixture(
        angleRadians: fixture.shots[1].angleRadians + 0.2,
        power: fixture.shots[1].power,
        equippedTrait: fixture.shots[1].equippedTrait,
      ),
    ];

    final safety = stage8_fixtures.stage8ReplaySafety(
      initial: initial,
      shots: tamperedShots,
      results: results,
      repeated: results,
    );

    expect(safety['multiShotNoSoftlock'], isFalse);
    final evidence = Map<String, Object?>.from(safety['safetyEvidence'] as Map);
    expect(evidence['verifiedFollowUpShotCount'], 0);
    expect(evidence['firstFollowUpFailure'], isNotNull);
  });
}

Map<String, int> _breakdown(CreativeChainScoreBreakdown value) {
  return {
    'totalPoints': value.totalPoints,
    'causalDepth': value.causalDepth,
    'causalEventCount': value.causalEventCount,
    'distinctEntityTypes': value.distinctEntityTypes,
    'wallReflectionCount': value.wallReflectionCount,
    'pastBallCount': value.pastBallCount,
    'powerSliderCount': value.powerSliderCount,
    'movedEntityCount': value.movedEntityCount,
    'preparationShotCount': value.preparationShotCount,
    'qualifiedImpactCount': value.qualifiedImpactCount,
  };
}
