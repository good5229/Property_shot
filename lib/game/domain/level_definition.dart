import 'entity_state.dart';
import 'game_state.dart';
import 'geometry.dart';
import 'trait.dart';

class LevelDefinition {
  const LevelDefinition({
    required this.name,
    required this.ballSpawn,
    required this.entities,
    this.requiresStickyAnchor = false,
    this.requiredHoleTrait,
    this.requiresCratePush = false,
  });

  final String name;
  final Vec2 ballSpawn;
  final List<EntityState> entities;
  final bool requiresStickyAnchor;
  final TraitType? requiredHoleTrait;
  final bool requiresCratePush;

  GameState createState(int index) {
    return GameState(
      levelIndex: index,
      levelName: name,
      ballSpawn: ballSpawn,
      requiresStickyAnchor: requiresStickyAnchor,
      requiredHoleTrait: requiredHoleTrait,
      requiresCratePush: requiresCratePush,
      entities: [
        EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: ballSpawn,
          size: const Vec2(24, 24),
          traits: const {},
          movable: true,
        ),
        ...entities,
      ],
    );
  }
}
