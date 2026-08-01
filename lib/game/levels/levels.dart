import '../domain/entity_state.dart';
import '../domain/geometry.dart';
import '../domain/level_definition.dart';
import '../domain/trait.dart';

const logicalSize = Vec2(360, 560);

final levels = <LevelDefinition>[
  LevelDefinition(
    name: '1. 무거움 익히기',
    ballSpawn: const Vec2(56, 456),
    requiredHoleTrait: TraitType.heavy,
    requiresCratePush: true,
    entities: const [
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(302, 132),
        size: Vec2(42, 42),
        solid: false,
      ),
      EntityState(
        id: 'wall_top',
        type: EntityType.wall,
        position: Vec2(180, 12),
        size: Vec2(340, 24),
      ),
      EntityState(
        id: 'wall_left',
        type: EntityType.wall,
        position: Vec2(12, 280),
        size: Vec2(24, 520),
      ),
      EntityState(
        id: 'wall_right',
        type: EntityType.wall,
        position: Vec2(348, 280),
        size: Vec2(24, 520),
      ),
      EntityState(
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(178, 286),
        size: Vec2(42, 42),
        movable: true,
        hitboxScale: 0.82,
      ),
      EntityState(
        id: 'anvil',
        type: EntityType.weight,
        position: Vec2(78, 154),
        size: Vec2(52, 38),
        traits: {TraitType.heavy},
        hitboxScale: 0.84,
      ),
    ],
  ),
  LevelDefinition(
    name: '2. 탄성 익히기',
    ballSpawn: const Vec2(58, 462),
    requiredHoleTrait: TraitType.bouncy,
    entities: const [
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(100, 110),
        size: Vec2(42, 42),
        solid: false,
      ),
      EntityState(
        id: 'wall_top',
        type: EntityType.wall,
        position: Vec2(180, 12),
        size: Vec2(340, 24),
      ),
      EntityState(
        id: 'wall_left',
        type: EntityType.wall,
        position: Vec2(12, 280),
        size: Vec2(24, 520),
      ),
      EntityState(
        id: 'wall_right',
        type: EntityType.wall,
        position: Vec2(348, 280),
        size: Vec2(24, 520),
      ),
      EntityState(
        id: 'blocker',
        type: EntityType.wall,
        position: Vec2(220, 270),
        size: Vec2(24, 300),
        restitution: 0.08,
      ),
      EntityState(
        id: 'approach_guard',
        type: EntityType.wall,
        position: Vec2(95, 230),
        size: Vec2(70, 24),
        restitution: 0.08,
      ),
      EntityState(
        id: 'jelly',
        type: EntityType.bumper,
        position: Vec2(300, 450),
        size: Vec2(58, 42),
        traits: {TraitType.bouncy},
      ),
    ],
  ),
  LevelDefinition(
    name: '3. 연쇄 문 열기',
    ballSpawn: const Vec2(56, 466),
    requiresStickyAnchor: true,
    entities: const [
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(304, 96),
        size: Vec2(34, 34),
        solid: false,
      ),
      EntityState(
        id: 'wall_top',
        type: EntityType.wall,
        position: Vec2(180, 12),
        size: Vec2(340, 24),
      ),
      EntityState(
        id: 'wall_left',
        type: EntityType.wall,
        position: Vec2(12, 280),
        size: Vec2(24, 520),
      ),
      EntityState(
        id: 'wall_right',
        type: EntityType.wall,
        position: Vec2(348, 280),
        size: Vec2(24, 520),
      ),
      EntityState(
        id: 'gate',
        type: EntityType.gate,
        position: Vec2(238, 226),
        size: Vec2(28, 118),
      ),
      EntityState(
        id: 'switch',
        type: EntityType.switchPad,
        position: Vec2(154, 352),
        size: Vec2(70, 22),
        solid: true,
      ),
      EntityState(
        id: 'steel',
        type: EntityType.weight,
        position: Vec2(80, 146),
        size: Vec2(52, 38),
        traits: {TraitType.heavy},
      ),
      EntityState(
        id: 'glue',
        type: EntityType.stickySurface,
        position: Vec2(300, 334),
        size: Vec2(50, 86),
        traits: {TraitType.sticky},
      ),
      EntityState(
        id: 'crate_b',
        type: EntityType.crate,
        position: Vec2(154, 292),
        size: Vec2(48, 48),
        movable: true,
      ),
    ],
  ),
];
