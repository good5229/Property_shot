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
    this.copyCoreReward = 0,
  });

  final String name;
  final Vec2 ballSpawn;
  final List<EntityState> entities;
  final int copyCharges;
  final int parShots;
  final String bonusGoal;
  final int copyCoreReward;

  GameState createState(
    int index, {
    bool productRules = false,
    int copyCoreCount = 0,
    bool copyCoreRewarded = false,
  }) {
    final startingCoreCount = productRules ? copyCoreCount : 0;
    return GameState(
      levelIndex: index,
      levelName: name,
      ballSpawn: ballSpawn,
      copyCharges: productRules ? startingCoreCount : copyCharges,
      copyChargeLimit: productRules ? startingCoreCount : copyCharges,
      copyCoreCount: startingCoreCount,
      copyCoreRewarded: productRules && copyCoreRewarded,
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
