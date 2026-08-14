import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';

void main() {
  test('40개 모든 패턴은 발사 전 공이 spawn에 있고 홀 밖의 planning 0발 상태다', () {
    var checkedPatterns = 0;

    for (
      var stageIndex = 0;
      stageIndex < generatedStageCatalog.stages.length;
      stageIndex++
    ) {
      final stage = generatedStageCatalog.stages[stageIndex];
      for (final pattern in stage.patterns) {
        final level = pattern.toLevelDefinition(
          stageId: stage.stageId,
          stageTitle: stage.title,
        );
        final state = level.createState(stageIndex, productRules: true);
        final ball = state.activeBall;
        final holes = state.entities.where(
          (entity) => entity.type == EntityType.hole,
        );

        expect(
          state.phase,
          GamePhase.planning,
          reason: '${pattern.patternId}: 초기 phase',
        );
        expect(
          state.shotCount,
          0,
          reason: '${pattern.patternId}: 초기 shotCount',
        );
        expect(
          state.history,
          isEmpty,
          reason: '${pattern.patternId}: 초기 history',
        );
        expect(
          ball.position,
          state.ballSpawn,
          reason: '${pattern.patternId}: 공은 spawn에서 시작해야 함',
        );
        expect(
          ball.visualState,
          isNot(anyOf('captured', 'hole_captured')),
          reason: '${pattern.patternId}: 초기 공은 포획 상태가 아니어야 함',
        );
        expect(holes, isNotEmpty, reason: '${pattern.patternId}: 홀 필요');
        for (final hole in holes) {
          expect(
            ball.position.distanceTo(hole.position),
            greaterThan(ball.hitRadius + hole.hitRadius),
            reason: '${pattern.patternId}: 초기 공과 홀 hitbox가 겹치면 안 됨',
          );
        }
        checkedPatterns++;
      }
    }

    expect(checkedPatterns, 40);
  });
}
