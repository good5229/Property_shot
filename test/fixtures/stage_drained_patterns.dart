import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';

class StageDrainedSolution {
  const StageDrainedSolution({
    required this.patternId,
    required this.strategyId,
    required this.degree,
    required this.power,
    required this.familyId,
    this.sourceMustMove = false,
  });

  final String patternId;
  final String strategyId;
  final int degree;
  final double power;
  final String familyId;
  final bool sourceMustMove;

  Vec2 get direction {
    final radians = degree * math.pi / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }
}

const stageDrainedRepresentativeSolutions = <StageDrainedSolution>[
  StageDrainedSolution(
    patternId: 'stage_drained_01',
    strategyId: 'drain_weight',
    degree: 222,
    power: 0.98,
    familyId: 'drained_weight_push',
    sourceMustMove: true,
  ),
  StageDrainedSolution(
    patternId: 'stage_drained_02',
    strategyId: 'drain_jelly',
    degree: 120,
    power: 0.76,
    familyId: 'drained_jelly_lane',
    sourceMustMove: true,
  ),
  StageDrainedSolution(
    patternId: 'stage_drained_03',
    strategyId: 'drain_glue',
    degree: 270,
    power: 0.60,
    familyId: 'drained_sticky_lane',
    sourceMustMove: true,
  ),
  StageDrainedSolution(
    patternId: 'stage_drained_04',
    strategyId: 'drain_weight_choice',
    degree: 272,
    power: 0.68,
    familyId: 'heavy_left_choice',
    sourceMustMove: true,
  ),
];

const stageDrainedAlternativeSolutions = <StageDrainedSolution>[
  StageDrainedSolution(
    patternId: 'stage_drained_01',
    strategyId: 'none',
    degree: 248,
    power: 0.78,
    familyId: 'outer_wall_bypass',
  ),
  StageDrainedSolution(
    patternId: 'stage_drained_02',
    strategyId: 'none',
    degree: 52,
    power: 0.78,
    familyId: 'elastic_bank',
  ),
  StageDrainedSolution(
    patternId: 'stage_drained_03',
    strategyId: 'none',
    degree: 102,
    power: 1,
    familyId: 'long_side_bypass',
  ),
  StageDrainedSolution(
    patternId: 'stage_drained_04',
    strategyId: 'drain_jelly_choice',
    degree: 314,
    power: 0.90,
    familyId: 'bouncy_right_choice',
    sourceMustMove: true,
  ),
  StageDrainedSolution(
    patternId: 'stage_drained_04',
    strategyId: 'none',
    degree: 300,
    power: 0.72,
    familyId: 'center_bypass',
  ),
];
