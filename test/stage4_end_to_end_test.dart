import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();

  test('4단계 실제 입력이 풍선부터 홀 포획까지 한 번에 재생된다', () {
    final initial = levels[3].createState(3);
    final source = initial.entityById('spike_source')!;
    final prepared = initial.copyWith(
      equippedTrait: TraitType.sharp,
      selectedSourceId: source.id,
      entities: [
        for (final entity in initial.entities)
          entity.id == source.id
              ? entity.copyWith(traits: {TraitType.sharp})
              : entity,
      ],
    );

    ShotResult? solution;
    for (var degree = 0; degree < 360 && solution == null; degree += 2) {
      final radians = degree * math.pi / 180;
      for (var step = 15; step <= 50 && solution == null; step++) {
        final result = resolver.resolve(
          prepared,
          ShotInput(
            direction: Vec2(math.cos(radians), math.sin(radians)),
            power: step / 50,
            equippedTrait: TraitType.sharp,
          ),
        );
        if (result.state.phase == GamePhase.success &&
            result.events.contains('balloon_popped') &&
            result.events.contains('balloon_switch_pressed') &&
            result.events.contains('hole_entered')) {
          solution = result;
        }
      }
    }

    expect(solution, isNotNull);
    final result = solution!;
    final balloon = result.state.entityById('balloon')!;
    final balloonSwitch = result.state.entityById('balloon_switch')!;
    final gate = result.state.entityById('balloon_gate')!;
    final hole = result.state.entityById('hole')!;

    expect(result.state.phase, GamePhase.success);
    expect(balloon.active, isFalse);
    expect(balloon.solid, isFalse);
    expect(balloon.visualState, 'popped');
    expect(balloonSwitch.pressed, isTrue);
    expect(balloonSwitch.solid, isFalse);
    expect(gate.open, isTrue);
    expect(gate.solid, isFalse);
    expect(
      result.state.entities
          .firstWhere((entity) => entity.id == 'spent_ball_1')
          .position,
      hole.position,
    );

    final events = result.physicsEvents;
    final balloonImpact = _indexOf(
      events,
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetEntityId == 'balloon',
    );
    final popped = _indexOf(
      events,
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetEntityId == 'balloon' &&
          event.visualState == 'popped',
    );
    final revealed = _indexOf(
      events,
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetEntityId == 'balloon_switch' &&
          event.visualState == 'revealed',
    );
    final switchImpact = _indexOf(
      events,
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetEntityId == 'balloon_switch',
    );
    final opened = _indexOf(
      events,
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetEntityId == 'balloon_gate' &&
          event.visualState == 'open',
    );
    final holeImpact = _indexOf(
      events,
      (event) =>
          event.kind == PhysicsEventKind.impact &&
          event.targetType == EntityType.hole,
    );
    final captured = _indexOf(
      events,
      (event) =>
          event.kind == PhysicsEventKind.stateChange &&
          event.targetType == EntityType.hole &&
          event.visualState == 'captured',
    );

    expect(popped, greaterThan(balloonImpact));
    expect(revealed, greaterThan(popped));
    expect(switchImpact, greaterThan(revealed));
    expect(opened, greaterThan(switchImpact));
    expect(holeImpact, greaterThan(opened));
    expect(captured, greaterThan(holeImpact));
    expect(
      events.where((event) => event.kind == PhysicsEventKind.chainSafetyStop),
      isEmpty,
    );
    expect(
      events
          .skip(captured)
          .where((event) => event.kind == PhysicsEventKind.impact),
      isEmpty,
    );
  });
}

int _indexOf(
  List<PhysicsEvent> events,
  bool Function(PhysicsEvent event) predicate,
) {
  return events.indexWhere(predicate);
}
