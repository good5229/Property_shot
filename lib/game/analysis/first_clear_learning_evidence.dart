import '../domain/entity_state.dart';
import '../domain/shot_input.dart';
import '../domain/trait.dart';
import '../simulation/shot_resolver.dart';

class FirstClearLearningEvidence {
  const FirstClearLearningEvidence({
    required this.satisfied,
    required this.guidance,
  });

  final bool satisfied;
  final String guidance;
}

/// 첫 세 스테이지를 처음 통과할 때 핵심 상호작용을 실제로 경험했는지 확인한다.
///
/// 이후 재도전에는 적용하지 않아 우회 해법과 기록 단축의 자유를 보존한다.
FirstClearLearningEvidence evaluateFirstClearLearningEvidence({
  required int levelIndex,
  required List<ShotResult> results,
  required List<ShotInput> inputs,
}) {
  final satisfied = switch (levelIndex) {
    0 =>
      inputs.any((input) => input.equippedTrait == TraitType.heavy) &&
          results.any(
            (result) => result.moves.any((move) {
              final moved = result.state.entityById(move.entityId);
              return moved?.type == EntityType.crate && move.from != move.to;
            }),
          ),
    1 =>
      inputs.any((input) => input.equippedTrait == TraitType.bouncy) &&
          results.any(
            (result) => result.events.contains('bounced'),
          ),
    2 =>
      results.any((result) => result.events.contains('switch_pressed')) &&
          results.lastOrNull?.state.entityById('gate')?.open == true,
    _ => true,
  };
  return FirstClearLearningEvidence(
    satisfied: satisfied,
    guidance: switch (levelIndex) {
      0 => '첫 클리어에서는 무거움을 공에 옮겨 상자를 실제로 움직여 보세요.',
      1 => '첫 클리어에서는 젤리의 탄성을 공에 옮기고 벽 반사를 이용해 홀에 넣어 보세요.',
      2 => '첫 클리어에서는 스위치를 먼저 눌러 문을 연 뒤 홀에 넣어 보세요.',
      _ => '이번 스테이지의 핵심 기믹을 수행한 뒤 다시 홀에 넣어 보세요.',
    },
  );
}
