import '../simulation/shot_resolver.dart';
import '../domain/entity_state.dart';
import 'creative_chain_score.dart';

class StageChainChallengeEvaluator {
  const StageChainChallengeEvaluator();

  bool isAchieved({
    required String patternId,
    required CreativeChainScoreAnalysis analysis,
    required List<ShotResult> results,
  }) {
    final holeShotIndex = analysis.holeShotIndex;
    if (!analysis.clearReached ||
        holeShotIndex == null ||
        holeShotIndex < 0 ||
        holeShotIndex >= results.length) {
      return false;
    }
    final causalEvents = _causalEvents(
      results[holeShotIndex].physicsEvents,
      analysis.causalEventIds,
      holeShotIndex,
    );
    final chainMatched = switch (patternId) {
      'stage_chain_score_01' => matchesOrderedCushionPastBallSequence(
        causalEvents,
      ),
      'stage_chain_score_02' =>
        _hasWallImpact(causalEvents) &&
            _containsEvents(causalEvents, const [
              _ExpectedEvent(
                PhysicsEventKind.impact,
                'chain_score_02_direct_guard',
              ),
              _ExpectedEvent(PhysicsEventKind.impact, 'spent_ball_1'),
            ]),
      'stage_chain_score_03' => _containsEvents(causalEvents, const [
        _ExpectedEvent(PhysicsEventKind.powerSliderActivation, 'speed_slider'),
        _ExpectedEvent(PhysicsEventKind.impact, 'chain_stone'),
        _ExpectedEvent(PhysicsEventKind.impact, 'bounce_wall'),
        _ExpectedEvent(PhysicsEventKind.impact, 'spent_ball_1'),
      ]),
      'stage_chain_score_04' =>
        analysis.breakdown.causalDepth >= 5 &&
            analysis.breakdown.distinctEntityTypes >= 4 &&
            _hasWallImpact(causalEvents) &&
            _containsAllEvents(causalEvents, const [
              _ExpectedEvent(PhysicsEventKind.impact, 'spent_ball_1'),
            ]) &&
            _matchingEventCount(causalEvents, const [
                  _ExpectedEvent(PhysicsEventKind.impact, 'score_balloon'),
                  _ExpectedEvent(
                    PhysicsEventKind.powerSliderActivation,
                    'score_slider',
                  ),
                  _ExpectedEvent(PhysicsEventKind.impact, 'score_jelly'),
                  _ExpectedEvent(PhysicsEventKind.impact, 'score_crate'),
                ]) >=
                2,
      _ => false,
    };
    return chainMatched && _containsHoleCapture(causalEvents);
  }

  List<PhysicsEvent> _causalEvents(
    List<PhysicsEvent> events,
    Set<String> causalEventIds,
    int shotIndex,
  ) {
    final ids = causalEventIds
        .where((id) => id.startsWith('$shotIndex:'))
        .map((id) => id.substring(id.indexOf(':') + 1))
        .toSet();
    return [
      for (final event in events)
        if (ids.contains(event.eventId)) event,
    ];
  }

  bool _containsEvents(
    List<PhysicsEvent> events,
    List<_ExpectedEvent> expected,
  ) {
    var nextIndex = 0;
    for (final event in events) {
      final target = expected[nextIndex];
      if (event.kind != target.kind ||
          event.targetEntityId != target.targetEntityId) {
        continue;
      }
      nextIndex++;
      if (nextIndex == expected.length) return true;
    }
    return false;
  }

  bool _containsHoleCapture(List<PhysicsEvent> events) {
    return events.any(
      (event) =>
          event.targetEntityId == 'hole' ||
          event.visualState == 'hole_captured' ||
          event.visualState == 'captured',
    );
  }

  bool _containsAllEvents(
    List<PhysicsEvent> events,
    List<_ExpectedEvent> expected,
  ) {
    return expected.every(
      (target) => events.any(
        (event) =>
            event.kind == target.kind &&
            event.targetEntityId == target.targetEntityId,
      ),
    );
  }

  int _matchingEventCount(
    List<PhysicsEvent> events,
    List<_ExpectedEvent> expected,
  ) {
    return expected
        .where(
          (target) => events.any(
            (event) =>
                event.kind == target.kind &&
                event.targetEntityId == target.targetEntityId,
          ),
        )
        .length;
  }

  bool _hasWallImpact(List<PhysicsEvent> events) {
    return events.any(
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetType == EntityType.wall,
    );
  }

  bool matchesOrderedCushionPastBallSequence(List<PhysicsEvent> events) {
    final pastBallIndex = events.indexWhere(
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetEntityId == 'spent_ball_1',
    );
    if (pastBallIndex < 0) return false;
    final wallImpacts = <MapEntry<int, PhysicsEvent>>[
      for (var index = 0; index < events.length; index++)
        if (events[index].kind == PhysicsEventKind.impact &&
            events[index].targetType == EntityType.wall)
          MapEntry(index, events[index]),
    ];
    final wallsBefore = wallImpacts.where((entry) => entry.key < pastBallIndex);
    final wallsAfter = wallImpacts.where((entry) => entry.key > pastBallIndex);
    final distinctWalls = wallImpacts
        .map((entry) => entry.value.targetEntityId)
        .toSet();
    return wallsBefore.length >= 2 &&
        wallsAfter.isNotEmpty &&
        distinctWalls.length >= 2;
  }
}

class _ExpectedEvent {
  const _ExpectedEvent(this.kind, this.targetEntityId);

  final PhysicsEventKind kind;
  final String targetEntityId;
}
