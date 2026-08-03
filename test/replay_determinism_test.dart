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

  test('네 단계의 다방향 고속 입력은 연쇄 안전 중단과 비유한 좌표 없이 끝난다', () {
    final directions = [
      for (var index = 0; index < 16; index++)
        Vec2(math.cos(index * math.pi / 8), math.sin(index * math.pi / 8)),
    ];
    const powers = [0.65, 0.85, 1.0];

    for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
      final state = levels[levelIndex].createState(
        levelIndex,
        productRules: true,
        copyCoreCount: 1,
      );
      for (final entity in state.entities.where(
        (entity) => entity.movable && entity.type != EntityType.hole,
      )) {
        expect(entity.hitBounds.left, greaterThanOrEqualTo(-0.01));
        expect(entity.hitBounds.top, greaterThanOrEqualTo(-0.01));
        expect(entity.hitBounds.right, lessThanOrEqualTo(logicalSize.x + 0.01));
        expect(
          entity.hitBounds.bottom,
          lessThanOrEqualTo(logicalSize.y + 0.01),
          reason: '단계 ${levelIndex + 1}, 초기 엔티티 ${entity.id}',
        );
      }
      for (final direction in directions) {
        for (final power in powers) {
          final result = resolver.resolve(
            state,
            ShotInput(direction: direction, power: power),
          );

          expect(
            result.chainSafetyDiagnostics,
            isEmpty,
            reason: '단계 ${levelIndex + 1}, 방향 $direction, 힘 $power',
          );
          expect(
            result.events,
            isNot(contains('chain_safety_stop')),
            reason: '단계 ${levelIndex + 1}, 방향 $direction, 힘 $power',
          );
          expect(
            result.path.every((point) => point.x.isFinite && point.y.isFinite),
            isTrue,
          );
          expect(
            result.physicsEvents.every(
              (event) =>
                  event.position.x.isFinite &&
                  event.position.y.isFinite &&
                  event.normal.x.isFinite &&
                  event.normal.y.isFinite &&
                  event.resultingVelocity.x.isFinite &&
                  event.resultingVelocity.y.isFinite,
            ),
            isTrue,
          );
          expect(
            result.state.entities.every(
              (entity) =>
                  entity.position.x.isFinite && entity.position.y.isFinite,
            ),
            isTrue,
          );
          for (final entity in result.state.entities.where(
            (entity) => entity.movable && entity.type != EntityType.hole,
          )) {
            final boundaryReason =
                '단계 ${levelIndex + 1}, 엔티티 ${entity.id}, 방향 $direction, 힘 $power';
            expect(
              entity.hitBounds.left,
              greaterThanOrEqualTo(-0.01),
              reason: boundaryReason,
            );
            expect(
              entity.hitBounds.top,
              greaterThanOrEqualTo(-0.01),
              reason: boundaryReason,
            );
            expect(
              entity.hitBounds.right,
              lessThanOrEqualTo(logicalSize.x + 0.01),
              reason: boundaryReason,
            );
            expect(
              entity.hitBounds.bottom,
              lessThanOrEqualTo(logicalSize.y + 0.01),
              reason: boundaryReason,
            );
          }
        }
      }
    }
  });
}
