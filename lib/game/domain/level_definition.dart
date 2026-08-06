import 'entity_state.dart';
import 'game_state.dart';
import 'geometry.dart';

class LevelDefinition {
  const LevelDefinition({
    required this.id,
    required this.name,
    required this.ballSpawn,
    required this.entities,
    this.copyCharges = 0,
    this.parShots = 3,
    this.bonusGoal = '복사 없이 클리어',
    this.copyCoreReward = 0,
    this.intendedStrategyId,
    this.acceptedStrategyIds = const {},
    this.stageId,
    this.patternId,
    this.patternWeight = 1,
    this.difficultyBand,
    this.solutionFamilies = const {},
    this.optionalChallenges = const {},
    this.patternMetadata = const {},
  });

  /// 배열 순서가 바뀌어도 진행 기록을 유지하는 내부 식별자다.
  final String id;
  final String name;
  final Vec2 ballSpawn;
  final List<EntityState> entities;
  final int copyCharges;
  final int parShots;
  final String bonusGoal;
  final int copyCoreReward;
  final String? intendedStrategyId;
  final Set<String> acceptedStrategyIds;

  /// 패턴 데이터에서 변환된 경우에만 채워지는 선택 메타데이터다.
  /// 기존 하드코딩 레벨은 이 값들을 생략해도 이전과 같은 상태를 만든다.
  final String? stageId;
  final String? patternId;
  final double patternWeight;
  final String? difficultyBand;
  final Set<String> solutionFamilies;
  final Set<String> optionalChallenges;
  final Map<String, String> patternMetadata;

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
