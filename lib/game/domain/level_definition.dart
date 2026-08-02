import 'entity_state.dart';
import 'game_state.dart';
import 'geometry.dart';

class LevelDefinition {
  const LevelDefinition({
    required this.name,
    required this.ballSpawn,
    required this.entities,
    this.copyCharges = 1,
    this.parShots = 3,
    this.bonusGoal = '복사 없이 클리어',
  });

  final String name;
  final Vec2 ballSpawn;
  final List<EntityState> entities;
  final int copyCharges;
  final int parShots;
  final String bonusGoal;

  GameState createState(int index, {bool productRules = false}) {
    return GameState(
      levelIndex: index,
      levelName: name,
      ballSpawn: ballSpawn,
      copyCharges: productRules ? 0 : copyCharges,
      copyChargeLimit: productRules ? 0 : copyCharges,
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
