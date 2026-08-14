import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/stage_discovery.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';

void main() {
  test('1단계 발견 임무는 속성 사용과 클리어를 별도 성취로 보여준다', () {
    final initial = levels.first.createState(0, productRules: true);
    final before = stageDiscoveryMilestones(
      state: initial,
      shotInputs: const [],
      shotResults: const [],
    );
    expect(before.map((item) => item.label), ['무거움 장착', '상자 움직임', '홀 도착']);
    expect(before.where((item) => item.achieved), isEmpty);

    final afterTrait = stageDiscoveryMilestones(
      state: initial,
      shotInputs: const [
        ShotInput(
          direction: Vec2(1, 0),
          power: .5,
          equippedTrait: TraitType.heavy,
        ),
      ],
      shotResults: const [],
    );
    expect(afterTrait.first.achieved, isTrue);
    expect(afterTrait.last.achieved, isFalse);

    final afterClear = stageDiscoveryMilestones(
      state: initial.copyWith(phase: GamePhase.success),
      shotInputs: const [],
      shotResults: const [],
    );
    expect(afterClear.last.achieved, isTrue);
  });

  test('10개 스테이지 질문은 플레이 목적을 한 문장으로 제공한다', () {
    final questions = [
      for (var index = 0; index < 10; index++) stageDiscoveryQuestion(index),
    ];
    expect(questions.toSet(), hasLength(10));
    expect(questions.every((question) => question.endsWith('?')), isTrue);
  });

  test('10개 스테이지는 지도 저장에 사용할 안정 발견 ID를 각 3개 제공한다', () {
    for (var index = 0; index < 10; index++) {
      final ids = stageDiscoveryMilestoneIds(index);
      expect(ids, hasLength(3), reason: '${index + 1}단계');
      expect(ids, contains('hole_reached'));
    }
    expect(stageDiscoveryMilestoneIds(0), {
      'heavy_equipped',
      'crate_moved',
      'hole_reached',
    });
    for (var index = 0; index < 10; index++) {
      expect(
        stageDiscoveryMilestoneLabels(index).keys.toSet(),
        stageDiscoveryMilestoneIds(index),
      );
    }
  });
}
