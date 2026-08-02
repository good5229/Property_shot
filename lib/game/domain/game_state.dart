import 'entity_state.dart';
import 'geometry.dart';
import 'trait.dart';

enum GamePhase { planning, resolving, success, paused }

class GameState {
  const GameState({
    required this.levelIndex,
    required this.levelName,
    required this.entities,
    required this.ballSpawn,
    this.phase = GamePhase.planning,
    this.shotCount = 0,
    this.score = 1000,
    this.selectedSourceId,
    this.selectedTrait,
    this.equippedTrait,
    this.aimDirection = const Vec2(1, 0),
    this.aimPower = 0.5,
    this.copyCharges = 1,
    this.copyChargeLimit = 1,
    this.message = '속성을 선택하고 조준하세요.',
    this.history = const [],
  });

  final int levelIndex;
  final String levelName;
  final List<EntityState> entities;
  final Vec2 ballSpawn;
  final GamePhase phase;
  final int shotCount;
  final int score;
  final String? selectedSourceId;
  final TraitType? selectedTrait;
  final TraitType? equippedTrait;
  final Vec2 aimDirection;
  final double aimPower;
  final int copyCharges;
  final int copyChargeLimit;
  final String message;
  final List<GameState> history;

  EntityState get activeBall =>
      entities.firstWhere((entity) => entity.id == 'active_ball');

  Iterable<EntityState> get traitSources {
    return entities.where(
      (entity) => entity.traits.isNotEmpty && entity.id != 'active_ball',
    );
  }

  EntityState? entityById(String id) {
    for (final entity in entities) {
      if (entity.id == id) {
        return entity;
      }
    }
    return null;
  }

  GameState copyWith({
    List<EntityState>? entities,
    GamePhase? phase,
    int? shotCount,
    int? score,
    String? selectedSourceId,
    TraitType? selectedTrait,
    bool clearSelection = false,
    TraitType? equippedTrait,
    bool clearEquippedTrait = false,
    Vec2? aimDirection,
    double? aimPower,
    int? copyCharges,
    int? copyChargeLimit,
    String? message,
    List<GameState>? history,
  }) {
    return GameState(
      levelIndex: levelIndex,
      levelName: levelName,
      entities: entities ?? this.entities,
      ballSpawn: ballSpawn,
      phase: phase ?? this.phase,
      shotCount: shotCount ?? this.shotCount,
      score: score ?? this.score,
      selectedSourceId: clearSelection
          ? null
          : selectedSourceId ?? this.selectedSourceId,
      selectedTrait: clearSelection
          ? null
          : selectedTrait ?? this.selectedTrait,
      equippedTrait: clearEquippedTrait
          ? null
          : equippedTrait ?? this.equippedTrait,
      aimDirection: aimDirection ?? this.aimDirection,
      aimPower: aimPower ?? this.aimPower,
      copyCharges: copyCharges ?? this.copyCharges,
      copyChargeLimit: copyChargeLimit ?? this.copyChargeLimit,
      message: message ?? this.message,
      history: history ?? this.history,
    );
  }
}
