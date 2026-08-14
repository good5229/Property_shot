// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/analysis/multi_shot_analyzer.dart';
import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/game_state.dart';
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
    final seed = _validatedTwoShotSeed(stageIndex);
    if (seed != null) {
      plans.add(seed);
      seen.add(_sequenceKey(seed.shots));
    }
    final candidates = [
      for (final strategy in metrics.strategyMetrics) ...strategy.examples,
    ]..sort((left, right) => right.shots.length.compareTo(left.shots.length));
    for (final plan in candidates) {
      final key = _sequenceKey(plan.shots);
      if (seen.add(key)) {
        plans.add(plan);
      }
      if (plans.length == 5) {
        break;
      }
    }
    /* 분석기 결과를 발 수 기준으로 정렬해 실제 상태 전달 시퀀스를 우선 보존한다. */
    if (plans.length < 5) {
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
    }
    if (plans.length < 5) {
      final base = levels[stageIndex].createState(
        stageIndex,
        productRules: true,
      );
      for (var degree = 0; degree < 360 && plans.length < 5; degree += 10) {
        final minimumPowerStep = stageIndex >= 6 ? 2 : 1;
        for (
          var powerStep = minimumPowerStep;
          powerStep <= 10 && plans.length < 5;
          powerStep++
        ) {
          final input = _gridInput(degree, powerStep);
          final result = resolver.resolve(base, input);
          if (result.state.phase != GamePhase.success) continue;
          final plan = ShotSequencePlan(strategy: '무속성', shots: [input]);
          if (seen.add(_sequenceKey(plan.shots))) {
            plans.add(plan);
          }
        }
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
    const JsonEncoder.withIndent('  ').convert({
      'schemaVersion': 1,
      'fixtures': fixtures.map((item) => item.toJson()).toList(),
    }),
  );
  print('다중샷 리플레이 픽스처 ${fixtures.length}개 생성: ${file.path}');
}

ShotSequencePlan? _validatedTwoShotSeed(int stageIndex) {
  if (stageIndex < 0 || stageIndex >= levels.length) {
    return null;
  }
  if (stageIndex == 6) {
    return ShotSequencePlan(
      strategy: '과거 공 쿠션',
      shots: [_angleInput(20, 0.12), _angleInput(170, 0.66)],
    );
  }
  if (stageIndex == 7) {
    return ShotSequencePlan(
      strategy: '3쿠션과 점착 과거 공 연쇄',
      shots: [_angleInput(22, 0.12), _angleInput(158, 0.88)],
    );
  }

  // 레벨 배치가 조금 바뀌어도 고정 좌표 시드가 낡지 않도록,
  // 결정된 격자에서 첫 발 실패·둘째 발 성공 조합을 찾는다.
  final initial = levels[stageIndex].createState(
    stageIndex,
    productRules: true,
  );
  final minimumPowerStep = stageIndex >= 6 ? 2 : 1;
  for (var firstDegree = 0; firstDegree < 360; firstDegree += 10) {
    for (
      var firstPowerStep = minimumPowerStep;
      firstPowerStep <= 10;
      firstPowerStep++
    ) {
      final firstInput = _gridInput(firstDegree, firstPowerStep);
      final first = resolver.resolve(initial, firstInput);
      if (first.state.phase == GamePhase.success) {
        continue;
      }
      for (var secondDegree = 0; secondDegree < 360; secondDegree += 10) {
        for (
          var secondPowerStep = minimumPowerStep;
          secondPowerStep <= 10;
          secondPowerStep++
        ) {
          final secondInput = _gridInput(secondDegree, secondPowerStep);
          final second = resolver.resolve(first.state, secondInput);
          if (second.state.phase == GamePhase.success) {
            return ShotSequencePlan(
              strategy: '무속성',
              shots: [firstInput, secondInput],
            );
          }
        }
      }
    }
  }
  throw StateError('단계 ${stageIndex + 1}의 격자에서 검증된 2발 시드를 찾지 못했습니다.');
}

ShotInput _angleInput(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}

ShotInput _gridInput(int degree, int powerStep) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: powerStep / 10,
  );
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
