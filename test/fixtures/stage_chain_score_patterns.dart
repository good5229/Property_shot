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
    firstDegree: 10,
    firstPower: 0.44,
    secondDegree: 228,
    secondPower: 0.92,
    directDegree: 292,
    directPower: 0.52,
    familyId: 'three_cushion_chain',
    expectedTargetOrder: [
      'wall_left',
      'three_balloon',
      'wall_left',
      'cushion_slider',
      'spent_ball_1',
      'field_boundary_bottom',
      'wall_right',
    ],
    minimumChainScore: 1700,
  ),
  StageChainScoreSolution(
    patternId: 'stage_chain_score_02',
    firstDegree: 260,
    firstPower: 0.52,
    secondDegree: 116,
    secondPower: 0.36,
    directDegree: 316,
    directPower: 0.94,
    familyId: 'multi_wall_past_ball',
    expectedTargetOrder: [
      'wall_left',
      'chain_score_02_direct_guard',
      'wall_left',
      'spent_ball_1',
    ],
    minimumChainScore: 1450,
  ),
  StageChainScoreSolution(
    patternId: 'stage_chain_score_03',
    firstDegree: 240,
    firstPower: 0.36,
    secondDegree: 208,
    secondPower: 0.92,
    directDegree: 326,
    directPower: 0.70,
    familyId: 'slider_stone_wall_past_ball',
    expectedTargetOrder: [
      'speed_slider',
      'chain_stone',
      'bounce_wall',
      'spent_ball_1',
    ],
    minimumChainScore: 1800,
  ),
  StageChainScoreSolution(
    patternId: 'stage_chain_score_04',
    firstDegree: 230,
    firstPower: 0.12,
    secondDegree: 120,
    secondPower: 0.92,
    directDegree: 224,
    directPower: 0.50,
    familyId: 'wall_object_chain',
    expectedTargetOrder: [
      'field_boundary_bottom',
      'wall_left',
      'spent_ball_1',
      'score_crate',
      'score_slider',
      'score_jelly',
      'wall_top',
    ],
    minimumChainScore: 1750,
  ),
];

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}
