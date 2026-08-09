import 'package:flutter/material.dart';

String? tutorialCausalHintForStage(int levelIndex) {
  return switch (levelIndex) {
    0 => '인과 힌트 · 무거움 → 상자. 무거움을 공으로 옮긴 뒤 상자와의 충돌을 살펴보세요.',
    1 => '인과 힌트 · 탄성 → 벽 반사. 탄성을 공으로 옮긴 뒤 벽에서 달라지는 움직임을 살펴보세요.',
    2 => '인과 힌트 · 무거움 → 스위치 → 문. 점착은 공을 고정하는 다른 선택지입니다.',
    3 => '인과 힌트 · 뾰족함 → 풍선 → 스위치. 풍선을 터뜨리면 뒤의 스위치가 드러납니다.',
    _ => null,
  };
}

String? persistentTutorialHintFor({
  required int levelIndex,
  required int failedShots,
}) {
  if (levelIndex != 2 || failedShots < 2) return null;
  return '무거움 → 스위치 → 문을 차례로 살펴보세요. '
      '점착은 공을 고정해 다음 충돌의 발판으로 쓸 수 있습니다.';
}

class PersistentTutorialHintCard extends StatelessWidget {
  const PersistentTutorialHintCard({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      excludeSemantics: true,
      label: '계속 표시되는 연쇄 힌트: $text',
      child: Container(
        key: const Key('persistent_tutorial_hint'),
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xF5FFF5D9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE7B45A)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_tree_outlined,
              size: 17,
              color: Color(0xFF8B5A2B),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 3,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF62462D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
