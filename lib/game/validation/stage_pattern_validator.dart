import 'dart:math' as math;

import '../domain/geometry.dart';
import '../domain/level_definition.dart';
import '../domain/stage_pattern.dart';
import '../domain/entity_state.dart';
import 'stage_pattern_runtime_probe.dart';

const _activeBallHitRadius = 12 * 0.88;

/// 기본 발사 속력(약 24)과 연쇄 이동 단위(약 4)를 고려해 반복 안전성을
/// 보수적으로 확보하는 파워 슬라이더 기준 속력 상한이다.
const maxPowerSliderReferenceSpeed = 48.0;

/// 패턴 검증 결과의 안정적인 심각도다.
enum ValidationSeverity { error, warning }

/// 패턴 검증기가 외부에 공개하는 안정적인 오류 코드다.
enum ValidationIssueCode {
  emptyStageId,
  emptyStageTitle,
  patternCountOutOfRange,
  emptyPatternId,
  duplicatePatternId,
  invalidWeight,
  invalidParShots,
  emptyDifficultyBand,
  insufficientSolutionFamilies,
  nonFiniteBallSpawn,
  nonFinitePosition,
  nonFiniteSize,
  nonFiniteHitboxScale,
  nonFiniteRestitution,
  invalidSize,
  invalidHitboxScale,
  invalidRestitution,
  ballSpawnOutOfBounds,
  objectOutOfBounds,
  reservedObjectId,
  emptyObjectId,
  duplicateObjectId,
  invalidHoleCount,
  holeIsSolid,
  holeIsMovable,
  wallIsMovable,
  invalidSliderDirection,
  invalidSliderReferenceSpeed,
  invalidSliderTargets,
  sliderMustBeStatic,
  sliderMustBeNonSolid,
  sliderOverlapsSolid,
  ballSpawnOverlapsHole,
  existingBallOverlapsHole,
  ballSpawnInsideSolid,
  initialObjectOverlap,
  missingLinkedTarget,
  linkedStateMismatch,
  objectCountExceeded,
  requiredReward,
  runtimeAutoClear,
  runtimeNoRoute,
  runtimeWallMoved,
  runtimeInfiniteBounce,
  runtimeSliderTunneling,
  runtimeNonDeterministic,
  runtimeHolePassThrough,
  runtimeRotatorOrder,
  runtimeSoftLock,
  runtimeNonFinite,
  runtimeNegativeTime,
  runtimeProbeBudget,
}

extension ValidationIssueCodeSchema on ValidationIssueCode {
  /// 저장·fixture 비교에 사용하는 이름이다. enum 순서에 의존하지 않는다.
  String get schemaName {
    switch (this) {
      case ValidationIssueCode.emptyStageId:
        return 'empty_stage_id';
      case ValidationIssueCode.emptyStageTitle:
        return 'empty_stage_title';
      case ValidationIssueCode.patternCountOutOfRange:
        return 'pattern_count_out_of_range';
      case ValidationIssueCode.emptyPatternId:
        return 'empty_pattern_id';
      case ValidationIssueCode.duplicatePatternId:
        return 'duplicate_pattern_id';
      case ValidationIssueCode.invalidWeight:
        return 'invalid_weight';
      case ValidationIssueCode.invalidParShots:
        return 'invalid_par_shots';
      case ValidationIssueCode.emptyDifficultyBand:
        return 'empty_difficulty_band';
      case ValidationIssueCode.insufficientSolutionFamilies:
        return 'insufficient_solution_families';
      case ValidationIssueCode.nonFiniteBallSpawn:
        return 'non_finite_ball_spawn';
      case ValidationIssueCode.nonFinitePosition:
        return 'non_finite_position';
      case ValidationIssueCode.nonFiniteSize:
        return 'non_finite_size';
      case ValidationIssueCode.nonFiniteHitboxScale:
        return 'non_finite_hitbox_scale';
      case ValidationIssueCode.nonFiniteRestitution:
        return 'non_finite_restitution';
      case ValidationIssueCode.invalidSize:
        return 'invalid_size';
      case ValidationIssueCode.invalidHitboxScale:
        return 'invalid_hitbox_scale';
      case ValidationIssueCode.invalidRestitution:
        return 'invalid_restitution';
      case ValidationIssueCode.ballSpawnOutOfBounds:
        return 'ball_spawn_out_of_bounds';
      case ValidationIssueCode.objectOutOfBounds:
        return 'object_out_of_bounds';
      case ValidationIssueCode.reservedObjectId:
        return 'reserved_object_id';
      case ValidationIssueCode.emptyObjectId:
        return 'empty_object_id';
      case ValidationIssueCode.duplicateObjectId:
        return 'duplicate_object_id';
      case ValidationIssueCode.invalidHoleCount:
        return 'invalid_hole_count';
      case ValidationIssueCode.holeIsSolid:
        return 'hole_is_solid';
      case ValidationIssueCode.holeIsMovable:
        return 'hole_is_movable';
      case ValidationIssueCode.wallIsMovable:
        return 'wall_is_movable';
      case ValidationIssueCode.invalidSliderDirection:
        return 'invalid_slider_direction';
      case ValidationIssueCode.invalidSliderReferenceSpeed:
        return 'invalid_slider_reference_speed';
      case ValidationIssueCode.invalidSliderTargets:
        return 'invalid_slider_targets';
      case ValidationIssueCode.sliderMustBeStatic:
        return 'slider_must_be_static';
      case ValidationIssueCode.sliderMustBeNonSolid:
        return 'slider_must_be_non_solid';
      case ValidationIssueCode.sliderOverlapsSolid:
        return 'slider_overlaps_solid';
      case ValidationIssueCode.ballSpawnOverlapsHole:
        return 'ball_spawn_overlaps_hole';
      case ValidationIssueCode.existingBallOverlapsHole:
        return 'existing_ball_overlaps_hole';
      case ValidationIssueCode.ballSpawnInsideSolid:
        return 'ball_spawn_inside_solid';
      case ValidationIssueCode.initialObjectOverlap:
        return 'initial_object_overlap';
      case ValidationIssueCode.missingLinkedTarget:
        return 'missing_linked_target';
      case ValidationIssueCode.linkedStateMismatch:
        return 'linked_state_mismatch';
      case ValidationIssueCode.objectCountExceeded:
        return 'object_count_exceeded';
      case ValidationIssueCode.requiredReward:
        return 'required_reward';
      case ValidationIssueCode.runtimeAutoClear:
        return 'invalid_auto_clear';
      case ValidationIssueCode.runtimeNoRoute:
        return 'invalid_no_route';
      case ValidationIssueCode.runtimeWallMoved:
        return 'invalid_wall_moves';
      case ValidationIssueCode.runtimeInfiniteBounce:
        return 'invalid_infinite_bounce';
      case ValidationIssueCode.runtimeSliderTunneling:
        return 'invalid_slider_tunneling';
      case ValidationIssueCode.runtimeNonDeterministic:
        return 'invalid_non_deterministic';
      case ValidationIssueCode.runtimeHolePassThrough:
        return 'invalid_hole_pass_through';
      case ValidationIssueCode.runtimeRotatorOrder:
        return 'invalid_rotator_order';
      case ValidationIssueCode.runtimeSoftLock:
        return 'invalid_soft_lock';
      case ValidationIssueCode.runtimeNonFinite:
        return 'invalid_non_finite_runtime';
      case ValidationIssueCode.runtimeNegativeTime:
        return 'invalid_negative_time';
      case ValidationIssueCode.runtimeProbeBudget:
        return 'invalid_probe_budget';
    }
  }
}

class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.severity,
    required this.message,
    required this.stageId,
    required this.patternId,
    this.objectIds = const [],
  });

  final ValidationIssueCode code;
  final ValidationSeverity severity;
  final String message;
  final String stageId;
  final String? patternId;
  final List<String> objectIds;

  String get codeName => code.schemaName;

  @override
  String toString() {
    return '${code.schemaName}($stageId/${patternId ?? '-'})'
        '${objectIds.isEmpty ? '' : ' ${objectIds.join(',')}'}: $message';
  }
}

class ValidationReport {
  ValidationReport(Iterable<ValidationIssue> issues)
    : issues = List.unmodifiable(issues);

  final List<ValidationIssue> issues;

  bool get isValid =>
      issues.every((issue) => issue.severity != ValidationSeverity.error);

  bool hasCode(ValidationIssueCode code) =>
      issues.any((issue) => issue.code == code);

  int count(ValidationIssueCode code) =>
      issues.where((issue) => issue.code == code).length;

  List<ValidationIssue> whereCode(ValidationIssueCode code) =>
      List.unmodifiable(issues.where((issue) => issue.code == code));

  Set<ValidationIssueCode> get codes =>
      Set.unmodifiable(issues.map((issue) => issue.code));
}

/// 데이터 파싱 이후에 실행하는 순수 정적 패턴 검증기다.
///
/// 이 클래스는 JSON 파서의 [FormatException]을 삼키지 않는다. 파싱에
/// 성공한 모델의 정책·기하 결함만 [ValidationReport]로 반환한다.
class StagePatternValidator {
  StagePatternValidator({
    this.boardSize = const Vec2(360, 560),
    this.minPatternCount = 3,
    this.maxPatternCount = 4,
    this.maxObjectCount = 64,
    this.minSolutionFamilyCount = 2,
    this.maxRestitution = 1,
  }) : assert(boardSize.x.isFinite && boardSize.x > 0),
       assert(boardSize.y.isFinite && boardSize.y > 0),
       assert(minPatternCount >= 0),
       assert(maxPatternCount >= minPatternCount),
       assert(maxObjectCount >= 0),
       assert(minSolutionFamilyCount >= 0),
       assert(maxRestitution.isFinite && maxRestitution >= 0);

  final Vec2 boardSize;
  final int minPatternCount;
  final int maxPatternCount;
  final int maxObjectCount;
  final int minSolutionFamilyCount;
  final double maxRestitution;

  /// production 정책까지 포함해 하나의 스테이지를 검사한다.
  ValidationReport validate(StageDefinition stage) {
    return _validateStage(stage, enforceProductionPolicy: true);
  }

  /// [validate]의 읽기 쉬운 별칭이다.
  ValidationReport validateStage(StageDefinition stage) => validate(stage);

  /// 여러 스테이지를 입력 순서대로 검사한다.
  ValidationReport validateStages(Iterable<StageDefinition> stages) {
    final issues = <ValidationIssue>[];
    for (final stage in stages) {
      issues.addAll(validate(stage).issues);
    }
    return ValidationReport(issues);
  }

  /// 정적 검사 결과에 제한된 런타임 probe evidence를 합친다.
  ///
  /// 대표 입력에서 성공이 관찰되지 않은 것만으로는 no-route 오류를 만들지
  /// 않는다. 완전 탐색을 증명한 probe가 [definitiveNoRoute]를 보고할 때만
  /// 해당 오류를 추가한다.
  ValidationReport validateWithRuntimeProbe(
    StageDefinition stage, {
    required PatternRuntimeProbe probe,
  }) {
    final issues = <ValidationIssue>[...validate(stage).issues];
    for (final pattern in stage.patterns) {
      final evidence = probe.probe(stage: stage, pattern: pattern);
      _validateRuntimeEvidence(stage, pattern, evidence, issues);
    }
    return ValidationReport(_sortIssues(issues));
  }

  /// 하나의 패턴과 scripted evidence를 검증하는 메타 테스트용 API다.
  ValidationReport validatePatternWithRuntimeEvidence(
    StageDefinition stage,
    StagePattern pattern,
    PatternRuntimeEvidence evidence, {
    bool enforceProductionPolicy = true,
  }) {
    final issues = <ValidationIssue>[
      ...validatePattern(
        stage,
        pattern,
        enforceProductionPolicy: enforceProductionPolicy,
      ).issues,
    ];
    _validateRuntimeEvidence(stage, pattern, evidence, issues);
    return ValidationReport(_sortIssues(issues));
  }

  /// 1~4단계처럼 패턴 하나만 가진 기존 레벨을 검사한다.
  ///
  /// 개별 배치의 안전성은 모두 검사하지만 production의 패턴 수와
  /// solution family 최소 개수는 검사하지 않는다.
  ValidationReport validateLegacyStage(StageDefinition stage) {
    return _validateStage(stage, enforceProductionPolicy: false);
  }

  /// 패턴 하나를 별도로 검사할 때 사용하는 API다.
  ValidationReport validatePattern(
    StageDefinition stage,
    StagePattern pattern, {
    bool enforceProductionPolicy = true,
  }) {
    final issues = <ValidationIssue>[];
    _validateStageMetadata(stage, issues);
    if (enforceProductionPolicy) {
      _validatePatternCount(stage.patterns.length, stage.stageId, issues);
    }
    _validatePattern(
      stage,
      pattern,
      issues,
      enforceSolutionFamilyPolicy: enforceProductionPolicy,
    );
    return ValidationReport(_sortPatternIssues(issues));
  }

  /// 기존 하드코딩 레벨을 패턴 경계로 감싼 뒤 개별 레거시 검사한다.
  ValidationReport validateLegacyLevel(
    LevelDefinition level, {
    String? patternId,
  }) {
    final pattern = StagePattern.fromLevelDefinition(
      level,
      patternId: patternId ?? '${level.id}_legacy',
    );
    final stage = StageDefinition(
      stageId: level.id,
      title: level.name,
      patterns: [pattern],
    );
    return validateLegacyStage(stage);
  }

  ValidationReport _validateStage(
    StageDefinition stage, {
    required bool enforceProductionPolicy,
  }) {
    final issues = <ValidationIssue>[];
    _validateStageMetadata(stage, issues);
    if (enforceProductionPolicy) {
      _validatePatternCount(stage.patterns.length, stage.stageId, issues);
    }
    final stageIssues = _sortStageIssues(issues);
    final all = <ValidationIssue>[...stageIssues];
    for (final pattern in stage.patterns) {
      final patternIssues = <ValidationIssue>[];
      _validatePattern(
        stage,
        pattern,
        patternIssues,
        enforceSolutionFamilyPolicy: enforceProductionPolicy,
      );
      all.addAll(_sortPatternIssues(patternIssues));
    }
    return ValidationReport(all);
  }

  void _validateStageMetadata(
    StageDefinition stage,
    List<ValidationIssue> issues,
  ) {
    if (stage.stageId.trim().isEmpty) {
      issues.add(_issue(ValidationIssueCode.emptyStageId, stage.stageId));
    }
    if (stage.title.trim().isEmpty) {
      issues.add(_issue(ValidationIssueCode.emptyStageTitle, stage.stageId));
    }
  }

  void _validatePatternCount(
    int count,
    String stageId,
    List<ValidationIssue> issues,
  ) {
    if (count < minPatternCount || count > maxPatternCount) {
      issues.add(
        _issue(
          ValidationIssueCode.patternCountOutOfRange,
          stageId,
          message: '패턴 수는 $minPatternCount~$maxPatternCount개여야 합니다.',
        ),
      );
    }
  }

  void _validatePattern(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues, {
    required bool enforceSolutionFamilyPolicy,
  }) {
    final stageId = stage.stageId;
    final patternId = pattern.patternId;

    if (patternId.trim().isEmpty) {
      issues.add(
        _issue(
          ValidationIssueCode.emptyPatternId,
          stageId,
          patternId: patternId,
        ),
      );
    }
    final duplicatePatterns = stage.patterns
        .where((candidate) => candidate.patternId == patternId)
        .length;
    if (patternId.isNotEmpty && duplicatePatterns > 1) {
      issues.add(
        _issue(
          ValidationIssueCode.duplicatePatternId,
          stageId,
          patternId: patternId,
        ),
      );
    }
    if (!pattern.weight.isFinite || pattern.weight <= 0) {
      issues.add(
        _issue(
          ValidationIssueCode.invalidWeight,
          stageId,
          patternId: patternId,
        ),
      );
    }
    if (pattern.parShots <= 0) {
      issues.add(
        _issue(
          ValidationIssueCode.invalidParShots,
          stageId,
          patternId: patternId,
        ),
      );
    }
    if (pattern.difficultyBand.trim().isEmpty) {
      issues.add(
        _issue(
          ValidationIssueCode.emptyDifficultyBand,
          stageId,
          patternId: patternId,
        ),
      );
    }
    if (enforceSolutionFamilyPolicy &&
        pattern.solutionFamilies.length < minSolutionFamilyCount) {
      issues.add(
        _issue(
          ValidationIssueCode.insufficientSolutionFamilies,
          stageId,
          patternId: patternId,
          message: '풀이 계열은 최소 $minSolutionFamilyCount개여야 합니다.',
        ),
      );
    }
    if (pattern.metadata.containsKey('required_reward') &&
        pattern.metadata['required_reward']!.trim().isNotEmpty) {
      issues.add(
        _issue(
          ValidationIssueCode.requiredReward,
          stageId,
          patternId: patternId,
        ),
      );
    }
    if (pattern.objects.length > maxObjectCount) {
      issues.add(
        _issue(
          ValidationIssueCode.objectCountExceeded,
          stageId,
          patternId: patternId,
          message: '기물 수가 허용 예산 $maxObjectCount개를 초과했습니다.',
        ),
      );
    }

    final spawnFinite = _isFiniteVec(pattern.ballSpawn);
    if (!spawnFinite) {
      issues.add(
        _issue(
          ValidationIssueCode.nonFiniteBallSpawn,
          stageId,
          patternId: patternId,
        ),
      );
    }

    final objectIds = <String, List<PatternObjectDefinition>>{};
    for (final object in pattern.objects) {
      objectIds.putIfAbsent(object.id, () => []).add(object);
      _validateObject(stage, pattern, object, issues);
    }
    for (final entry in objectIds.entries) {
      if (entry.key.isNotEmpty && entry.value.length > 1) {
        issues.add(
          _issue(
            ValidationIssueCode.duplicateObjectId,
            stageId,
            patternId: patternId,
            objectIds: [entry.key],
          ),
        );
      }
    }

    _validateHoleRules(stage, pattern, issues);
    if (spawnFinite) {
      _validateSpawnRules(stage, pattern, issues);
    }
    _validateInitialOverlaps(stage, pattern, issues);
    _validateLinks(stage, pattern, issues);
  }

  void _validateObject(
    StageDefinition stage,
    StagePattern pattern,
    PatternObjectDefinition object,
    List<ValidationIssue> issues,
  ) {
    final stageId = stage.stageId;
    final patternId = pattern.patternId;
    final objectId = object.id;
    final ids = objectId.isEmpty ? const <String>[] : [objectId];
    if (objectId.trim().isEmpty) {
      issues.add(
        _issue(
          ValidationIssueCode.emptyObjectId,
          stageId,
          patternId: patternId,
        ),
      );
    }
    if (objectId == 'active_ball') {
      issues.add(
        _issue(
          ValidationIssueCode.reservedObjectId,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    }
    if (!_isFiniteVec(object.position)) {
      issues.add(
        _issue(
          ValidationIssueCode.nonFinitePosition,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    }
    if (!_isFiniteVec(object.size)) {
      issues.add(
        _issue(
          ValidationIssueCode.nonFiniteSize,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    } else if (object.size.x <= 0 || object.size.y <= 0) {
      issues.add(
        _issue(
          ValidationIssueCode.invalidSize,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    }
    if (!object.hitboxScale.isFinite) {
      issues.add(
        _issue(
          ValidationIssueCode.nonFiniteHitboxScale,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    } else if (object.hitboxScale <= 0) {
      issues.add(
        _issue(
          ValidationIssueCode.invalidHitboxScale,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    }
    if (!object.restitution.isFinite) {
      issues.add(
        _issue(
          ValidationIssueCode.nonFiniteRestitution,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    } else if (object.restitution < 0 || object.restitution > maxRestitution) {
      issues.add(
        _issue(
          ValidationIssueCode.invalidRestitution,
          stageId,
          patternId: patternId,
          objectIds: ids,
          message: '반발 계수는 0~$maxRestitution 범위여야 합니다.',
        ),
      );
    }
    if (object.type == EntityType.wall && object.movable) {
      issues.add(
        _issue(
          ValidationIssueCode.wallIsMovable,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    }
    if (object.type == EntityType.powerSlider) {
      if (!_isFiniteVec(object.direction) ||
          object.direction.length <= 0.0001) {
        issues.add(
          _issue(
            ValidationIssueCode.invalidSliderDirection,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
      if (!object.referenceSpeed.isFinite ||
          object.referenceSpeed <= 0 ||
          object.referenceSpeed > maxPowerSliderReferenceSpeed) {
        issues.add(
          _issue(
            ValidationIssueCode.invalidSliderReferenceSpeed,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
      if (object.allowedTargets.isEmpty ||
          object.allowedTargets.any(
            (type) => !_validPowerSliderTargetTypes.contains(type),
          )) {
        issues.add(
          _issue(
            ValidationIssueCode.invalidSliderTargets,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
      if (!object.active || object.movable) {
        issues.add(
          _issue(
            ValidationIssueCode.sliderMustBeStatic,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
      if (object.solid) {
        issues.add(
          _issue(
            ValidationIssueCode.sliderMustBeNonSolid,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
    }

    final shape = _shapeFor(object);
    if (shape != null &&
        !_isInsideBoard(shape, width: boardSize.x, height: boardSize.y)) {
      issues.add(
        _issue(
          ValidationIssueCode.objectOutOfBounds,
          stageId,
          patternId: patternId,
          objectIds: ids,
        ),
      );
    }
  }

  void _validateHoleRules(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
  ) {
    final holes = pattern.objects
        .where((object) => object.type == EntityType.hole)
        .toList();
    if (holes.length != 1) {
      issues.add(
        _issue(
          ValidationIssueCode.invalidHoleCount,
          stage.stageId,
          patternId: pattern.patternId,
          objectIds: holes.map((hole) => hole.id).where((id) => id.isNotEmpty),
          message: '홀은 정확히 하나여야 합니다.',
        ),
      );
    }
    for (final hole in holes) {
      final ids = hole.id.isEmpty ? const <String>[] : [hole.id];
      if (hole.solid) {
        issues.add(
          _issue(
            ValidationIssueCode.holeIsSolid,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: ids,
          ),
        );
      }
      if (hole.movable) {
        issues.add(
          _issue(
            ValidationIssueCode.holeIsMovable,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: ids,
          ),
        );
      }
    }
  }

  void _validateSpawnRules(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
  ) {
    final spawn = _Shape.circle(pattern.ballSpawn, 12 * 0.88);
    if (!_isInsideBoard(spawn, width: boardSize.x, height: boardSize.y)) {
      issues.add(
        _issue(
          ValidationIssueCode.ballSpawnOutOfBounds,
          stage.stageId,
          patternId: pattern.patternId,
        ),
      );
    }
    for (final object in pattern.objects) {
      final shape = _shapeFor(object);
      if (shape == null || (!object.active && object.type != EntityType.hole)) {
        continue;
      }
      if (object.type == EntityType.hole &&
          _isInsideActiveBallCaptureRadius(pattern.ballSpawn, object)) {
        final ids = object.id.isEmpty ? const <String>[] : [object.id];
        issues.add(
          _issue(
            ValidationIssueCode.ballSpawnOverlapsHole,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: ids,
          ),
        );
      } else if (object.type != EntityType.hole &&
          _isSolidForValidation(object) &&
          _overlaps(spawn, shape)) {
        final ids = object.id.isEmpty ? const <String>[] : [object.id];
        issues.add(
          _issue(
            ValidationIssueCode.ballSpawnInsideSolid,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: ids,
          ),
        );
      }
    }
  }

  void _validateInitialOverlaps(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
  ) {
    final objects = <PatternObjectDefinition>[];
    for (final object in pattern.objects) {
      if (object.active &&
          object.type != EntityType.hole &&
          _isSolidForValidation(object)) {
        objects.add(object);
      }
    }
    for (var i = 0; i < objects.length; i++) {
      final first = _shapeFor(objects[i]);
      if (first == null) continue;
      for (var j = i + 1; j < objects.length; j++) {
        final second = _shapeFor(objects[j]);
        if (second == null ||
            _isAllowedWallCorner(
              objects[i],
              objects[j],
              width: boardSize.x,
              height: boardSize.y,
            ) ||
            !_overlaps(first, second)) {
          continue;
        }
        final ids = [objects[i].id, objects[j].id]
          ..sort((a, b) => a.compareTo(b));
        issues.add(
          _issue(
            ValidationIssueCode.initialObjectOverlap,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: ids.where((id) => id.isNotEmpty),
          ),
        );
      }
    }

    final sliders = pattern.objects.where(
      (object) => object.type == EntityType.powerSlider && object.active,
    );
    for (final slider in sliders) {
      final sliderShape = _shapeFor(slider);
      if (sliderShape == null) continue;
      for (final object in pattern.objects) {
        if (object.id == slider.id ||
            !object.active ||
            object.type == EntityType.powerSlider) {
          continue;
        }
        final shape = _shapeFor(object);
        if (shape == null || !_overlaps(sliderShape, shape)) continue;
        _addIssueForObjectPair(
          stage,
          pattern,
          issues,
          ValidationIssueCode.sliderOverlapsSolid,
          slider,
          object,
        );
      }
    }

    PatternObjectDefinition? hole;
    for (final object in pattern.objects) {
      if (object.type == EntityType.hole) {
        hole = object;
        break;
      }
    }
    if (hole != null && _shapeFor(hole) != null) {
      for (final object in pattern.objects) {
        if (!object.active ||
            object.type != EntityType.ball ||
            _shapeFor(object) == null) {
          continue;
        }
        final captureRadius =
            math.min(hole.size.x, hole.size.y) / 2 +
            (math.min(object.size.x, object.size.y) /
                2 *
                object.hitboxScale *
                0.85);
        if (hole.position.distanceTo(object.position) <= captureRadius) {
          final ids = object.id.isEmpty ? const <String>[] : [object.id];
          issues.add(
            _issue(
              ValidationIssueCode.existingBallOverlapsHole,
              stage.stageId,
              patternId: pattern.patternId,
              objectIds: ids,
            ),
          );
        }
      }
    }
  }

  void _addIssueForObjectPair(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
    ValidationIssueCode code,
    PatternObjectDefinition first,
    PatternObjectDefinition second,
  ) {
    final ids = [first.id, second.id].where((id) => id.isNotEmpty).toList()
      ..sort();
    issues.add(
      _issue(code, stage.stageId, patternId: pattern.patternId, objectIds: ids),
    );
  }

  void _validateLinks(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
  ) {
    final activeGates = pattern.objects
        .where((object) => object.active && object.type == EntityType.gate)
        .toList();
    final activeSwitches = pattern.objects
        .where((object) => object.active && object.type == EntityType.switchPad)
        .toList();
    final linkedSwitches = activeSwitches
        .where((object) => object.linkId?.trim().isNotEmpty ?? false)
        .toList();
    final unlinkedSwitches = activeSwitches
        .where((object) => object.linkId?.trim().isNotEmpty != true)
        .toList();

    final gatesById = <String, List<PatternObjectDefinition>>{};
    for (final gate in activeGates) {
      gatesById.putIfAbsent(gate.id, () => []).add(gate);
    }
    final linkedByGateId = <String, List<PatternObjectDefinition>>{};
    for (final switchPad in linkedSwitches) {
      final targetId = switchPad.linkId!.trim();
      final targets = gatesById[targetId] ?? const [];
      if (targets.isEmpty) {
        _addMissingLinkIssue(stage, pattern, issues, [switchPad.id]);
        continue;
      }
      linkedByGateId.putIfAbsent(targetId, () => []).add(switchPad);
    }

    // linkId가 없는 switch는 resolver에서 모든 gate를 여는 legacy broadcast다.
    // 단일 switch·단일 gate 외의 unlinked 조합은 의도가 모호하므로 차단한다.
    final validLegacyBroadcast =
        linkedSwitches.isEmpty &&
        unlinkedSwitches.length == 1 &&
        activeGates.length == 1;
    if (unlinkedSwitches.isNotEmpty && !validLegacyBroadcast) {
      _addMissingLinkIssue(stage, pattern, issues, [
        ...unlinkedSwitches.map((object) => object.id),
        ...activeGates.map((object) => object.id),
      ]);
    }
    if (activeGates.isEmpty && activeSwitches.isNotEmpty) {
      _addMissingLinkIssue(
        stage,
        pattern,
        issues,
        activeSwitches.map((object) => object.id),
      );
    }

    for (final gate in activeGates) {
      final gateSwitches = linkedByGateId[gate.id];
      if (gateSwitches?.isNotEmpty ?? false) {
        final expectedOpen = gateSwitches!.any(
          (switchPad) => switchPad.pressed,
        );
        if (gate.open != expectedOpen) {
          _addStateMismatchIssue(stage, pattern, issues, gate, gateSwitches);
        }
      } else if (validLegacyBroadcast) {
        final expectedOpen = unlinkedSwitches.single.pressed;
        if (gate.open != expectedOpen) {
          _addStateMismatchIssue(
            stage,
            pattern,
            issues,
            gate,
            unlinkedSwitches,
          );
        }
      } else {
        // gate.linkId는 resolver에서 읽지 않으므로 연결 대상 판단에 사용하지 않는다.
        _addMissingLinkIssue(stage, pattern, issues, [gate.id]);
      }
    }
  }

  void _addMissingLinkIssue(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
    Iterable<String> objectIds,
  ) {
    final ids = objectIds.where((id) => id.isNotEmpty).toList()
      ..sort((a, b) => a.compareTo(b));
    final issue = _issue(
      ValidationIssueCode.missingLinkedTarget,
      stage.stageId,
      patternId: pattern.patternId,
      objectIds: ids,
    );
    final alreadyReported = issues.any(
      (existing) =>
          existing.code == issue.code &&
          existing.stageId == issue.stageId &&
          existing.patternId == issue.patternId &&
          _sameObjectIds(existing.objectIds, issue.objectIds),
    );
    if (!alreadyReported) {
      issues.add(issue);
    }
  }

  void _addStateMismatchIssue(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
    PatternObjectDefinition gate,
    Iterable<PatternObjectDefinition> switches,
  ) {
    final ids = [
      gate.id,
      ...switches.map((object) => object.id),
    ].where((id) => id.isNotEmpty).toList()..sort((a, b) => a.compareTo(b));
    issues.add(
      _issue(
        ValidationIssueCode.linkedStateMismatch,
        stage.stageId,
        patternId: pattern.patternId,
        objectIds: ids,
      ),
    );
  }

  List<ValidationIssue> _sortStageIssues(List<ValidationIssue> issues) {
    return _sortIssues(issues);
  }

  List<ValidationIssue> _sortPatternIssues(List<ValidationIssue> issues) {
    return _sortIssues(issues);
  }

  List<ValidationIssue> _sortIssues(List<ValidationIssue> issues) {
    final indexed = [
      for (var index = 0; index < issues.length; index++)
        (index: index, issue: issues[index]),
    ];
    indexed.sort((a, b) {
      final code = a.issue.code.schemaName.compareTo(b.issue.code.schemaName);
      if (code != 0) return code;
      final objectIds = _joinIds(
        a.issue.objectIds,
      ).compareTo(_joinIds(b.issue.objectIds));
      if (objectIds != 0) return objectIds;
      final pattern = (a.issue.patternId ?? '').compareTo(
        b.issue.patternId ?? '',
      );
      if (pattern != 0) return pattern;
      return a.index.compareTo(b.index);
    });
    return [for (final item in indexed) item.issue];
  }

  ValidationIssue _issue(
    ValidationIssueCode code,
    String stageId, {
    String? patternId,
    Iterable<String> objectIds = const [],
    String? message,
  }) {
    return ValidationIssue(
      code: code,
      severity: ValidationSeverity.error,
      message: message ?? _defaultMessage(code),
      stageId: stageId,
      patternId: patternId,
      objectIds: List.unmodifiable(objectIds),
    );
  }

  void _validateRuntimeEvidence(
    StageDefinition stage,
    StagePattern pattern,
    PatternRuntimeEvidence evidence,
    List<ValidationIssue> issues,
  ) {
    void add(ValidationIssueCode code, String message) {
      issues.add(
        _issue(
          code,
          stage.stageId,
          patternId: pattern.patternId,
          message: message,
        ),
      );
    }

    if (evidence.autoClearDetected) {
      add(ValidationIssueCode.runtimeAutoClear, '실행 시작 시 공이 자동으로 홀에 들어갑니다.');
    }
    if (evidence.definitiveNoRoute) {
      add(
        ValidationIssueCode.runtimeNoRoute,
        '완전 탐색 probe가 홀에 도달하는 경로가 없음을 증명했습니다.',
      );
    }
    if (evidence.wallMoved) {
      add(ValidationIssueCode.runtimeWallMoved, '실행 중 벽의 위치가 바뀌었습니다.');
    }
    if (evidence.safetyStop || evidence.infiniteBounce) {
      add(
        ValidationIssueCode.runtimeInfiniteBounce,
        '실행이 안전 중단되었거나 무한 반사 상태에 빠졌습니다.',
      );
    }
    if (evidence.sliderApplicable && evidence.sliderTunneling) {
      add(
        ValidationIssueCode.runtimeSliderTunneling,
        '파워 슬라이더 충돌을 한 프레임에 통과했습니다.',
      );
    }
    if (evidence.nonDeterministic) {
      add(
        ValidationIssueCode.runtimeNonDeterministic,
        '같은 시드와 입력의 실행 결과가 서로 다릅니다.',
      );
    }
    if (evidence.holePassThrough) {
      add(
        ValidationIssueCode.runtimeHolePassThrough,
        '공이 홀 포획 범위를 통과했지만 멈추지 않았습니다.',
      );
    }
    if (evidence.rotatorApplicable && evidence.rotatorOrderViolation) {
      add(
        ValidationIssueCode.runtimeRotatorOrder,
        '회전 반사판의 충돌 순서가 결정론적이지 않습니다.',
      );
    }
    if (evidence.launchUnavailable) {
      add(ValidationIssueCode.runtimeSoftLock, '발사할 수 없어 진행이 막혔습니다.');
    }
    if (!evidence.finiteCoordinates || !evidence.finiteTime) {
      add(
        ValidationIssueCode.runtimeNonFinite,
        '실행 결과에 유한하지 않은 좌표 또는 물리 수치가 포함되었습니다.',
      );
    }
    if (evidence.negativeTime) {
      add(
        ValidationIssueCode.runtimeNegativeTime,
        '실행 결과에 음수 이벤트 순서 또는 반복 횟수가 포함되었습니다.',
      );
    }
    if (!evidence.withinBudget) {
      add(
        ValidationIssueCode.runtimeProbeBudget,
        '실행 검증이 공개된 입력 또는 샷 상한을 초과했습니다.',
      );
    }
  }
}

String _defaultMessage(ValidationIssueCode code) {
  switch (code) {
    case ValidationIssueCode.emptyStageId:
      return '스테이지 ID가 비어 있습니다.';
    case ValidationIssueCode.emptyStageTitle:
      return '스테이지 제목이 비어 있습니다.';
    case ValidationIssueCode.patternCountOutOfRange:
      return '스테이지 패턴 수가 허용 범위를 벗어났습니다.';
    case ValidationIssueCode.emptyPatternId:
      return '패턴 ID가 비어 있습니다.';
    case ValidationIssueCode.duplicatePatternId:
      return '패턴 ID가 중복됩니다.';
    case ValidationIssueCode.invalidWeight:
      return '패턴 가중치는 유한한 양수여야 합니다.';
    case ValidationIssueCode.invalidParShots:
      return '기준 샷 수는 양수여야 합니다.';
    case ValidationIssueCode.emptyDifficultyBand:
      return '난이도 구간이 비어 있습니다.';
    case ValidationIssueCode.insufficientSolutionFamilies:
      return '풀이 계열 수가 부족합니다.';
    case ValidationIssueCode.nonFiniteBallSpawn:
      return '공 시작점은 유한한 좌표여야 합니다.';
    case ValidationIssueCode.nonFinitePosition:
      return '기물 위치는 유한한 좌표여야 합니다.';
    case ValidationIssueCode.nonFiniteSize:
      return '기물 크기는 유한한 값이어야 합니다.';
    case ValidationIssueCode.nonFiniteHitboxScale:
      return '히트박스 배율은 유한한 값이어야 합니다.';
    case ValidationIssueCode.nonFiniteRestitution:
      return '반발 계수는 유한한 값이어야 합니다.';
    case ValidationIssueCode.invalidSize:
      return '기물 크기는 양수여야 합니다.';
    case ValidationIssueCode.invalidHitboxScale:
      return '히트박스 배율은 양수여야 합니다.';
    case ValidationIssueCode.invalidRestitution:
      return '반발 계수가 허용 범위를 벗어났습니다.';
    case ValidationIssueCode.ballSpawnOutOfBounds:
      return '공 시작 히트박스가 필드 밖에 있습니다.';
    case ValidationIssueCode.objectOutOfBounds:
      return '기물 히트박스가 필드 밖에 있습니다.';
    case ValidationIssueCode.reservedObjectId:
      return 'active_ball은 패턴 기물 ID로 사용할 수 없습니다.';
    case ValidationIssueCode.emptyObjectId:
      return '기물 ID가 비어 있습니다.';
    case ValidationIssueCode.duplicateObjectId:
      return '기물 ID가 중복됩니다.';
    case ValidationIssueCode.invalidHoleCount:
      return '홀은 정확히 하나여야 합니다.';
    case ValidationIssueCode.holeIsSolid:
      return '홀은 고체일 수 없습니다.';
    case ValidationIssueCode.holeIsMovable:
      return '홀은 움직일 수 없습니다.';
    case ValidationIssueCode.wallIsMovable:
      return '벽은 움직일 수 없습니다.';
    case ValidationIssueCode.invalidSliderDirection:
      return '파워 슬라이더 방향은 유한하고 0이 아닌 벡터여야 합니다.';
    case ValidationIssueCode.invalidSliderReferenceSpeed:
      return '파워 슬라이더 기준 속력은 0보다 크고 ${maxPowerSliderReferenceSpeed.toStringAsFixed(0)} 이하여야 합니다.';
    case ValidationIssueCode.invalidSliderTargets:
      return '파워 슬라이더 대상에는 허용된 이동 기물만 안정적인 순서로 지정해야 합니다.';
    case ValidationIssueCode.sliderMustBeStatic:
      return '파워 슬라이더는 활성 정적 영역이어야 합니다.';
    case ValidationIssueCode.sliderMustBeNonSolid:
      return '파워 슬라이더는 비고체 영역이어야 합니다.';
    case ValidationIssueCode.sliderOverlapsSolid:
      return '파워 슬라이더 영역은 초기 고체 기물과 겹칠 수 없습니다.';
    case ValidationIssueCode.ballSpawnOverlapsHole:
      return '공 시작점이 홀에 걸쳐 자동 클리어됩니다.';
    case ValidationIssueCode.existingBallOverlapsHole:
      return '기존 공이 시작부터 홀 포획 범위에 있습니다.';
    case ValidationIssueCode.ballSpawnInsideSolid:
      return '공 시작 히트박스가 고체 기물 안에 있습니다.';
    case ValidationIssueCode.initialObjectOverlap:
      return '초기 기물 히트박스가 겹칩니다.';
    case ValidationIssueCode.missingLinkedTarget:
      return '문과 스위치의 연결 대상이 없습니다.';
    case ValidationIssueCode.linkedStateMismatch:
      return '연결된 문과 스위치의 초기 상태가 맞지 않습니다.';
    case ValidationIssueCode.objectCountExceeded:
      return '기물 수가 성능 예산을 초과했습니다.';
    case ValidationIssueCode.requiredReward:
      return '특정 보상 없이는 클리어해야 하는 패턴을 허용하지 않습니다.';
    case ValidationIssueCode.runtimeAutoClear:
      return '실행 시작 시 자동 클리어됩니다.';
    case ValidationIssueCode.runtimeNoRoute:
      return '홀에 도달할 수 있는 경로가 없습니다.';
    case ValidationIssueCode.runtimeWallMoved:
      return '벽이 물리 계산 중 이동했습니다.';
    case ValidationIssueCode.runtimeInfiniteBounce:
      return '무한 반사 또는 안전 중단이 감지되었습니다.';
    case ValidationIssueCode.runtimeSliderTunneling:
      return '파워 슬라이더 충돌을 통과했습니다.';
    case ValidationIssueCode.runtimeNonDeterministic:
      return '동일 입력 재실행 결과가 달라졌습니다.';
    case ValidationIssueCode.runtimeHolePassThrough:
      return '홀을 통과했지만 포획되지 않았습니다.';
    case ValidationIssueCode.runtimeRotatorOrder:
      return '회전 반사판 충돌 순서가 불안정합니다.';
    case ValidationIssueCode.runtimeSoftLock:
      return '발사할 수 없어 진행이 막혔습니다.';
    case ValidationIssueCode.runtimeNonFinite:
      return '실행 중 유한하지 않은 좌표 또는 물리 수치가 발생했습니다.';
    case ValidationIssueCode.runtimeNegativeTime:
      return '실행 중 음수 이벤트 순서 또는 반복 횟수가 발생했습니다.';
    case ValidationIssueCode.runtimeProbeBudget:
      return '실행 검증 상한을 초과했습니다.';
  }
}

bool _isFiniteVec(Vec2 value) => value.x.isFinite && value.y.isFinite;

String _joinIds(Iterable<String> ids) => ids.join('\u0000');

bool _sameObjectIds(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

bool _isSolidForValidation(PatternObjectDefinition object) {
  if (object.type == EntityType.powerSlider) {
    return false;
  }
  if (object.type == EntityType.wall) {
    return true;
  }
  if (object.type == EntityType.gate && object.open) {
    return false;
  }
  return object.solid;
}

const _validPowerSliderTargetTypes = <EntityType>{
  EntityType.ball,
  EntityType.crate,
  EntityType.bumper,
  EntityType.stickySurface,
  EntityType.weight,
  EntityType.balloon,
  EntityType.spikeSource,
};

bool _isInsideActiveBallCaptureRadius(
  Vec2 ballSpawn,
  PatternObjectDefinition hole,
) {
  if (!_isFiniteVec(hole.size) || hole.size.x <= 0 || hole.size.y <= 0) {
    return false;
  }
  final captureRadius =
      math.min(hole.size.x, hole.size.y) / 2 + _activeBallHitRadius;
  return ballSpawn.distanceTo(hole.position) <= captureRadius;
}

class _Shape {
  const _Shape.circle(this.center, this.radius)
    : isCircle = true,
      halfWidth = 0,
      halfHeight = 0;

  const _Shape.rectangle(this.center, this.halfWidth, this.halfHeight)
    : isCircle = false,
      radius = 0;

  final Vec2 center;
  final bool isCircle;
  final double radius;
  final double halfWidth;
  final double halfHeight;
}

_Shape? _shapeFor(PatternObjectDefinition object) {
  if (!_isFiniteVec(object.position) ||
      !_isFiniteVec(object.size) ||
      !object.hitboxScale.isFinite ||
      object.size.x <= 0 ||
      object.size.y <= 0 ||
      object.hitboxScale <= 0) {
    return null;
  }
  if (object.type == EntityType.ball ||
      object.type == EntityType.hole ||
      object.type == EntityType.balloon) {
    return _Shape.circle(
      object.position,
      math.min(object.size.x, object.size.y) / 2 * object.hitboxScale,
    );
  }
  return _Shape.rectangle(
    object.position,
    object.size.x / 2 * object.hitboxScale,
    object.size.y / 2 * object.hitboxScale,
  );
}

bool _isInsideBoard(_Shape shape, {double width = 360, double height = 560}) {
  if (shape.isCircle) {
    return shape.center.x - shape.radius >= 0 &&
        shape.center.x + shape.radius <= width &&
        shape.center.y - shape.radius >= 0 &&
        shape.center.y + shape.radius <= height;
  }
  return shape.center.x - shape.halfWidth >= 0 &&
      shape.center.x + shape.halfWidth <= width &&
      shape.center.y - shape.halfHeight >= 0 &&
      shape.center.y + shape.halfHeight <= height;
}

bool _overlaps(_Shape first, _Shape second, {bool inclusive = false}) {
  const epsilon = 0.000001;
  if (first.isCircle && second.isCircle) {
    final distance = first.center.distanceTo(second.center);
    final limit = first.radius + second.radius;
    return inclusive ? distance <= limit + epsilon : distance < limit - epsilon;
  }
  if (!first.isCircle && !second.isCircle) {
    final overlapX =
        math.min(
          first.center.x + first.halfWidth,
          second.center.x + second.halfWidth,
        ) -
        math.max(
          first.center.x - first.halfWidth,
          second.center.x - second.halfWidth,
        );
    final overlapY =
        math.min(
          first.center.y + first.halfHeight,
          second.center.y + second.halfHeight,
        ) -
        math.max(
          first.center.y - first.halfHeight,
          second.center.y - second.halfHeight,
        );
    return inclusive
        ? overlapX >= -epsilon && overlapY >= -epsilon
        : overlapX > epsilon && overlapY > epsilon;
  }
  final circle = first.isCircle ? first : second;
  final rectangle = first.isCircle ? second : first;
  final nearestX = circle.center.x.clamp(
    rectangle.center.x - rectangle.halfWidth,
    rectangle.center.x + rectangle.halfWidth,
  );
  final nearestY = circle.center.y.clamp(
    rectangle.center.y - rectangle.halfHeight,
    rectangle.center.y + rectangle.halfHeight,
  );
  final distance = circle.center.distanceTo(Vec2(nearestX, nearestY));
  return inclusive
      ? distance <= circle.radius + epsilon
      : distance < circle.radius - epsilon;
}

bool _isAllowedWallCorner(
  PatternObjectDefinition first,
  PatternObjectDefinition second, {
  required double width,
  required double height,
}) {
  if (first.type != EntityType.wall || second.type != EntityType.wall) {
    return false;
  }
  final a = _shapeFor(first);
  final b = _shapeFor(second);
  if (a == null || b == null) return false;
  final left = math.max(a.center.x - a.halfWidth, b.center.x - b.halfWidth);
  final right = math.min(a.center.x + a.halfWidth, b.center.x + b.halfWidth);
  final top = math.max(a.center.y - a.halfHeight, b.center.y - b.halfHeight);
  final bottom = math.min(a.center.y + a.halfHeight, b.center.y + b.halfHeight);
  const epsilon = 0.000001;
  final touchesVerticalBoundary = left <= epsilon || right >= width - epsilon;
  final touchesHorizontalBoundary =
      top <= epsilon || bottom >= height - epsilon;
  return right - left > epsilon &&
      bottom - top > epsilon &&
      touchesVerticalBoundary &&
      touchesHorizontalBoundary;
}
