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
  rotatingReflector,
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
    this.reflectorOrientation = 0,
    this.reflectorRotationCount = 0,
    this.movableWhenDrained = false,
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

  /// 회전 반사판의 현재 법선 방향(0~7)과 누적 회전 횟수다.
  /// 화면 좌표(y가 아래로 증가)에서 0은 위쪽이며, 값이 1씩 늘 때
  /// 시계 방향으로 45도씩 증가한다. 90도 회전은 `(방향 + 2) % 8`이다.
  /// 회전판이 아닌 엔티티에는 기본값을 사용하고 JSON에 기록하지 않는다.
  final int reflectorOrientation;
  final int reflectorRotationCount;

  /// 속성 이전으로 마지막 속성을 잃었을 때 이동 가능한 물체가 되는지 나타낸다.
  final bool movableWhenDrained;

  bool get isCircle =>
      type == EntityType.ball ||
      type == EntityType.hole ||
      type == EntityType.balloon;
  bool get isPowerSlider => type == EntityType.powerSlider;
  bool get isRotatingReflector => type == EntityType.rotatingReflector;
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
    int? reflectorOrientation,
    int? reflectorRotationCount,
    bool? movableWhenDrained,
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
      reflectorOrientation: reflectorOrientation ?? this.reflectorOrientation,
      reflectorRotationCount:
          reflectorRotationCount ?? this.reflectorRotationCount,
      movableWhenDrained: movableWhenDrained ?? this.movableWhenDrained,
    );
  }
}
