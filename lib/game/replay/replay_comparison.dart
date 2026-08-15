import 'dart:math' as math;

import 'replay_document.dart';

class ReplayComparison {
  const ReplayComparison({
    required this.stageId,
    required this.patternId,
    required this.leftShots,
    required this.rightShots,
    required this.leftAveragePower,
    required this.rightAveragePower,
    required this.leftTraitCount,
    required this.rightTraitCount,
  });

  final String stageId;
  final String patternId;
  final int leftShots;
  final int rightShots;
  final double leftAveragePower;
  final double rightAveragePower;
  final int leftTraitCount;
  final int rightTraitCount;

  factory ReplayComparison.compare(
    ReplayDocument left,
    ReplayDocument right,
  ) {
    if (left.stageId != right.stageId || left.patternId != right.patternId) {
      throw const FormatException('같은 스테이지와 패턴의 리플레이만 비교할 수 있습니다.');
    }
    double averagePower(ReplayDocument document) => document.shots.isEmpty
        ? 0
        : document.shots
                  .map((shot) => shot.powerValue)
                  .reduce((a, b) => a + b) /
              document.shots.length;
    int traitCount(ReplayDocument document) => document.shots
        .map((shot) => shot.equippedTrait)
        .whereType<Object>()
        .toSet()
        .length;
    return ReplayComparison(
      stageId: left.stageId,
      patternId: left.patternId,
      leftShots: left.shots.length,
      rightShots: right.shots.length,
      leftAveragePower: averagePower(left),
      rightAveragePower: averagePower(right),
      leftTraitCount: traitCount(left),
      rightTraitCount: traitCount(right),
    );
  }

  int get shotDifference => rightShots - leftShots;
  double get averagePowerDifference =>
      (rightAveragePower - leftAveragePower).clamp(-1, 1);
  int get traitDifference => rightTraitCount - leftTraitCount;

  String get summary {
    final shotCopy = shotDifference == 0
        ? '발사 수가 같습니다.'
        : shotDifference > 0
        ? '비교 기록이 ${shotDifference.abs()}발 더 사용했습니다.'
        : '비교 기록이 ${shotDifference.abs()}발 적게 사용했습니다.';
    final powerPercent = (averagePowerDifference.abs() * 100).round();
    final powerCopy = powerPercent == 0
        ? '평균 힘도 같습니다.'
        : averagePowerDifference > 0
        ? '평균 힘은 $powerPercent% 더 강합니다.'
        : '평균 힘은 $powerPercent% 더 약합니다.';
    return '$shotCopy $powerCopy';
  }

  double get normalizedDistance => math.min(
    1,
    shotDifference.abs() / 10 + averagePowerDifference.abs(),
  );
}
