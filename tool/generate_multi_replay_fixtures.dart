// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/analysis/difficulty_analyzer.dart';
import 'package:property_shot/game/analysis/multi_shot_analyzer.dart';
import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

const resolver = ShotResolver();

void main() {
  final fixtures = <ReplayFixture>[];
  const analyzer = MultiShotDifficultyAnalyzer(
    angleStepDegrees: 20,
    powerSteps: 5,
    maxShots: 2,
  );

  for (var stageIndex = 0; stageIndex < levels.length; stageIndex++) {
    final metrics = analyzer.analyzeLevel(stageIndex);
    final seen = <String>{};
    final plans = <ShotSequencePlan>[];
    for (final strategy in metrics.strategyMetrics) {
      for (final plan in strategy.examples) {
        final key = _sequenceKey(plan.shots);
        if (seen.add(key)) {
          plans.add(plan);
        }
        if (plans.length == 5) {
          break;
        }
      }
      if (plans.length == 5) {
        break;
      }
    }
    if (plans.length != 5) {
      throw StateError('단계 ${stageIndex + 1}의 다중샷 예시 5개를 찾지 못했습니다.');
    }
    for (var index = 0; index < plans.length; index++) {
      fixtures.add(_fixture(stageIndex, plans[index], index));
    }
  }

  final file = File('harness_docs/qa/replays/multi_shot_fixtures.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert({'schemaVersion': 1, 'fixtures': <Map<String, Object?>>[]})
        .replaceFirst(
          '[]',
          jsonEncode(fixtures.map((item) => item.toJson()).toList()),
        ),
  );
  print('다중샷 리플레이 픽스처 ${fixtures.length}개 생성: ${file.path}');
}

ReplayFixture _fixture(int stageIndex, ShotSequencePlan plan, int index) {
  var state = levels[stageIndex].createState(
    stageIndex,
    productRules: true,
    copyCoreCount: plan.strategy.contains('복제') ? 1 : 0,
  );
  final shots = <ReplayShotFixture>[];
  final fingerprints = <String>[];
  for (final input in plan.shots) {
    shots.add(_toFixture(input));
    final result = resolver.resolve(state, input);
    fingerprints.add(shotResultFingerprint(result));
    state = result.state;
  }
  return ReplayFixture(
    id: 'stage_${stageIndex + 1}_multi_${index + 1}',
    stageIndex: stageIndex,
    routeTag: _routeTag(plan.strategy),
    shots: shots,
    expectedFingerprints: fingerprints,
    expectedPhase: state.phase.name,
    copyCoreCount: plan.strategy.contains('복제') ? 1 : 0,
  );
}

ReplayShotFixture _toFixture(ShotInput input) {
  final direction = input.direction.normalized();
  return ReplayShotFixture(
    angleRadians: math.atan2(direction.y, direction.x),
    power: input.power,
    equippedTrait: input.equippedTrait,
  );
}

String _sequenceKey(List<ShotInput> shots) {
  return shots
      .map((shot) {
        final direction = shot.direction.normalized();
        return '${direction.x.toStringAsFixed(6)}:${direction.y.toStringAsFixed(6)}:${shot.power.toStringAsFixed(6)}:${shot.equippedTrait?.name}';
      })
      .join('|');
}

String _routeTag(String strategy) {
  if (strategy.contains('무속성')) {
    return 'direct';
  }
  if (strategy.contains('복제')) {
    return 'copy';
  }
  return 'alternate';
}
