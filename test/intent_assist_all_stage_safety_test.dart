import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/input/intent_assist_resolver.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  test('생산 40패턴의 의도 보정은 물리 첫 접촉과 설정 상한을 우회하지 않는다', () {
    const physics = ShotResolver();
    const assist = IntentAssistResolver();
    var patternCount = 0;
    var probeCount = 0;

    for (
      var stageIndex = 0;
      stageIndex < generatedStageCatalog.stages.length;
      stageIndex++
    ) {
      final stage = generatedStageCatalog.stages[stageIndex];
      for (final pattern in stage.patterns) {
        patternCount++;
        final state = pattern
            .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
            .createState(stageIndex);
        final hole = state.entities.singleWhere(
          (entity) => entity.type == EntityType.hole,
        );
        final holeAngle = math.atan2(
          hole.position.y - state.activeBall.position.y,
          hole.position.x - state.activeBall.position.x,
        );
        final angles = <double>[
          for (var octant = 0; octant < 8; octant++)
            octant * math.pi / 4,
          holeAngle - 3.25 * math.pi / 180,
          holeAngle + 3.25 * math.pi / 180,
        ];

        for (final angle in angles) {
          for (final power in const [0.4, 0.72]) {
            probeCount++;
            final raw = ShotInput(
              direction: Vec2(math.cos(angle), math.sin(angle)),
              power: power,
            );
            final first = assist.resolve(state: state, rawInput: raw);
            final repeated = assist.resolve(state: state, rawInput: raw);
            final applied = first.appliedInput;

            expect(
              first.angleDeltaDegrees.abs(),
              lessThanOrEqualTo(3.0001),
              reason: '${stage.stageId}/${pattern.patternId}',
            );
            expect(
              first.powerDelta.abs(),
              lessThanOrEqualTo(0.0201),
              reason: '${stage.stageId}/${pattern.patternId}',
            );
            expect(applied.holeForgivenessRadius, 6);
            expect(repeated.appliedInput.direction, applied.direction);
            expect(repeated.appliedInput.power, applied.power);
            expect(repeated.targetEntityId, first.targetEntityId);

            final rawArrival = physics.firstArrival(state, raw);
            final appliedArrival = physics.firstArrival(state, applied);
            if (_isRealEntity(state.entities, rawArrival.entityId)) {
              expect(
                first.targetSnapped,
                isFalse,
                reason:
                    '${stage.stageId}/${pattern.patternId}: '
                    '이미 ${rawArrival.entityId}를 향한 입력을 재탐색했습니다.',
              );
              expect(appliedArrival.entityId, rawArrival.entityId);
            }
            if (first.targetSnapped) {
              expect(first.targetEntityId, isNotNull);
              expect(
                appliedArrival.entityId,
                first.targetEntityId,
                reason:
                    '${stage.stageId}/${pattern.patternId}: '
                    '표시한 보정 대상과 실제 첫 충돌이 다릅니다.',
              );
              expect(
                _isRealEntity(state.entities, first.targetEntityId),
                isTrue,
              );
            }
          }
        }
      }
    }

    expect(patternCount, 40);
    expect(probeCount, 800);
  });
}

bool _isRealEntity(Iterable<EntityState> entities, String? id) =>
    id != null && entities.any((entity) => entity.id == id);
