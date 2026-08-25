enum JudgeJourneyReadiness { notStarted, inProgress, ready, needsAttention }

class JudgeJourneyReport {
  const JudgeJourneyReport({
    required this.readiness,
    required this.firstShotMilliseconds,
    required this.coreCompletionMilliseconds,
    required this.totalJourneyMilliseconds,
    required this.invalidLaunchCount,
    required this.completedMilestones,
    required this.issueCodes,
  });

  static const firstShotTargetMilliseconds = 20000;
  static const coreTargetMilliseconds = 60000;
  static const totalTargetMilliseconds = 180000;

  factory JudgeJourneyReport.fromEvents(Iterable<Map<String, Object?>> source) {
    final events = source.toList(growable: false);
    int indexOf(String code, {int start = 0}) {
      for (var index = start; index < events.length; index++) {
        if (events[index]['event_code'] == code) return index;
      }
      return -1;
    }

    int? sessionElapsedAt(int index) {
      if (index < 0 || index >= events.length) return null;
      final raw = events[index]['session_elapsed_ms'];
      if (raw is! num || !raw.isFinite || raw < 0) return null;
      return raw.round();
    }

    int? eventElapsedAt(int index) {
      if (index < 0 || index >= events.length) return null;
      final raw = events[index]['elapsed_ms'];
      if (raw is! num || !raw.isFinite || raw < 0) return null;
      return raw.round();
    }

    final startedIndex = indexOf('judge_journey_started');
    if (startedIndex < 0) {
      return const JudgeJourneyReport(
        readiness: JudgeJourneyReadiness.notStarted,
        firstShotMilliseconds: null,
        coreCompletionMilliseconds: null,
        totalJourneyMilliseconds: null,
        invalidLaunchCount: 0,
        completedMilestones: 0,
        issueCodes: [],
      );
    }

    final firstShotIndex = indexOf('shot_released', start: startedIndex + 1);
    final coreIndex = indexOf(
      'core_experience_completed',
      start: startedIndex + 1,
    );
    final continuedIndex = indexOf(
      'judge_campaign_continued',
      start: coreIndex < 0 ? startedIndex + 1 : coreIndex + 1,
    );
    final clearedIndex = indexOf(
      'judge_first_stage_cleared',
      start: continuedIndex < 0 ? startedIndex + 1 : continuedIndex + 1,
    );
    final discoveryIndex = indexOf(
      'judge_island_discovery_recorded',
      start: clearedIndex < 0 ? startedIndex + 1 : clearedIndex + 1,
    );
    final startElapsed = sessionElapsedAt(startedIndex);
    final firstShotElapsed = sessionElapsedAt(firstShotIndex);
    final discoveryElapsed = sessionElapsedAt(discoveryIndex);
    final firstShotMilliseconds =
        startElapsed == null || firstShotElapsed == null
        ? null
        : firstShotElapsed - startElapsed;
    final totalJourneyMilliseconds =
        startElapsed == null || discoveryElapsed == null
        ? null
        : discoveryElapsed - startElapsed;
    final coreCompletionMilliseconds = eventElapsedAt(coreIndex);
    final completedMilestones = [
      coreIndex,
      continuedIndex,
      clearedIndex,
      discoveryIndex,
    ].where((index) => index >= 0).length;
    final completed = discoveryIndex >= 0;
    final invalidLaunchCount = events
        .skip(startedIndex + 1)
        .take(
          completed
              ? discoveryIndex - startedIndex - 1
              : events.length - startedIndex - 1,
        )
        .where((event) => event['event_code'] == 'invalid_launch_start')
        .length;
    final abandoned = indexOf(
      'core_experience_abandoned',
      start: startedIndex + 1,
    );
    final issues = <String>[];
    if (abandoned >= 0 && !completed) issues.add('core_abandoned');
    if (invalidLaunchCount >= 3) issues.add('repeated_invalid_launch');
    if (firstShotMilliseconds != null &&
        firstShotMilliseconds > firstShotTargetMilliseconds) {
      issues.add('first_shot_late');
    }
    if (coreCompletionMilliseconds != null &&
        coreCompletionMilliseconds > coreTargetMilliseconds) {
      issues.add('core_over_60_seconds');
    }
    if (totalJourneyMilliseconds != null &&
        totalJourneyMilliseconds > totalTargetMilliseconds) {
      issues.add('journey_over_3_minutes');
    }
    if (completed &&
        !(startedIndex < coreIndex &&
            coreIndex < continuedIndex &&
            continuedIndex < clearedIndex &&
            clearedIndex < discoveryIndex)) {
      issues.add('milestone_order_invalid');
    }
    final readiness = issues.isNotEmpty
        ? JudgeJourneyReadiness.needsAttention
        : completed
        ? JudgeJourneyReadiness.ready
        : JudgeJourneyReadiness.inProgress;
    return JudgeJourneyReport(
      readiness: readiness,
      firstShotMilliseconds: firstShotMilliseconds,
      coreCompletionMilliseconds: coreCompletionMilliseconds,
      totalJourneyMilliseconds: totalJourneyMilliseconds,
      invalidLaunchCount: invalidLaunchCount,
      completedMilestones: completedMilestones,
      issueCodes: List.unmodifiable(issues),
    );
  }

  final JudgeJourneyReadiness readiness;
  final int? firstShotMilliseconds;
  final int? coreCompletionMilliseconds;
  final int? totalJourneyMilliseconds;
  final int invalidLaunchCount;
  final int completedMilestones;
  final List<String> issueCodes;

  bool get passed => readiness == JudgeJourneyReadiness.ready;
}
