// 이 파일은 사람이 읽는 난이도 측정 결과를 표준 출력으로 내보내는 도구다.
// ignore_for_file: avoid_print

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
  const highResolution = DifficultyAnalyzer(
    angleStepDegrees: 2,
    powerSteps: 50,
  );
  final thirdStage = highResolution.analyzeLevel(2);
  print('3단계 고해상도 대체 풀이: ${thirdStage.successfulStrategies.join(', ')}');
}
