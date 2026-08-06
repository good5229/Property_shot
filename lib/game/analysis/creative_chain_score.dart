import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../simulation/shot_resolver.dart';
import 'replay_fixture.dart';
import 'replay_signature.dart';

/// 창의 연쇄 점수에 사용되는 선택 도전의 안정적인 식별자다.
abstract final class CreativeChainChallengeId {
  static const wallReflection = 'wall_reflection';
  static const pastBall = 'past_ball';
  static const traitReaction = 'trait_reaction';
  static const powerSlider = 'power_slider';
  static const boardState = 'board_state';
  static const preparationShot = 'preparation_shot';
  static const diverseChain = 'diverse_chain';

  static const all = <String>{
    wallReflection,
    pastBall,
    traitReaction,
    powerSlider,
    boardState,
    preparationShot,
    diverseChain,
  };
}

enum CreativeChainEvidenceKind {
  clearBase,
  causalDepth,
  entityType,
  entity,
  wallReflection,
  pastBall,
  traitActivation,
  traitConsumption,
  powerSlider,
  boardState,
  movedEntity,
  preparationShot,
  minimumShot,
  optionalChallenge,
  unrelatedImpact,
}

/// 분석기가 산출한 하나의 점수 근거다.
class CreativeChainEvidence {
  const CreativeChainEvidence({
    required this.kind,
    required this.label,
    required this.points,
    this.shotIndex,
    this.eventId,
    this.entityId,
  });

  final CreativeChainEvidenceKind kind;
  final String label;
  final int points;
  final int? shotIndex;
  final String? eventId;
  final String? entityId;
}

/// 준비 발사가 최종 홀 진입에 기여한 방식이다.
class CreativeChainPreparationContribution {
  const CreativeChainPreparationContribution({
    required this.shotIndex,
    required this.entityIds,
    required this.evidenceLabels,
    required this.points,
  });

  final int shotIndex;
  final Set<String> entityIds;
  final List<String> evidenceLabels;
  final int points;
}

/// 점수의 각 구성요소를 별도 값으로 보존한다.
///
/// `totalScore`만 저장하지 않고 구성요소를 함께 저장해야 리플레이·QA에서
/// 점수 상승이 어떤 인과 근거에서 발생했는지 설명할 수 있다.
class CreativeChainScoreBreakdown {
  const CreativeChainScoreBreakdown({
    required this.clearBasePoints,
    required this.causalDepth,
    required this.causalEventCount,
    required this.causalDepthPoints,
    required this.distinctEntityTypes,
    required this.distinctEntityTypePoints,
    required this.distinctEntityIds,
    required this.distinctEntityPoints,
    required this.wallReflectionCount,
    required this.wallReflectionPoints,
    required this.pastBallCount,
    required this.pastBallPoints,
    required this.traitActivationCount,
    required this.traitActivationPoints,
    required this.traitConsumptionCount,
    required this.traitConsumptionPoints,
    required this.powerSliderCount,
    required this.powerSliderPoints,
    required this.boardStateChangeCount,
    required this.boardStateChangePoints,
    required this.movedEntityCount,
    required this.movedEntityPoints,
    required this.preparationShotCount,
    required this.preparationEvidenceCount,
    required this.preparationPoints,
    required this.minimumShotBonus,
    required this.optionalChallengeCount,
    required this.optionalChallengePoints,
    required this.unrelatedImpactCount,
    required this.unrelatedImpactPoints,
    required this.qualifiedImpactCount,
    required this.dampedImpactCount,
    required this.ignoredImpactCount,
    required this.cappedImpactCount,
  });

  final int clearBasePoints;
  final int causalDepth;
  final int causalEventCount;
  final int causalDepthPoints;
  final int distinctEntityTypes;
  final int distinctEntityTypePoints;
  final int distinctEntityIds;
  final int distinctEntityPoints;
  final int wallReflectionCount;
  final int wallReflectionPoints;
  final int pastBallCount;
  final int pastBallPoints;
  final int traitActivationCount;
  final int traitActivationPoints;
  final int traitConsumptionCount;
  final int traitConsumptionPoints;
  final int powerSliderCount;
  final int powerSliderPoints;
  final int boardStateChangeCount;
  final int boardStateChangePoints;
  final int movedEntityCount;
  final int movedEntityPoints;
  final int preparationShotCount;
  final int preparationEvidenceCount;
  final int preparationPoints;
  final int minimumShotBonus;
  final int optionalChallengeCount;
  final int optionalChallengePoints;
  final int unrelatedImpactCount;
  final int unrelatedImpactPoints;
  final int qualifiedImpactCount;
  final int dampedImpactCount;
  final int ignoredImpactCount;
  final int cappedImpactCount;

  int get totalPoints =>
      clearBasePoints +
      causalDepthPoints +
      distinctEntityTypePoints +
      distinctEntityPoints +
      wallReflectionPoints +
      pastBallPoints +
      traitActivationPoints +
      traitConsumptionPoints +
      powerSliderPoints +
      boardStateChangePoints +
      movedEntityPoints +
      preparationPoints +
      minimumShotBonus +
      optionalChallengePoints +
      unrelatedImpactPoints;
}

/// `CreativeChainScoreAnalyzer`의 전체 결과다.
class CreativeChainScoreAnalysis {
  const CreativeChainScoreAnalysis({
    required this.clearReached,
    required this.holeShotIndex,
    required this.causalEventIds,
    required this.completedOptionalChallengeIds,
    required this.preparationContributions,
    required this.breakdown,
    required this.evidence,
    required this.replayMatchesFixture,
    required this.replaySignature,
  });

  final bool clearReached;
  final int? holeShotIndex;
  final Set<String> causalEventIds;
  final Set<String> completedOptionalChallengeIds;
  final List<CreativeChainPreparationContribution> preparationContributions;
  final CreativeChainScoreBreakdown breakdown;
  final List<CreativeChainEvidence> evidence;

  /// 저장된 `ReplayFixture.expectedFingerprints`와 결과가 일치하는지다.
  /// 빈 기대값은 아직 기록되지 않은 분석용 fixture로 허용한다.
  final bool replayMatchesFixture;
  final String replaySignature;

  int get totalScore => breakdown.totalPoints;
}

/// 물리 판정과 클리어 조건을 변경하지 않고, 확정된 물리 사건만 분석한다.
///
/// 점수는 한 샷의 충돌 횟수 합이 아니다. 최종 홀 사건의 인과 경로를
/// 우선 분석하고, 반복 접촉·미세 진동·무관 충돌은 별도의 제한을 거친다.
class CreativeChainScoreAnalyzer {
  const CreativeChainScoreAnalyzer({
    this.maxCausalImpacts = 12,
    this.maxUnrelatedImpacts = 3,
    this.repeatWindowPathIndices = 12,
    this.microVibrationSpeed = 0.35,
    this.microVibrationImpulse = 0.1,
  }) : assert(maxCausalImpacts >= 0),
       assert(maxUnrelatedImpacts >= 0),
       assert(repeatWindowPathIndices >= 0),
       assert(microVibrationSpeed >= 0),
       assert(microVibrationImpulse >= 0);

  static const scoreVersion = 'creative-chain-score-v1';

  final int maxCausalImpacts;
  final int maxUnrelatedImpacts;
  final int repeatWindowPathIndices;
  final double microVibrationSpeed;
  final double microVibrationImpulse;

  /// 여러 `ShotResult`를 최종 클리어 관점에서 분석한다.
  CreativeChainScoreAnalysis analyze(
    List<ShotResult> results, {
    required int parShots,
    Set<String> optionalChallengeIds = const {},
    String replayContext = '',
  }) {
    if (parShots < 1) {
      throw ArgumentError.value(parShots, 'parShots', '1 이상이어야 합니다.');
    }
    final normalizedChallenges = optionalChallengeIds.intersection(
      CreativeChainChallengeId.all,
    );
    final eventsByShot = [for (final result in results) _eventsFor(result)];
    final holeShotIndex = _findHoleShot(results, eventsByShot);
    final clearReached = holeShotIndex != null;

    if (!clearReached) {
      final breakdown = _emptyBreakdown(parShots: parShots);
      return CreativeChainScoreAnalysis(
        clearReached: false,
        holeShotIndex: null,
        causalEventIds: const {},
        completedOptionalChallengeIds: const {},
        preparationContributions: const [],
        breakdown: breakdown,
        evidence: const [],
        replayMatchesFixture: true,
        replaySignature: _signature(
          replayContext: replayContext,
          results: results,
          breakdown: breakdown,
          holeShotIndex: null,
        ),
      );
    }

    final finalEvents = eventsByShot[holeShotIndex];
    final holeEvent = _holeEvent(finalEvents)!;
    final chain = _causalChain(finalEvents, holeEvent);
    final causalEventIds = {
      for (final event in chain) '$holeShotIndex:${event.eventId}',
    };
    final causalEvents = chain
        .where((event) => event.kind != PhysicsEventKind.move)
        .toList(growable: false);
    final causalImpacts = causalEvents
        .where(
          (event) =>
              event.kind == PhysicsEventKind.impact &&
              event.targetType != EntityType.hole,
        )
        .toList(growable: false);
    final impactScoring = _scoreImpacts(causalImpacts);
    final scoringEvents = impactScoring.scoredImpacts;

    final causalEntityEvents = <PhysicsEvent>[
      ...scoringEvents,
      ...causalEvents.where(
        (event) =>
            event.kind != PhysicsEventKind.impact &&
            event.targetType != EntityType.hole,
      ),
    ];
    final entityTypes = {
      for (final event in causalEntityEvents)
        if (event.targetType != EntityType.hole) event.targetType,
    };
    final entityIds = {
      for (final event in causalEntityEvents)
        if (event.targetType != EntityType.hole) event.targetEntityId,
    };
    final wallEvents = scoringEvents
        .where((event) => event.targetType == EntityType.wall)
        .toList(growable: false);
    final pastBallEvents = _uniqueEvents(
      scoringEvents.where(
        (event) => _isPastBall(event.targetEntityId, event.targetType),
      ),
      (event) => event.targetEntityId,
    );
    final traitActivationEvents = _uniqueEvents(<PhysicsEvent>[
      ...scoringEvents.where((event) => event.sourceTraits.isNotEmpty),
      ...causalEvents.where(_isTraitActivation),
    ], _traitActivationKey);
    final traitConsumptionEvents = _uniqueEvents(
      causalEvents.where(_isTraitConsumption),
      (event) => event.targetEntityId,
    );
    final sliderEvents = _uniqueEvents(
      causalEvents.where(
        (event) => event.kind == PhysicsEventKind.powerSliderActivation,
      ),
      (event) => event.targetEntityId,
    );
    final boardStateEvents = _uniqueEvents(
      causalEvents.where(_isBoardStateChange),
      (event) => event.targetEntityId,
    );
    final movedEntityIds = _movedEntityIds(finalEvents, causalEvents);
    final preparation = _preparationContributions(
      results,
      eventsByShot,
      finalShotIndex: holeShotIndex,
      causalEntityIds: {for (final event in causalEvents) event.targetEntityId},
    );
    final detectedChallenges = _detectedChallenges(
      wallReflectionCount: wallEvents.length,
      pastBallCount: pastBallEvents.length,
      traitCount: traitActivationEvents.length + traitConsumptionEvents.length,
      sliderCount: sliderEvents.length,
      boardStateChangeCount: boardStateEvents.length,
      preparationShotCount: preparation.length,
      distinctEntityTypes: entityTypes.length,
    );
    final completedChallenges = detectedChallenges.intersection(
      normalizedChallenges,
    );
    final minimumShotBonus = _minimumShotBonus(
      parShots: parShots,
      shotsUsed: holeShotIndex + 1,
    );
    final optionalChallengePoints = completedChallenges.length * 40;
    final unrelated = _unrelatedImpacts(
      eventsByShot,
      finalShotIndex: holeShotIndex,
      causalEventIds: causalEventIds,
    );

    final causalDepth = _causalDepth(causalEvents, impactScoring);
    final depthPoints = _cap(causalDepth, 8) * 45;
    final typePoints = _diversityPoints(entityTypes.length);
    final entityPoints = _cap(entityIds.length, 8) * 22;
    final wallPoints = _wallPoints(wallEvents, impactScoring.factors);
    final pastBallPoints = _cap(pastBallEvents.length, 3) * 55;
    final traitActivationPoints = _cap(traitActivationEvents.length, 3) * 45;
    final traitConsumptionPoints = _cap(traitConsumptionEvents.length, 3) * 65;
    final sliderPoints = _cap(sliderEvents.length, 3) * 50;
    final boardStatePoints = _cap(boardStateEvents.length, 5) * 35;
    final movedPoints = _cap(movedEntityIds.length, 5) * 30;
    final preparationEvidenceCount = preparation.fold<int>(
      0,
      (total, item) => total + item.evidenceLabels.length,
    );
    final preparationPoints = _cap(
      preparation.fold<int>(0, (total, item) => total + item.points),
      150,
    );
    final breakdown = CreativeChainScoreBreakdown(
      clearBasePoints: 1000,
      causalDepth: causalDepth,
      causalEventCount: causalEvents.length,
      causalDepthPoints: depthPoints,
      distinctEntityTypes: entityTypes.length,
      distinctEntityTypePoints: typePoints,
      distinctEntityIds: entityIds.length,
      distinctEntityPoints: entityPoints,
      wallReflectionCount: wallEvents.length,
      wallReflectionPoints: wallPoints,
      pastBallCount: pastBallEvents.length,
      pastBallPoints: pastBallPoints,
      traitActivationCount: traitActivationEvents.length,
      traitActivationPoints: traitActivationPoints,
      traitConsumptionCount: traitConsumptionEvents.length,
      traitConsumptionPoints: traitConsumptionPoints,
      powerSliderCount: sliderEvents.length,
      powerSliderPoints: sliderPoints,
      boardStateChangeCount: boardStateEvents.length,
      boardStateChangePoints: boardStatePoints,
      movedEntityCount: movedEntityIds.length,
      movedEntityPoints: movedPoints,
      preparationShotCount: preparation.length,
      preparationEvidenceCount: preparationEvidenceCount,
      preparationPoints: preparationPoints,
      minimumShotBonus: minimumShotBonus,
      optionalChallengeCount: completedChallenges.length,
      optionalChallengePoints: optionalChallengePoints,
      unrelatedImpactCount: unrelated.count,
      unrelatedImpactPoints: unrelated.points,
      qualifiedImpactCount: scoringEvents.length,
      dampedImpactCount: impactScoring.dampedCount,
      ignoredImpactCount: impactScoring.ignoredCount,
      cappedImpactCount: impactScoring.cappedCount,
    );

    final evidence = _evidence(
      holeShotIndex: holeShotIndex,
      breakdown: breakdown,
      completedChallenges: completedChallenges,
    );
    return CreativeChainScoreAnalysis(
      clearReached: true,
      holeShotIndex: holeShotIndex,
      causalEventIds: Set.unmodifiable(causalEventIds),
      completedOptionalChallengeIds: Set.unmodifiable(completedChallenges),
      preparationContributions: preparation,
      breakdown: breakdown,
      evidence: evidence,
      replayMatchesFixture: true,
      replaySignature: _signature(
        replayContext: replayContext,
        results: results,
        breakdown: breakdown,
        holeShotIndex: holeShotIndex,
      ),
    );
  }

  /// 저장된 fixture와 이미 재생한 결과를 함께 분석한다.
  ///
  /// 물리 재생은 호출자가 기존 `ShotResolver`로 수행한다. 이 메서드는
  /// fixture의 입력·기대 fingerprint와 결과의 점수 서명을 결합해 저장
  /// replay가 같은 분석 결과를 만드는지 확인한다.
  CreativeChainScoreAnalysis analyzeReplay(
    ReplayFixture fixture,
    List<ShotResult> results, {
    required int parShots,
    Set<String> optionalChallengeIds = const {},
  }) {
    if (fixture.shots.length != results.length) {
      throw ArgumentError.value(
        results.length,
        'results',
        'ReplayFixture의 발사 수와 결과 수가 다릅니다.',
      );
    }
    final base = analyze(
      results,
      parShots: parShots,
      optionalChallengeIds: optionalChallengeIds,
      replayContext: _fixtureContext(fixture),
    );
    final replayFingerprints = [
      for (final result in results) shotResultFingerprint(result),
    ];
    final fingerprintsMatch =
        fixture.expectedFingerprints.isEmpty ||
        fixture.expectedFingerprints.length == replayFingerprints.length &&
            List.generate(replayFingerprints.length, (index) => index).every(
              (index) =>
                  replayFingerprints[index] ==
                  fixture.expectedFingerprints[index],
            );
    return CreativeChainScoreAnalysis(
      clearReached: base.clearReached,
      holeShotIndex: base.holeShotIndex,
      causalEventIds: base.causalEventIds,
      completedOptionalChallengeIds: base.completedOptionalChallengeIds,
      preparationContributions: base.preparationContributions,
      breakdown: base.breakdown,
      evidence: base.evidence,
      replayMatchesFixture: fingerprintsMatch,
      replaySignature: _signature(
        replayContext:
            '${_fixtureContext(fixture)};fixtureMatch=$fingerprintsMatch',
        results: results,
        breakdown: base.breakdown,
        holeShotIndex: base.holeShotIndex,
      ),
    );
  }

  List<PhysicsEvent> _eventsFor(ShotResult result) {
    if (result.physicsEvents.isNotEmpty) {
      return List<PhysicsEvent>.unmodifiable(result.physicsEvents);
    }
    return buildPhysicsEvents(
      path: result.path,
      impacts: result.impacts,
      moves: result.moves,
      chainSafetyDiagnostics: result.chainSafetyDiagnostics,
      powerSliderActivations: result.powerSliderActivations,
      reflectorRotations: result.reflectorRotations,
    );
  }

  int? _findHoleShot(
    List<ShotResult> results,
    List<List<PhysicsEvent>> eventsByShot,
  ) {
    for (var shotIndex = eventsByShot.length - 1; shotIndex >= 0; shotIndex--) {
      if (results[shotIndex].state.phase == GamePhase.success &&
          _holeEvent(eventsByShot[shotIndex]) != null) {
        return shotIndex;
      }
    }
    return null;
  }

  PhysicsEvent? _holeEvent(List<PhysicsEvent> events) {
    for (final event in events) {
      if (event.targetType == EntityType.hole ||
          event.visualState == 'hole_captured' ||
          event.visualState == 'captured') {
        return event;
      }
    }
    return null;
  }

  List<PhysicsEvent> _causalChain(
    List<PhysicsEvent> events,
    PhysicsEvent holeEvent,
  ) {
    final byId = {for (final event in events) event.eventId: event};
    final chain = <PhysicsEvent>[];
    final visited = <String>{};
    PhysicsEvent? current = holeEvent;
    while (current != null && visited.add(current.eventId)) {
      chain.add(current);
      final parent = current.parentEventId == null
          ? null
          : byId[current.parentEventId!];
      current = parent ?? _fallbackParent(events, current);
      if (current == null) {
        break;
      }
    }
    return chain.reversed.toList(growable: false);
  }

  PhysicsEvent? _fallbackParent(List<PhysicsEvent> events, PhysicsEvent child) {
    PhysicsEvent? candidate;
    for (final event in events) {
      if (event.eventId == child.eventId || !_isCausalEvent(event)) {
        continue;
      }
      if (event.pathIndex > child.pathIndex) {
        continue;
      }
      if (event.pathIndex == child.pathIndex &&
          event.kind.index >= child.kind.index) {
        continue;
      }
      if (event.sourceEntityId == child.sourceEntityId ||
          event.targetEntityId == child.sourceEntityId) {
        if (candidate == null ||
            event.pathIndex > candidate.pathIndex ||
            event.pathIndex == candidate.pathIndex &&
                event.eventId.compareTo(candidate.eventId) > 0) {
          candidate = event;
        }
      }
    }
    return candidate;
  }

  _ImpactScoring _scoreImpacts(List<PhysicsEvent> impacts) {
    final factors = <PhysicsEvent, double>{};
    final scored = <PhysicsEvent>[];
    final lastByContact = <String, PhysicsEvent>{};
    var dampedCount = 0;
    var ignoredCount = 0;
    var cappedCount = 0;
    final impactLimit = _cap(maxCausalImpacts, 12);
    for (final impact in impacts) {
      if (!_isMeaningfulImpact(impact)) {
        ignoredCount++;
        continue;
      }
      if (scored.length >= impactLimit) {
        cappedCount++;
        continue;
      }
      final key = _contactKey(impact);
      var factor = 1.0;
      final previous = lastByContact[key];
      if (previous != null &&
          impact.pathIndex - previous.pathIndex <= repeatWindowPathIndices) {
        factor = 0.25;
      }
      if (impact.targetType == EntityType.wall) {
        final wallKey = '${impact.targetEntityId}:${_wallFace(impact.normal)}';
        final previousWall = lastByContact[wallKey];
        if (previousWall != null &&
            impact.pathIndex - previousWall.pathIndex <=
                repeatWindowPathIndices * 2) {
          factor = factor < 0.2 ? factor : 0.2;
        }
        lastByContact[wallKey] = impact;
      }
      if (factor < 1) {
        dampedCount++;
      }
      factors[impact] = factor;
      scored.add(impact);
      lastByContact[key] = impact;
    }
    return _ImpactScoring(
      scoredImpacts: scored,
      factors: factors,
      dampedCount: dampedCount,
      ignoredCount: ignoredCount,
      cappedCount: cappedCount,
    );
  }

  List<String> _movedEntityIds(
    List<PhysicsEvent> finalEvents,
    List<PhysicsEvent> causalEvents,
  ) {
    final causalTargets = {
      for (final event in causalEvents) event.targetEntityId,
    };
    final moved = <String>{};
    for (final event in finalEvents) {
      if (event.kind != PhysicsEventKind.move || event.move == null) {
        continue;
      }
      if (causalTargets.contains(event.targetEntityId) &&
          event.move!.from != event.move!.to &&
          event.move!.path.isNotEmpty) {
        moved.add(event.targetEntityId);
      }
    }
    return moved.toList(growable: false);
  }

  List<CreativeChainPreparationContribution> _preparationContributions(
    List<ShotResult> results,
    List<List<PhysicsEvent>> eventsByShot, {
    required int finalShotIndex,
    required Set<String> causalEntityIds,
  }) {
    final contributions = <CreativeChainPreparationContribution>[];
    if (finalShotIndex == 0) {
      return const [];
    }
    final stateBeforeFinalShot = results[finalShotIndex - 1].state;
    final lastMutationShotByEntity = <String, int>{};
    for (var shotIndex = 0; shotIndex < finalShotIndex; shotIndex++) {
      for (final event in eventsByShot[shotIndex]) {
        if (event.kind == PhysicsEventKind.stateChange ||
            event.kind == PhysicsEventKind.move) {
          lastMutationShotByEntity[event.targetEntityId] = shotIndex;
        }
      }
    }
    for (var shotIndex = 0; shotIndex < finalShotIndex; shotIndex++) {
      final events = eventsByShot[shotIndex];
      final stateAfterShot = results[shotIndex].state;
      final entityIds = <String>{};
      final labels = <String>[];
      final previousEntityIds = shotIndex == 0
          ? const <String>{}
          : results[shotIndex - 1].state.entities
                .map((entity) => entity.id)
                .toSet();
      for (final entity in stateAfterShot.entities) {
        if (entity.id.startsWith('spent_ball_') &&
            entity.id == 'spent_ball_${stateAfterShot.shotCount}' &&
            !previousEntityIds.contains(entity.id) &&
            causalEntityIds.contains(entity.id) &&
            stateBeforeFinalShot.entityById(entity.id) != null) {
          entityIds.add(entity.id);
          labels.add('${entity.id} 생성');
        }
      }
      final stateChanges = events.where(
        (event) =>
            event.kind == PhysicsEventKind.stateChange &&
            event.targetEntityId != 'active_ball',
      );
      for (final event in stateChanges) {
        if (lastMutationShotByEntity[event.targetEntityId] != shotIndex) {
          continue;
        }
        final after = stateAfterShot.entityById(event.targetEntityId);
        final persisted = stateBeforeFinalShot.entityById(event.targetEntityId);
        if (causalEntityIds.contains(event.targetEntityId) &&
            after != null &&
            persisted != null &&
            _reflectsState(after, event.visualState) &&
            _reflectsState(persisted, event.visualState)) {
          entityIds.add(event.targetEntityId);
          labels.add('${event.targetEntityId} 상태 변경');
        }
      }
      final moved = events.where(
        (event) =>
            event.kind == PhysicsEventKind.move &&
            causalEntityIds.contains(event.targetEntityId),
      );
      for (final event in moved) {
        if (lastMutationShotByEntity[event.targetEntityId] != shotIndex) {
          continue;
        }
        final after = stateAfterShot.entityById(event.targetEntityId);
        final persisted = stateBeforeFinalShot.entityById(event.targetEntityId);
        final destination = event.move?.to;
        if (after != null &&
            persisted != null &&
            destination != null &&
            after.position.distanceTo(destination) <= 0.01 &&
            persisted.position.distanceTo(after.position) <= 0.01) {
          entityIds.add(event.targetEntityId);
          labels.add('${event.targetEntityId} 이동');
        }
      }
      if (entityIds.isEmpty && labels.isEmpty) {
        continue;
      }
      final evidenceLabels = labels.toSet();
      final points = _cap(
        entityIds.length * 20 + evidenceLabels.length * 10 + 25,
        80,
      );
      contributions.add(
        CreativeChainPreparationContribution(
          shotIndex: shotIndex,
          entityIds: Set.unmodifiable(entityIds),
          evidenceLabels: List.unmodifiable(evidenceLabels),
          points: points,
        ),
      );
    }
    return List.unmodifiable(contributions);
  }

  _UnrelatedImpacts _unrelatedImpacts(
    List<List<PhysicsEvent>> eventsByShot, {
    required int finalShotIndex,
    required Set<String> causalEventIds,
  }) {
    var count = 0;
    for (var shotIndex = 0; shotIndex <= finalShotIndex; shotIndex++) {
      for (final event in eventsByShot[shotIndex]) {
        if (event.kind != PhysicsEventKind.impact ||
            event.targetType == EntityType.hole ||
            causalEventIds.contains('$shotIndex:${event.eventId}') ||
            !_isMeaningfulImpact(event)) {
          continue;
        }
        count++;
      }
    }
    final capped = _cap(count, _cap(maxUnrelatedImpacts, 3));
    return _UnrelatedImpacts(count: count, points: capped * 4);
  }

  Set<String> _detectedChallenges({
    required int wallReflectionCount,
    required int pastBallCount,
    required int traitCount,
    required int sliderCount,
    required int boardStateChangeCount,
    required int preparationShotCount,
    required int distinctEntityTypes,
  }) {
    return {
      if (wallReflectionCount > 0) CreativeChainChallengeId.wallReflection,
      if (pastBallCount > 0) CreativeChainChallengeId.pastBall,
      if (traitCount > 0) CreativeChainChallengeId.traitReaction,
      if (sliderCount > 0) CreativeChainChallengeId.powerSlider,
      if (boardStateChangeCount > 0) CreativeChainChallengeId.boardState,
      if (preparationShotCount > 0) CreativeChainChallengeId.preparationShot,
      if (distinctEntityTypes >= 3) CreativeChainChallengeId.diverseChain,
    };
  }

  List<CreativeChainEvidence> _evidence({
    required int holeShotIndex,
    required CreativeChainScoreBreakdown breakdown,
    required Set<String> completedChallenges,
  }) {
    final evidence = <CreativeChainEvidence>[];
    void add(CreativeChainEvidenceKind kind, String label, int points) {
      if (points <= 0) return;
      evidence.add(
        CreativeChainEvidence(
          kind: kind,
          label: label,
          points: points,
          shotIndex: holeShotIndex,
        ),
      );
    }

    add(CreativeChainEvidenceKind.clearBase, '홀 진입', breakdown.clearBasePoints);
    add(
      CreativeChainEvidenceKind.causalDepth,
      '홀 진입 인과 깊이 ${breakdown.causalDepth}',
      breakdown.causalDepthPoints,
    );
    add(
      CreativeChainEvidenceKind.entityType,
      '서로 다른 기물 타입 ${breakdown.distinctEntityTypes}종',
      breakdown.distinctEntityTypePoints,
    );
    add(
      CreativeChainEvidenceKind.entity,
      '서로 다른 기물 ${breakdown.distinctEntityIds}개',
      breakdown.distinctEntityPoints,
    );
    add(
      CreativeChainEvidenceKind.wallReflection,
      '벽 반사 ${breakdown.wallReflectionCount}회',
      breakdown.wallReflectionPoints,
    );
    add(
      CreativeChainEvidenceKind.pastBall,
      '과거 공 ${breakdown.pastBallCount}개 활용',
      breakdown.pastBallPoints,
    );
    add(
      CreativeChainEvidenceKind.traitActivation,
      '속성 ${breakdown.traitActivationCount}종 발동',
      breakdown.traitActivationPoints,
    );
    add(
      CreativeChainEvidenceKind.traitConsumption,
      '속성 ${breakdown.traitConsumptionCount}회 소모',
      breakdown.traitConsumptionPoints,
    );
    add(
      CreativeChainEvidenceKind.powerSlider,
      '파워 슬라이더 ${breakdown.powerSliderCount}개 작동',
      breakdown.powerSliderPoints,
    );
    add(
      CreativeChainEvidenceKind.boardState,
      '판 상태 ${breakdown.boardStateChangeCount}곳 변경',
      breakdown.boardStateChangePoints,
    );
    add(
      CreativeChainEvidenceKind.movedEntity,
      '기물 ${breakdown.movedEntityCount}개 이동',
      breakdown.movedEntityPoints,
    );
    add(
      CreativeChainEvidenceKind.preparationShot,
      '준비 샷 ${breakdown.preparationShotCount}회 기여',
      breakdown.preparationPoints,
    );
    add(
      CreativeChainEvidenceKind.minimumShot,
      '최소 샷 보너스',
      breakdown.minimumShotBonus,
    );
    evidence.addAll(
      completedChallenges.map(
        (challengeId) => CreativeChainEvidence(
          kind: CreativeChainEvidenceKind.optionalChallenge,
          label: '선택 도전 ${_challengeLabel(challengeId)}',
          points: 40,
          shotIndex: holeShotIndex,
        ),
      ),
    );
    add(
      CreativeChainEvidenceKind.unrelatedImpact,
      '부가 충돌 ${breakdown.unrelatedImpactCount}회',
      breakdown.unrelatedImpactPoints,
    );
    return List.unmodifiable(evidence);
  }

  CreativeChainScoreBreakdown _emptyBreakdown({required int parShots}) {
    return const CreativeChainScoreBreakdown(
      clearBasePoints: 0,
      causalDepth: 0,
      causalEventCount: 0,
      causalDepthPoints: 0,
      distinctEntityTypes: 0,
      distinctEntityTypePoints: 0,
      distinctEntityIds: 0,
      distinctEntityPoints: 0,
      wallReflectionCount: 0,
      wallReflectionPoints: 0,
      pastBallCount: 0,
      pastBallPoints: 0,
      traitActivationCount: 0,
      traitActivationPoints: 0,
      traitConsumptionCount: 0,
      traitConsumptionPoints: 0,
      powerSliderCount: 0,
      powerSliderPoints: 0,
      boardStateChangeCount: 0,
      boardStateChangePoints: 0,
      movedEntityCount: 0,
      movedEntityPoints: 0,
      preparationShotCount: 0,
      preparationEvidenceCount: 0,
      preparationPoints: 0,
      minimumShotBonus: 0,
      optionalChallengeCount: 0,
      optionalChallengePoints: 0,
      unrelatedImpactCount: 0,
      unrelatedImpactPoints: 0,
      qualifiedImpactCount: 0,
      dampedImpactCount: 0,
      ignoredImpactCount: 0,
      cappedImpactCount: 0,
    );
  }

  int _causalDepth(
    List<PhysicsEvent> causalEvents,
    _ImpactScoring impactScoring,
  ) {
    var depth = 0;
    for (final event in causalEvents) {
      if (event.targetType == EntityType.hole) {
        continue;
      }
      if (event.kind == PhysicsEventKind.impact) {
        final factor = impactScoring.factors[event];
        if (factor == null || factor < 1) {
          continue;
        }
      }
      depth++;
    }
    return _cap(depth, 32);
  }

  int _wallPoints(
    List<PhysicsEvent> wallEvents,
    Map<PhysicsEvent, double> factors,
  ) {
    var points = 0.0;
    for (final event in wallEvents) {
      points += 30 * (factors[event] ?? 1);
    }
    return points.round();
  }

  int _minimumShotBonus({required int parShots, required int shotsUsed}) {
    return _cap(parShots - shotsUsed, 10) * 35;
  }

  int _diversityPoints(int count) {
    if (count == 0) return 0;
    final firstTwo = _cap(count, 2) * 35;
    final weightedTail = _cap(count - 2, 6) * 25;
    return firstTwo + weightedTail;
  }

  bool _isCausalEvent(PhysicsEvent event) {
    return event.kind == PhysicsEventKind.impact ||
        event.kind == PhysicsEventKind.powerSliderActivation ||
        event.kind == PhysicsEventKind.reflectorRotation ||
        event.kind == PhysicsEventKind.stateChange;
  }

  bool _isMeaningfulImpact(PhysicsEvent event) {
    if (event.kind != PhysicsEventKind.impact) return false;
    final impact = event.impact;
    final speed = impact?.relativeNormalSpeed ?? event.resultingVelocity.length;
    final impulse = impact?.impulse ?? event.impulse;
    return speed >= microVibrationSpeed || impulse >= microVibrationImpulse;
  }

  bool _isTraitActivation(PhysicsEvent event) {
    if (event.kind != PhysicsEventKind.stateChange) return false;
    return event.visualState == 'stuck' || event.visualState == 'popped';
  }

  String _traitActivationKey(PhysicsEvent event) {
    if (event.sourceTraits.isNotEmpty) {
      final traits = event.sourceTraits.map((trait) => trait.name).toList()
        ..sort();
      return '속성:${traits.join(',')}';
    }
    return '상태:${event.visualState}';
  }

  bool _isTraitConsumption(PhysicsEvent event) {
    return event.kind == PhysicsEventKind.stateChange &&
        event.visualState == 'sharpness_consumed';
  }

  bool _isBoardStateChange(PhysicsEvent event) {
    if (event.kind == PhysicsEventKind.reflectorRotation) return true;
    if (event.kind != PhysicsEventKind.stateChange) return false;
    return event.targetType == EntityType.switchPad ||
        event.targetType == EntityType.gate ||
        event.targetType == EntityType.rotatingReflector;
  }

  bool _reflectsState(EntityState entity, String? visualState) {
    return switch (visualState) {
      'open' => entity.open || entity.visualState == 'open',
      'pressed' => entity.pressed || entity.visualState == 'pressed',
      null || '' => false,
      _ => entity.visualState == visualState,
    };
  }

  List<PhysicsEvent> _uniqueEvents(
    Iterable<PhysicsEvent> events,
    String Function(PhysicsEvent event) keyOf,
  ) {
    final seen = <String>{};
    return List.unmodifiable(events.where((event) => seen.add(keyOf(event))));
  }

  String _challengeLabel(String challengeId) {
    return switch (challengeId) {
      CreativeChainChallengeId.wallReflection => '벽 반사',
      CreativeChainChallengeId.pastBall => '과거 공 활용',
      CreativeChainChallengeId.traitReaction => '속성 반응',
      CreativeChainChallengeId.powerSlider => '파워 슬라이더',
      CreativeChainChallengeId.boardState => '판 상태 변경',
      CreativeChainChallengeId.preparationShot => '준비 샷',
      CreativeChainChallengeId.diverseChain => '다양한 연쇄',
      _ => '연쇄 달성',
    };
  }

  bool _isPastBall(String id, EntityType type) {
    return type == EntityType.ball && id != 'active_ball';
  }

  String _contactKey(PhysicsEvent event) {
    final face = event.targetType == EntityType.wall
        ? ':${_wallFace(event.normal)}'
        : '';
    return '${event.targetEntityId}$face';
  }

  String _wallFace(Vec2 normal) {
    final x = normal.x;
    final y = normal.y;
    if (x.abs() >= y.abs()) return x >= 0 ? 'right' : 'left';
    return y >= 0 ? 'bottom' : 'top';
  }

  int _cap(int value, int maximum) {
    if (value <= 0 || maximum <= 0) return 0;
    if (value >= maximum) return maximum;
    return value;
  }

  String _fixtureContext(ReplayFixture fixture) {
    final inputs = fixture.shots
        .map(
          (shot) =>
              '${shot.angleRadians.toStringAsFixed(6)}:${shot.power.toStringAsFixed(6)}:${shot.equippedTrait?.name}',
        )
        .join('|');
    return '$scoreVersion;fixture=${fixture.id};stage=${fixture.stageIndex};'
        'route=${fixture.routeTag};inputs=$inputs';
  }

  String _signature({
    required String replayContext,
    required List<ShotResult> results,
    required CreativeChainScoreBreakdown breakdown,
    required int? holeShotIndex,
  }) {
    final raw = StringBuffer()
      ..write('$scoreVersion;$replayContext;hole=$holeShotIndex;')
      ..write('score=${breakdown.totalPoints};')
      ..write(
        '${breakdown.causalDepth}:${breakdown.distinctEntityTypes}:'
        '${breakdown.distinctEntityIds}:${breakdown.wallReflectionCount}:',
      )
      ..write(
        '${breakdown.pastBallCount}:${breakdown.preparationShotCount}:'
        '${breakdown.optionalChallengeCount};',
      );
    for (final result in results) {
      raw.write(shotResultFingerprint(result));
    }
    var hash = BigInt.parse('14695981039346656037');
    final mask = (BigInt.one << 64) - BigInt.one;
    for (final codeUnit in raw.toString().codeUnits) {
      hash =
          ((hash ^ BigInt.from(codeUnit)) * BigInt.parse('1099511628211')) &
          mask;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}

class _ImpactScoring {
  const _ImpactScoring({
    required this.scoredImpacts,
    required this.factors,
    required this.dampedCount,
    required this.ignoredCount,
    required this.cappedCount,
  });

  final List<PhysicsEvent> scoredImpacts;
  final Map<PhysicsEvent, double> factors;
  final int dampedCount;
  final int ignoredCount;
  final int cappedCount;
}

class _UnrelatedImpacts {
  const _UnrelatedImpacts({required this.count, required this.points});

  final int count;
  final int points;
}
