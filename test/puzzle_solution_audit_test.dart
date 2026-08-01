import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  const shots = ShotResolver();

  test('1단계는 무거움 풀이가 있고 무속성 격자 우회가 없다', () {
    final heavy = _transfer(levels[0].createState(0), 'anvil');
    final heavySuccesses = _successfulResults(shots, heavy);
    final normalSuccesses = _successfulResults(shots, levels[0].createState(0));

    expect(heavySuccesses, isNotEmpty);
    expect(normalSuccesses, isEmpty);
    expect(
      heavySuccesses.every(
        (result) =>
            result.events.contains('crate_pushed') &&
            result.events.contains('hole_entered'),
      ),
      isTrue,
    );
  });

  test('2단계는 탄성 풀이가 있고 무속성 격자 우회가 없다', () {
    final bouncy = _transfer(levels[1].createState(1), 'jelly');
    final bouncySuccesses = _successfulResults(shots, bouncy);
    final normalSuccesses = _successfulResults(shots, levels[1].createState(1));

    expect(bouncySuccesses, isNotEmpty);
    expect(normalSuccesses, isEmpty);
    expect(
      bouncySuccesses.every(
        (result) =>
            result.events.contains('bounced') &&
            result.events.contains('hole_entered'),
      ),
      isTrue,
    );
  });

  test('3단계는 점착 발판을 먼저 만든 뒤 무거움을 허용한다', () {
    final initial = levels[2].createState(2);
    final sticky = _transfer(initial, 'glue');
    final attached = shots.resolve(
      sticky,
      const ShotInput(direction: Vec2(1, -0.54), power: 1),
    );

    expect(attached.events, contains('sticky_attached'));
    expect(
      attached.state.entities.any(
        (entity) => entity.visualState == 'stuck' && !entity.movable,
      ),
      isTrue,
    );
    expect(attached.state.requiresStickyAnchor, isTrue);
    expect(attached.state.shotCount, 1);
  });
}

GameState _transfer(GameState state, String sourceId) {
  const traits = TraitResolver();
  return traits.transferSelectedTrait(traits.selectSource(state, sourceId));
}

List<ShotResult> _successfulResults(ShotResolver shots, GameState state) {
  final successes = <ShotResult>[];
  for (var degree = 0; degree < 360; degree += 10) {
    final radians = degree * math.pi / 180;
    for (final power in [0.55, 0.7, 0.85, 1.0]) {
      final direction = Vec2(math.cos(radians), math.sin(radians));
      final result = shots.resolve(
        state,
        ShotInput(
          direction: direction,
          power: power,
          equippedTrait: state.equippedTrait,
        ),
      );
      if (result.state.phase == GamePhase.success) {
        successes.add(result);
      }
    }
  }
  return successes;
}
