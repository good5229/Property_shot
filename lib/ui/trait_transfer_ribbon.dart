import 'package:flutter/material.dart';

import '../game/domain/entity_state.dart';
import '../game/domain/trait.dart';

@immutable
class TraitTransferFeedback {
  const TraitTransferFeedback({
    required this.sourceName,
    required this.sourceType,
    required this.trait,
    required this.sourceEffect,
  });

  final String sourceName;
  final EntityType sourceType;
  final TraitType trait;
  final String sourceEffect;

  String get semanticsLabel =>
      '속성 이전 완료. 원본 $sourceName은 ${trait.label}을 잃어 $sourceEffect. '
      '공은 ${trait.label}을 얻었습니다.';
}

String traitLossConsequence(EntityState source, TraitType trait) {
  return switch (trait) {
    TraitType.heavy =>
      source.movableWhenDrained
          ? '가벼워져 충돌하면 움직입니다'
          : '무거운 충돌과 무게 스위치 효과가 사라집니다',
    TraitType.bouncy =>
      source.movableWhenDrained
          ? '탄성을 잃어 튕기지 않고 움직입니다'
          : '탄성을 잃어 더는 강하게 반사하지 않습니다',
    TraitType.sticky =>
      source.movableWhenDrained
          ? '점착을 잃어 공을 붙잡지 않고 움직입니다'
          : '점착을 잃어 더는 공을 붙잡지 않습니다',
    TraitType.sharp =>
      source.movableWhenDrained
          ? '뾰족함을 잃어 풍선을 터뜨리지 않고 움직입니다'
          : '뾰족함을 잃어 더는 풍선을 터뜨리지 못합니다',
  };
}

class TraitTransferRibbon extends StatelessWidget {
  const TraitTransferRibbon({super.key, required this.feedback});

  final TraitTransferFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('trait_transfer_ribbon_semantics'),
      container: true,
      liveRegion: true,
      label: feedback.semanticsLabel,
      excludeSemantics: true,
      child: Container(
        key: const Key('trait_transfer_ribbon'),
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 2),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF3D0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8A6527), width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _TransferStateNode(
                    asset: _sourceAsset(feedback.sourceType),
                    title: '원본 · ${feedback.sourceName}',
                    state: '${feedback.trait.label} 보유 → 비움',
                    drained: true,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFF8A6527),
                    size: 24,
                  ),
                ),
                Expanded(
                  child: _TransferStateNode(
                    asset: _ballAsset(feedback.trait),
                    title: '공',
                    state: '기본 → ${feedback.trait.label}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              '원본: ${feedback.sourceEffect}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF5A4825),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferStateNode extends StatelessWidget {
  const _TransferStateNode({
    required this.asset,
    required this.title,
    required this.state,
    this.drained = false,
  });

  final String asset;
  final String title;
  final String state;
  final bool drained;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: drained ? 0.5 : 1,
              child: Image.asset(
                asset,
                width: 38,
                height: 38,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            if (drained)
              Transform.rotate(
                angle: -0.72,
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B3F32),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                state,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, height: 1.15),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _sourceAsset(EntityType type) => switch (type) {
  EntityType.weight => 'assets/generated/stone-v3.png',
  EntityType.bumper => 'assets/generated/jelly-bumper-v2.png',
  EntityType.stickySurface => 'assets/generated/sticky-pad-v1.png',
  EntityType.spikeSource => 'assets/generated/spike-source-v1.png',
  _ => 'assets/generated/crate-v3.png',
};

String _ballAsset(TraitType trait) => switch (trait) {
  TraitType.heavy => 'assets/generated/ball-heavy-v1.png',
  TraitType.bouncy => 'assets/generated/ball-bouncy-v1.png',
  TraitType.sticky => 'assets/generated/ball-sticky-v1.png',
  TraitType.sharp => 'assets/generated/ball-sharp-v1.png',
};
