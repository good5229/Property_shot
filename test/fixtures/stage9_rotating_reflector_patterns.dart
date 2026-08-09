import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';

class Stage9RotatingReflectorSolution {
  const Stage9RotatingReflectorSolution({
    required this.patternId,
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
    required this.directDegree,
    required this.directPower,
    required this.expectedRotationOrder,
    this.expectedSecondRotationSource,
    this.expectedFirstSlider = false,
  });

  final String patternId;
  final int firstDegree;
  final double firstPower;
  final int secondDegree;
  final double secondPower;
  final int directDegree;
  final double directPower;
  final List<String> expectedRotationOrder;
  final String? expectedSecondRotationSource;
  final bool expectedFirstSlider;

  ShotInput get firstInput => _input(firstDegree, firstPower);
  ShotInput get secondInput => _input(secondDegree, secondPower);
  ShotInput get directInput => _input(directDegree, directPower);
}

const stage9RotatingReflectorSolutions = <Stage9RotatingReflectorSolution>[
  Stage9RotatingReflectorSolution(
    patternId: 'stage_rotating_reflector_01',
    firstDegree: 296,
    firstPower: 0.12,
    secondDegree: 222,
    secondPower: 0.48,
    directDegree: 44,
    directPower: 0.90,
    expectedRotationOrder: ['reflector_a', 'reflector_a'],
  ),
  Stage9RotatingReflectorSolution(
    patternId: 'stage_rotating_reflector_02',
    firstDegree: 228,
    firstPower: 0.12,
    secondDegree: 54,
    secondPower: 0.72,
    directDegree: 62,
    directPower: 0.64,
    expectedRotationOrder: ['reflector_a', 'reflector_b'],
  ),
  Stage9RotatingReflectorSolution(
    patternId: 'stage_rotating_reflector_03',
    firstDegree: 236,
    firstPower: 0.90,
    secondDegree: 324,
    secondPower: 0.70,
    directDegree: 64,
    directPower: 0.60,
    expectedRotationOrder: ['reflector_a', 'reflector_a', 'reflector_a'],
    expectedSecondRotationSource: 'spent_ball_1',
  ),
  Stage9RotatingReflectorSolution(
    patternId: 'stage_rotating_reflector_04',
    firstDegree: 312,
    firstPower: 0.12,
    secondDegree: 72,
    secondPower: 0.54,
    directDegree: 224,
    directPower: 0.36,
    expectedRotationOrder: ['reflector_a'],
    expectedFirstSlider: true,
  ),
];

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}
