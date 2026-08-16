import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'fixtures/invalid_patterns/invalid_pattern_fixtures.dart';

void main() {
  final basePattern = StagePattern.fromLevelDefinition(
    levels.first,
    patternId: 'runtime_probe_pattern',
  );
  final stage = StageDefinition(
    stageId: 'runtime_probe_stage',
    title: '실행 검증',
    patterns: [basePattern],
  );

  test('실제 ShotResolver probe는 공개된 입력·샷 상한 안에서 실행된다', () {
    final probe = ShotResolverPatternRuntimeProbe();
    final evidence = probe.probe(stage: stage, pattern: basePattern);

    expect(evidence.probeCount, lessThanOrEqualTo(evidence.maxProbeCount));
    expect(evidence.shotCount, lessThanOrEqualTo(evidence.maxShots));
    expect(evidence.withinBudget, isTrue);
    expect(evidence.finiteCoordinates, isTrue);
    expect(evidence.finiteTime, isTrue);
    expect(evidence.negativeTime, isFalse);
    expect(evidence.nonDeterministic, isFalse);
    expect(evidence.wallMoved, isFalse);
    expect(evidence.sliderApplicable, isFalse);
    expect(evidence.rotatorApplicable, isFalse);
  });

  test('정상 레거시 1단계의 실제 probe는 런타임 오류를 만들지 않는다', () {
    final probe = ShotResolverPatternRuntimeProbe();
    final evidence = probe.probe(stage: stage, pattern: basePattern);
    final report = StagePatternValidator().validatePatternWithRuntimeEvidence(
      stage,
      basePattern,
      evidence,
      enforceProductionPolicy: false,
    );
    final runtimeCodes = <ValidationIssueCode>{
      ValidationIssueCode.runtimeAutoClear,
      ValidationIssueCode.runtimeNoRoute,
      ValidationIssueCode.runtimeWallMoved,
      ValidationIssueCode.runtimeInfiniteBounce,
      ValidationIssueCode.runtimeNonDeterministic,
      ValidationIssueCode.runtimeHolePassThrough,
      ValidationIssueCode.runtimeSoftLock,
      ValidationIssueCode.runtimeNonFinite,
      ValidationIssueCode.runtimeNegativeTime,
      ValidationIssueCode.runtimeProbeBudget,
    };
    expect(runtimeCodes.any(report.codes.contains), isFalse);
  });

  test('기존 1~4단계는 실제 벽 연결성 probe에서 오탐하지 않는다', () {
    final validator = StagePatternValidator();
    final runtimeCodes = <ValidationIssueCode>{
      ValidationIssueCode.runtimeAutoClear,
      ValidationIssueCode.runtimeNoRoute,
      ValidationIssueCode.runtimeWallMoved,
      ValidationIssueCode.runtimeInfiniteBounce,
      ValidationIssueCode.runtimeNonDeterministic,
      ValidationIssueCode.runtimeHolePassThrough,
      ValidationIssueCode.runtimeSoftLock,
      ValidationIssueCode.runtimeNonFinite,
      ValidationIssueCode.runtimeNegativeTime,
      ValidationIssueCode.runtimeProbeBudget,
    };
    for (final level in levels) {
      final pattern = StagePattern.fromLevelDefinition(
        level,
        patternId: '${level.id}_runtime_probe',
      );
      final legacyStage = StageDefinition(
        stageId: level.id,
        title: level.name,
        patterns: [pattern],
      );
      final evidence = ShotResolverPatternRuntimeProbe().probe(
        stage: legacyStage,
        pattern: pattern,
      );
      expect(evidence.finiteCoordinates, isTrue, reason: level.id);
      expect(evidence.finiteTime, isTrue, reason: level.id);
      expect(evidence.negativeTime, isFalse, reason: level.id);
      final report = validator.validatePatternWithRuntimeEvidence(
        legacyStage,
        pattern,
        evidence,
        enforceProductionPolicy: false,
      );
      expect(
        runtimeCodes.any(report.codes.contains),
        isFalse,
        reason: '${level.id}: ${report.issues}',
      );
    }
  });

  test('대표 입력 성공 없음은 definitive no-route가 아니다', () {
    final probe = ShotResolverPatternRuntimeProbe();
    final evidence = probe.probe(stage: stage, pattern: basePattern);
    expect(evidence.definitiveNoRoute, isFalse);

    final report = StagePatternValidator().validatePatternWithRuntimeEvidence(
      stage,
      basePattern,
      evidence,
      enforceProductionPolicy: false,
    );
    expect(report.hasCode(ValidationIssueCode.runtimeNoRoute), isFalse);
  });

  test('동일 패턴 probe 반복은 동일한 evidence를 만든다', () {
    final probe = ShotResolverPatternRuntimeProbe();
    final first = probe.probe(stage: stage, pattern: basePattern);
    final second = probe.probe(stage: stage, pattern: basePattern);

    expect(_evidenceFingerprint(first), equals(_evidenceFingerprint(second)));
  });

  test('scripted evidence가 신규 기물 계약을 정확한 오류 코드로 변환한다', () {
    const evidence = PatternRuntimeEvidence(
      probeCount: 2,
      maxProbeCount: 2,
      shotCount: 4,
      maxShots: 4,
      sliderApplicable: true,
      sliderTunneling: true,
      rotatorApplicable: true,
      rotatorOrderViolation: true,
    );
    final report = StagePatternValidator().validatePatternWithRuntimeEvidence(
      stage,
      basePattern,
      evidence,
      enforceProductionPolicy: false,
    );

    expect(
      report.codes,
      containsAll(<ValidationIssueCode>[
        ValidationIssueCode.runtimeSliderTunneling,
        ValidationIssueCode.runtimeRotatorOrder,
      ]),
    );
  });

  test('점착 또는 동일 접촉 중복 impact만으로는 회전 누락을 오탐하지 않는다', () {
    final pattern = StagePattern(
      patternId: 'reflector_negative',
      weight: 1,
      parShots: 3,
      difficultyBand: '중급',
      ballSpawn: const Vec2(60, 520),
      solutionFamilies: const {'반사'},
      objects: const [
        PatternObjectDefinition(
          id: 'hole',
          type: EntityType.hole,
          position: Vec2(320, 100),
          size: Vec2(36, 36),
          solid: false,
        ),
        PatternObjectDefinition(
          id: 'reflector',
          type: EntityType.rotatingReflector,
          position: Vec2(60, 280),
          size: Vec2(76, 12),
        ),
      ],
    );
    final reflectorStage = StageDefinition(
      stageId: 'reflector_negative_stage',
      title: '반사판 음성 검증',
      patterns: [pattern],
    );
    final initial = pattern
        .toLevelDefinition(
          stageId: reflectorStage.stageId,
          stageTitle: reflectorStage.title,
        )
        .createState(0);
    final impact = ShotImpact(
      entityId: 'reflector',
      entityType: EntityType.rotatingReflector,
      position: const Vec2(60, 286),
      normal: const Vec2(0, 1),
      pathIndex: 1,
      strength: 1,
    );
    final impactEvent = PhysicsEvent(
      eventId: 'impact:sticky',
      kind: PhysicsEventKind.impact,
      pathIndex: 1,
      sourceEntityId: 'active_ball',
      targetEntityId: 'reflector',
      targetType: EntityType.rotatingReflector,
      position: impact.position,
      normal: impact.normal,
      impulse: 0,
      resultingVelocity: Vec2.zero,
      impact: impact,
    );
    final duplicate = ShotResult(
      state: initial,
      path: [initial.activeBall.position, impact.position],
      events: const ['sticky_attached'],
      impacts: [impact, impact],
      physicsEvents: [impactEvent],
    );
    final evidence = _probeReflectorResult(
      stage: reflectorStage,
      pattern: pattern,
      result: duplicate,
    );
    expect(evidence.rotatorOrderViolation, isFalse);
  });

  test('비자격 impact를 부모로 둔 가짜 회전 사건을 검출한다', () {
    final pattern = StagePattern(
      patternId: 'reflector_nonqualifying_rotation',
      weight: 1,
      parShots: 3,
      difficultyBand: '중급',
      ballSpawn: const Vec2(60, 520),
      solutionFamilies: const {'반사'},
      objects: const [
        PatternObjectDefinition(
          id: 'hole',
          type: EntityType.hole,
          position: Vec2(320, 100),
          size: Vec2(36, 36),
          solid: false,
        ),
        PatternObjectDefinition(
          id: 'reflector',
          type: EntityType.rotatingReflector,
          position: Vec2(60, 280),
          size: Vec2(76, 12),
        ),
      ],
    );
    final fixtureStage = StageDefinition(
      stageId: 'reflector_nonqualifying_rotation_stage',
      title: '비자격 회전 검증',
      patterns: [pattern],
    );
    final initial = pattern
        .toLevelDefinition(
          stageId: fixtureStage.stageId,
          stageTitle: fixtureStage.title,
        )
        .createState(0);
    final changed = initial.copyWith(
      entities: [
        for (final entity in initial.entities)
          entity.id == 'reflector'
              ? entity.copyWith(
                  reflectorOrientation: 2,
                  reflectorRotationCount: 1,
                )
              : entity,
      ],
    );
    const impact = ShotImpact(
      entityId: 'reflector',
      entityType: EntityType.rotatingReflector,
      position: Vec2(60, 286),
      normal: Vec2(0, 1),
      pathIndex: 1,
      strength: 1,
      contactId: 'active_ball:reflector',
      triggersReflectorRotation: false,
    );
    const rotation = ReflectorRotation(
      sourceEntityId: 'active_ball',
      reflectorEntityId: 'reflector',
      contactId: 'active_ball:reflector',
      pathIndex: 1,
      orientationBefore: 0,
      orientationAfter: 2,
      rotationCountBefore: 0,
      rotationCountAfter: 1,
      collisionNormal: Vec2(0, 1),
      velocityBefore: Vec2(0, -8),
      velocityAfter: Vec2(0, 6),
    );
    const path = [Vec2(60, 520), Vec2(60, 286), Vec2(60, 292)];
    final result = ShotResult(
      state: changed,
      path: path,
      events: const [],
      impacts: const [impact],
      reflectorRotations: const [rotation],
      physicsEvents: buildPhysicsEvents(
        path: path,
        impacts: const [impact],
        moves: const [],
        chainSafetyDiagnostics: const [],
        reflectorRotations: const [rotation],
      ),
    );

    final evidence = _probeReflectorResult(
      stage: fixtureStage,
      pattern: pattern,
      result: result,
    );
    expect(evidence.rotatorOrderViolation, isTrue);
  });

  test('회전 횟수만 증가하고 회전 사건이 누락된 fake resolver를 검출한다', () {
    final reflector = const PatternObjectDefinition(
      id: 'reflector',
      type: EntityType.rotatingReflector,
      position: Vec2(60, 280),
      size: Vec2(76, 12),
    );
    final pattern = StagePattern(
      patternId: 'reflector_missing_rotation',
      weight: 1,
      parShots: 3,
      difficultyBand: '중급',
      ballSpawn: const Vec2(60, 520),
      solutionFamilies: const {'반사'},
      objects: [
        const PatternObjectDefinition(
          id: 'hole',
          type: EntityType.hole,
          position: Vec2(320, 100),
          size: Vec2(36, 36),
          solid: false,
        ),
        reflector,
      ],
    );
    final stage = StageDefinition(
      stageId: 'reflector_missing_rotation_stage',
      title: '반사 사건 누락 검증',
      patterns: [pattern],
    );
    final initial = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    final changed = initial.copyWith(
      entities: [
        for (final entity in initial.entities)
          entity.id == 'reflector'
              ? entity.copyWith(
                  reflectorOrientation: 2,
                  reflectorRotationCount: 1,
                )
              : entity,
      ],
    );
    final result = ShotResult(
      state: changed,
      path: [initial.activeBall.position],
      events: const [],
    );
    final evidence = _probeReflectorResult(
      stage: stage,
      pattern: pattern,
      result: result,
    );
    expect(evidence.rotatorOrderViolation, isTrue);
  });

  test(
    'qualifying reflector impact와 rotation·state가 모두 누락된 fake resolver를 검출한다',
    () {
      final pattern = StagePattern(
        patternId: 'reflector_qualifying_missing',
        weight: 1,
        parShots: 3,
        difficultyBand: '중급',
        ballSpawn: const Vec2(180, 440),
        solutionFamilies: const {'반사'},
        objects: const [
          PatternObjectDefinition(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(320, 100),
            size: Vec2(36, 36),
            solid: false,
          ),
          PatternObjectDefinition(
            id: 'reflector',
            type: EntityType.rotatingReflector,
            position: Vec2(180, 280),
            size: Vec2(76, 12),
          ),
        ],
      );
      final fixtureStage = StageDefinition(
        stageId: 'reflector_qualifying_missing_stage',
        title: '회전 자격 사건 누락',
        patterns: [pattern],
      );
      final initial = pattern
          .toLevelDefinition(
            stageId: fixtureStage.stageId,
            stageTitle: fixtureStage.title,
          )
          .createState(0);
      const impact = ShotImpact(
        entityId: 'reflector',
        entityType: EntityType.rotatingReflector,
        position: Vec2(180, 286),
        normal: Vec2(0, 1),
        pathIndex: 2,
        strength: 1,
        contactId: 'active_ball:reflector',
        triggersReflectorRotation: true,
      );
      final result = ShotResult(
        state: initial,
        path: [initial.activeBall.position, impact.position],
        events: const [],
        impacts: const [impact],
        physicsEvents: const [
          PhysicsEvent(
            eventId: 'impact:qualifying_missing',
            kind: PhysicsEventKind.impact,
            pathIndex: 2,
            sourceEntityId: 'active_ball',
            targetEntityId: 'reflector',
            targetType: EntityType.rotatingReflector,
            position: Vec2(180, 286),
            normal: Vec2(0, 1),
            impulse: 1,
            resultingVelocity: Vec2(0, 1),
            contactId: 'active_ball:reflector',
            triggersReflectorRotation: true,
            impact: impact,
          ),
        ],
      );
      final evidence = _probeReflectorResult(
        stage: fixtureStage,
        pattern: pattern,
        result: result,
      );

      expect(evidence.rotatorOrderViolation, isTrue);
    },
  );

  test('impact보다 앞선 rotation, 잘못된 parent, velocity 불일치 fake 사건을 모두 검출한다', () {
    final pattern = StagePattern(
      patternId: 'reflector_event_contract',
      weight: 1,
      parShots: 3,
      difficultyBand: '중급',
      ballSpawn: const Vec2(180, 440),
      solutionFamilies: const {'반사'},
      objects: const [
        PatternObjectDefinition(
          id: 'hole',
          type: EntityType.hole,
          position: Vec2(320, 100),
          size: Vec2(36, 36),
          solid: false,
        ),
        PatternObjectDefinition(
          id: 'reflector',
          type: EntityType.rotatingReflector,
          position: Vec2(180, 280),
          size: Vec2(76, 12),
        ),
      ],
    );
    final eventStage = StageDefinition(
      stageId: 'reflector_event_contract_stage',
      title: '반사 사건 계약',
      patterns: [pattern],
    );
    final initial = pattern
        .toLevelDefinition(
          stageId: eventStage.stageId,
          stageTitle: eventStage.title,
        )
        .createState(0);
    final valid = ShotResolver().resolve(
      initial,
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    final impact = valid.physicsEvents.firstWhere(
      (event) => event.kind == PhysicsEventKind.impact,
    );
    final rotation = valid.physicsEvents.firstWhere(
      (event) => event.kind == PhysicsEventKind.reflectorRotation,
    );
    final otherEvents = valid.physicsEvents
        .where(
          (event) =>
              event.eventId != impact.eventId &&
              event.eventId != rotation.eventId,
        )
        .toList();

    PatternRuntimeEvidence probeWith(List<PhysicsEvent> events) {
      return _probeReflectorResult(
        stage: eventStage,
        pattern: pattern,
        result: _resultWithPhysicsEvents(valid, events),
      );
    }

    expect(
      probeWith([rotation, impact, ...otherEvents]).rotatorOrderViolation,
      isTrue,
    );
    expect(
      probeWith([
        impact,
        _copyPhysicsEvent(rotation, parentEventId: 'wrong-parent'),
        ...otherEvents,
      ]).rotatorOrderViolation,
      isTrue,
    );
    expect(
      probeWith([
        impact,
        _copyPhysicsEvent(
          rotation,
          resultingVelocity: rotation.resultingVelocity + const Vec2(1, 0),
        ),
        ...otherEvents,
      ]).rotatorOrderViolation,
      isTrue,
    );
  });

  test('metadata 문자열만으로 신규 기물 오류를 만들지 않는다', () {
    final json = Map<String, dynamic>.from(basePattern.toJson());
    json['metadata'] = <String, dynamic>{
      'slider_tunneling': 'true',
      'rotator_order': 'invalid',
    };
    final metadataOnly = StagePattern.fromJson(json);
    final metadataStage = StageDefinition(
      stageId: stage.stageId,
      title: stage.title,
      patterns: [metadataOnly],
    );
    final report = StagePatternValidator().validatePatternWithRuntimeEvidence(
      metadataStage,
      metadataOnly,
      const PatternRuntimeEvidence(),
      enforceProductionPolicy: false,
    );

    expect(report.hasCode(ValidationIssueCode.runtimeSliderTunneling), isFalse);
    expect(report.hasCode(ValidationIssueCode.runtimeRotatorOrder), isFalse);
  });

  test('유한값·음수 시간 evidence도 안정 오류 코드로 변환한다', () {
    const evidence = PatternRuntimeEvidence(
      probeCount: 1,
      maxProbeCount: 1,
      shotCount: 2,
      maxShots: 2,
      finiteCoordinates: false,
      finiteTime: false,
      negativeTime: true,
    );
    final report = StagePatternValidator().validatePatternWithRuntimeEvidence(
      stage,
      basePattern,
      evidence,
      enforceProductionPolicy: false,
    );

    expect(
      report.codes,
      containsAll(<ValidationIssueCode>[
        ValidationIssueCode.runtimeNonFinite,
        ValidationIssueCode.runtimeNegativeTime,
      ]),
    );
  });

  test('완전 차단 벽 fixture는 실제 probe로만 no-route를 증명한다', () {
    final fixture = buildInvalidPatternFixtures().singleWhere(
      (candidate) => candidate.name == 'invalid_no_route',
    );
    final evidence = fixture.runtimeProbe!.probe(
      stage: fixture.stage,
      pattern: fixture.pattern,
    );
    expect(evidence.definitiveNoRoute, isTrue);
    expect(evidence.routeObserved, isFalse);
    expect(evidence.withinBudget, isTrue);
  });

  test('확장 벽 사이의 좁은 유효 통로를 no-route로 오판하지 않는다', () {
    final pattern = _narrowPassagePattern(basePattern);
    final narrowStage = StageDefinition(
      stageId: 'narrow_passage_stage',
      title: '좁은 통로',
      patterns: [pattern],
    );
    final evidence = ShotResolverPatternRuntimeProbe().probe(
      stage: narrowStage,
      pattern: pattern,
    );
    expect(evidence.definitiveNoRoute, isFalse);
  });

  test('홀 가까이에서 시작한 정상 성공을 자동 클리어로 오판하지 않는다', () {
    final pattern = _nearHolePattern(basePattern);
    final nearHoleStage = StageDefinition(
      stageId: 'near_hole_stage',
      title: '가까운 홀',
      patterns: [pattern],
    );
    final evidence = ShotResolverPatternRuntimeProbe().probe(
      stage: nearHoleStage,
      pattern: pattern,
    );
    expect(evidence.autoClearDetected, isFalse);
    expect(evidence.routeObserved, isTrue);
  });

  test('홀 포획 범위를 지나고도 진입 이벤트가 없으면 홀 통과 오류로 관찰한다', () {
    final state = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    final hole = state.entityById('hole')!;
    final result = ShotResult(
      state: state,
      path: [state.activeBall.position, hole.position, const Vec2(330, 132)],
      events: const [],
    );
    final evidence = ShotResolverPatternRuntimeProbe(
      shotResolver: _FixedShotResolver(result),
      representativeInputs: const [
        ShotInput(direction: Vec2(1, 0), power: 0.5),
      ],
      maxProbeCount: 1,
      maxShots: 2,
    ).probe(stage: stage, pattern: basePattern);

    expect(evidence.holePassThrough, isTrue);
    final report = StagePatternValidator().validatePatternWithRuntimeEvidence(
      stage,
      basePattern,
      evidence,
      enforceProductionPolicy: false,
    );
    expect(report.hasCode(ValidationIssueCode.runtimeHolePassThrough), isTrue);
  });

  test('충돌·이동·연쇄 진단의 음수 순서를 모두 오류로 관찰한다', () {
    final level = basePattern.toLevelDefinition(
      stageId: stage.stageId,
      stageTitle: stage.title,
    );
    final state = level.createState(0);
    final impact = ShotImpact(
      entityId: 'hole',
      entityType: EntityType.hole,
      position: Vec2.zero,
      normal: Vec2.zero,
      pathIndex: -1,
      strength: 1,
    );
    final move = ShotAnimationMove(
      entityId: 'crate_a',
      from: Vec2.zero,
      to: Vec2.zero,
      triggerPathIndex: -2,
    );
    final event = PhysicsEvent(
      eventId: '정상_물리_이벤트',
      kind: PhysicsEventKind.impact,
      pathIndex: 0,
      sourceEntityId: 'active_ball',
      targetEntityId: 'hole',
      targetType: EntityType.hole,
      position: Vec2.zero,
      normal: Vec2.zero,
      impulse: 0,
      resultingVelocity: Vec2.zero,
      iterations: 0,
    );
    final result = ShotResult(
      state: state,
      path: [state.activeBall.position],
      events: const [],
      impacts: [impact],
      moves: [move],
      physicsEvents: [event],
      chainSafetyDiagnostics: [
        const ChainSafetyDiagnostic(
          targetEntityId: 'active_ball',
          pathIndex: -3,
          depth: -4,
          iterations: -5,
          remainingDistance: 1,
          remainingSpeed: 1,
        ),
      ],
    );
    final evidence = ShotResolverPatternRuntimeProbe(
      shotResolver: _FixedShotResolver(result),
      representativeInputs: const [
        ShotInput(direction: Vec2(1, 0), power: 0.5),
      ],
      maxProbeCount: 1,
      maxShots: 2,
    ).probe(stage: stage, pattern: basePattern);

    expect(evidence.negativeTime, isTrue);
  });

  test('대표 입력 전체 무이동은 launchUnavailable 증명이 아니다', () {
    final state = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    final result = ShotResult(
      state: state,
      path: [state.activeBall.position],
      events: const [],
    );
    final evidence = ShotResolverPatternRuntimeProbe(
      shotResolver: _FixedShotResolver(result),
      representativeInputs: const [
        ShotInput(direction: Vec2(1, 0), power: 0.5),
      ],
      maxProbeCount: 1,
      maxShots: 2,
    ).probe(stage: stage, pattern: basePattern);

    expect(evidence.allRepresentativeInputsNoMovement, isTrue);
    expect(evidence.launchUnavailable, isFalse);
  });

  test('생산 발사 가능성 계약은 계획 상태의 활성 이동 공만 허용한다', () {
    const resolver = ShotResolver();
    final state = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);

    expect(resolver.canLaunch(state), isTrue);
    expect(
      resolver.canLaunch(state.copyWith(phase: GamePhase.paused)),
      isFalse,
    );
    expect(
      resolver.canLaunch(
        state.copyWith(
          entities: [
            for (final entity in state.entities)
              if (entity.id == 'active_ball')
                entity.copyWith(active: false)
              else
                entity,
          ],
        ),
      ),
      isFalse,
    );
  });

  test('발사 불가 resolver 변이는 실제 probe에서 soft lock을 만든다', () {
    final evidence = ShotResolverPatternRuntimeProbe(
      shotResolver: const _AlwaysLaunchUnavailableResolver(),
      representativeInputs: const [
        ShotInput(direction: Vec2(1, 0), power: 0.5),
      ],
      maxProbeCount: 1,
      maxShots: 2,
    ).probe(stage: stage, pattern: basePattern);

    expect(evidence.launchUnavailable, isTrue);
  });

  test('GameState 전체 필드와 중첩 이벤트 차이는 비결정성으로 관찰된다', () {
    final baseState = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    final baseImpact = const ShotImpact(
      entityId: 'crate_a',
      entityType: EntityType.crate,
      position: Vec2(100, 100),
      normal: Vec2(1, 0),
      pathIndex: 1,
      strength: 1,
    );
    final baseMove = const ShotAnimationMove(
      entityId: 'crate_a',
      from: Vec2(100, 100),
      to: Vec2(110, 100),
      triggerPathIndex: 1,
    );
    final baseEvent = PhysicsEvent(
      eventId: '중첩_이벤트',
      kind: PhysicsEventKind.impact,
      pathIndex: 1,
      sourceEntityId: 'active_ball',
      targetEntityId: 'crate_a',
      targetType: EntityType.crate,
      position: const Vec2(100, 100),
      normal: const Vec2(1, 0),
      impulse: 1,
      resultingVelocity: const Vec2(1, 0),
      impact: baseImpact,
      move: baseMove,
    );
    final baseResult = ShotResult(
      state: baseState,
      path: [baseState.activeBall.position, const Vec2(60, 456)],
      events: const ['충돌'],
      impacts: [baseImpact],
      moves: [baseMove],
      physicsEvents: [baseEvent],
    );

    final stateVariants = <String, GameState>{
      'levelIndex': _copyState(baseState, levelIndex: baseState.levelIndex + 1),
      'levelName': _copyState(baseState, levelName: '다른 단계'),
      'ballSpawn': _copyState(baseState, ballSpawn: const Vec2(57, 456)),
      'phase': _copyState(baseState, phase: GamePhase.resolving),
      'shotCount': _copyState(baseState, shotCount: 1),
      'score': _copyState(baseState, score: 999),
      'selectedSourceId': _copyState(baseState, selectedSourceId: 'anvil'),
      'selectedTrait': _copyState(baseState, selectedTrait: TraitType.heavy),
      'equippedTrait': _copyState(baseState, equippedTrait: TraitType.bouncy),
      'aimDirection': _copyState(baseState, aimDirection: const Vec2(0, 1)),
      'aimPower': _copyState(baseState, aimPower: 0.9),
      'copyCharges': _copyState(baseState, copyCharges: 1),
      'copyChargeLimit': _copyState(baseState, copyChargeLimit: 1),
      'copyCoreCount': _copyState(baseState, copyCoreCount: 1),
      'copyCoreRewarded': _copyState(baseState, copyCoreRewarded: true),
      'message': _copyState(baseState, message: '다른 메시지'),
      'history': _copyState(
        baseState,
        history: [baseState.copyWith(message: '이전 상태')],
      ),
    };

    for (final entry in stateVariants.entries) {
      final evidence = _probeAlternating(
        stage,
        basePattern,
        baseResult,
        _resultWithState(baseResult, entry.value),
      );
      expect(
        evidence.nonDeterministic,
        isTrue,
        reason: '${entry.key} 필드가 지문에 포함되어야 합니다.',
      );
    }

    final nestedImpact = const ShotImpact(
      entityId: 'crate_a',
      entityType: EntityType.crate,
      position: Vec2(100, 100),
      normal: Vec2(1, 0),
      pathIndex: 1,
      strength: 2,
    );
    final nestedMove = const ShotAnimationMove(
      entityId: 'crate_a',
      from: Vec2(100, 100),
      to: Vec2(120, 100),
      triggerPathIndex: 1,
    );
    final nestedEvent = PhysicsEvent(
      eventId: '중첩_이벤트',
      kind: PhysicsEventKind.impact,
      pathIndex: 1,
      sourceEntityId: 'active_ball',
      targetEntityId: 'crate_a',
      targetType: EntityType.crate,
      position: const Vec2(100, 100),
      normal: const Vec2(1, 0),
      impulse: 1,
      resultingVelocity: const Vec2(1, 0),
      impact: nestedImpact,
      move: nestedMove,
    );
    final nestedResult = ShotResult(
      state: baseState,
      path: baseResult.path,
      events: baseResult.events,
      impacts: baseResult.impacts,
      moves: baseResult.moves,
      physicsEvents: [nestedEvent],
    );
    expect(
      _probeAlternating(
        stage,
        basePattern,
        baseResult,
        nestedResult,
      ).nonDeterministic,
      isTrue,
    );
  });

  test('1e-7 차이도 결정론 위반으로 관찰한다', () {
    final baseState = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    final baseResult = ShotResult(
      state: baseState,
      path: [baseState.activeBall.position],
      events: const [],
    );
    final changedState = _copyState(
      baseState,
      aimPower: baseState.aimPower + 0.0000001,
    );
    expect(
      _probeAlternating(
        stage,
        basePattern,
        baseResult,
        _resultWithState(baseResult, changedState),
      ).nonDeterministic,
      isTrue,
    );
  });

  test('공유 인스턴스와 값이 같은 복사 인스턴스는 비결정성으로 보지 않는다', () {
    final baseState = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    const impact = ShotImpact(
      entityId: 'crate_a',
      entityType: EntityType.crate,
      position: Vec2(100, 100),
      normal: Vec2(1, 0),
      pathIndex: 1,
      strength: 1,
    );
    const move = ShotAnimationMove(
      entityId: 'crate_a',
      from: Vec2(100, 100),
      to: Vec2(110, 100),
      triggerPathIndex: 1,
    );
    PhysicsEvent eventWith(
      ShotImpact nestedImpact,
      ShotAnimationMove nestedMove,
    ) {
      return PhysicsEvent(
        eventId: '값_동일_이벤트',
        kind: PhysicsEventKind.impact,
        pathIndex: 1,
        sourceEntityId: 'active_ball',
        targetEntityId: 'crate_a',
        targetType: EntityType.crate,
        position: const Vec2(100, 100),
        normal: const Vec2(1, 0),
        impulse: 1,
        resultingVelocity: const Vec2(1, 0),
        impact: nestedImpact,
        move: nestedMove,
      );
    }

    final shared = ShotResult(
      state: baseState,
      path: [baseState.activeBall.position],
      events: const [],
      impacts: const [impact],
      moves: const [move],
      physicsEvents: [eventWith(impact, move)],
    );
    final copied = ShotResult(
      state: baseState,
      path: shared.path,
      events: shared.events,
      impacts: shared.impacts,
      moves: shared.moves,
      physicsEvents: [
        eventWith(
          const ShotImpact(
            entityId: 'crate_a',
            entityType: EntityType.crate,
            position: Vec2(100, 100),
            normal: Vec2(1, 0),
            pathIndex: 1,
            strength: 1,
          ),
          const ShotAnimationMove(
            entityId: 'crate_a',
            from: Vec2(100, 100),
            to: Vec2(110, 100),
            triggerPathIndex: 1,
          ),
        ),
      ],
    );

    expect(
      _probeAlternating(stage, basePattern, shared, copied).nonDeterministic,
      isFalse,
    );
  });

  test('history 내부 엔티티 수치도 finite 검사에 포함한다', () {
    final baseState = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    final anvil = baseState.entityById('anvil')!;
    final invalidHistory = baseState.copyWith(
      entities: _replaceEntity(
        baseState,
        anvil.copyWith(size: const Vec2(double.nan, 38)),
      ),
    );
    final stateWithHistory = baseState.copyWith(history: [invalidHistory]);
    final result = ShotResult(
      state: stateWithHistory,
      path: [stateWithHistory.activeBall.position],
      events: const [],
    );
    final evidence = ShotResolverPatternRuntimeProbe(
      shotResolver: _FixedShotResolver(result),
      representativeInputs: const [
        ShotInput(direction: Vec2(1, 0), power: 0.5),
      ],
      maxProbeCount: 1,
      maxShots: 2,
    ).probe(stage: stage, pattern: basePattern);

    expect(evidence.finiteCoordinates, isFalse);
  });

  test('벽의 물리 불변 필드 변화는 감지하고 visualState만의 변화는 무시한다', () {
    final baseState = basePattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    final baseResult = ShotResult(
      state: baseState,
      path: [baseState.activeBall.position],
      events: const [],
    );
    final wall = baseState.entityById('wall_left')!;
    final changedWall = wall.copyWith(
      type: EntityType.crate,
      size: const Vec2(30, 530),
      traits: const {TraitType.heavy},
      movable: true,
      solid: false,
      active: false,
      open: true,
      pressed: true,
      hitboxScale: 0.5,
      restitution: 0.1,
    );
    final changedState = baseState.copyWith(
      entities: _replaceEntity(baseState, changedWall),
    );
    final changedEvidence = _probeAlternating(
      stage,
      basePattern,
      baseResult,
      _resultWithState(baseResult, changedState),
    );
    expect(changedEvidence.wallMoved, isTrue);

    final subtlyMoved = wall.copyWith(
      position: Vec2(wall.position.x + 0.0001, wall.position.y),
    );
    final subtleEvidence = _probeAlternating(
      stage,
      basePattern,
      baseResult,
      _resultWithState(
        baseResult,
        baseState.copyWith(entities: _replaceEntity(baseState, subtlyMoved)),
      ),
    );
    expect(subtleEvidence.wallMoved, isTrue);

    final sameIdNewWall = baseState
        .entityById('anvil')!
        .copyWith(type: EntityType.wall);
    final newWallEvidence = _probeAlternating(
      stage,
      basePattern,
      baseResult,
      _resultWithState(
        baseResult,
        baseState.copyWith(entities: _replaceEntity(baseState, sameIdNewWall)),
      ),
    );
    expect(newWallEvidence.wallMoved, isTrue);

    final visualOnly = wall.copyWith(visualState: '충돌_표시');
    final visualEvidence = _probeAlternating(
      stage,
      basePattern,
      baseResult,
      _resultWithState(
        baseResult,
        baseState.copyWith(entities: _replaceEntity(baseState, visualOnly)),
      ),
    );
    expect(visualEvidence.wallMoved, isFalse);
  });
}

class _FixedShotResolver extends ShotResolver {
  _FixedShotResolver(this.result);

  final ShotResult result;

  @override
  ShotResult resolve(GameState state, ShotInput rawInput) => result;
}

PatternRuntimeEvidence _probeReflectorResult({
  required StageDefinition stage,
  required StagePattern pattern,
  required ShotResult result,
}) {
  return ShotResolverPatternRuntimeProbe(
    shotResolver: _FixedShotResolver(result),
    representativeInputs: const [ShotInput(direction: Vec2(0, -1), power: 0.5)],
    maxProbeCount: 1,
    maxShots: 2,
  ).probe(stage: stage, pattern: pattern);
}

class _AlternatingShotResolver extends ShotResolver {
  _AlternatingShotResolver(this.first, this.second);

  final ShotResult first;
  final ShotResult second;
  var callCount = 0;

  @override
  ShotResult resolve(GameState state, ShotInput rawInput) {
    final result = callCount.isEven ? first : second;
    callCount++;
    return result;
  }
}

class _AlwaysLaunchUnavailableResolver extends ShotResolver {
  const _AlwaysLaunchUnavailableResolver();

  @override
  bool canLaunch(GameState state) => false;
}

PatternRuntimeEvidence _probeAlternating(
  StageDefinition stage,
  StagePattern pattern,
  ShotResult first,
  ShotResult second,
) {
  return ShotResolverPatternRuntimeProbe(
    shotResolver: _AlternatingShotResolver(first, second),
    representativeInputs: const [ShotInput(direction: Vec2(1, 0), power: 0.5)],
    maxProbeCount: 1,
    maxShots: 2,
  ).probe(stage: stage, pattern: pattern);
}

GameState _copyState(
  GameState state, {
  int? levelIndex,
  String? levelName,
  Vec2? ballSpawn,
  GamePhase? phase,
  int? shotCount,
  int? score,
  String? selectedSourceId,
  TraitType? selectedTrait,
  TraitType? equippedTrait,
  Vec2? aimDirection,
  double? aimPower,
  int? copyCharges,
  int? copyChargeLimit,
  int? copyCoreCount,
  bool? copyCoreRewarded,
  String? message,
  List<GameState>? history,
}) {
  return GameState(
    levelIndex: levelIndex ?? state.levelIndex,
    levelName: levelName ?? state.levelName,
    entities: state.entities,
    ballSpawn: ballSpawn ?? state.ballSpawn,
    phase: phase ?? state.phase,
    shotCount: shotCount ?? state.shotCount,
    score: score ?? state.score,
    selectedSourceId: selectedSourceId ?? state.selectedSourceId,
    selectedTrait: selectedTrait ?? state.selectedTrait,
    equippedTrait: equippedTrait ?? state.equippedTrait,
    aimDirection: aimDirection ?? state.aimDirection,
    aimPower: aimPower ?? state.aimPower,
    copyCharges: copyCharges ?? state.copyCharges,
    copyChargeLimit: copyChargeLimit ?? state.copyChargeLimit,
    copyCoreCount: copyCoreCount ?? state.copyCoreCount,
    copyCoreRewarded: copyCoreRewarded ?? state.copyCoreRewarded,
    message: message ?? state.message,
    history: history ?? state.history,
  );
}

List<EntityState> _replaceEntity(GameState state, EntityState replacement) {
  return state.entities
      .map((entity) => entity.id == replacement.id ? replacement : entity)
      .toList();
}

ShotResult _resultWithState(ShotResult result, GameState state) {
  return ShotResult(
    state: state,
    path: result.path,
    events: result.events,
    moves: result.moves,
    impacts: result.impacts,
    physicsEvents: result.physicsEvents,
    chainSafetyDiagnostics: result.chainSafetyDiagnostics,
  );
}

ShotResult _resultWithPhysicsEvents(
  ShotResult result,
  List<PhysicsEvent> physicsEvents,
) {
  return ShotResult(
    state: result.state,
    path: result.path,
    events: result.events,
    moves: result.moves,
    impacts: result.impacts,
    powerSliderActivations: result.powerSliderActivations,
    reflectorRotations: result.reflectorRotations,
    physicsEvents: physicsEvents,
    chainSafetyDiagnostics: result.chainSafetyDiagnostics,
  );
}

PhysicsEvent _copyPhysicsEvent(
  PhysicsEvent event, {
  String? parentEventId,
  Vec2? resultingVelocity,
}) {
  return PhysicsEvent(
    eventId: event.eventId,
    parentEventId: parentEventId ?? event.parentEventId,
    kind: event.kind,
    pathIndex: event.pathIndex,
    sourceEntityId: event.sourceEntityId,
    targetEntityId: event.targetEntityId,
    targetType: event.targetType,
    position: event.position,
    normal: event.normal,
    impulse: event.impulse,
    resultingVelocity: resultingVelocity ?? event.resultingVelocity,
    visualState: event.visualState,
    remainingDistance: event.remainingDistance,
    remainingSpeed: event.remainingSpeed,
    iterations: event.iterations,
    impact: event.impact,
    move: event.move,
    contactId: event.contactId,
    powerSlider: event.powerSlider,
    reflectorRotation: event.reflectorRotation,
  );
}

StagePattern _narrowPassagePattern(StagePattern source) {
  final json = jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>;
  final objects = (json['objects'] as List).cast<Map<String, dynamic>>();
  final hole = Map<String, dynamic>.from(
    objects.firstWhere((object) => object['id'] == 'hole'),
  );
  final left =
      Map<String, dynamic>.from(
          objects.firstWhere((object) => object['id'] == 'wall_top'),
        )
        ..['id'] = 'narrow_left'
        ..['position'] = const {'x': 84.0, 'y': 300.0}
        ..['size'] = const {'x': 166.0, 'y': 24.0}
        ..['hitboxScale'] = 1.0;
  final right = Map<String, dynamic>.from(left)
    ..['id'] = 'narrow_right'
    ..['position'] = const {'x': 276.0, 'y': 300.0};
  json['objects'] = [hole, left, right];
  json['patternId'] = 'narrow_passage';
  return StagePattern.fromJson(json);
}

StagePattern _nearHolePattern(StagePattern source) {
  final json = jsonDecode(jsonEncode(source.toJson())) as Map<String, dynamic>;
  final objects = (json['objects'] as List).cast<Map<String, dynamic>>();
  final hole = Map<String, dynamic>.from(
    objects.firstWhere((object) => object['id'] == 'hole'),
  );
  json['objects'] = [hole];
  // Keep the fixture close enough to exercise the near-hole path while
  // remaining outside the enlarged tutorial hole's capture radius.
  json['ballSpawn'] = const {'x': 250.0, 'y': 132.0};
  json['patternId'] = 'near_hole';
  return StagePattern.fromJson(json);
}

String _evidenceFingerprint(PatternRuntimeEvidence evidence) {
  return [
    evidence.probeCount,
    evidence.maxProbeCount,
    evidence.shotCount,
    evidence.maxShots,
    evidence.routeObserved,
    evidence.definitiveNoRoute,
    evidence.observedSolutionFamilies.toList()..sort(),
    evidence.rewardFreeRouteObserved,
    evidence.solutionContractRequired,
    evidence.safetyStop,
    evidence.infiniteBounce,
    evidence.finiteCoordinates,
    evidence.finiteTime,
    evidence.negativeTime,
    evidence.wallMoved,
    evidence.holePassThrough,
    evidence.nonDeterministic,
    evidence.sliderApplicable,
    evidence.sliderTunneling,
    evidence.rotatorApplicable,
    evidence.rotatorOrderViolation,
    evidence.allRepresentativeInputsNoMovement,
    evidence.launchUnavailable,
    evidence.autoClearDetected,
  ].toString();
}
