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
}
