import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();
  final inputs = [
    for (var index = 0; index < 8; index++)
      ShotInput(
        direction: Vec2(
          math.cos(index * math.pi / 4),
          math.sin(index * math.pi / 4),
        ),
        power: 0.25 + index * 0.1,
      ),
  ];

  test('대표 단일샷을 100회 반복해도 결과 서명이 일치한다', () {
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final state = levels[levelIndex].createState(
        levelIndex,
        productRules: true,
        copyCoreCount: 1,
      );
      for (final input in inputs) {
        final expected = shotResultSignature(resolver.resolve(state, input));
        for (var repetition = 0; repetition < 100; repetition++) {
          expect(
            shotResultSignature(resolver.resolve(state, input)),
            expected,
            reason: '단계 ${levelIndex + 1}, 입력 ${input.power}',
          );
        }
      }
    }
  });

  test('속성별 대표 발사도 동일한 이벤트 서명을 재생한다', () {
    final traitInputs = [
      for (final trait in TraitType.values)
        ShotInput(
          direction: const Vec2(0.8, -0.6),
          power: 0.82,
          equippedTrait: trait,
        ),
    ];
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final state = levels[levelIndex].createState(levelIndex);
      for (final input in traitInputs) {
        final first = resolver.resolve(state, input);
        final second = resolver.resolve(state, input);
        expect(shotResultSignature(second), shotResultSignature(first));
      }
    }
  });

  test('샷 종료 후 모든 벽은 위치와 이동 가능 상태를 유지한다', () {
    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final state = levels[levelIndex].createState(levelIndex);
      final originalWalls = {
        for (final entity in state.entities.where(
          (entity) => entity.type == EntityType.wall,
        ))
          entity.id: entity,
      };
      final result = resolver.resolve(
        state,
        const ShotInput(direction: Vec2(1, -0.2), power: 1),
      );
      for (final entry in originalWalls.entries) {
        final wall = result.state.entityById(entry.key);
        expect(wall, isNotNull);
        expect(wall!.position, entry.value.position);
        expect(wall.movable, isFalse);
      }
    }
  });
}
