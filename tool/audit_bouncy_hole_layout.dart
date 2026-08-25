// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final pattern = catalog
      .stageById('stage_bouncy')
      .patternById('stage_bouncy_01');
  final candidates =
      <
        ({
          int x,
          int y,
          int none,
          int jelly,
          int coarseNone,
          int coarseJelly,
          int angle,
          double power,
          int component,
        })
      >[];
  for (var y = 240; y <= 300; y += 10) {
    for (var x = 190; x <= 250; x += 10) {
      final plain = _moveEntity(
        _state(pattern, false),
        'blocker',
        Vec2(x + .0, y + .0),
      );
      final elastic = _moveEntity(
        _state(pattern, true),
        'blocker',
        Vec2(x + .0, y + .0),
      );
      var none = 0;
      var jelly = 0;
      for (var degree = 0; degree < 360; degree += 4) {
        for (var step = 1; step <= 10; step++) {
          final direction = Vec2(
            math.cos(degree * math.pi / 180),
            math.sin(degree * math.pi / 180),
          );
          if (const ShotResolver()
                  .resolve(
                    plain,
                    ShotInput(direction: direction, power: step / 10),
                  )
                  .state
                  .phase ==
              GamePhase.success) {
            none++;
          }
          if (const ShotResolver()
                  .resolve(
                    elastic,
                    ShotInput(
                      direction: direction,
                      power: step / 10,
                      equippedTrait: TraitType.bouncy,
                    ),
                  )
                  .state
                  .phase ==
              GamePhase.success) {
            jelly++;
          }
        }
      }
      final fineSuccesses = <({int degree, int step})>{};
      for (var degree = 0; degree < 360; degree += 2) {
        final direction = Vec2(
          math.cos(degree * math.pi / 180),
          math.sin(degree * math.pi / 180),
        );
        for (var step = 6; step <= 50; step++) {
          final result = const ShotResolver().resolve(
            elastic,
            ShotInput(
              direction: direction,
              power: step / 50,
              equippedTrait: TraitType.bouncy,
            ),
          );
          if (result.state.phase == GamePhase.success) {
            fineSuccesses.add((degree: degree ~/ 2, step: step));
          }
        }
      }
      var coarseNone = 0;
      var coarseJelly = 0;
      for (var degree = 0; degree < 360; degree += 10) {
        final direction = Vec2(
          math.cos(degree * math.pi / 180),
          math.sin(degree * math.pi / 180),
        );
        for (final power in const [0.55, 0.7, 0.85, 1.0]) {
          if (const ShotResolver()
                  .resolve(plain, ShotInput(direction: direction, power: power))
                  .state
                  .phase ==
              GamePhase.success) {
            coarseNone++;
          }
          if (const ShotResolver()
                  .resolve(
                    elastic,
                    ShotInput(
                      direction: direction,
                      power: power,
                      equippedTrait: TraitType.bouncy,
                    ),
                  )
                  .state
                  .phase ==
              GamePhase.success) {
            coarseJelly++;
          }
        }
      }
      candidates.add((
        x: x,
        y: y,
        none: none,
        jelly: jelly,
        coarseNone: coarseNone,
        coarseJelly: coarseJelly,
        angle:
            _largestCircularRun(
              fineSuccesses.map((input) => input.degree).toSet(),
              180,
            ) *
            2,
        power:
            _largestLinearRun(
              fineSuccesses.map((input) => input.step).toSet(),
            ) *
            0.02,
        component: _largestGridComponent(fineSuccesses),
      ));
    }
  }
  candidates.sort((left, right) {
    final leftRatio = left.jelly / math.max(1, left.none);
    final rightRatio = right.jelly / math.max(1, right.none);
    final leftPass =
        left.coarseJelly > left.coarseNone &&
        left.coarseNone <= 4 &&
        left.angle >= 8 &&
        left.power >= 0.20;
    final rightPass =
        right.coarseJelly > right.coarseNone &&
        right.coarseNone <= 4 &&
        right.angle >= 8 &&
        right.power >= 0.20;
    if (leftPass != rightPass) return rightPass ? 1 : -1;
    final angle = right.angle.compareTo(left.angle);
    if (angle != 0) return angle;
    final component = right.component.compareTo(left.component);
    return component != 0 ? component : rightRatio.compareTo(leftRatio);
  });
  for (final candidate in candidates.take(12)) {
    print(candidate);
  }
}

int _largestCircularRun(Set<int> values, int period) {
  var longest = 0;
  var current = 0;
  for (var index = 0; index < period * 2; index++) {
    if (values.contains(index % period)) {
      current++;
      longest = math.max(longest, current);
    } else {
      current = 0;
    }
  }
  return math.min(longest, period);
}

int _largestLinearRun(Set<int> values) {
  if (values.isEmpty) return 0;
  final sorted = values.toList()..sort();
  var longest = 1;
  var current = 1;
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index] == sorted[index - 1] + 1) {
      current++;
      longest = math.max(longest, current);
    } else {
      current = 1;
    }
  }
  return math.max(0, longest - 1);
}

int _largestGridComponent(Set<({int degree, int step})> values) {
  var largest = 0;
  final remaining = values.toSet();
  while (remaining.isNotEmpty) {
    final queue = <({int degree, int step})>[remaining.first];
    remaining.remove(queue.first);
    var count = 0;
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      count++;
      for (final neighbor in <({int degree, int step})>[
        (degree: (current.degree + 179) % 180, step: current.step),
        (degree: (current.degree + 1) % 180, step: current.step),
        (degree: current.degree, step: current.step - 1),
        (degree: current.degree, step: current.step + 1),
      ]) {
        if (remaining.remove(neighbor)) queue.add(neighbor);
      }
    }
    largest = math.max(largest, count);
  }
  return largest;
}

GameState _state(StagePattern pattern, bool jelly) {
  var state = pattern
      .toLevelDefinition(stageId: 'stage_bouncy', stageTitle: '2. 탄성 익히기')
      .createState(1);
  if (jelly) {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(traits.selectSource(state, 'jelly'));
  }
  return state;
}

GameState _moveEntity(GameState state, String id, Vec2 position) =>
    state.copyWith(
      entities: [
        for (final entity in state.entities)
          if (entity.id == id) entity.copyWith(position: position) else entity,
      ],
    );
