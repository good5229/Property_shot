import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  test('생산 40패턴은 공에서 홀까지 열린 직선 통로를 두지 않는다', () {
    final openCorridors = <String>[];
    final runtimeDirectClears = <String>[];
    const resolver = ShotResolver();

    for (
      var stageIndex = 0;
      stageIndex < generatedStageCatalog.stages.length;
      stageIndex++
    ) {
      final stage = generatedStageCatalog.stages[stageIndex];
      for (final pattern in stage.patterns) {
        final hole = pattern.objects
            .singleWhere((object) => object.type == EntityType.hole)
            .toEntityState();
        if (!_hasSolidCorridorBlocker(
          pattern.ballSpawn,
          hole.position,
          pattern,
        )) {
          openCorridors.add('${stage.stageId}/${pattern.patternId}');
        }

        final initial = pattern
            .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
            .createState(stageIndex);
        final centerDirection = (hole.position - pattern.ballSpawn)
            .normalized();
        final centerAngle = math.atan2(centerDirection.y, centerDirection.x);
        for (var angleOffset = -6; angleOffset <= 6; angleOffset++) {
          final angle = centerAngle + angleOffset * math.pi / 180;
          final direction = Vec2(math.cos(angle), math.sin(angle));
          for (var powerPercent = 12; powerPercent <= 100; powerPercent += 2) {
            final result = resolver.resolve(
              initial,
              ShotInput(direction: direction, power: powerPercent / 100),
            );
            if (result.state.phase != GamePhase.success) continue;
            final purposefulImpact = result.impacts.any(
              (impact) => impact.entityType != EntityType.hole,
            );
            final purposefulEvent = result.events.any(
              (event) =>
                  event == 'switch_pressed' ||
                  event == 'power_slider_activated' ||
                  event == 'reflector_rotated' ||
                  event == 'balloon_popped' ||
                  event == 'sticky_attached' ||
                  event == 'spent_ball_bounced',
            );
            if (!purposefulImpact && !purposefulEvent) {
              runtimeDirectClears.add(
                '${stage.stageId}/${pattern.patternId}'
                '@${angleOffset >= 0 ? '+' : ''}$angleOffset°/$powerPercent%',
              );
              break;
            }
          }
          if (runtimeDirectClears.any(
            (entry) =>
                entry.startsWith('${stage.stageId}/${pattern.patternId}@'),
          )) {
            break;
          }
        }
      }
    }

    expect(
      openCorridors,
      isEmpty,
      reason: '공 반경을 포함한 중심선에 고체 장애물이 없습니다: $openCorridors',
    );
    expect(
      runtimeDirectClears,
      isEmpty,
      reason: '기믹 충돌 없는 홀 중심 직행 성공이 있습니다: $runtimeDirectClears',
    );
  });
}

bool _hasSolidCorridorBlocker(Vec2 from, Vec2 to, StagePattern pattern) {
  final distance = from.distanceTo(to);
  final samples = (distance / 2).ceil();
  const activeBallHitRadius = 12 * 0.88;
  for (var sample = 1; sample < samples; sample++) {
    final t = sample / samples;
    final point = Vec2(
      from.x + (to.x - from.x) * t,
      from.y + (to.y - from.y) * t,
    );
    for (final object in pattern.objects) {
      if (object.type == EntityType.hole) continue;
      final entity = object.toEntityState();
      if (!entity.active || !entity.solid) continue;
      if (entity.type == EntityType.gate && entity.open) continue;
      if (entity.hitBounds.intersectsCircle(point, activeBallHitRadius)) {
        return true;
      }
    }
  }
  return false;
}
