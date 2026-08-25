import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/session_role_review.dart';

void main() {
  Map<String, Object?> event(String code, int elapsed) => {
    'event_code': code,
    'session_elapsed_ms': elapsed,
  };

  String exported(List<Map<String, Object?>> events) => jsonEncode({
    'schema': 'property-shot-local-session/v1',
    'privacy': {'local_only': true, 'external_link_created': false},
    'events': events,
  });

  test('네 역할은 같은 개인정보 제거 세션을 서로 다른 관점으로 평가한다', () {
    final events = [
      event('judge_journey_started', 1000),
      event('shot_released', 10000),
      {...event('core_experience_completed', 55000), 'elapsed_ms': 54000},
      event('judge_campaign_continued', 56000),
      event('property_transferred', 60000),
      event('switch_activated', 90000),
      event('door_opened', 100000),
      event('precision_control_adjusted', 110000),
      event('stage_cleared', 140000),
      event('judge_first_stage_cleared', 141000),
      event('judge_island_discovery_recorded', 160000),
    ];

    final evaluation = SessionRoleEvaluation.fromPrivacySafeJson(
      exported(events),
    );

    expect(evaluation.eventCount, events.length);
    expect(evaluation.reviews, hasLength(4));
    expect(
      evaluation.reviews.map((review) => review.role).toSet(),
      SessionReviewRole.values.toSet(),
    );
    expect(evaluation.reviews.first.verdict, SessionReviewVerdict.clear);
    expect(
      evaluation.reviews
          .singleWhere(
            (review) => review.role == SessionReviewRole.accessibility,
          )
          .verdict,
      SessionReviewVerdict.clear,
    );
    final markdown = evaluation.toMarkdown();
    expect(markdown, contains('설명을 건너뛰는 심사자'));
    expect(markdown, contains('성급한 모바일 사용자'));
    expect(markdown, contains('사람의 재미와 감정을 입증하지 않습니다'));
    expect(markdown, isNot(contains('session_id')));
  });

  test('반복 오입력과 재시도는 모바일 막힘으로 전면에 나온다', () {
    final events = [
      event('judge_journey_started', 0),
      event('invalid_launch_start', 1000),
      event('invalid_launch_start', 2000),
      event('invalid_launch_start', 3000),
      for (var index = 0; index < 6; index++)
        event('retry_pressed', 4000 + index * 1000),
    ];

    final evaluation = SessionRoleEvaluation.fromEvents(events);
    final mobile = evaluation.reviews.singleWhere(
      (review) => review.role == SessionReviewRole.impatientMobile,
    );

    expect(mobile.verdict, SessionReviewVerdict.blocked);
    expect(mobile.score, lessThan(60));
    expect(
      mobile.findings.map((finding) => finding.code),
      containsAll(['repeated_invalid_launch', 'retry_loop']),
    );
  });

  test('미세 조작을 쓰지 않은 세션은 접근성 실패가 아니라 추가 관찰이다', () {
    final evaluation = SessionRoleEvaluation.fromEvents([
      event('stage_entered', 0),
      event('shot_released', 5000),
    ]);
    final accessibility = evaluation.reviews.singleWhere(
      (review) => review.role == SessionReviewRole.accessibility,
    );

    expect(accessibility.verdict, SessionReviewVerdict.observe);
    expect(
      accessibility.findings.single.code,
      'precision_controls_not_exercised',
    );
  });

  test('알 수 없는 스키마와 events 누락을 보수적으로 거부한다', () {
    expect(
      () => SessionRoleEvaluation.fromPrivacySafeJson('{}'),
      throwsFormatException,
    );
    expect(
      () => SessionRoleEvaluation.fromPrivacySafeJson(
        jsonEncode({'schema': 'property-shot-local-session/v1'}),
      ),
      throwsFormatException,
    );
  });
}
