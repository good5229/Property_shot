import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/multi_shot_analyzer.dart';

void main() {
  test('이전 공 상태를 보존한 다중 샷 분석은 성공 순서와 최소 샷을 기록한다', () {
    const analyzer = MultiShotDifficultyAnalyzer(
      angleStepDegrees: 20,
      powerSteps: 5,
      maxShots: 2,
    );
    final metrics = analyzer.analyzeLevel(0);

    expect(metrics.totalSequences, greaterThan(0));
    expect(metrics.successfulSequences, greaterThan(0));
    expect(metrics.minimumShots, lessThanOrEqualTo(2));
    expect(metrics.copylessSuccess, isTrue);
    expect(
      metrics.strategyMetrics.any((item) => item.label.contains('복제')),
      isTrue,
    );
    expect(metrics.examples.every((plan) => plan.shots.length <= 2), isTrue);
  });
}
