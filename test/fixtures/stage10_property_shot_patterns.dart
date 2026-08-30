import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';

class Stage10PropertyShotSolution {
  const Stage10PropertyShotSolution({
    required this.patternId,
    required this.contract,
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
    required this.directDegree,
    required this.directPower,
    required this.familyId,
    this.directFamilyId,
    this.openedGateBankDegree,
    this.openedGateBankPower,
    this.conditionalGateId,
    this.transferTrait,
    this.expectedImpactIds = const [],
    this.expectedEvents = const [],
    this.directSuccessUpperBound,
    this.directConnectedUpperBound,
    this.chainSuccessLowerBound,
    this.chainConnectedLowerBound,
  });

  final String patternId;
  final String contract;
  final int firstDegree;
  final double firstPower;
  final int secondDegree;
  final double secondPower;
  final int directDegree;
  final double directPower;
  final String familyId;
  final String? directFamilyId;
  final int? openedGateBankDegree;
  final double? openedGateBankPower;
  final String? conditionalGateId;
  final TraitType? transferTrait;
  final List<String> expectedImpactIds;
  final List<String> expectedEvents;
  final int? directSuccessUpperBound;
  final int? directConnectedUpperBound;
  final int? chainSuccessLowerBound;
  final int? chainConnectedLowerBound;

  // 실제 UI는 이전된 속성을 첫 발사 입력에 싣고, 실패 공이 남은 뒤에는
  // 장착을 해제한다. 대표 두 발도 같은 한 번 이전 계약을 재생한다.
  ShotInput get firstInput => _input(firstDegree, firstPower, transferTrait);
  ShotInput get secondInput => _input(secondDegree, secondPower);
  ShotInput get directInput => _input(directDegree, directPower);
  ShotInput? get openedGateBankInput =>
      switch ((openedGateBankDegree, openedGateBankPower)) {
        (final degree?, final power?) => _input(degree, power),
        _ => null,
      };
}

const stage10PropertyShotSolutions = <Stage10PropertyShotSolution>[
  Stage10PropertyShotSolution(
    patternId: 'stage_property_shot_a',
    contract: 'A',
    firstDegree: 10,
    firstPower: 0.56,
    secondDegree: 42,
    secondPower: 0.94,
    directDegree: 40,
    directPower: 0.96,
    familyId: 'heavy_transfer_switch',
    conditionalGateId: 'a_gate',
    openedGateBankDegree: 9,
    openedGateBankPower: 0.94,
    transferTrait: TraitType.heavy,
    expectedImpactIds: ['a_crate', 'a_switch'],
    expectedEvents: ['crate_pushed', 'switch_pressed'],
    directSuccessUpperBound: 18,
    directConnectedUpperBound: 18,
    chainSuccessLowerBound: 60,
    chainConnectedLowerBound: 24,
  ),
  Stage10PropertyShotSolution(
    patternId: 'stage_property_shot_b',
    contract: 'B',
    firstDegree: 312,
    firstPower: 0.12,
    secondDegree: 62,
    secondPower: 0.80,
    directDegree: 126,
    directPower: 0.80,
    familyId: 'slider_reflector_chain',
    directFamilyId: 'direct_bypass',
    conditionalGateId: 'sequence_gate_b',
    expectedImpactIds: ['b_reflector', 'b_bumper'],
    expectedEvents: [
      'power_slider_activated',
      'reflector_rotated',
      'jelly_bounced',
    ],
  ),
  Stage10PropertyShotSolution(
    patternId: 'stage_property_shot_c',
    contract: 'C',
    firstDegree: 0,
    firstPower: 0.12,
    secondDegree: 12,
    secondPower: 0.86,
    directDegree: 128,
    directPower: 0.72,
    familyId: 'sticky_balloon_crate_chain',
    conditionalGateId: 'sequence_gate_c',
    openedGateBankDegree: 63,
    openedGateBankPower: 0.84,
    transferTrait: TraitType.sticky,
    expectedImpactIds: ['spent_ball_1', 'c_crate', 'c_balloon'],
    expectedEvents: [
      'sticky_attached',
      'spent_ball_bounced',
      'balloon_bounced',
    ],
  ),
  Stage10PropertyShotSolution(
    patternId: 'stage_property_shot_d',
    contract: 'D',
    firstDegree: 277,
    firstPower: 0.48,
    secondDegree: 307,
    secondPower: 0.86,
    directDegree: 80,
    directPower: 0.60,
    familyId: 'slider_stone_wall_past_ball',
    directFamilyId: 'direct_bypass',
    conditionalGateId: 'sequence_gate_d',
    expectedImpactIds: ['d_stone', 'd_wall', 'spent_ball_1'],
    expectedEvents: ['power_slider_activated', 'existing_ball_hole_entered'],
  ),
];

ShotInput _input(int degree, double power, [TraitType? trait]) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
    equippedTrait: trait,
  );
}
