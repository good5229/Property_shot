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
    (fixture) => fixture.strategyId == 'none',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
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
        id: '${fixture.patternId}_${fixture.familyId}',
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
        id: '${fixture.patternId}_${fixture.familyId}',
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
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stageDrainedAlternativeSolutions.where(
    (fixture) => fixture.strategyId == 'none',
  )) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stageSpeedBypassSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [ShotInput(direction: fixture.direction, power: fixture.power)],
      ),
    );
  }
  for (final fixture in stagePersistentAlternativeSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
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
        id: '${fixture.patternId}_$familyId',
        familyId: familyId,
        inputs: [fixture.directInput],
      ),
    );
  }
  for (final fixture in stage9RotatingReflectorSolutions) {
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_direct_bypass',
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
          id: '${fixture.patternId}_$directFamilyId',
          familyId: directFamilyId,
          inputs: [fixture.directInput],
        ),
      );
      continue;
    }

    // A/C 계약은 기믹을 직접 완성하는 정규 해법과, 같은 첫 발로 문을 연 뒤
    // 뱅크 샷으로 끝내는 대체 해법을 모두 갖는다. 이전 manifest는 후자만
    // 실행하면서 정규 해법의 family 증거가 있는 것처럼 보이게 했다.
    add(
      fixture.patternId,
      PatternRuntimeScenario(
        id: '${fixture.patternId}_${fixture.familyId}',
        familyId: fixture.familyId,
        inputs: [fixture.firstInput, fixture.secondInput],
      ),
    );
    final openedGateBankInput = fixture.openedGateBankInput;
    if (openedGateBankInput != null) {
      add(
        fixture.patternId,
        PatternRuntimeScenario(
          id: '${fixture.patternId}_opened_gate_bank',
          familyId: 'opened_gate_bank',
          inputs: [fixture.firstInput, openedGateBankInput],
        ),
      );
    }
  }

  return {
    for (final entry in scenarios.entries)
      entry.key: List.unmodifiable(entry.value),
  };
}
