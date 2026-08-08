import 'dart:collection';
import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../domain/stage_pattern.dart';
import '../simulation/shot_resolver.dart';

/// 정적 패턴 검증으로 증명할 수 없는 런타임 사실을 주입하는 경계다.
///
/// 실제 게임 물리를 대체하는 인터페이스가 아니다. 생산 probe는 제한된
/// 대표 입력으로 관찰한 사실만 보고하고, 테스트 probe는 후속 기믹 구현의
/// evidence 계약을 검증하기 위해 명시적인 사실을 주입한다.
abstract interface class PatternRuntimeProbe {
  PatternRuntimeEvidence probe({
    required StageDefinition stage,
    required StagePattern pattern,
  });
}

/// 생산 패턴의 대표 해법을 실제 물리로 재생하기 위한 제한된 시나리오다.
///
/// [familyId]는 정답 추천이 아니라 선언된 풀이 계열에 실행 증거를 연결하는
/// QA 식별자다. [rewardFree]는 런 보상을 주입하지 않은 해법임을 뜻한다.
class PatternRuntimeScenario {
  const PatternRuntimeScenario({
    required this.id,
    required this.familyId,
    required this.inputs,
    this.rewardFree = true,
  }) : assert(id != ''),
       assert(familyId != ''),
       assert(inputs.length > 0);

  final String id;
  final String familyId;
  final List<ShotInput> inputs;
  final bool rewardFree;
}

/// 패턴 실행 검증에서 관찰된 사실이다.
///
/// `definitiveNoRoute`와 신규 기물 적용 여부는 반드시 probe가 명시적으로
/// 보고해야 한다. metadata 문자열만으로 이 값을 만들지 않는다.
class PatternRuntimeEvidence {
  const PatternRuntimeEvidence({
    this.probeCount = 0,
    this.maxProbeCount = 0,
    this.shotCount = 0,
    this.maxShots = 0,
    this.routeObserved = false,
    this.definitiveNoRoute = false,
    this.observedSolutionFamilies = const {},
    this.rewardFreeRouteObserved = false,
    this.solutionContractRequired = false,
    this.safetyStop = false,
    this.infiniteBounce = false,
    this.finiteCoordinates = true,
    this.finiteTime = true,
    this.negativeTime = false,
    this.wallMoved = false,
    this.holePassThrough = false,
    this.nonDeterministic = false,
    this.sliderApplicable = false,
    this.sliderTunneling = false,
    this.rotatorApplicable = false,
    this.rotatorOrderViolation = false,
    this.allRepresentativeInputsNoMovement = false,
    this.launchUnavailable = false,
    this.autoClearDetected = false,
  });

  /// 서로 다른 대표 입력을 실행한 횟수다.
  final int probeCount;
  final int maxProbeCount;

  /// ShotResolver를 실제 호출한 횟수다. 결정론 검증 때문에 한 입력을 두 번
  /// 실행할 수 있으므로 [probeCount]보다 클 수 있다.
  final int shotCount;
  final int maxShots;

  final bool routeObserved;
  final bool definitiveNoRoute;
  final Set<String> observedSolutionFamilies;
  final bool rewardFreeRouteObserved;
  final bool solutionContractRequired;
  final bool safetyStop;
  final bool infiniteBounce;

  /// 좌표뿐 아니라 현재 결과 모델이 가진 모든 물리 실수값의 유한성을 뜻한다.
  final bool finiteCoordinates;

  /// 기존 evidence 계약을 위한 필드다. 현재 ShotResolver 결과 모델에는
  /// 명시적인 시간 double 필드가 없으므로 실제 probe에서는 항상 true다.
  final bool finiteTime;

  /// 실제 시간 필드가 생기기 전까지 음수 이벤트 순서와 반복 횟수를 나타낸다.
  final bool negativeTime;
  final bool wallMoved;
  final bool holePassThrough;
  final bool nonDeterministic;

  /// 패턴에 해당 기물이 있을 때만 결함 판정을 적용한다.
  final bool sliderApplicable;
  final bool sliderTunneling;
  final bool rotatorApplicable;
  final bool rotatorOrderViolation;

  final bool allRepresentativeInputsNoMovement;
  final bool launchUnavailable;
  final bool autoClearDetected;

  bool get withinBudget =>
      probeCount >= 0 &&
      shotCount >= 0 &&
      maxProbeCount >= 0 &&
      maxShots >= 0 &&
      probeCount <= maxProbeCount &&
      shotCount <= maxShots;

  PatternRuntimeEvidence copyWith({
    int? probeCount,
    int? maxProbeCount,
    int? shotCount,
    int? maxShots,
    bool? routeObserved,
    bool? definitiveNoRoute,
    Set<String>? observedSolutionFamilies,
    bool? rewardFreeRouteObserved,
    bool? solutionContractRequired,
    bool? safetyStop,
    bool? infiniteBounce,
    bool? finiteCoordinates,
    bool? finiteTime,
    bool? negativeTime,
    bool? wallMoved,
    bool? holePassThrough,
    bool? nonDeterministic,
    bool? sliderApplicable,
    bool? sliderTunneling,
    bool? rotatorApplicable,
    bool? rotatorOrderViolation,
    bool? allRepresentativeInputsNoMovement,
    bool? launchUnavailable,
    bool? autoClearDetected,
  }) {
    return PatternRuntimeEvidence(
      probeCount: probeCount ?? this.probeCount,
      maxProbeCount: maxProbeCount ?? this.maxProbeCount,
      shotCount: shotCount ?? this.shotCount,
      maxShots: maxShots ?? this.maxShots,
      routeObserved: routeObserved ?? this.routeObserved,
      definitiveNoRoute: definitiveNoRoute ?? this.definitiveNoRoute,
      observedSolutionFamilies:
          observedSolutionFamilies ?? this.observedSolutionFamilies,
      rewardFreeRouteObserved:
          rewardFreeRouteObserved ?? this.rewardFreeRouteObserved,
      solutionContractRequired:
          solutionContractRequired ?? this.solutionContractRequired,
      safetyStop: safetyStop ?? this.safetyStop,
      infiniteBounce: infiniteBounce ?? this.infiniteBounce,
      finiteCoordinates: finiteCoordinates ?? this.finiteCoordinates,
      finiteTime: finiteTime ?? this.finiteTime,
      negativeTime: negativeTime ?? this.negativeTime,
      wallMoved: wallMoved ?? this.wallMoved,
      holePassThrough: holePassThrough ?? this.holePassThrough,
      nonDeterministic: nonDeterministic ?? this.nonDeterministic,
      sliderApplicable: sliderApplicable ?? this.sliderApplicable,
      sliderTunneling: sliderTunneling ?? this.sliderTunneling,
      rotatorApplicable: rotatorApplicable ?? this.rotatorApplicable,
      rotatorOrderViolation:
          rotatorOrderViolation ?? this.rotatorOrderViolation,
      allRepresentativeInputsNoMovement:
          allRepresentativeInputsNoMovement ??
          this.allRepresentativeInputsNoMovement,
      launchUnavailable: launchUnavailable ?? this.launchUnavailable,
      autoClearDetected: autoClearDetected ?? this.autoClearDetected,
    );
  }
}

/// 테스트에서 실제 기물 구현과 무관하게 동적 evidence 계약을 검증한다.
class ScriptedPatternRuntimeProbe implements PatternRuntimeProbe {
  ScriptedPatternRuntimeProbe(this.evidenceByPatternId);

  final Map<String, PatternRuntimeEvidence> evidenceByPatternId;
  final List<String> requestedPatternIds = <String>[];

  @override
  PatternRuntimeEvidence probe({
    required StageDefinition stage,
    required StagePattern pattern,
  }) {
    requestedPatternIds.add(pattern.patternId);
    return evidenceByPatternId[pattern.patternId] ??
        const PatternRuntimeEvidence();
  }
}

/// 기존 ShotResolver를 제한된 입력 집합으로 관찰하는 생산용 probe다.
class ShotResolverPatternRuntimeProbe implements PatternRuntimeProbe {
  ShotResolverPatternRuntimeProbe({
    this.shotResolver = const ShotResolver(),
    this.representativeInputs = defaultRepresentativeInputs,
    this.representativeScenarios = const [],
    this.requireSolutionContract = false,
    this.boardSize = const Vec2(360, 560),
    this.maxProbeCount = 24,
    this.maxShots = 48,
  }) : assert(boardSize.x > 0 && boardSize.y > 0),
       assert(maxProbeCount >= 1),
       assert(maxShots >= 2);

  static const defaultRepresentativeInputs = <ShotInput>[
    ShotInput(direction: Vec2(1, 0), power: 0.45),
    ShotInput(direction: Vec2(0.7071, 0.7071), power: 0.45),
    ShotInput(direction: Vec2(0, 1), power: 0.45),
    ShotInput(direction: Vec2(-0.7071, 0.7071), power: 0.45),
    ShotInput(direction: Vec2(-1, 0), power: 0.45),
    ShotInput(direction: Vec2(-0.7071, -0.7071), power: 0.45),
    ShotInput(direction: Vec2(0, -1), power: 0.45),
    ShotInput(direction: Vec2(0.7071, -0.7071), power: 0.45),
    ShotInput(direction: Vec2(1, 0), power: 1),
    ShotInput(direction: Vec2(0, 1), power: 1),
    ShotInput(direction: Vec2(-1, 0), power: 1),
    ShotInput(direction: Vec2(0, -1), power: 1),
  ];

  final ShotResolver shotResolver;
  final List<ShotInput> representativeInputs;
  final List<PatternRuntimeScenario> representativeScenarios;
  final bool requireSolutionContract;
  final Vec2 boardSize;
  final int maxProbeCount;
  final int maxShots;

  @override
  PatternRuntimeEvidence probe({
    required StageDefinition stage,
    required StagePattern pattern,
  }) {
    final hasPowerSlider = pattern.objects.any(
      (object) => object.type == EntityType.powerSlider && object.active,
    );
    final hasRotatingReflector = pattern.objects.any(
      (object) => object.type == EntityType.rotatingReflector && object.active,
    );
    final scenarios = _boundedScenarios();
    if (scenarios.isEmpty) {
      return PatternRuntimeEvidence(
        maxProbeCount: maxProbeCount,
        maxShots: maxShots,
        sliderApplicable: hasPowerSlider,
        rotatorApplicable: hasRotatingReflector,
        allRepresentativeInputsNoMovement: true,
        solutionContractRequired: requireSolutionContract,
      );
    }

    final level = pattern.toLevelDefinition(
      stageId: stage.stageId,
      stageTitle: stage.title,
    );
    final initial = level.createState(0);
    final launchUnavailable =
        initial.phase == GamePhase.planning && !shotResolver.canLaunch(initial);
    final results = <ShotResult>[];
    var nonDeterministic = false;
    var finiteCoordinates = true;
    final finiteTime = true;
    var negativeTime = false;
    var safetyStop = false;
    var infiniteBounce = false;
    var wallMoved = false;
    var holePassThrough = false;
    var sliderTunneling = false;
    var rotatorOrderViolation = false;
    var routeObserved = false;
    var rewardFreeRouteObserved = false;
    final autoClearDetected = _initialBallOverlapsHole(initial);
    final definitiveNoRoute = !_hasStaticWallRoute(initial, boardSize);
    final families = <String>{};

    var shotCount = 0;
    for (final scenario in scenarios) {
      final firstRun = _resolveScenario(initial, scenario);
      final secondRun = _resolveScenario(initial, scenario);
      shotCount += scenario.inputs.length * 2;
      results
        ..addAll(firstRun)
        ..addAll(secondRun);
      if (_resultListFingerprint(firstRun) !=
          _resultListFingerprint(secondRun)) {
        nonDeterministic = true;
      }
      final scenarioSucceeded =
          firstRun.isNotEmpty &&
          secondRun.isNotEmpty &&
          firstRun.last.state.phase == GamePhase.success &&
          secondRun.last.state.phase == GamePhase.success;
      if (scenarioSucceeded) {
        routeObserved = true;
        if (representativeScenarios.isNotEmpty) {
          families.add(scenario.familyId);
        }
        rewardFreeRouteObserved =
            rewardFreeRouteObserved || scenario.rewardFree;
      }
      for (final result in [...firstRun, ...secondRun]) {
        finiteCoordinates = finiteCoordinates && _hasFiniteCoordinates(result);
        negativeTime = negativeTime || _hasNegativeEventOrder(result);
        safetyStop =
            safetyStop ||
            result.chainSafetyDiagnostics.isNotEmpty ||
            result.events.contains('chain_safety_stop');
        infiniteBounce =
            infiniteBounce ||
            result.chainSafetyDiagnostics.isNotEmpty ||
            result.events.contains('chain_safety_stop');
        routeObserved =
            routeObserved || result.state.phase == GamePhase.success;
        if (representativeScenarios.isEmpty) {
          families.addAll(_familiesFor(result));
          rewardFreeRouteObserved =
              rewardFreeRouteObserved ||
              result.state.phase == GamePhase.success;
        }
        wallMoved = wallMoved || _wallMoved(initial, result.state);
        holePassThrough =
            holePassThrough || _holeWasPassedWithoutCapture(initial, result);
        sliderTunneling =
            sliderTunneling || _hasSliderTunneling(initial, result);
        rotatorOrderViolation =
            rotatorOrderViolation ||
            _hasReflectorOrderViolation(initial, result);
      }
    }

    final allNoMovement = results.every((result) => !_pathMoved(result));
    return PatternRuntimeEvidence(
      probeCount: scenarios.length,
      maxProbeCount: maxProbeCount,
      shotCount: shotCount,
      maxShots: maxShots,
      routeObserved: routeObserved,
      definitiveNoRoute: definitiveNoRoute,
      observedSolutionFamilies: Set.unmodifiable(families),
      rewardFreeRouteObserved: rewardFreeRouteObserved,
      solutionContractRequired: requireSolutionContract,
      safetyStop: safetyStop,
      infiniteBounce: infiniteBounce,
      finiteCoordinates: finiteCoordinates,
      finiteTime: finiteTime,
      negativeTime: negativeTime,
      wallMoved: wallMoved,
      holePassThrough: holePassThrough,
      nonDeterministic: nonDeterministic,
      sliderApplicable: hasPowerSlider,
      sliderTunneling: sliderTunneling,
      rotatorApplicable: hasRotatingReflector,
      rotatorOrderViolation: rotatorOrderViolation,
      allRepresentativeInputsNoMovement: allNoMovement,
      launchUnavailable: launchUnavailable,
      autoClearDetected: autoClearDetected,
    );
  }

  List<PatternRuntimeScenario> _boundedScenarios() {
    final source = representativeScenarios.isEmpty
        ? [
            for (var index = 0; index < representativeInputs.length; index++)
              PatternRuntimeScenario(
                id: '기본 입력 ${index + 1}',
                familyId: '기본 탐색',
                inputs: [representativeInputs[index]],
              ),
          ]
        : representativeScenarios;
    final selected = <PatternRuntimeScenario>[];
    var shots = 0;
    for (final scenario in source) {
      final requiredShots = scenario.inputs.length * 2;
      if (selected.length >= maxProbeCount ||
          shots + requiredShots > maxShots) {
        break;
      }
      selected.add(scenario);
      shots += requiredShots;
    }
    return selected;
  }

  List<ShotResult> _resolveScenario(
    GameState initial,
    PatternRuntimeScenario scenario,
  ) {
    var state = initial;
    final results = <ShotResult>[];
    for (final input in scenario.inputs) {
      final result = shotResolver.resolve(state, input);
      results.add(result);
      state = result.state;
    }
    return results;
  }
}

String _resultListFingerprint(List<ShotResult> results) =>
    results.map(_fingerprint).join('\u0000');

bool _hasSliderTunneling(GameState initial, ShotResult result) {
  final sliders = initial.entities.where(
    (entity) => entity.type == EntityType.powerSlider && entity.active,
  );
  for (final slider in sliders) {
    final activeBall = initial.activeBall;
    if (activeBall.movable &&
        slider.allowedTargets.contains(activeBall.type) &&
        _pathCrossesSlider(result.path, activeBall, slider) &&
        !_hasSliderActivation(result, activeBall.id, slider.id)) {
      return true;
    }
    for (final move in result.moves) {
      final mover = initial.entityById(move.entityId);
      if (mover == null ||
          !mover.movable ||
          !slider.allowedTargets.contains(mover.type)) {
        continue;
      }
      final points = move.path.length >= 2 ? move.path : [move.from, move.to];
      if (_pathCrossesSlider(points, mover, slider) &&
          !_hasSliderActivation(result, mover.id, slider.id)) {
        return true;
      }
    }
  }
  return false;
}

bool _hasReflectorOrderViolation(GameState initial, ShotResult result) {
  final events = result.physicsEvents;
  final impacts = events
      .where(
        (event) =>
            event.kind == PhysicsEventKind.impact &&
            event.targetType == EntityType.rotatingReflector,
      )
      .toList();
  final rotations = events
      .where((event) => event.kind == PhysicsEventKind.reflectorRotation)
      .toList();

  final initialReflectors = <String, EntityState>{
    for (final entity in initial.entities)
      if (entity.type == EntityType.rotatingReflector) entity.id: entity,
  };
  final finalReflectors = <String, EntityState>{
    for (final entity in result.state.entities)
      if (entity.type == EntityType.rotatingReflector) entity.id: entity,
  };
  final eventRotationsByTarget = <String, List<PhysicsEvent>>{};
  for (final event in rotations) {
    eventRotationsByTarget
        .putIfAbsent(event.targetEntityId, () => <PhysicsEvent>[])
        .add(event);
  }
  final payloadRotationsByTarget = <String, List<ReflectorRotation>>{};
  for (final rotation in result.reflectorRotations) {
    payloadRotationsByTarget
        .putIfAbsent(rotation.reflectorEntityId, () => <ReflectorRotation>[])
        .add(rotation);
  }

  for (final entry in initialReflectors.entries) {
    final finalReflector = finalReflectors[entry.key];
    if (finalReflector == null) return true;
    final countDelta =
        finalReflector.reflectorRotationCount -
        entry.value.reflectorRotationCount;
    if (countDelta < 0 ||
        finalReflector.reflectorOrientation !=
            (entry.value.reflectorOrientation + 2 * countDelta) % 8) {
      return true;
    }
    final eventList = eventRotationsByTarget[entry.key] ?? const [];
    final payloadList = payloadRotationsByTarget[entry.key] ?? const [];
    if (eventList.length != countDelta ||
        payloadList.length != countDelta ||
        eventList.length != payloadList.length) {
      return true;
    }
    for (var index = 0; index < countDelta; index++) {
      final payload = payloadList[index];
      if (payload.rotationCountBefore !=
              entry.value.reflectorRotationCount + index ||
          payload.rotationCountAfter != payload.rotationCountBefore + 1 ||
          payload.orientationBefore !=
              (entry.value.reflectorOrientation + 2 * index) % 8 ||
          payload.orientationAfter != (payload.orientationBefore + 2) % 8) {
        return true;
      }
      final matchingEvents = eventList.where(
        (event) =>
            event.reflectorRotation != null &&
            _sameReflectorPayload(event.reflectorRotation!, payload),
      );
      if (matchingEvents.length != 1) {
        return true;
      }
    }
  }

  if (initialReflectors.length != finalReflectors.length ||
      eventRotationsByTarget.keys.any(
        (id) => !initialReflectors.containsKey(id),
      ) ||
      payloadRotationsByTarget.keys.any(
        (id) => !initialReflectors.containsKey(id),
      )) {
    return true;
  }

  bool sameKey(PhysicsEvent first, PhysicsEvent second) {
    return first.sourceEntityId == second.sourceEntityId &&
        first.targetEntityId == second.targetEntityId &&
        first.pathIndex == second.pathIndex &&
        (first.contactId == null ||
            second.contactId == null ||
            first.contactId == second.contactId);
  }

  // sticky·동일 접촉·outward escape impact은 기록만 하고 회전하지 않는다.
  // resolver가 qualifying 계약을 true로 확정한 impact만 회전의 원인이 된다.
  for (final impact in impacts.where(
    (event) => event.impact?.triggersReflectorRotation == true,
  )) {
    final matches = rotations
        .where((rotation) => sameKey(impact, rotation))
        .toList();
    if (matches.length != 1) return true;
    final rotation = matches.single;
    final index = events.indexOf(rotation);
    final impactIndex = events.indexOf(impact);
    if (impactIndex < 0 || index < 0 || impactIndex >= index) return true;
    if (rotation.parentEventId != impact.eventId) return true;
    final payload = rotation.reflectorRotation;
    if (payload == null ||
        payload.sourceEntityId != rotation.sourceEntityId ||
        payload.reflectorEntityId != rotation.targetEntityId ||
        impact.contactId != payload.contactId ||
        payload.pathIndex != rotation.pathIndex ||
        payload.collisionNormal != impact.normal ||
        rotation.normal != payload.collisionNormal ||
        impact.resultingVelocity != payload.velocityAfter ||
        rotation.resultingVelocity != payload.velocityAfter ||
        payload.orientationAfter != (payload.orientationBefore + 2) % 8 ||
        payload.rotationCountAfter != payload.rotationCountBefore + 1) {
      return true;
    }
  }

  // 회전은 정확히 하나의 qualifying impact를 부모로 가져야 한다.
  for (final rotation in rotations) {
    final causes = impacts.where(
      (impact) =>
          sameKey(impact, rotation) && rotation.parentEventId == impact.eventId,
    );
    if (causes.length != 1 ||
        causes.single.impact?.triggersReflectorRotation != true) {
      return true;
    }
  }
  return false;
}

bool _sameReflectorPayload(ReflectorRotation first, ReflectorRotation second) {
  return first.sourceEntityId == second.sourceEntityId &&
      first.reflectorEntityId == second.reflectorEntityId &&
      first.contactId == second.contactId &&
      first.pathIndex == second.pathIndex &&
      first.orientationBefore == second.orientationBefore &&
      first.orientationAfter == second.orientationAfter &&
      first.rotationCountBefore == second.rotationCountBefore &&
      first.rotationCountAfter == second.rotationCountAfter &&
      first.collisionNormal == second.collisionNormal &&
      first.velocityBefore == second.velocityBefore &&
      first.velocityAfter == second.velocityAfter;
}

bool _hasSliderActivation(ShotResult result, String sourceId, String sliderId) {
  return result.powerSliderActivations.any(
    (activation) =>
        activation.sourceEntityId == sourceId &&
        activation.sliderEntityId == sliderId,
  );
}

bool _pathCrossesSlider(
  List<Vec2> points,
  EntityState mover,
  EntityState slider,
) {
  if (points.length < 2) return false;
  for (var index = 1; index < points.length; index++) {
    final from = points[index - 1];
    final to = points[index];
    final distance = from.distanceTo(to);
    final steps = math.max(1, (distance / 1.25).ceil());
    for (var step = 0; step <= steps; step++) {
      final progress = step / steps;
      final position = Vec2(
        from.x + (to.x - from.x) * progress,
        from.y + (to.y - from.y) * progress,
      );
      if (_probeOverlaps(mover, slider, position)) return true;
    }
  }
  return false;
}

bool _probeOverlaps(EntityState mover, EntityState slider, Vec2 position) {
  if (mover.isCircle) {
    return slider.hitBounds.intersectsCircle(position, mover.hitRadius);
  }
  final moving = mover.copyWith(position: position).hitBounds;
  final target = slider.hitBounds;
  return moving.left <= target.right &&
      moving.right >= target.left &&
      moving.top <= target.bottom &&
      moving.bottom >= target.top;
}

Set<String> _familiesFor(ShotResult result) {
  if (result.state.phase != GamePhase.success) {
    return const {};
  }
  final families = <String>{};
  if (result.impacts.isEmpty) {
    families.add('직접 진입');
  }
  if (result.events.contains('bounced')) {
    families.add('벽 또는 탄성 반사');
  }
  if (result.events.any(
    (event) =>
        event.contains('pushed') ||
        event.contains('momentum') ||
        event.contains('switch'),
  )) {
    families.add('물체 연쇄');
  }
  if (result.events.any((event) => event.contains('sticky'))) {
    families.add('점착 활용');
  }
  return families;
}

bool _pathMoved(ShotResult result) {
  if (result.path.length < 2) return false;
  for (var index = 1; index < result.path.length; index++) {
    if (result.path[index].distanceTo(result.path[index - 1]) > 0.001) {
      return true;
    }
  }
  return false;
}

bool _hasFiniteCoordinates(ShotResult result) {
  bool finiteVec(Vec2 value) => value.x.isFinite && value.y.isFinite;
  if (!result.path.every(finiteVec)) return false;
  if (!_hasFiniteGameState(result.state, Set<GameState>.identity())) {
    return false;
  }
  bool finiteImpact(ShotImpact impact) {
    return finiteVec(impact.position) &&
        finiteVec(impact.normal) &&
        impact.strength.isFinite &&
        impact.relativeNormalSpeed.isFinite &&
        impact.impulse.isFinite;
  }

  bool finiteMove(ShotAnimationMove move) {
    return finiteVec(move.from) &&
        finiteVec(move.to) &&
        move.path.every(finiteVec) &&
        (move.impactPosition == null || finiteVec(move.impactPosition!)) &&
        (move.impactNormal == null || finiteVec(move.impactNormal!));
  }

  if (!result.moves.every(finiteMove)) {
    return false;
  }
  if (!result.impacts.every(finiteImpact)) {
    return false;
  }
  bool finiteSlider(PowerSliderActivation activation) {
    return finiteVec(activation.position) &&
        finiteVec(activation.direction) &&
        finiteVec(activation.motionDirection) &&
        finiteVec(activation.velocityBefore) &&
        finiteVec(activation.velocityAfter) &&
        activation.speedBefore.isFinite &&
        activation.speedAfter.isFinite &&
        activation.referenceSpeed.isFinite &&
        activation.pathIndex >= 0;
  }

  if (!result.powerSliderActivations.every(finiteSlider)) {
    return false;
  }
  bool finiteReflector(ReflectorRotation rotation) {
    return finiteVec(rotation.collisionNormal) &&
        finiteVec(rotation.velocityBefore) &&
        finiteVec(rotation.velocityAfter) &&
        rotation.orientationBefore >= 0 &&
        rotation.orientationBefore <= 7 &&
        rotation.orientationAfter >= 0 &&
        rotation.orientationAfter <= 7 &&
        rotation.rotationCountBefore >= 0 &&
        rotation.rotationCountAfter >= 0 &&
        rotation.pathIndex >= 0;
  }

  if (!result.reflectorRotations.every(finiteReflector)) {
    return false;
  }
  bool finitePhysicsEvent(PhysicsEvent event) {
    return finiteVec(event.position) &&
        finiteVec(event.normal) &&
        event.impulse.isFinite &&
        finiteVec(event.resultingVelocity) &&
        (event.remainingDistance == null ||
            event.remainingDistance!.isFinite) &&
        (event.remainingSpeed == null || event.remainingSpeed!.isFinite) &&
        (event.impact == null || finiteImpact(event.impact!)) &&
        (event.move == null || finiteMove(event.move!)) &&
        (event.powerSlider == null || finiteSlider(event.powerSlider!)) &&
        (event.reflectorRotation == null ||
            finiteReflector(event.reflectorRotation!));
  }

  if (!result.physicsEvents.every(finitePhysicsEvent)) {
    return false;
  }
  return result.chainSafetyDiagnostics.every(
    (diagnostic) =>
        diagnostic.remainingDistance.isFinite &&
        diagnostic.remainingSpeed.isFinite,
  );
}

bool _hasFiniteGameState(GameState state, Set<GameState> activeStates) {
  if (!activeStates.add(state)) return true;
  bool finiteVec(Vec2 value) => value.x.isFinite && value.y.isFinite;
  final finite =
      finiteVec(state.ballSpawn) &&
      finiteVec(state.aimDirection) &&
      state.aimPower.isFinite &&
      state.entities.every(
        (entity) =>
            finiteVec(entity.position) &&
            finiteVec(entity.size) &&
            finiteVec(entity.direction) &&
            entity.hitboxScale.isFinite &&
            entity.restitution.isFinite &&
            entity.referenceSpeed.isFinite &&
            (entity.type != EntityType.rotatingReflector ||
                (entity.reflectorOrientation >= 0 &&
                    entity.reflectorOrientation <= 7 &&
                    entity.reflectorRotationCount >= 0)),
      ) &&
      state.history.every(
        (historyState) => _hasFiniteGameState(historyState, activeStates),
      );
  activeStates.remove(state);
  return finite;
}

bool _hasNegativeEventOrder(ShotResult result) {
  return result.impacts.any((impact) => impact.pathIndex < 0) ||
      result.moves.any((move) => move.triggerPathIndex < 0) ||
      result.physicsEvents.any(
        (event) =>
            event.pathIndex < 0 ||
            (event.iterations != null && event.iterations! < 0),
      ) ||
      result.chainSafetyDiagnostics.any(
        (diagnostic) =>
            diagnostic.pathIndex < 0 ||
            diagnostic.depth < 0 ||
            diagnostic.iterations < 0,
      );
}

bool _wallMoved(GameState before, GameState after) {
  final beforeWalls = before.entities.where(
    (entity) => entity.type == EntityType.wall,
  );
  final afterWalls = after.entities.where(
    (entity) => entity.type == EntityType.wall,
  );
  for (final wall in beforeWalls) {
    final next = after.entityById(wall.id);
    if (next == null || !_sameWallPhysics(wall, next)) {
      return true;
    }
  }
  for (final wall in afterWalls) {
    final previous = before.entityById(wall.id);
    if (previous == null || previous.type != EntityType.wall) return true;
  }
  return false;
}

bool _sameWallPhysics(EntityState before, EntityState after) {
  final sameVec =
      before.position.x == after.position.x &&
      before.position.y == after.position.y &&
      before.size.x == after.size.x &&
      before.size.y == after.size.y;
  final beforeTraits = before.traits.map((trait) => trait.name).toList()
    ..sort();
  final afterTraits = after.traits.map((trait) => trait.name).toList()..sort();
  final sameTraits =
      beforeTraits.length == afterTraits.length &&
      beforeTraits.asMap().entries.every(
        (entry) => entry.value == afterTraits[entry.key],
      );
  return sameVec &&
      before.type == after.type &&
      sameTraits &&
      before.movable == after.movable &&
      before.solid == after.solid &&
      before.active == after.active &&
      before.open == after.open &&
      before.pressed == after.pressed &&
      before.hitboxScale == after.hitboxScale &&
      before.restitution == after.restitution &&
      before.linkId == after.linkId;
}

bool _initialBallOverlapsHole(GameState state) {
  final hole = state.entities
      .where((entity) => entity.type == EntityType.hole)
      .firstOrNull;
  if (hole == null) return false;
  return hole.position.distanceTo(state.activeBall.position) <=
      hole.radius + state.activeBall.hitRadius;
}

bool _holeWasPassedWithoutCapture(GameState initial, ShotResult result) {
  if (result.events.contains('hole_entered')) {
    return false;
  }
  final hole = initial.entities
      .where((entity) => entity.type == EntityType.hole)
      .firstOrNull;
  if (hole == null || result.path.length < 2) return false;
  final radius = hole.radius + initial.activeBall.hitRadius;
  for (var index = 1; index < result.path.length; index++) {
    if (_segmentDistanceToPoint(
          result.path[index - 1],
          result.path[index],
          hole.position,
        ) <=
        radius) {
      return true;
    }
  }
  return false;
}

double _segmentDistanceToPoint(Vec2 start, Vec2 end, Vec2 point) {
  final delta = end - start;
  final lengthSquared = delta.dot(delta);
  if (lengthSquared == 0) return start.distanceTo(point);
  final t = ((point - start).dot(delta) / lengthSquared).clamp(0.0, 1.0);
  return (start + delta * t).distanceTo(point);
}

String _fingerprint(ShotResult result) {
  final buffer = StringBuffer()..write('shot{');
  final activeStates = Set<GameState>.identity();
  _appendGameStateFingerprint(buffer, result.state, activeStates);
  buffer.write('}');
  buffer.write('|events[');
  for (final event in result.events) {
    _writeText(buffer, 'event', event);
  }
  buffer.write(']|path[');
  for (final point in result.path) {
    buffer.write('|${_vecFingerprint(point)}');
  }
  buffer.write(']');

  buffer.write('|impacts[');
  for (final impact in result.impacts) {
    _appendImpactFingerprint(buffer, impact);
  }
  buffer.write(']|sliders[');
  for (final activation in result.powerSliderActivations) {
    buffer
      ..write('|activation{')
      ..write('|position=${_vecFingerprint(activation.position)}')
      ..write('|direction=${_vecFingerprint(activation.direction)}')
      ..write('|motionDirection=${_vecFingerprint(activation.motionDirection)}')
      ..write('|velocityBefore=${_vecFingerprint(activation.velocityBefore)}')
      ..write('|velocityAfter=${_vecFingerprint(activation.velocityAfter)}')
      ..write('|pathIndex=${activation.pathIndex}')
      ..write('|speedBefore=${_number(activation.speedBefore)}')
      ..write('|speedAfter=${_number(activation.speedAfter)}')
      ..write('|referenceSpeed=${_number(activation.referenceSpeed)}');
    _writeText(buffer, 'sourceEntityId', activation.sourceEntityId);
    _writeText(buffer, 'sliderEntityId', activation.sliderEntityId);
    _writeText(buffer, 'contactId', activation.contactId);
    buffer.write('}');
  }
  buffer.write(']|moves[');
  for (final move in result.moves) {
    _appendMoveFingerprint(buffer, move);
  }
  buffer.write(']|physics[');
  for (final event in result.physicsEvents) {
    _appendPhysicsEventFingerprint(buffer, event);
  }
  buffer.write(']|diagnostics[');
  for (final diagnostic in result.chainSafetyDiagnostics) {
    buffer
      ..write('|target=${_stableText(diagnostic.targetEntityId)}')
      ..write(
        ':${diagnostic.pathIndex}:${diagnostic.depth}:${diagnostic.iterations}',
      )
      ..write(':${_number(diagnostic.remainingDistance)}')
      ..write(':${_number(diagnostic.remainingSpeed)}');
  }
  buffer.write(']');
  return buffer.toString();
}

String _stableText(String? value) {
  if (value == null) return '<null>';
  return '${value.length}:$value';
}

void _writeText(StringBuffer buffer, String label, String? value) {
  buffer.write('|$label=${_stableText(value)}');
}

void _appendGameStateFingerprint(
  StringBuffer buffer,
  GameState state,
  Set<GameState> activeStates,
) {
  if (!activeStates.add(state)) {
    buffer.write('|state_cycle');
    return;
  }
  buffer
    ..write('|state{')
    ..write('|levelIndex=${state.levelIndex}')
    ..write('|phase=${state.phase.name}')
    ..write('|shotCount=${state.shotCount}')
    ..write('|score=${state.score}')
    ..write('|ballSpawn=${_vecFingerprint(state.ballSpawn)}')
    ..write('|aimDirection=${_vecFingerprint(state.aimDirection)}')
    ..write('|aimPower=${_number(state.aimPower)}')
    ..write('|copyCharges=${state.copyCharges}')
    ..write('|copyChargeLimit=${state.copyChargeLimit}')
    ..write('|copyCoreCount=${state.copyCoreCount}')
    ..write('|copyCoreRewarded=${state.copyCoreRewarded}');
  _writeText(buffer, 'levelName', state.levelName);
  _writeText(buffer, 'selectedSourceId', state.selectedSourceId);
  _writeText(buffer, 'selectedTrait', state.selectedTrait?.name);
  _writeText(buffer, 'equippedTrait', state.equippedTrait?.name);
  _writeText(buffer, 'message', state.message);
  buffer.write('|entities[');
  for (final entity in state.entities) {
    _appendEntityFingerprint(buffer, entity);
  }
  buffer.write(']|history[');
  for (final historyState in state.history) {
    _appendGameStateFingerprint(buffer, historyState, activeStates);
  }
  buffer.write(']}');
  activeStates.remove(state);
}

void _appendEntityFingerprint(StringBuffer buffer, EntityState entity) {
  final traits = entity.traits.map((trait) => trait.name).toList()..sort();
  buffer
    ..write('|entity{')
    ..write('|type=${entity.type.name}')
    ..write('|position=${_vecFingerprint(entity.position)}')
    ..write('|size=${_vecFingerprint(entity.size)}')
    ..write('|traits=${traits.join(',')}')
    ..write('|movable=${entity.movable}')
    ..write('|solid=${entity.solid}')
    ..write('|active=${entity.active}')
    ..write('|open=${entity.open}')
    ..write('|pressed=${entity.pressed}')
    ..write('|hitboxScale=${_number(entity.hitboxScale)}')
    ..write('|restitution=${_number(entity.restitution)}')
    ..write('|direction=${_vecFingerprint(entity.direction)}')
    ..write('|referenceSpeed=${_number(entity.referenceSpeed)}')
    ..write('|allowedTargets=${_stableAllowedTargets(entity.allowedTargets)}')
    ..write('|movableWhenDrained=${entity.movableWhenDrained}');
  if (entity.type == EntityType.rotatingReflector) {
    buffer
      ..write('|reflectorOrientation=${entity.reflectorOrientation}')
      ..write('|reflectorRotationCount=${entity.reflectorRotationCount}');
  }
  _writeText(buffer, 'id', entity.id);
  _writeText(buffer, 'visualState', entity.visualState);
  _writeText(buffer, 'linkId', entity.linkId);
  buffer.write('}');
}

void _appendImpactFingerprint(StringBuffer buffer, ShotImpact impact) {
  buffer
    ..write('|impact{')
    ..write('|entityType=${impact.entityType.name}')
    ..write('|pathIndex=${impact.pathIndex}')
    ..write('|position=${_vecFingerprint(impact.position)}')
    ..write('|normal=${_vecFingerprint(impact.normal)}')
    ..write('|strength=${_number(impact.strength)}')
    ..write('|relativeNormalSpeed=${_number(impact.relativeNormalSpeed)}')
    ..write('|impulse=${_number(impact.impulse)}')
    ..write('|impactTier=${impact.impactTier.name}')
    ..write('|triggersReflectorRotation=${impact.triggersReflectorRotation}');
  _writeText(buffer, 'sourceEntityId', impact.sourceEntityId);
  _writeText(buffer, 'entityId', impact.entityId);
  _writeText(buffer, 'contactId', impact.contactId);
  buffer.write('}');
}

void _appendMoveFingerprint(StringBuffer buffer, ShotAnimationMove move) {
  buffer
    ..write('|move{')
    ..write('|from=${_vecFingerprint(move.from)}')
    ..write('|to=${_vecFingerprint(move.to)}')
    ..write('|triggerPathIndex=${move.triggerPathIndex}')
    ..write('|path=${move.path.map(_vecFingerprint).join(';')}')
    ..write(
      '|impactPosition=${move.impactPosition == null ? '' : _vecFingerprint(move.impactPosition!)}',
    )
    ..write(
      '|impactNormal=${move.impactNormal == null ? '' : _vecFingerprint(move.impactNormal!)}',
    );
  _writeText(buffer, 'entityId', move.entityId);
  _writeText(buffer, 'visualState', move.visualState);
  buffer.write('}');
}

void _appendPhysicsEventFingerprint(StringBuffer buffer, PhysicsEvent event) {
  buffer
    ..write('|event{')
    ..write('|kind=${event.kind.name}')
    ..write('|pathIndex=${event.pathIndex}')
    ..write('|targetType=${event.targetType.name}')
    ..write('|position=${_vecFingerprint(event.position)}')
    ..write('|normal=${_vecFingerprint(event.normal)}')
    ..write('|impulse=${_number(event.impulse)}')
    ..write('|resultingVelocity=${_vecFingerprint(event.resultingVelocity)}')
    ..write('|remainingDistance=${_nullableNumber(event.remainingDistance)}')
    ..write('|remainingSpeed=${_nullableNumber(event.remainingSpeed)}')
    ..write('|iterations=${event.iterations ?? ''}')
    ..write('|triggersReflectorRotation=${event.triggersReflectorRotation}');
  _writeText(buffer, 'eventId', event.eventId);
  _writeText(buffer, 'parentEventId', event.parentEventId);
  _writeText(buffer, 'sourceEntityId', event.sourceEntityId);
  _writeText(buffer, 'targetEntityId', event.targetEntityId);
  _writeText(buffer, 'visualState', event.visualState);
  _writeText(buffer, 'contactId', event.contactId);
  if (event.powerSlider == null) {
    buffer.write('|powerSlider=null');
  } else {
    final activation = event.powerSlider!;
    buffer
      ..write('|powerSlider=')
      ..write(activation.contactId)
      ..write(':${_vecFingerprint(activation.direction)}')
      ..write(':${_vecFingerprint(activation.motionDirection)}')
      ..write(':${_vecFingerprint(activation.velocityBefore)}')
      ..write(':${_vecFingerprint(activation.velocityAfter)}')
      ..write(':${_number(activation.speedBefore)}')
      ..write(':${_number(activation.speedAfter)}');
  }
  if (event.reflectorRotation == null) {
    buffer.write('|reflectorRotation=null');
  } else {
    final rotation = event.reflectorRotation!;
    buffer
      ..write('|reflectorRotation=')
      ..write(':${rotation.orientationBefore}')
      ..write(':${rotation.orientationAfter}')
      ..write(':${rotation.rotationCountBefore}')
      ..write(':${rotation.rotationCountAfter}')
      ..write(':${_vecFingerprint(rotation.collisionNormal)}')
      ..write(':${_vecFingerprint(rotation.velocityBefore)}')
      ..write(':${_vecFingerprint(rotation.velocityAfter)}');
  }
  if (event.impact == null) {
    buffer.write('|impact=null');
  } else {
    buffer.write('|impact=');
    _appendImpactFingerprint(buffer, event.impact!);
  }
  if (event.move == null) {
    buffer.write('|move=null');
  } else {
    buffer.write('|move=');
    _appendMoveFingerprint(buffer, event.move!);
  }
  buffer.write('}');
}

String _number(double value) => value.toStringAsPrecision(17);

String _stableAllowedTargets(Set<EntityType> targets) {
  return EntityType.values
      .where(targets.contains)
      .map((target) => target.name)
      .join(',');
}

String _nullableNumber(double? value) => value == null ? '' : _number(value);

String _vecFingerprint(Vec2 value) => '${_number(value.x)},${_number(value.y)}';

bool _hasStaticWallRoute(GameState state, Vec2 boardSize) {
  final hole = state.entities
      .where((entity) => entity.type == EntityType.hole)
      .firstOrNull;
  if (hole == null) return true;

  final ball = state.activeBall;
  final radius = ball.hitRadius;
  final minX = radius;
  final minY = radius;
  final maxX = boardSize.x - radius;
  final maxY = boardSize.y - radius;
  if (maxX < minX || maxY < minY) return false;

  const spacing = 4.0;
  final columns = ((maxX - minX) / spacing).ceil();
  final rows = ((maxY - minY) / spacing).ceil();
  if (columns <= 0 || rows <= 0) return false;

  final walls = state.entities
      .where((entity) => entity.active && entity.type == EntityType.wall)
      .toList();

  Bounds cellBounds(int column, int row) {
    final left = minX + column * spacing;
    final top = minY + row * spacing;
    final right = math.min(left + spacing, maxX);
    final bottom = math.min(top + spacing, maxY);
    return Bounds(
      left: left,
      top: top,
      width: right - left,
      height: bottom - top,
    );
  }

  // 셀 전체가 하나의 벽에 덮일 때만 막힌 셀로 처리한다.
  // 일부만 겹친 셀은 연속 자유 공간의 보수적 상위 근사를 유지하도록 통과시킨다.
  bool blocked(int column, int row) {
    final cell = cellBounds(column, row);
    for (final wall in walls) {
      final bounds = wall.hitBounds;
      final expanded = Bounds(
        left: bounds.left - radius,
        top: bounds.top - radius,
        width: bounds.width + radius * 2,
        height: bounds.height + radius * 2,
      );
      if (cell.left >= expanded.left &&
          cell.right <= expanded.right &&
          cell.top >= expanded.top &&
          cell.bottom <= expanded.bottom) {
        return true;
      }
    }
    return false;
  }

  int nearestColumn(double x) =>
      ((x.clamp(minX, maxX) - minX) / spacing).floor().clamp(0, columns - 1);
  int nearestRow(double y) =>
      ((y.clamp(minY, maxY) - minY) / spacing).floor().clamp(0, rows - 1);
  int keyFor(int column, int row) => row * columns + column;

  final startColumn = nearestColumn(ball.position.x);
  final startRow = nearestRow(ball.position.y);
  if (blocked(startColumn, startRow)) return false;

  final targetRadius = hole.radius + radius;
  final queue = Queue<(int, int)>()..add((startColumn, startRow));
  final visited = <int>{keyFor(startColumn, startRow)};
  const directions = <(int, int)>[
    (-1, -1),
    (0, -1),
    (1, -1),
    (-1, 0),
    (1, 0),
    (-1, 1),
    (0, 1),
    (1, 1),
  ];

  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final cell = cellBounds(current.$1, current.$2);
    if (cell.intersectsCircle(hole.position, targetRadius)) return true;
    for (final direction in directions) {
      final nextColumn = current.$1 + direction.$1;
      final nextRow = current.$2 + direction.$2;
      if (nextColumn < 0 ||
          nextColumn >= columns ||
          nextRow < 0 ||
          nextRow >= rows) {
        continue;
      }
      final key = keyFor(nextColumn, nextRow);
      if (visited.contains(key)) continue;
      if (blocked(nextColumn, nextRow)) continue;
      visited.add(key);
      queue.add((nextColumn, nextRow));
    }
  }
  return false;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
