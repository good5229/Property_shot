import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../domain/trait.dart';
import '../levels/levels.dart';

class ShotResult {
  const ShotResult({
    required this.state,
    required this.path,
    required this.events,
    this.moves = const [],
    this.impacts = const [],
  });

  final GameState state;
  final List<Vec2> path;
  final List<String> events;
  final List<ShotAnimationMove> moves;
  final List<ShotImpact> impacts;
}

class ShotImpact {
  const ShotImpact({
    required this.entityId,
    required this.entityType,
    required this.position,
    required this.normal,
    required this.pathIndex,
    required this.strength,
  });

  final String entityId;
  final EntityType entityType;
  final Vec2 position;
  final Vec2 normal;
  final int pathIndex;
  final double strength;
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

class CollisionHit {
  const CollisionHit({required this.entity, required this.normal});

  final EntityState entity;
  final Vec2 normal;
}

class CollisionSample {
  const CollisionSample({required this.hit, required this.position});

  final CollisionHit hit;
  final Vec2 position;
}

class _MovingEntityCollision {
  const _MovingEntityCollision({required this.entity, required this.position});

  final EntityState entity;
  final Vec2 position;
}

class ShotResolver {
  const ShotResolver();

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
    var success = false;
    var stopped = false;
    var holeContractRejected = false;
    var previousPosition = position;

    for (
      var traveled = 0.0;
      traveled < distanceBudget && speed > 1.8 && !stopped && !success;
      traveled += speed
    ) {
      previousPosition = position;
      position = position + direction * speed;
      path.add(position);
      speed *= 0.982;

      final collisionSample = _firstCollisionAlongSegment(
        entities,
        ball,
        previousPosition,
        position,
      );
      final hole = _findHole(entities);
      final holeCaptureRadius = hole == null
          ? 0.0
          : hole.radius + ball.hitRadius;
      final holeProgress = hole == null
          ? double.infinity
          : _segmentCircleEntryProgress(
              previousPosition,
              position,
              hole.position,
              holeCaptureRadius,
            );
      final collisionProgress = collisionSample == null
          ? double.infinity
          : _segmentProgress(
              previousPosition,
              position,
              collisionSample.position,
            );
      if (hole != null &&
          holeProgress.isFinite &&
          _segmentDistance(previousPosition, position, hole.position) <=
              holeCaptureRadius &&
          holeProgress <= collisionProgress + 0.001 &&
          _gateOpen(entities)) {
        final traitAllowed =
            state.requiredHoleTrait == null ||
            ball.traits.contains(state.requiredHoleTrait);
        final crateAllowed =
            !state.requiresCratePush || events.contains('crate_pushed');
        if (traitAllowed && crateAllowed) {
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
            ),
          );
          events.add('hole_entered');
          success = true;
          break;
        }
        if (!holeContractRejected) {
          events.add(
            !traitAllowed ? 'hole_rejected_trait' : 'hole_rejected_crate',
          );
          holeContractRejected = true;
        }
      }
      if (_anyBallInHole(entities) &&
          _existingHoleContractSatisfied(state, entities)) {
        events.add('existing_ball_hole_entered');
        success = true;
        break;
      }
      if (collisionSample == null) {
        continue;
      }
      position = collisionSample.position;
      path[path.length - 1] = position;
      final collision = collisionSample.hit;
      final hit = collision.entity;
      impacts.add(
        ShotImpact(
          entityId: hit.id,
          entityType: hit.type,
          position: position,
          normal: collision.normal,
          pathIndex: path.length - 1,
          strength: (speed / 24).clamp(0.18, 1.0),
        ),
      );

      if (hit.type == EntityType.gate && hit.open) {
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
        events.add('sticky_attached');
        stopped = true;
        break;
      }

      if (hit.type == EntityType.switchPad) {
        if (!ball.traits.contains(TraitType.heavy)) {
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
        if (state.requiresStickyAnchor && !_hasStickyAnchor(entities)) {
          position = _separateFromCollision(
            hit,
            ball,
            position,
            collision.normal,
          );
          path[path.length - 1] = position;
          events.add('switch_rejected_sticky');
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
        for (final gate in entities.where(
          (entity) => entity.type == EntityType.gate,
        )) {
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
        entities = _openGates(entities);
        events.add('switch_pressed');
        speed *= 0.82;
        continue;
      }

      if (hit.type == EntityType.stickySurface) {
        position = _separateFromCollision(
          hit,
          ball,
          position,
          collision.normal,
        );
        path[path.length - 1] = position;
        entities = _replace(entities, hit.copyWith(visualState: 'stuck'));
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'stuck',
            impactPosition: position,
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
            state.requiresStickyAnchor,
            const {},
            impacts,
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
          if ((_anyBallInHole(entities) &&
                  _holeContractSatisfiedForShot(
                    state,
                    ball,
                    entities,
                    events,
                  )) ||
              (_holeContractSatisfiedForShot(state, ball, entities, events) &&
                  _anyBallMoveEnteredHole(entities, moves))) {
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
          state.requiresStickyAnchor,
          const {},
          impacts,
        );
        if ((_anyBallInHole(entities) &&
                _holeContractSatisfiedForShot(state, ball, entities, events)) ||
            (_holeContractSatisfiedForShot(state, ball, entities, events) &&
                _anyBallMoveEnteredHole(entities, moves))) {
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

      if (hit.type == EntityType.bumper) {
        moves.add(
          ShotAnimationMove(
            entityId: hit.id,
            from: hit.position,
            to: hit.position,
            triggerPathIndex: path.length - 1,
            visualState: 'pushed',
            impactPosition: position,
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
        entities = _pushWithMomentum(
          entities,
          hit,
          direction,
          24 + 52 * impulseScale,
          events,
          moves,
          path.length - 1,
          collision.normal,
          0,
          ball.traits.contains(TraitType.heavy),
          state.requiresStickyAnchor,
          const {},
          impacts,
        );
        if ((_anyBallInHole(entities) &&
                _holeContractSatisfiedForShot(state, ball, entities, events)) ||
            (_holeContractSatisfiedForShot(state, ball, entities, events) &&
                _anyBallMoveEnteredHole(entities, moves))) {
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
            impactPosition: position,
            impactNormal: collision.normal,
          ),
        );
        direction = _reflect(direction, collision.normal);
        final wallRestitution = ball.traits.contains(TraitType.bouncy)
            ? math.max(hit.restitution, 0.88)
            : hit.restitution;
        speed *= wallRestitution;
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

    final landedBall = ball.copyWith(
      id: 'spent_ball_${state.shotCount + 1}',
      position: position,
      traits: ball.traits,
      movable: !events.contains('sticky_attached'),
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
      traits: input.equippedTrait == null ? const {} : {input.equippedTrait!},
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
      clearEquippedTrait: !success,
      message: success ? '홀 진입 성공!' : _messageFor(events),
      history: [beforeShot, ...state.history],
    );

    return ShotResult(
      state: next,
      path: path,
      events: events,
      moves: moves,
      impacts: impacts,
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

  GameState rewind(GameState state) {
    if (state.history.isEmpty) {
      return state.copyWith(message: '되감기할 샷이 없습니다.');
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
    if (!_gateOpen(entities)) {
      return false;
    }
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
          hole.radius + entity.hitRadius * 0.85;
    });
  }

  bool _existingHoleContractSatisfied(
    GameState state,
    List<EntityState> entities,
  ) {
    final traitSatisfied =
        state.requiredHoleTrait == null ||
        entities.any(
          (entity) =>
              entity.type == EntityType.ball &&
              entity.id != 'active_ball' &&
              entity.traits.contains(state.requiredHoleTrait),
        );
    final crateSatisfied =
        !state.requiresCratePush ||
        entities.any(
          (entity) =>
              entity.type == EntityType.crate && entity.visualState == 'pushed',
        );
    return traitSatisfied && crateSatisfied;
  }

  bool _holeContractSatisfiedForShot(
    GameState state,
    EntityState ball,
    List<EntityState> entities,
    List<String> events,
  ) {
    final traitSatisfied =
        state.requiredHoleTrait == null ||
        ball.traits.contains(state.requiredHoleTrait);
    final crateSatisfied =
        !state.requiresCratePush ||
        events.contains('crate_pushed') ||
        entities.any(
          (entity) =>
              entity.type == EntityType.crate && entity.visualState == 'pushed',
        );
    return traitSatisfied && crateSatisfied;
  }

  bool _anyBallMoveEnteredHole(
    List<EntityState> entities,
    List<ShotAnimationMove> moves,
  ) {
    if (!_gateOpen(entities)) {
      return false;
    }
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
      final tolerance = hole.radius + entity.hitRadius * 0.85;
      for (var index = 1; index < points.length; index++) {
        if (_segmentDistance(points[index - 1], points[index], hole.position) <=
            tolerance) {
          return true;
        }
      }
    }
    return false;
  }

  bool _gateOpen(List<EntityState> entities) {
    return entities
        .where((entity) => entity.type == EntityType.gate)
        .every((entity) => entity.open);
  }

  bool _hasStickyAnchor(List<EntityState> entities) {
    return entities.any(
      (entity) =>
          entity.type == EntityType.ball &&
          entity.visualState == 'stuck' &&
          !entity.movable,
    );
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
        final candidate = CollisionHit(
          entity: entity,
          normal: _collisionNormal(ball, entity, high),
        );
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
        return CollisionSample(hit: bestHit, position: bestPosition);
      }
      previous = position;
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

  double _massOf(EntityState entity) {
    if (entity.traits.contains(TraitType.heavy)) {
      return 4.4;
    }
    return switch (entity.type) {
      EntityType.ball => 1.0,
      EntityType.crate => 2.0,
      EntityType.weight => 5.2,
      EntityType.bumper => 1.4,
      EntityType.stickySurface => 2.6,
      EntityType.switchPad => 3.0,
      EntityType.gate => 8.0,
      EntityType.wall => 999.0,
      EntityType.hole => 0.0,
    };
  }

  Vec2 _collisionNormal(EntityState ball, EntityState hit, Vec2 position) {
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

  List<EntityState> _openGates(List<EntityState> entities) {
    return [
      for (final entity in entities)
        if (entity.type == EntityType.gate)
          entity.copyWith(open: true, solid: false, visualState: 'open')
        else
          entity,
    ];
  }

  String _messageFor(List<String> events) {
    if (events.contains('hole_rejected_crate')) {
      return '상자를 먼저 밀어야 홀에 들어갈 수 있습니다.';
    }
    if (events.contains('hole_rejected_trait')) {
      return '이 단계의 홀에는 탄성 속성이 필요합니다.';
    }
    if (events.contains('switch_rejected_sticky')) {
      return '점착판에 공을 먼저 붙여 발판을 만들어야 합니다.';
    }
    if (events.contains('switch_pressed')) {
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
      return '접착 속성으로 표면에 붙었습니다.';
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
    bool requiresStickyAnchor = false,
    Set<String> chainIds = const {},
    List<ShotImpact>? impacts,
  ]) {
    // 연쇄 깊이를 임의의 상수로 자르면 물체 수가 많은 스테이지에서
    // 충돌 이벤트가 누락된다. 한 번의 연쇄에서 같은 엔티티를 계속
    // 재귀 처리하는 것은 별도 물리 계산 없이도 진행을 끝낼 수 없으므로,
    // 현재 스테이지의 엔티티 수를 상한으로 사용한다.
    if (!target.movable ||
        target.type == EntityType.wall ||
        depth >= entities.length) {
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
    final chainCollisionIds = chainIds.isEmpty ? <String>{target.id} : chainIds;
    chainCollisionIds.add(target.id);
    var remaining = distance * strength;
    var velocity = impulseDirection * remaining;
    var iterations = 0;
    final path = <Vec2>[target.position];

    while (velocity.length > 0.8 && iterations < 96) {
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
        chainCollisionIds,
      );
      final hole = _findHole(entities);
      final holeCaptureRadius = hole == null
          ? 0.0
          : hole.radius + current.hitRadius;
      final holeProgress =
          current.type == EntityType.ball && hole != null && _gateOpen(entities)
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
      if (hole != null &&
          holeProgress.isFinite &&
          _segmentDistance(
                current.position,
                candidate.position,
                hole.position,
              ) <=
              holeCaptureRadius &&
          holeProgress <= collisionProgress + 0.001) {
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
          ),
        );
        entities = _replace(entities, current);
        events.add('chain_hole_entered');
        break;
      }
      if (collision == null) {
        current = candidate;
        velocity = stepDirection * math.max(0.0, availableSpeed - step);
        impulseDirection = stepDirection;
        remaining = velocity.length;
        _appendMovePoint(path, current.position);
        continue;
      }

      final hit = collision.entity;
      if (hit.type != EntityType.wall && hit.type != EntityType.gate) {
        chainCollisionIds.add(hit.id);
      }
      final collisionEntity = candidate.copyWith(position: collision.position);
      final normal = _collisionNormalForMovingEntity(collisionEntity, hit);
      final collisionTrigger = triggerPathIndex + iterations;
      impacts?.add(
        ShotImpact(
          entityId: hit.id,
          entityType: hit.type,
          position: collision.position,
          normal: normal,
          pathIndex: collisionTrigger,
          strength: (velocity.length / 24).clamp(0.18, 1.0),
        ),
      );
      current = candidate.copyWith(
        position: _separateMovingEntityFromCollision(
          hit,
          collisionEntity,
          normal,
        ),
        movable: hit.type == EntityType.stickySurface ? false : current.movable,
        visualState: hit.type == EntityType.stickySurface ? 'stuck' : 'pushed',
      );
      _appendMovePoint(path, collision.position);
      _appendMovePoint(path, current.position);
      events.add('chain_collision_${hit.type.name}');

      if (hit.type == EntityType.stickySurface) {
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
        if (!carriesHeavy && !current.traits.contains(TraitType.heavy)) {
          events.add('switch_rejected');
          current = current.copyWith(visualState: 'blocked');
          break;
        }
        if (requiresStickyAnchor && !_hasStickyAnchor(entities)) {
          events.add('switch_rejected_sticky');
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
        for (final gate in entities.where(
          (entity) => entity.type == EntityType.gate,
        )) {
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
        entities = _openGates(entities);
        events.add('switch_pressed');
        velocity *= 0.72;
        remaining = velocity.length;
        continue;
      }

      if (hit.type == EntityType.bumper) {
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
          requiresStickyAnchor,
          chainCollisionIds,
          impacts,
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
        velocity = _collisionVelocity(
          velocity,
          normal,
          _massOf(current),
          _massOf(hit),
          _collisionRestitution(current, hit),
        );
        final wallScale = target.type == EntityType.ball ? 0.58 : 0.34;
        velocity *= wallScale;
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
        if (!_isMovingEntityCollisionCandidate(
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
        return _MovingEntityCollision(entity: bestHit, position: bestPosition);
      }
      previous = position;
    }
    return null;
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
