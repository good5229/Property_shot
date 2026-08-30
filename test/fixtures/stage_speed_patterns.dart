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
    degree: 132,
    power: 0.34,
    familyId: 'last_segment_reacceleration',
    expectedSliderId: 'last_slider',
    weak: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_02',
    degree: 72,
    power: 0.60,
    familyId: 'wall_reflection_slider',
    expectedSliderId: 'after_bank_slider',
    expectedImpactId: 'bank_wall',
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_03',
    degree: 122,
    power: 0.68,
    familyId: 'crate_push_reacceleration',
    expectedSliderId: 'crate_slider',
    expectedMoveId: 'push_crate',
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_04',
    degree: 34,
    power: 0.86,
    familyId: 'multiple_slider_choice_right',
    expectedSliderId: 'right_slider',
  ),
];

const stageSpeedWeakAlternatives = <StageSpeedSolution>[
  StageSpeedSolution(
    patternId: 'stage_speed_01',
    degree: 132,
    power: 0.34,
    familyId: 'last_segment_reacceleration',
    expectedSliderId: 'last_slider',
    weak: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_02',
    degree: 264,
    power: 0.38,
    familyId: 'wall_reflection_slider',
    expectedSliderId: 'after_bank_slider',
    expectedImpactId: 'bank_wall',
    weak: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_03',
    degree: 220,
    power: 0.36,
    familyId: 'crate_slider_weak_entry',
    expectedSliderId: 'crate_slider',
    weak: true,
  ),
];

const stageSpeedChoiceAlternatives = <StageSpeedSolution>[
  StageSpeedSolution(
    patternId: 'stage_speed_04',
    degree: 116,
    power: 0.58,
    familyId: 'multiple_slider_choice_left',
    expectedSliderId: 'left_slider',
  ),
];

const stageSpeedBypassSolutions = <StageSpeedSolution>[
  StageSpeedSolution(
    patternId: 'stage_speed_01',
    degree: 50,
    power: 0.30,
    familyId: 'outer_wall_bypass',
    bypass: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_02',
    degree: 102,
    power: 0.54,
    familyId: 'outer_wall_bypass',
    bypass: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_03',
    degree: 68,
    power: 0.70,
    familyId: 'outer_wall_bypass',
    bypass: true,
  ),
  StageSpeedSolution(
    patternId: 'stage_speed_04',
    degree: 66,
    power: 0.62,
    familyId: 'center_bypass',
    bypass: true,
  ),
];
