import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';

class StageBouncyRepresentative {
  const StageBouncyRepresentative({
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
    final radians = degree * 3.141592653589793 / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }
}

class StageBouncyCollisionFixture {
  const StageBouncyCollisionFixture({
    required this.patternId,
    required this.degree,
    required this.power,
    required this.minimumPathGain,
  });

  final String patternId;
  final int degree;
  final double power;
  final double minimumPathGain;

  Vec2 get direction {
    final radians = degree * 3.141592653589793 / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }
}

// 저장된 값은 임시 탐색 결과가 아니라 실제 resolver 재생용 QA 입력이다.
const stageBouncyRepresentatives = <StageBouncyRepresentative>[
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_01',
    strategyId: 'none',
    degree: 292,
    power: 0.80,
    familyId: 'wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_01',
    strategyId: 'jelly',
    degree: 48,
    power: 0.90,
    familyId: 'multi_wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_02',
    strategyId: 'none',
    degree: 11,
    power: 0.95,
    familyId: 'wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_02',
    strategyId: 'jelly',
    degree: 210,
    power: 0.70,
    familyId: 'wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_02',
    strategyId: 'none',
    degree: 314,
    power: 0.96,
    familyId: 'jelly_interaction',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_03',
    strategyId: 'none',
    degree: 286,
    power: 1.00,
    familyId: 'wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_03',
    strategyId: 'jelly',
    degree: 204,
    power: 0.85,
    familyId: 'wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_03',
    strategyId: 'jelly',
    degree: 200,
    power: 0.97,
    familyId: 'multi_wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_04',
    strategyId: 'jelly',
    degree: 104,
    power: 0.90,
    familyId: 'wall_reflection',
  ),
  StageBouncyRepresentative(
    patternId: 'stage_bouncy_04',
    strategyId: 'none',
    degree: 246,
    power: 0.88,
    familyId: 'multi_wall_reflection',
  ),
];

const stageBouncyCollisionFixtures = <StageBouncyCollisionFixture>[
  StageBouncyCollisionFixture(
    patternId: 'stage_bouncy_01',
    degree: 4,
    power: 0.42,
    minimumPathGain: 8,
  ),
  StageBouncyCollisionFixture(
    patternId: 'stage_bouncy_02',
    degree: 25,
    power: 0.95,
    minimumPathGain: 12,
  ),
  StageBouncyCollisionFixture(
    patternId: 'stage_bouncy_03',
    degree: 20,
    power: 0.08,
    minimumPathGain: 33,
  ),
  StageBouncyCollisionFixture(
    patternId: 'stage_bouncy_04',
    degree: 0,
    power: 0.22,
    minimumPathGain: 9,
  ),
];
