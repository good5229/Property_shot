import '../domain/entity_state.dart';
import '../domain/geometry.dart';
import '../domain/level_definition.dart';
import '../domain/trait.dart';

class PhysicsLabScenario {
  const PhysicsLabScenario({
    required this.id,
    required this.title,
    required this.question,
    required this.linkedStageIndex,
    required this.level,
  });

  final String id;
  final String title;
  final String question;
  final int linkedStageIndex;
  final LevelDefinition level;
}

const physicsLabScenarios = <PhysicsLabScenario>[
  PhysicsLabScenario(
    id: 'lab_heavy_crate_v1',
    title: '무거움과 상자',
    question: '무거운 공은 상자를 얼마나 밀 수 있을까요?',
    linkedStageIndex: 0,
    level: LevelDefinition(
      id: 'lab_heavy_crate_v1',
      stageId: 'stage_heavy',
      name: '실험실 · 무거움',
      ballSpawn: Vec2(62, 470),
      parShots: 4,
      entities: [
        EntityState(
          id: 'lab_weight',
          type: EntityType.weight,
          position: Vec2(72, 165),
          size: Vec2(54, 54),
          traits: {TraitType.heavy},
        ),
        EntityState(
          id: 'lab_crate',
          type: EntityType.crate,
          position: Vec2(185, 310),
          size: Vec2(48, 48),
          movable: true,
        ),
        EntityState(
          id: 'lab_hole',
          type: EntityType.hole,
          position: Vec2(300, 105),
          size: Vec2(48, 48),
          solid: false,
        ),
      ],
    ),
  ),
  PhysicsLabScenario(
    id: 'lab_bouncy_second_rebound_v1',
    title: '탄성이 남는 반사',
    question: '젤리 탄성은 두 번째 벽에서도 유지될까요?',
    linkedStageIndex: 1,
    level: LevelDefinition(
      id: 'lab_bouncy_second_rebound_v1',
      stageId: 'stage_bouncy',
      name: '실험실 · 탄성',
      ballSpawn: Vec2(62, 470),
      parShots: 4,
      entities: [
        EntityState(
          id: 'lab_jelly',
          type: EntityType.bumper,
          position: Vec2(80, 150),
          size: Vec2(58, 58),
          traits: {TraitType.bouncy},
          restitution: 1.18,
        ),
        EntityState(
          id: 'lab_wall_a',
          type: EntityType.wall,
          position: Vec2(185, 360),
          size: Vec2(150, 18),
        ),
        EntityState(
          id: 'lab_wall_b',
          type: EntityType.wall,
          position: Vec2(270, 235),
          size: Vec2(18, 155),
        ),
        EntityState(
          id: 'lab_hole',
          type: EntityType.hole,
          position: Vec2(305, 100),
          size: Vec2(48, 48),
          solid: false,
        ),
      ],
    ),
  ),
  PhysicsLabScenario(
    id: 'lab_sticky_chain_v1',
    title: '점착과 남은 공',
    question: '붙여 둔 공을 다음 발사의 발판으로 쓸 수 있을까요?',
    linkedStageIndex: 6,
    level: LevelDefinition(
      id: 'lab_sticky_chain_v1',
      stageId: 'stage_persistent',
      name: '실험실 · 점착',
      ballSpawn: Vec2(62, 470),
      parShots: 5,
      entities: [
        EntityState(
          id: 'lab_sticky',
          type: EntityType.stickySurface,
          position: Vec2(74, 150),
          size: Vec2(62, 34),
          traits: {TraitType.sticky},
        ),
        EntityState(
          id: 'lab_wall',
          type: EntityType.wall,
          position: Vec2(210, 300),
          size: Vec2(20, 170),
        ),
        EntityState(
          id: 'lab_hole',
          type: EntityType.hole,
          position: Vec2(305, 110),
          size: Vec2(48, 48),
          solid: false,
        ),
      ],
    ),
  ),
  PhysicsLabScenario(
    id: 'lab_sharp_balloon_v1',
    title: '뾰족함과 풍선',
    question: '뾰족한 공으로 풍선을 터뜨리면 길이 어떻게 바뀔까요?',
    linkedStageIndex: 3,
    level: LevelDefinition(
      id: 'lab_sharp_balloon_v1',
      stageId: 'stage_balloon',
      name: '실험실 · 뾰족함',
      ballSpawn: Vec2(62, 470),
      parShots: 4,
      entities: [
        EntityState(
          id: 'lab_spike',
          type: EntityType.spikeSource,
          position: Vec2(72, 160),
          size: Vec2(48, 48),
          traits: {TraitType.sharp},
        ),
        EntityState(
          id: 'lab_balloon',
          type: EntityType.balloon,
          position: Vec2(190, 300),
          size: Vec2(54, 54),
        ),
        EntityState(
          id: 'lab_hole',
          type: EntityType.hole,
          position: Vec2(305, 110),
          size: Vec2(48, 48),
          solid: false,
        ),
      ],
    ),
  ),
  PhysicsLabScenario(
    id: 'lab_switch_gate_v1',
    title: '스위치와 문',
    question: '스위치를 눌러 닫힌 문을 열어 보세요.',
    linkedStageIndex: 2,
    level: LevelDefinition(
      id: 'lab_switch_gate_v1',
      stageId: 'stage_chain_gate',
      name: '실험실 · 스위치',
      ballSpawn: Vec2(62, 470),
      parShots: 5,
      entities: [
        EntityState(
          id: 'lab_weight',
          type: EntityType.weight,
          position: Vec2(72, 155),
          size: Vec2(50, 50),
          traits: {TraitType.heavy},
        ),
        EntityState(
          id: 'lab_switch',
          type: EntityType.switchPad,
          position: Vec2(165, 350),
          size: Vec2(54, 24),
          linkId: 'lab_gate',
        ),
        EntityState(
          id: 'lab_gate',
          type: EntityType.gate,
          position: Vec2(240, 245),
          size: Vec2(22, 155),
          linkId: 'lab_gate',
        ),
        EntityState(
          id: 'lab_hole',
          type: EntityType.hole,
          position: Vec2(305, 100),
          size: Vec2(48, 48),
          solid: false,
        ),
      ],
    ),
  ),
];
