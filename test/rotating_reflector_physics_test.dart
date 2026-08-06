import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/run/run_state.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

void main() {
  const resolver = ShotResolver();

  test('회전 반사판 JSON은 방향·회전 횟수를 왕복 보존하고 레거시는 그대로 둔다', () {
    const reflector = PatternObjectDefinition(
      id: 'reflector',
      type: EntityType.rotatingReflector,
      position: Vec2(180, 280),
      size: Vec2(76, 12),
      movable: false,
      solid: true,
      active: true,
      reflectorOrientation: 7,
      reflectorRotationCount: 4,
    );
    final decoded = PatternObjectDefinition.fromJson(reflector.toJson());
    expect(decoded.type, EntityType.rotatingReflector);
    expect(decoded.reflectorOrientation, 7);
    expect(decoded.reflectorRotationCount, 4);
    expect(reflector.toJson()['type'], 'rotating_reflector');

    final legacy = const PatternObjectDefinition(
      id: 'crate',
      type: EntityType.crate,
      position: Vec2(100, 100),
      size: Vec2(30, 30),
    ).toJson();
    expect(legacy.containsKey('reflectorOrientation'), isFalse);
    expect(legacy.containsKey('reflectorRotationCount'), isFalse);
  });

  test('validator는 회전판의 8방향·음수 횟수·고정 고체 정책을 독립 검사한다', () {
    final invalid = _patternWithReflector(
      reflector: const PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(180, 280),
        size: Vec2(76, 12),
        movable: true,
        solid: false,
        active: false,
        reflectorOrientation: 8,
        reflectorRotationCount: -1,
      ),
    );
    final report = StagePatternValidator().validatePattern(
      invalid,
      invalid.patterns.single,
      enforceProductionPolicy: false,
    );
    expect(
      report.codes,
      containsAll(<ValidationIssueCode>[
        ValidationIssueCode.invalidReflectorOrientation,
        ValidationIssueCode.invalidReflectorRotationCount,
        ValidationIssueCode.reflectorMustBeStatic,
        ValidationIssueCode.reflectorMustBeSolid,
      ]),
    );
  });

  test('validator는 회전판 OBB 모서리의 보드 경계와 초기 겹침을 판정한다', () {
    final valid = _patternWithReflector(
      reflector: const PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(35, 35),
        size: Vec2(76, 12),
        reflectorOrientation: 1,
      ),
    );
    final validReport = StagePatternValidator().validatePattern(
      valid,
      valid.patterns.single,
      enforceProductionPolicy: false,
    );
    expect(validReport.hasCode(ValidationIssueCode.objectOutOfBounds), isFalse);

    final outOfBounds = _patternWithReflector(
      reflector: const PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(25, 35),
        size: Vec2(76, 12),
        reflectorOrientation: 1,
      ),
    );
    final outReport = StagePatternValidator().validatePattern(
      outOfBounds,
      outOfBounds.patterns.single,
      enforceProductionPolicy: false,
    );
    expect(outReport.hasCode(ValidationIssueCode.objectOutOfBounds), isTrue);

    final overlap = _patternWithReflector(
      reflector: const PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(180, 280),
        size: Vec2(76, 12),
        reflectorOrientation: 1,
      ),
    );
    final withDiagonalBall = StagePattern(
      patternId: overlap.patterns.single.patternId,
      weight: overlap.patterns.single.weight,
      parShots: overlap.patterns.single.parShots,
      difficultyBand: overlap.patterns.single.difficultyBand,
      ballSpawn: overlap.patterns.single.ballSpawn,
      solutionFamilies: overlap.patterns.single.solutionFamilies,
      objects: [
        ...overlap.patterns.single.objects,
        const PatternObjectDefinition(
          id: 'diagonal_ball',
          type: EntityType.ball,
          position: Vec2(210, 310),
          size: Vec2(24, 24),
          movable: true,
        ),
      ],
    );
    final overlapStage = StageDefinition(
      stageId: 'reflector_obb_overlap',
      title: '반사판 OBB 겹침 시험',
      patterns: [withDiagonalBall],
    );
    final overlapReport = StagePatternValidator().validatePattern(
      overlapStage,
      withDiagonalBall,
      enforceProductionPolicy: false,
    );
    expect(
      overlapReport.hasCode(ValidationIssueCode.initialObjectOverlap),
      isTrue,
    );
    expect(overlapReport.count(ValidationIssueCode.initialObjectOverlap), 1);
  });

  test('validator는 회전 후 도달 가능한 네 방향의 보드 경계와 고체 겹침을 판정한다', () {
    StagePattern patternWithObjects(List<PatternObjectDefinition> objects) {
      return StagePattern(
        patternId: 'reflector_future_direction',
        weight: 1,
        parShots: 3,
        difficultyBand: '중급',
        ballSpawn: const Vec2(60, 520),
        solutionFamilies: const {'반사'},
        objects: objects,
      );
    }

    final futureBoundary = patternWithObjects(const [
      PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(180, 30),
        size: Vec2(76, 12),
      ),
    ]);
    final boundaryStage = StageDefinition(
      stageId: 'reflector_future_boundary',
      title: '회전판 미래 경계',
      patterns: [futureBoundary],
    );
    final boundaryReport = StagePatternValidator().validatePattern(
      boundaryStage,
      futureBoundary,
      enforceProductionPolicy: false,
    );
    expect(
      boundaryReport.hasCode(ValidationIssueCode.objectOutOfBounds),
      isTrue,
    );

    final futureOverlap = patternWithObjects(const [
      PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(180, 280),
        size: Vec2(76, 12),
      ),
      PatternObjectDefinition(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(180, 312),
        size: Vec2(18, 18),
      ),
    ]);
    final overlapStage = StageDefinition(
      stageId: 'reflector_future_overlap',
      title: '회전판 미래 겹침',
      patterns: [futureOverlap],
    );
    final overlapReport = StagePatternValidator().validatePattern(
      overlapStage,
      futureOverlap,
      enforceProductionPolicy: false,
    );
    expect(
      overlapReport.hasCode(ValidationIssueCode.initialObjectOverlap),
      isTrue,
    );

    final safe = patternWithObjects(const [
      PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(180, 280),
        size: Vec2(76, 12),
      ),
      PatternObjectDefinition(
        id: 'wall',
        type: EntityType.wall,
        position: Vec2(80, 80),
        size: Vec2(18, 18),
      ),
    ]);
    final safeStage = StageDefinition(
      stageId: 'reflector_future_safe',
      title: '회전판 미래 안전',
      patterns: [safe],
    );
    final safeReport = StagePatternValidator().validatePattern(
      safeStage,
      safe,
      enforceProductionPolicy: false,
    );
    expect(safeReport.hasCode(ValidationIssueCode.objectOutOfBounds), isFalse);
    expect(
      safeReport.hasCode(ValidationIssueCode.initialObjectOverlap),
      isFalse,
    );

    final movableFutureOverlap = patternWithObjects(const [
      PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(180, 280),
        size: Vec2(76, 12),
      ),
      PatternObjectDefinition(
        id: 'crate',
        type: EntityType.crate,
        position: Vec2(180, 312),
        size: Vec2(18, 18),
        movable: true,
        solid: true,
        active: true,
      ),
    ]);
    final movableStage = StageDefinition(
      stageId: 'reflector_future_movable',
      title: '회전판 미래 이동 기물',
      patterns: [movableFutureOverlap],
    );
    final movableReport = StagePatternValidator().validatePattern(
      movableStage,
      movableFutureOverlap,
      enforceProductionPolicy: false,
    );
    expect(
      movableReport.hasCode(ValidationIssueCode.initialObjectOverlap),
      isFalse,
    );
  });

  test('한 충돌은 이전 방향으로 반사한 뒤 정확히 한 번만 90도 회전한다', () {
    final result = resolver.resolve(
      _physicsState(reflectorOrientation: 0),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );

    expect(result.reflectorRotations, hasLength(1));
    final rotation = result.reflectorRotations.single;
    final impact = result.impacts.firstWhere(
      (candidate) =>
          candidate.entityId == 'reflector' &&
          candidate.pathIndex == rotation.pathIndex,
    );
    expect(rotation.orientationBefore, 0);
    expect(rotation.orientationAfter, 2);
    expect(rotation.rotationCountBefore, 0);
    expect(rotation.rotationCountAfter, 1);
    expect(rotation.pathIndex, impact.pathIndex);
    expect(rotation.collisionNormal, impact.normal);
    expect(
      rotation.velocityBefore.dot(rotation.collisionNormal),
      lessThanOrEqualTo(0.001),
    );
    expect(
      result.physicsEvents.where(
        (event) => event.kind == PhysicsEventKind.reflectorRotation,
      ),
      hasLength(1),
    );
    expect(
      rotation.velocityAfter,
      result.physicsEvents
          .firstWhere(
            (event) => event.kind == PhysicsEventKind.reflectorRotation,
          )
          .resultingVelocity,
    );
    expect(result.state.entityById('reflector')!.reflectorOrientation, 2);
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 1);
  });

  test('시작 OBB 겹침에서 공이 outward로 빠지면 같은 MTV로만 빠져나온다', () {
    final result = resolver.resolve(
      _physicsState(ballPosition: const Vec2(180, 280)),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    final impact = result.impacts.firstWhere(
      (candidate) => candidate.entityId == 'reflector',
    );
    expect(impact.contactId, 'active_ball:reflector');
    expect(impact.triggersReflectorRotation, isFalse);
    expect(
      result.reflectorRotations.where(
        (rotation) => rotation.pathIndex <= impact.pathIndex,
      ),
      isEmpty,
    );
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 1);
    expect(result.chainSafetyDiagnostics, isEmpty);
  });

  test('시작 OBB 겹침에서 공이 inward로 들어가면 같은 MTV 법선으로 반사·회전한다', () {
    final result = resolver.resolve(
      _physicsState(ballPosition: const Vec2(180, 280)),
      const ShotInput(direction: Vec2(0, 1), power: 1),
    );
    final impact = result.impacts.firstWhere(
      (candidate) => candidate.entityId == 'reflector',
    );
    final rotation = result.reflectorRotations.single;

    expect(impact.triggersReflectorRotation, isTrue);
    expect(impact.contactId, rotation.contactId);
    expect(impact.normal, rotation.collisionNormal);
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 1);
  });

  test('같은 contact는 정확히 1회 회전하고 완전 이탈 후 재진입은 정확히 2회다', () {
    final result = resolver.resolve(
      _physicsState(
        ballPosition: const Vec2(100, 280),
        reflectorPosition: const Vec2(220, 280),
        extra: const [
          EntityState(
            id: 'return_wall',
            type: EntityType.wall,
            position: Vec2(60, 280),
            size: Vec2(18, 560),
            movable: false,
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );

    expect(
      result.reflectorRotations.where(
        (rotation) => rotation.reflectorEntityId == 'reflector',
      ),
      hasLength(2),
    );
    expect(
      result.reflectorRotations.map((rotation) => rotation.pathIndex).toSet(),
      hasLength(2),
    );
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 2);
  });

  test('회전 직후 새 OBB와 접촉이 남아도 같은 접촉은 중복 회전하지 않는다', () {
    final result = resolver.resolve(
      _physicsState(reflectorOrientation: 0),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    final rotation = result.reflectorRotations.single;
    final postImpactPosition = result.path[rotation.pathIndex];
    final postImpactBall = result.state.activeBall.copyWith(
      position: postImpactPosition,
    );

    expect(
      _overlapsReflectorAabb(
        result.state.entityById('reflector')!,
        postImpactBall,
      ),
      isTrue,
    );
    expect(
      result.reflectorRotations.where(
        (candidate) => candidate.contactId == rotation.contactId,
      ),
      hasLength(1),
    );
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 1);
  });

  test('8개 방향의 OBB 충돌 법선은 입사 속도와 반대인 실제 접촉면을 사용한다', () {
    for (var orientation = 0; orientation < 8; orientation++) {
      final normal = _reflectorNormal(orientation);
      final state = _physicsState(
        reflectorOrientation: orientation,
        ballPosition: const Vec2(180, 280) - normal * 150,
      );
      final result = resolver.resolve(
        state,
        ShotInput(direction: normal, power: 1),
      );
      final rotation = result.reflectorRotations.single;
      expect(rotation.orientationBefore, orientation);
      expect(rotation.orientationAfter, (orientation + 2) % 8);
      expect(
        rotation.velocityBefore.dot(rotation.collisionNormal),
        lessThanOrEqualTo(0.001),
      );
      expect(rotation.collisionNormal.length, closeTo(1, 0.001));
    }
  });

  test('8개 방향은 각각 기대한 반사 단위 벡터를 만든다', () {
    for (var orientation = 0; orientation < 8; orientation++) {
      final normal = _reflectorNormal(orientation);
      final result = resolver.resolve(
        _physicsState(
          reflectorOrientation: orientation,
          ballPosition: const Vec2(180, 280) - normal * 150,
        ),
        ShotInput(direction: normal, power: 1),
      );
      final rotation = result.reflectorRotations.single;
      final expected = -normal;
      final actual = rotation.velocityAfter.normalized();
      expect(
        actual.x,
        closeTo(expected.x, 0.02),
        reason: 'orientation=$orientation',
      );
      expect(
        actual.y,
        closeTo(expected.y, 0.02),
        reason: 'orientation=$orientation',
      );
    }
  });

  test('다음 resolve는 첫 결과에 저장된 새 방향을 사용한다', () {
    final first = resolver.resolve(
      _physicsState(reflectorOrientation: 0),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    final firstReflector = first.state.entityById('reflector')!;
    final secondState = first.state.copyWith(
      entities: [
        first.state.activeBall.copyWith(position: const Vec2(180, 440)),
        firstReflector.copyWith(position: const Vec2(180, 280)),
      ],
    );
    final second = resolver.resolve(
      secondState,
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    expect(second.reflectorRotations, isNotEmpty);
    expect(second.reflectorRotations.first.orientationBefore, 2);
    expect(second.reflectorRotations.first.rotationCountBefore, 1);
  });

  test('끝 모서리를 스치는 공은 접촉 접선을 유지한 채 대각 법선으로 반사된다', () {
    final result = resolver.resolve(
      _physicsState(ballPosition: const Vec2(230, 370)),
      const ShotInput(direction: Vec2(-0.18, -1), power: 1),
    );
    final rotation = result.reflectorRotations.first;
    final impact = result.impacts.firstWhere(
      (candidate) =>
          candidate.entityId == 'reflector' &&
          candidate.pathIndex == rotation.pathIndex,
    );
    expect(impact.position.x, greaterThan(210));
    expect(impact.normal.x.abs(), greaterThan(0.05));
    expect(
      rotation.velocityBefore.dot(rotation.collisionNormal),
      lessThanOrEqualTo(0.001),
    );

    final separation = result.path[rotation.pathIndex];
    expect(separation.x, greaterThan(205));
    expect(separation.distanceTo(impact.position), lessThan(24));
  });

  test('고속 접선 스침과 최소 두께 반사판도 연속 swept로 놓치지 않는다', () {
    final state = _physicsState(
      ballPosition: const Vec2(40, 291.3),
      reflectorPosition: const Vec2(180, 280),
      reflectorSize: const Vec2(76, 2),
    );
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(result.reflectorRotations, isNotEmpty);
    expect(
      result.impacts
          .firstWhere((impact) => impact.entityId == 'reflector')
          .position
          .x,
      greaterThan(100),
    );
    expect(
      result.reflectorRotations.first.velocityBefore.length,
      greaterThan(20),
    );
  });

  test('직사각형 상자가 회전판 끝에 닿으면 OBB 접촉점을 보존하며 연쇄 반사된다', () {
    final state = GameState(
      levelIndex: 0,
      levelName: '직사각형 연쇄 시험',
      entities: [
        const EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(40, 280),
          size: Vec2(24, 24),
          movable: true,
          solid: true,
        ),
        const EntityState(
          id: 'crate',
          type: EntityType.crate,
          position: Vec2(120, 280),
          size: Vec2(30, 30),
          movable: true,
          solid: true,
        ),
        _reflector(position: const Vec2(220, 280)),
      ],
      ballSpawn: const Vec2(40, 280),
    );
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final rotation = result.reflectorRotations.firstWhere(
      (candidate) => candidate.sourceEntityId == 'crate',
    );
    final impact = result.impacts.firstWhere(
      (candidate) =>
          candidate.entityId == 'reflector' &&
          candidate.pathIndex == rotation.pathIndex,
    );
    expect(rotation.orientationBefore, 0);
    expect(rotation.collisionNormal.x, closeTo(-1, 0.001));
    expect(rotation.collisionNormal.y, closeTo(0, 0.001));
    expect(rotation.collisionNormal, impact.normal);
    expect(
      rotation.collisionNormal.dot(rotation.velocityBefore),
      lessThanOrEqualTo(0.001),
    );
    final crate = result.state.entityById('crate')!;
    expect(crate.position.x, greaterThan(120));
    expect(
      _overlapsReflectorAabb(result.state.entityById('reflector')!, crate),
      isFalse,
    );
    expect(result.events, contains('reflector_rotated'));
  });

  test('대각 회전판의 직사각형 모서리 충돌은 SAT 대각 법선을 선택한다', () {
    final state = GameState(
      levelIndex: 0,
      levelName: '대각 OBB 시험',
      entities: [
        const EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(40, 315),
          size: Vec2(24, 24),
          movable: true,
          solid: true,
        ),
        const EntityState(
          id: 'crate',
          type: EntityType.crate,
          position: Vec2(120, 315),
          size: Vec2(30, 30),
          movable: true,
          solid: true,
        ),
        _reflector(orientation: 1, position: const Vec2(220, 280)),
      ],
      ballSpawn: const Vec2(40, 315),
    );
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final rotation = result.reflectorRotations.firstWhere(
      (candidate) => candidate.sourceEntityId == 'crate',
    );
    expect(rotation.collisionNormal.length, closeTo(1, 0.001));
    expect(rotation.collisionNormal.x.abs(), greaterThan(0.2));
    expect(rotation.collisionNormal.y.abs(), greaterThan(0.2));
    expect(
      rotation.collisionNormal.dot(rotation.velocityBefore),
      lessThanOrEqualTo(0.001),
    );
    expect(
      _overlapsReflectorAabb(
        result.state.entityById('reflector')!,
        result.state.entityById('crate')!,
      ),
      isFalse,
    );
    expect(rotation.orientationAfter, 3);
  });

  test('끝단의 접선·화면 축 동률은 고정 축 순서로 end-cap 법선을 선택한다', () {
    final state = GameState(
      levelIndex: 0,
      levelName: '축 동률 시험',
      entities: [
        const EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(40, 280),
          size: Vec2(24, 24),
          movable: true,
          solid: true,
        ),
        const EntityState(
          id: 'crate',
          type: EntityType.crate,
          position: Vec2(120, 280),
          size: Vec2(30, 30),
          movable: true,
          solid: true,
        ),
        _reflector(),
      ],
      ballSpawn: const Vec2(40, 280),
    );
    final result = resolver.resolve(
      state,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final rotation = result.reflectorRotations.firstWhere(
      (candidate) => candidate.sourceEntityId == 'crate',
    );
    expect(rotation.collisionNormal, const Vec2(-1, 0));
    expect(
      _overlapsReflectorAabb(
        result.state.entityById('reflector')!,
        result.state.entityById('crate')!,
      ),
      isFalse,
    );
  });

  test('회전판이 반사한 뒤에도 벽 경계와의 다음 swept 판정을 건너뛰지 않는다', () {
    final result = resolver.resolve(
      _physicsState(reflectorOrientation: 0),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    final rotation = result.reflectorRotations.single;
    final followingImpacts = result.impacts.where(
      (impact) => impact.pathIndex > rotation.pathIndex,
    );
    expect(followingImpacts, isNotEmpty);
    expect(
      followingImpacts.any((impact) => impact.entityType == EntityType.wall),
      isTrue,
    );
    expect(
      result.state.entityById('reflector')!.position,
      const Vec2(180, 280),
    );
  });

  test('얇은 벽 충돌 뒤 벽 EntityState 전체는 변하지 않는다', () {
    final wall = const EntityState(
      id: 'thin_wall',
      type: EntityType.wall,
      position: Vec2(180, 420),
      size: Vec2(240, 2),
      movable: false,
      solid: true,
      active: true,
      hitboxScale: 0.92,
      restitution: 0.31,
      visualState: '기본',
    );
    final result = resolver.resolve(
      _physicsState(reflectorPosition: const Vec2(180, 280), extra: [wall]),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    final after = result.state.entityById(wall.id)!;
    expect(after.id, wall.id);
    expect(after.type, wall.type);
    expect(after.position, wall.position);
    expect(after.size, wall.size);
    expect(after.traits, wall.traits);
    expect(after.movable, wall.movable);
    expect(after.solid, wall.solid);
    expect(after.active, wall.active);
    expect(after.open, wall.open);
    expect(after.pressed, wall.pressed);
    expect(after.visualState, wall.visualState);
    expect(after.hitboxScale, wall.hitboxScale);
    expect(after.restitution, wall.restitution);
    expect(after.linkId, wall.linkId);
    expect(after.direction, wall.direction);
    expect(after.referenceSpeed, wall.referenceSpeed);
    expect(after.allowedTargets, wall.allowedTargets);
    expect(after.reflectorOrientation, wall.reflectorOrientation);
    expect(after.reflectorRotationCount, wall.reflectorRotationCount);
    expect(result.impacts.any((impact) => impact.entityId == wall.id), isTrue);
  });

  test('다중 반사판·다중 이동 source는 엔티티 나열 순서와 무관하게 안정적이다', () {
    final base = _physicsState(
      ballPosition: const Vec2(40, 280),
      reflectorPosition: const Vec2(340, 100),
      extra: const [
        EntityState(
          id: 'spent_ball',
          type: EntityType.ball,
          position: Vec2(110, 280),
          size: Vec2(24, 24),
          movable: true,
          solid: true,
        ),
        EntityState(
          id: 'crate',
          type: EntityType.crate,
          position: Vec2(145, 280),
          size: Vec2(24, 24),
          movable: true,
          solid: true,
        ),
        EntityState(
          id: 'reflector_a',
          type: EntityType.rotatingReflector,
          position: Vec2(220, 280),
          size: Vec2(76, 12),
        ),
        EntityState(
          id: 'reflector_b',
          type: EntityType.rotatingReflector,
          position: Vec2(220, 340),
          size: Vec2(76, 12),
        ),
      ],
    );
    final reversed = base.copyWith(entities: base.entities.reversed.toList());
    final input = const ShotInput(direction: Vec2(1, 0), power: 1);
    final first = resolver.resolve(base, input);
    final second = resolver.resolve(reversed, input);

    String eventOrder(ShotResult result) {
      return result.physicsEvents
          .map(
            (event) =>
                '${event.eventId}:${event.parentEventId}:${event.kind.name}:${event.sourceEntityId}:${event.targetEntityId}:${event.pathIndex}',
          )
          .join('|');
    }

    expect(eventOrder(first), eventOrder(second));
    expect(first.reflectorRotations, isNotEmpty);
    expect(
      first.reflectorRotations
          .map((rotation) => rotation.sourceEntityId)
          .toSet(),
      isNotEmpty,
    );
    expect(
      first.reflectorRotations
          .map((rotation) => rotation.reflectorEntityId)
          .toSet(),
      isNotEmpty,
    );
    expect(
      first.state
          .entityById('spent_ball')!
          .position
          .distanceTo(base.entityById('spent_ball')!.position),
      greaterThan(0.5),
    );
    expect(
      first.state
          .entityById('crate')!
          .position
          .distanceTo(base.entityById('crate')!.position),
      greaterThan(0.5),
    );
    expect(
      first.state.entityById('reflector_a')!.reflectorRotationCount +
          first.state.entityById('reflector_b')!.reflectorRotationCount,
      greaterThan(0),
    );
    expect(
      first.reflectorRotations
          .map((rotation) => rotation.sourceEntityId)
          .toSet(),
      equals(
        second.reflectorRotations
            .map((rotation) => rotation.sourceEntityId)
            .toSet(),
      ),
    );
    expect(
      first.reflectorRotations
          .map((rotation) => rotation.reflectorEntityId)
          .toSet(),
      equals(
        second.reflectorRotations
            .map((rotation) => rotation.reflectorEntityId)
            .toSet(),
      ),
    );
  });

  test('앞선 벽·홀·슬라이더가 뒤쪽 반사판보다 먼저 선택된다', () {
    final frontWall = const EntityState(
      id: 'front_wall',
      type: EntityType.wall,
      position: Vec2(180, 360),
      size: Vec2(240, 18),
      movable: false,
      solid: true,
    );
    final wallResult = resolver.resolve(
      _physicsState(extra: [frontWall]),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    expect(wallResult.reflectorRotations, isEmpty);
    expect(wallResult.impacts.first.entityId, 'front_wall');
    expect(wallResult.state.entityById('reflector')!.reflectorRotationCount, 0);

    final frontHole = const EntityState(
      id: 'front_hole',
      type: EntityType.hole,
      position: Vec2(180, 360),
      size: Vec2(36, 36),
      solid: false,
    );
    final holeResult = resolver.resolve(
      _physicsState(extra: [frontHole]),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    expect(holeResult.state.phase, GamePhase.success);
    expect(holeResult.reflectorRotations, isEmpty);
    expect(holeResult.impacts.first.entityType, EntityType.hole);

    final frontSlider = const EntityState(
      id: 'front_slider',
      type: EntityType.powerSlider,
      position: Vec2(180, 360),
      size: Vec2(80, 18),
      solid: false,
      direction: Vec2(1, 0),
      referenceSpeed: 30,
      allowedTargets: {EntityType.ball},
    );
    final sliderResult = resolver.resolve(
      _physicsState(extra: [frontSlider]),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    expect(sliderResult.powerSliderActivations, isNotEmpty);
    expect(sliderResult.reflectorRotations, isNotEmpty);
    expect(
      sliderResult.powerSliderActivations.first.pathIndex,
      lessThan(sliderResult.reflectorRotations.first.pathIndex),
    );
  });

  test('연쇄 상자도 앞선 벽을 먼저 선택하고 뒤쪽 반사판을 선점하지 않는다', () {
    final result = resolver.resolve(
      _physicsState(
        ballPosition: const Vec2(40, 280),
        reflectorPosition: const Vec2(260, 280),
        extra: const [
          EntityState(
            id: 'crate',
            type: EntityType.crate,
            position: Vec2(120, 280),
            size: Vec2(30, 30),
            movable: true,
            solid: true,
          ),
          EntityState(
            id: 'front_wall',
            type: EntityType.wall,
            position: Vec2(190, 280),
            size: Vec2(18, 560),
            movable: false,
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(
      result.impacts.any((impact) => impact.entityId == 'front_wall'),
      isTrue,
    );
    expect(result.reflectorRotations, isEmpty);
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 0);
  });

  test('멀리 떨어진 같은 방향의 반사판은 연쇄 첫 sample에서 가짜 충돌하지 않는다', () {
    final result = resolver.resolve(
      _physicsState(
        ballPosition: const Vec2(40, 280),
        reflectorPosition: const Vec2(340, 100),
        extra: const [
          EntityState(
            id: 'crate',
            type: EntityType.crate,
            position: Vec2(120, 280),
            size: Vec2(30, 30),
            movable: true,
            solid: true,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(result.reflectorRotations, isEmpty);
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 0);
  });

  test('점착 공은 회전판보다 먼저 정지하고 회전 사건을 만들지 않는다', () {
    final result = resolver.resolve(
      _physicsState(),
      const ShotInput(
        direction: Vec2(0, -1),
        power: 1,
        equippedTrait: TraitType.sticky,
      ),
    );
    expect(result.reflectorRotations, isEmpty);
    expect(result.events, contains('sticky_attached'));
    expect(result.state.entityById('reflector')!.reflectorRotationCount, 0);
  });

  test('홀 포획이 같은 진행의 고체 충돌보다 먼저 처리된다', () {
    final result = resolver.resolve(
      _physicsState(
        extra: const [
          EntityState(
            id: 'hole',
            type: EntityType.hole,
            position: Vec2(180, 300),
            size: Vec2(36, 36),
            solid: false,
          ),
        ],
      ),
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    expect(result.state.phase, GamePhase.success);
    expect(result.reflectorRotations, isEmpty);
    expect(result.events, contains('hole_entered'));
  });

  test('움직이는 과거 공과 무거운 물체는 회전판까지 연쇄 이동한다', () {
    for (final movable in <EntityState>[
      const EntityState(
        id: 'spent_ball',
        type: EntityType.ball,
        position: Vec2(120, 280),
        size: Vec2(24, 24),
        movable: true,
        solid: true,
      ),
      const EntityState(
        id: 'weight',
        type: EntityType.weight,
        position: Vec2(120, 280),
        size: Vec2(32, 32),
        movable: true,
        solid: true,
      ),
    ]) {
      final result = resolver.resolve(
        _physicsState(ballPosition: const Vec2(40, 280), extra: [movable]),
        const ShotInput(direction: Vec2(1, 0), power: 1),
      );
      expect(
        result.reflectorRotations,
        contains(
          isA<ReflectorRotation>().having(
            (rotation) => rotation.sourceEntityId,
            'sourceEntityId',
            movable.id,
          ),
        ),
      );
      expect(
        result.state
            .entityById(movable.id)!
            .position
            .distanceTo(movable.position),
        greaterThan(1),
      );
      final rotationEvent = result.physicsEvents.singleWhere(
        (event) =>
            event.kind == PhysicsEventKind.reflectorRotation &&
            event.sourceEntityId == movable.id,
      );
      final impactEvent = result.physicsEvents.singleWhere(
        (event) => event.eventId == rotationEvent.parentEventId,
      );
      expect(
        impactEvent.resultingVelocity,
        rotationEvent.reflectorRotation!.velocityAfter,
      );
    }
  });

  test('고정된 과거 공은 이동 source가 아니라 고체 반사 장애물이다', () {
    final fixed = const EntityState(
      id: 'spent_ball',
      type: EntityType.ball,
      position: Vec2(120, 280),
      size: Vec2(24, 24),
      movable: false,
      solid: true,
    );
    final result = resolver.resolve(
      _physicsState(ballPosition: const Vec2(40, 280), extra: [fixed]),
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    expect(result.reflectorRotations, isEmpty);
    expect(result.state.entityById('spent_ball')!.position, fixed.position);
    expect(result.events, contains('spent_ball_bounced'));
  });

  test('RunState 샷 로그 왕복 후 회전판 방향과 replay fingerprint를 재구성한다', () {
    final stage = _patternWithReflector(
      reflector: const PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(60, 280),
        size: Vec2(76, 12),
      ),
    );
    final draw = StageShuffleBag.draw(
      stage: stage,
      state: StageShuffleBagState.initial(stage.stageId),
      rootSeed: 17,
    );
    final inputLog = [
      RunShotInput(
        stageId: draw.stageId,
        patternId: draw.patternId,
        shotIndex: 0,
        direction: const Vec2(0, -1),
        power: 1,
      ),
      RunShotInput(
        stageId: draw.stageId,
        patternId: draw.patternId,
        shotIndex: 1,
        direction: const Vec2(0, -1),
        power: 1,
      ),
    ];
    final saved = RunState.initial(
      runId: 'reflector-replay',
      rootSeed: 17,
      resolverVersion: 'resolver-1',
      currentDraw: draw,
      now: DateTime.utc(2026, 8, 6),
    );
    final restored = RunState.fromJson({
      ...saved.toJson(),
      'shotInputLog': inputLog.map((input) => input.toJson()).toList(),
    });

    List<String> replayFingerprints(
      Iterable<RunShotInput> log,
      StagePattern pattern,
    ) {
      var state = pattern
          .toLevelDefinition(
            stageId: restored.currentStageId!,
            stageTitle: stage.title,
          )
          .createState(0);
      final fingerprints = <String>[];
      for (final input in log) {
        final result = resolver.resolve(
          state,
          ShotInput(
            direction: input.direction,
            power: input.power,
            equippedTrait: input.equippedTrait,
          ),
        );
        fingerprints.add(shotResultFingerprint(result));
        state = result.state;
      }
      return fingerprints;
    }

    expect(restored.shotInputLog, hasLength(2));
    expect(restored.currentStageId, draw.stageId);
    expect(restored.currentPatternId, draw.patternId);
    expect(restored.currentPatternSeed, draw.patternSeed);
    expect(restored.rootSeed, saved.rootSeed);
    expect(restored.resolverVersion, saved.resolverVersion);
    expect(
      replayFingerprints(inputLog, stage.patterns.single),
      equals(replayFingerprints(restored.shotInputLog, stage.patterns.single)),
    );
    final originalFingerprints = replayFingerprints(
      inputLog,
      stage.patterns.single,
    );
    final restoredFingerprints = replayFingerprints(
      restored.shotInputLog,
      stage.patterns.single,
    );
    expect(originalFingerprints, hasLength(2));
    expect(restoredFingerprints, equals(originalFingerprints));
    var reconstructed = stage.patterns.single
        .toLevelDefinition(
          stageId: restored.currentStageId!,
          stageTitle: stage.title,
        )
        .createState(0);
    for (final input in restored.shotInputLog) {
      reconstructed = resolver
          .resolve(
            reconstructed,
            ShotInput(
              direction: input.direction,
              power: input.power,
              equippedTrait: input.equippedTrait,
            ),
          )
          .state;
    }
    var original = stage.patterns.single
        .toLevelDefinition(
          stageId: saved.currentStageId!,
          stageTitle: stage.title,
        )
        .createState(0);
    for (final input in inputLog) {
      original = resolver
          .resolve(
            original,
            ShotInput(
              direction: input.direction,
              power: input.power,
              equippedTrait: input.equippedTrait,
            ),
          )
          .state;
    }
    expect(
      reconstructed.entityById('reflector')!.reflectorOrientation,
      original.entityById('reflector')!.reflectorOrientation,
    );
    expect(
      reconstructed.entityById('reflector')!.reflectorRotationCount,
      original.entityById('reflector')!.reflectorRotationCount,
    );
    expect(
      original.entityById('reflector')!.reflectorRotationCount,
      greaterThan(0),
    );
  });

  test('동일한 회전판 입력 100회는 동일한 fingerprint를 만든다', () {
    final fingerprints = <String>{};
    final eventOrders = <String>{};
    for (var index = 0; index < 100; index++) {
      final result = resolver.resolve(
        _physicsState(reflectorOrientation: 1),
        const ShotInput(direction: Vec2(0.7, -0.7), power: 1),
      );
      fingerprints.add(shotResultFingerprint(result));
      eventOrders.add(
        result.physicsEvents
            .asMap()
            .entries
            .map(
              (entry) =>
                  '${entry.key}:${entry.value.eventId}:${entry.value.parentEventId}:${entry.value.kind.name}',
            )
            .join('|'),
      );
    }
    expect(fingerprints, hasLength(1));
    expect(eventOrders, hasLength(1));
  });

  test('실제 runtime probe는 회전판 적용과 impact 후 rotation 순서를 증거로 보고한다', () {
    final stage = _patternWithReflector(
      reflector: const PatternObjectDefinition(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: Vec2(180, 280),
        size: Vec2(76, 12),
      ),
    );
    final pattern = stage.patterns.single;
    final evidence = ShotResolverPatternRuntimeProbe().probe(
      stage: stage,
      pattern: pattern,
    );
    expect(evidence.rotatorApplicable, isTrue);
    expect(evidence.rotatorOrderViolation, isFalse);
    expect(evidence.finiteCoordinates, isTrue);
    expect(evidence.finiteTime, isTrue);
  });
}

EntityState _reflector({
  int orientation = 0,
  int rotationCount = 0,
  Vec2 position = const Vec2(180, 280),
  Vec2 size = const Vec2(76, 12),
}) {
  return EntityState(
    id: 'reflector',
    type: EntityType.rotatingReflector,
    position: position,
    size: size,
    reflectorOrientation: orientation,
    reflectorRotationCount: rotationCount,
    movable: false,
    solid: true,
    active: true,
  );
}

GameState _physicsState({
  int reflectorOrientation = 0,
  int reflectorRotationCount = 0,
  Vec2 ballPosition = const Vec2(180, 440),
  Vec2 reflectorPosition = const Vec2(180, 280),
  Vec2 reflectorSize = const Vec2(76, 12),
  List<EntityState> extra = const [],
}) {
  return GameState(
    levelIndex: 0,
    levelName: '회전 반사판 시험',
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: ballPosition,
        size: const Vec2(24, 24),
        movable: true,
        solid: true,
      ),
      _reflector(
        orientation: reflectorOrientation,
        rotationCount: reflectorRotationCount,
        position: reflectorPosition,
        size: reflectorSize,
      ),
      ...extra,
    ],
    ballSpawn: ballPosition,
  );
}

StageDefinition _patternWithReflector({
  required PatternObjectDefinition reflector,
}) {
  return StageDefinition(
    stageId: 'reflector_stage',
    title: '회전 반사판 시험',
    patterns: [
      StagePattern(
        patternId: 'reflector_pattern',
        weight: 1,
        parShots: 3,
        difficultyBand: '중급',
        ballSpawn: const Vec2(60, 520),
        solutionFamilies: const {'직선', '반사'},
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
      ),
    ],
  );
}

Vec2 _reflectorNormal(int orientation) {
  final angle = -math.pi / 2 + orientation * math.pi / 4;
  return Vec2(math.cos(angle), math.sin(angle)).normalized();
}

bool _overlapsReflectorAabb(EntityState reflector, EntityState mover) {
  final angle = -math.pi / 2 + reflector.reflectorOrientation * math.pi / 4;
  final normal = Vec2(math.cos(angle), math.sin(angle)).normalized();
  final tangent = Vec2(-normal.y, normal.x);
  final halfNormal = reflector.size.y * reflector.hitboxScale / 2;
  final halfTangent = reflector.size.x * reflector.hitboxScale / 2;
  final halfWidth = mover.hitBounds.width / 2;
  final halfHeight = mover.hitBounds.height / 2;
  final delta = mover.position - reflector.position;
  for (final axis in [normal, tangent, const Vec2(1, 0), const Vec2(0, 1)]) {
    final reflectorRadius =
        halfNormal * axis.dot(normal).abs() +
        halfTangent * axis.dot(tangent).abs();
    final moverRadius = halfWidth * axis.x.abs() + halfHeight * axis.y.abs();
    if (delta.dot(axis).abs() > reflectorRadius + moverRadius) {
      return false;
    }
  }
  return true;
}
