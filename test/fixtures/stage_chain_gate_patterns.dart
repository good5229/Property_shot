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
    degree: 230,
    power: 0.72,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_01',
    strategyId: 'steel',
    degree: 76,
    power: 0.94,
    familyId: 'steel_switch',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_02',
    strategyId: 'none',
    degree: 206,
    power: 0.80,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_02',
    strategyId: 'steel',
    degree: 308,
    power: 0.64,
    familyId: 'steel_switch',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_03',
    strategyId: 'none',
    degree: 288,
    power: 0.64,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_03',
    strategyId: 'steel',
    degree: 216,
    power: 0.54,
    familyId: 'steel_switch',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_04',
    strategyId: 'none',
    degree: 290,
    power: 0.70,
    familyId: 'none_direct',
  ),
  StageChainGateRepresentative(
    patternId: 'stage_chain_gate_04',
    strategyId: 'steel',
    degree: 84,
    power: 0.50,
    familyId: 'steel_switch',
  ),
];

const stageChainGatePreparedShots = <StageChainGatePreparedShot>[
  StageChainGatePreparedShot(
    patternId: 'stage_chain_gate_02',
    firstDegree: 0,
    firstPower: 0.12,
    secondDegree: 344,
    secondPower: 0.395,
  ),
  StageChainGatePreparedShot(
    patternId: 'stage_chain_gate_02',
    firstDegree: 1,
    firstPower: 0.175,
    secondDegree: 345,
    secondPower: 0.34,
  ),
  StageChainGatePreparedShot(
    patternId: 'stage_chain_gate_02',
    firstDegree: 5,
    firstPower: 0.23,
    secondDegree: 350,
    secondPower: 0.67,
  ),
];
