// 이 파일은 사람이 읽는 난이도 측정 결과를 표준 출력으로 내보내는 도구다.
// ignore_for_file: avoid_print

import 'package:property_shot/game/analysis/difficulty_analyzer.dart';
import 'package:property_shot/game/analysis/multi_shot_analyzer.dart';

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
    print('분석 기반 파 샷: ${metrics.recommendedParShots ?? '-'}');
    print('성공 전략: ${metrics.successfulStrategies.join(', ')}');
    for (final strategy in metrics.strategyMetrics) {
      print(
        '  ${strategy.label}: ${strategy.successInputs}/${strategy.totalInputs} '
        '(${(strategy.successRate * 100).toStringAsFixed(2)}%), '
        '각도 ${strategy.widestAngleDegrees.toStringAsFixed(0)}도, '
        '힘 ${(strategy.widestPowerRange * 100).toStringAsFixed(0)}%, '
        '연결 ${strategy.largestConnectedRegion}셀',
      );
    }
    print('복사 없는 성공: ${metrics.copylessSuccess ? '예' : '아니오'}');
    print('---');
  }
  const multiShotAnalyzer = MultiShotDifficultyAnalyzer(
    angleStepDegrees: 20,
    powerSteps: 5,
    maxShots: 2,
  );
  print('다중 샷 탐색 (각도 20도·힘 20%·최대 2회)');
  for (var levelIndex = 0; levelIndex < 3; levelIndex++) {
    final metrics = multiShotAnalyzer.analyzeLevel(levelIndex);
    print(
      '${metrics.levelName}: ${metrics.successfulSequences}/${metrics.totalSequences} '
      '성공, 최소 샷 ${metrics.minimumShots ?? '-'}, '
      '복사 없는 성공 ${metrics.copylessSuccess ? '예' : '아니오'}',
    );
    for (final strategy in metrics.strategyMetrics.where(
      (item) => item.successfulSequences > 0,
    )) {
      final representative = strategy.examples.isEmpty
          ? '-'
          : strategy.examples.first.actions.join(' → ');
      print(
        '  ${strategy.label}: ${strategy.successfulSequences}회 성공, '
        '최소 ${strategy.minimumShots ?? '-'}샷, '
        '대표 순서 $representative',
      );
    }
  }
  const highResolution = DifficultyAnalyzer(
    angleStepDegrees: 2,
    powerSteps: 50,
  );
  for (var levelIndex = 0; levelIndex < 2; levelIndex++) {
    final metrics = highResolution.analyzeLevel(levelIndex);
    print(
      '${metrics.levelName} 고해상도 폭: '
      '${metrics.widestAngleDegrees.toStringAsFixed(0)}도, '
      '힘 ${(metrics.widestPowerRange * 100).toStringAsFixed(0)}%',
    );
  }
  final thirdStage = highResolution.analyzeLevel(2);
  print('3단계 고해상도 대체 풀이: ${thirdStage.successfulStrategies.join(', ')}');
  for (final strategy in thirdStage.strategyMetrics) {
    print(
      '  ${strategy.label}: ${strategy.successInputs}/${strategy.totalInputs} '
      '(${(strategy.successRate * 100).toStringAsFixed(2)}%), '
      '각도 ${strategy.widestAngleDegrees.toStringAsFixed(0)}도, '
      '힘 ${(strategy.widestPowerRange * 100).toStringAsFixed(0)}%, '
      '연결 ${strategy.largestConnectedRegion}셀',
    );
  }
}
