import 'dart:math' as math;

import 'geometry.dart';
import 'trait.dart';

enum EntityType {
  ball,
  hole,
  wall,
  crate,
  bumper,
  stickySurface,
  weight,
  switchPad,
  gate,
  balloon,
  spikeSource,
  powerSlider,
}

class EntityState {
  const EntityState({
    required this.id,
    required this.type,
    required this.position,
    required this.size,
    this.traits = const {},
    this.movable = false,
    this.solid = true,
    this.active = true,
    this.open = false,
    this.pressed = false,
    this.visualState = '',
    this.hitboxScale = 0.88,
    this.restitution = 0.72,
    this.linkId,
    this.direction = const Vec2(1, 0),
    this.referenceSpeed = 0,
    this.allowedTargets = const {},
  });

  final String id;
  final EntityType type;
  final Vec2 position;
  final Vec2 size;
  final Set<TraitType> traits;
  final bool movable;
  final bool solid;
  final bool active;
  final bool open;
  final bool pressed;
  final String visualState;
  final double hitboxScale;
  final double restitution;
  final String? linkId;

  /// 파워 슬라이더의 배치·시각 방향이다. 물리 이동 방향과 분리한다.
  final Vec2 direction;
  final double referenceSpeed;
  final Set<EntityType> allowedTargets;

  bool get isCircle =>
      type == EntityType.ball ||
      type == EntityType.hole ||
      type == EntityType.balloon;
  bool get isPowerSlider => type == EntityType.powerSlider;
  double get radius => math.min(size.x, size.y) / 2;
  double get hitRadius => radius * hitboxScale;
  Bounds get bounds => Bounds(
    left: position.x - size.x / 2,
    top: position.y - size.y / 2,
    width: size.x,
    height: size.y,
  );
  Bounds get hitBounds => bounds.scaled(hitboxScale);

  EntityState copyWith({
    String? id,
    EntityType? type,
    Vec2? position,
    Vec2? size,
    Set<TraitType>? traits,
    bool? movable,
    bool? solid,
    bool? active,
    bool? open,
    bool? pressed,
    String? visualState,
    double? hitboxScale,
    double? restitution,
    String? linkId,
    Vec2? direction,
    double? referenceSpeed,
    Set<EntityType>? allowedTargets,
  }) {
    return EntityState(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
      traits: traits ?? this.traits,
      movable: movable ?? this.movable,
      solid: solid ?? this.solid,
      active: active ?? this.active,
      open: open ?? this.open,
      pressed: pressed ?? this.pressed,
      visualState: visualState ?? this.visualState,
      hitboxScale: hitboxScale ?? this.hitboxScale,
      restitution: restitution ?? this.restitution,
      linkId: linkId ?? this.linkId,
      direction: direction ?? this.direction,
      referenceSpeed: referenceSpeed ?? this.referenceSpeed,
      allowedTargets: allowedTargets ?? this.allowedTargets,
    );
  }
}
