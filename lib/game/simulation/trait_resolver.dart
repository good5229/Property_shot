import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/trait.dart';

class TraitResolver {
  const TraitResolver();

  GameState selectSource(GameState state, String sourceId) {
    final source = state.entityById(sourceId);
    if (source == null || source.traits.isEmpty) {
      return state.copyWith(message: '선택 가능한 속성이 없습니다.');
    }
    final trait = source.traits.first;
    return state.copyWith(
      selectedSourceId: sourceId,
      selectedTrait: trait,
      message: '${trait.label} 속성을 선택했습니다.',
    );
  }

  GameState transferSelectedTrait(GameState state) {
    final sourceId = state.selectedSourceId;
    final trait = state.selectedTrait;
    if (sourceId == null || trait == null) {
      return state.copyWith(message: '먼저 속성 물체를 선택하세요.');
    }

    final entities = <EntityState>[];
    for (final entity in state.entities) {
      if (entity.id == sourceId) {
        final nextTraits = Set.of(entity.traits)..remove(trait);
        entities.add(
          entity.copyWith(
            traits: nextTraits,
            visualState: 'drained',
            movable: entity.movable || trait == state.selectedTrait,
          ),
        );
      } else if (entity.id == state.activeBall.id) {
        entities.add(entity.copyWith(traits: {trait}, visualState: 'equipped'));
      } else {
        entities.add(entity);
      }
    }

    return state.copyWith(
      entities: entities,
      equippedTrait: trait,
      clearSelection: true,
      message: '${trait.label} 속성을 공으로 옮겼습니다.',
    );
  }

  GameState copySelectedTrait(GameState state) {
    final trait = state.selectedTrait;
    if (trait == null) {
      return state.copyWith(message: '먼저 속성 물체를 선택하세요.');
    }

    final entities = <EntityState>[];
    for (final entity in state.entities) {
      if (entity.id == state.activeBall.id) {
        entities.add(entity.copyWith(traits: {trait}, visualState: 'copied'));
      } else {
        entities.add(entity);
      }
    }

    return state.copyWith(
      entities: entities,
      equippedTrait: trait,
      clearSelection: true,
      message: '${trait.label} 속성을 복사했습니다.',
    );
  }
}
