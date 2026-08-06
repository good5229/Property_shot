import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';

/// PS-STAGE-01B-1에서 결정론적 탐색으로 발견한 대표 입력이다.
///
/// degree/power 주변의 작은 변형도 별도 테스트에서 재생한다. 이 자료는
/// 추천 정답이나 점수 계산에 사용하지 않고 패턴 QA 회귀에만 사용한다.
class StageHeavyRepresentative {
  const StageHeavyRepresentative({
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

const List<StageHeavyRepresentative> stageHeavyRepresentatives = [
  StageHeavyRepresentative(
    patternId: 'stage_heavy_01',
    strategyId: 'none',
    degree: 62,
    power: 0.70,
    familyId: 'wall_reflection',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_01',
    strategyId: 'anvil',
    degree: 72,
    power: 0.56,
    familyId: 'crate_push',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_02',
    strategyId: 'none',
    degree: 38,
    power: 0.96,
    familyId: 'wall_reflection',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_02',
    strategyId: 'anvil',
    degree: 42,
    power: 0.96,
    familyId: 'multi_wall_reflection',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_03',
    strategyId: 'none',
    degree: 230,
    power: 0.68,
    familyId: 'wall_reflection',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_03',
    strategyId: 'none',
    degree: 326,
    power: 0.56,
    familyId: 'crate_push',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_03',
    strategyId: 'anvil',
    degree: 66,
    power: 0.60,
    familyId: 'crate_push',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_04',
    strategyId: 'none',
    degree: 60,
    power: 0.70,
    familyId: 'wall_reflection',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_04',
    strategyId: 'none',
    degree: 306,
    power: 0.60,
    familyId: 'crate_push',
  ),
  StageHeavyRepresentative(
    patternId: 'stage_heavy_04',
    strategyId: 'anvil',
    degree: 66,
    power: 0.62,
    familyId: 'crate_push',
  ),
];

class StageHeavyCollisionFixture {
  const StageHeavyCollisionFixture({
    required this.patternId,
    required this.degree,
    required this.power,
  });

  final String patternId;
  final int degree;
  final double power;

  Vec2 get direction {
    final radians = degree * math.pi / 180;
    return Vec2(math.cos(radians), math.sin(radians));
  }
}

const stageHeavyCollisionFixtures = [
  StageHeavyCollisionFixture(
    patternId: 'stage_heavy_01',
    degree: 40,
    power: 0.62,
  ),
  StageHeavyCollisionFixture(
    patternId: 'stage_heavy_02',
    degree: 48,
    power: 0.78,
  ),
  StageHeavyCollisionFixture(
    patternId: 'stage_heavy_03',
    degree: 54,
    power: 0.34,
  ),
  StageHeavyCollisionFixture(
    patternId: 'stage_heavy_04',
    degree: 30,
    power: 0.58,
  ),
];
