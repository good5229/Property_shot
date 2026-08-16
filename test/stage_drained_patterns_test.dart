import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

import 'fixtures/stage_drained_patterns.dart';

void main() {
  const shots = ShotResolver();
  const traits = TraitResolver();
  late StageDefinition stage;

  setUpAll(() {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_drained');
  });

  test('5단계는 네 패턴과 기준 패턴 하나, 복제 횟수 0을 가진다', () {
    expect(stage.title, '5. 비워진 속성');
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_drained_01',
      'stage_drained_02',
      'stage_drained_03',
      'stage_drained_04',
    ]);
    expect(
      stage.patterns.where((pattern) => pattern.metadata['baseline'] == 'true'),
      hasLength(1),
    );
    expect(stage.patterns.every((pattern) => pattern.copyCharges == 0), isTrue);
    expect(
      stage.patterns.every((pattern) => pattern.copyCoreReward == 0),
      isTrue,
    );
    expect(
      stage.patterns.every(
        (pattern) => pattern.acceptedStrategyIds.contains('none'),
      ),
      isTrue,
    );
  });

  test('속성 이전은 공과 원본의 양쪽 변화를 한 상태에 보존한다', () {
    for (final pattern in stage.patterns) {
      final base = _state(pattern);
      for (final source in base.traitSources.toList()) {
        final originalSolid = source.solid;
        final trait = source.traits.single;
        final transferred = traits.transferSelectedTrait(
          traits.selectSource(base, source.id),
        );
        final drained = transferred.entityById(source.id)!;

        expect(drained.traits, isEmpty, reason: source.id);
        expect(drained.solid, originalSolid, reason: source.id);
        expect(source.movableWhenDrained, isTrue, reason: source.id);
        expect(drained.movable, isTrue, reason: source.id);
        expect(drained.visualState, 'drained', reason: source.id);
        expect(transferred.activeBall.traits, {trait}, reason: source.id);
        expect(transferred.message, contains('공은 ${trait.label} 능력을 얻고'));
        expect(transferred.message, contains('원본은 그 능력을 잃었'));
      }
    }
  });

  test('비워진 돌 질량은 무거움 보유 전보다 정량적으로 낮고 더 멀리 밀린다', () {
    final pattern = stage.patternById('stage_drained_01');
    // 질량 전달만 격리해서 비교한다. 실제 플레이의 직선 차단벽은 아래
    // 대표·대체 해법 및 전 패턴 직선 통로 회귀 테스트에서 별도로 검증한다.
    final initial = _state(pattern);
    final base = _replaceEntity(
      initial,
      initial.entityById('drained_01_direct_guard')!.copyWith(active: false),
    );
    final original = base.entityById('drain_weight')!;
    final heavyMovable = original.copyWith(movable: true);
    final drained = original.copyWith(
      traits: const {},
      movable: true,
      visualState: 'drained',
    );

    expect(ShotResolver.massOf(heavyMovable), 4.4);
    expect(ShotResolver.massOf(drained), 1.6);
    expect(
      ShotResolver.massOf(heavyMovable) / ShotResolver.massOf(drained),
      greaterThanOrEqualTo(2.7),
    );

    final direction = original.position - base.activeBall.position;
    final heavyResult = shots.resolve(
      _replaceEntity(base, heavyMovable),
      ShotInput(direction: direction, power: 1),
    );
    final drainedResult = shots.resolve(
      _replaceEntity(base, drained),
      ShotInput(direction: direction, power: 1),
    );
    final heavyDistance = heavyMovable.position.distanceTo(
      heavyResult.state.entityById(original.id)!.position,
    );
    final drainedDistance = drained.position.distanceTo(
      drainedResult.state.entityById(original.id)!.position,
    );
    expect(drainedDistance, greaterThan(heavyDistance));
    expect(heavyDistance, inInclusiveRange(20, 23));
    expect(drainedDistance, inInclusiveRange(42, 46));
    expect(drainedDistance / heavyDistance, greaterThanOrEqualTo(2));
  });

  for (final solution in stageDrainedRepresentativeSolutions) {
    test('${solution.patternId} 대표 해법은 비워진 원본 이동 뒤 성공한다', () {
      final result = _resolve(stage, solution);
      expect(result.state.phase, GamePhase.success);
      expect(
        result.events,
        anyOf(contains('hole_entered'), contains('existing_ball_hole_entered')),
      );
      expect(
        result.moves.any(
          (move) =>
              move.entityId == solution.strategyId && move.from != move.to,
        ),
        isTrue,
      );
      final impactIndex = result.events.indexWhere(
        (event) =>
            event == 'momentum_transfer' || event == 'chain_collision_ball',
      );
      final holeIndex = result.events.indexWhere(
        (event) => event.contains('hole_entered'),
      );
      expect(impactIndex, greaterThanOrEqualTo(0));
      expect(holeIndex, greaterThan(impactIndex));
    });
  }

  for (final solution in stageDrainedAlternativeSolutions) {
    test('${solution.patternId} ${solution.familyId} 대체 해법도 성공한다', () {
      final result = _resolve(stage, solution);
      expect(result.state.phase, GamePhase.success);
      if (solution.sourceMustMove) {
        expect(
          result.moves.any(
            (move) =>
                move.entityId == solution.strategyId && move.from != move.to,
          ),
          isTrue,
        );
      }
    });
  }

  test(
    '대표 해법은 2도·2% 격자에서 연결된 근방 성공 영역을 가진다',
    () {
      final minimumRegions = <String, int>{
        'stage_drained_01': 20,
        'stage_drained_02': 24,
        'stage_drained_03': 600,
        'stage_drained_04': 20,
      };
      for (final solution in stageDrainedRepresentativeSolutions) {
        final pattern = stage.patternById(solution.patternId);
        final prepared = _prepare(_state(pattern), solution.strategyId);
        final successes = <(int, int)>{};
        for (var degree = 0; degree < 360; degree += 2) {
          final radians = degree * math.pi / 180;
          for (var powerStep = 10; powerStep <= 50; powerStep++) {
            final result = shots.resolve(
              prepared,
              ShotInput(
                direction: Vec2(math.cos(radians), math.sin(radians)),
                power: powerStep / 50,
                equippedTrait: prepared.equippedTrait,
              ),
            );
            if (result.state.phase == GamePhase.success &&
                result.moves.any(
                  (move) =>
                      move.entityId == solution.strategyId &&
                      move.from != move.to,
                )) {
              successes.add((degree ~/ 2, powerStep));
            }
          }
        }
        expect(
          _largestComponent(successes),
          greaterThanOrEqualTo(minimumRegions[solution.patternId]!),
          reason: solution.patternId,
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('복제 코어 경로는 원본을 유지하지만 기본 클리어에 필요하지 않다', () {
    final pattern = stage.patternById('stage_drained_02');
    final base = pattern
        .toLevelDefinition(stageId: 'stage_drained', stageTitle: stage.title)
        .createState(4, productRules: true, copyCoreCount: 1);
    final copied = traits.copySelectedTrait(
      traits.selectSource(base, 'drain_jelly'),
    );
    final result = shots.resolve(
      copied,
      ShotInput(
        direction: _direction(120),
        power: 0.90,
        equippedTrait: copied.equippedTrait,
      ),
    );
    expect(copied.entityById('drain_jelly')!.traits, {TraitType.bouncy});
    expect(copied.copyCoreCount, 0);
    expect(result.state.phase, GamePhase.success);
    expect(stage.patterns.every((item) => item.copyCharges == 0), isTrue);
  });

  test('되감기는 발사 전 비워진 상태를, 초기화는 원본 속성을 복원한다', () {
    final pattern = stage.patternById('stage_drained_01');
    final base = _state(pattern);
    final transferred = _prepare(base, 'drain_weight');
    final result = shots.resolve(
      transferred,
      ShotInput(
        direction: _direction(222),
        power: 0.98,
        equippedTrait: transferred.equippedTrait,
      ),
    );
    final rewound = shots.rewind(result.state);
    final reset = _state(pattern);

    expect(rewound.entityById('drain_weight')!.traits, isEmpty);
    expect(rewound.entityById('drain_weight')!.visualState, 'drained');
    expect(rewound.equippedTrait, TraitType.heavy);
    expect(reset.entityById('drain_weight')!.traits, {TraitType.heavy});
    expect(reset.entityById('drain_weight')!.movable, isFalse);
  });
}

GameState _state(StagePattern pattern) => pattern
    .toLevelDefinition(stageId: 'stage_drained', stageTitle: '5. 비워진 속성')
    .createState(4, productRules: true);

GameState _prepare(GameState state, String strategyId) {
  if (strategyId == 'none') return state;
  const traits = TraitResolver();
  return traits.transferSelectedTrait(traits.selectSource(state, strategyId));
}

ShotResult _resolve(StageDefinition stage, StageDrainedSolution solution) {
  const shots = ShotResolver();
  final pattern = stage.patternById(solution.patternId);
  final prepared = _prepare(_state(pattern), solution.strategyId);
  return shots.resolve(
    prepared,
    ShotInput(
      direction: solution.direction,
      power: solution.power,
      equippedTrait: prepared.equippedTrait,
    ),
  );
}

GameState _replaceEntity(GameState state, EntityState replacement) {
  return state.copyWith(
    entities: [
      for (final entity in state.entities)
        if (entity.id == replacement.id) replacement else entity,
    ],
  );
}

Vec2 _direction(int degree) {
  final radians = degree * math.pi / 180;
  return Vec2(math.cos(radians), math.sin(radians));
}

int _largestComponent(Set<(int, int)> cells) {
  final remaining = Set<(int, int)>.of(cells);
  var largest = 0;
  while (remaining.isNotEmpty) {
    final queue = <(int, int)>[remaining.first];
    remaining.remove(queue.first);
    var count = 0;
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      count++;
      for (final neighbor in [
        ((cell.$1 + 179) % 180, cell.$2),
        ((cell.$1 + 1) % 180, cell.$2),
        (cell.$1, cell.$2 - 1),
        (cell.$1, cell.$2 + 1),
      ]) {
        if (remaining.remove(neighbor)) queue.add(neighbor);
      }
    }
    largest = math.max(largest, count);
  }
  return largest;
}
