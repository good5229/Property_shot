import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';

class StageChainScoreSolution {
  const StageChainScoreSolution({
    required this.patternId,
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
    required this.directDegree,
    required this.directPower,
    required this.familyId,
    required this.expectedTargetOrder,
    required this.minimumChainScore,
  });

  final String patternId;
  final int firstDegree;
  final double firstPower;
  final int secondDegree;
  final double secondPower;
  final int directDegree;
  final double directPower;
  final String familyId;
  final List<String> expectedTargetOrder;
  final int minimumChainScore;

  ShotInput get firstInput => _input(firstDegree, firstPower);
  ShotInput get secondInput => _input(secondDegree, secondPower);
  ShotInput get directInput => _input(directDegree, directPower);
}

const stageChainScoreSolutions = <StageChainScoreSolution>[
  StageChainScoreSolution(
    patternId: 'stage_chain_score_01',
    firstDegree: 160,
    firstPower: 0.20,
    secondDegree: 158,
    secondPower: 0.96,
    directDegree: 292,
    directPower: 0.52,
    familyId: 'three_cushion_chain',
    expectedTargetOrder: [
      'wall_left',
      'field_boundary_bottom',
      'spent_ball_1',
      'wall_left',
      'field_boundary_bottom',
      'cushion_slider',
    ],
    minimumChainScore: 1900,
  ),
  StageChainScoreSolution(
    patternId: 'stage_chain_score_02',
    firstDegree: 340,
    firstPower: 0.84,
    secondDegree: 234,
    secondPower: 0.56,
    directDegree: 326,
    directPower: 0.74,
    familyId: 'multi_wall_past_ball',
    expectedTargetOrder: ['chain_score_02_direct_guard', 'spent_ball_1'],
    minimumChainScore: 1650,
  ),
  StageChainScoreSolution(
    patternId: 'stage_chain_score_03',
    firstDegree: 280,
    firstPower: 0.44,
    secondDegree: 312,
    secondPower: 0.84,
    directDegree: 52,
    directPower: 0.96,
    familyId: 'slider_stone_wall_past_ball',
    expectedTargetOrder: [
      'speed_slider',
      'chain_stone',
      'bounce_wall',
      'spent_ball_1',
    ],
    minimumChainScore: 1900,
  ),
  StageChainScoreSolution(
    patternId: 'stage_chain_score_04',
    firstDegree: 70,
    firstPower: 0.52,
    secondDegree: 56,
    secondPower: 0.76,
    directDegree: 74,
    directPower: 0.60,
    familyId: 'wall_object_chain',
    expectedTargetOrder: [
      'field_boundary_bottom',
      'wall_right',
      'score_crate',
      'score_slider',
      'wall_right',
      'spent_ball_1',
    ],
    minimumChainScore: 1900,
  ),
];

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}
