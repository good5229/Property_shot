import 'entity_state.dart';
import 'game_state.dart';
import 'geometry.dart';

class LevelDefinition {
  const LevelDefinition({
    required this.name,
    required this.ballSpawn,
    required this.entities,
    this.requiresStickyAnchor = false,
  });

  final String name;
  final Vec2 ballSpawn;
  final List<EntityState> entities;
  final bool requiresStickyAnchor;

  GameState createState(int index) {
    return GameState(
      levelIndex: index,
      levelName: name,
      ballSpawn: ballSpawn,
      requiresStickyAnchor: requiresStickyAnchor,
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
