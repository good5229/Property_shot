// ignore_for_file: avoid_print

import 'dart:math' as math;
import 'dart:io';

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

const resolver = ShotResolver();
const degreeStep = 2;
const powerStep = 2;
const secondDegreeStep = 6;
const secondPowerStep = 6;

void main() {
  final stage = generatedStageCatalog.stageById('stage_rotating_reflector');
  final requested = Platform.environment['STAGE9_PATTERN'];
  for (final pattern in stage.patterns.where(
    (pattern) => requested == null || pattern.patternId == requested,
  )) {
    print('\n${pattern.patternId}');
    final direct = _findDirect(stage, pattern);
    print('  직접: ${_format(direct)}');
    final prepared = _findPrepared(stage, pattern);
    print('  대표: ${_formatPrepared(prepared)}');
  }
}

_DirectCandidate? _findDirect(StageDefinition stage, StagePattern pattern) {
  final base = _state(stage, pattern);
  _DirectCandidate? best;
  for (var degree = 0; degree < 360; degree += degreeStep) {
    for (var power = 12; power <= 100; power += powerStep) {
      final result = resolver.resolve(base, _input(degree, power));
      if (result.state.phase != GamePhase.success) continue;
      if (result.reflectorRotations.isNotEmpty) continue;
      final candidate = _DirectCandidate(degree, power, result);
      if (best == null || power < best.power) best = candidate;
    }
  }
  return best;
}

_PreparedCandidate? _findPrepared(StageDefinition stage, StagePattern pattern) {
  final base = _state(stage, pattern);
  final firstCandidates = <_FirstCandidate>[];
  for (var degree = 0; degree < 360; degree += degreeStep) {
    for (var power = 12; power <= 100; power += powerStep) {
      final first = resolver.resolve(base, _input(degree, power));
      if (first.state.phase == GamePhase.success) continue;
      final rotations = first.reflectorRotations;
      final slider = first.powerSliderActivations;
      final spent = first.state.entityById('spent_ball_1');
      final hasReflector = pattern.objects.any(
        (object) => object.type.name == 'rotatingReflector',
      );
      final requiresPastBall = pattern.patternId.endsWith('_03');
      final qualifies = switch (pattern.patternId.split('_').last) {
        '01' => rotations.isNotEmpty,
        '02' => rotations.isNotEmpty,
        '03' => spent != null,
        '04' => slider.isNotEmpty,
        _ => false,
      };
      if (!hasReflector || (requiresPastBall && spent == null) || !qualifies) {
        continue;
      }
      firstCandidates.add(_FirstCandidate(degree, power, first));
    }
  }
  if (pattern.patternId.endsWith('_03')) {
    final reflector = pattern.objects.firstWhere(
      (object) => object.type.name == 'rotatingReflector',
    );
    firstCandidates.sort((a, b) {
      final aBall = a.result.state.entityById('spent_ball_1')!;
      final bBall = b.result.state.entityById('spent_ball_1')!;
      return aBall.position
          .distanceTo(reflector.position)
          .compareTo(bBall.position.distanceTo(reflector.position));
    });
  } else {
    firstCandidates.sort((a, b) => a.power.compareTo(b.power));
  }
  print('  준비 후보=${firstCandidates.length}');
  if (pattern.patternId.endsWith('_03')) {
    for (final candidate in firstCandidates.take(12)) {
      final spent = candidate.result.state.entityById('spent_ball_1');
      print(
        '    준비 ${candidate.degree}도/${candidate.power}% '
        '공=${spent?.position.x.toStringAsFixed(0)},${spent?.position.y.toStringAsFixed(0)} '
        '${candidate.result.events.join(' → ')}, '
        '회전=${candidate.result.reflectorRotations.length}',
      );
    }
  }
  final candidates = pattern.patternId.endsWith('_03')
      ? firstCandidates.take(80)
      : firstCandidates.take(12);
  for (final firstCandidate in candidates) {
    for (var degree = 0; degree < 360; degree += secondDegreeStep) {
      for (var power = 12; power <= 100; power += secondPowerStep) {
        final second = resolver.resolve(
          firstCandidate.result.state,
          _input(degree, power),
        );
        if (second.state.phase != GamePhase.success) continue;
        final source = pattern.patternId.endsWith('_03')
            ? second.reflectorRotations.any(
                (rotation) => rotation.sourceEntityId == 'spent_ball_1',
              )
            : true;
        final usesReflector = pattern.patternId.endsWith('_03')
            ? second.reflectorRotations.any(
                (rotation) => rotation.sourceEntityId == 'spent_ball_1',
              )
            : pattern.patternId.endsWith('_01') ||
                  pattern.patternId.endsWith('_02')
            ? second.reflectorRotations.isNotEmpty &&
                  (pattern.patternId.endsWith('_01') ||
                      {
                            for (final rotation in [
                              ...firstCandidate.result.reflectorRotations,
                              ...second.reflectorRotations,
                            ])
                              rotation.reflectorEntityId,
                          }.length >=
                          2)
            : firstCandidate.result.reflectorRotations.isNotEmpty &&
                  second.state.phase == GamePhase.success;
        final sliderFirst = pattern.patternId.endsWith('_04')
            ? firstCandidate.result.powerSliderActivations.isNotEmpty
            : true;
        if (!source || !usesReflector || !sliderFirst) continue;
        return _PreparedCandidate(
          firstDegree: firstCandidate.degree,
          firstPower: firstCandidate.power,
          secondDegree: degree,
          secondPower: power,
          first: firstCandidate.result,
          second: second,
        );
      }
    }
  }
  return null;
}

GameState _state(StageDefinition stage, StagePattern pattern) => pattern
    .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
    .createState(8, productRules: true);

ShotInput _input(int degree, int powerPercent) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: powerPercent / 100,
  );
}

String _format(_DirectCandidate? candidate) {
  if (candidate == null) return '없음';
  return '${candidate.degree}도/${candidate.power}%, ${candidate.result.events.join(' → ')}';
}

String _formatPrepared(_PreparedCandidate? candidate) {
  if (candidate == null) return '없음';
  return '${candidate.firstDegree}도/${candidate.firstPower}% → '
      '${candidate.secondDegree}도/${candidate.secondPower}%, '
      '1샷=${candidate.first.events.join(' → ')}, '
      '2샷=${candidate.second.events.join(' → ')}, '
      '회전=${candidate.first.reflectorRotations.length + candidate.second.reflectorRotations.length}, '
      '판=${[...candidate.first.reflectorRotations, ...candidate.second.reflectorRotations].map((rotation) => '${rotation.sourceEntityId}:${rotation.reflectorEntityId}').join(',')}';
}

class _DirectCandidate {
  const _DirectCandidate(this.degree, this.power, this.result);
  final int degree;
  final int power;
  final ShotResult result;
}

class _FirstCandidate {
  const _FirstCandidate(this.degree, this.power, this.result);
  final int degree;
  final int power;
  final ShotResult result;
}

class _PreparedCandidate {
  const _PreparedCandidate({
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
    required this.first,
    required this.second,
  });
  final int firstDegree;
  final int firstPower;
  final int secondDegree;
  final int secondPower;
  final ShotResult first;
  final ShotResult second;
}
