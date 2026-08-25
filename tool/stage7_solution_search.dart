// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

const resolver = ShotResolver();

void main() {
  final stage = generatedStageCatalog.stageById('stage_persistent');
  final requested = Platform.environment['STAGE7_PATTERN'];
  for (final pattern in stage.patterns.where(
    (pattern) => requested == null || pattern.patternId == requested,
  )) {
    final firstTrait = switch (pattern.patternId) {
      'stage_persistent_02' => TraitType.heavy,
      'stage_persistent_03' => TraitType.sticky,
      _ => null,
    };
    final chain = _findChain(stage, pattern, firstTrait);
    final bypass = _findBypass(stage, pattern);
    print('\n${pattern.patternId}');
    if (chain == null) {
      print('  연쇄 해법: 찾지 못함');
    } else {
      print(
        '  연쇄 해법: 첫 ${chain.firstDegree}도/${_percent(chain.firstPower)}% '
        '${firstTrait?.label ?? '무속성'} → '
        '둘째 ${chain.secondDegree}도/${_percent(chain.secondPower)}%',
      );
      print('  첫 사건: ${chain.first.events.join(' → ')}');
      print('  둘째 사건: ${chain.second.events.join(' → ')}');
      final firstSpent = chain.first.state.entityById('spent_ball_1');
      print(
        '  첫 공 상태=${firstSpent?.visualState} 고정=${firstSpent?.movable == false} '
        '위치=${firstSpent?.position.x.toStringAsFixed(2)},'
        '${firstSpent?.position.y.toStringAsFixed(2)}',
      );
      print(
        '  과거 공 충돌=${chain.previousBallImpact} 이동=${chain.previousBallMove} '
        '홀 충돌=${chain.holeImpactPath}',
      );
      final spent = chain.second.state.entityById('spent_ball_1');
      print(
        '  첫 공 최종 위치=${spent?.position.x.toStringAsFixed(2)},'
        '${spent?.position.y.toStringAsFixed(2)} 상태=${spent?.visualState} '
        '고정=${spent?.movable == false}',
      );
    }
    if (bypass == null) {
      print('  대체 해법: 찾지 못함');
    } else {
      print(
        '  대체 해법: ${bypass.degree}도/${_percent(bypass.power)}% '
        '단일 발사, 사건=${bypass.result.events.join(' → ')}',
      );
    }
  }
}

_ChainCandidate? _findChain(
  StageDefinition stage,
  StagePattern pattern,
  TraitType? firstTrait,
) {
  final base = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(6, productRules: true);
  final probe = Platform.environment['STAGE7_PROBE_SECOND'] == 'true';
  final verboseProbe = Platform.environment['STAGE7_VERBOSE_PROBE'] == 'true';
  final firstDegreeOverride = int.tryParse(
    Platform.environment['STAGE7_FIRST_DEGREE'] ?? '',
  );
  final firstStepOverride = int.tryParse(
    Platform.environment['STAGE7_FIRST_STEP'] ?? '',
  );
  for (
    var firstDegree = firstDegreeOverride ?? (probe ? 200 : 0);
    firstDegree < 360;
    firstDegree += firstDegreeOverride != null ? 360 : (probe ? 360 : 10)
  ) {
    final maximumFirstStep = pattern.patternId == 'stage_persistent_04'
        ? 50
        : 10;
    final minimumStep = firstStepOverride ?? 6;
    for (
      var firstStep = firstStepOverride ?? minimumStep;
      firstStep <= (firstStepOverride ?? (probe ? 6 : maximumFirstStep));
      firstStep++
    ) {
      final firstInput = _input(firstDegree, firstStep / 50, firstTrait);
      final first = resolver.resolve(base, firstInput);
      if (first.state.phase == GamePhase.success) continue;
      final previous = first.state.entityById('spent_ball_1');
      if (previous == null) continue;
      if (Platform.environment['STAGE7_DIAGNOSTIC'] == 'true' &&
          ((pattern.patternId == 'stage_persistent_02' &&
                  first.events.contains('switch_pressed')) ||
              (pattern.patternId == 'stage_persistent_03' &&
                  first.events.contains('sticky_attached')) ||
              (pattern.patternId == 'stage_persistent_04' &&
                  first.events.contains('crate_pushed')))) {
        print(
          '진단 첫 $firstDegree도/${firstStep * 2}% 사건=${first.events} '
          '위치=${previous.position.x.toStringAsFixed(1)},'
          '${previous.position.y.toStringAsFixed(1)} 상태=${previous.visualState}',
        );
      }
      if (pattern.patternId == 'stage_persistent_03' &&
          !first.impacts.any((impact) => impact.entityId == 'sticky_pad')) {
        continue;
      }
      if (pattern.patternId == 'stage_persistent_02' &&
          !first.events.contains('switch_pressed')) {
        continue;
      }
      if (pattern.patternId == 'stage_persistent_04' &&
          (!first.events.contains('crate_pushed') ||
              !first.impacts.any(
                (impact) => impact.entityId == 'stopper_crate',
              ))) {
        continue;
      }
      if (Platform.environment['STAGE7_ONLY_FIRST'] == 'true') {
        print(
          '첫 결과 ${first.events} impacts=${first.impacts.map((item) => item.entityId).join(',')} '
          '위치=${previous.position.x},${previous.position.y} 상태=${previous.visualState}',
        );
        return null;
      }
      final hole = first.state.entityById('hole');
      if (hole != null &&
          previous.position.distanceTo(hole.position) <=
              hole.radius + previous.hitRadius) {
        continue;
      }
      for (
        var secondDegree = 0;
        secondDegree < 360;
        secondDegree += probe ? 2 : 10
      ) {
        for (var secondStep = 6; secondStep <= 50; secondStep++) {
          final secondInput = _input(secondDegree, secondStep / 50, null);
          final second = resolver.resolve(first.state, secondInput);
          if (probe &&
              verboseProbe &&
              (second.state.phase == GamePhase.success ||
                  second.impacts.any(
                    (item) => item.entityId == 'spent_ball_1',
                  ))) {
            final probeSpent = second.state.entityById('spent_ball_1');
            final probeCrate = second.state.entityById('stopper_crate');
            final probeActive = second.state.entityById('active_ball');
            print(
              '탐침 둘째 $secondDegree도/${secondStep * 2}% '
              '사건=${second.events} impacts=${second.impacts.map((item) => '${item.sourceEntityId}>${item.entityId}').join(',')} '
              '끝=${probeActive?.position.x.toStringAsFixed(1)},${probeActive?.position.y.toStringAsFixed(1)}',
            );
            print(
              '탐침 위치 과거공=${probeSpent?.position.x.toStringAsFixed(1)},${probeSpent?.position.y.toStringAsFixed(1)} '
              '상자=${probeCrate?.position.x.toStringAsFixed(1)},${probeCrate?.position.y.toStringAsFixed(1)}',
            );
          }
          if (second.state.phase != GamePhase.success) continue;
          final preparationRequired =
              pattern.patternId == 'stage_persistent_02' &&
              resolver.resolve(base, secondInput).state.phase !=
                  GamePhase.success;
          final previousBallImpact = second.impacts.any(
            (impact) =>
                impact.entityId == 'spent_ball_1' ||
                impact.sourceEntityId == 'spent_ball_1',
          );
          final previousBallMove = second.moves.any(
            (move) => move.entityId == 'spent_ball_1' && move.from != move.to,
          );
          final holeImpactPath = second.impacts.any(
            (impact) =>
                impact.entityId == 'hole' &&
                impact.sourceEntityId == 'spent_ball_1',
          );
          final previousBallEvent = second.events.any(
            (event) =>
                event.contains('spent_ball') ||
                event == 'chain_collision_ball' ||
                event == 'existing_ball_hole_entered',
          );
          if (pattern.patternId == 'stage_persistent_02') {
            if (!preparationRequired ||
                !first.events.contains('switch_pressed') ||
                first.state.entityById('switch_hold')?.pressed != true ||
                first.state.entityById('hold_gate')?.open != true) {
              continue;
            }
            return _ChainCandidate(
              firstDegree: firstDegree,
              firstPower: firstStep / 50,
              secondDegree: secondDegree,
              secondPower: secondStep / 50,
              first: first,
              second: second,
              previousBallImpact: previousBallImpact,
              previousBallMove: previousBallMove,
              holeImpactPath: holeImpactPath,
            );
          }
          final requiresPreviousMove =
              pattern.patternId != 'stage_persistent_03';
          if (!previousBallImpact ||
              requiresPreviousMove && !previousBallMove ||
              !previousBallEvent) {
            continue;
          }
          if (Platform.environment['STAGE7_ROBUST'] == 'true' &&
              pattern.patternId == 'stage_persistent_04') {
            final robustCount = _robustPersistent04Count(
              base,
              firstDegree,
              firstStep / 50,
              secondDegree,
              secondStep / 50,
            );
            if (robustCount < 3) continue;
            print('  주변 준비 입력 성공=$robustCount/15');
          }
          return _ChainCandidate(
            firstDegree: firstDegree,
            firstPower: firstStep / 50,
            secondDegree: secondDegree,
            secondPower: secondStep / 50,
            first: first,
            second: second,
            previousBallImpact: previousBallImpact,
            previousBallMove: previousBallMove,
            holeImpactPath: holeImpactPath,
          );
        }
      }
    }
  }
  return null;
}

int _robustPersistent04Count(
  GameState base,
  int firstDegree,
  double firstPower,
  int secondDegree,
  double secondPower,
) {
  var count = 0;
  for (final degreeDelta in [-2, 0, 2]) {
    for (final powerDelta in [-.04, -.02, 0.0, .02, .04]) {
      final first = resolver.resolve(
        base,
        _input(
          firstDegree + degreeDelta,
          (firstPower + powerDelta).clamp(0.12, 1),
          null,
        ),
      );
      if (first.state.phase == GamePhase.success ||
          !first.impacts.any((impact) => impact.entityId == 'stopper_crate')) {
        continue;
      }
      final second = resolver.resolve(
        first.state,
        _input(secondDegree, secondPower, null),
      );
      if (second.state.phase != GamePhase.success) continue;
      final touchedPastBall = second.impacts.any(
        (impact) =>
            impact.entityId == 'spent_ball_1' ||
            impact.sourceEntityId == 'spent_ball_1',
      );
      final movedPastBall = second.moves.any(
        (move) => move.entityId == 'spent_ball_1' && move.from != move.to,
      );
      final pastBallEnteredHole = second.impacts.any(
        (impact) =>
            impact.entityId == 'hole' &&
            impact.sourceEntityId == 'spent_ball_1',
      );
      if (touchedPastBall && movedPastBall && pastBallEnteredHole) count++;
    }
  }
  return count;
}

_BypassCandidate? _findBypass(StageDefinition stage, StagePattern pattern) {
  final base = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(6, productRules: true);
  for (var degree = 0; degree < 360; degree += 2) {
    for (var step = 6; step <= 50; step++) {
      final result = resolver.resolve(base, _input(degree, step / 50, null));
      if (result.state.phase == GamePhase.success) {
        return _BypassCandidate(degree, step / 50, result);
      }
    }
  }
  return null;
}

ShotInput _input(int degree, double power, TraitType? trait) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
    equippedTrait: trait,
  );
}

String _percent(double power) => (power * 100).round().toString();

class _ChainCandidate {
  const _ChainCandidate({
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
    required this.first,
    required this.second,
    required this.previousBallImpact,
    required this.previousBallMove,
    required this.holeImpactPath,
  });

  final int firstDegree;
  final double firstPower;
  final int secondDegree;
  final double secondPower;
  final ShotResult first;
  final ShotResult second;
  final bool previousBallImpact;
  final bool previousBallMove;
  final bool holeImpactPath;
}

class _BypassCandidate {
  const _BypassCandidate(this.degree, this.power, this.result);

  final int degree;
  final double power;
  final ShotResult result;
}
