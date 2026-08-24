import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/virtual_player_simulator.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/input/intent_assist_resolver.dart';

void main() {
  const simulator = VirtualPlayerSimulator();
  final scenario = VirtualPlayerScenario(
    id: 'straight_hole',
    initialState: _state(),
    canonicalShots: const [ShotInput(direction: Vec2(1, 0), power: 0.6)],
  );
  const noisyPointer = VirtualPlayerPersona(
    id: 'test_pointer',
    label: '테스트 포인터',
    angleSigmaDegrees: 5,
    powerSigma: 0.04,
    compactPointer: true,
  );

  test('같은 시드의 가상 플레이는 완전히 같은 결과를 만든다', () {
    final first = simulator.run(
      scenario: scenario,
      persona: noisyPointer,
      assistStrength: IntentAssistStrength.standard,
      trials: 100,
      seed: 42,
    );
    final second = simulator.run(
      scenario: scenario,
      persona: noisyPointer,
      assistStrength: IntentAssistStrength.standard,
      trials: 100,
      seed: 42,
    );

    expect(second.clears, first.clears);
    expect(second.assistedShots, first.assistedShots);
    expect(second.targetSnaps, first.targetSnaps);
    expect(second.localRescues, first.localRescues);
    expect(
      second.totalAbsoluteAngleCorrection,
      first.totalAbsoluteAngleCorrection,
    );
  });

  test('표준 보정은 무보정보다 noisy 포인터의 성공률을 낮추지 않는다', () {
    final direct = simulator.run(
      scenario: scenario,
      persona: noisyPointer,
      assistStrength: IntentAssistStrength.off,
      trials: 400,
      seed: 7,
    );
    final assisted = simulator.run(
      scenario: scenario,
      persona: noisyPointer,
      assistStrength: IntentAssistStrength.standard,
      trials: 400,
      seed: 7,
    );

    expect(direct.assistedShots, 0);
    expect(direct.targetSnaps, 0);
    expect(assisted.clearRate, greaterThanOrEqualTo(direct.clearRate));
    expect(assisted.assistedShots, greaterThan(0));
    expect(assisted.localRescues, greaterThan(0));
    expect(assisted.safe, isTrue);
  });

  test('기믹 판정은 단순 클리어와 별도로 집계한다', () {
    final noMechanic = VirtualPlayerScenario(
      id: 'mechanic_contract',
      initialState: _state(),
      canonicalShots: const [ShotInput(direction: Vec2(1, 0), power: 0.6)],
      mechanicCheck: (_) => false,
    );
    final result = simulator.run(
      scenario: noMechanic,
      persona: const VirtualPlayerPersona(
        id: 'exact',
        label: '정확',
        angleSigmaDegrees: 0,
        powerSigma: 0,
      ),
      assistStrength: IntentAssistStrength.off,
      trials: 5,
    );

    expect(result.clears, 5);
    expect(result.mechanicClears, 0);
  });

  test('비정상 프로필과 과도한 반복 횟수를 거부한다', () {
    expect(
      () => simulator.run(
        scenario: scenario,
        persona: const VirtualPlayerPersona(
          id: 'bad',
          label: '비정상',
          angleSigmaDegrees: double.nan,
          powerSigma: 0,
        ),
        assistStrength: IntentAssistStrength.standard,
      ),
      throwsArgumentError,
    );
    expect(
      () => simulator.run(
        scenario: scenario,
        persona: noisyPointer,
        assistStrength: IntentAssistStrength.standard,
        trials: 0,
      ),
      throwsArgumentError,
    );
  });
}

GameState _state() => const GameState(
  levelIndex: 0,
  levelName: '가상 플레이어 시험',
  ballSpawn: Vec2(100, 280),
  entities: [
    EntityState(
      id: 'active_ball',
      type: EntityType.ball,
      position: Vec2(100, 280),
      size: Vec2(20, 20),
      movable: true,
      hitboxScale: 1,
    ),
    EntityState(
      id: 'hole',
      type: EntityType.hole,
      position: Vec2(300, 280),
      size: Vec2(28, 28),
      solid: false,
      hitboxScale: 1,
    ),
  ],
);
