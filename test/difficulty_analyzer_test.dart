import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/difficulty_analyzer.dart';

void main() {
  test('첫 챕터 자동 분석은 각 단계의 성공 영역과 최소 샷을 산출한다', () {
    const analyzer = DifficultyAnalyzer();
    final metrics = analyzer.analyzeAll();

    expect(metrics, hasLength(3));
    for (final result in metrics) {
      expect(result.totalInputs, greaterThan(0));
      expect(result.successInputs, greaterThan(0));
      expect(result.successRate, greaterThan(0));
      expect(result.widestAngleDegrees, greaterThan(0));
      expect(result.widestPowerRange, greaterThan(0));
      expect(result.largestConnectedRegion, greaterThanOrEqualTo(1));
      expect(result.minimumShots, 1);
      expect(result.successfulStrategies, isNotEmpty);
    }
  });

  test('현재 첫 챕터는 복사 없이 성공 입력을 포함한다', () {
    const analyzer = DifficultyAnalyzer();
    final metrics = analyzer.analyzeAll();

    expect(metrics.every((result) => result.copylessSuccess), isTrue);
  });

  test('3단계 고해상도 분석은 무거움 없이도 성공하는 전략을 집계한다', () {
    const analyzer = DifficultyAnalyzer(angleStepDegrees: 2, powerSteps: 50);
    final metrics = analyzer.analyzeLevel(2);

    expect(metrics.successfulStrategies, contains('무속성'));
    expect(metrics.successfulStrategies, contains('steel (무거움)'));
  });
}
