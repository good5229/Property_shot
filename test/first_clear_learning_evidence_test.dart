import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/first_clear_learning_evidence.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

import 'fixtures/stage_bouncy_patterns.dart';
import 'fixtures/stage_chain_gate_patterns.dart';
import 'fixtures/stage_heavy_patterns.dart';

void main() {
  late StageCatalog catalog;

  setUpAll(() {
    catalog = StageCatalog.fromJsonString(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
  });

  test('1~3단계의 알려진 무기믹 우회 클리어는 최초 학습 증거가 아니다', () {
    final cases =
        <
          ({
            int level,
            String stageId,
            String patternId,
            String strategyId,
            Vec2 direction,
            double power,
          })
        >[
          (
            level: 0,
            stageId: 'stage_heavy',
            patternId: stageHeavyRepresentatives[0].patternId,
            strategyId: stageHeavyRepresentatives[0].strategyId,
            direction: stageHeavyRepresentatives[0].direction,
            power: stageHeavyRepresentatives[0].power,
          ),
          (
            level: 1,
            stageId: 'stage_bouncy',
            patternId: stageBouncyRepresentatives[0].patternId,
            strategyId: stageBouncyRepresentatives[0].strategyId,
            direction: stageBouncyRepresentatives[0].direction,
            power: stageBouncyRepresentatives[0].power,
          ),
          (
            level: 2,
            stageId: 'stage_chain_gate',
            patternId: stageChainGateRepresentatives[0].patternId,
            strategyId: stageChainGateRepresentatives[0].strategyId,
            direction: stageChainGateRepresentatives[0].direction,
            power: stageChainGateRepresentatives[0].power,
          ),
        ];

    for (final entry in cases) {
      final replay = _resolveRepresentative(
        catalog: catalog,
        levelIndex: entry.level,
        stageId: entry.stageId,
        patternId: entry.patternId,
        strategyId: entry.strategyId,
        direction: entry.direction,
        power: entry.power,
      );
      expect(replay.result.state.phase, GamePhase.success);
      expect(
        evaluateFirstClearLearningEvidence(
          levelIndex: entry.level,
          results: [replay.result],
          inputs: [replay.input],
        ).satisfied,
        isFalse,
        reason: entry.stageId,
      );
    }
  });

  test('1~3단계의 대표 기믹 풀이에는 실제 상호작용 증거가 남는다', () {
    final cases =
        <
          ({
            int level,
            String stageId,
            String patternId,
            String strategyId,
            Vec2 direction,
            double power,
          })
        >[
          (
            level: 0,
            stageId: 'stage_heavy',
            patternId: stageHeavyRepresentatives[1].patternId,
            strategyId: stageHeavyRepresentatives[1].strategyId,
            direction: stageHeavyRepresentatives[1].direction,
            power: stageHeavyRepresentatives[1].power,
          ),
          (
            level: 1,
            stageId: 'stage_bouncy',
            patternId: stageBouncyRepresentatives[1].patternId,
            strategyId: stageBouncyRepresentatives[1].strategyId,
            direction: stageBouncyRepresentatives[1].direction,
            power: stageBouncyRepresentatives[1].power,
          ),
          (
            level: 2,
            stageId: 'stage_chain_gate',
            patternId: stageChainGateRepresentatives[1].patternId,
            strategyId: stageChainGateRepresentatives[1].strategyId,
            direction: stageChainGateRepresentatives[1].direction,
            power: stageChainGateRepresentatives[1].power,
          ),
        ];

    for (final entry in cases) {
      final replay = _resolveRepresentative(
        catalog: catalog,
        levelIndex: entry.level,
        stageId: entry.stageId,
        patternId: entry.patternId,
        strategyId: entry.strategyId,
        direction: entry.direction,
        power: entry.power,
      );
      expect(replay.result.state.phase, GamePhase.success);
      expect(
        evaluateFirstClearLearningEvidence(
          levelIndex: entry.level,
          results: [replay.result],
          inputs: [replay.input],
        ).satisfied,
        isTrue,
        reason: entry.stageId,
      );
    }
  });

  test('빈 복원 기록과 비정상 단계 입력은 예외 없이 보수적으로 처리한다', () {
    expect(
      evaluateFirstClearLearningEvidence(
        levelIndex: 2,
        results: const [],
        inputs: const [],
      ).satisfied,
      isFalse,
    );
    expect(
      evaluateFirstClearLearningEvidence(
        levelIndex: 99,
        results: const [],
        inputs: const [],
      ).satisfied,
      isTrue,
    );
  });
}

({ShotResult result, ShotInput input}) _resolveRepresentative({
  required StageCatalog catalog,
  required int levelIndex,
  required String stageId,
  required String patternId,
  required String strategyId,
  required Vec2 direction,
  required double power,
}) {
  final stage = catalog.stageById(stageId);
  final pattern = stage.patternById(patternId);
  final state = _stateFor(
    pattern: pattern,
    levelIndex: levelIndex,
    stageId: stageId,
    title: stage.title,
    strategyId: strategyId,
  );
  final input = ShotInput(
    direction: direction,
    power: power,
    equippedTrait: state.equippedTrait,
  );
  return (result: const ShotResolver().resolve(state, input), input: input);
}

GameState _stateFor({
  required StagePattern pattern,
  required int levelIndex,
  required String stageId,
  required String title,
  required String strategyId,
}) {
  var state = pattern
      .toLevelDefinition(stageId: stageId, stageTitle: title)
      .createState(levelIndex);
  if (strategyId != 'none') {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(
      traits.selectSource(state, strategyId),
    );
  }
  return state;
}
