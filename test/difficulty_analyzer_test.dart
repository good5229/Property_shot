import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/difficulty_analyzer.dart';
import 'package:property_shot/game/levels/levels.dart';

void main() {
  test('첫 챕터 자동 분석은 각 단계의 성공 영역과 최소 샷을 산출한다', () {
    const analyzer = DifficultyAnalyzer();
    final metrics = analyzer.analyzeAll();

    expect(metrics, hasLength(3));
    expect(metrics.map((result) => result.recommendedParShots), [2, 3, 3]);
    expect(
      metrics.asMap().entries.map(
        (entry) =>
            levels[entry.key].parShots == entry.value.recommendedParShots,
      ),
      everyElement(isTrue),
    );
    for (final result in metrics) {
      expect(result.totalInputs, greaterThan(0));
      expect(result.successInputs, greaterThan(0));
      expect(result.successRate, greaterThan(0));
      expect(result.widestAngleDegrees, greaterThan(0));
      expect(result.widestPowerRange, greaterThan(0));
      expect(result.largestConnectedRegion, greaterThanOrEqualTo(1));
      expect(result.minimumShots, 1);
      expect(result.successfulStrategies, isNotEmpty);
      expect(result.strategyMetrics, isNotEmpty);
      expect(result.intendedStrategyId, isNotNull);
      expect(result.dominantStrategyId, isNotNull);
      expect(result.dominantStrategy, isNotNull);
      expect(result.dominantStrategyShare, greaterThan(0));
      expect(result.dominantStrategyShare, lessThanOrEqualTo(1));
      expect(result.alternativeStrategyCount, greaterThanOrEqualTo(0));
      expect(result.intendedStrategyMatchesDominant, isTrue);
      expect(result.uniqueSuccessfulInputs, greaterThan(0));
      expect(result.accidentalSuccessInputs, 0);
      expect(result.accidentalSuccessRate, 0);
      expect(result.inputPrecisionSensitivity, greaterThan(0));
      expect(
        result.strategyMetrics.every(
          (strategy) => strategy.inputPrecisionSensitivity >= 0,
        ),
        isTrue,
      );
    }
  });

  test('현재 첫 챕터는 복사 없이 성공 입력을 포함한다', () {
    const analyzer = DifficultyAnalyzer();
    final metrics = analyzer.analyzeAll();

    expect(metrics.every((result) => result.copylessSuccess), isTrue);
  });

  test('성공률이 낮은 단계에는 분석 기반 파 여유를 더한다', () {
    expect(recommendedParShotsFor(minimumShots: 1, successRate: 0.06), 2);
    expect(recommendedParShotsFor(minimumShots: 1, successRate: 0.03), 3);
    expect(
      recommendedParShotsFor(minimumShots: null, successRate: 0.03),
      isNull,
    );
  });

  test('승인되지 않은 전략은 우연 경로 후보로 분리한다', () {
    const analyzer = DifficultyAnalyzer();
    final metrics = analyzer.analyzeLevel(0);

    expect(metrics.successfulStrategies, contains('무속성'));
    expect(metrics.successfulStrategies, contains('anvil (무거움)'));
    expect(metrics.accidentalSuccessInputs, 0);
    expect(metrics.dominantStrategy, 'anvil (무거움)');
    expect(metrics.alternativeStrategyCount, 1);
    expect(metrics.uniqueSuccessfulInputs, greaterThanOrEqualTo(72));
    expect(metrics.dominantStrategyShare, greaterThanOrEqualTo(0.85));
  });

  test('QA 허용 목록 재정의가 우연 경로 후보를 실제로 드러낸다', () {
    const analyzer = DifficultyAnalyzer(acceptedStrategyIdsOverride: {'none'});
    final metrics = analyzer.analyzeLevel(0);

    expect(metrics.accidentalSuccessInputs, greaterThan(0));
    expect(
      metrics.accidentalSuccessInputs,
      lessThan(metrics.uniqueSuccessfulInputs),
    );
    expect(
      metrics.accidentalSuccessRate,
      closeTo(metrics.accidentalSuccessInputs / metrics.totalInputs, 0.000001),
    );
  });

  test('3단계 고해상도 분석은 무거움 없이도 성공하는 전략을 집계한다', () {
    const analyzer = DifficultyAnalyzer(angleStepDegrees: 2, powerSteps: 50);
    final metrics = analyzer.analyzeLevel(2);

    expect(metrics.successfulStrategies, contains('무속성'));
    expect(metrics.successfulStrategies, contains('steel (무거움)'));
    final normal = metrics.strategyMetrics.firstWhere(
      (strategy) => strategy.label == '무속성',
    );
    expect(normal.successInputs, greaterThan(0));
    expect(normal.successRate, greaterThan(0));
    expect(normal.widestAngleDegrees, greaterThan(0));
    expect(normal.largestConnectedRegion, greaterThan(0));
    expect(normal.widestAngleDegrees, greaterThanOrEqualTo(2));
    expect(normal.largestConnectedRegion, greaterThanOrEqualTo(19));
  });
}
