import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';

class StageSpeedSolution {
  const StageSpeedSolution({
    required this.patternId,
    required this.degree,
    required this.power,
    required this.familyId,
    this.expectedSliderId,
    this.expectedImpactId,
    this.expectedMoveId,
    this.weak = false,
    this.bypass = false,
  });

  final String patternId;
  final int degree;
  final double power;
  final String familyId;
  final String? expectedSliderId;
  final String? expectedImpactId;
  final String? expectedMoveId;
  final bool weak;
  final bool bypass;

  Vec2 get direction {
    final radians = degree * math.pi / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }
}

const stageSpeedRepresentativeSolutions = <StageSpeedSolution>[
  StageSpeedSolution(
    patternId: 'stage_speed_01',
    degree: 58,
    power: 0.32,
    familyId: 'last_segment_reacceleration',
    expectedSliderId: 'last_slider',
    weak: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_02',
    degree: 66,
    power: 0.62,
    familyId: 'wall_reflection_slider',
    expectedSliderId: 'after_bank_slider',
    expectedImpactId: 'bank_wall',
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_03',
    degree: 210,
    power: 0.56,
    familyId: 'crate_push_reacceleration',
    expectedSliderId: 'crate_slider',
    expectedMoveId: 'push_crate',
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_04',
    degree: 40,
    power: 0.80,
    familyId: 'multiple_slider_choice_right',
    expectedSliderId: 'right_slider',
  ),
];

const stageSpeedWeakAlternatives = <StageSpeedSolution>[
  StageSpeedSolution(
    patternId: 'stage_speed_01',
    degree: 58,
    power: 0.32,
    familyId: 'last_segment_reacceleration',
    expectedSliderId: 'last_slider',
    weak: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_02',
    degree: 216,
    power: 0.40,
    familyId: 'wall_reflection_slider',
    expectedSliderId: 'after_bank_slider',
    expectedImpactId: 'bank_wall',
    weak: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_03',
    degree: 222,
    power: 0.28,
    familyId: 'crate_slider_weak_entry',
    expectedSliderId: 'crate_slider',
    weak: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_04',
    degree: 222,
    power: 0.40,
    familyId: 'multiple_slider_choice_left',
    expectedSliderId: 'left_slider',
    weak: true,
  ),
];

const stageSpeedBypassSolutions = <StageSpeedSolution>[
  StageSpeedSolution(
    patternId: 'stage_speed_01',
    degree: 52,
    power: 0.44,
    familyId: 'outer_wall_bypass',
    bypass: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_02',
    degree: 96,
    power: 0.52,
    familyId: 'outer_wall_bypass',
    bypass: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_03',
    degree: 50,
    power: 0.68,
    familyId: 'outer_wall_bypass',
    bypass: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_04',
    degree: 68,
    power: 0.72,
    familyId: 'center_bypass',
    bypass: true,
  ),
];
