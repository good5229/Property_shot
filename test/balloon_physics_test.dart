import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/hidden_mechanic_state.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();

  GameState stateWithBalloon({TraitType? trait}) {
    final base = levels[3].createState(3);
    final active = base.activeBall.copyWith(position: const Vec2(56, 466));
    return base.copyWith(
      entities: [
        active,
        ...base.entities
            .where((entity) => entity.id != 'active_ball')
            .map(
              (entity) => entity.id == 'balloon'
                  ? entity.copyWith(position: const Vec2(132, 466))
                  : entity,
            ),
      ],
      equippedTrait: trait,
    );
  }

  test('일반 공은 풍선을 움직이지 않고 튕겨 나오며 터뜨리지 않는다', () {
    final result = resolver.resolve(
      stateWithBalloon(),
      const ShotInput(direction: Vec2(1, 0), power: 0.75),
    );

    expect(result.events, contains('balloon_bounced'));
    expect(result.events, isNot(contains('balloon_popped')));
    expect(result.state.entityById('balloon')!.active, isTrue);
    expect(result.state.entityById('balloon')!.position, const Vec2(132, 466));
  });

  test('충돌 직전 속도가 클수록 고정 풍선에서 더 큰 반사 충격이 나온다', () {
    final low = resolver.resolve(
      stateWithBalloon(),
      const ShotInput(direction: Vec2(1, 0), power: 0.35),
    );
    final high = resolver.resolve(
      stateWithBalloon(),
      const ShotInput(direction: Vec2(1, 0), power: 0.95),
    );

    final lowImpact = low.impacts.firstWhere(
      (impact) => impact.entityId == 'balloon',
    );
    final highImpact = high.impacts.firstWhere(
      (impact) => impact.entityId == 'balloon',
    );
    expect(
      highImpact.relativeNormalSpeed,
      greaterThan(lowImpact.relativeNormalSpeed),
    );
    expect(highImpact.impulse, greaterThan(lowImpact.impulse));
    expect(high.state.entityById('balloon')!.position, const Vec2(132, 466));
  });

  test('뾰족함 공은 풍선을 팝하고 한 번 소모한다', () {
    final result = resolver.resolve(
      stateWithBalloon(trait: TraitType.sharp),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.75,
        equippedTrait: TraitType.sharp,
      ),
    );

    expect(
      result.events,
      containsAllInOrder(['balloon_popped', 'sharpness_consumed']),
    );
    expect(result.state.entityById('balloon')!.active, isFalse);
    expect(result.state.equippedTrait, isNull);
    expect(result.state.entityById('balloon')!.visualState, 'popped');
    // 팝은 문을 직접 열지 않고 뒤의 스위치만 노출한다.
    expect(result.state.entityById('balloon_switch')!.visualState, 'revealed');
    expect(result.state.entityById('balloon_switch')!.solid, isTrue);
    expect(result.state.entityById('balloon_gate')!.open, isFalse);
    final revealMoves = result.moves
        .where((move) => move.entityId == 'balloon_switch')
        .toList(growable: false);
    expect(
      revealMoves.map((move) => move.visualState),
      containsAllInOrder([
        HiddenMechanicState.opening,
        HiddenMechanicState.revealed,
      ]),
    );
    final openingIndex = revealMoves.indexWhere(
      (move) => move.visualState == HiddenMechanicState.opening,
    );
    final revealedIndex = revealMoves.indexWhere(
      (move) => move.visualState == HiddenMechanicState.revealed,
    );
    expect(openingIndex, greaterThanOrEqualTo(0));
    expect(revealedIndex, greaterThan(openingIndex));
    expect(
      revealMoves[revealedIndex].triggerPathIndex -
          revealMoves[openingIndex].triggerPathIndex,
      greaterThanOrEqualTo(6),
    );
  });

  test('풍선 linkId가 가리키는 임의 ID의 숨은 기믹을 공개한다', () {
    final base = stateWithBalloon(trait: TraitType.sharp);
    final linked = base.copyWith(
      entities: [
        for (final entity in base.entities)
          if (entity.id == 'balloon')
            entity.copyWith(linkId: 'secret_pad')
          else if (entity.id == 'balloon_switch')
            entity.copyWith(id: 'secret_pad', position: const Vec2(300, 90))
          else
            entity,
      ],
    );

    final result = resolver.resolve(
      linked,
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.75,
        equippedTrait: TraitType.sharp,
      ),
    );

    final secret = result.state.entityById('secret_pad')!;
    expect(secret.visualState, HiddenMechanicState.revealed);
    expect(secret.solid, isTrue);
    expect(
      result.moves
          .where((move) => move.entityId == 'secret_pad')
          .map((move) => move.visualState),
      containsAllInOrder([
        HiddenMechanicState.opening,
        HiddenMechanicState.revealed,
      ]),
    );
  });

  test('이전에 발사된 뾰족함 공도 풍선을 터뜨린다', () {
    final base = stateWithBalloon();
    final previous = base.activeBall.copyWith(
      id: 'spent_ball_1',
      position: const Vec2(112, 466),
      traits: {TraitType.sharp},
      visualState: 'spent',
    );
    final state = base.copyWith(
      entities: [
        base.activeBall,
        previous,
        ...base.entities.where((entity) => entity.id != 'active_ball'),
      ],
    );
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.9),
    );

    expect(result.events, contains('balloon_popped'));
    expect(result.state.entityById('balloon')!.active, isFalse);
  });

  test('되감기는 풍선과 뾰족함 상태를 결정론적으로 복원한다', () {
    final initial = stateWithBalloon(trait: TraitType.sharp);
    final result = resolver.resolve(
      initial,
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.75,
        equippedTrait: TraitType.sharp,
      ),
    );
    final rewound = resolver.rewind(result.state);

    expect(rewound.entityById('balloon')!.active, isTrue);
    expect(rewound.equippedTrait, TraitType.sharp);
    final repeated = resolver.resolve(
      rewound,
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.75,
        equippedTrait: TraitType.sharp,
      ),
    );
    expect(repeated.events, result.events);
    expect(repeated.state.entityById('balloon')!.active, isFalse);
  });
}
