import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';

class StageChainGateRepresentative {
  const StageChainGateRepresentative({
    required this.patternId,
    required this.strategyId,
    required this.degree,
    required this.power,
    required this.familyId,
  });

  final String patternId;
  final String strategyId;
  final int degree;
  final double power;
  final String familyId;

  Vec2 get direction {
    final radians = degree * math.pi / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }
}

class StageChainGatePreparedShot {
  const StageChainGatePreparedShot({
    required this.patternId,
    required this.firstDegree,
    required this.firstPower,
    required this.secondDegree,
    required this.secondPower,
  });

  final String patternId;
  final int firstDegree;
  final double firstPower;
  final int secondDegree;
  final double secondPower;

  Vec2 get firstDirection {
    final radians = firstDegree * math.pi / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }

  Vec2 get secondDirection {
    final radians = secondDegree * math.pi / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }
}

const stageChainGateRepresentatives = <StageChainGateRepresentative>[
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_01',
    strategyId: 'none',
    degree: 234,
    power: 0.65,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_01',
    strategyId: 'steel',
    degree: 66,
    power: 0.65,
    familyId: 'steel_switch',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_02',
    strategyId: 'none',
    degree: 204,
    power: 0.80,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_02',
    strategyId: 'steel',
    degree: 236,
    power: 0.30,
    familyId: 'steel_switch',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_03',
    strategyId: 'none',
    degree: 76,
    power: 0.90,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_03',
    strategyId: 'steel',
    degree: 220,
    power: 0.35,
    familyId: 'steel_switch',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_04',
    strategyId: 'none',
    degree: 86,
    power: 0.55,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_04',
    strategyId: 'steel',
    degree: 82,
    power: 0.55,
    familyId: 'steel_switch',
  ),
];

const stageChainGatePreparedShots = <StageChainGatePreparedShot>[
  StageChainGatePreparedShot(
    patternId: 'stage_chain_gate_02',
    firstDegree: 0,
    firstPower: 0.12,
    secondDegree: 319,
    secondPower: 0.56,
  ),
  StageChainGatePreparedShot(
    patternId: 'stage_chain_gate_02',
    firstDegree: 0,
    firstPower: 0.175,
    secondDegree: 319,
    secondPower: 0.615,
  ),
  StageChainGatePreparedShot(
    patternId: 'stage_chain_gate_02',
    firstDegree: 4,
    firstPower: 0.175,
    secondDegree: 326,
    secondPower: 0.67,
  ),
];
