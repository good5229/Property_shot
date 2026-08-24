import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';

class StageBalloonRepresentative {
  const StageBalloonRepresentative({
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

const stageBalloonRepresentatives = <StageBalloonRepresentative>[
  StageBalloonRepresentative(
    patternId: 'stage_balloon_01',
    strategyId: 'sharp',
    degree: 72,
    power: 0.615,
    familyId: 'sharp_pop_chain',
  ),
  StageBalloonRepresentative(
    patternId: 'stage_balloon_01',
    strategyId: 'none',
    degree: 62,
    power: 0.670,
    familyId: 'none_bypass',
  ),
  StageBalloonRepresentative(
    patternId: 'stage_balloon_02',
    strategyId: 'sharp',
    degree: 228,
    power: 0.450,
    familyId: 'sharp_pop_chain',
  ),
  StageBalloonRepresentative(
    patternId: 'stage_balloon_02',
    strategyId: 'none',
    degree: 233,
    power: 0.780,
    familyId: 'balloon_bounce',
  ),
  StageBalloonRepresentative(
    patternId: 'stage_balloon_03',
    strategyId: 'sharp',
    degree: 44,
    power: 0.945,
    familyId: 'sharp_pop_direct',
  ),
  StageBalloonRepresentative(
    patternId: 'stage_balloon_03',
    strategyId: 'none',
    degree: 202,
    power: 0.835,
    familyId: 'none_bypass',
  ),
  StageBalloonRepresentative(
    patternId: 'stage_balloon_04',
    strategyId: 'sharp',
    degree: 46,
    power: 0.945,
    familyId: 'sharp_single_use',
  ),
  StageBalloonRepresentative(
    patternId: 'stage_balloon_04',
    strategyId: 'none',
    degree: 52,
    power: 0.890,
    familyId: 'balloon_bounce',
  ),
];
