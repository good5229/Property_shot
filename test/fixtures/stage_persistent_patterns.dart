import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';

class StagePersistentSolution {
  const StagePersistentSolution({
    required this.patternId,
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
    required this.familyId,
    this.firstTrait,
    this.expectedFirstImpactId,
    this.expectedSecondImpactId = 'spent_ball_1',
    this.expectedSecondHoleSourceId,
    this.requireFirstMove = true,
    this.requireFirstFixed = false,
  });

  final String patternId;
  final int firstDegree;
  final double firstPower;
  final int secondDegree;
  final double secondPower;
  final String familyId;
  final TraitType? firstTrait;
  final String? expectedFirstImpactId;
  final String? expectedSecondImpactId;
  final String? expectedSecondHoleSourceId;
  final bool requireFirstMove;
  final bool requireFirstFixed;

  ShotInput get firstInput => _input(firstDegree, firstPower, firstTrait);
  ShotInput get secondInput => _input(secondDegree, secondPower, null);
}

const stagePersistentRepresentativeSolutions = <StagePersistentSolution>[
  StagePersistentSolution(
    patternId: 'stage_persistent_01',
    firstDegree: 20,
    firstPower: 0.12,
    secondDegree: 170,
    secondPower: 0.66,
    familyId: 'past_ball_cushion',
    expectedFirstImpactId: 'field_boundary_bottom',
    expectedSecondHoleSourceId: 'spent_ball_1',
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_02',
    firstDegree: 320,
    firstPower: 0.12,
    secondDegree: 74,
    secondPower: 1,
    familyId: 'spent_switch_hold',
    firstTrait: TraitType.heavy,
    expectedFirstImpactId: 'switch_hold',
    expectedSecondImpactId: null,
    expectedSecondHoleSourceId: 'active_ball',
    requireFirstMove: false,
    requireFirstFixed: true,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_03',
    firstDegree: 300,
    firstPower: 0.12,
    secondDegree: 220,
    secondPower: 0.76,
    familyId: 'sticky_ball_bumper',
    firstTrait: TraitType.sticky,
    expectedFirstImpactId: 'sticky_pad',
    expectedSecondHoleSourceId: 'active_ball',
    requireFirstMove: false,
    requireFirstFixed: true,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_04',
    firstDegree: 130,
    firstPower: 0.60,
    secondDegree: 252,
    secondPower: 0.16,
    familyId: 'crate_stopper_chain',
    expectedFirstImpactId: 'stopper_crate',
    expectedSecondHoleSourceId: 'spent_ball_1',
  ),
];

const stagePersistentAlternativeSolutions = <StagePersistentSolution>[
  StagePersistentSolution(
    patternId: 'stage_persistent_01',
    firstDegree: 24,
    firstPower: 0.60,
    secondDegree: 24,
    secondPower: 0.12,
    familyId: 'direct_bypass',
    requireFirstMove: false,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_02',
    firstDegree: 78,
    firstPower: 0.98,
    secondDegree: 78,
    secondPower: 0.12,
    familyId: 'direct_bypass',
    requireFirstMove: false,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_03',
    firstDegree: 50,
    firstPower: 0.82,
    secondDegree: 2,
    secondPower: 0.12,
    familyId: 'direct_bypass',
    requireFirstMove: false,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_04',
    firstDegree: 50,
    firstPower: 0.38,
    secondDegree: 50,
    secondPower: 0.12,
    familyId: 'direct_bypass',
    requireFirstMove: false,
  ),
];

ShotInput _input(int degree, double power, TraitType? trait) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
    equippedTrait: trait,
  );
}
