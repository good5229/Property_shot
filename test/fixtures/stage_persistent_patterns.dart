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
    firstDegree: 60,
    firstPower: 0.12,
    secondDegree: 10,
    secondPower: 0.12,
    familyId: 'past_ball_cushion',
    expectedFirstImpactId: null,
    expectedSecondHoleSourceId: 'spent_ball_1',
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_02',
    firstDegree: 70,
    firstPower: 0.12,
    secondDegree: 80,
    secondPower: 0.88,
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
    firstDegree: 270,
    firstPower: 0.12,
    secondDegree: 94,
    secondPower: 0.98,
    familyId: 'sticky_ball_bumper',
    firstTrait: TraitType.sticky,
    expectedFirstImpactId: 'sticky_pad',
    expectedSecondHoleSourceId: 'active_ball',
    requireFirstMove: false,
    requireFirstFixed: true,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_04',
    firstDegree: 20,
    firstPower: 0.90,
    secondDegree: 90,
    secondPower: 0.98,
    familyId: 'crate_stopper_chain',
    expectedFirstImpactId: 'stopper_crate',
    expectedSecondHoleSourceId: 'spent_ball_1',
  ),
];

const stagePersistentAlternativeSolutions = <StagePersistentSolution>[
  StagePersistentSolution(
    patternId: 'stage_persistent_01',
    firstDegree: 0,
    firstPower: 0.12,
    secondDegree: 0,
    secondPower: 0.12,
    familyId: 'direct_bypass',
    requireFirstMove: false,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_02',
    firstDegree: 240,
    firstPower: 0.90,
    secondDegree: 240,
    secondPower: 0.12,
    familyId: 'direct_bypass',
    requireFirstMove: false,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_03',
    firstDegree: 54,
    firstPower: 0.78,
    secondDegree: 54,
    secondPower: 0.12,
    familyId: 'direct_bypass',
    requireFirstMove: false,
  ),
  StagePersistentSolution(
    patternId: 'stage_persistent_04',
    firstDegree: 44,
    firstPower: 0.64,
    secondDegree: 44,
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
