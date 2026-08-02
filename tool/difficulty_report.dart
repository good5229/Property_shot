import 'package:property_shot/game/analysis/difficulty_analyzer.dart';

void main() {
  const analyzer = DifficultyAnalyzer();
  for (final metrics in analyzer.analyzeAll()) {
    print('단계: ${metrics.levelName}');
    print('전체 입력: ${metrics.totalInputs}');
    print('성공 입력: ${metrics.successInputs}');
    print('성공률: ${(metrics.successRate * 100).toStringAsFixed(2)}%');
    print('최대 연속 각도: ${metrics.widestAngleDegrees.toStringAsFixed(0)}도');
    print('최대 연속 힘: ${(metrics.widestPowerRange * 100).toStringAsFixed(0)}%');
    print('최대 연결 성공 영역: ${metrics.largestConnectedRegion}셀');
    print('최소 샷: ${metrics.minimumShots ?? '-'}');
    print('성공 전략: ${metrics.successfulStrategies.join(', ')}');
    print('복사 없는 성공: ${metrics.copylessSuccess ? '예' : '아니오'}');
    print('---');
  }
}
