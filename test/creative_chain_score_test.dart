import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import 'fixtures/stage_persistent_patterns.dart';

void main() {
  const analyzer = CreativeChainScoreAnalyzer();

  test('홀의 부모 사건에서 인과 깊이와 기물 다양성을 산출한다', () {
    final result = _syntheticResult(
      events: _causalEvents(),
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze(
      [result],
      parShots: 3,
      optionalChallengeIds: CreativeChainChallengeId.all,
    );

    expect(analysis.clearReached, isTrue);
    expect(analysis.holeShotIndex, 0);
    expect(analysis.breakdown.causalDepth, 9);
    expect(analysis.breakdown.distinctEntityTypes, greaterThanOrEqualTo(4));
    expect(analysis.breakdown.distinctEntityIds, greaterThanOrEqualTo(4));
    expect(analysis.breakdown.wallReflectionCount, 2);
    expect(analysis.breakdown.pastBallCount, 1);
    expect(analysis.breakdown.powerSliderCount, 1);
    expect(analysis.breakdown.boardStateChangeCount, 3);
    expect(analysis.breakdown.movedEntityCount, 1);
    expect(analysis.breakdown.traitActivationCount, 1);
    expect(analysis.breakdown.traitConsumptionCount, 1);
    expect(
      analysis.completedOptionalChallengeIds,
      containsAll(<String>[
        CreativeChainChallengeId.wallReflection,
        CreativeChainChallengeId.pastBall,
        CreativeChainChallengeId.traitReaction,
        CreativeChainChallengeId.powerSlider,
        CreativeChainChallengeId.boardState,
        CreativeChainChallengeId.diverseChain,
      ]),
    );
    expect(analysis.totalScore, greaterThan(1000));
    expect(
      analysis.evidence
          .where(
            (item) => item.kind == CreativeChainEvidenceKind.wallReflection,
          )
          .fold<int>(0, (total, item) => total + item.points),
      analysis.breakdown.wallReflectionPoints,
    );
    expect(
      analysis.evidence.fold<int>(0, (total, item) => total + item.points),
      analysis.totalScore,
    );
  });

  test('같은 벽면 반복과 미세 진동은 감쇠·제외되고 총 충돌은 상한을 지킨다', () {
    final repeated = <PhysicsEvent>[];
    repeated.add(
      _impact(
        id: 'micro',
        pathIndex: 0,
        targetId: 'same_wall',
        targetType: EntityType.wall,
        normal: const Vec2(0, -1),
        impulse: 0.01,
        relativeNormalSpeed: 0.01,
      ),
    );
    String parent = 'micro';
    for (var index = 0; index < 18; index++) {
      final event = _impact(
        id: 'wall-$index',
        parent: parent,
        pathIndex: index + 1,
        targetId: 'same_wall',
        targetType: EntityType.wall,
        normal: const Vec2(0, -1),
        impulse: 1,
      );
      repeated.add(event);
      parent = event.eventId;
    }
    repeated.add(
      _impact(
        id: 'hole',
        parent: 'wall-17',
        pathIndex: 40,
        targetId: 'hole',
        targetType: EntityType.hole,
        impulse: 1,
      ),
    );

    final breakdown = analyzer.analyze([
      _syntheticResult(events: repeated, phase: GamePhase.success),
    ], parShots: 1).breakdown;

    expect(breakdown.qualifiedImpactCount, 12);
    expect(breakdown.cappedImpactCount, greaterThan(0));
    expect(breakdown.dampedImpactCount, greaterThan(0));
    expect(breakdown.ignoredImpactCount, 1);
    expect(breakdown.causalDepth, 1);
  });

  test('같은 과거 공을 반복해서 맞혀도 활용 횟수는 한 번만 센다', () {
    final impacts = <PhysicsEvent>[];
    String? parent;
    for (var index = 0; index < 3; index++) {
      final event = _impact(
        id: 'past-$index',
        parent: parent,
        pathIndex: index * 20,
        targetId: 'spent_ball_1',
        targetType: EntityType.ball,
        impulse: 1,
      );
      impacts.add(event);
      parent = event.eventId;
    }
    impacts.add(
      _impact(
        id: 'hole',
        parent: parent,
        pathIndex: 80,
        targetId: 'hole',
        targetType: EntityType.hole,
        impulse: 1,
      ),
    );

    final breakdown = analyzer.analyze([
      _syntheticResult(events: impacts, phase: GamePhase.success),
    ], parShots: 1).breakdown;

    expect(breakdown.pastBallCount, 1);
    expect(breakdown.pastBallPoints, 55);
  });

  test('무거움과 탄성 충돌은 서로 다른 속성 발동으로 기록한다', () {
    final heavy = _impact(
      id: 'heavy',
      pathIndex: 1,
      targetId: 'crate',
      targetType: EntityType.crate,
      impulse: 1,
      sourceTraits: const {TraitType.heavy},
    );
    final bouncy = _impact(
      id: 'bouncy',
      parent: heavy.eventId,
      pathIndex: 20,
      targetId: 'wall',
      targetType: EntityType.wall,
      impulse: 1,
      sourceTraits: const {TraitType.bouncy},
    );
    final result = _syntheticResult(
      events: [
        heavy,
        bouncy,
        _impact(
          id: 'hole',
          parent: bouncy.eventId,
          pathIndex: 30,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 1,
        ),
      ],
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze([result], parShots: 1);

    expect(analysis.breakdown.traitActivationCount, 2);
    expect(analysis.breakdown.traitActivationPoints, 90);
  });

  test('최종 홀과 무관한 충돌은 별도 제한으로만 반영한다', () {
    final unrelated = _impact(
      id: 'unrelated',
      pathIndex: 1,
      targetId: 'unrelated_crate',
      targetType: EntityType.crate,
      impulse: 1,
    );
    final result = _syntheticResult(
      events: [
        unrelated,
        _impact(
          id: 'hole',
          pathIndex: 20,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 1,
          sourceEntityId: 'direct_ball',
        ),
      ],
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze([result], parShots: 1);

    expect(analysis.breakdown.unrelatedImpactCount, 1);
    expect(analysis.breakdown.unrelatedImpactPoints, lessThanOrEqualTo(12));
    expect(analysis.breakdown.causalDepth, 0);
    expect(analysis.breakdown.distinctEntityIds, 0);
  });

  test('준비 샷으로 만들어진 과거 공은 최종 샷의 기여로 설명된다', () {
    final first = _syntheticResult(
      events: [
        _impact(
          id: 'first-wall',
          pathIndex: 4,
          targetId: 'wall',
          targetType: EntityType.wall,
          impulse: 1,
        ),
      ],
      phase: GamePhase.planning,
      entities: [_entity('spent_ball_1', EntityType.ball)],
      shotCount: 1,
    );
    final second = _syntheticResult(
      events: [
        _impact(
          id: 'past-ball',
          pathIndex: 8,
          targetId: 'spent_ball_1',
          targetType: EntityType.ball,
          impulse: 1,
        ),
        _impact(
          id: 'hole',
          parent: 'past-ball',
          pathIndex: 20,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 1,
        ),
      ],
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze([first, second], parShots: 3);

    expect(analysis.holeShotIndex, 1);
    expect(analysis.breakdown.preparationShotCount, 1);
    expect(analysis.preparationContributions.single.shotIndex, 0);
    expect(analysis.preparationContributions.single.entityIds, {
      'spent_ball_1',
    });
    expect(analysis.breakdown.minimumShotBonus, 35);
  });

  test('이전 샷에 이미 존재한 과거 공은 다음 준비 샷에서 다시 적립하지 않는다', () {
    final spentBall = _entity('spent_ball_1', EntityType.ball);
    final first = _syntheticResult(
      events: const [],
      phase: GamePhase.planning,
      entities: [spentBall],
      shotCount: 1,
    );
    final second = _syntheticResult(
      events: const [],
      phase: GamePhase.planning,
      entities: [spentBall],
      shotCount: 2,
    );
    final third = _syntheticResult(
      events: [
        _impact(
          id: 'past-ball',
          pathIndex: 8,
          targetId: 'spent_ball_1',
          targetType: EntityType.ball,
          impulse: 1,
        ),
        _impact(
          id: 'hole',
          parent: 'past-ball',
          pathIndex: 20,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 1,
        ),
      ],
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze([first, second, third], parShots: 3);

    expect(analysis.preparationContributions, hasLength(1));
    expect(analysis.preparationContributions.single.shotIndex, 0);
  });

  test('다음 샷 전에 되돌아간 기물 이동은 준비 샷 기여로 세지 않는다', () {
    final first = _syntheticResult(
      events: [_moveEvent('crate', const Vec2(20, 0))],
      phase: GamePhase.planning,
      entities: [
        _entity('crate', EntityType.crate, position: const Vec2(20, 0)),
      ],
      shotCount: 1,
    );
    final second = _syntheticResult(
      events: const [],
      phase: GamePhase.planning,
      entities: [_entity('crate', EntityType.crate)],
      shotCount: 2,
    );
    final crateImpact = _impact(
      id: 'crate-impact',
      pathIndex: 1,
      targetId: 'crate',
      targetType: EntityType.crate,
      impulse: 1,
    );
    final third = _syntheticResult(
      events: [
        crateImpact,
        _impact(
          id: 'hole',
          parent: crateImpact.eventId,
          pathIndex: 5,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 1,
        ),
      ],
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze([first, second, third], parShots: 3);

    expect(analysis.preparationContributions, isEmpty);
    expect(analysis.breakdown.preparationPoints, 0);
  });

  test('중간에 풀렸다가 다시 눌린 상태는 마지막 준비 샷에만 귀속한다', () {
    final pressed = _entity(
      'switch',
      EntityType.switchPad,
    ).copyWith(pressed: true, visualState: 'pressed');
    final released = _entity('switch', EntityType.switchPad);
    final first = _syntheticResult(
      events: [
        _stateChange(
          id: 'first-press',
          pathIndex: 1,
          targetId: 'switch',
          targetType: EntityType.switchPad,
          visualState: 'pressed',
        ),
      ],
      phase: GamePhase.planning,
      entities: [pressed],
      shotCount: 1,
    );
    final second = _syntheticResult(
      events: [
        _stateChange(
          id: 'release',
          pathIndex: 1,
          targetId: 'switch',
          targetType: EntityType.switchPad,
          visualState: 'released',
        ),
      ],
      phase: GamePhase.planning,
      entities: [released],
      shotCount: 2,
    );
    final third = _syntheticResult(
      events: [
        _stateChange(
          id: 'last-press',
          pathIndex: 1,
          targetId: 'switch',
          targetType: EntityType.switchPad,
          visualState: 'pressed',
        ),
      ],
      phase: GamePhase.planning,
      entities: [pressed],
      shotCount: 3,
    );
    final switchImpact = _impact(
      id: 'switch-impact',
      pathIndex: 1,
      targetId: 'switch',
      targetType: EntityType.switchPad,
      impulse: 1,
    );
    final fourth = _syntheticResult(
      events: [
        switchImpact,
        _impact(
          id: 'hole',
          parent: switchImpact.eventId,
          pathIndex: 5,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 1,
        ),
      ],
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze([
      first,
      second,
      third,
      fourth,
    ], parShots: 4);

    expect(analysis.preparationContributions, hasLength(1));
    expect(analysis.preparationContributions.single.shotIndex, 2);
  });

  test('다른 물체의 직전 사건을 활성 공의 홀 인과로 흡수하지 않는다', () {
    final result = _syntheticResult(
      events: [
        _impact(
          id: 'active-wall',
          pathIndex: 2,
          targetId: 'wall',
          targetType: EntityType.wall,
          impulse: 1,
        ),
        _impact(
          id: 'other-crate',
          pathIndex: 9,
          targetId: 'crate',
          targetType: EntityType.crate,
          impulse: 1,
          sourceEntityId: 'other_ball',
        ),
        _impact(
          id: 'hole',
          pathIndex: 10,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 1,
        ),
      ],
      phase: GamePhase.success,
    );

    final analysis = analyzer.analyze([result], parShots: 1);

    expect(analysis.causalEventIds, contains('0:active-wall'));
    expect(analysis.causalEventIds, isNot(contains('0:other-crate')));
    expect(analysis.breakdown.distinctEntityIds, 1);
  });

  test('실제 7단계 과거 공 경로도 준비 샷과 과거 공 사건을 인식한다', () {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    final pattern = catalog
        .stageById('stage_persistent')
        .patternById('stage_persistent_01');
    var state = pattern
        .toLevelDefinition(
          stageId: 'stage_persistent',
          stageTitle: '7. 공은 사라지지 않는다',
        )
        .createState(6, productRules: true);
    const resolver = ShotResolver();
    final solution = stagePersistentRepresentativeSolutions.first;
    final results = <ShotResult>[];
    final first = resolver.resolve(state, solution.firstInput);
    results.add(first);
    state = first.state;
    results.add(resolver.resolve(state, solution.secondInput));

    final analysis = analyzer.analyze(results, parShots: 3);

    expect(analysis.clearReached, isTrue);
    expect(analysis.breakdown.pastBallCount, greaterThan(0));
    expect(analysis.breakdown.preparationShotCount, 1);
    expect(analysis.totalScore, greaterThan(1000));
  });

  test('동일한 replay fixture와 결과는 점수·구성·서명이 결정론적이다', () {
    final result = _syntheticResult(
      events: _causalEvents(),
      phase: GamePhase.success,
    );
    final fixture = ReplayFixture(
      id: 'score_fixture',
      stageIndex: 0,
      routeTag: 'creative_chain',
      shots: const [],
      expectedFingerprints: [shotResultFingerprint(result)],
      expectedPhase: 'success',
    );
    final actualFixture = ReplayFixture(
      id: fixture.id,
      stageIndex: fixture.stageIndex,
      routeTag: fixture.routeTag,
      shots: const [ReplayShotFixture(angleRadians: 0, power: 0.5)],
      expectedFingerprints: fixture.expectedFingerprints,
      expectedPhase: fixture.expectedPhase,
    );

    final first = analyzer.analyzeReplay(actualFixture, [result], parShots: 2);
    final second = analyzer.analyzeReplay(actualFixture, [result], parShots: 2);

    expect(first.replayMatchesFixture, isTrue);
    expect(second.replayMatchesFixture, isTrue);
    expect(second.totalScore, first.totalScore);
    expect(second.breakdown.totalPoints, first.breakdown.totalPoints);
    expect(second.replaySignature, first.replaySignature);
  });

  test('실패 결과에는 창의 연쇄 점수를 주지 않는다', () {
    final result = _syntheticResult(
      events: [
        _impact(
          id: 'wall',
          pathIndex: 1,
          targetId: 'wall',
          targetType: EntityType.wall,
          impulse: 1,
        ),
      ],
      phase: GamePhase.planning,
    );

    final analysis = analyzer.analyze([result], parShots: 1);

    expect(analysis.clearReached, isFalse);
    expect(analysis.totalScore, 0);
    expect(analysis.breakdown.qualifiedImpactCount, 0);
  });

  test('이미 놓인 공이 홀에 들어간 성공도 홀 물리 사건과 점수를 남긴다', () {
    final state = GameState(
      levelIndex: 0,
      levelName: '기존 공 홀 진입',
      entities: [
        _entity('active_ball', EntityType.ball),
        _entity('hole', EntityType.hole, position: const Vec2(80, 0)),
        _entity('spent_ball_1', EntityType.ball, position: const Vec2(80, 0)),
      ],
      ballSpawn: Vec2.zero,
    );
    const resolver = ShotResolver();
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 0.12),
    );

    expect(result.state.phase, GamePhase.success);
    expect(result.events, contains('existing_ball_hole_entered'));
    expect(
      result.physicsEvents,
      contains(
        isA<PhysicsEvent>()
            .having((event) => event.targetType, '대상', EntityType.hole)
            .having((event) => event.sourceEntityId, '출발 기물', 'spent_ball_1'),
      ),
    );
    expect(analyzer.analyze([result], parShots: 1).clearReached, isTrue);
  });

  test('홀 사건이 있어도 상태가 클리어가 아니면 점수를 주지 않는다', () {
    final result = _syntheticResult(
      events: [
        _impact(
          id: 'hole-touch',
          pathIndex: 1,
          targetId: 'hole',
          targetType: EntityType.hole,
          impulse: 0.2,
        ),
      ],
      phase: GamePhase.planning,
    );

    final analysis = analyzer.analyze([result], parShots: 1);

    expect(analysis.clearReached, isFalse);
    expect(analysis.totalScore, 0);
  });

  test('공개 결과 컬렉션은 외부에서 변경할 수 없다', () {
    final analysis = analyzer.analyze([
      _syntheticResult(events: _causalEvents(), phase: GamePhase.success),
    ], parShots: 1);

    expect(() => analysis.causalEventIds.add('임의 사건'), throwsUnsupportedError);
    expect(
      () => analysis.completedOptionalChallengeIds.add('임의 도전'),
      throwsUnsupportedError,
    );
  });

  test('충돌 속성은 원본 집합 변경과 외부 수정에서 보호된다', () {
    final mutableTraits = <TraitType>{TraitType.heavy};
    final impact = ShotImpact(
      entityId: 'crate',
      entityType: EntityType.crate,
      position: Vec2.zero,
      normal: const Vec2(-1, 0),
      pathIndex: 1,
      strength: 1,
      sourceTraitMask: traitMaskOf(mutableTraits),
    );
    final events = buildPhysicsEvents(
      path: const [Vec2.zero, Vec2(1, 0)],
      impacts: [impact],
      moves: const [],
      chainSafetyDiagnostics: const [],
    );
    final event = events.single;

    mutableTraits.add(TraitType.bouncy);

    expect(event.sourceTraits, {TraitType.heavy});
    expect(
      () => event.sourceTraits.add(TraitType.sticky),
      throwsUnsupportedError,
    );
    expect(impact.sourceTraits, {TraitType.heavy});
  });
}

PhysicsEvent _impact({
  required String id,
  required int pathIndex,
  required String targetId,
  required EntityType targetType,
  required double impulse,
  String? parent,
  Vec2 normal = const Vec2(0, -1),
  double relativeNormalSpeed = 1,
  String sourceEntityId = 'active_ball',
  Set<TraitType> sourceTraits = const {},
}) {
  final impact = ShotImpact(
    entityId: targetId,
    entityType: targetType,
    position: Vec2.zero,
    normal: normal,
    pathIndex: pathIndex,
    strength: impulse,
    impulse: impulse,
    relativeNormalSpeed: relativeNormalSpeed,
    sourceTraitMask: traitMaskOf(sourceTraits),
  );
  return PhysicsEvent(
    eventId: id,
    parentEventId: parent,
    kind: PhysicsEventKind.impact,
    pathIndex: pathIndex,
    sourceEntityId: sourceEntityId,
    targetEntityId: targetId,
    targetType: targetType,
    position: Vec2.zero,
    normal: normal,
    impulse: impulse,
    resultingVelocity: const Vec2(1, 0),
    impact: impact,
    sourceTraitMask: traitMaskOf(sourceTraits),
  );
}

PhysicsEvent _moveEvent(String entityId, Vec2 destination) {
  final move = ShotAnimationMove(
    entityId: entityId,
    from: Vec2.zero,
    to: destination,
    triggerPathIndex: 1,
    path: [Vec2.zero, destination],
  );
  return PhysicsEvent(
    eventId: 'move:$entityId',
    kind: PhysicsEventKind.move,
    pathIndex: 1,
    sourceEntityId: 'active_ball',
    targetEntityId: entityId,
    targetType: EntityType.crate,
    position: destination,
    normal: Vec2.zero,
    impulse: 1,
    resultingVelocity: const Vec2(1, 0),
    move: move,
  );
}

List<PhysicsEvent> _causalEvents() {
  final wall1 = _impact(
    id: 'wall-1',
    pathIndex: 1,
    targetId: 'wall_a',
    targetType: EntityType.wall,
    impulse: 1,
  );
  final wall2 = _impact(
    id: 'wall-2',
    parent: wall1.eventId,
    pathIndex: 4,
    targetId: 'wall_a',
    targetType: EntityType.wall,
    impulse: 1,
  );
  final crate = _impact(
    id: 'crate',
    parent: wall2.eventId,
    pathIndex: 8,
    targetId: 'crate_a',
    targetType: EntityType.crate,
    impulse: 1,
  );
  final pastBall = _impact(
    id: 'past-ball',
    parent: crate.eventId,
    pathIndex: 12,
    targetId: 'spent_ball_1',
    targetType: EntityType.ball,
    impulse: 1,
  );
  final slider = PhysicsEvent(
    eventId: 'slider',
    parentEventId: pastBall.eventId,
    kind: PhysicsEventKind.powerSliderActivation,
    pathIndex: 16,
    sourceEntityId: 'active_ball',
    targetEntityId: 'slider_a',
    targetType: EntityType.powerSlider,
    position: Vec2.zero,
    normal: Vec2.zero,
    impulse: 2,
    resultingVelocity: const Vec2(2, 0),
  );
  final sticky = _stateChange(
    id: 'sticky',
    parent: slider.eventId,
    pathIndex: 18,
    targetId: 'spent_ball_1',
    targetType: EntityType.ball,
    visualState: 'stuck',
  );
  final sharp = _stateChange(
    id: 'sharp',
    parent: sticky.eventId,
    pathIndex: 20,
    targetId: 'active_ball',
    targetType: EntityType.ball,
    visualState: 'sharpness_consumed',
  );
  final switchEvent = _stateChange(
    id: 'switch',
    parent: sharp.eventId,
    pathIndex: 21,
    targetId: 'switch_a',
    targetType: EntityType.switchPad,
    visualState: 'pressed',
  );
  final gate = _stateChange(
    id: 'gate',
    parent: switchEvent.eventId,
    pathIndex: 23,
    targetId: 'gate_a',
    targetType: EntityType.gate,
    visualState: 'open',
  );
  final reflector = PhysicsEvent(
    eventId: 'reflector',
    parentEventId: gate.eventId,
    kind: PhysicsEventKind.reflectorRotation,
    pathIndex: 25,
    sourceEntityId: 'active_ball',
    targetEntityId: 'reflector_a',
    targetType: EntityType.rotatingReflector,
    position: Vec2.zero,
    normal: const Vec2(0, -1),
    impulse: 1,
    resultingVelocity: const Vec2(1, 0),
  );
  final movedCrate = PhysicsEvent(
    eventId: 'crate-move',
    parentEventId: crate.eventId,
    kind: PhysicsEventKind.move,
    pathIndex: 9,
    sourceEntityId: 'crate_a',
    targetEntityId: 'crate_a',
    targetType: EntityType.crate,
    position: Vec2.zero,
    normal: Vec2.zero,
    impulse: 0,
    resultingVelocity: const Vec2(1, 0),
    move: ShotAnimationMove(
      entityId: 'crate_a',
      from: Vec2.zero,
      to: const Vec2(20, 0),
      triggerPathIndex: 9,
      path: const [Vec2.zero, Vec2(20, 0)],
    ),
  );
  return [
    wall1,
    wall2,
    crate,
    pastBall,
    slider,
    sticky,
    sharp,
    switchEvent,
    gate,
    reflector,
    movedCrate,
    _impact(
      id: 'hole',
      parent: reflector.eventId,
      pathIndex: 30,
      targetId: 'hole',
      targetType: EntityType.hole,
      impulse: 1,
    ),
  ];
}

PhysicsEvent _stateChange({
  required String id,
  required int pathIndex,
  required String targetId,
  required EntityType targetType,
  required String visualState,
  String? parent,
  String sourceEntityId = 'active_ball',
}) {
  return PhysicsEvent(
    eventId: id,
    parentEventId: parent,
    kind: PhysicsEventKind.stateChange,
    pathIndex: pathIndex,
    sourceEntityId: sourceEntityId,
    targetEntityId: targetId,
    targetType: targetType,
    position: Vec2.zero,
    normal: Vec2.zero,
    impulse: 0,
    resultingVelocity: Vec2.zero,
    visualState: visualState,
  );
}

ShotResult _syntheticResult({
  required List<PhysicsEvent> events,
  required GamePhase phase,
  List<EntityState> entities = const [],
  int? shotCount,
}) {
  final state = GameState(
    levelIndex: 0,
    levelName: '점수 테스트',
    entities: [
      _entity('active_ball', EntityType.ball),
      _entity('hole', EntityType.hole),
      ...entities,
    ],
    ballSpawn: Vec2.zero,
    phase: phase,
    shotCount: shotCount ?? (phase == GamePhase.success ? 1 : 0),
  );
  return ShotResult(
    state: state,
    path: const [Vec2.zero],
    events: const [],
    physicsEvents: events,
  );
}

EntityState _entity(String id, EntityType type, {Vec2 position = Vec2.zero}) {
  return EntityState(
    id: id,
    type: type,
    position: position,
    size: const Vec2(20, 20),
    movable: type == EntityType.ball,
  );
}
