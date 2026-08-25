import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/hidden_mechanic_state.dart';
import '../domain/shot_input.dart';
import '../domain/trait.dart';
import '../levels/levels.dart';
import 'impact_metrics.dart';

class ShotResult {
  const ShotResult({
    required this.state,
    required this.path,
    required this.events,
    this.animationPath = const [],
    this.moves = const [],
    this.impacts = const [],
    this.powerSliderActivations = const [],
    this.reflectorRotations = const [],
    this.physicsEvents = const [],
    this.chainSafetyDiagnostics = const [],
  });

  final GameState state;
  final List<Vec2> path;

  /// 화면 재생에만 쓰는 보간 경로다. 비어 있으면 [path]를 그대로 사용한다.
  /// 판정·리플레이 지문·다음 샷의 착지 상태에는 영향을 주지 않는다.
  final List<Vec2> animationPath;
  final List<String> events;
  final List<ShotAnimationMove> moves;
  final List<ShotImpact> impacts;
  final List<PowerSliderActivation> powerSliderActivations;
  final List<ReflectorRotation> reflectorRotations;
  final List<PhysicsEvent> physicsEvents;
  final List<ChainSafetyDiagnostic> chainSafetyDiagnostics;
}

enum PhysicsEventKind {
  impact,
  powerSliderActivation,
  reflectorRotation,
  stateChange,
  move,
  chainSafetyStop,
}

int traitMaskOf(Iterable<TraitType> traits) {
  var mask = 0;
  for (final trait in traits) {
    mask |= 1 << trait.index;
  }
  return mask;
}

Set<TraitType> traitsFromMask(int mask) {
  return Set.unmodifiable(
    TraitType.values.where((trait) => mask & (1 << trait.index) != 0),
  );
}

class PowerSliderActivation {
  const PowerSliderActivation({
    required this.sourceEntityId,
    required this.sliderEntityId,
    required this.contactId,
    required this.position,
    required this.pathIndex,
    required this.direction,
    required this.motionDirection,
    required this.velocityBefore,
    required this.velocityAfter,
    required this.speedBefore,
    required this.speedAfter,
    required this.referenceSpeed,
  });

  final String sourceEntityId;
  final String sliderEntityId;
  final String contactId;
  final Vec2 position;
  final int pathIndex;

  /// 슬라이더의 배치·시각 방향이다. 이동체의 방향이 아니다.
  final Vec2 direction;

  /// 슬라이더 작동 전후의 실제 이동 방향과 속도다.
  final Vec2 motionDirection;
  final Vec2 velocityBefore;
  final Vec2 velocityAfter;
  final double speedBefore;
  final double speedAfter;
  final double referenceSpeed;
}

class ReflectorRotation {
  const ReflectorRotation({
    required this.sourceEntityId,
    required this.reflectorEntityId,
    required this.contactId,
    required this.pathIndex,
    required this.orientationBefore,
    required this.orientationAfter,
    required this.rotationCountBefore,
    required this.rotationCountAfter,
    required this.collisionNormal,
    required this.velocityBefore,
    required this.velocityAfter,
  });

  final String sourceEntityId;
  final String reflectorEntityId;
  final String contactId;
  final int pathIndex;
  final int orientationBefore;
  final int orientationAfter;
  final int rotationCountBefore;
  final int rotationCountAfter;
  final Vec2 collisionNormal;
  final Vec2 velocityBefore;
  final Vec2 velocityAfter;
}

/// 판정 중 실제로 적용된 엔티티 상태 변화를 기록한다.
/// 문자열 이벤트나 애니메이션 경로를 다시 해석하지 않고도
/// 충돌 이후의 인과 순서를 재생·검증할 수 있게 한다.
class PhysicsStateTransition {
  const PhysicsStateTransition({
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.targetType,
    required this.pathIndex,
    required this.previousState,
    required this.nextState,
    this.position = Vec2.zero,
    this.normal = Vec2.zero,
  });

  final String sourceEntityId;
  final String targetEntityId;
  final EntityType targetType;
  final int pathIndex;
  final String? previousState;
  final String nextState;
  final Vec2 position;
  final Vec2 normal;
}

class ChainSafetyDiagnostic {
  const ChainSafetyDiagnostic({
    required this.targetEntityId,
    required this.pathIndex,
    required this.depth,
    required this.iterations,
    required this.remainingDistance,
    required this.remainingSpeed,
  });

  final String targetEntityId;
  final int pathIndex;
  final int depth;
  final int iterations;
  final double remainingDistance;
  final double remainingSpeed;
}

class PhysicsEvent {
  const PhysicsEvent({
    required this.eventId,
    required this.kind,
    required this.pathIndex,
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.targetType,
    required this.position,
    required this.normal,
    required this.impulse,
    required this.resultingVelocity,
    this.parentEventId,
    this.visualState,
    this.remainingDistance,
    this.remainingSpeed,
    this.iterations,
    this.impact,
    this.move,
    this.contactId,
    this.triggersReflectorRotation = false,
    this.powerSlider,
    this.reflectorRotation,
    this.sourceTraitMask = 0,
  });

  final String eventId;
  final String? parentEventId;
  final PhysicsEventKind kind;
  final int pathIndex;
  final String sourceEntityId;
  final String targetEntityId;
  final EntityType targetType;
  final Vec2 position;
  final Vec2 normal;
  final double impulse;
  final Vec2 resultingVelocity;
  final String? visualState;
  final double? remainingDistance;
  final double? remainingSpeed;
  final int? iterations;
  final ShotImpact? impact;
  final ShotAnimationMove? move;
  final String? contactId;
  final bool triggersReflectorRotation;
  final PowerSliderActivation? powerSlider;
  final ReflectorRotation? reflectorRotation;
  final int sourceTraitMask;
  Set<TraitType> get sourceTraits => traitsFromMask(sourceTraitMask);
}

class ShotImpact {
  const ShotImpact({
    required this.entityId,
    required this.entityType,
    required this.position,
    required this.normal,
    required this.pathIndex,
    required this.strength,
    this.sourceEntityId = 'active_ball',
    this.contactId,
    this.triggersReflectorRotation = false,
    this.relativeNormalSpeed = 0,
    this.impulse = 0,
    this.impactTier = ImpactTier.light,
    this.sourceTraitMask = 0,
  });

  final String entityId;
  final EntityType entityType;
  final Vec2 position;
  final Vec2 normal;
  final int pathIndex;
  final double strength;
  final String sourceEntityId;
  final String? contactId;
  final bool triggersReflectorRotation;
  final double relativeNormalSpeed;
  final double impulse;
  final ImpactTier impactTier;
  final int sourceTraitMask;
  Set<TraitType> get sourceTraits => traitsFromMask(sourceTraitMask);
}

class ShotAnimationMove {
  const ShotAnimationMove({
    required this.entityId,
    required this.from,
    required this.to,
    required this.triggerPathIndex,
    this.visualState = 'pushed',
    this.path = const [],
    this.impactPosition,
    this.impactNormal,
  });

  final String entityId;
  final Vec2 from;
  final Vec2 to;
  final int triggerPathIndex;
  final String visualState;
  final List<Vec2> path;
  final Vec2? impactPosition;
  final Vec2? impactNormal;
}

List<PhysicsEvent> buildPhysicsEvents({
  required List<Vec2> path,
  required List<ShotImpact> impacts,
  required List<ShotAnimationMove> moves,
  required List<ChainSafetyDiagnostic> chainSafetyDiagnostics,
  List<PhysicsStateTransition> stateTransitions = const [],
  List<PowerSliderActivation> powerSliderActivations = const [],
  List<ReflectorRotation> reflectorRotations = const [],
}) {
  final events = <PhysicsEvent>[];
  final impactEventsByTarget = <String, PhysicsEvent>{};
  final impactEventsByContact = <String, List<PhysicsEvent>>{};
  final reflectorParentCursor = <String, int>{};

  for (var index = 0; index < impacts.length; index++) {
    final impact = impacts[index];
    final event = PhysicsEvent(
      eventId:
          'impact:$index:${impact.sourceEntityId}:${impact.entityId}:${impact.pathIndex}',
      parentEventId: impact.sourceEntityId == 'active_ball'
          ? null
          : impactEventsByTarget[impact.sourceEntityId]?.eventId,
      kind: PhysicsEventKind.impact,
      pathIndex: impact.pathIndex,
      sourceEntityId: impact.sourceEntityId,
      targetEntityId: impact.entityId,
      targetType: impact.entityType,
      position: impact.position,
      normal: impact.normal,
      impulse: impact.impulse,
      resultingVelocity: _impactResultingVelocity(
        path,
        moves,
        reflectorRotations,
        impact,
      ),
      impact: impact,
      contactId: impact.contactId,
      triggersReflectorRotation: impact.triggersReflectorRotation,
      sourceTraitMask: impact.sourceTraitMask,
    );
    events.add(event);
    impactEventsByTarget[impact.entityId] = event;
    final key =
        '${impact.sourceEntityId}:${impact.entityId}:${impact.pathIndex}';
    impactEventsByContact.putIfAbsent(key, () => <PhysicsEvent>[]).add(event);
  }

  for (var index = 0; index < powerSliderActivations.length; index++) {
    final activation = powerSliderActivations[index];
    final parent = events
        .where(
          (event) =>
              event.pathIndex <= activation.pathIndex &&
              (event.targetEntityId == activation.sourceEntityId ||
                  event.targetEntityId == activation.sliderEntityId),
        )
        .fold<PhysicsEvent?>(
          null,
          (latest, event) =>
              latest == null || event.pathIndex > latest.pathIndex
              ? event
              : latest,
        );
    events.add(
      PhysicsEvent(
        eventId:
            'slider:${activation.contactId}:${activation.pathIndex}:$index',
        parentEventId: parent?.eventId,
        kind: PhysicsEventKind.powerSliderActivation,
        pathIndex: activation.pathIndex,
        sourceEntityId: activation.sourceEntityId,
        targetEntityId: activation.sliderEntityId,
        targetType: EntityType.powerSlider,
        position: activation.position,
        // 슬라이더 방향은 배치·시각 전용이다. 물리 법선으로 노출하지 않는다.
        normal: Vec2.zero,
        impulse: activation.speedAfter - activation.speedBefore,
        resultingVelocity: activation.velocityAfter,
        contactId: activation.contactId,
        powerSlider: activation,
      ),
    );
  }

  for (var index = 0; index < reflectorRotations.length; index++) {
    final rotation = reflectorRotations[index];
    final key =
        '${rotation.sourceEntityId}:${rotation.reflectorEntityId}:${rotation.pathIndex}';
    final candidates = impactEventsByContact[key] ?? const <PhysicsEvent>[];
    final parentIndex = reflectorParentCursor[key] ?? 0;
    final parent = candidates.length > parentIndex
        ? candidates[parentIndex]
        : null;
    reflectorParentCursor[key] = parentIndex + 1;
    events.add(
      PhysicsEvent(
        eventId: 'reflector:${rotation.contactId}:${rotation.pathIndex}:$index',
        parentEventId: parent?.eventId,
        kind: PhysicsEventKind.reflectorRotation,
        pathIndex: rotation.pathIndex,
        sourceEntityId: rotation.sourceEntityId,
        targetEntityId: rotation.reflectorEntityId,
        targetType: EntityType.rotatingReflector,
        position: parent?.position ?? Vec2.zero,
        normal: rotation.collisionNormal,
        impulse: rotation.velocityAfter.length - rotation.velocityBefore.length,
        resultingVelocity: rotation.velocityAfter,
        contactId: rotation.contactId,
        triggersReflectorRotation: true,
        reflectorRotation: rotation,
      ),
    );
  }

  for (var index = 0; index < stateTransitions.length; index++) {
    final transition = stateTransitions[index];
    final parent = events
        .where(
          (event) =>
              event.pathIndex <= transition.pathIndex &&
              (event.targetEntityId == transition.sourceEntityId ||
                  event.targetEntityId == transition.targetEntityId),
        )
        .fold<PhysicsEvent?>(
          null,
          (latest, event) =>
              latest == null || event.pathIndex > latest.pathIndex
              ? event
              : latest,
        );
    events.add(
      PhysicsEvent(
        eventId:
            'state:$index:${transition.targetEntityId}:${transition.pathIndex}:${transition.nextState}',
        parentEventId: parent?.eventId,
        kind: PhysicsEventKind.stateChange,
        pathIndex: transition.pathIndex,
        sourceEntityId: transition.sourceEntityId,
        targetEntityId: transition.targetEntityId,
        targetType: transition.targetType,
        position: transition.position,
        normal: transition.normal,
        impulse: 0,
        resultingVelocity: Vec2.zero,
        visualState: transition.nextState,
      ),
    );
  }

  for (var index = 0; index < moves.length; index++) {
    final move = moves[index];
    final parent = events
        .where(
          (event) =>
              event.kind == PhysicsEventKind.impact &&
              event.pathIndex <= move.triggerPathIndex,
        )
        .fold<PhysicsEvent?>(
          null,
          (latest, event) =>
              latest == null || event.pathIndex > latest.pathIndex
              ? event
              : latest,
        );
    final event = PhysicsEvent(
      eventId: 'move:$index:${move.entityId}:${move.triggerPathIndex}',
      parentEventId: parent?.eventId,
      kind: PhysicsEventKind.move,
      pathIndex: move.triggerPathIndex,
      sourceEntityId: parent?.targetEntityId ?? 'simulation',
      targetEntityId: move.entityId,
      targetType: parent?.targetType ?? EntityType.ball,
      position: move.impactPosition ?? move.from,
      normal: move.impactNormal ?? Vec2.zero,
      impulse: 0,
      resultingVelocity: _observedVelocity(move.path, 0),
      visualState: move.visualState,
      move: move,
    );
    events.add(event);
  }

  for (var index = 0; index < chainSafetyDiagnostics.length; index++) {
    final diagnostic = chainSafetyDiagnostics[index];
    final parent = events
        .where((event) => event.pathIndex <= diagnostic.pathIndex)
        .fold<PhysicsEvent?>(
          null,
          (latest, event) =>
              latest == null || event.pathIndex > latest.pathIndex
              ? event
              : latest,
        );
    events.add(
      PhysicsEvent(
        eventId: 'diagnostic:chain_safety_stop:$index:${diagnostic.pathIndex}',
        parentEventId: parent?.eventId,
        kind: PhysicsEventKind.chainSafetyStop,
        pathIndex: diagnostic.pathIndex,
        sourceEntityId: parent?.targetEntityId ?? 'simulation',
        targetEntityId: diagnostic.targetEntityId,
        targetType: EntityType.ball,
        position: Vec2.zero,
        normal: Vec2.zero,
        impulse: 0,
        resultingVelocity: Vec2.zero,
        remainingDistance: diagnostic.remainingDistance,
        remainingSpeed: diagnostic.remainingSpeed,
        iterations: diagnostic.iterations,
      ),
    );
  }

  events.sort((left, right) {
    final byPath = left.pathIndex.compareTo(right.pathIndex);
    if (byPath != 0) {
      return byPath;
    }
    final byKind = _physicsEventPriority(
      left.kind,
    ).compareTo(_physicsEventPriority(right.kind));
    if (byKind != 0) {
      return byKind;
    }
    return left.eventId.compareTo(right.eventId);
  });
  return events;
}

int _physicsEventPriority(PhysicsEventKind kind) {
  return switch (kind) {
    PhysicsEventKind.impact => 0,
    PhysicsEventKind.powerSliderActivation => 1,
    PhysicsEventKind.reflectorRotation => 2,
    PhysicsEventKind.stateChange => 3,
    PhysicsEventKind.move => 4,
    PhysicsEventKind.chainSafetyStop => 5,
  };
}

Vec2 _observedVelocity(List<Vec2> points, int index) {
  if (index < 0 || index + 1 >= points.length) {
    return Vec2.zero;
  }
  return points[index + 1] - points[index];
}

Vec2 _impactResultingVelocity(
  List<Vec2> activePath,
  List<ShotAnimationMove> moves,
  List<ReflectorRotation> reflectorRotations,
  ShotImpact impact,
) {
  for (final rotation in reflectorRotations) {
    if (rotation.sourceEntityId == impact.sourceEntityId &&
        rotation.reflectorEntityId == impact.entityId &&
        rotation.pathIndex == impact.pathIndex &&
        rotation.contactId == impact.contactId) {
      return rotation.velocityAfter;
    }
  }
  if (impact.sourceEntityId == 'active_ball') {
    return _observedVelocity(activePath, impact.pathIndex);
  }
  for (final move in moves) {
    if (move.entityId != impact.sourceEntityId || move.path.length < 2) {
      continue;
    }
    var nearestIndex = 0;
    var nearestDistance = double.infinity;
    for (var index = 0; index + 1 < move.path.length; index++) {
      final distance = move.path[index].distanceTo(impact.position);
      if (distance < nearestDistance) {
        nearestIndex = index;
        nearestDistance = distance;
      }
    }
    return _observedVelocity(move.path, nearestIndex);
  }
  return Vec2.zero;
}

class TrajectoryPreview {
  const TrajectoryPreview({
    required this.points,
    this.reflection,
    this.highlightEntityId,
  });

  final List<Vec2> points;
  final List<Vec2>? reflection;
  final String? highlightEntityId;
}

enum FirstArrivalKind { impact, hole, powerSlider, rangeEnd }

/// 쉬움 모드의 조준 보조가 표시할 첫 도착점이다.
///
/// 판정 결과에서 첫 물리 사건만 읽으며 게임 상태나 발사 입력을 변경하지 않는다.
class FirstArrivalPreview {
  const FirstArrivalPreview({
    required this.position,
    required this.pathIndex,
    required this.kind,
    this.entityId,
  });

  final Vec2 position;
  final int pathIndex;
  final FirstArrivalKind kind;
  final String? entityId;
}

class CollisionHit {
  const CollisionHit({
    required this.entity,
    required this.normal,
    this.startsOverlapping = false,
  });

  final EntityState entity;
  final Vec2 normal;
  final bool startsOverlapping;
}

class CollisionSample {
  const CollisionSample({required this.hit, required this.position});

  final CollisionHit hit;
  final Vec2 position;
}

class _MovingEntityCollision {
  const _MovingEntityCollision({
    required this.entity,
    required this.position,
    this.normal,
    this.startsOverlapping = false,
  });

  final EntityState entity;
  final Vec2 position;
  final Vec2? normal;
  final bool startsOverlapping;
}

class _ReflectorSweepHit {
  const _ReflectorSweepHit({
    required this.position,
    required this.normal,
    this.startsOverlapping = false,
  });

  final Vec2 position;
  final Vec2 normal;
  final bool startsOverlapping;
}

const _physicsEpsilon = 0.0001;
// 얇은 OBB의 접선 스침을 놓치지 않도록 반사판 sweep 간격을 고정한다.
const _reflectorSweepLedgerSampleDistance = 0.5;

class _PowerSliderEntry {
  const _PowerSliderEntry({
    required this.slider,
    required this.position,
    required this.progress,
    required this.contactId,
  });

  final EntityState slider;
  final Vec2 position;
  final double progress;
  final String contactId;
}

class _SliderEntryPoint {
  const _SliderEntryPoint({required this.position, required this.progress});

  final Vec2 position;
  final double progress;
}

/// 한 resolve와 그 안에서 재귀로 발생한 전체 연쇄가 공유하는 접촉 원장이다.
/// 경계에 계속 걸린 동안은 재발동하지 않고 완전히 빠져나온 뒤 재진입만 허용한다.
class _SliderContactLedger {
  final Set<String> _inside = <String>{};

  bool isInside(String contactId) => _inside.contains(contactId);

  void markEntered(String contactId) => _inside.add(contactId);

  void markExited(String contactId) => _inside.remove(contactId);
}

class _ReflectorContactLedger {
  final Set<String> _inside = <String>{};

  bool isInside(String contactId) => _inside.contains(contactId);

  void markEntered(String contactId) => _inside.add(contactId);

  void markExited(String contactId) => _inside.remove(contactId);
}

class _OrientedReflector {
  const _OrientedReflector({
    required this.center,
    required this.normal,
    required this.tangent,
    required this.halfNormal,
    required this.halfTangent,
  });

  final Vec2 center;
  final Vec2 normal;
  final Vec2 tangent;
  final double halfNormal;
  final double halfTangent;
}

class _ReflectorContact {
  const _ReflectorContact({required this.point, required this.normal});

  final Vec2 point;
  final Vec2 normal;
}

class _ReflectorSatContact {
  const _ReflectorSatContact({required this.normal, required this.penetration});

  final Vec2 normal;
  final double penetration;
}

class ShotResolver {
  const ShotResolver();

  /// 탄성 속성은 첫 충돌 연출이 아니라 발사 전체에 적용되는 물성이다.
  /// 일반 벽(0.72)과 두 번 이상 반사한 뒤에도 플레이어가 차이를
  /// 눈으로 확인할 수 있도록 모든 벽 충돌에 이 하한을 반복 적용한다.
  static const double bouncyWallRestitutionFloor = 0.88;

  bool canLaunch(GameState state) {
    if (state.phase != GamePhase.planning) return false;
    final ball = state.entityById('active_ball');
    return ball != null &&
        ball.type == EntityType.ball &&
        ball.active &&
        ball.movable &&
        ball.position.x.isFinite &&
        ball.position.y.isFinite;
  }

  ShotResult resolve(GameState state, ShotInput rawInput) {
    final input = rawInput.normalized();
    final beforeShot = state.copyWith(history: const []);
    var entities = [...state.entities, ..._fieldBoundaryEntities()];
    var ball = state.activeBall.copyWith(
      traits: input.equippedTrait == null ? const {} : {input.equippedTrait!},
    );
    var position = ball.position;
    var direction = input.direction;
    final distanceBudget =
        210 +
        (input.power * 520) +
        (ball.traits.contains(TraitType.heavy) ? 95 : 0);
    var speed = 8.0 + input.power * 16.0;
    final movingMass = _massOf(ball);
    final path = <Vec2>[position];
    final events = <String>[];
    final moves = <ShotAnimationMove>[];
    final impacts = <ShotImpact>[];
    final powerSliderActivations = <PowerSliderActivation>[];
    final reflectorRotations = <ReflectorRotation>[];
    final sliderContacts = _SliderContactLedger();
    final reflectorContacts = _ReflectorContactLedger();
    final stateTransitions = <PhysicsStateTransition>[];
    final chainSafetyDiagnostics = <ChainSafetyDiagnostic>[];
    var success = false;
    var stopped = false;
    var previousPosition = position;
    var consumedDistance = 0.0;

    for (
      var traveled = 0.0;
      traveled < distanceBudget && speed > 1.8 && !stopped && !success;
      traveled += consumedDistance
    ) {
      previousPosition = position;
      final attemptedSpeed = speed;
      position = position + direction * attemptedSpeed;
      path.add(position);
      speed *= 0.982;
      consumedDistance = speed;

      final collisionSample = _firstCollisionAlongSegment(
        entities,
        ball,
        previousPosition,
        position,
      );
      final hole = _findHole(entities);
      final holeCaptureRadius = hole == null
          ? 0.0
          : hole.hitRadius + ball.hitRadius;
      final baseHoleProgress = hole == null
          ? double.infinity
          : _segmentCircleEntryProgress(
              previousPosition,
              position,
              hole.position,
              holeCaptureRadius,
            );
      final assistedHoleProgress =
          hole == null ||
              baseHoleProgress.isFinite ||
              input.holeForgivenessRadius <= 0 ||
              attemptedSpeed > 15
          ? double.infinity
          : _assistedHoleEntryProgress(
              previousPosition: previousPosition,
              position: position,
              direction: direction,
              hole: hole,
              captureRadius: holeCaptureRadius + input.holeForgivenessRadius,
            );
      final holeLipAssisted = assistedHoleProgress.isFinite;
      final holeProgress = baseHoleProgress.isFinite
          ? baseHoleProgress
          : assistedHoleProgress;
      final effectiveHoleCaptureRadius = holeLipAssisted
          ? holeCaptureRadius + input.holeForgivenessRadius
          : holeCaptureRadius;
      final collisionProgress = collisionSample == null
          ? double.infinity
          : _segmentProgress(
              previousPosition,
              position,
              collisionSample.position,
            );
      final sliderEntries = _firstPowerSliderEntriesAlongSegment(
        entities,
        ball,
        previousPosition,
        position,
        sliderContacts,
      );
      final sliderProgress = sliderEntries.isEmpty
          ? double.infinity
          : sliderEntries.first.progress;
      if (collisionProgress.isFinite) {
        consumedDistance = attemptedSpeed * collisionProgress;
      }
      if (holeProgress.isFinite &&
          holeProgress <= collisionProgress + _physicsEpsilon &&
          holeProgress <= sliderProgress + _physicsEpsilon) {
        consumedDistance = attemptedSpeed * holeProgress;
      }
      if (sliderProgress.isFinite &&
          sliderProgress < collisionProgress - _physicsEpsilon &&
          sliderProgress < holeProgress - _physicsEpsilon) {
        final entryPosition = sliderEntries.first.position;
        position = entryPosition;
        path[path.length - 1] = position;
        _consumeReflectorSegment(
          entities,
          ball,
          previousPosition,
          entryPosition,
          reflectorContacts,
        );
        final speedBefore = speed;
        final motionDirection = direction.normalized();
        final referenceSpeed = sliderEntries.fold<double>(
          0,
          (maximum, entry) => math.max(maximum, entry.slider.referenceSpeed),
        );
        final speedAfter = math.max(speedBefore, referenceSpeed);
        speed = speedAfter;
        _consumeSliderSegment(
          entities,
          ball,
          previousPosition,
          entryPosition,
          sliderContacts,
          entered: sliderEntries,
        );
        for (final entry in sliderEntries) {
          final activation = PowerSliderActivation(
            sourceEntityId: ball.id,
            sliderEntityId: entry.slider.id,
            contactId: entry.contactId,
            position: entry.position,
            pathIndex: path.length - 1,
            direction: entry.slider.direction,
            motionDirection: motionDirection,
            velocityBefore: motionDirection * speedBefore,
            velocityAfter: motionDirection * speedAfter,
            speedBefore: speedBefore,
            speedAfter: speedAfter,
            referenceSpeed: entry.slider.referenceSpeed,
          );
          powerSliderActivations.add(activation);
          events.add('power_slider_activated');
          if (entry.slider.linkId case final gateId?) {
            entities = _openLinkedEntity(entities, gateId);
            events.add('slider_gate_opened');
          }
        }
        consumedDistance = attemptedSpeed * sliderProgress;
        continue;
      }
      if (hole != null &&
          holeProgress.isFinite &&
          _segmentDistance(previousPosition, position, hole.position) <=
              effectiveHoleCaptureRadius &&
          holeProgress <= collisionProgress + _physicsEpsilon &&
          holeProgress <= sliderProgress + _physicsEpsilon) {
        _consumeReflectorSegment(
          entities,
          ball,
          previousPosition,
          hole.position,
          reflectorContacts,
        );
        _consumeSliderSegment(
          entities,
          ball,
          previousPosition,
          hole.position,
          sliderContacts,
        );
        position = hole.position;
        path[path.length - 1] = position;
        impacts.add(
          ShotImpact(
            entityId: hole.id,
            entityType: EntityType.hole,
            position: position,
            normal: direction * -1,
            pathIndex: path.length - 1,
            strength: 1,
            sourceTraitMask: traitMaskOf(ball.traits),
          ),
        );
        stateTransitions.add(
          PhysicsStateTransition(
            sourceEntityId: ball.id,
            targetEntityId: hole.id,
            targetType: hole.type,
            pathIndex: path.length - 1,
            previousState: 'approaching',
            nextState: 'captured',
            position: position,
            normal: direction * -1,
          ),
        );
        events.add('hole_entered');
        if (holeLipAssisted) events.add('hole_lip_in_assist');
        success = true;
        break;
      }
      if (_anyBallInHole(entities)) {
        _consumeReflectorSegment(
          entities,
          ball,
          previousPosition,
          position,
          reflectorContacts,
        );
        events.add('existing_ball_hole_entered');
        success = true;
        break;
      }
      if (collisionSample == null) {
        _consumeReflectorSegment(
          entities,
          ball,
          previousPosition,
          position,
          reflectorContacts,
        );
        _consumeSliderSegment(
          entities,
          ball,
          previousPosition,
          position,
          sliderContacts,
        );
        continue;
      }
      _consumeSliderSegment(
        entities,
        ball,
        previousPosition,
        collisionSample.position,
        sliderContacts,
      );
      _consumeReflectorSegment(
        entities,
        ball,
        previousPosition,
        collisionSample.position,
        reflectorContacts,
      );
      position = collisionSample.position;
      path[path.length - 1] = position;
      final collision = collisionSample.hit;
      final hit = collision.entity;
      final impactContactId = hit.type == EntityType.rotatingReflector
          ? '${ball.id}:${hit.id}'
          : null;
      final impactVelocity = direction * speed;
      final reflectorRotationQualifies =
          hit.type == EntityType.rotatingReflector &&
          !ball.traits.contains(TraitType.sticky) &&
          impactContactId != null &&
          !reflectorContacts.isInside(impactContactId) &&
          !(collision.startsOverlapping &&
              impactVelocity.dot(collision.normal) >= -_physicsEpsilon);
      impacts.add(
        ShotImpact(
          entityId: hit.id,
          entityType: hit.type,
          position: position,
          normal: collision.normal,
          pathIndex: path.length - 1,
          strength: (speed / 24).clamp(0.18, 1.0),
          relativeNormalSpeed: speed * -collision.normal.dot(direction),
          impulse: ImpactMetrics.normalizedImpulse(
            relativeNormalSpeed: speed * -collision.normal.dot(direction),
            movingMass: movingMass,
            targetMass: _massOf(hit),
          ),
          impactTier: ImpactMetrics.tierFor(
            ImpactMetrics.normalizedImpulse(
              relativeNormalSpeed: speed * -collision.normal.dot(direction),
              movingMass: movingMass,
              targetMass: _massOf(hit),
            ),
          ),
          contactId: impactContactId,
          triggersReflectorRotation: reflectorRotationQualifies,
          sourceTraitMask: traitMaskOf(ball.traits),
        ),
      );
      final contactPosition = position;

      if (hit.type == EntityType.gate && hit.open) {
        continue;
      }

      if (hit.type == EntityType.rotatingReflector) {
        if (ball.traits.contains(TraitType.sticky)) {
          position = _separateFromCollision(
            hit,
            ball,
            position,
            collision.normal,
          );
          path[path.length - 1] = position;
          events.add('sticky_attached');
          stopped = true;
          break;
        }
        final contactId = '${ball.id}:${hit.id}';
        if (reflectorContacts.isInside(contactId)) {
          position = _separateFromCollision(
            hit,
            ball,
            position,
            collision.normal,
          );
          path[path.length - 1] = position;
          _consumeReflectorSegment(
            entities,
            ball,
            contactPosition,
            position,
            reflectorContacts,
          );
          continue;
        }
        final normal = collision.normal;
        final velocityBefore = direction * speed;
        if (collision.startsOverlapping &&
            velocityBefore.dot(normal) >= -_physicsEpsilon) {
          position = _separateFromCollision(hit, ball, position, normal);
          path[path.length - 1] = position;
          reflectorContacts.markEntered(contactId);
          _consumeReflectorSegment(
            entities,
            ball,
            contactPosition,
            position,
            reflectorContacts,
          );
          events.add('reflector_overlap_separated');
          continue;
        }
        final bounced = _reflectorBounceVelocity(
          velocityBefore,
          normal,
          ball,
          hit,
        );
        final beforeOrientation = hit.reflectorOrientation;
        final afterOrientation = (beforeOrientation + 2) % 8;
        final beforeCount = hit.reflectorRotationCount;
        final afterCount = beforeCount + 1;
        position = _separateFromCollision(hit, ball, position, normal);
        path[path.length - 1] = position;
        direction = bounced.length <= 0.001 ? direction : bounced.normalized();
        speed = bounced.length;
        entities = _replace(
          entities,
          hit.copyWith(
            reflectorOrientation: afterOrientation,
            reflectorRotationCount: afterCount,
            visualState: 'rotated',
          ),
        );
        final openedRotationGate = entities.any(
          (entity) =>
              entity.type == EntityType.gate &&
              entity.id.startsWith('rotation_gate') &&
              !entity.open,
        );
        entities = _openReflectorGates(entities);
        reflectorContacts.markEntered(contactId);
        reflectorRotations.add(
          ReflectorRotation(
            sourceEntityId: ball.id,
            reflectorEntityId: hit.id,
            contactId: contactId,
            pathIndex: path.length - 1,
            orientationBefore: beforeOrientation,
            orientationAfter: afterOrientation,
            rotationCountBefore: beforeCount,
            rotationCountAfter: afterCount,
            collisionNormal: normal,
            velocityBefore: velocityBefore,
            velocityAfter: bounced,
          ),
        );
        events.add('reflector_reflected');
        events.add('reflector_rotated');
        if (openedRotationGate) events.add('rotation_gate_opened');
        continue;
      }

      if (hit.type == EntityType.balloon) {
        if (ball.traits.contains(TraitType.sharp)) {
          entities = _replace(
            entities,
            hit.copyWith(active: false, solid: false, visualState: 'popped'),
          );
          final balloonSwitch = _hiddenMechanicLinkedFrom(entities, hit);
          stateTransitions.add(
            PhysicsStateTransition(
              sourceEntityId: hit.id,
              targetEntityId: hit.id,
              targetType: hit.type,
              pathIndex: path.length - 1,
              previousState: hit.visualState,
              nextState: 'popped',
              position: contactPosition,
              normal: collision.normal,
            ),
          );
          if (balloonSwitch != null) {
            entities = _replace(
              entities,
              balloonSwitch.copyWith(
                solid: true,
                visualState: HiddenMechanicState.revealed,
              ),
            );
            stateTransitions.add(
              PhysicsStateTransition(
                sourceEntityId: hit.id,
                targetEntityId: balloonSwitch.id,
                targetType: balloonSwitch.type,
                pathIndex: path.length - 1,
                previousState: balloonSwitch.visualState,
                nextState: HiddenMechanicState.revealed,
                position: balloonSwitch.position,
                normal: collision.normal,
              ),
            );
            moves.add(
              ShotAnimationMove(
                entityId: balloonSwitch.id,
                from: balloonSwitch.position,
                to: balloonSwitch.position,
                triggerPathIndex: path.length,
                visualState: HiddenMechanicState.opening,
                impactPosition: contactPosition,
                impactNormal: collision.normal,
              ),
            );
            moves.add(
              ShotAnimationMove(
                entityId: balloonSwitch.id,
                from: balloonSwitch.position,
                to: balloonSwitch.position,
                triggerPathIndex: path.length + 6,
                visualState: HiddenMechanicState.revealed,
                impactPosition: contactPosition,
                impactNormal: collision.normal,
              ),
            );
          }
          moves.add(
            ShotAnimationMove(
              entityId: hit.id,
              from: hit.position,
              to: hit.position,
              triggerPathIndex: path.length - 1,
              visualState: 'popped',
              impactPosition: contactPosition,
              impactNormal: collision.normal,
            ),
          );
          ball = ball.copyWith(
            traits: {...ball.traits}..remove(TraitType.sharp),
          );
          stateTransitions.add(
            PhysicsStateTransition(
              sourceEntityId: hit.id,
              targetEntityId: ball.id,
              targetType: ball.type,
              pathIndex: path.length - 1,
              previousState: TraitType.sharp.name,
              nextState: 'sharpness_consumed',
              position: contactPosition,
              normal: collision.normal,
            ),
          );
          events.add('balloon_popped');
          events.add('sharpness_consumed');
          if (balloonSwitch != null) {
            events.add('balloon_switch_revealed');
          }
          speed *= 0.86;
          continue;
        }
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        final bouncedVelocity = _wallBounceVelocity(
          direction * speed,
          collision.normal,
          ball,
          hit,
        );
        direction = bouncedVelocity.normalized();
        speed = bouncedVelocity.length;
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'pressed',
            impactPosition: contactPosition,
            impactNormal: collision.normal,
          ),
        );
        events.add('balloon_bounced');
        continue;
      }

      if (ball.traits.contains(TraitType.sticky) &&
          hit.type != EntityType.stickySurface &&
          hit.type != EntityType.hole) {
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        stateTransitions.add(
          PhysicsStateTransition(
            sourceEntityId: ball.id,
            targetEntityId: ball.id,
            targetType: ball.type,
            pathIndex: path.length - 1,
            previousState: ball.visualState,
            nextState: 'stuck',
            position: position,
            normal: collision.normal,
          ),
        );
        events.add('sticky_attached');
        stopped = true;
        break;
      }

      if (hit.type == EntityType.switchPad) {
        final isBalloonSwitch = hit.id == 'balloon_switch';
        final acceptsAnyBall =
            isBalloonSwitch ||
            hit.visualState == HiddenMechanicState.revealed ||
            hit.id.startsWith('sequence_switch_');
        if (!acceptsAnyBall && !ball.traits.contains(TraitType.heavy)) {
          position = _separateFromCollision(
            hit,
            ball,
            position,
            collision.normal,
          );
          path[path.length - 1] = position;
          events.add('switch_rejected');
          direction = _reflect(direction, collision.normal);
          speed *= 0.42;
          continue;
        }
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'pressed',
            impactPosition: position,
            impactNormal: collision.normal,
          ),
        );
        final linkedGates = hit.linkId == null
            ? entities.where((entity) => entity.type == EntityType.gate)
            : entities.where((entity) => entity.id == hit.linkId);
        for (final gate in linkedGates) {
          moves.add(
            ShotAnimationMove(
              entityId: gate.id,
              from: gate.position,
              to: gate.position,
              triggerPathIndex: path.length + 2,
              visualState: 'opening',
            ),
          );
        }
        entities = _replace(
          entities,
          hit.copyWith(pressed: true, solid: false, visualState: 'pressed'),
        );
        entities = hit.linkId == null
            ? _openGates(entities)
            : _openLinkedEntity(entities, hit.linkId!);
        stateTransitions.add(
          PhysicsStateTransition(
            sourceEntityId: ball.id,
            targetEntityId: hit.id,
            targetType: hit.type,
            pathIndex: path.length - 1,
            previousState: hit.visualState,
            nextState: 'pressed',
            position: position,
            normal: collision.normal,
          ),
        );
        for (final gate in linkedGates) {
          stateTransitions.add(
            PhysicsStateTransition(
              sourceEntityId: hit.id,
              targetEntityId: gate.id,
              targetType: gate.type,
              pathIndex: path.length - 1,
              previousState: gate.visualState,
              nextState: 'open',
              position: gate.position,
              normal: collision.normal,
            ),
          );
        }
        events.add('switch_pressed');
        if (isBalloonSwitch) {
          events.add('balloon_switch_pressed');
        }
        speed *= 0.82;
        continue;
      }

      if (hit.type == EntityType.stickySurface &&
          hit.traits.contains(TraitType.sticky) &&
          (hit.linkId == null || ball.traits.contains(TraitType.sticky))) {
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        entities = _replace(entities, hit.copyWith(visualState: 'stuck'));
        if (hit.linkId case final gateId?) {
          entities = _openLinkedEntity(entities, gateId);
          events.add('sticky_gate_opened');
        }
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'stuck',
            impactPosition: contactPosition,
            impactNormal: collision.normal,
          ),
        );
        events.add('sticky_attached');
        stopped = true;
        break;
      }

      if (ball.traits.contains(TraitType.sticky) &&
          (hit.type == EntityType.wall ||
              hit.type == EntityType.crate ||
              hit.type == EntityType.ball)) {
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        events.add('sticky_attached');
        stopped = true;
        break;
      }

      if (hit.type == EntityType.crate) {
        final heavy = ball.traits.contains(TraitType.heavy);
        if (heavy || input.power >= 0.55) {
          final impactSpeedRatio = (speed / (8.0 + input.power * 16.0)).clamp(
            0.25,
            1.0,
          );
          final impulseScale = ((0.35 + input.power * 0.65) * impactSpeedRatio)
              .clamp(0.25, 1.0);
          final beforePush = hit.position;
          entities = _pushWithMomentum(
            entities,
            hit,
            direction,
            (heavy ? 42 : 24) + (heavy ? 100 : 60) * impulseScale,
            events,
            moves,
            path.length - 1,
            collision.normal,
            0,
            heavy,
            const {},
            impacts,
            chainSafetyDiagnostics,
            stateTransitions,
            sliderContacts,
            powerSliderActivations,
            reflectorContacts,
            reflectorRotations,
          );
          final pushedCrate =
              entities
                  .firstWhere((entity) => entity.id == hit.id)
                  .position
                  .distanceTo(beforePush) >
              0.01;
          if (pushedCrate) {
            events.add('crate_pushed');
          } else {
            events.add('crate_blocked');
          }
          speed *= (heavy ? 0.78 : 0.56) * _restitutionMultiplier(ball, hit);
          if (_anyBallInHole(entities) ||
              _anyBallMoveEnteredHole(entities, moves)) {
            events.add('existing_ball_hole_entered');
            success = true;
            break;
          }
          position = _separateFromCollision(
            hit,
            ball,
            position,
            collision.normal,
          );
          path[path.length - 1] = position;
          direction = _postImpactDirection(
            direction,
            collision.normal,
            movingMass,
            _massOf(hit),
          );
          continue;
        }
        events.add('crate_blocked');
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        direction = _reflect(direction, collision.normal);
        speed *= 0.62;
        events.add('bounced');
        continue;
      }

      if (hit.type == EntityType.ball && !hit.movable) {
        // 점착으로 고정된 과거 공도 실제 충돌 대상이다. 정지한 물체를
        // 통과시키거나 단순히 멈추게 하지 않고, 벽과 같은 고정 장애물로
        // 취급해 접촉 법선에 따라 발사 공을 반사한다.
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'spent_ball_hit',
            impactPosition: contactPosition,
            impactNormal: collision.normal,
          ),
        );
        final bouncedVelocity = _wallBounceVelocity(
          direction * speed,
          collision.normal,
          ball,
          hit,
        );
        direction = bouncedVelocity.normalized();
        speed = bouncedVelocity.length;
        events.add('bounced');
        events.add('spent_ball_bounced');
        continue;
      }

      if (hit.type == EntityType.ball && hit.movable) {
        final targetMass = _massOf(hit);
        final transferRatio = (movingMass * 2 / (movingMass + targetMass))
            .clamp(0.35, 2.4);
        entities = _pushWithMomentum(
          entities,
          hit,
          direction,
          (54 + input.power * 58) * transferRatio,
          events,
          moves,
          path.length - 1,
          collision.normal,
          0,
          ball.traits.contains(TraitType.heavy),
          const {},
          impacts,
          chainSafetyDiagnostics,
          stateTransitions,
          sliderContacts,
          powerSliderActivations,
          reflectorContacts,
          reflectorRotations,
        );
        if (_anyBallInHole(entities) ||
            _anyBallMoveEnteredHole(entities, moves)) {
          events.add('existing_ball_hole_entered');
          success = true;
          break;
        }
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        final equalMassHeadOn =
            (movingMass - targetMass).abs() < 0.05 &&
            collision.normal.dot(direction) < -0.9;
        if (equalMassHeadOn) {
          speed = 0;
          stopped = true;
          events.add('equal_mass_exchange');
          events.add('momentum_transfer');
          break;
        }
        direction = _postImpactDirection(
          direction,
          collision.normal,
          movingMass,
          targetMass,
        );
        speed *=
            _postImpactSpeedFactor(movingMass, targetMass) *
            _restitutionMultiplier(ball, hit);
        events.add('momentum_transfer');
        continue;
      }

      if (hit.type == EntityType.bumper &&
          hit.traits.contains(TraitType.bouncy)) {
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'pushed',
            impactPosition: contactPosition,
            impactNormal: collision.normal,
          ),
        );
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        direction = _reflect(direction, collision.normal);
        speed *= 0.72 * _restitutionMultiplier(ball, hit);
        events.add('jelly_bounced');
        continue;
      }

      if (hit.movable && hit.type != EntityType.wall) {
        final impactSpeedRatio = (speed / (8.0 + input.power * 16.0)).clamp(
          0.25,
          1.0,
        );
        final impulseScale = ((0.35 + input.power * 0.65) * impactSpeedRatio)
            .clamp(0.25, 1.0);
        final targetMass = _massOf(hit);
        final transferRatio = (movingMass * 2 / (movingMass + targetMass))
            .clamp(0.35, 2.4);
        entities = _pushWithMomentum(
          entities,
          hit,
          direction,
          (24 + 52 * impulseScale) * transferRatio,
          events,
          moves,
          path.length - 1,
          collision.normal,
          0,
          ball.traits.contains(TraitType.heavy),
          const {},
          impacts,
          chainSafetyDiagnostics,
          stateTransitions,
          sliderContacts,
          powerSliderActivations,
          reflectorContacts,
          reflectorRotations,
        );
        if (_anyBallInHole(entities) ||
            _anyBallMoveEnteredHole(entities, moves)) {
          events.add('existing_ball_hole_entered');
          success = true;
          break;
        }
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        direction = _reflect(direction, collision.normal);
        speed *= 0.68 * _restitutionMultiplier(ball, hit);
        events.add('momentum_transfer');
        continue;
      }

      if (hit.type == EntityType.wall || hit.type == EntityType.gate) {
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'wall_hit',
            impactPosition: contactPosition,
            impactNormal: collision.normal,
          ),
        );
        final bouncedVelocity = _wallBounceVelocity(
          direction * speed,
          collision.normal,
          ball,
          hit,
        );
        direction = bouncedVelocity.normalized();
        speed = bouncedVelocity.length;
        events.add('bounced');
        continue;
      }

      if (hit.type == EntityType.weight) {
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        direction = _postImpactDirection(
          direction,
          collision.normal,
          movingMass,
          _massOf(hit),
        );
        speed *=
            _postImpactSpeedFactor(movingMass, _massOf(hit)) *
            0.82 *
            _restitutionMultiplier(ball, hit);
        events.add('bounced');
        continue;
      }

      if (hit.type == EntityType.hole) {
        stopped = true;
        break;
      }

      if (ball.traits.contains(TraitType.bouncy)) {
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        direction = _reflect(direction, collision.normal);
        speed *= 0.88 * _restitutionMultiplier(ball, hit);
        events.add('bounced');
        continue;
      }

      events.add('blocked_by_${hit.type.name}');
      stopped = true;
    }

    // 거리 예산 또는 저속 임계점에서 자연스럽게 끝난 샷은 마지막 위치에서
    // 즉시 정지시키지 않는다. 마지막 실제 이동 구간을 점점 짧아지는 조각으로
    // 나눠 여러 프레임에 걸쳐 0으로 수렴하게 한다. 끝점은 물리 결과와 같으므로
    // 애니메이션 종료 뒤 공이 되돌아가는 현상도 만들지 않는다.
    final animationPath = [...path];
    if (!success && !stopped && path.length >= 2) {
      final start = path[path.length - 2];
      final end = path.last;
      if (start.distanceTo(end) > 0.3) {
        animationPath.removeLast();
        for (final progress in const [
          0.32,
          0.55,
          0.72,
          0.84,
          0.91,
          0.955,
          0.98,
          0.992,
          0.997,
          0.999,
          1.0,
        ]) {
          animationPath.add(start + (end - start) * progress);
        }
      }
    }

    if (success &&
        events.contains('existing_ball_hole_entered') &&
        !impacts.any((impact) => impact.entityType == EntityType.hole)) {
      final hole = _findHole(entities);
      final capturedBall = hole == null
          ? null
          : _existingBallAtHole(entities, moves, hole);
      if (hole != null && capturedBall != null) {
        final capturePathIndex = moves
            .where((move) => move.entityId == capturedBall.id)
            .fold<int>(
              path.length - 1,
              (latest, move) => math.max(latest, move.triggerPathIndex),
            );
        impacts.add(
          ShotImpact(
            entityId: hole.id,
            entityType: EntityType.hole,
            position: hole.position,
            normal: Vec2.zero,
            pathIndex: capturePathIndex,
            strength: 1,
            sourceEntityId: capturedBall.id,
            sourceTraitMask: traitMaskOf(capturedBall.traits),
          ),
        );
        stateTransitions.add(
          PhysicsStateTransition(
            sourceEntityId: capturedBall.id,
            targetEntityId: hole.id,
            targetType: hole.type,
            pathIndex: capturePathIndex,
            previousState: capturedBall.visualState,
            nextState: 'captured',
            position: hole.position,
            normal: Vec2.zero,
          ),
        );
      }
    }

    final landedBall = ball.copyWith(
      id: 'spent_ball_${state.shotCount + 1}',
      position: position,
      traits: ball.traits,
      movable: !events.contains('sticky_attached'),
      hitboxScale: ball.hitboxScale,
      visualState: success
          ? 'scored'
          : events.contains('sticky_attached')
          ? 'stuck'
          : 'spent',
    );
    final activeBall = EntityState(
      id: 'active_ball',
      type: EntityType.ball,
      position: state.ballSpawn,
      size: ball.size,
      traits: ball.traits,
      movable: true,
      visualState: 'ready',
    );

    entities = [
      for (final entity in entities)
        if (entity.id != state.activeBall.id &&
            !entity.id.startsWith('field_boundary_'))
          entity,
      landedBall,
      if (!success) activeBall,
    ];

    if (!success) {
      if (input.power < 0.4) {
        events.add('power_low');
      } else if (input.power > 0.88) {
        events.add('power_high');
      }
    }

    final next = state.copyWith(
      entities: entities,
      phase: success ? GamePhase.success : GamePhase.planning,
      shotCount: state.shotCount + 1,
      score: math.max(0, state.score - 75),
      clearSelection: true,
      clearEquippedTrait: !success || events.contains('sharpness_consumed'),
      message: success ? '홀 진입 성공!' : _messageFor(events),
      history: [beforeShot, ...state.history],
    );

    return ShotResult(
      state: next,
      path: path,
      animationPath: animationPath.length == path.length
          ? const []
          : animationPath,
      events: events,
      moves: moves,
      impacts: impacts,
      physicsEvents: buildPhysicsEvents(
        path: path,
        impacts: impacts,
        moves: moves,
        chainSafetyDiagnostics: chainSafetyDiagnostics,
        stateTransitions: stateTransitions,
        powerSliderActivations: powerSliderActivations,
        reflectorRotations: reflectorRotations,
      ),
      chainSafetyDiagnostics: chainSafetyDiagnostics,
      powerSliderActivations: powerSliderActivations,
      reflectorRotations: reflectorRotations,
    );
  }

  TrajectoryPreview preview(GameState state) {
    final ball = state.activeBall.copyWith(
      traits: state.equippedTrait == null ? const {} : {state.equippedTrait!},
    );
    final direction = state.aimDirection.normalized();
    final power = state.aimPower.clamp(0, 1);
    var position = ball.position;
    final points = <Vec2>[position];
    EntityState? hit;

    for (var traveled = 0.0; traveled < 130 + power * 260; traveled += 12) {
      position = position + direction * 12;
      points.add(position);
      final collision = _firstCollision(
        [...state.entities, ..._fieldBoundaryEntities()],
        ball,
        position,
      );
      hit = collision?.entity;
      if (hit != null) {
        break;
      }
    }

    List<Vec2>? reflection;
    if (state.equippedTrait == TraitType.bouncy && hit != null) {
      final reflected = _reflect(
        direction,
        _collisionNormal(ball, hit, position),
      );
      reflection = [position, position + reflected * 72];
    }

    String? highlight;
    if (state.equippedTrait == TraitType.heavy &&
        hit?.type == EntityType.crate) {
      highlight = hit!.id;
    }
    if (state.equippedTrait == TraitType.sticky && hit != null) {
      highlight = hit.id;
    }

    return TrajectoryPreview(
      points: points,
      reflection: reflection,
      highlightEntityId: highlight,
    );
  }

  /// 실제 발사 판정과 같은 규칙으로 첫 충돌·홀 진입·파워 슬라이더 진입을
  /// 찾는다. 아무 사건도 없으면 사거리 끝을 반환한다.
  FirstArrivalPreview firstArrival(GameState state, ShotInput rawInput) {
    return firstArrivalFromResult(resolve(state, rawInput));
  }

  /// 조준 보정 후보를 좁히기 위한 첫 도착 전용 탐색이다. 이 결과만으로
  /// 보정을 확정하지 않으며, 선택 후보는 반드시 [resolve]로 다시 검증한다.
  FirstArrivalPreview quickFirstArrival(GameState state, ShotInput rawInput) {
    final input = rawInput.normalized();
    final ball = state.activeBall.copyWith(
      traits: input.equippedTrait == null ? const {} : {input.equippedTrait!},
    );
    final direction = input.direction.normalized();
    final power = input.power.clamp(0, 1).toDouble();
    final entities = [...state.entities, ..._fieldBoundaryEntities()];
    final maxDistance = 130 + power * 260;
    final from = ball.position;
    final to = from + direction * maxDistance;
    var bestProgress = double.infinity;
    EntityState? bestEntity;
    var bestKind = FirstArrivalKind.rangeEnd;
    for (final entity in entities) {
      if (!entity.active || entity.id == ball.id) continue;
      var progress = double.infinity;
      var kind = FirstArrivalKind.impact;
      if (entity.type == EntityType.hole) {
        final captureRadius =
            entity.hitRadius +
            ball.hitRadius * 0.85 +
            input.holeForgivenessRadius;
        progress = _assistedHoleEntryProgress(
          previousPosition: from,
          position: to,
          direction: direction,
          hole: entity,
          captureRadius: captureRadius,
        );
        kind = FirstArrivalKind.hole;
      } else if (entity.type == EntityType.powerSlider) {
        progress = _segmentBoundsEntryProgress(
          from,
          to,
          entity.hitBounds,
          padding: ball.hitRadius,
        );
        kind = FirstArrivalKind.powerSlider;
      } else if (_isSolidForPhysics(entity) &&
          !(entity.type == EntityType.gate && entity.open)) {
        progress = entity.isCircle
            ? _segmentCircleEntryProgress(
                from,
                to,
                entity.position,
                ball.hitRadius + entity.hitRadius,
              )
            : _segmentBoundsEntryProgress(
                from,
                to,
                entity.hitBounds,
                padding: ball.hitRadius,
              );
      }
      if (!progress.isFinite) continue;
      if (progress < bestProgress - 0.000001 ||
          ((progress - bestProgress).abs() <= 0.000001 &&
              (bestEntity == null || entity.id.compareTo(bestEntity.id) < 0))) {
        bestProgress = progress;
        bestEntity = entity;
        bestKind = kind;
      }
    }
    if (bestEntity != null) {
      final position = from + (to - from) * bestProgress;
      return FirstArrivalPreview(
        position: position,
        pathIndex: math.max(1, (bestProgress * maxDistance / 2).ceil()),
        kind: bestKind,
        entityId: bestEntity.id,
      );
    }
    return FirstArrivalPreview(
      position: to,
      pathIndex: math.max(1, (maxDistance / 2).ceil()),
      kind: FirstArrivalKind.rangeEnd,
    );
  }

  double _segmentBoundsEntryProgress(
    Vec2 from,
    Vec2 to,
    Bounds bounds, {
    double padding = 0,
  }) {
    final delta = to - from;
    final left = bounds.left - padding;
    final right = bounds.right + padding;
    final top = bounds.top - padding;
    final bottom = bounds.bottom + padding;
    var minimum = 0.0;
    var maximum = 1.0;

    bool clip(double origin, double direction, double low, double high) {
      if (direction.abs() <= _physicsEpsilon) {
        return origin >= low && origin <= high;
      }
      var first = (low - origin) / direction;
      var second = (high - origin) / direction;
      if (first > second) {
        final swap = first;
        first = second;
        second = swap;
      }
      minimum = math.max(minimum, first);
      maximum = math.min(maximum, second);
      return minimum <= maximum;
    }

    if (!clip(from.x, delta.x, left, right) ||
        !clip(from.y, delta.y, top, bottom)) {
      return double.infinity;
    }
    return minimum >= 0 && minimum <= 1 ? minimum : double.infinity;
  }

  double _assistedHoleEntryProgress({
    required Vec2 previousPosition,
    required Vec2 position,
    required Vec2 direction,
    required EntityState hole,
    required double captureRadius,
  }) {
    final progress = _segmentCircleEntryProgress(
      previousPosition,
      position,
      hole.position,
      captureRadius,
    );
    if (!progress.isFinite) return double.infinity;
    final segment = position - previousPosition;
    final entry = previousPosition + segment * progress;
    final toHole = hole.position - entry;
    if (toHole.length <= 0.001) return progress;
    final inwardAlignment = direction.normalized().dot(toHole.normalized());
    return inwardAlignment >= 0.28 ? progress : double.infinity;
  }

  /// 조준 보조와 첫 충돌 보상이 같은 판정 결과를 공유할 수 있게 한다.
  /// 실제 발사는 이 캐시를 사용하지 않고 [resolve]를 다시 실행한다.
  FirstArrivalPreview firstArrivalFromResult(ShotResult result) {
    ShotImpact? impact;
    for (final candidate in result.impacts) {
      if (impact == null || candidate.pathIndex < impact.pathIndex) {
        impact = candidate;
      }
    }
    PowerSliderActivation? slider;
    for (final candidate in result.powerSliderActivations) {
      if (slider == null || candidate.pathIndex < slider.pathIndex) {
        slider = candidate;
      }
    }

    if (impact != null &&
        (slider == null || impact.pathIndex <= slider.pathIndex)) {
      return FirstArrivalPreview(
        position: impact.position,
        pathIndex: impact.pathIndex,
        kind: impact.entityType == EntityType.hole
            ? FirstArrivalKind.hole
            : FirstArrivalKind.impact,
        entityId: impact.entityId,
      );
    }
    if (slider != null) {
      return FirstArrivalPreview(
        position: slider.position,
        pathIndex: slider.pathIndex,
        kind: FirstArrivalKind.powerSlider,
        entityId: slider.sliderEntityId,
      );
    }
    return FirstArrivalPreview(
      position: result.path.last,
      pathIndex: result.path.length - 1,
      kind: FirstArrivalKind.rangeEnd,
    );
  }

  GameState rewind(GameState state) {
    if (state.history.isEmpty) {
      return state.copyWith(message: '되감기할 발사가 없습니다.');
    }
    return state.history.first.copyWith(
      message: '직전 발사 전 상태로 되감았습니다.',
      history: state.history.skip(1).toList(),
    );
  }

  EntityState? _findHole(List<EntityState> entities) {
    for (final entity in entities) {
      if (entity.type == EntityType.hole) {
        return entity;
      }
    }
    return null;
  }

  bool _anyBallInHole(List<EntityState> entities) {
    final hole = _findHole(entities);
    if (hole == null) {
      return false;
    }
    return entities.any((entity) {
      if (entity.type != EntityType.ball || !entity.active) {
        return false;
      }
      if (entity.id == 'active_ball') {
        return false;
      }
      return entity.position.distanceTo(hole.position) <=
          hole.hitRadius + entity.hitRadius * 0.85;
    });
  }

  EntityState? _existingBallAtHole(
    List<EntityState> entities,
    List<ShotAnimationMove> moves,
    EntityState hole,
  ) {
    for (final entity in entities) {
      if (entity.type == EntityType.ball &&
          entity.id != 'active_ball' &&
          entity.active &&
          entity.position.distanceTo(hole.position) <=
              hole.hitRadius + entity.hitRadius * 0.85) {
        return entity;
      }
    }
    for (final move in moves.reversed) {
      final entity = _entityById(entities, move.entityId);
      if (entity == null || entity.type != EntityType.ball) {
        continue;
      }
      final points = move.path.length >= 2 ? move.path : [move.from, move.to];
      final tolerance = hole.hitRadius + entity.hitRadius * 0.85;
      for (var index = 1; index < points.length; index++) {
        if (_segmentDistance(points[index - 1], points[index], hole.position) <=
            tolerance) {
          return entity;
        }
      }
    }
    return null;
  }

  bool _anyBallMoveEnteredHole(
    List<EntityState> entities,
    List<ShotAnimationMove> moves,
  ) {
    final hole = _findHole(entities);
    if (hole == null) {
      return false;
    }
    for (final move in moves) {
      final entity = entities.firstWhere(
        (entity) => entity.id == move.entityId,
        orElse: () => EntityState(
          id: move.entityId,
          type: EntityType.wall,
          position: move.to,
          size: const Vec2(1, 1),
        ),
      );
      if (entity.type != EntityType.ball) {
        continue;
      }
      final points = move.path.length >= 2 ? move.path : [move.from, move.to];
      final tolerance = hole.hitRadius + entity.hitRadius * 0.85;
      for (var index = 1; index < points.length; index++) {
        if (_segmentDistance(points[index - 1], points[index], hole.position) <=
            tolerance) {
          return true;
        }
      }
    }
    return false;
  }

  CollisionHit? _firstCollision(
    List<EntityState> entities,
    EntityState ball,
    Vec2 position,
  ) {
    CollisionHit? best;
    var bestMetric = double.infinity;
    for (final entity in entities) {
      if (entity.id == ball.id ||
          !entity.active ||
          !_isSolidForPhysics(entity)) {
        continue;
      }
      if (entity.type == EntityType.gate && entity.open) {
        continue;
      }
      if (entity.isCircle) {
        if (position.distanceTo(entity.position) <=
            ball.hitRadius + entity.hitRadius) {
          final candidate = CollisionHit(
            entity: entity,
            normal: (position - entity.position).normalized(),
          );
          final metric = position.distanceTo(entity.position);
          if (_isEarlierCollision(candidate, metric, best, bestMetric)) {
            best = candidate;
            bestMetric = metric;
          }
        }
      } else if (entity.hitBounds.intersectsCircle(position, ball.hitRadius)) {
        final candidate = CollisionHit(
          entity: entity,
          normal: _rectNormal(entity.hitBounds, position),
        );
        final metric = position.distanceTo(
          entity.hitBounds.nearestPoint(position),
        );
        if (_isEarlierCollision(candidate, metric, best, bestMetric)) {
          best = candidate;
          bestMetric = metric;
        }
      }
    }
    return best;
  }

  List<EntityState> _fieldBoundaryEntities() {
    return [
      EntityState(
        id: 'field_boundary_top',
        type: EntityType.wall,
        position: Vec2(logicalSize.x / 2, -12),
        size: Vec2(logicalSize.x + 48, 24),
        hitboxScale: 1,
        movable: false,
      ),
      EntityState(
        id: 'field_boundary_bottom',
        type: EntityType.wall,
        position: Vec2(logicalSize.x / 2, logicalSize.y + 12),
        size: Vec2(logicalSize.x + 48, 24),
        hitboxScale: 1,
        movable: false,
      ),
      EntityState(
        id: 'field_boundary_left',
        type: EntityType.wall,
        position: Vec2(-12, logicalSize.y / 2),
        size: Vec2(24, logicalSize.y + 48),
        hitboxScale: 1,
        movable: false,
      ),
      EntityState(
        id: 'field_boundary_right',
        type: EntityType.wall,
        position: Vec2(logicalSize.x + 12, logicalSize.y / 2),
        size: Vec2(24, logicalSize.y + 48),
        hitboxScale: 1,
        movable: false,
      ),
    ];
  }

  CollisionSample? _firstCollisionAlongSegment(
    List<EntityState> entities,
    EntityState ball,
    Vec2 from,
    Vec2 to,
  ) {
    final distance = from.distanceTo(to);
    final steps = math.max(1, (distance / 1.25).ceil());
    CollisionSample? reflectorCandidate;
    var reflectorProgress = double.infinity;
    for (final entity in entities) {
      if (entity.type != EntityType.rotatingReflector ||
          !_isCollisionCandidate(entity, ball.id)) {
        continue;
      }
      final swept = _firstReflectorSweepHit(ball, entity, from, to);
      if (swept == null) continue;
      final candidateProgress = _segmentProgress(from, to, swept.position);
      if (reflectorCandidate == null ||
          candidateProgress < reflectorProgress - _physicsEpsilon ||
          (candidateProgress - reflectorProgress).abs() <= _physicsEpsilon &&
              entity.id.compareTo(reflectorCandidate.hit.entity.id) < 0) {
        reflectorCandidate = CollisionSample(
          hit: CollisionHit(
            entity: entity,
            normal: swept.normal,
            startsOverlapping: swept.startsOverlapping,
          ),
          position: swept.position,
        );
        reflectorProgress = candidateProgress;
      }
    }
    var previous = from;
    for (var step = 1; step <= steps; step++) {
      final progress = step / steps;
      final position = Vec2(
        from.x + (to.x - from.x) * progress,
        from.y + (to.y - from.y) * progress,
      );
      CollisionHit? bestHit;
      Vec2? bestPosition;
      var bestProgress = double.infinity;
      for (final entity in entities) {
        if (!_isCollisionCandidate(entity, ball.id)) {
          continue;
        }
        if (entity.type == EntityType.rotatingReflector) {
          continue;
        }
        if (!_collidesAt(ball, entity, position)) {
          continue;
        }
        var low = previous;
        var high = position;
        if (_collidesAt(ball, entity, low)) {
          high = low;
        } else {
          for (var iteration = 0; iteration < 8; iteration++) {
            final middle = Vec2((low.x + high.x) / 2, (low.y + high.y) / 2);
            if (_collidesAt(ball, entity, middle)) {
              high = middle;
            } else {
              low = middle;
            }
          }
        }
        final candidateProgress = _segmentProgress(from, to, high);
        var candidateNormal = _collisionNormal(ball, entity, high);
        if (entity.type == EntityType.rotatingReflector &&
            candidateNormal.dot(to - from) > 0) {
          candidateNormal = -candidateNormal;
        }
        final candidate = CollisionHit(entity: entity, normal: candidateNormal);
        if (bestHit == null ||
            candidateProgress < bestProgress - 0.0001 ||
            (candidateProgress - bestProgress).abs() <= 0.0001 &&
                entity.id.compareTo(bestHit.entity.id) < 0) {
          bestHit = candidate;
          bestPosition = high;
          bestProgress = candidateProgress;
        }
      }
      if (bestHit != null && bestPosition != null) {
        if (reflectorCandidate != null &&
            (reflectorProgress < bestProgress - _physicsEpsilon ||
                (reflectorProgress - bestProgress).abs() <= _physicsEpsilon &&
                    reflectorCandidate.hit.entity.id.compareTo(
                          bestHit.entity.id,
                        ) <
                        0)) {
          return reflectorCandidate;
        }
        return CollisionSample(hit: bestHit, position: bestPosition);
      }
      previous = position;
    }
    return reflectorCandidate;
  }

  /// 반사판만 연속 swept로 판정한다. 원형 이동체는 OBB의 두 면 띠와
  /// 네 모서리 원을, 사각 이동체는 OBB/AABB의 4개 SAT 축을 사용한다.
  _ReflectorSweepHit? _firstReflectorSweepHit(
    EntityState mover,
    EntityState reflector,
    Vec2 from,
    Vec2 to,
  ) {
    final shape = _orientedReflector(reflector);
    final delta = to - from;
    final startMover = mover.copyWith(position: from);
    if (_orientedReflectorOverlaps(reflector, startMover)) {
      final normal = mover.isCircle
          ? _reflectorContact(reflector, from).normal
          : _reflectorAabbSatContact(reflector, startMover)?.normal ??
                _reflectorSeparationNormal(reflector, from);
      return _ReflectorSweepHit(
        position: from,
        normal: normal,
        startsOverlapping: true,
      );
    }
    final localFrom = Vec2(
      (from - shape.center).dot(shape.tangent),
      (from - shape.center).dot(shape.normal),
    );
    final localDelta = Vec2(delta.dot(shape.tangent), delta.dot(shape.normal));
    double? earliest;

    if (mover.isCircle) {
      final radius = mover.hitRadius;
      for (final interval in [
        _segmentAabbEntry(
          localFrom,
          localDelta,
          -shape.halfTangent - radius,
          shape.halfTangent + radius,
          -shape.halfNormal,
          shape.halfNormal,
        ),
        _segmentAabbEntry(
          localFrom,
          localDelta,
          -shape.halfTangent,
          shape.halfTangent,
          -shape.halfNormal - radius,
          shape.halfNormal + radius,
        ),
      ]) {
        if (interval != null) {
          earliest = earliest == null ? interval : math.min(earliest, interval);
        }
      }
      for (final corner in [
        Vec2(shape.halfTangent, shape.halfNormal),
        Vec2(-shape.halfTangent, shape.halfNormal),
        Vec2(-shape.halfTangent, -shape.halfNormal),
        Vec2(shape.halfTangent, -shape.halfNormal),
      ]) {
        final interval = _segmentCircleEntry(
          localFrom,
          localDelta,
          corner,
          radius,
        );
        if (interval != null) {
          earliest = earliest == null ? interval : math.min(earliest, interval);
        }
      }
    } else {
      final axes = [
        shape.normal,
        shape.tangent,
        const Vec2(1, 0),
        const Vec2(0, 1),
      ];
      final centerDelta = mover.position - shape.center;
      var entry = 0.0;
      var exit = 1.0;
      for (final axis in axes) {
        final reflectorRadius =
            shape.halfNormal * axis.dot(shape.normal).abs() +
            shape.halfTangent * axis.dot(shape.tangent).abs();
        final moverRadius = _aabbSupportRadius(mover, axis);
        final interval = _sweptAxisRange(
          centerDelta.dot(axis),
          delta.dot(axis),
          -reflectorRadius - moverRadius,
          reflectorRadius + moverRadius,
        );
        if (interval == null) return null;
        entry = math.max(entry, interval.$1);
        exit = math.min(exit, interval.$2);
        if (entry > exit + _physicsEpsilon) return null;
      }
      earliest = entry;
    }

    final hitProgress = earliest;
    if (hitProgress == null ||
        hitProgress < -_physicsEpsilon ||
        hitProgress > 1) {
      return null;
    }
    final progress = hitProgress.clamp(0.0, 1.0);
    final position = _lerp(from, to, progress);
    var normal = mover.isCircle
        ? _reflectorSeparationNormal(reflector, position)
        : _reflectorAabbSatContact(
                reflector,
                mover.copyWith(position: position),
              )?.normal ??
              _reflectorSeparationNormal(reflector, position);
    if (normal.dot(delta) > 0) normal = -normal;
    return _ReflectorSweepHit(position: position, normal: normal);
  }

  double? _segmentAabbEntry(
    Vec2 from,
    Vec2 delta,
    double left,
    double right,
    double top,
    double bottom,
  ) {
    var entry = 0.0;
    var exit = 1.0;
    for (final axis in const [Vec2(1, 0), Vec2(0, 1)]) {
      final minimum = axis.x.abs() > 0 ? left : top;
      final maximum = axis.x.abs() > 0 ? right : bottom;
      final interval = _sweptAxisRange(
        from.dot(axis),
        delta.dot(axis),
        minimum,
        maximum,
      );
      if (interval == null) return null;
      entry = math.max(entry, interval.$1);
      exit = math.min(exit, interval.$2);
      if (entry > exit + _physicsEpsilon) return null;
    }
    return entry;
  }

  (double, double)? _sweptAxisRange(
    double start,
    double velocity,
    double minimum,
    double maximum,
  ) {
    if (velocity.abs() <= _physicsEpsilon) {
      return start >= minimum - _physicsEpsilon &&
              start <= maximum + _physicsEpsilon
          ? (0.0, 1.0)
          : null;
    }
    final first = (minimum - start) / velocity;
    final second = (maximum - start) / velocity;
    return (math.min(first, second), math.max(first, second));
  }

  double? _segmentCircleEntry(
    Vec2 from,
    Vec2 delta,
    Vec2 center,
    double radius,
  ) {
    final offset = from - center;
    final a = delta.dot(delta);
    final c = offset.dot(offset) - radius * radius;
    if (c <= _physicsEpsilon) return 0;
    if (a <= _physicsEpsilon) return null;
    final b = 2 * offset.dot(delta);
    final discriminant = b * b - 4 * a * c;
    if (discriminant < -_physicsEpsilon) return null;
    final root = (-b - math.sqrt(math.max(0, discriminant))) / (2 * a);
    return root >= -_physicsEpsilon && root <= 1 + _physicsEpsilon
        ? root.clamp(0.0, 1.0)
        : null;
  }

  List<_PowerSliderEntry> _firstPowerSliderEntriesAlongSegment(
    List<EntityState> entities,
    EntityState mover,
    Vec2 from,
    Vec2 to,
    _SliderContactLedger ledger,
  ) {
    if (!mover.movable) return const [];
    final entries = <_PowerSliderEntry>[];
    for (final slider in entities) {
      if (slider.type != EntityType.powerSlider ||
          !slider.active ||
          !slider.allowedTargets.contains(mover.type)) {
        continue;
      }
      final contactId = '${mover.id}:${slider.id}';
      if (ledger.isInside(contactId)) {
        final exit = _firstPowerSliderExit(slider, mover, from, to);
        if (exit == null) {
          continue;
        }
        final reentry = _firstPowerSliderEntry(
          slider,
          mover,
          exit.position,
          to,
        );
        if (reentry == null) continue;
        final progress = exit.progress + reentry.progress * (1 - exit.progress);
        entries.add(
          _PowerSliderEntry(
            slider: slider,
            position: _lerp(from, to, progress),
            progress: progress,
            contactId: contactId,
          ),
        );
        continue;
      }
      final entry = _firstPowerSliderEntry(slider, mover, from, to);
      if (entry == null) continue;
      entries.add(
        _PowerSliderEntry(
          slider: slider,
          position: entry.position,
          progress: entry.progress,
          contactId: contactId,
        ),
      );
    }
    entries.sort((left, right) {
      final byProgress = left.progress.compareTo(right.progress);
      if (byProgress != 0) return byProgress;
      return left.slider.id.compareTo(right.slider.id);
    });
    if (entries.isEmpty) return const [];
    final firstProgress = entries.first.progress;
    return entries
        .where(
          (entry) => (entry.progress - firstProgress).abs() <= _physicsEpsilon,
        )
        .toList(growable: false);
  }

  /// 원장 변경은 실제로 소비한 선분에서만 수행한다.
  void _consumeSliderSegment(
    List<EntityState> entities,
    EntityState mover,
    Vec2 from,
    Vec2 to,
    _SliderContactLedger ledger, {
    List<_PowerSliderEntry> entered = const [],
  }) {
    for (final slider in entities) {
      if (slider.type != EntityType.powerSlider ||
          !slider.active ||
          !slider.allowedTargets.contains(mover.type)) {
        continue;
      }
      final contactId = '${mover.id}:${slider.id}';
      if (ledger.isInside(contactId) &&
          _segmentHasFullExit(mover, slider, from, to)) {
        ledger.markExited(contactId);
      }
    }
    for (final entry in entered) {
      ledger.markEntered(entry.contactId);
    }
  }

  bool _segmentHasFullExit(
    EntityState mover,
    EntityState slider,
    Vec2 from,
    Vec2 to,
  ) {
    if (!_collidesAt(mover, slider, from)) return true;
    final distance = from.distanceTo(to);
    final steps = math.max(1, (distance / 1.25).ceil());
    for (var step = 1; step <= steps; step++) {
      if (!_collidesAt(mover, slider, _lerp(from, to, step / steps))) {
        return true;
      }
    }
    return false;
  }

  void _consumeReflectorSegment(
    List<EntityState> entities,
    EntityState mover,
    Vec2 from,
    Vec2 to,
    _ReflectorContactLedger ledger,
  ) {
    for (final reflector in entities) {
      if (reflector.type != EntityType.rotatingReflector || !reflector.active) {
        continue;
      }
      final contactId = '${mover.id}:${reflector.id}';
      if (!ledger.isInside(contactId)) continue;
      if (!_collidesAt(mover, reflector, from) ||
          _segmentHasFullReflectorExit(mover, reflector, from, to)) {
        ledger.markExited(contactId);
      }
    }
  }

  bool _segmentHasFullReflectorExit(
    EntityState mover,
    EntityState reflector,
    Vec2 from,
    Vec2 to,
  ) {
    final distance = from.distanceTo(to);
    final steps = math.max(
      1,
      (distance / _reflectorSweepLedgerSampleDistance).ceil(),
    );
    for (var step = 1; step <= steps; step++) {
      if (!_collidesAt(mover, reflector, _lerp(from, to, step / steps))) {
        return true;
      }
    }
    return false;
  }

  _SliderEntryPoint? _firstPowerSliderExit(
    EntityState slider,
    EntityState mover,
    Vec2 from,
    Vec2 to,
  ) {
    if (!_collidesAt(mover, slider, from)) {
      return const _SliderEntryPoint(position: Vec2.zero, progress: 0);
    }
    final distance = from.distanceTo(to);
    final steps = math.max(1, (distance / 1.25).ceil());
    var previous = from;
    for (var step = 1; step <= steps; step++) {
      final progress = step / steps;
      final position = _lerp(from, to, progress);
      if (_collidesAt(mover, slider, position)) {
        previous = position;
        continue;
      }
      var low = previous;
      var high = position;
      for (var iteration = 0; iteration < 8; iteration++) {
        final middle = _lerp(low, high, 0.5);
        if (_collidesAt(mover, slider, middle)) {
          low = middle;
        } else {
          high = middle;
        }
      }
      return _SliderEntryPoint(
        position: high,
        progress: _segmentProgress(from, to, high),
      );
    }
    return null;
  }

  Vec2 _lerp(Vec2 from, Vec2 to, double progress) {
    return Vec2(
      from.x + (to.x - from.x) * progress,
      from.y + (to.y - from.y) * progress,
    );
  }

  _SliderEntryPoint? _firstPowerSliderEntry(
    EntityState slider,
    EntityState mover,
    Vec2 from,
    Vec2 to,
  ) {
    final distance = from.distanceTo(to);
    final steps = math.max(1, (distance / 1.25).ceil());
    var previous = from;
    for (var step = 1; step <= steps; step++) {
      final progress = step / steps;
      final position = Vec2(
        from.x + (to.x - from.x) * progress,
        from.y + (to.y - from.y) * progress,
      );
      if (!_collidesAt(mover, slider, position)) {
        previous = position;
        continue;
      }
      var low = previous;
      var high = position;
      if (_collidesAt(mover, slider, low)) {
        high = low;
      } else {
        for (var iteration = 0; iteration < 8; iteration++) {
          final middle = Vec2((low.x + high.x) / 2, (low.y + high.y) / 2);
          if (_collidesAt(mover, slider, middle)) {
            high = middle;
          } else {
            low = middle;
          }
        }
      }
      return _SliderEntryPoint(
        position: high,
        progress: _segmentProgress(from, to, high),
      );
    }
    return null;
  }

  bool _isCollisionCandidate(EntityState entity, String movingId) {
    if (entity.id == movingId ||
        !entity.active ||
        !_isSolidForPhysics(entity)) {
      return false;
    }
    return !(entity.type == EntityType.gate && entity.open);
  }

  // 벽은 렌더링 상태나 상호작용 상태와 무관하게 항상 고정 장애물이다.
  bool _isSolidForPhysics(EntityState entity) {
    if (entity.type == EntityType.powerSlider) return false;
    return entity.type == EntityType.wall || entity.solid;
  }

  bool _collidesAt(EntityState moving, EntityState target, Vec2 position) {
    return _collides(moving.copyWith(position: position), target);
  }

  double _segmentProgress(Vec2 from, Vec2 to, Vec2 point) {
    final delta = to - from;
    final lengthSquared = delta.dot(delta);
    if (lengthSquared <= 0.0001) {
      return 0;
    }
    return ((point - from).dot(delta) / lengthSquared).clamp(0.0, 1.0);
  }

  double _segmentCircleEntryProgress(
    Vec2 from,
    Vec2 to,
    Vec2 center,
    double radius,
  ) {
    final delta = to - from;
    final offset = from - center;
    final a = delta.dot(delta);
    if (a <= 0.0001) {
      return offset.length <= radius ? 0.0 : double.infinity;
    }
    final c = offset.dot(offset) - radius * radius;
    if (c <= 0) {
      return 0.0;
    }
    final b = 2 * offset.dot(delta);
    final discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
      return double.infinity;
    }
    final root = (-b - math.sqrt(discriminant)) / (2 * a);
    return root >= 0 && root <= 1 ? root : double.infinity;
  }

  bool _isEarlierCollision(
    CollisionHit candidate,
    double metric,
    CollisionHit? best,
    double bestMetric,
  ) {
    if (best == null || metric < bestMetric - 0.001) {
      return true;
    }
    if ((metric - bestMetric).abs() <= 0.001) {
      return candidate.entity.id.compareTo(best.entity.id) < 0;
    }
    return false;
  }

  Vec2 _reflect(Vec2 direction, Vec2 normal) {
    return direction.reflectedBy(normal);
  }

  Vec2 _separateFromCollision(
    EntityState hit,
    EntityState ball,
    Vec2 position,
    Vec2 normal,
  ) {
    if (hit.type == EntityType.rotatingReflector) {
      final contact = _reflectorContact(hit, position);
      final separationNormal = normal.length <= _physicsEpsilon
          ? contact.normal
          : normal.normalized();
      final support = ball.isCircle
          ? ball.hitRadius
          : _aabbSupportRadius(ball, separationNormal);
      return contact.point + separationNormal * (support + 1.8);
    }
    if (hit.isCircle) {
      return hit.position +
          normal.normalized() * (hit.hitRadius + ball.hitRadius + 0.8);
    }
    final bounds = hit.hitBounds;
    final n = normal.normalized();
    if (n.x.abs() >= n.y.abs()) {
      final x = n.x < 0
          ? bounds.left - ball.hitRadius - 1.8
          : bounds.right + ball.hitRadius + 1.8;
      return Vec2(x, position.y);
    }
    final y = n.y < 0
        ? bounds.top - ball.hitRadius - 1.8
        : bounds.bottom + ball.hitRadius + 1.8;
    return Vec2(position.x, y);
  }

  Vec2 _postImpactDirection(
    Vec2 direction,
    Vec2 normal,
    double movingMass,
    double targetMass,
  ) {
    final reflected = _reflect(direction, normal);
    if (movingMass <= targetMass) {
      return reflected;
    }
    final keep = ((movingMass - targetMass) / (movingMass + targetMass)).clamp(
      0.0,
      0.82,
    );
    final deflection = normal * (0.22 * (1 - keep));
    return (direction * (0.78 + keep * 0.5) + deflection).normalized();
  }

  Vec2 _collisionVelocity(
    Vec2 incoming,
    Vec2 normal,
    double movingMass,
    double targetMass,
    double restitution,
  ) {
    final n = normal.normalized();
    final normalSpeed = incoming.dot(n);
    if (normalSpeed >= 0 || incoming.length <= 0.001) {
      return incoming;
    }
    final tangent = incoming - n * normalSpeed;
    final stationaryTargetMass = math.min(targetMass, 999.0);
    final normalCoefficient =
        (movingMass - restitution * stationaryTargetMass) /
        (movingMass + stationaryTargetMass);
    return tangent + n * (normalSpeed * normalCoefficient);
  }

  Vec2 _wallBounceVelocity(
    Vec2 incoming,
    Vec2 normal,
    EntityState moving,
    EntityState wall,
  ) {
    final n = normal.normalized();
    final normalSpeed = incoming.dot(n);
    if (normalSpeed >= 0 || incoming.length <= 0.001) {
      return incoming;
    }
    final restitution = moving.traits.contains(TraitType.bouncy)
        ? math.max(wall.restitution, bouncyWallRestitutionFloor)
        : wall.restitution;
    final tangent = incoming - n * normalSpeed;
    final tangentRetention = _tangentRetention(wall);
    return tangent * tangentRetention - n * (normalSpeed * restitution);
  }

  double _tangentRetention(EntityState surface) {
    return switch (surface.type) {
      EntityType.stickySurface => 0.12,
      EntityType.bumper => 0.96,
      EntityType.balloon => 0.82,
      EntityType.wall || EntityType.gate => 1.0,
      _ => 1.0,
    };
  }

  double _postImpactSpeedFactor(double movingMass, double targetMass) {
    if (movingMass > targetMass) {
      return (0.64 +
              (movingMass - targetMass) / (movingMass + targetMass) * 0.3)
          .clamp(0.64, 0.9);
    }
    return (0.35 + movingMass / (movingMass + targetMass) * 0.35).clamp(
      0.35,
      0.7,
    );
  }

  double _effectiveRestitution(EntityState entity) {
    final base = entity.restitution.clamp(0.12, 0.98).toDouble();
    return entity.traits.contains(TraitType.bouncy)
        ? math.max(base, 0.88)
        : base;
  }

  double _restitutionMultiplier(EntityState moving, EntityState hit) {
    final pair =
        (_effectiveRestitution(moving) + _effectiveRestitution(hit)) / 2;
    return (pair / 0.72).clamp(0.2, 1.35).toDouble();
  }

  // 속도 감쇠에 쓰는 정규화 배율과 충돌 방정식의 실제 반발계수는
  // 서로 다른 값이다. 기본 재질의 0.72를 1.0으로 올려 쓰면
  // 벽·공·물체 연쇄가 탄성 충돌처럼 에너지를 과도하게 보존한다.
  double _collisionRestitution(EntityState moving, EntityState hit) {
    return ((_effectiveRestitution(moving) + _effectiveRestitution(hit)) / 2)
        .clamp(0.12, 0.98)
        .toDouble();
  }

  double _massOf(EntityState entity) => massOf(entity);

  /// 진단·벤치마크에서 판정과 같은 질량 표를 읽을 수 있게 공개한다.
  /// 실제 충돌 계산은 계속 이 표를 통해서만 수행한다.
  static double massOf(EntityState entity) {
    if (entity.traits.contains(TraitType.heavy)) {
      return 4.4;
    }
    return switch (entity.type) {
      EntityType.ball => 1.0,
      EntityType.crate => 2.0,
      // 비워진 돌은 무거움(4.4)을 잃은 뒤 상자보다도 가볍게 밀린다.
      // 이 값은 5단계 대표 충돌과 근방 성공 영역 회귀로 함께 고정한다.
      EntityType.weight => 1.6,
      EntityType.bumper => 1.4,
      EntityType.stickySurface => 2.6,
      EntityType.switchPad => 3.0,
      EntityType.gate => 8.0,
      EntityType.wall => 999.0,
      EntityType.hole => 0.0,
      EntityType.balloon => 0.18,
      EntityType.spikeSource => 1.2,
      EntityType.powerSlider => 0.0,
      EntityType.rotatingReflector => 999.0,
    };
  }

  _OrientedReflector _orientedReflector(EntityState entity) {
    final angle = -math.pi / 2 + entity.reflectorOrientation * math.pi / 4;
    final normal = Vec2(math.cos(angle), math.sin(angle)).normalized();
    final tangent = Vec2(-normal.y, normal.x);
    final scale = entity.hitboxScale;
    return _OrientedReflector(
      center: entity.position,
      normal: normal,
      tangent: tangent,
      halfNormal: entity.size.y * scale / 2,
      halfTangent: entity.size.x * scale / 2,
    );
  }

  Vec2 _reflectorSeparationNormal(EntityState reflector, Vec2 position) {
    return _reflectorContact(reflector, position).normal;
  }

  _ReflectorContact _reflectorContact(EntityState reflector, Vec2 position) {
    final shape = _orientedReflector(reflector);
    final delta = position - shape.center;
    final localNormal = delta.dot(shape.normal);
    final localTangent = delta.dot(shape.tangent);
    final nearestNormal = localNormal.clamp(
      -shape.halfNormal,
      shape.halfNormal,
    );
    final nearestTangent = localTangent.clamp(
      -shape.halfTangent,
      shape.halfTangent,
    );
    final nearest =
        shape.center +
        shape.normal * nearestNormal +
        shape.tangent * nearestTangent;
    final offset = position - nearest;
    if (offset.length > _physicsEpsilon) {
      return _ReflectorContact(point: nearest, normal: offset.normalized());
    }

    final normalClearance = shape.halfNormal - localNormal.abs();
    final tangentClearance = shape.halfTangent - localTangent.abs();
    if (normalClearance <= tangentClearance) {
      final sign = localNormal < 0 ? -1.0 : 1.0;
      return _ReflectorContact(
        point:
            shape.center +
            shape.normal * (sign * shape.halfNormal) +
            shape.tangent * nearestTangent,
        normal: shape.normal * sign,
      );
    }
    final sign = localTangent < 0 ? -1.0 : 1.0;
    return _ReflectorContact(
      point:
          shape.center +
          shape.normal * nearestNormal +
          shape.tangent * (sign * shape.halfTangent),
      normal: shape.tangent * sign,
    );
  }

  bool _orientedReflectorOverlaps(EntityState reflector, EntityState mover) {
    final shape = _orientedReflector(reflector);
    if (mover.isCircle) {
      final delta = mover.position - shape.center;
      final tangentDistance = delta.dot(shape.tangent).abs();
      final normalDistance = delta.dot(shape.normal).abs();
      final clampedTangent = tangentDistance.clamp(0.0, shape.halfTangent);
      final clampedNormal = normalDistance.clamp(0.0, shape.halfNormal);
      final tangentGap = tangentDistance - clampedTangent;
      final normalGap = normalDistance - clampedNormal;
      return (tangentGap * tangentGap + normalGap * normalGap) <=
          mover.hitRadius * mover.hitRadius;
    }
    return _reflectorAabbSatContact(reflector, mover) != null;
  }

  /// 회전판과 AABB 이동체가 실제로 겹치는 최소 분리축을 계산한다.
  ///
  /// 축 순서는 반사판 법선, 반사판 접선, 화면 x축, 화면 y축으로 고정한다.
  /// 침투 깊이가 같으면 이 순서를 그대로 사용해 재현 가능한 법선을 만든다.
  _ReflectorSatContact? _reflectorAabbSatContact(
    EntityState reflector,
    EntityState mover,
  ) {
    final shape = _orientedReflector(reflector);
    final delta = mover.position - shape.center;
    final axes = <Vec2>[
      shape.normal,
      shape.tangent,
      const Vec2(1, 0),
      const Vec2(0, 1),
    ];
    _ReflectorSatContact? best;
    for (final axis in axes) {
      final reflectorRadius =
          shape.halfNormal * axis.dot(shape.normal).abs() +
          shape.halfTangent * axis.dot(shape.tangent).abs();
      final moverRadius = _aabbSupportRadius(mover, axis);
      final penetration = reflectorRadius + moverRadius - delta.dot(axis).abs();
      if (penetration < -_physicsEpsilon) return null;
      if (best == null || penetration < best.penetration - _physicsEpsilon) {
        final sign = delta.dot(axis) < 0 ? -1.0 : 1.0;
        best = _ReflectorSatContact(
          normal: axis * sign,
          penetration: math.max(0, penetration),
        );
      }
    }
    return best;
  }

  double _aabbSupportRadius(EntityState entity, Vec2 normal) {
    if (entity.isCircle) return entity.hitRadius;
    return entity.hitBounds.width / 2 * normal.x.abs() +
        entity.hitBounds.height / 2 * normal.y.abs();
  }

  Vec2 _reflectorBounceVelocity(
    Vec2 incoming,
    Vec2 normal,
    EntityState moving,
    EntityState reflector,
  ) {
    if (incoming.length <= 0.001) return incoming;
    final n = normal.normalized();
    final normalSpeed = incoming.dot(n);
    final tangent = incoming - n * normalSpeed;
    final restitution = _collisionRestitution(moving, reflector);
    return tangent - n * (normalSpeed * restitution);
  }

  Vec2 _collisionNormal(EntityState ball, EntityState hit, Vec2 position) {
    if (hit.type == EntityType.rotatingReflector) {
      return _reflectorSeparationNormal(hit, position);
    }
    if (hit.isCircle) {
      final delta = position - hit.position;
      return delta.length <= 0.001 ? const Vec2(1, 0) : delta.normalized();
    }
    return _rectNormal(hit.hitBounds, position);
  }

  Vec2 _rectNormal(Bounds bounds, Vec2 impact) {
    final nearest = bounds.nearestPoint(impact);
    var normal = impact - nearest;
    if (normal.length > 0.001) {
      return normal.normalized();
    }
    final center = Vec2(
      (bounds.left + bounds.right) / 2,
      (bounds.top + bounds.bottom) / 2,
    );
    final horizontal = math.min(
      (impact.x - bounds.left).abs(),
      (impact.x - bounds.right).abs(),
    );
    final vertical = math.min(
      (impact.y - bounds.top).abs(),
      (impact.y - bounds.bottom).abs(),
    );
    if ((horizontal - vertical).abs() <= 0.001) {
      final diagonal = Vec2(
        impact.x < center.x ? -1 : 1,
        impact.y < center.y ? -1 : 1,
      );
      return diagonal.normalized();
    }
    final distances = <Vec2, double>{
      const Vec2(-1, 0): (impact.x - bounds.left).abs(),
      const Vec2(1, 0): (impact.x - bounds.right).abs(),
      const Vec2(0, -1): (impact.y - bounds.top).abs(),
      const Vec2(0, 1): (impact.y - bounds.bottom).abs(),
    };
    return distances.entries.reduce((a, b) => a.value < b.value ? a : b).key;
  }

  List<EntityState> _replace(
    List<EntityState> entities,
    EntityState replacement,
  ) {
    return [
      for (final entity in entities)
        entity.id == replacement.id ? replacement : entity,
    ];
  }

  EntityState? _entityById(List<EntityState> entities, String id) {
    for (final entity in entities) {
      if (entity.id == id) {
        return entity;
      }
    }
    return null;
  }

  /// 공개 트리거가 자신의 [EntityState.linkId]로 숨은 기믹을 지정한다.
  /// 이전 스테이지 데이터도 안전하게 재생할 수 있도록 숨은 대상이 정확히 하나인
  /// 경우에만 제한적으로 추론한다. ID 이름에는 의존하지 않는다.
  EntityState? _hiddenMechanicLinkedFrom(
    List<EntityState> entities,
    EntityState trigger,
  ) {
    final linkedId = trigger.linkId;
    if (linkedId != null) {
      final linked = _entityById(entities, linkedId);
      if (linked != null &&
          HiddenMechanicState.masksIdentity(linked.visualState)) {
        return linked;
      }
    }
    final concealed = entities
        .where(
          (entity) =>
              entity.active &&
              HiddenMechanicState.masksIdentity(entity.visualState),
        )
        .toList(growable: false);
    return concealed.length == 1 ? concealed.single : null;
  }

  List<EntityState> _openGates(List<EntityState> entities) {
    return [
      for (final entity in entities)
        if (entity.type == EntityType.gate)
          entity.copyWith(open: true, solid: false, visualState: 'open')
        else
          entity,
    ];
  }

  List<EntityState> _openReflectorGates(List<EntityState> entities) {
    return [
      for (final entity in entities)
        if (entity.type == EntityType.gate &&
            entity.id.startsWith('rotation_gate'))
          entity.copyWith(open: true, solid: false, visualState: 'open')
        else
          entity,
    ];
  }

  List<EntityState> _openLinkedEntity(
    List<EntityState> entities,
    String linkId,
  ) {
    return [
      for (final entity in entities)
        entity.id == linkId
            ? entity.copyWith(open: true, solid: false, visualState: 'open')
            : entity,
    ];
  }

  String _messageFor(List<String> events) {
    if (events.contains('hole_rejected_crate')) {
      return '홀에 닿지 못했어요. 상자와의 충돌 또는 다른 경로를 시도해 보세요.';
    }
    if (events.contains('hole_rejected_trait')) {
      return '홀에 닿지 못했어요. 속성 없이도 다른 각도와 경로를 시도해 보세요.';
    }
    if (events.contains('switch_rejected_sticky')) {
      return '스위치는 무거운 공에 반응합니다. 점착판 없이 다른 경로도 시도해 보세요.';
    }
    if (events.contains('switch_pressed')) {
      if (events.contains('balloon_switch_pressed')) {
        return '풍선 뒤 스위치가 눌려 문이 열렸습니다.';
      }
      return '무거운 공이 스위치를 눌렀습니다. 문이 열렸습니다.';
    }
    if (events.contains('switch_rejected')) {
      return '스위치에는 무거움이 필요합니다.';
    }
    if (events.contains('crate_pushed')) {
      return '상자를 밀고 튕겼습니다.';
    }
    if (events.contains('bounced')) {
      return '부딪혀 튕겼습니다.';
    }
    if (events.contains('jelly_bounced')) {
      return '젤리에 맞고 통통 튕겼습니다.';
    }
    if (events.contains('momentum_transfer')) {
      return '충격이 다른 물체로 전달되었습니다.';
    }
    if (events.contains('sticky_attached')) {
      return '점착 속성으로 표면에 붙었어요.';
    }
    if (events.contains('balloon_popped')) {
      return '풍선이 터졌어요. 뒤의 스위치를 눌러 길을 열어 보세요.';
    }
    if (events.contains('balloon_bounced')) {
      return '풍선에 맞고 공이 튕겨 나갔어요.';
    }
    return '공이 멈췄습니다. 남은 공을 다음 전략에 활용하세요.';
  }

  List<EntityState> _pushWithMomentum(
    List<EntityState> entities,
    EntityState target,
    Vec2 direction,
    double distance,
    List<String> events, [
    List<ShotAnimationMove>? moves,
    int triggerPathIndex = 0,
    Vec2 contactNormal = Vec2.zero,
    int depth = 0,
    bool carriesHeavy = false,
    Set<String> chainIds = const {},
    List<ShotImpact>? impacts,
    List<ChainSafetyDiagnostic>? chainSafetyDiagnostics,
    List<PhysicsStateTransition>? stateTransitions,
    _SliderContactLedger? sliderContacts,
    List<PowerSliderActivation>? powerSliderActivations,
    _ReflectorContactLedger? reflectorContacts,
    List<ReflectorRotation>? reflectorRotations,
  ]) {
    // 연쇄 깊이를 임의의 상수로 자르면 물체 수가 많은 스테이지에서
    // 충돌 이벤트가 누락된다. 한 번의 연쇄에서 같은 엔티티를 계속
    // 재귀 처리하는 것은 별도 물리 계산 없이도 진행을 끝낼 수 없으므로,
    // 현재 스테이지의 엔티티 수를 상한으로 사용한다.
    if (!target.movable ||
        target.type == EntityType.wall ||
        depth >= entities.length) {
      if (depth >= entities.length) {
        events.add('chain_safety_stop');
        chainSafetyDiagnostics?.add(
          ChainSafetyDiagnostic(
            targetEntityId: target.id,
            pathIndex: triggerPathIndex,
            depth: depth,
            iterations: 0,
            remainingDistance: distance,
            remainingSpeed: distance,
          ),
        );
      }
      return entities;
    }

    final strength = math.max(0.22, -direction.normalized().dot(contactNormal));
    final travelDirection = direction.normalized();
    final normalImpulse = contactNormal == Vec2.zero
        ? travelDirection
        : (-contactNormal).normalized();
    var impulseDirection = travelDirection.dot(normalImpulse) < 0
        ? travelDirection
        : normalImpulse;
    var current = target;
    // 직전 부모만 제외한다. 전체 연쇄에서 충돌한 대상을 영구 제외하면
    // 반사 후 다시 닿는 합법적인 충돌 이벤트가 누락된다.
    final temporarilyIgnoredIds = Set<String>.from(chainIds);
    var remaining = distance * strength;
    var velocity = impulseDirection * remaining;
    var iterations = 0;
    final path = <Vec2>[target.position];

    final maxIterations = entities.length * 2 + 16;
    while (velocity.length > 0.8 && iterations < maxIterations) {
      iterations += 1;
      final availableSpeed = velocity.length;
      final step = math.min(availableSpeed, 4.0);
      final stepDirection = availableSpeed <= 0.001
          ? impulseDirection
          : velocity.normalized();
      final candidate = current.copyWith(
        position: current.position + stepDirection * step,
        visualState: 'pushed',
      );
      final collision = _firstEntityCollisionAlongSegment(
        entities,
        current,
        candidate,
        target.id,
        temporarilyIgnoredIds,
      );
      final hole = _findHole(entities);
      final holeCaptureRadius = hole == null
          ? 0.0
          : hole.hitRadius + current.hitRadius;
      final holeProgress = current.type == EntityType.ball && hole != null
          ? _segmentCircleEntryProgress(
              current.position,
              candidate.position,
              hole.position,
              holeCaptureRadius,
            )
          : double.infinity;
      final collisionProgress = collision == null
          ? double.infinity
          : _segmentProgress(
              current.position,
              candidate.position,
              collision.position,
            );
      final sliderEntries = sliderContacts == null
          ? const <_PowerSliderEntry>[]
          : _firstPowerSliderEntriesAlongSegment(
              entities,
              current,
              current.position,
              candidate.position,
              sliderContacts,
            );
      final sliderProgress = sliderEntries.isEmpty
          ? double.infinity
          : sliderEntries.first.progress;
      if (sliderProgress.isFinite &&
          sliderProgress < collisionProgress - _physicsEpsilon &&
          sliderProgress < holeProgress - _physicsEpsilon) {
        final entry = sliderEntries.first;
        final speedBefore = velocity.length;
        final motionDirection = velocity.normalized();
        final referenceSpeed = sliderEntries.fold<double>(
          0,
          (maximum, sliderEntry) =>
              math.max(maximum, sliderEntry.slider.referenceSpeed),
        );
        final speedAfter = math.max(speedBefore, referenceSpeed);
        _consumeSliderSegment(
          entities,
          current,
          current.position,
          entry.position,
          sliderContacts!,
          entered: sliderEntries,
        );
        _consumeReflectorSegment(
          entities,
          current,
          current.position,
          entry.position,
          reflectorContacts!,
        );
        current = current.copyWith(position: entry.position);
        _appendMovePoint(path, entry.position);
        velocity = velocity.normalized() * speedAfter;
        impulseDirection = velocity.normalized();
        remaining = velocity.length;
        for (final sliderEntry in sliderEntries) {
          powerSliderActivations?.add(
            PowerSliderActivation(
              sourceEntityId: current.id,
              sliderEntityId: sliderEntry.slider.id,
              contactId: sliderEntry.contactId,
              position: sliderEntry.position,
              pathIndex: triggerPathIndex + iterations,
              direction: sliderEntry.slider.direction,
              motionDirection: motionDirection,
              velocityBefore: motionDirection * speedBefore,
              velocityAfter: motionDirection * speedAfter,
              speedBefore: speedBefore,
              speedAfter: speedAfter,
              referenceSpeed: sliderEntry.slider.referenceSpeed,
            ),
          );
          events.add('power_slider_activated');
          if (sliderEntry.slider.linkId case final gateId?) {
            entities = _openLinkedEntity(entities, gateId);
            events.add('slider_gate_opened');
          }
        }
        continue;
      }
      if (hole != null &&
          holeProgress.isFinite &&
          _segmentDistance(
                current.position,
                candidate.position,
                hole.position,
              ) <=
              holeCaptureRadius &&
          holeProgress <= collisionProgress + _physicsEpsilon &&
          holeProgress <= sliderProgress + _physicsEpsilon) {
        _consumeReflectorSegment(
          entities,
          current,
          current.position,
          hole.position,
          reflectorContacts!,
        );
        _consumeSliderSegment(
          entities,
          current,
          current.position,
          hole.position,
          sliderContacts!,
        );
        current = current.copyWith(
          position: hole.position,
          movable: false,
          visualState: 'hole_captured',
        );
        _appendMovePoint(path, hole.position);
        impacts?.add(
          ShotImpact(
            entityId: hole.id,
            entityType: EntityType.hole,
            position: hole.position,
            normal: stepDirection * -1,
            pathIndex: triggerPathIndex + iterations,
            strength: (velocity.length / 24).clamp(0.18, 1.0),
            sourceEntityId: target.id,
            sourceTraitMask: traitMaskOf(current.traits),
          ),
        );
        stateTransitions?.add(
          PhysicsStateTransition(
            sourceEntityId: target.id,
            targetEntityId: hole.id,
            targetType: hole.type,
            pathIndex: triggerPathIndex + iterations,
            previousState: current.visualState,
            nextState: 'captured',
            position: hole.position,
            normal: stepDirection * -1,
          ),
        );
        entities = _replace(entities, current);
        events.add('chain_hole_entered');
        break;
      }
      if (collision == null) {
        _consumeReflectorSegment(
          entities,
          current,
          current.position,
          candidate.position,
          reflectorContacts!,
        );
        _consumeSliderSegment(
          entities,
          current,
          current.position,
          candidate.position,
          sliderContacts!,
        );
        current = candidate;
        velocity = stepDirection * math.max(0.0, availableSpeed - step);
        impulseDirection = stepDirection;
        remaining = velocity.length;
        _appendMovePoint(path, current.position);
        continue;
      }

      _consumeSliderSegment(
        entities,
        current,
        current.position,
        collision.position,
        sliderContacts!,
      );
      _consumeReflectorSegment(
        entities,
        current,
        current.position,
        collision.position,
        reflectorContacts!,
      );

      final hit = collision.entity;
      final collisionEntity = candidate.copyWith(position: collision.position);
      var normal =
          collision.normal ??
          _collisionNormalForMovingEntity(collisionEntity, hit);
      if (hit.type == EntityType.rotatingReflector &&
          !collision.startsOverlapping &&
          normal.dot(velocity) > 0) {
        normal = -normal;
      }
      final collisionTrigger = triggerPathIndex + iterations;
      final impactContactId = hit.type == EntityType.rotatingReflector
          ? '${current.id}:${hit.id}'
          : null;
      final reflectorRotationQualifies =
          hit.type == EntityType.rotatingReflector &&
          !current.traits.contains(TraitType.sticky) &&
          impactContactId != null &&
          !reflectorContacts.isInside(impactContactId) &&
          !(collision.startsOverlapping &&
              velocity.dot(normal) >= -_physicsEpsilon);
      impacts?.add(
        ShotImpact(
          entityId: hit.id,
          entityType: hit.type,
          position: collision.position,
          normal: normal,
          pathIndex: collisionTrigger,
          strength: (velocity.length / 24).clamp(0.18, 1.0),
          sourceEntityId: target.id,
          contactId: impactContactId,
          triggersReflectorRotation: reflectorRotationQualifies,
          relativeNormalSpeed: math.max(0, -velocity.dot(normal)),
          impulse: ImpactMetrics.normalizedImpulse(
            relativeNormalSpeed: math.max(0, -velocity.dot(normal)),
            movingMass: _massOf(current),
            targetMass: _massOf(hit),
          ),
          impactTier: ImpactMetrics.tierFor(
            ImpactMetrics.normalizedImpulse(
              relativeNormalSpeed: math.max(0, -velocity.dot(normal)),
              movingMass: _massOf(current),
              targetMass: _massOf(hit),
            ),
          ),
          sourceTraitMask: traitMaskOf(current.traits),
        ),
      );
      final hitIsSticky =
          hit.type == EntityType.stickySurface &&
          hit.traits.contains(TraitType.sticky);
      current = candidate.copyWith(
        position: _separateMovingEntityFromCollision(
          hit,
          collisionEntity,
          normal,
        ),
        movable: hitIsSticky ? false : current.movable,
        visualState: hitIsSticky ? 'stuck' : 'pushed',
      );
      _appendMovePoint(path, collision.position);
      _appendMovePoint(path, current.position);
      events.add('chain_collision_${hit.type.name}');

      if (hit.type == EntityType.rotatingReflector) {
        if (current.traits.contains(TraitType.sticky)) {
          stateTransitions?.add(
            PhysicsStateTransition(
              sourceEntityId: target.id,
              targetEntityId: current.id,
              targetType: current.type,
              pathIndex: collisionTrigger,
              previousState: current.visualState,
              nextState: 'stuck',
              position: collision.position,
              normal: normal,
            ),
          );
          entities = _replace(entities, current.copyWith(visualState: 'stuck'));
          break;
        }
        final contactId = '${current.id}:${hit.id}';
        if (reflectorContacts.isInside(contactId)) {
          entities = _replace(entities, current);
          _consumeReflectorSegment(
            entities,
            current,
            collision.position,
            current.position,
            reflectorContacts,
          );
          continue;
        }
        final reflectorNormal = normal;
        final velocityBefore = velocity;
        if (collision.startsOverlapping &&
            velocityBefore.dot(reflectorNormal) >= -_physicsEpsilon) {
          entities = _replace(entities, current);
          reflectorContacts.markEntered(contactId);
          _consumeReflectorSegment(
            entities,
            current,
            collision.position,
            current.position,
            reflectorContacts,
          );
          events.add('reflector_overlap_separated');
          continue;
        }
        final bounced = _reflectorBounceVelocity(
          velocityBefore,
          reflectorNormal,
          current,
          hit,
        );
        final beforeOrientation = hit.reflectorOrientation;
        final afterOrientation = (beforeOrientation + 2) % 8;
        final beforeCount = hit.reflectorRotationCount;
        final afterCount = beforeCount + 1;
        current = current.copyWith(
          position: _separateMovingEntityFromCollision(
            hit,
            collisionEntity,
            reflectorNormal,
          ),
        );
        entities = _replace(
          entities,
          hit.copyWith(
            reflectorOrientation: afterOrientation,
            reflectorRotationCount: afterCount,
            visualState: 'rotated',
          ),
        );
        entities = _replace(entities, current);
        final openedRotationGate = entities.any(
          (entity) =>
              entity.type == EntityType.gate &&
              entity.id.startsWith('rotation_gate') &&
              !entity.open,
        );
        entities = _openReflectorGates(entities);
        reflectorContacts.markEntered(contactId);
        reflectorRotations?.add(
          ReflectorRotation(
            sourceEntityId: current.id,
            reflectorEntityId: hit.id,
            contactId: contactId,
            pathIndex: collisionTrigger,
            orientationBefore: beforeOrientation,
            orientationAfter: afterOrientation,
            rotationCountBefore: beforeCount,
            rotationCountAfter: afterCount,
            collisionNormal: reflectorNormal,
            velocityBefore: velocityBefore,
            velocityAfter: bounced,
          ),
        );
        velocity = bounced;
        remaining = velocity.length;
        if (remaining > 0.001) {
          impulseDirection = velocity.normalized();
        }
        events.add('reflector_reflected');
        events.add('reflector_rotated');
        if (openedRotationGate) events.add('rotation_gate_opened');
        continue;
      }

      if (hit.type == EntityType.balloon) {
        if (current.traits.contains(TraitType.sharp)) {
          entities = _replace(
            entities,
            hit.copyWith(active: false, solid: false, visualState: 'popped'),
          );
          stateTransitions?.add(
            PhysicsStateTransition(
              sourceEntityId: target.id,
              targetEntityId: hit.id,
              targetType: hit.type,
              pathIndex: collisionTrigger,
              previousState: hit.visualState,
              nextState: 'popped',
              position: collision.position,
              normal: normal,
            ),
          );
          final balloonSwitch = _hiddenMechanicLinkedFrom(entities, hit);
          if (balloonSwitch != null) {
            entities = _replace(
              entities,
              balloonSwitch.copyWith(
                solid: true,
                visualState: HiddenMechanicState.revealed,
              ),
            );
            stateTransitions?.add(
              PhysicsStateTransition(
                sourceEntityId: hit.id,
                targetEntityId: balloonSwitch.id,
                targetType: balloonSwitch.type,
                pathIndex: collisionTrigger,
                previousState: balloonSwitch.visualState,
                nextState: HiddenMechanicState.revealed,
                position: balloonSwitch.position,
                normal: normal,
              ),
            );
            moves?.add(
              ShotAnimationMove(
                entityId: balloonSwitch.id,
                from: balloonSwitch.position,
                to: balloonSwitch.position,
                triggerPathIndex: collisionTrigger + 1,
                visualState: HiddenMechanicState.opening,
                impactPosition: collision.position,
                impactNormal: normal,
              ),
            );
            moves?.add(
              ShotAnimationMove(
                entityId: balloonSwitch.id,
                from: balloonSwitch.position,
                to: balloonSwitch.position,
                triggerPathIndex: collisionTrigger + 7,
                visualState: HiddenMechanicState.revealed,
                impactPosition: collision.position,
                impactNormal: normal,
              ),
            );
          }
          current = current.copyWith(
            traits: {...current.traits}..remove(TraitType.sharp),
            visualState: 'pushed',
          );
          stateTransitions?.add(
            PhysicsStateTransition(
              sourceEntityId: hit.id,
              targetEntityId: current.id,
              targetType: current.type,
              pathIndex: collisionTrigger,
              previousState: TraitType.sharp.name,
              nextState: 'sharpness_consumed',
              position: collision.position,
              normal: normal,
            ),
          );
          moves?.add(
            ShotAnimationMove(
              entityId: hit.id,
              from: hit.position,
              to: hit.position,
              triggerPathIndex: collisionTrigger,
              visualState: 'popped',
              impactPosition: collision.position,
              impactNormal: normal,
            ),
          );
          events.add('balloon_popped');
          events.add('sharpness_consumed');
          if (balloonSwitch != null) {
            events.add('balloon_switch_revealed');
          }
          velocity *= 0.86;
          remaining = velocity.length;
          if (remaining > 0.001) {
            impulseDirection = velocity.normalized();
          }
          entities = _replace(entities, current);
          continue;
        }
        velocity =
            _collisionVelocity(
              velocity,
              normal,
              _massOf(current),
              _massOf(hit),
              _collisionRestitution(current, hit),
            ) *
            0.8;
        remaining = velocity.length;
        if (remaining > 0.001) {
          impulseDirection = velocity.normalized();
        }
        moves?.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: collisionTrigger,
            visualState: 'pressed',
            impactPosition: collision.position,
            impactNormal: normal,
          ),
        );
        events.add('balloon_bounced');
        continue;
      }

      if (hit.type == EntityType.stickySurface &&
          hit.traits.contains(TraitType.sticky) &&
          (hit.linkId == null || current.traits.contains(TraitType.sticky))) {
        stateTransitions?.add(
          PhysicsStateTransition(
            sourceEntityId: target.id,
            targetEntityId: current.id,
            targetType: current.type,
            pathIndex: collisionTrigger,
            previousState: current.visualState,
            nextState: 'stuck',
            position: collision.position,
            normal: normal,
          ),
        );
        entities = _replace(entities, hit.copyWith(visualState: 'stuck'));
        moves?.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: collisionTrigger,
            visualState: 'stuck',
            impactPosition: collision.position,
            impactNormal: normal,
          ),
        );
        break;
      }

      if (hit.type == EntityType.switchPad) {
        final isBalloonSwitch = hit.id == 'balloon_switch';
        final acceptsAnyBall =
            isBalloonSwitch ||
            hit.visualState == HiddenMechanicState.revealed ||
            hit.id.startsWith('sequence_switch_');
        if (!acceptsAnyBall &&
            !carriesHeavy &&
            !current.traits.contains(TraitType.heavy)) {
          events.add('switch_rejected');
          current = current.copyWith(visualState: 'blocked');
          break;
        }
        entities = _replace(
          entities,
          hit.copyWith(pressed: true, solid: false, visualState: 'pressed'),
        );
        moves?.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: collisionTrigger,
            visualState: 'pressed',
            impactPosition: collision.position,
            impactNormal: normal,
          ),
        );
        final linkedGates = hit.linkId == null
            ? entities.where((entity) => entity.type == EntityType.gate)
            : entities.where((entity) => entity.id == hit.linkId);
        for (final gate in linkedGates) {
          moves?.add(
            ShotAnimationMove(
              entityId: gate.id,
              from: gate.position,
              to: gate.position,
              triggerPathIndex: collisionTrigger + 2,
              visualState: 'opening',
            ),
          );
        }
        entities = hit.linkId == null
            ? _openGates(entities)
            : _openLinkedEntity(entities, hit.linkId!);
        stateTransitions?.add(
          PhysicsStateTransition(
            sourceEntityId: current.id,
            targetEntityId: hit.id,
            targetType: hit.type,
            pathIndex: collisionTrigger,
            previousState: hit.visualState,
            nextState: 'pressed',
            position: collision.position,
            normal: normal,
          ),
        );
        for (final gate in linkedGates) {
          stateTransitions?.add(
            PhysicsStateTransition(
              sourceEntityId: hit.id,
              targetEntityId: gate.id,
              targetType: gate.type,
              pathIndex: collisionTrigger,
              previousState: gate.visualState,
              nextState: 'open',
              position: gate.position,
              normal: normal,
            ),
          );
        }
        events.add('switch_pressed');
        if (isBalloonSwitch) {
          events.add('balloon_switch_pressed');
        }
        velocity *= 0.72;
        remaining = velocity.length;
        continue;
      }

      if (hit.type == EntityType.bumper &&
          hit.traits.contains(TraitType.bouncy)) {
        moves?.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: collisionTrigger,
            visualState: 'pushed',
            impactPosition: collision.position,
            impactNormal: normal,
          ),
        );
        velocity = _collisionVelocity(
          velocity,
          normal,
          _massOf(current),
          _massOf(hit),
          _collisionRestitution(current, hit),
        );
        final jellyScale = target.type == EntityType.ball ? 0.7 : 0.28;
        velocity *= jellyScale;
        remaining = velocity.length;
        if (remaining > 0.001) {
          impulseDirection = velocity.normalized();
        }
        events.add('jelly_bounced');
        continue;
      }

      if (hit.movable && hit.type != EntityType.wall) {
        final targetMass = _massOf(current);
        final hitMass = _massOf(hit);
        // 재귀 연쇄가 시작되기 전에 현재 물체를 공유 상태에 반영한다.
        // 그렇지 않으면 다음 물체가 이전 위치의 조상 물체를 후보로 보게 된다.
        entities = _replace(entities, current);
        final transferRatio = (targetMass * 2 / (targetMass + hitMass)).clamp(
          0.25,
          2.2,
        );
        entities = _pushWithMomentum(
          entities,
          hit,
          impulseDirection,
          velocity.length *
              0.68 *
              transferRatio *
              _restitutionMultiplier(current, hit),
          events,
          moves,
          collisionTrigger,
          normal,
          depth + 1,
          carriesHeavy || current.traits.contains(TraitType.heavy),
          {target.id},
          impacts,
          chainSafetyDiagnostics,
          stateTransitions,
          sliderContacts,
          powerSliderActivations,
          reflectorContacts,
          reflectorRotations,
        );
        events.add('chain_push');
        if (_anyBallInHole(entities)) {
          break;
        }
        final postVelocity = _collisionVelocity(
          velocity,
          normal,
          targetMass,
          hitMass,
          _collisionRestitution(current, hit),
        );
        velocity = postVelocity * 0.76;
        remaining = velocity.length;
        if (remaining > 0.001) {
          impulseDirection = velocity.normalized();
        }
        continue;
      }

      if (hit.type == EntityType.wall || hit.type == EntityType.gate) {
        events.add('bounced');
        current = current.copyWith(
          position: _separateMovingEntityFromCollision(
            hit,
            collisionEntity,
            normal,
          ),
          visualState: 'wall_bounced',
        );
        _appendMovePoint(path, current.position);
        // 벽과 문은 고정되어 있으므로 연쇄 물체도 활성 공과 같은
        // 무한 질량 반사식을 사용한다. 임의의 wallScale로 줄이면
        // 같은 입사각·재질인데 충돌 주체에 따라 물리 결과가 달라진다.
        velocity = _wallBounceVelocity(velocity, normal, current, hit);
        remaining = velocity.length;
        if (remaining > 0.001) {
          impulseDirection = velocity.normalized();
        }
        continue;
      }

      if (hit.type == EntityType.weight || hit.type == EntityType.crate) {
        final targetMass = _massOf(current);
        final hitMass = _massOf(hit);
        events.add('bounced');
        if (target.type == EntityType.ball && targetMass > hitMass * 0.8) {
          final postDirection = _postImpactDirection(
            impulseDirection,
            normal,
            targetMass,
            hitMass,
          );
          final postSpeed =
              velocity.length *
              _postImpactSpeedFactor(targetMass, hitMass) *
              0.72 *
              _restitutionMultiplier(current, hit);
          velocity = postDirection * postSpeed;
          remaining = velocity.length;
          impulseDirection = postDirection;
          continue;
        }
        current = current.copyWith(visualState: 'blocked');
        break;
      }

      current = current.copyWith(visualState: 'blocked');
      break;
    }

    if (velocity.length > 0.8 && iterations >= maxIterations) {
      events.add('chain_safety_stop');
      chainSafetyDiagnostics?.add(
        ChainSafetyDiagnostic(
          targetEntityId: target.id,
          pathIndex: triggerPathIndex + iterations,
          depth: depth,
          iterations: iterations,
          remainingDistance: remaining,
          remainingSpeed: velocity.length,
        ),
      );
    }

    if (current.position != target.position) {
      if (target.type == EntityType.crate && !events.contains('crate_pushed')) {
        events.add('crate_pushed');
      }
      moves?.add(
        ShotAnimationMove(
          entityId: target.id,
          from: target.position,
          to: current.position,
          triggerPathIndex: triggerPathIndex,
          visualState: current.visualState,
          path: path,
          impactPosition: path.length >= 2 ? path[path.length - 2] : null,
          impactNormal: contactNormal == Vec2.zero ? null : contactNormal,
        ),
      );
    }
    return _replace(entities, current);
  }

  void _appendMovePoint(List<Vec2> path, Vec2 point) {
    if (path.isEmpty || path.last.distanceTo(point) >= 1.2) {
      path.add(point);
    }
  }

  _MovingEntityCollision? _firstEntityCollisionAlongSegment(
    List<EntityState> entities,
    EntityState from,
    EntityState to,
    String ignoreId,
    Set<String> ignoredIds,
  ) {
    final distance = from.position.distanceTo(to.position);
    final steps = math.max(1, (distance / 1.25).ceil());
    _MovingEntityCollision? reflectorCandidate;
    var reflectorProgress = double.infinity;
    for (final entity in entities) {
      if (!_isMovingEntityCollisionCandidate(
            entity,
            from.id,
            ignoreId,
            ignoredIds,
          ) ||
          entity.type != EntityType.rotatingReflector) {
        continue;
      }
      final swept = _firstReflectorSweepHit(
        from,
        entity,
        from.position,
        to.position,
      );
      if (swept == null) continue;
      final candidateProgress = _segmentProgress(
        from.position,
        to.position,
        swept.position,
      );
      if (reflectorCandidate == null ||
          candidateProgress < reflectorProgress - _physicsEpsilon ||
          (candidateProgress - reflectorProgress).abs() <= _physicsEpsilon &&
              entity.id.compareTo(reflectorCandidate.entity.id) < 0) {
        reflectorCandidate = _MovingEntityCollision(
          entity: entity,
          position: swept.position,
          normal: swept.normal,
          startsOverlapping: swept.startsOverlapping,
        );
        reflectorProgress = candidateProgress;
      }
    }
    var previous = from.position;
    for (var step = 1; step <= steps; step++) {
      final progress = step / steps;
      final position = Vec2(
        from.position.x + (to.position.x - from.position.x) * progress,
        from.position.y + (to.position.y - from.position.y) * progress,
      );
      final candidate = from.copyWith(position: position);
      EntityState? bestHit;
      Vec2? bestPosition;
      var bestProgress = double.infinity;
      for (final entity in entities) {
        if (entity.type == EntityType.rotatingReflector ||
            !_isMovingEntityCollisionCandidate(
              entity,
              from.id,
              ignoreId,
              ignoredIds,
            ) ||
            !_collides(candidate, entity)) {
          continue;
        }
        var low = previous;
        var high = position;
        final previousCandidate = from.copyWith(position: previous);
        if (_collides(previousCandidate, entity)) {
          high = previous;
        } else {
          for (var iteration = 0; iteration < 8; iteration++) {
            final middle = Vec2((low.x + high.x) / 2, (low.y + high.y) / 2);
            if (_collides(from.copyWith(position: middle), entity)) {
              high = middle;
            } else {
              low = middle;
            }
          }
        }
        final candidateProgress = _segmentProgress(
          from.position,
          to.position,
          high,
        );
        if (bestHit == null ||
            candidateProgress < bestProgress - 0.0001 ||
            (candidateProgress - bestProgress).abs() <= 0.0001 &&
                entity.id.compareTo(bestHit.id) < 0) {
          bestHit = entity;
          bestPosition = high;
          bestProgress = candidateProgress;
        }
      }
      if (bestHit != null && bestPosition != null) {
        if (reflectorCandidate != null &&
            (reflectorProgress < bestProgress - _physicsEpsilon ||
                (reflectorProgress - bestProgress).abs() <= _physicsEpsilon &&
                    reflectorCandidate.entity.id.compareTo(bestHit.id) < 0)) {
          return reflectorCandidate;
        }
        return _MovingEntityCollision(entity: bestHit, position: bestPosition);
      }
      previous = position;
    }
    return reflectorCandidate;
  }

  bool _isMovingEntityCollisionCandidate(
    EntityState entity,
    String movingId,
    String ignoreId,
    Set<String> ignoredIds,
  ) {
    if (entity.id == movingId ||
        entity.id == ignoreId ||
        ignoredIds.contains(entity.id) ||
        entity.id == 'active_ball' ||
        !entity.active ||
        !_isSolidForPhysics(entity)) {
      return false;
    }
    return !(entity.type == EntityType.gate && entity.open);
  }

  Vec2 _collisionNormalForMovingEntity(EntityState moving, EntityState hit) {
    if (hit.type == EntityType.rotatingReflector) {
      if (!moving.isCircle) {
        return _reflectorAabbSatContact(hit, moving)?.normal ??
            _reflectorSeparationNormal(hit, moving.position);
      }
      return _reflectorSeparationNormal(hit, moving.position);
    }
    if (moving.isCircle && hit.isCircle) {
      final delta = moving.position - hit.position;
      return delta.length <= 0.001 ? const Vec2(1, 0) : delta.normalized();
    }
    if (hit.isCircle) {
      final delta = moving.position - hit.position;
      return delta.length <= 0.001 ? const Vec2(1, 0) : delta.normalized();
    }
    return _rectNormal(hit.hitBounds, moving.position);
  }

  Vec2 _separateMovingEntityFromCollision(
    EntityState hit,
    EntityState moving,
    Vec2 normal,
  ) {
    if (hit.type == EntityType.rotatingReflector) {
      final contact = _reflectorAabbSatContact(hit, moving);
      if (contact != null) {
        final separationNormal = normal.length <= _physicsEpsilon
            ? contact.normal
            : normal.normalized();
        return moving.position + separationNormal * (contact.penetration + 1.8);
      }
      final fallback = _reflectorContact(hit, moving.position);
      final separationNormal = normal.length <= _physicsEpsilon
          ? fallback.normal
          : normal.normalized();
      final support = _aabbSupportRadius(moving, separationNormal);
      return fallback.point + separationNormal * (support + 1.8);
    }
    if (moving.isCircle) {
      return _separateFromCollision(hit, moving, moving.position, normal);
    }
    final n = normal.normalized();
    final movingBounds = moving.hitBounds;
    final hitBounds = hit.hitBounds;
    if (n.x.abs() >= n.y.abs()) {
      final x = n.x < 0
          ? hitBounds.left - movingBounds.width / 2 - 1.8
          : hitBounds.right + movingBounds.width / 2 + 1.8;
      return Vec2(x, moving.position.y);
    }
    final y = n.y < 0
        ? hitBounds.top - movingBounds.height / 2 - 1.8
        : hitBounds.bottom + movingBounds.height / 2 + 1.8;
    return Vec2(moving.position.x, y);
  }

  bool _collides(EntityState a, EntityState b) {
    if (b.type == EntityType.gate && b.open) {
      return false;
    }
    if (b.type == EntityType.rotatingReflector) {
      return _orientedReflectorOverlaps(b, a);
    }
    if (a.type == EntityType.rotatingReflector) {
      return _orientedReflectorOverlaps(a, b);
    }
    if (a.isCircle && b.isCircle) {
      return a.position.distanceTo(b.position) <= a.hitRadius + b.hitRadius;
    }
    if (a.isCircle) {
      return b.hitBounds.intersectsCircle(a.position, a.hitRadius);
    }
    if (b.isCircle) {
      return a.hitBounds.intersectsCircle(b.position, b.hitRadius);
    }
    return a.hitBounds.left <= b.hitBounds.right &&
        a.hitBounds.right >= b.hitBounds.left &&
        a.hitBounds.top <= b.hitBounds.bottom &&
        a.hitBounds.bottom >= b.hitBounds.top;
  }

  double _segmentDistance(Vec2 a, Vec2 b, Vec2 point) {
    final ab = b - a;
    final lengthSquared = ab.dot(ab);
    if (lengthSquared == 0) {
      return a.distanceTo(point);
    }
    final t = ((point - a).dot(ab) / lengthSquared).clamp(0.0, 1.0);
    final projection = a + ab * t;
    return projection.distanceTo(point);
  }
}
