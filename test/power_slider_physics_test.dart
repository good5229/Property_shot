import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';

void main() {
  const resolver = ShotResolver();

  test('파워 슬라이더 JSON은 대상 집합을 안정 순서로 보존한다', () {
    final pattern = PatternObjectDefinition(
      id: 'slider',
      type: EntityType.powerSlider,
      position: const Vec2(120, 260),
      size: const Vec2(48, 64),
      active: true,
      movable: false,
      solid: false,
      direction: const Vec2(0, 2),
      referenceSpeed: 30,
      allowedTargets: const {
        EntityType.weight,
        EntityType.crate,
        EntityType.ball,
      },
    );
    final decoded = PatternObjectDefinition.fromJson(pattern.toJson());

    expect(pattern.toJson()['allowedTargets'], ['ball', 'crate', 'weight']);
    expect(decoded.allowedTargets, pattern.allowedTargets);
    expect(decoded.toEntityState().allowedTargets, pattern.allowedTargets);
  });

  test('슬라이더 정책은 방향·속력·대상·정적 비고체 조건을 안정 오류로 거부한다', () {
    final stage = _stageWith(
      slider: const PatternObjectDefinition(
        id: 'slider',
        type: EntityType.powerSlider,
        position: Vec2(120, 260),
        size: Vec2(48, 64),
        active: false,
        movable: true,
        solid: true,
        direction: Vec2.zero,
        referenceSpeed: 0,
        allowedTargets: {EntityType.wall},
      ),
    );
    final report = StagePatternValidator().validatePattern(
      stage,
      stage.patterns.single,
      enforceProductionPolicy: false,
    );

    expect(
      report.codes,
      containsAll(<ValidationIssueCode>[
        ValidationIssueCode.invalidSliderDirection,
        ValidationIssueCode.invalidSliderReferenceSpeed,
        ValidationIssueCode.invalidSliderTargets,
        ValidationIssueCode.sliderMustBeStatic,
        ValidationIssueCode.sliderMustBeNonSolid,
      ]),
    );
  });

  test('validator가 nonfinite direction을 독립적으로 거부한다', () {
    final report = _sliderReport(direction: const Vec2(double.nan, 1));
    expect(report.hasCode(ValidationIssueCode.invalidSliderDirection), true);
  });

  test('validator가 nonfinite·0·상한 초과 기준 속력을 독립적으로 거부한다', () {
    for (final value in [double.nan, double.infinity, 0.0, -1.0]) {
      final report = _sliderReport(referenceSpeed: value);
      expect(
        report.hasCode(ValidationIssueCode.invalidSliderReferenceSpeed),
        true,
      );
    }
    expect(
      _sliderReport(
        referenceSpeed: 48.0,
      ).hasCode(ValidationIssueCode.invalidSliderReferenceSpeed),
      false,
    );
    expect(
      _sliderReport(
        referenceSpeed: 48.01,
      ).hasCode(ValidationIssueCode.invalidSliderReferenceSpeed),
      true,
    );
  });

  test('validator가 빈 allowedTargets를 독립적으로 거부한다', () {
    expect(
      _sliderReport(
        allowedTargets: const {},
      ).hasCode(ValidationIssueCode.invalidSliderTargets),
      true,
    );
  });

  test('validator가 금지된 allowedTarget을 독립적으로 거부한다', () {
    expect(
      _sliderReport(
        allowedTargets: const {EntityType.wall},
      ).hasCode(ValidationIssueCode.invalidSliderTargets),
      true,
    );
  });

  test('validator가 active=false를 독립적으로 거부한다', () {
    expect(
      _sliderReport(
        active: false,
      ).hasCode(ValidationIssueCode.sliderMustBeStatic),
      true,
    );
  });

  test('validator가 movable=true를 독립적으로 거부한다', () {
    expect(
      _sliderReport(
        movable: true,
      ).hasCode(ValidationIssueCode.sliderMustBeStatic),
      true,
    );
  });

  test('validator가 solid=true를 독립적으로 거부한다', () {
    expect(
      _sliderReport(
        solid: true,
      ).hasCode(ValidationIssueCode.sliderMustBeNonSolid),
      true,
    );
  });

  test('validator가 보드 밖 slider를 독립적으로 거부한다', () {
    expect(
      _sliderReport(
        position: const Vec2(-10, 280),
      ).hasCode(ValidationIssueCode.objectOutOfBounds),
      true,
    );
  });

  test('validator가 고체와 겹친 slider를 독립적으로 거부한다', () {
    final report = _sliderReport(
      extra: const [
        PatternObjectDefinition(
          id: 'crate',
          type: EntityType.crate,
          position: Vec2(120, 280),
          size: Vec2(40, 40),
          movable: true,
          solid: true,
        ),
      ],
    );
    expect(report.hasCode(ValidationIssueCode.sliderOverlapsSolid), true);
  });

  test('슬라이더 작동은 방향을 바꾸지 않고 기준 속력의 최댓값만 적용한다', () {
    final result = resolver.resolve(
      _state(
        slider: const EntityState(
          id: 'slider',
          type: EntityType.powerSlider,
          position: Vec2(100, 280),
          size: Vec2(36, 60),
          solid: false,
          direction: Vec2(0, 1),
          referenceSpeed: 30,
          allowedTargets: {EntityType.ball},
        ),
      ),
      const ShotInput(direction: Vec2(1, 0), power: 0.35),
    );

    expect(result.powerSliderActivations, hasLength(1));
    final activation = result.powerSliderActivations.single;
    expect(activation.sourceEntityId, 'active_ball');
    expect(activation.speedBefore, lessThan(activation.referenceSpeed));
    expect(activation.speedAfter, activation.referenceSpeed);
    expect(activation.direction, const Vec2(0, 1));
    expect(activation.motionDirection, const Vec2(1, 0));
    expect(activation.velocityBefore.x, activation.speedBefore);
    expect(activation.velocityAfter.x, activation.speedAfter);
    expect(
      result.impacts.any(
        (impact) => impact.entityType == EntityType.powerSlider,
      ),
      isFalse,
    );
    expect(
      result.physicsEvents.where(
        (event) => event.kind == PhysicsEventKind.powerSliderActivation,
      ),
      hasLength(1),
    );
    expect(
      result.physicsEvents
          .singleWhere(
            (event) => event.kind == PhysicsEventKind.powerSliderActivation,
          )
          .contactId,
      activation.contactId,
    );
    expect(
      result.physicsEvents
          .singleWhere(
            (event) => event.kind == PhysicsEventKind.powerSliderActivation,
          )
          .resultingVelocity,
      activation.velocityAfter,
    );
  });

  test('같은 접촉은 한 번만 작동하고 완전 이탈 후 재진입은 다시 작동한다', () {
    final once = resolver.resolve(
      _state(
        slider: const EntityState(
          id: 'slider',
          type: EntityType.powerSlider,
          position: Vec2(100, 280),
          size: Vec2(80, 60),
          solid: false,
          direction: Vec2(1, 0),
          referenceSpeed: 28,
          allowedTargets: {EntityType.ball},
        ),
        extra: const [
          EntityState(
            id: 'hole_after_slider',
            type: EntityType.hole,
            position: Vec2(180, 280),
            size: Vec2(24, 24),
            solid: false,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(once.powerSliderActivations, hasLength(1));
    final oncePathIndices = once.powerSliderActivations
        .map((activation) => activation.pathIndex)
        .toList();
    expect(oncePathIndices.toSet(), hasLength(oncePathIndices.length));

    final reentry = resolver.resolve(
      _state(
        slider: const EntityState(
          id: 'slider',
          type: EntityType.powerSlider,
          position: Vec2(90, 280),
          size: Vec2(30, 60),
          solid: false,
          direction: Vec2(1, 0),
          referenceSpeed: 30,
          allowedTargets: {EntityType.ball},
        ),
        extra: const [
          EntityState(
            id: 'wall',
            type: EntityType.wall,
            position: Vec2(150, 280),
            size: Vec2(18, 80),
            solid: true,
          ),
          EntityState(
            id: 'hole_after_reentry',
            type: EntityType.hole,
            position: Vec2(0, 280),
            size: Vec2(20, 20),
            solid: false,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(
      reentry.powerSliderActivations
          .where((activation) => activation.contactId == 'active_ball:slider')
          .length,
      2,
    );
  });

  test('홀과 점착 정지는 슬라이더보다 우선한다', () {
    final holeFirst = resolver.resolve(
      _state(
        slider: const EntityState(
          id: 'slider',
          type: EntityType.powerSlider,
          position: Vec2(170, 280),
          size: Vec2(36, 60),
          solid: false,
          direction: Vec2(1, 0),
          referenceSpeed: 40,
          allowedTargets: {EntityType.ball},
        ),
        extra: const [
          EntityState(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(100, 280),
            size: Vec2(36, 36),
            solid: false,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 0.4),
    );
    expect(holeFirst.state.phase, GamePhase.success);
    expect(holeFirst.powerSliderActivations, isEmpty);

    final stickyFirst = resolver.resolve(
      _state(
        slider: const EntityState(
          id: 'slider',
          type: EntityType.powerSlider,
          position: Vec2(170, 280),
          size: Vec2(36, 60),
          solid: false,
          direction: Vec2(1, 0),
          referenceSpeed: 40,
          allowedTargets: {EntityType.ball},
        ),
        extra: const [
          EntityState(
            id: 'sticky',
            type: EntityType.stickySurface,
            position: Vec2(100, 280),
            size: Vec2(36, 60),
            solid: true,
          ),
        ],
      ),
      const ShotInput(
        direction: Vec2(1, 0),
        power: 0.4,
        equippedTrait: TraitType.sticky,
      ),
    );
    expect(stickyFirst.events, contains('sticky_attached'));
    expect(stickyFirst.powerSliderActivations, isEmpty);
  });

  test('같은 시점의 고체 충돌은 슬라이더보다 우선한다', () {
    final result = resolver.resolve(
      _state(
        slider: _slider(id: 'slider', x: 100, referenceSpeed: 60),
        extra: const [
          EntityState(
            id: 'solid',
            type: EntityType.crate,
            position: Vec2(100, 280),
            size: Vec2(36, 60),
            movable: false,
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 0.45),
    );
    expect(result.powerSliderActivations, isEmpty);
    expect(result.impacts.any((impact) => impact.entityId == 'solid'), isTrue);
  });

  test('연쇄로 이동한 공도 같은 슬라이더 계약을 적용한다', () {
    final result = resolver.resolve(
      _state(
        slider: const EntityState(
          id: 'slider',
          type: EntityType.powerSlider,
          position: Vec2(180, 280),
          size: Vec2(36, 60),
          solid: false,
          direction: Vec2(-1, 0),
          referenceSpeed: 34,
          allowedTargets: {EntityType.ball},
        ),
        extra: const [
          EntityState(
            id: 'other_ball',
            type: EntityType.ball,
            position: Vec2(100, 280),
            size: Vec2(24, 24),
            movable: true,
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(
      result.powerSliderActivations.any(
        (activation) => activation.sourceEntityId == 'other_ball',
      ),
      isTrue,
    );
  });

  test('현재 속력이 기준 속력보다 빠르면 속력은 정확히 불변이다', () {
    final result = resolver.resolve(
      _state(
        slider: _slider(id: 'slider', x: 100, referenceSpeed: 4),
        extra: const [
          EntityState(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(165, 280),
            size: Vec2(24, 24),
            solid: false,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final activation = result.powerSliderActivations.single;
    expect(activation.speedBefore, greaterThan(activation.referenceSpeed));
    expect(activation.speedAfter, activation.speedBefore);
    expect(activation.speedAfter, isNot(activation.speedBefore + 4));
  });

  test('같은 시점의 복수 슬라이더는 각 1회이며 기준 속력 최댓값을 적용한다', () {
    final result = resolver.resolve(
      _state(
        slider: _slider(id: 'slider_a', x: 100, referenceSpeed: 30),
        extra: [_slider(id: 'slider_b', x: 100, referenceSpeed: 50)],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 0.45),
    );
    expect(result.powerSliderActivations.map((e) => e.sliderEntityId), [
      'slider_a',
      'slider_b',
    ]);
    expect(
      result.powerSliderActivations.every((e) => e.speedAfter == 50),
      isTrue,
    );
  });

  test('앞 슬라이더와 뒤 슬라이더는 실제 도달 순서로 각각 작동한다', () {
    final result = resolver.resolve(
      _state(
        slider: _slider(id: 'slider_front', x: 100, referenceSpeed: 28),
        extra: [
          _slider(id: 'slider_back', x: 170, referenceSpeed: 36),
          const EntityState(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(235, 280),
            size: Vec2(24, 24),
            solid: false,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(
      result.powerSliderActivations.map((e) => e.sliderEntityId).toList(),
      ['slider_front', 'slider_back'],
    );
    expect(
      result.powerSliderActivations.map((e) => e.contactId).toSet(),
      hasLength(2),
    );
  });

  test('허용 대상에서 제외된 이동체와 movable=false 이동체는 작동하지 않는다', () {
    final excluded = resolver.resolve(
      _state(
        slider: _slider(
          id: 'slider',
          x: 100,
          allowedTargets: {EntityType.weight},
        ),
      ),
      const ShotInput(direction: Vec2(1, 0), power: 0.5),
    );
    expect(excluded.powerSliderActivations, isEmpty);

    final fixedMover = resolver.resolve(
      _state(
        slider: _slider(id: 'slider', x: 180),
        extra: const [
          EntityState(
            id: 'fixed_ball',
            type: EntityType.ball,
            position: Vec2(105, 280),
            size: Vec2(24, 24),
            movable: false,
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(
      fixedMover.powerSliderActivations.any(
        (e) => e.sourceEntityId == 'fixed_ball',
      ),
      isFalse,
    );
  });

  test('crate와 weight 연쇄 이동 모두에 슬라이더가 적용된다', () {
    final result = resolver.resolve(
      _state(
        slider: _slider(
          id: 'slider_crate',
          x: 130,
          referenceSpeed: 34,
          allowedTargets: {EntityType.crate},
        ),
        extra: const [
          EntityState(
            id: 'slider_weight',
            type: EntityType.powerSlider,
            position: Vec2(190, 280),
            size: Vec2(36, 60),
            solid: false,
            direction: Vec2(1, 0),
            referenceSpeed: 34,
            allowedTargets: {EntityType.weight},
          ),
          EntityState(
            id: 'crate',
            type: EntityType.crate,
            position: Vec2(105, 280),
            size: Vec2(28, 28),
            movable: true,
            solid: true,
          ),
          EntityState(
            id: 'weight',
            type: EntityType.weight,
            position: Vec2(155, 280),
            size: Vec2(32, 32),
            movable: true,
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(
      result.powerSliderActivations.map((e) => e.sourceEntityId).toSet(),
      containsAll(<String>{'crate', 'weight'}),
    );
  });

  test('기준 속력 48 연쇄 이동은 벽을 넘지 않고 안전하게 결정 종료된다', () {
    const chainWall = EntityState(
      id: 'chain_wall_48',
      type: EntityType.wall,
      position: Vec2(225, 280),
      size: Vec2(10, 120),
      solid: true,
    );
    final initial = _state(
      slider: _slider(
        id: 'slider_crate_48',
        x: 130,
        referenceSpeed: 48.0,
        allowedTargets: {EntityType.crate},
      ),
      extra: const [
        EntityState(
          id: 'crate_48',
          type: EntityType.crate,
          position: Vec2(105, 280),
          size: Vec2(28, 28),
          movable: true,
          solid: true,
        ),
        chainWall,
      ],
    );
    const input = ShotInput(direction: Vec2(1, 0), power: 1);
    final first = resolver.resolve(initial, input);
    final second = resolver.resolve(initial, input);

    expect(first.chainSafetyDiagnostics, isEmpty);
    expect(first.powerSliderActivations.single.referenceSpeed, 48.0);
    expect(
      first.powerSliderActivations.single.speedAfter,
      greaterThanOrEqualTo(48.0),
    );
    expect(
      first.physicsEvents.every(
        (event) =>
            event.position.x.isFinite &&
            event.position.y.isFinite &&
            event.resultingVelocity.x.isFinite &&
            event.resultingVelocity.y.isFinite,
      ),
      true,
    );
    expect(
      first.state.entities.every(
        (entity) =>
            entity.position.x.isFinite &&
            entity.position.y.isFinite &&
            entity.hitBounds.left.isFinite &&
            entity.hitBounds.top.isFinite &&
            entity.hitBounds.right.isFinite &&
            entity.hitBounds.bottom.isFinite,
      ),
      true,
    );
    final crate = first.state.entityById('crate_48');
    final wall = first.state.entityById('chain_wall_48');
    expect(crate, isNotNull);
    expect(wall, isNotNull);
    expect(
      first.impacts.any(
        (impact) =>
            impact.entityId == 'chain_wall_48' &&
            impact.sourceEntityId == 'crate_48',
      ),
      true,
    );
    final crateBounds = crate!.hitBounds;
    final wallBounds = wall!.hitBounds;
    expect(crateBounds.left, greaterThanOrEqualTo(0));
    expect(crateBounds.top, greaterThanOrEqualTo(0));
    expect(crateBounds.right, lessThanOrEqualTo(360));
    expect(crateBounds.bottom, lessThanOrEqualTo(560));
    expect(
      crateBounds.right <= wallBounds.left + 0.001 ||
          crateBounds.left >= wallBounds.right - 0.001,
      true,
    );
    final resolvedWall = first.state.entityById('chain_wall_48')!;
    expect(resolvedWall.position, chainWall.position);
    expect(resolvedWall.size, chainWall.size);
    expect(resolvedWall.movable, chainWall.movable);
    expect(resolvedWall.solid, chainWall.solid);
    expect(resolvedWall.active, chainWall.active);
    expect(resolvedWall.open, chainWall.open);
    expect(resolvedWall.pressed, chainWall.pressed);
    expect(
      first.powerSliderActivations.map((event) => event.contactId),
      second.powerSliderActivations.map((event) => event.contactId),
    );
    expect(
      first.physicsEvents.map((event) => event.eventId),
      second.physicsEvents.map((event) => event.eventId),
    );
    expect(
      first.state.entities.map((entity) => entity.position),
      second.state.entities.map((entity) => entity.position),
    );
  });

  test('슬라이더 직후 벽·얇은 벽은 반사 이벤트를 남기고 터널링하지 않는다', () {
    final result = resolver.resolve(
      _state(
        slider: _slider(id: 'slider', x: 100, referenceSpeed: 40),
        extra: const [
          EntityState(
            id: 'thin_wall',
            type: EntityType.wall,
            position: Vec2(145, 280),
            size: Vec2(2, 100),
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final sliderIndex = result.physicsEvents.indexWhere(
      (event) => event.kind == PhysicsEventKind.powerSliderActivation,
    );
    final wallIndex = result.physicsEvents.indexWhere(
      (event) => event.targetEntityId == 'thin_wall',
    );
    expect(sliderIndex, greaterThanOrEqualTo(0));
    expect(wallIndex, greaterThan(sliderIndex));
    expect(
      result.impacts.any((impact) => impact.entityId == 'thin_wall'),
      true,
    );
  });

  test('슬라이더 직후 홀 포획은 뒤 벽 이벤트를 만들지 않는다', () {
    final result = resolver.resolve(
      _state(
        slider: _slider(id: 'slider', x: 100, referenceSpeed: 40),
        extra: const [
          EntityState(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(145, 280),
            size: Vec2(32, 32),
            solid: false,
          ),
          EntityState(
            id: 'behind_wall',
            type: EntityType.wall,
            position: Vec2(190, 280),
            size: Vec2(10, 100),
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(result.state.phase, GamePhase.success);
    expect(result.impacts.any((impact) => impact.entityId == 'hole'), true);
    expect(
      result.impacts.any((impact) => impact.entityId == 'behind_wall'),
      isFalse,
    );
  });

  test('벽은 전후 물리 상태가 완전히 불변이다', () {
    final wall = const EntityState(
      id: 'wall',
      type: EntityType.wall,
      position: Vec2(150, 280),
      size: Vec2(14, 100),
      solid: true,
    );
    final before = _state(
      slider: _slider(id: 'slider', x: 100),
      extra: [wall],
    );
    final after = resolver
        .resolve(before, const ShotInput(direction: Vec2(1, 0), power: 1))
        .state
        .entityById('wall');
    expect(after, isNotNull);
    expect(after!.position, wall.position);
    expect(after.size, wall.size);
    expect(after.movable, wall.movable);
    expect(after.solid, wall.solid);
    expect(after.active, wall.active);
  });

  test('동일 입력은 activation·event ID와 최종 상태가 결정론적이다', () {
    final initial = _state(
      slider: _slider(id: 'slider', x: 100, referenceSpeed: 34),
    );
    final first = resolver.resolve(
      initial,
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );
    final second = resolver.resolve(
      initial,
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );
    expect(
      first.powerSliderActivations.map((e) => '${e.contactId}:${e.pathIndex}'),
      second.powerSliderActivations.map((e) => '${e.contactId}:${e.pathIndex}'),
    );
    expect(
      first.physicsEvents.map((event) => event.eventId),
      second.physicsEvents.map((event) => event.eventId),
    );
    expect(first.state.phase, second.state.phase);
    expect(
      first.state.entities.map((e) => e.position),
      second.state.entities.map((e) => e.position),
    );
  });

  test('다수 슬라이더·이동체 스트레스에서도 안전 중단과 비유한 상태가 없다', () {
    final sliders = [
      for (var index = 0; index < 12; index++)
        _slider(
          id: 'slider_$index',
          x: 70 + index * 20.0,
          referenceSpeed: 22.0 + index,
        ),
    ];
    final movers = [
      for (var index = 0; index < 8; index++)
        EntityState(
          id: 'mover_$index',
          type: index.isEven ? EntityType.crate : EntityType.weight,
          position: Vec2(120 + index * 24.0, 360),
          size: const Vec2(24, 24),
          movable: true,
          solid: true,
        ),
    ];
    final result = resolver.resolve(
      _state(slider: sliders.first, extra: [...sliders.skip(1), ...movers]),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(result.chainSafetyDiagnostics, isEmpty);
    expect(
      result.path.every((point) => point.x.isFinite && point.y.isFinite),
      true,
    );
    expect(
      result.physicsEvents.every(
        (event) =>
            event.position.x.isFinite &&
            event.position.y.isFinite &&
            event.resultingVelocity.x.isFinite &&
            event.resultingVelocity.y.isFinite,
      ),
      true,
    );
  });

  test('실제 runtime probe는 슬라이더 존재와 비터널링을 분리해 보고한다', () {
    final stage = _stageWith(
      slider: const PatternObjectDefinition(
        id: 'slider',
        type: EntityType.powerSlider,
        position: Vec2(120, 280),
        size: Vec2(48, 64),
        solid: false,
        direction: Vec2(1, 0),
        referenceSpeed: 30,
        allowedTargets: {EntityType.ball},
      ),
    );
    final evidence = ShotResolverPatternRuntimeProbe(
      representativeInputs: const [
        ShotInput(direction: Vec2(1, 0), power: 0.7),
      ],
      maxProbeCount: 2,
      maxShots: 4,
    ).probe(stage: stage, pattern: stage.patterns.single);

    expect(evidence.sliderApplicable, isTrue);
    expect(evidence.sliderTunneling, isFalse);
  });

  test('runtime probe는 영역 통과 후 activation이 없으면 tunneling을 양성 보고한다', () {
    final stage = _stageWith(
      slider: const PatternObjectDefinition(
        id: 'slider',
        type: EntityType.powerSlider,
        position: Vec2(120, 280),
        size: Vec2(48, 64),
        solid: false,
        direction: Vec2(1, 0),
        referenceSpeed: 30,
        allowedTargets: {EntityType.ball},
      ),
    );
    final evidence = ShotResolverPatternRuntimeProbe(
      shotResolver: const _NoActivationResolver(),
      representativeInputs: const [
        ShotInput(direction: Vec2(1, 0), power: 0.7),
      ],
      maxProbeCount: 2,
      maxShots: 4,
    ).probe(stage: stage, pattern: stage.patterns.single);

    expect(evidence.sliderApplicable, true);
    expect(evidence.sliderTunneling, true);
  });
}

EntityState _slider({
  required String id,
  required double x,
  double referenceSpeed = 30,
  Set<EntityType> allowedTargets = const {EntityType.ball},
  Vec2 direction = const Vec2(1, 0),
}) {
  return EntityState(
    id: id,
    type: EntityType.powerSlider,
    position: Vec2(x, 280),
    size: const Vec2(36, 60),
    solid: false,
    direction: direction,
    referenceSpeed: referenceSpeed,
    allowedTargets: allowedTargets,
  );
}

ValidationReport _sliderReport({
  Vec2 direction = const Vec2(1, 0),
  double referenceSpeed = 30,
  Set<EntityType> allowedTargets = const {EntityType.ball},
  bool active = true,
  bool movable = false,
  bool solid = false,
  Vec2 position = const Vec2(120, 280),
  List<PatternObjectDefinition> extra = const [],
}) {
  final stage = _stageWith(
    slider: PatternObjectDefinition(
      id: 'slider',
      type: EntityType.powerSlider,
      position: position,
      size: const Vec2(48, 64),
      active: active,
      movable: movable,
      solid: solid,
      direction: direction,
      referenceSpeed: referenceSpeed,
      allowedTargets: allowedTargets,
    ),
    extra: extra,
  );
  return StagePatternValidator().validatePattern(
    stage,
    stage.patterns.single,
    enforceProductionPolicy: false,
  );
}

GameState _state({
  required EntityState slider,
  List<EntityState> extra = const [],
}) {
  final active = const EntityState(
    id: 'active_ball',
    type: EntityType.ball,
    position: Vec2(40, 280),
    size: Vec2(24, 24),
    movable: true,
    solid: true,
  );
  return GameState(
    levelIndex: 0,
    levelName: '파워 슬라이더 시험',
    entities: [active, slider, ...extra],
    ballSpawn: active.position,
  );
}

StageDefinition _stageWith({
  required PatternObjectDefinition slider,
  List<PatternObjectDefinition> extra = const [],
}) {
  return StageDefinition(
    stageId: 'slider_stage',
    title: '파워 슬라이더 시험',
    patterns: [
      StagePattern(
        patternId: 'slider_pattern',
        weight: 1,
        parShots: 3,
        difficultyBand: '중급',
        ballSpawn: const Vec2(40, 280),
        solutionFamilies: const {'직접 진입', '반사'},
        objects: [
          const PatternObjectDefinition(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(320, 480),
            size: Vec2(36, 36),
            solid: false,
          ),
          slider,
          ...extra,
        ],
      ),
    ],
  );
}

class _NoActivationResolver extends ShotResolver {
  const _NoActivationResolver();

  @override
  ShotResult resolve(GameState state, ShotInput input) {
    final actual = const ShotResolver().resolve(state, input);
    return ShotResult(
      state: actual.state,
      path: actual.path,
      events: actual.events,
      moves: actual.moves,
      impacts: actual.impacts,
      powerSliderActivations: const [],
      physicsEvents: actual.physicsEvents
          .where(
            (event) => event.kind != PhysicsEventKind.powerSliderActivation,
          )
          .toList(growable: false),
      chainSafetyDiagnostics: actual.chainSafetyDiagnostics,
    );
  }
}
