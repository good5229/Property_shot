import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../domain/trait.dart';

class ShotResult {
  const ShotResult({
    required this.state,
    required this.path,
    required this.events,
    this.moves = const [],
  });

  final GameState state;
  final List<Vec2> path;
  final List<String> events;
  final List<ShotAnimationMove> moves;
}

class ShotAnimationMove {
  const ShotAnimationMove({
    required this.entityId,
    required this.from,
    required this.to,
    required this.triggerPathIndex,
  });

  final String entityId;
  final Vec2 from;
  final Vec2 to;
  final int triggerPathIndex;
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

class ShotResolver {
  const ShotResolver();

  ShotResult resolve(GameState state, ShotInput rawInput) {
    final input = rawInput.normalized();
    final beforeShot = state.copyWith(history: const []);
    var entities = state.entities.map((entity) => entity).toList();
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
    var success = false;
    var stopped = false;
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

      final hole = _findHole(entities);
      if (hole != null &&
          _segmentDistance(previousPosition, position, hole.position) <=
              hole.radius + ball.hitRadius * 0.75 &&
          _gateOpen(entities)) {
        events.add('hole_entered');
        success = true;
        break;
      }
      if (_anyBallInHole(entities)) {
        events.add('existing_ball_hole_entered');
        success = true;
        break;
      }

      final collision = _firstCollision(entities, ball, position);
      if (collision == null) {
        continue;
      }
      final hit = collision.entity;

      if (hit.type == EntityType.gate && hit.open) {
        continue;
      }

      if (hit.type == EntityType.switchPad) {
        final heavy = ball.traits.contains(TraitType.heavy);
        entities = _replace(
          entities,
          hit.copyWith(
            pressed: heavy,
            visualState: heavy ? 'pressed' : 'needs-heavy',
          ),
        );
        if (heavy) {
          entities = _openGates(entities);
          events.add('switch_pressed');
          direction = Vec2(direction.x, -direction.y).normalized();
          continue;
        }
        events.add('switch_rejected');
        stopped = true;
        break;
      }

      if (ball.traits.contains(TraitType.sticky) &&
          (hit.type == EntityType.wall ||
              hit.type == EntityType.stickySurface ||
              hit.type == EntityType.crate ||
              hit.type == EntityType.ball)) {
        events.add('sticky_attached');
        stopped = true;
        break;
      }

      if (hit.type == EntityType.crate) {
        final heavy = ball.traits.contains(TraitType.heavy);
        if (heavy || input.power >= 0.55) {
          entities = _pushWithMomentum(
            entities,
            hit,
            direction,
            heavy ? 126 : 54,
            events,
            moves,
            path.length - 1,
            collision.normal,
          );
          events.add('crate_pushed');
          speed *= heavy ? 0.78 : 0.56;
          if (_anyBallInHole(entities) ||
              _anyBallMoveEnteredHole(entities, moves)) {
            events.add('existing_ball_hole_entered');
            success = true;
            break;
          }
          direction = _postImpactDirection(
            direction,
            collision.normal,
            movingMass,
            _massOf(hit),
          );
          continue;
        }
        events.add('crate_blocked');
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
        );
        if (_anyBallInHole(entities) ||
            _anyBallMoveEnteredHole(entities, moves)) {
          events.add('existing_ball_hole_entered');
          success = true;
          break;
        }
        direction = _postImpactDirection(
          direction,
          collision.normal,
          movingMass,
          targetMass,
        );
        speed *= _postImpactSpeedFactor(movingMass, targetMass);
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
          ),
        );
        direction = _reflect(direction, collision.normal);
        speed *= 0.72;
        events.add('jelly_bounced');
        continue;
      }

      if (hit.movable && hit.type != EntityType.wall) {
        entities = _pushWithMomentum(
          entities,
          hit,
          direction,
          52,
          events,
          moves,
          path.length - 1,
          collision.normal,
        );
        if (_anyBallInHole(entities) ||
            _anyBallMoveEnteredHole(entities, moves)) {
          events.add('existing_ball_hole_entered');
          success = true;
          break;
        }
        direction = _reflect(direction, collision.normal);
        speed *= 0.68;
        events.add('momentum_transfer');
        continue;
      }

      if (hit.type == EntityType.wall || hit.type == EntityType.gate) {
        direction = _reflect(direction, collision.normal);
        speed *= 0.72;
        events.add('bounced');
        continue;
      }

      if (hit.type == EntityType.weight) {
        direction = _postImpactDirection(
          direction,
          collision.normal,
          movingMass,
          _massOf(hit),
        );
        speed *= _postImpactSpeedFactor(movingMass, _massOf(hit)) * 0.82;
        events.add('bounced');
        continue;
      }

      if (hit.type == EntityType.stickySurface) {
        direction = _reflect(direction, collision.normal);
        speed *= 0.48;
        events.add('bounced');
        continue;
      }

      if (hit.type == EntityType.hole) {
        stopped = true;
        break;
      }

      if (ball.traits.contains(TraitType.bouncy)) {
        direction = _reflect(direction, collision.normal);
        speed *= 0.88;
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
      movable: true,
      visualState: success ? 'scored' : 'spent',
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
        if (entity.id != state.activeBall.id) entity,
      landedBall,
      if (!success) activeBall,
    ];

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

    return ShotResult(state: next, path: path, events: events, moves: moves);
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
      final collision = _firstCollision(state.entities, ball, position);
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
      return entity.position.distanceTo(hole.position) <=
          hole.radius + entity.hitRadius * 0.85;
    });
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
      if (_segmentDistance(move.from, move.to, hole.position) <=
          hole.radius + entity.hitRadius * 0.85) {
        return true;
      }
    }
    return false;
  }

  bool _gateOpen(List<EntityState> entities) {
    return entities
        .where((entity) => entity.type == EntityType.gate)
        .every((entity) => entity.open);
  }

  CollisionHit? _firstCollision(
    List<EntityState> entities,
    EntityState ball,
    Vec2 position,
  ) {
    for (final entity in entities) {
      if (entity.id == ball.id || !entity.active || !entity.solid) {
        continue;
      }
      if (entity.type == EntityType.gate && entity.open) {
        continue;
      }
      if (entity.isCircle) {
        if (position.distanceTo(entity.position) <=
            ball.hitRadius + entity.hitRadius) {
          return CollisionHit(
            entity: entity,
            normal: (position - entity.position).normalized(),
          );
        }
      } else if (entity.hitBounds.intersectsCircle(position, ball.hitRadius)) {
        return CollisionHit(
          entity: entity,
          normal: _rectNormal(entity.hitBounds, position),
        );
      }
    }
    return null;
  }

  Vec2 _reflect(Vec2 direction, Vec2 normal) {
    return direction.reflectedBy(normal);
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
      return (position - hit.position).normalized();
    }
    return _rectNormal(hit.hitBounds, position);
  }

  Vec2 _rectNormal(Bounds bounds, Vec2 impact) {
    final nearest = bounds.nearestPoint(impact);
    var normal = impact - nearest;
    if (normal.length > 0.001) {
      return normal.normalized();
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
    if (events.contains('switch_rejected')) {
      return '스위치에는 무거움이 필요합니다.';
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
  ]) {
    if (!target.movable || target.type == EntityType.wall || depth > 3) {
      return entities;
    }

    final strength = math.max(0.22, -direction.normalized().dot(contactNormal));
    final travelDirection = direction.normalized();
    final normalImpulse = contactNormal == Vec2.zero
        ? travelDirection
        : (-contactNormal).normalized();
    final impulseDirection = travelDirection.dot(normalImpulse) < 0
        ? travelDirection
        : normalImpulse;
    var candidate = target.copyWith(
      position: target.position + impulseDirection * (distance * strength),
      visualState: 'pushed',
    );

    for (final other in entities) {
      if (other.id == target.id || !other.active || !other.solid) {
        continue;
      }
      if (!_collides(candidate, other)) {
        continue;
      }
      if (other.movable && other.type != EntityType.wall) {
        entities = _pushWithMomentum(
          entities,
          other,
          direction,
          distance * 0.62,
          events,
          moves,
          triggerPathIndex + 5,
          contactNormal,
          depth + 1,
        );
        events.add('chain_push');
      } else {
        candidate = target.copyWith(visualState: 'blocked');
        break;
      }
    }

    if (candidate.position != target.position) {
      moves?.add(
        ShotAnimationMove(
          entityId: target.id,
          from: target.position,
          to: candidate.position,
          triggerPathIndex: triggerPathIndex + depth * 5,
        ),
      );
    }
    return _replace(entities, candidate);
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
    return a.hitBounds.left < b.hitBounds.right &&
        a.hitBounds.right > b.hitBounds.left &&
        a.hitBounds.top < b.hitBounds.bottom &&
        a.hitBounds.bottom > b.hitBounds.top;
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
