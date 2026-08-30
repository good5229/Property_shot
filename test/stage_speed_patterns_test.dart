import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import 'fixtures/stage_speed_patterns.dart';

void main() {
  const resolver = ShotResolver();
  late StageDefinition stage;

  setUpAll(() {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_speed');
  });

  test('6단계는 속도 학습을 위한 네 패턴과 기준 패턴 하나를 가진다', () {
    expect(stage.title, '6. 속도를 되살리는 길');
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_speed_01',
      'stage_speed_02',
      'stage_speed_03',
      'stage_speed_04',
    ]);
    expect(
      stage.patterns.where((pattern) => pattern.metadata['baseline'] == 'true'),
      hasLength(1),
    );
    expect(stage.patterns.every((pattern) => pattern.copyCharges == 0), isTrue);
    expect(
      stage.patterns.every((pattern) => pattern.solutionFamilies.length >= 2),
      isTrue,
    );
    expect(
      stage.patterns.every(
        (pattern) => pattern.acceptedStrategyIds.contains('none'),
      ),
      isTrue,
    );
    expect(
      stage.patterns
          .expand((pattern) => pattern.objects)
          .where((object) => object.type.name == 'powerSlider'),
      isNotEmpty,
    );
  });

  for (final solution in stageSpeedRepresentativeSolutions) {
    test('${solution.patternId} 대표 경로는 ${solution.familyId}를 재현한다', () {
      final result = _resolve(solution);
      expect(result.state.phase, GamePhase.success);
      expect(result.powerSliderActivations, isNotEmpty);
      expect(
        result.powerSliderActivations.any(
          (activation) =>
              activation.sliderEntityId == solution.expectedSliderId,
        ),
        isTrue,
      );
      final activation = result.powerSliderActivations.firstWhere(
        (activation) => activation.sliderEntityId == solution.expectedSliderId,
      );
      final launchSpeed = 8 + solution.power * 16;
      expect(
        activation.speedBefore,
        lessThan(launchSpeed),
        reason: '${solution.patternId}은 발판 진입 전에 실제로 감속해야 합니다.',
      );
      expect(activation.speedAfter, greaterThan(activation.speedBefore));
      if (solution.expectedImpactId != null) {
        expect(
          result.impacts.any(
            (impact) => impact.entityId == solution.expectedImpactId,
          ),
          isTrue,
        );
      }
      if (solution.expectedMoveId != null) {
        expect(
          result.moves.any(
            (move) =>
                move.entityId == solution.expectedMoveId &&
                move.from != move.to,
          ),
          isTrue,
        );
        final pushedPath = result.impacts
            .firstWhere((impact) => impact.entityId == solution.expectedMoveId)
            .pathIndex;
        expect(
          result.powerSliderActivations.first.pathIndex,
          greaterThan(pushedPath),
        );
      }
    });
  }

  for (final solution in stageSpeedWeakAlternatives) {
    test(
      '${solution.patternId} 약한 발사 ${solution.degree}도/${solution.power}는 유효하다',
      () {
        final result = _resolve(solution);
        expect(result.state.phase, GamePhase.success);
        expect(solution.power, lessThanOrEqualTo(0.4));
        expect(
          result.powerSliderActivations.any(
            (activation) =>
                activation.sliderEntityId == solution.expectedSliderId,
          ),
          isTrue,
        );
        if (solution.expectedImpactId != null) {
          expect(
            result.impacts.any(
              (impact) => impact.entityId == solution.expectedImpactId,
            ),
            isTrue,
          );
        }
      },
    );
  }

  for (final solution in stageSpeedBypassSolutions) {
    test('${solution.patternId} 슬라이더 없이도 성공한다', () {
      final result = _resolve(solution);
      expect(result.state.phase, GamePhase.success);
      expect(result.powerSliderActivations, isEmpty);
    });
  }

  test('3번은 상자 이동 뒤 같은 물리 흐름에서 재가속한다', () {
    final result = _resolve(stageSpeedRepresentativeSolutions[2]);
    final pushed = result.impacts.firstWhere(
      (impact) => impact.entityId == 'push_crate',
    );
    final activation = result.powerSliderActivations.firstWhere(
      (item) => item.sourceEntityId == 'push_crate',
    );
    expect(
      result.moves.any(
        (move) => move.entityId == 'push_crate' && move.from != move.to,
      ),
      isTrue,
    );
    expect(activation.pathIndex, greaterThan(pushed.pathIndex));
    expect(activation.speedAfter, greaterThan(activation.speedBefore));
  });

  test('4번은 왼쪽·오른쪽 발판을 각각 선택할 수 있다', () {
    final left = _resolve(stageSpeedChoiceAlternatives.single);
    final right = _resolve(stageSpeedRepresentativeSolutions.last);
    expect(left.powerSliderActivations.single.sliderEntityId, 'left_slider');
    expect(right.powerSliderActivations.single.sliderEntityId, 'right_slider');
    expect(left.state.phase, GamePhase.success);
    expect(right.state.phase, GamePhase.success);
  });

  test('슬라이더는 한 번만 재가속하고 속도 상한·안전 종료를 지킨다', () {
    for (final solution in stageSpeedRepresentativeSolutions) {
      final result = _resolve(solution);
      final activations = result.powerSliderActivations;
      final contactIds = activations
          .map((activation) => activation.contactId)
          .toList();
      expect(
        contactIds.toSet(),
        hasLength(contactIds.length),
        reason: solution.patternId,
      );
      expect(
        activations.every((activation) => activation.speedAfter <= 48),
        isTrue,
      );
      expect(
        activations.every((activation) => activation.speedAfter.isFinite),
        isTrue,
      );
      expect(
        result.chainSafetyDiagnostics,
        isEmpty,
        reason: solution.patternId,
      );
      expect(
        result.physicsEvents.where(
          (event) => event.kind == PhysicsEventKind.powerSliderActivation,
        ),
        hasLength(activations.length),
      );
    }
  });

  test('고속 발사도 슬라이더를 건너뛰지 않고 유한하게 종료한다', () {
    final pattern = stage.patternById('stage_speed_01');
    final state = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(5, productRules: true);
    final result = resolver.resolve(
      state,
      ShotInput(
        direction: stageSpeedRepresentativeSolutions.first.direction,
        power: 1,
      ),
    );
    expect(result.powerSliderActivations, hasLength(1));
    expect(result.chainSafetyDiagnostics, isEmpty);
    expect(
      result.path.every((point) => point.x.isFinite && point.y.isFinite),
      isTrue,
    );
  });
}

ShotResult _resolve(StageSpeedSolution solution) {
  final pattern = _stage.patternById(solution.patternId);
  final state = pattern
      .toLevelDefinition(stageId: _stage.stageId, stageTitle: _stage.title)
      .createState(5, productRules: true);
  return const ShotResolver().resolve(
    state,
    ShotInput(direction: solution.direction, power: solution.power),
  );
}

final StageDefinition _stage = stageCatalogFromJson(
  File('assets/stages/chapter_1.json').readAsStringSync(),
).stageById('stage_speed');
