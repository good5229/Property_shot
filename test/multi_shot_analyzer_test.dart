import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/difficulty_analyzer.dart';

void main() {
  test('이전 공 상태를 보존한 다중 샷 분석은 성공 순서와 최소 샷을 기록한다', () {
    const analyzer = DifficultyAnalyzer();
    final metrics = analyzer.analyzeLevel(0, includeMultiShot: true);
    final multiShot = metrics.multiShotMetrics!;

    expect(multiShot.totalSequences, greaterThan(0));
    expect(multiShot.successfulSequences, greaterThan(0));
    expect(multiShot.minimumShots, lessThanOrEqualTo(2));
    expect(multiShot.copylessSuccess, isTrue);
    expect(multiShot.dominantStrategy, isNotNull);
    expect(multiShot.dominantStrategyShare, inInclusiveRange(0, 1));
    expect(multiShot.alternativeStrategyCount, greaterThanOrEqualTo(0));
    expect(
      multiShot.strategyMetrics.any((item) => item.label.contains('복제')),
      isTrue,
    );
    expect(multiShot.examples.every((plan) => plan.shots.length <= 2), isTrue);
    expect(
      multiShot.examples.every(
        (plan) => plan.actions.length == plan.shots.length,
      ),
      isTrue,
    );
    expect(
      multiShot.examples.every(
        (plan) => plan.events.length == plan.shots.length,
      ),
      isTrue,
    );

    final thirdStage = analyzer
        .analyzeLevel(2, includeMultiShot: true)
        .multiShotMetrics!;
    final stickyFollowUp = thirdStage.strategyMetrics
        .expand((strategy) => strategy.examples)
        .where((plan) => plan.actions.length == 2)
        .firstWhere(
          (plan) =>
              plan.actions.first.contains('점착') &&
              plan.actions.last.contains('무거움'),
          orElse: () => throw StateError('점착 후 무거움 재선택 경로가 없습니다.'),
        );
    expect(stickyFollowUp.shots, hasLength(2));
    expect(stickyFollowUp.events.first, contains('sticky_attached'));
    expect(stickyFollowUp.events.last, contains('hole_entered'));
  });
}
