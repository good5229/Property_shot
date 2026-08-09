import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/game/domain/trait.dart';

void main() {
  const shots = ShotResolver();

  test('1단계는 무거움 풀이와 다른 물리 풀이를 모두 허용한다', () {
    final heavy = _transfer(levels[0].createState(0), 'anvil');
    final heavySuccesses = _successfulResults(shots, heavy);
    final normalSuccesses = _successfulResults(shots, levels[0].createState(0));

    expect(heavySuccesses, isNotEmpty);
    expect(normalSuccesses, isNotEmpty);
    expect(
      heavySuccesses.any((result) => result.events.contains('crate_pushed')),
      isTrue,
    );
  });

  test('2단계 기준 격자는 탄성 풀이를 보장하고 거친 무속성 직행을 제한한다', () {
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

  test('3단계는 점착 고정 역할과 직접 스위치 풀이를 구분해 허용한다', () {
    final initial = levels[2].createState(2);
    final sticky = _transfer(initial, 'glue');
    final attached = shots.resolve(
      sticky,
      ShotInput(
        direction: const Vec2(-1, 0),
        power: 0.5,
        equippedTrait: sticky.equippedTrait,
      ),
    );

    expect(attached.events, contains('sticky_attached'));
    expect(
      attached.state.entities.any(
        (entity) => entity.visualState == 'stuck' && !entity.movable,
      ),
      isTrue,
    );
    expect(attached.state.shotCount, 1);

    final direct = _transfer(initial, 'anvil');
    final exactDirect = shots.resolve(
      direct,
      const ShotInput(
        direction: Vec2(1, -1.3),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    );
    expect(
      exactDirect.state.phase,
      GamePhase.success,
      reason: '점착 없이 무거운 공으로 스위치를 거쳐 홀에 도달하는 경로가 없음',
    );
    expect(exactDirect.events, contains('switch_pressed'));
    expect(exactDirect.events, contains('hole_entered'));
  });

  test('3단계는 기믹을 거치지 않는 물리 경로도 홀에 도달할 수 있다', () {
    final initial = levels[2].createState(2);
    ShotResult? bypass;
    for (var degree = 0; degree < 360 && bypass == null; degree += 2) {
      final radians = degree * math.pi / 180;
      for (var step = 20; step <= 50 && bypass == null; step++) {
        final result = shots.resolve(
          initial,
          ShotInput(
            direction: Vec2(math.cos(radians), math.sin(radians)),
            power: step / 50,
          ),
        );
        if (result.state.phase == GamePhase.success &&
            !result.events.contains('switch_pressed') &&
            !result.events.contains('sticky_attached')) {
          bypass = result;
        }
      }
    }
    expect(bypass, isNotNull, reason: '특정 기믹을 수행하지 않아도 물리 경로로 홀에 도달할 수 있어야 한다');
  });

  test('4단계는 풍선 팝·스위치·문 개방을 실제 충돌 순서로 연결한다', () {
    final state = _transfer(levels[3].createState(3), 'spike_source');
    ShotResult? solution;
    for (var degree = 0; degree < 360 && solution == null; degree += 2) {
      final radians = degree * math.pi / 180;
      for (var step = 15; step <= 50 && solution == null; step++) {
        final result = shots.resolve(
          state,
          ShotInput(
            direction: Vec2(math.cos(radians), math.sin(radians)),
            power: step / 50,
            equippedTrait: state.equippedTrait,
          ),
        );
        if (result.state.phase == GamePhase.success &&
            result.events.contains('balloon_popped') &&
            result.events.contains('balloon_switch_revealed') &&
            result.events.contains('balloon_switch_pressed')) {
          solution = result;
        }
      }
    }
    expect(solution, isNotNull, reason: '팝 후 실제 스위치 충돌로 문을 여는 성공 경로가 필요하다');
    final events = solution!.events;
    expect(
      events.indexOf('balloon_popped'),
      lessThan(events.indexOf('balloon_switch_revealed')),
    );
    expect(
      events.indexOf('balloon_switch_revealed'),
      lessThan(events.indexOf('balloon_switch_pressed')),
    );
    expect(solution.state.entityById('balloon_gate')!.open, isTrue);

    final physicsEvents = solution.physicsEvents;
    final balloonImpact = physicsEvents.indexWhere(
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetEntityId == 'balloon',
    );
    final balloonPopped = physicsEvents.indexWhere(
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetEntityId == 'balloon' &&
          event.visualState == 'popped',
    );
    final switchRevealed = physicsEvents.indexWhere(
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetEntityId == 'balloon_switch' &&
          event.visualState == 'revealed',
    );
    final switchImpact = physicsEvents.indexWhere(
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetEntityId == 'balloon_switch',
    );
    final gateOpened = physicsEvents.indexWhere(
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetEntityId == 'balloon_gate' &&
          event.visualState == 'open',
    );
    final holeImpact = physicsEvents.indexWhere(
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetType == EntityType.hole,
    );
    expect(balloonImpact, greaterThanOrEqualTo(0));
    expect(balloonPopped, greaterThan(balloonImpact));
    expect(switchRevealed, greaterThan(balloonPopped));
    expect(switchImpact, greaterThan(switchRevealed));
    expect(gateOpened, greaterThan(switchImpact));
    expect(holeImpact, greaterThan(gateOpened));
    expect(
      physicsEvents
          .where((event) => event.kind == PhysicsEventKind.stateChange)
          .map((event) => event.eventId)
          .toSet()
          .length,
      equals(
        physicsEvents
            .where((event) => event.kind == PhysicsEventKind.stateChange)
            .length,
      ),
    );
  });

  test('4단계는 뾰족함 없이도 우회 성공을 허용한다', () {
    ShotResult? bypass;
    final state = levels[3].createState(3);
    for (var degree = 0; degree < 360 && bypass == null; degree += 2) {
      final radians = degree * math.pi / 180;
      for (var step = 15; step <= 50 && bypass == null; step++) {
        final result = shots.resolve(
          state,
          ShotInput(
            direction: Vec2(math.cos(radians), math.sin(radians)),
            power: step / 50,
          ),
        );
        if (result.state.phase == GamePhase.success &&
            !result.events.contains('balloon_popped') &&
            !result.events.contains('balloon_switch_pressed')) {
          bypass = result;
        }
      }
    }
    expect(bypass, isNotNull, reason: '4단계는 특정 기믹을 수행하지 않는 성공 경로도 허용해야 한다');
  });

  test('첫 2단계 성공 영역은 연결된 입력 영역으로 측정된다', () {
    final widths = <String, _SuccessWidth>{};
    for (var index = 0; index < 2; index++) {
      final state = _transfer(
        levels[index].createState(index),
        index == 0 ? 'anvil' : 'jelly',
      );
      final successes = <({int degree, int step})>{};
      for (var degree = 0; degree < 360; degree += 2) {
        final radians = degree * math.pi / 180;
        for (var step = 6; step <= 50; step++) {
          final power = step / 50;
          final result = shots.resolve(
            state,
            ShotInput(
              direction: Vec2(math.cos(radians), math.sin(radians)),
              power: power,
              equippedTrait: state.equippedTrait,
            ),
          );
          if (result.state.phase == GamePhase.success) {
            successes.add((degree: degree ~/ 2, step: step));
          }
        }
      }
      expect(successes, isNotEmpty, reason: '${levels[index].name} 성공 입력 없음');
      final width = _SuccessWidth(
        angle:
            _largestCircularRun(
              successes.map((input) => input.degree).toSet(),
              180,
            ) *
            2,
        power:
            _largestLinearRun(successes.map((input) => input.step).toSet()) *
            0.02,
        component: _largestGridComponent(successes),
      );
      widths['${index + 1}단계'] = width;
    }
    expect(widths['1단계']!.angle, greaterThanOrEqualTo(24));
    expect(widths['1단계']!.power, greaterThanOrEqualTo(0.20));
    expect(widths['2단계']!.angle, greaterThanOrEqualTo(8));
    expect(widths['2단계']!.power, greaterThanOrEqualTo(0.20));
    expect(widths['1단계']!.component, greaterThanOrEqualTo(8));
    expect(widths['2단계']!.component, greaterThanOrEqualTo(8));
  });
}

class _SuccessWidth {
  const _SuccessWidth({
    required this.angle,
    required this.power,
    required this.component,
  });

  final int angle;
  final double power;
  final int component;
}

int _largestCircularRun(Set<int> values, int period) {
  if (values.isEmpty) {
    return 0;
  }
  var longest = 0;
  var current = 0;
  for (var index = 0; index < period * 2; index++) {
    if (values.contains(index % period)) {
      current += 1;
      longest = math.max(longest, current);
    } else {
      current = 0;
    }
  }
  return math.min(longest, period);
}

int _largestLinearRun(Set<int> values) {
  if (values.isEmpty) {
    return 0;
  }
  final sorted = values.toList()..sort();
  var longest = 1;
  var current = 1;
  for (var index = 1; index < sorted.length; index++) {
    if (sorted[index] == sorted[index - 1] + 1) {
      current += 1;
      longest = math.max(longest, current);
    } else {
      current = 1;
    }
  }
  return math.max(0, longest - 1);
}

int _largestGridComponent(Set<({int degree, int step})> cells) {
  final remaining = Set<({int degree, int step})>.of(cells);
  var largest = 0;
  while (remaining.isNotEmpty) {
    final start = remaining.first;
    final queue = <({int degree, int step})>[start];
    remaining.remove(start);
    var size = 0;
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      size += 1;
      final neighbors = <({int degree, int step})>[
        (degree: (cell.degree + 1) % 180, step: cell.step),
        (degree: (cell.degree + 179) % 180, step: cell.step),
        (degree: cell.degree, step: cell.step + 1),
        (degree: cell.degree, step: cell.step - 1),
      ];
      for (final neighbor in neighbors) {
        if (remaining.remove(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    largest = math.max(largest, size);
  }
  return largest;
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
