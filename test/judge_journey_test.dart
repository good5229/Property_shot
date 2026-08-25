import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/judge_journey.dart';

void main() {
  Map<String, Object?> event(
    String code,
    int sessionMilliseconds, {
    int? elapsedMilliseconds,
  }) {
    final value = <String, Object?>{
      'event_code': code,
      'session_elapsed_ms': sessionMilliseconds,
    };
    if (elapsedMilliseconds != null) {
      value['elapsed_ms'] = elapsedMilliseconds;
    }
    return value;
  }

  test('심사 경로를 시작하지 않은 세션은 평가 대상이 아니다', () {
    final report = JudgeJourneyReport.fromEvents([
      event('stage_entered', 1000),
    ]);

    expect(report.readiness, JudgeJourneyReadiness.notStarted);
    expect(report.completedMilestones, 0);
    expect(report.issueCodes, isEmpty);
  });

  test('3분 안에 순서대로 완료한 경로는 준비 완료다', () {
    final report = JudgeJourneyReport.fromEvents([
      event('judge_journey_started', 1000),
      event('shot_released', 12500),
      event('core_experience_completed', 58000, elapsedMilliseconds: 57000),
      event('judge_campaign_continued', 60000),
      event('judge_first_stage_cleared', 150000),
      event('judge_island_discovery_recorded', 175000),
    ]);

    expect(report.readiness, JudgeJourneyReadiness.ready);
    expect(report.passed, isTrue);
    expect(report.firstShotMilliseconds, 11500);
    expect(report.coreCompletionMilliseconds, 57000);
    expect(report.totalJourneyMilliseconds, 174000);
    expect(report.completedMilestones, 4);
  });

  test('느린 첫 입력·핵심 체험·전체 경로와 반복 오입력을 함께 찾는다', () {
    final report = JudgeJourneyReport.fromEvents([
      event('judge_journey_started', 1000),
      event('invalid_launch_start', 5000),
      event('invalid_launch_start', 7000),
      event('invalid_launch_start', 9000),
      event('shot_released', 25000),
      event('core_experience_completed', 70000, elapsedMilliseconds: 69000),
      event('judge_campaign_continued', 71000),
      event('judge_first_stage_cleared', 170000),
      event('judge_island_discovery_recorded', 190500),
    ]);

    expect(report.readiness, JudgeJourneyReadiness.needsAttention);
    expect(
      report.issueCodes,
      containsAll([
        'repeated_invalid_launch',
        'first_shot_late',
        'core_over_60_seconds',
        'journey_over_3_minutes',
      ]),
    );
  });

  test('중도 이탈은 완료로 가장하지 않는다', () {
    final report = JudgeJourneyReport.fromEvents([
      event('judge_journey_started', 1000),
      event('core_experience_abandoned', 15000, elapsedMilliseconds: 14000),
    ]);

    expect(report.readiness, JudgeJourneyReadiness.needsAttention);
    expect(report.issueCodes, contains('core_abandoned'));
    expect(report.completedMilestones, 0);
  });

  test('손상된 시간 값은 예외 없이 미측정으로 남긴다', () {
    final report = JudgeJourneyReport.fromEvents([
      {'event_code': 'judge_journey_started', 'session_elapsed_ms': -1},
      {'event_code': 'shot_released', 'session_elapsed_ms': 'fast'},
      {'event_code': 'core_experience_completed', 'elapsed_ms': double.nan},
    ]);

    expect(report.readiness, JudgeJourneyReadiness.inProgress);
    expect(report.firstShotMilliseconds, isNull);
    expect(report.coreCompletionMilliseconds, isNull);
  });
}
