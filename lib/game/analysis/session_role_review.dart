import 'dart:convert';

import 'judge_journey.dart';

enum SessionReviewRole {
  noInstructionJudge,
  impatientMobile,
  puzzleExpert,
  accessibility,
}

enum SessionReviewVerdict { clear, observe, blocked }

class SessionReviewFinding {
  const SessionReviewFinding({
    required this.code,
    required this.title,
    required this.evidence,
    required this.recommendation,
  });

  final String code;
  final String title;
  final String evidence;
  final String recommendation;
}

class SessionRoleReview {
  const SessionRoleReview({
    required this.role,
    required this.score,
    required this.verdict,
    required this.findings,
  });

  final SessionReviewRole role;
  final int score;
  final SessionReviewVerdict verdict;
  final List<SessionReviewFinding> findings;

  String get roleLabel => switch (role) {
    SessionReviewRole.noInstructionJudge => '설명을 건너뛰는 심사자',
    SessionReviewRole.impatientMobile => '성급한 모바일 사용자',
    SessionReviewRole.puzzleExpert => '퍼즐 숙련자',
    SessionReviewRole.accessibility => '키보드·접근성 사용자',
  };

  String get verdictLabel => switch (verdict) {
    SessionReviewVerdict.clear => '관찰상 원활',
    SessionReviewVerdict.observe => '추가 관찰 필요',
    SessionReviewVerdict.blocked => '명확한 막힘',
  };
}

class SessionRoleEvaluation {
  const SessionRoleEvaluation({
    required this.eventCount,
    required this.judgeJourney,
    required this.reviews,
  });

  factory SessionRoleEvaluation.fromPrivacySafeJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map ||
        decoded['schema'] != 'property-shot-local-session/v1') {
      throw const FormatException('지원하지 않는 로컬 세션 형식입니다.');
    }
    final rawEvents = decoded['events'];
    if (rawEvents is! List) {
      throw const FormatException('세션 events 배열이 없습니다.');
    }
    final events = rawEvents
        .whereType<Map>()
        .map((event) => Map<String, Object?>.from(event))
        .toList(growable: false);
    return SessionRoleEvaluation.fromEvents(events);
  }

  factory SessionRoleEvaluation.fromEvents(
    Iterable<Map<String, Object?>> source,
  ) {
    final events = source.toList(growable: false);
    final journey = JudgeJourneyReport.fromEvents(events);
    return SessionRoleEvaluation(
      eventCount: events.length,
      judgeJourney: journey,
      reviews: [
        _judgeReview(journey),
        _mobileReview(events),
        _expertReview(events),
        _accessibilityReview(events),
      ],
    );
  }

  final int eventCount;
  final JudgeJourneyReport judgeJourney;
  final List<SessionRoleReview> reviews;

  String toMarkdown() {
    final buffer = StringBuffer()
      ..writeln('# 속성 한방 로컬 세션 역할별 평가')
      ..writeln()
      ..writeln('- 사건 수: $eventCount')
      ..writeln('- 첫 3분 경로: ${_journeyLabel(judgeJourney.readiness)}')
      ..writeln('- 주의: 이 평가는 관찰 가능한 입력·상태 전이만 분석하며 사람의 재미와 감정을 입증하지 않습니다.');
    for (final review in reviews) {
      buffer
        ..writeln()
        ..writeln('## ${review.roleLabel}')
        ..writeln()
        ..writeln('- 판정: ${review.verdictLabel}')
        ..writeln('- 관찰 점수: ${review.score}/100');
      for (final finding in review.findings) {
        buffer
          ..writeln()
          ..writeln('### ${finding.title}')
          ..writeln()
          ..writeln('- 관찰: ${finding.evidence}')
          ..writeln('- 다음 확인: ${finding.recommendation}');
      }
    }
    return buffer.toString().trimRight();
  }

  static SessionRoleReview _judgeReview(JudgeJourneyReport journey) {
    var score = journey.completedMilestones * 20;
    if (journey.firstShotMilliseconds != null &&
        journey.firstShotMilliseconds! <=
            JudgeJourneyReport.firstShotTargetMilliseconds) {
      score += 20;
    }
    score = score.clamp(0, 100).toInt();
    final findings = <SessionReviewFinding>[];
    if (!journey.passed) {
      findings.add(
        SessionReviewFinding(
          code: 'judge_route_incomplete',
          title: '첫 3분 핵심 경로가 아직 입증되지 않음',
          evidence: '네 이정표 중 ${journey.completedMilestones}개가 기록됐습니다.',
          recommendation: '핵심 체험부터 첫 발견까지 같은 세션으로 다시 진행하세요.',
        ),
      );
    }
    if (journey.issueCodes.contains('first_shot_late')) {
      findings.add(
        SessionReviewFinding(
          code: 'first_shot_late',
          title: '첫 조작 진입이 늦음',
          evidence: '첫 발사까지 ${journey.firstShotMilliseconds}밀리초가 걸렸습니다.',
          recommendation: '첫 화면의 핵심 CTA와 첫 장면 목표를 더 직접적으로 확인하세요.',
        ),
      );
    }
    return SessionRoleReview(
      role: SessionReviewRole.noInstructionJudge,
      score: score,
      verdict: journey.passed
          ? SessionReviewVerdict.clear
          : journey.readiness == JudgeJourneyReadiness.needsAttention
          ? SessionReviewVerdict.blocked
          : SessionReviewVerdict.observe,
      findings: List.unmodifiable(findings),
    );
  }

  static SessionRoleReview _mobileReview(List<Map<String, Object?>> events) {
    final invalid = _count(events, 'invalid_launch_start');
    final cancelled = _count(events, 'power_gauge_cancelled');
    final retries = _count(events, 'retry_pressed');
    final abandoned = _count(events, 'stage_abandoned');
    final findings = <SessionReviewFinding>[];
    var score = 100 - invalid * 15 - cancelled * 5 - abandoned * 30;
    if (retries > 4) score -= (retries - 4) * 4;
    if (invalid >= 3) {
      findings.add(
        SessionReviewFinding(
          code: 'repeated_invalid_launch',
          title: '빈 공간에서 발사를 반복 시도함',
          evidence: '유효하지 않은 발사 시작이 $invalid회 기록됐습니다.',
          recommendation: '공의 터치 영역과 첫 입력 안내가 손가락 위치에서 분명한지 확인하세요.',
        ),
      );
    }
    if (retries > 4) {
      findings.add(
        SessionReviewFinding(
          code: 'retry_loop',
          title: '같은 세션에서 재시도가 누적됨',
          evidence: '재시도 버튼을 $retries회 사용했습니다.',
          recommendation: '실패 후 조언이 실제 다음 입력 변화로 이어졌는지 리플레이와 함께 확인하세요.',
        ),
      );
    }
    if (findings.isEmpty) {
      findings.add(
        const SessionReviewFinding(
          code: 'mobile_no_observed_blocker',
          title: '관찰 가능한 반복 막힘 없음',
          evidence: '반복 오입력이나 과도한 재시도 기준을 넘지 않았습니다.',
          recommendation: '실제 터치 기기의 손가락 가림과 진동 체감은 별도로 확인하세요.',
        ),
      );
    }
    return SessionRoleReview(
      role: SessionReviewRole.impatientMobile,
      score: score.clamp(0, 100).toInt(),
      verdict: invalid >= 3 || abandoned > 0
          ? SessionReviewVerdict.blocked
          : retries > 4
          ? SessionReviewVerdict.observe
          : SessionReviewVerdict.clear,
      findings: List.unmodifiable(findings),
    );
  }

  static SessionRoleReview _expertReview(List<Map<String, Object?>> events) {
    const mechanicCodes = {
      'property_transferred',
      'property_copied',
      'switch_activated',
      'door_opened',
      'balloon_popped',
      'ball_stuck',
      'object_started_moving',
      'key_collected',
    };
    final observed = events
        .map((event) => event['event_code']?.toString())
        .whereType<String>()
        .where(mechanicCodes.contains)
        .toSet();
    final cleared = _count(events, 'stage_cleared');
    final score = (30 + observed.length * 10 + cleared * 10)
        .clamp(0, 100)
        .toInt();
    final findings = <SessionReviewFinding>[];
    if (observed.length < 3) {
      findings.add(
        SessionReviewFinding(
          code: 'mechanic_breadth_low',
          title: '세션에서 확인한 기믹 폭이 좁음',
          evidence: '서로 다른 핵심 상호작용 ${observed.length}종이 기록됐습니다.',
          recommendation: '속성 변화와 장면 상태 재사용이 모두 드러나는 경로를 다시 확인하세요.',
        ),
      );
    } else {
      findings.add(
        SessionReviewFinding(
          code: 'mechanic_breadth_observed',
          title: '복수 기믹 상호작용을 확인함',
          evidence: '${observed.length}종의 핵심 상호작용과 $cleared회의 클리어가 기록됐습니다.',
          recommendation: '대체 해법의 발견 가능성은 별도 세션과 비교하세요.',
        ),
      );
    }
    return SessionRoleReview(
      role: SessionReviewRole.puzzleExpert,
      score: score,
      verdict: observed.length < 2
          ? SessionReviewVerdict.blocked
          : observed.length < 3
          ? SessionReviewVerdict.observe
          : SessionReviewVerdict.clear,
      findings: List.unmodifiable(findings),
    );
  }

  static SessionRoleReview _accessibilityReview(
    List<Map<String, Object?>> events,
  ) {
    final precision = _count(events, 'precision_control_adjusted');
    final findings = <SessionReviewFinding>[
      SessionReviewFinding(
        code: precision > 0
            ? 'precision_controls_exercised'
            : 'precision_controls_not_exercised',
        title: precision > 0 ? '대체 정밀 조작을 사용함' : '대체 정밀 조작 증거가 없음',
        evidence: precision > 0
            ? '각도·힘 미세 조정이 $precision회 기록됐습니다.'
            : '이 세션에서는 각도·힘 미세 조정이 기록되지 않았습니다.',
        recommendation: precision > 0
            ? '키보드 포커스 순서와 화면 낭독 결과를 수동으로 함께 확인하세요.'
            : '키보드 또는 미세 조정 버튼 전용 세션을 한 번 더 실행하세요.',
      ),
    ];
    return SessionRoleReview(
      role: SessionReviewRole.accessibility,
      score: precision > 0 ? 80 : 40,
      verdict: precision > 0
          ? SessionReviewVerdict.clear
          : SessionReviewVerdict.observe,
      findings: List.unmodifiable(findings),
    );
  }

  static int _count(List<Map<String, Object?>> events, String code) =>
      events.where((event) => event['event_code']?.toString() == code).length;

  static String _journeyLabel(JudgeJourneyReadiness readiness) =>
      switch (readiness) {
        JudgeJourneyReadiness.notStarted => '미시작',
        JudgeJourneyReadiness.inProgress => '진행 중',
        JudgeJourneyReadiness.ready => '목표 통과',
        JudgeJourneyReadiness.needsAttention => '주의 필요',
      };
}
