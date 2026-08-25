import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';

import '../test/fixtures/stage10_property_shot_patterns.dart';
import '../test/fixtures/stage9_rotating_reflector_patterns.dart';
import '../test/fixtures/stage_balloon_patterns.dart';
import '../test/fixtures/stage_bouncy_patterns.dart';
import '../test/fixtures/stage_chain_gate_patterns.dart';
import '../test/fixtures/stage_chain_score_patterns.dart';
import '../test/fixtures/stage_drained_patterns.dart';
import '../test/fixtures/stage_heavy_patterns.dart';
import '../test/fixtures/stage_persistent_patterns.dart';
import '../test/fixtures/stage_speed_patterns.dart';

/// 스테이지별 회귀 fixture에서 생산 카탈로그 검증용 대표 해법을 모은다.
///
/// 이 manifest는 정답을 게임에 노출하지 않는다. 각 패턴이 선언한 풀이 계열
/// 중 하나와 런 보상을 쓰지 않는 실제 성공 경로가 계속 존재하는지만 검사한다.
Map<String, List<PatternRuntimeScenario>> buildRuntimeValidationManifest() {
  final scenarios = <String, List<PatternRuntimeScenario>>{};

  void add(String patternId, PatternRuntimeScenario scenario) {
    scenarios.putIfAbsent(patternId, () => []).add(scenario);
  }

  for (final fixture in stageHeavyRepresentatives.where(
    (fixture) => fixture.strategyId == 'anvil',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
        intendedMechanic: true,
        traitSourceEntityId: 'anvil',
      ),
    );
  }
  for (final fixture in stageBouncyRepresentatives.where(
    (fixture) => fixture.strategyId == 'jelly',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
        intendedMechanic: true,
        traitSourceEntityId: 'jelly',
      ),
    );
  }
  for (final fixture in stageChainGateRepresentatives.where(
    (fixture) => fixture.strategyId == 'steel',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
        intendedMechanic: true,
        traitSourceEntityId: 'steel',
      ),
    );
  }
  for (final fixture in stageBalloonRepresentatives.where(
    (fixture) => fixture.strategyId == 'sharp',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
        intendedMechanic: true,
        traitSourceEntityId: 'spike_source',
      ),
    );
  }
  for (final fixture in stageDrainedRepresentativeSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
        intendedMechanic: true,
        traitSourceEntityId: fixture.strategyId,
      ),
    );
  }
  for (final fixture in stageSpeedRepresentativeSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
        intendedMechanic: true,
      ),
    );
  }
  for (final fixture in stagePersistentRepresentativeSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [fixture.firstInput, fixture.secondInput],
        intendedMechanic: true,
      ),
    );
  }
  for (final fixture in stageChainScoreSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [fixture.firstInput, fixture.secondInput],
        intendedMechanic: true,
      ),
    );
  }
  const reflectorFamilies = <String, String>{
    'stage_rotating_reflector_01': 'single_reflector_prepare',
    'stage_rotating_reflector_02': 'two_reflector_order',
    'stage_rotating_reflector_03': 'past_ball_activation',
    'stage_rotating_reflector_04': 'slider_reflector_chain',
  };
  for (final fixture in stage9RotatingReflectorSolutions) {
    final familyId = reflectorFamilies[fixture.patternId]!;
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_$familyId',
        familyId: familyId,
        inputs: [fixture.firstInput, fixture.secondInput],
        intendedMechanic: true,
      ),
    );
  }
  for (final fixture in stage10PropertyShotSolutions) {
    final traitSourceEntityId = switch (fixture.contract) {
      'A' => 'a_stone',
      'C' => 'c_sticky',
      _ => null,
    };
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [fixture.firstInput, fixture.secondInput],
        intendedMechanic: true,
        traitSourceEntityId: traitSourceEntityId,
      ),
    );
  }

  // 대체 해법도 계속 재생해 선언된 모든 solution family가 살아 있는지
  // 확인한다. 다만 아래 시나리오는 의도 기믹 증거로 승격하지 않는다.
  for (final fixture in stageHeavyRepresentatives.where(
    (fixture) => fixture.strategyId == 'none',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}_alternative',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stageBouncyRepresentatives.where(
    (fixture) => fixture.strategyId == 'none',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}_alternative',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stageChainGateRepresentatives.where(
    (fixture) => fixture.strategyId == 'none',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}_alternative',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stageBalloonRepresentatives.where(
    (fixture) => fixture.strategyId == 'none',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}_alternative',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stageDrainedAlternativeSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}_alternative',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
        traitSourceEntityId: fixture.strategyId == 'none'
            ? null
            : fixture.strategyId,
      ),
    );
  }
  for (final fixture in stageSpeedBypassSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}_alternative',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stagePersistentAlternativeSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}_alternative',
        familyId: fixture.familyId,
        inputs: [fixture.firstInput],
      ),
    );
  }
  for (final fixture in stageChainScoreSolutions) {
    final familyId = fixture.patternId == 'stage_chain_score_04'
        ? 'straight_low_chain_high'
        : 'direct_bypass';
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${familyId}_alternative',
        familyId: familyId,
        inputs: [fixture.directInput],
      ),
    );
  }
  for (final fixture in stage9RotatingReflectorSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_direct_bypass_alternative',
        familyId: 'direct_bypass',
        inputs: [fixture.directInput],
      ),
    );
  }
  for (final fixture in stage10PropertyShotSolutions) {
    final directFamilyId = fixture.directFamilyId;
    if (directFamilyId != null) {
      add(
        fixture.patternId,
        PatternRuntimeScenario(
          id: '${fixture.patternId}_${directFamilyId}_alternative',
          familyId: directFamilyId,
          inputs: [fixture.directInput],
        ),
      );
      continue;
    }
    final openedGateBankInput = fixture.openedGateBankInput;
    if (openedGateBankInput != null) {
      final traitSourceEntityId = fixture.contract == 'A'
          ? 'a_stone'
          : 'c_sticky';
      add(
        fixture.patternId,
        PatternRuntimeScenario(
          id: '${fixture.patternId}_opened_gate_bank_alternative',
          familyId: 'opened_gate_bank',
          inputs: [fixture.firstInput, openedGateBankInput],
          traitSourceEntityId: traitSourceEntityId,
        ),
      );
    }
  }

  return {
    for (final entry in scenarios.entries)
      entry.key: List.unmodifiable(entry.value),
  };
}
