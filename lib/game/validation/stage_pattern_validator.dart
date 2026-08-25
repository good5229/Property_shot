import 'dart:math' as math;

import '../domain/geometry.dart';
import '../domain/level_definition.dart';
import '../domain/stage_pattern.dart';
import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/hidden_mechanic_state.dart';
import '../domain/shot_input.dart';
import '../hint/hint_catalog.dart';
import '../hint/pattern_hint.dart';
import '../simulation/shot_resolver.dart';
import 'stage_pattern_runtime_probe.dart';

const _activeBallHitRadius = 12 * 0.88;

/// 시작 공과 벽 사이에 공의 시각 지름과 같은 빈 조준 공간을 둔다.
const defaultMinSpawnWallClearance = 24.0;

/// 플레이 영역을 둘러싸는 프레임 벽은 내부 장애물과 구분한다.
const stageBoundaryWallIds = {'wall_top', 'wall_left', 'wall_right'};

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
  invalidMovableWhenDrained,
  invalidSliderDirection,
  invalidSliderReferenceSpeed,
  invalidSliderTargets,
  sliderMustBeStatic,
  sliderMustBeNonSolid,
  sliderOverlapsSolid,
  invalidReflectorOrientation,
  invalidReflectorRotationCount,
  reflectorMustBeStatic,
  reflectorMustBeSolid,
  ballSpawnOverlapsHole,
  existingBallOverlapsHole,
  ballSpawnInsideSolid,
  ballSpawnTooCloseToWall,
  initialObjectOverlap,
  visualObjectOverlap,
  missingLinkedTarget,
  linkedStateMismatch,
  hiddenMechanicMissingTrigger,
  hiddenMechanicInvalidTrigger,
  hiddenMechanicAmbiguousTrigger,
  hiddenMechanicHintSpoiler,
  gimmickDirectBypass,
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
  runtimeMissingSolutionEvidence,
  runtimeRewardFreeRouteMissing,
  runtimeIntendedMechanicRouteMissing,
  hintCatalogVersion,
  hintMissing,
  hintDuplicate,
  hintInvalidLevel,
  hintEmptyText,
  hintMissingIntent,
  hintMissingReference,
  hintUnknownReference,
  hintTooVague,
  hintExactSolution,
  keyInvalidVersion,
  keyOutOfBounds,
  keyOverlapsSpawn,
  keyOverlapsSolid,
  keyOverlapsHole,
  keyUnreachable,
  demoDirectClear,
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
      case ValidationIssueCode.invalidMovableWhenDrained:
        return 'invalid_movable_when_drained';
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
      case ValidationIssueCode.invalidReflectorOrientation:
        return 'invalid_reflector_orientation';
      case ValidationIssueCode.invalidReflectorRotationCount:
        return 'invalid_reflector_rotation_count';
      case ValidationIssueCode.reflectorMustBeStatic:
        return 'reflector_must_be_static';
      case ValidationIssueCode.reflectorMustBeSolid:
        return 'reflector_must_be_solid';
      case ValidationIssueCode.ballSpawnOverlapsHole:
        return 'ball_spawn_overlaps_hole';
      case ValidationIssueCode.existingBallOverlapsHole:
        return 'existing_ball_overlaps_hole';
      case ValidationIssueCode.ballSpawnInsideSolid:
        return 'ball_spawn_inside_solid';
      case ValidationIssueCode.ballSpawnTooCloseToWall:
        return 'ball_spawn_too_close_to_wall';
      case ValidationIssueCode.initialObjectOverlap:
        return 'initial_object_overlap';
      case ValidationIssueCode.visualObjectOverlap:
        return 'visual_object_overlap';
      case ValidationIssueCode.missingLinkedTarget:
        return 'missing_linked_target';
      case ValidationIssueCode.linkedStateMismatch:
        return 'linked_state_mismatch';
      case ValidationIssueCode.hiddenMechanicMissingTrigger:
        return 'hidden_mechanic_missing_trigger';
      case ValidationIssueCode.hiddenMechanicInvalidTrigger:
        return 'hidden_mechanic_invalid_trigger';
      case ValidationIssueCode.hiddenMechanicAmbiguousTrigger:
        return 'hidden_mechanic_ambiguous_trigger';
      case ValidationIssueCode.hiddenMechanicHintSpoiler:
        return 'hidden_mechanic_hint_spoiler';
      case ValidationIssueCode.gimmickDirectBypass:
        return 'gimmick_direct_bypass';
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
      case ValidationIssueCode.runtimeMissingSolutionEvidence:
        return 'missing_solution_family_evidence';
      case ValidationIssueCode.runtimeRewardFreeRouteMissing:
        return 'missing_reward_free_route_evidence';
      case ValidationIssueCode.runtimeIntendedMechanicRouteMissing:
        return 'missing_intended_mechanic_route_evidence';
      case ValidationIssueCode.hintCatalogVersion:
        return 'invalid_hint_catalog_version';
      case ValidationIssueCode.hintMissing:
        return 'invalid_hint_missing';
      case ValidationIssueCode.hintDuplicate:
        return 'invalid_hint_duplicate';
      case ValidationIssueCode.hintInvalidLevel:
        return 'invalid_hint_level';
      case ValidationIssueCode.hintEmptyText:
        return 'invalid_hint_empty';
      case ValidationIssueCode.hintMissingIntent:
        return 'invalid_hint_missing_intent';
      case ValidationIssueCode.hintMissingReference:
        return 'invalid_hint_stage_pattern';
      case ValidationIssueCode.hintUnknownReference:
        return 'invalid_hint_wrong_pattern';
      case ValidationIssueCode.hintTooVague:
        return 'invalid_hint_too_vague';
      case ValidationIssueCode.hintExactSolution:
        return 'invalid_hint_exact_solution';
      case ValidationIssueCode.keyInvalidVersion:
        return 'invalid_key_version';
      case ValidationIssueCode.keyOutOfBounds:
        return 'invalid_key_out_of_bounds';
      case ValidationIssueCode.keyOverlapsSpawn:
        return 'invalid_key_overlap_spawn';
      case ValidationIssueCode.keyOverlapsSolid:
        return 'invalid_key_overlap';
      case ValidationIssueCode.keyOverlapsHole:
        return 'invalid_key_blocks_hole';
      case ValidationIssueCode.keyUnreachable:
        return 'invalid_key_unreachable';
      case ValidationIssueCode.demoDirectClear:
        return 'invalid_demo_direct_clear';
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

/// validator 메타 테스트에서 실제 런타임 규칙을 하나씩 변이하기 위한 정책이다.
///
/// 제품 기본값은 모든 규칙 활성화다. 비활성 정책은 검증기 자체가 결함을
/// 놓칠 때 계약 테스트가 이를 잡는지 확인하는 용도로만 사용한다.
class RuntimeValidationRulePolicy {
  const RuntimeValidationRulePolicy({this.disabledCodes = const {}});

  final Set<ValidationIssueCode> disabledCodes;

  bool isEnabled(ValidationIssueCode code) => !disabledCodes.contains(code);
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
    this.minSpawnWallClearance = defaultMinSpawnWallClearance,
    this.runtimeRulePolicy = const RuntimeValidationRulePolicy(),
  }) : assert(boardSize.x.isFinite && boardSize.x > 0),
       assert(boardSize.y.isFinite && boardSize.y > 0),
       assert(minPatternCount >= 0),
       assert(maxPatternCount >= minPatternCount),
       assert(maxObjectCount >= 0),
       assert(minSolutionFamilyCount >= 0),
       assert(maxRestitution.isFinite && maxRestitution >= 0),
       assert(minSpawnWallClearance.isFinite && minSpawnWallClearance >= 0);

  final Vec2 boardSize;
  final int minPatternCount;
  final int maxPatternCount;
  final int maxObjectCount;
  final int minSolutionFamilyCount;
  final double maxRestitution;
  final double minSpawnWallClearance;
  final RuntimeValidationRulePolicy runtimeRulePolicy;

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
    _validateHiddenMechanics(stage, pattern, issues);
    if (pattern.metadata['gimmick_required'] == 'true' &&
        _hasDirectClear(stage, pattern)) {
      issues.add(
        _issue(
          ValidationIssueCode.gimmickDirectBypass,
          stageId,
          patternId: patternId,
        ),
      );
    }
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
    if (object.movableWhenDrained &&
        (object.traits.isEmpty ||
            !object.solid ||
            _fixedWhenDrainedTypes.contains(object.type))) {
      issues.add(
        _issue(
          ValidationIssueCode.invalidMovableWhenDrained,
          stageId,
          patternId: patternId,
          objectIds: ids,
          message: '비워진 뒤 이동하려면 속성이 있는 이동 가능한 종류의 고체여야 합니다.',
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
    if (object.type == EntityType.rotatingReflector) {
      if (object.reflectorOrientation < 0 || object.reflectorOrientation > 7) {
        issues.add(
          _issue(
            ValidationIssueCode.invalidReflectorOrientation,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
      if (object.reflectorRotationCount < 0) {
        issues.add(
          _issue(
            ValidationIssueCode.invalidReflectorRotationCount,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
      if (!object.active || object.movable) {
        issues.add(
          _issue(
            ValidationIssueCode.reflectorMustBeStatic,
            stageId,
            patternId: patternId,
            objectIds: ids,
          ),
        );
      }
      if (!object.solid) {
        issues.add(
          _issue(
            ValidationIssueCode.reflectorMustBeSolid,
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
    if (object.type == EntityType.rotatingReflector &&
        object.reflectorOrientation >= 0 &&
        object.reflectorOrientation <= 7) {
      for (final orientation in {
        (object.reflectorOrientation + 2) % 8,
        (object.reflectorOrientation + 4) % 8,
        (object.reflectorOrientation + 6) % 8,
      }) {
        final reachableShape = _shapeFor(
          object,
          reflectorOrientation: orientation,
        );
        if (reachableShape != null &&
            !_isInsideBoard(
              reachableShape,
              width: boardSize.x,
              height: boardSize.y,
            )) {
          // 회전 후에도 기존 objectOutOfBounds 계약을 재사용한다.
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
      final blocksLikeWall =
          (object.type == EntityType.wall &&
              !stageBoundaryWallIds.contains(object.id)) ||
          (object.type == EntityType.gate && !object.open);
      if (blocksLikeWall &&
          _isSolidForValidation(object) &&
          !_overlaps(spawn, shape) &&
          _clearanceBetween(spawn, shape) < minSpawnWallClearance) {
        final ids = object.id.isEmpty ? const <String>[] : [object.id];
        issues.add(
          _issue(
            ValidationIssueCode.ballSpawnTooCloseToWall,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: ids,
            message:
                '공 시작점과 벽 사이에 최소 ${minSpawnWallClearance.toStringAsFixed(0)}의 빈 공간이 필요합니다.',
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

    final visibleObjects = pattern.objects
        .where(
          (object) =>
              object.active &&
              object.type != EntityType.wall &&
              !(object.type == EntityType.gate && object.open) &&
              object.size.x.isFinite &&
              object.size.y.isFinite &&
              object.position.x.isFinite &&
              object.position.y.isFinite,
        )
        .toList(growable: false);
    for (var firstIndex = 0; firstIndex < visibleObjects.length; firstIndex++) {
      final first = visibleObjects[firstIndex];
      final firstBounds = _visualBounds(first);
      for (
        var secondIndex = firstIndex + 1;
        secondIndex < visibleObjects.length;
        secondIndex++
      ) {
        final second = visibleObjects[secondIndex];
        if (_isIntentionalVisualPair(first, second)) continue;
        final intersection = firstBounds.intersection(_visualBounds(second));
        if (intersection.width <= 4 || intersection.height <= 4) continue;
        _addIssueForObjectPair(
          stage,
          pattern,
          issues,
          ValidationIssueCode.visualObjectOverlap,
          first,
          second,
        );
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

    final futureReflectorPairs = <String>{};
    for (final reflector in objects.where(
      (object) => object.type == EntityType.rotatingReflector,
    )) {
      for (final orientation in {
        (reflector.reflectorOrientation + 2) % 8,
        (reflector.reflectorOrientation + 4) % 8,
        (reflector.reflectorOrientation + 6) % 8,
      }) {
        final rotatedShape = _shapeFor(
          reflector,
          reflectorOrientation: orientation,
        );
        if (rotatedShape == null) continue;
        for (final object in objects) {
          if (object.id == reflector.id || object.movable) continue;
          final otherShape = _shapeFor(object);
          if (otherShape == null || !_overlaps(rotatedShape, otherShape)) {
            continue;
          }
          final pairIds = [reflector.id, object.id]
            ..sort((first, second) => first.compareTo(second));
          final pairKey = pairIds.join('\u0000');
          if (!futureReflectorPairs.add(pairKey)) continue;
          _addIssueForObjectPair(
            stage,
            pattern,
            issues,
            ValidationIssueCode.initialObjectOverlap,
            reflector,
            object,
          );
        }
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
        .where(
          (object) =>
              object.active &&
              object.type == EntityType.gate &&
              !object.id.startsWith('rotation_gate'),
        )
        .toList();
    // 연쇄 패턴은 스위치뿐 아니라 힘 발판/점착면이 의도된 첫 사건으로
    // 문을 열 수 있다. resolver의 linked-gate 규칙과 같은 활성자 집합을
    // 정적으로 검증한다.
    final activeSwitches = pattern.objects
        .where(
          (object) =>
              object.active &&
              (object.type == EntityType.switchPad ||
                  ((object.type == EntityType.powerSlider ||
                          object.type == EntityType.stickySurface) &&
                      (object.linkId?.trim().isNotEmpty ?? false))),
        )
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

  void _validateHiddenMechanics(
    StageDefinition stage,
    StagePattern pattern,
    List<ValidationIssue> issues,
  ) {
    final hiddenTargets = pattern.objects
        .where(
          (object) =>
              object.active &&
              HiddenMechanicState.masksIdentity(object.visualState),
        )
        .toList(growable: false);
    for (final target in hiddenTargets) {
      final triggers = pattern.objects
          .where((object) => object.active && object.linkId == target.id)
          .toList(growable: false);
      if (triggers.isEmpty) {
        issues.add(
          _issue(
            ValidationIssueCode.hiddenMechanicMissingTrigger,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: [target.id],
          ),
        );
        continue;
      }
      if (triggers.length > 1) {
        issues.add(
          _issue(
            ValidationIssueCode.hiddenMechanicAmbiguousTrigger,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: [target.id, ...triggers.map((item) => item.id)]..sort(),
          ),
        );
      }
      final invalid = triggers
          .where((trigger) => trigger.type != EntityType.balloon)
          .toList(growable: false);
      if (invalid.isNotEmpty) {
        issues.add(
          _issue(
            ValidationIssueCode.hiddenMechanicInvalidTrigger,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: [target.id, ...invalid.map((item) => item.id)]..sort(),
          ),
        );
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
      if (!runtimeRulePolicy.isEnabled(code)) return;
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
    if (evidence.solutionContractRequired) {
      final declaredFamilyObserved = evidence.observedSolutionFamilies.any(
        pattern.solutionFamilies.contains,
      );
      if (!declaredFamilyObserved) {
        add(
          ValidationIssueCode.runtimeMissingSolutionEvidence,
          '선언된 풀이 계열을 실제 성공으로 재현한 대표 입력 증거가 없습니다.',
        );
      }
      if (!evidence.rewardFreeRouteObserved) {
        add(
          ValidationIssueCode.runtimeRewardFreeRouteMissing,
          '런 보상 없이 성공하는 대표 입력 증거가 없습니다.',
        );
      }
    }
    if (evidence.intendedMechanicContractRequired &&
        !evidence.intendedMechanicRouteObserved) {
      add(
        ValidationIssueCode.runtimeIntendedMechanicRouteMissing,
        '우회 해법이 아닌 의도된 기믹 경로를 실제 성공으로 재현한 증거가 없습니다.',
      );
    }
  }

  /// 패턴 물리 카탈로그와 분리된 힌트/열쇠 카탈로그를 검사한다.
  ///
  /// 힌트 권한 저장이나 Flame VFX는 이 검증 경계에 포함하지 않는다. 여기서는
  /// stageId+patternId 연결, 실제 기물 참조, 열쇠 배치, 데모 직선 성공만 본다.
  ValidationReport validateHintCatalog(
    Iterable<StageDefinition> stages,
    HintCatalog hintCatalog,
  ) {
    final stageList = stages.toList(growable: false);
    final issues = <ValidationIssue>[];
    if (hintCatalog.version != 1) {
      issues.add(
        _issue(
          ValidationIssueCode.hintCatalogVersion,
          'hint_catalog',
          message: '지원하지 않는 힌트 카탈로그 버전입니다.',
        ),
      );
    }
    final entries = <String, PatternHintEntry>{};
    for (final entry in hintCatalog.entries) {
      final key = '${entry.stageId}\u0000${entry.patternId}';
      if (entries.containsKey(key)) {
        issues.add(
          _issue(
            ValidationIssueCode.hintDuplicate,
            entry.stageId,
            patternId: entry.patternId,
          ),
        );
      } else {
        entries[key] = entry;
      }
    }
    for (final stage in stageList) {
      for (final pattern in stage.patterns) {
        final entry = entries['${stage.stageId}\u0000${pattern.patternId}'];
        if (entry == null) {
          issues.add(
            _issue(
              ValidationIssueCode.hintMissing,
              stage.stageId,
              patternId: pattern.patternId,
            ),
          );
          continue;
        }
        _validateHintEntry(stage, pattern, entry, issues);
      }
    }
    for (final entry in hintCatalog.entries) {
      final stage = stageList.where((item) => item.stageId == entry.stageId);
      if (stage.length != 1 ||
          !stage.single.patterns.any(
            (item) => item.patternId == entry.patternId,
          )) {
        issues.add(
          _issue(
            ValidationIssueCode.hintMissingReference,
            entry.stageId,
            patternId: entry.patternId,
            message: '힌트가 존재하지 않는 stageId/patternId를 가리킵니다.',
          ),
        );
      }
    }
    return ValidationReport(_sortIssues(issues));
  }

  void _validateHintEntry(
    StageDefinition stage,
    StagePattern pattern,
    PatternHintEntry entry,
    List<ValidationIssue> issues,
  ) {
    final objectIds = pattern.objects.map((object) => object.id).toSet();
    final levels = entry.hints.map((hint) => hint.level).toList();
    if (entry.hintVersion < 1) {
      issues.add(
        _issue(
          ValidationIssueCode.hintCatalogVersion,
          stage.stageId,
          patternId: pattern.patternId,
        ),
      );
    }
    if (entry.intentTags.isEmpty) {
      issues.add(
        _issue(
          ValidationIssueCode.hintMissingIntent,
          stage.stageId,
          patternId: pattern.patternId,
        ),
      );
    }
    if (levels.length != 2 || levels[0] != 1 || levels[1] != 2) {
      issues.add(
        _issue(
          ValidationIssueCode.hintInvalidLevel,
          stage.stageId,
          patternId: pattern.patternId,
          message: '힌트 레벨은 중복 없이 L1, L2 두 단계가 연속으로 필요합니다.',
        ),
      );
    }
    for (final hint in entry.hints) {
      if (hint.text.trim().isEmpty) {
        issues.add(
          _issue(
            ValidationIssueCode.hintEmptyText,
            stage.stageId,
            patternId: pattern.patternId,
          ),
        );
      }
      if (hint.intentTags.isEmpty) {
        issues.add(
          _issue(
            ValidationIssueCode.hintMissingIntent,
            stage.stageId,
            patternId: pattern.patternId,
          ),
        );
      }
      if (hint.referencedObjectIds.isEmpty) {
        issues.add(
          _issue(
            ValidationIssueCode.hintTooVague,
            stage.stageId,
            patternId: pattern.patternId,
            message: '힌트는 실제 기물과 행동 의도를 하나 이상 참조해야 합니다.',
          ),
        );
      }
      final missing =
          hint.referencedObjectIds
              .where((id) => !objectIds.contains(id))
              .toList()
            ..sort();
      if (missing.isNotEmpty) {
        issues.add(
          _issue(
            ValidationIssueCode.hintUnknownReference,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: missing,
          ),
        );
      }
      if (_containsExactSolutionNumber(hint.text)) {
        issues.add(
          _issue(
            ValidationIssueCode.hintExactSolution,
            stage.stageId,
            patternId: pattern.patternId,
          ),
        );
      }
      final hiddenTargets = pattern.objects.where(
        (object) => HiddenMechanicState.masksIdentity(object.visualState),
      );
      for (final hidden in hiddenTargets) {
        final normalized = hint.text.toLowerCase();
        final leaked = _hiddenIdentityTokens(
          hidden,
        ).any((token) => normalized.contains(token.toLowerCase()));
        if (!leaked) continue;
        issues.add(
          _issue(
            ValidationIssueCode.hiddenMechanicHintSpoiler,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: [hidden.id],
          ),
        );
      }
    }
    final key = entry.key;
    if (key != null) _validateHintKey(stage, pattern, key, issues);
    if (!entry.directClearPolicy.allowed && _hasDirectClear(stage, pattern)) {
      issues.add(
        _issue(
          ValidationIssueCode.demoDirectClear,
          stage.stageId,
          patternId: pattern.patternId,
        ),
      );
    }
  }

  void _validateHintKey(
    StageDefinition stage,
    StagePattern pattern,
    HintKeyDefinition key,
    List<ValidationIssue> issues,
  ) {
    if (key.version < 1 ||
        key.id.trim().isEmpty ||
        !key.position.x.isFinite ||
        !key.position.y.isFinite ||
        !key.size.x.isFinite ||
        !key.size.y.isFinite ||
        key.size.x <= 0 ||
        key.size.y <= 0) {
      issues.add(
        _issue(
          ValidationIssueCode.keyInvalidVersion,
          stage.stageId,
          patternId: pattern.patternId,
          objectIds: [key.id],
        ),
      );
      return;
    }
    final bounds = key.bounds;
    if (bounds.left < 0 ||
        bounds.top < 0 ||
        bounds.right > boardSize.x ||
        bounds.bottom > boardSize.y) {
      issues.add(
        _issue(
          ValidationIssueCode.keyOutOfBounds,
          stage.stageId,
          patternId: pattern.patternId,
          objectIds: [key.id],
        ),
      );
    }
    const ballRadius = _activeBallHitRadius;
    if (bounds.intersectsCircle(pattern.ballSpawn, ballRadius)) {
      issues.add(
        _issue(
          ValidationIssueCode.keyOverlapsSpawn,
          stage.stageId,
          patternId: pattern.patternId,
          objectIds: [key.id],
        ),
      );
    }
    PatternObjectDefinition? hole;
    for (final object in pattern.objects) {
      if (object.type == EntityType.hole) hole = object;
      final entity = object.toEntityState();
      if (entity.solid &&
          entity.active &&
          entity.hitBounds.intersectsCircle(
            key.position,
            math.max(key.size.x, key.size.y) / 2,
          )) {
        issues.add(
          _issue(
            ValidationIssueCode.keyOverlapsSolid,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: [key.id, object.id],
          ),
        );
      }
    }
    if (hole != null) {
      final holeRadius = math.min(hole.size.x, hole.size.y) / 2;
      if (key.position.distanceTo(hole.position) <=
          holeRadius + math.max(key.size.x, key.size.y) / 2) {
        issues.add(
          _issue(
            ValidationIssueCode.keyOverlapsHole,
            stage.stageId,
            patternId: pattern.patternId,
            objectIds: [key.id, hole.id],
          ),
        );
      }
    }
    if (!_keyHasStraightApproach(pattern, key)) {
      issues.add(
        _issue(
          ValidationIssueCode.keyUnreachable,
          stage.stageId,
          patternId: pattern.patternId,
          objectIds: [key.id],
        ),
      );
    }
  }

  bool _keyHasStraightApproach(StagePattern pattern, HintKeyDefinition key) {
    final distance = pattern.ballSpawn.distanceTo(key.position);
    final samples = math.max(1, (distance / 4).ceil());
    for (var sample = 1; sample < samples; sample++) {
      final t = sample / samples;
      final point = Vec2(
        pattern.ballSpawn.x + (key.position.x - pattern.ballSpawn.x) * t,
        pattern.ballSpawn.y + (key.position.y - pattern.ballSpawn.y) * t,
      );
      for (final object in pattern.objects) {
        final entity = object.toEntityState();
        if (entity.active &&
            entity.solid &&
            entity.hitBounds.intersectsCircle(point, _activeBallHitRadius)) {
          return false;
        }
      }
    }
    return true;
  }

  bool _hasDirectClear(StageDefinition stage, StagePattern pattern) {
    final hole = pattern.objects.where((item) => item.type == EntityType.hole);
    if (hole.length != 1) return false;
    final direction = (hole.single.position - pattern.ballSpawn).normalized();
    if (direction.length == 0) return true;
    final initial = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    const resolver = ShotResolver();
    for (var step = 2; step <= 20; step++) {
      final power = step / 20;
      final result = resolver.resolve(
        initial,
        ShotInput(direction: direction, power: power),
      );
      if (result.state.phase != GamePhase.success) continue;
      if (result.events.any(
        (event) =>
            event == 'power_slider_activated' ||
            event == 'slider_gate_opened' ||
            event == 'switch_pressed' ||
            event == 'sticky_gate_opened',
      )) {
        continue;
      }
      if (result.impacts.every(
        (impact) => impact.entityType == EntityType.hole,
      )) {
        return true;
      }
    }
    return false;
  }
}

final RegExp _exactHintNumber = RegExp(
  r'(?:\d+(?:\.\d+)?\s*(?:도|%|퍼센트)|(?:각도|파워|힘)\s*[:：]?\s*\d+)',
);

bool _containsExactSolutionNumber(String text) =>
    _exactHintNumber.hasMatch(text);

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
    case ValidationIssueCode.invalidMovableWhenDrained:
      return '비워진 뒤 이동 설정을 이 기물에 사용할 수 없습니다.';
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
    case ValidationIssueCode.invalidReflectorOrientation:
      return '회전 반사판 방향은 0부터 7 사이여야 합니다.';
    case ValidationIssueCode.invalidReflectorRotationCount:
      return '회전 반사판 회전 횟수는 음수일 수 없습니다.';
    case ValidationIssueCode.reflectorMustBeStatic:
      return '회전 반사판은 활성 상태의 고정 기물이어야 합니다.';
    case ValidationIssueCode.reflectorMustBeSolid:
      return '회전 반사판은 고체 충돌면이어야 합니다.';
    case ValidationIssueCode.ballSpawnOverlapsHole:
      return '공 시작점이 홀에 걸쳐 자동 클리어됩니다.';
    case ValidationIssueCode.existingBallOverlapsHole:
      return '기존 공이 시작부터 홀 포획 범위에 있습니다.';
    case ValidationIssueCode.ballSpawnInsideSolid:
      return '공 시작 히트박스가 고체 기물 안에 있습니다.';
    case ValidationIssueCode.ballSpawnTooCloseToWall:
      return '공 시작점과 벽 사이의 조준 공간이 너무 좁습니다.';
    case ValidationIssueCode.initialObjectOverlap:
      return '초기 기물 히트박스가 겹칩니다.';
    case ValidationIssueCode.visualObjectOverlap:
      return '서로 다른 기물의 화면 영역이 겹쳐 정체를 구분하기 어렵습니다.';
    case ValidationIssueCode.missingLinkedTarget:
      return '문과 스위치의 연결 대상이 없습니다.';
    case ValidationIssueCode.linkedStateMismatch:
      return '연결된 문과 스위치의 초기 상태가 맞지 않습니다.';
    case ValidationIssueCode.hiddenMechanicMissingTrigger:
      return '숨은 기믹을 공개할 트리거가 없습니다.';
    case ValidationIssueCode.hiddenMechanicInvalidTrigger:
      return '숨은 기믹 공개 트리거가 현재 물리 규칙에서 지원되지 않습니다.';
    case ValidationIssueCode.hiddenMechanicAmbiguousTrigger:
      return '숨은 기믹에 공개 트리거가 둘 이상 연결되어 인과가 모호합니다.';
    case ValidationIssueCode.hiddenMechanicHintSpoiler:
      return '공개 전 힌트가 숨은 기믹의 정체를 누설합니다.';
    case ValidationIssueCode.gimmickDirectBypass:
      return '필수 기믹을 사용하지 않는 직선 즉시 클리어 경로가 있습니다.';
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
    case ValidationIssueCode.runtimeMissingSolutionEvidence:
      return '선언된 풀이 계열의 실행 증거가 없습니다.';
    case ValidationIssueCode.runtimeRewardFreeRouteMissing:
      return '런 보상 없는 대표 성공 증거가 없습니다.';
    case ValidationIssueCode.runtimeIntendedMechanicRouteMissing:
      return '의도된 기믹을 수행한 대표 성공 증거가 없습니다.';
    case ValidationIssueCode.hintCatalogVersion:
      return '힌트 카탈로그 버전이 올바르지 않습니다.';
    case ValidationIssueCode.hintMissing:
      return '패턴에 연결된 힌트가 없습니다.';
    case ValidationIssueCode.hintDuplicate:
      return '같은 패턴의 힌트가 중복됩니다.';
    case ValidationIssueCode.hintInvalidLevel:
      return '힌트 레벨 구성이 올바르지 않습니다.';
    case ValidationIssueCode.hintEmptyText:
      return '힌트 문구가 비어 있습니다.';
    case ValidationIssueCode.hintMissingIntent:
      return '힌트의 행동 의도가 없습니다.';
    case ValidationIssueCode.hintMissingReference:
      return '힌트의 stageId 또는 patternId 참조가 올바르지 않습니다.';
    case ValidationIssueCode.hintUnknownReference:
      return '힌트가 현재 패턴에 없는 기물을 참조합니다.';
    case ValidationIssueCode.hintTooVague:
      return '힌트가 구체 기물 또는 행동을 참조하지 않습니다.';
    case ValidationIssueCode.hintExactSolution:
      return '힌트에 정확한 각도 또는 힘 수치가 들어 있습니다.';
    case ValidationIssueCode.keyInvalidVersion:
      return '힌트 열쇠 정의가 올바르지 않습니다.';
    case ValidationIssueCode.keyOutOfBounds:
      return '힌트 열쇠가 필드 밖에 있습니다.';
    case ValidationIssueCode.keyOverlapsSpawn:
      return '힌트 열쇠가 공 시작점과 겹칩니다.';
    case ValidationIssueCode.keyOverlapsSolid:
      return '힌트 열쇠가 고체 기물과 겹칩니다.';
    case ValidationIssueCode.keyOverlapsHole:
      return '힌트 열쇠가 홀 근처를 가립니다.';
    case ValidationIssueCode.keyUnreachable:
      return '힌트 열쇠로 향하는 기본 접근선이 막혀 있습니다.';
    case ValidationIssueCode.demoDirectClear:
      return '시연 패턴이 기믹 없이 직선으로 즉시 클리어됩니다.';
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

class _VisualBounds {
  const _VisualBounds(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  _VisualBounds intersection(_VisualBounds other) => _VisualBounds(
    math.max(left, other.left),
    math.max(top, other.top),
    math.min(right, other.right),
    math.min(bottom, other.bottom),
  );

  double get width => math.max(0, right - left);
  double get height => math.max(0, bottom - top);
}

_VisualBounds _visualBounds(PatternObjectDefinition object) => _VisualBounds(
  object.position.x - object.size.x / 2,
  object.position.y - object.size.y / 2,
  object.position.x + object.size.x / 2,
  object.position.y + object.size.y / 2,
);

bool _isIntentionalVisualPair(
  PatternObjectDefinition first,
  PatternObjectDefinition second,
) {
  final types = {first.type, second.type};
  return types.contains(EntityType.ball) &&
      types.contains(EntityType.stickySurface);
}

Set<String> _hiddenIdentityTokens(PatternObjectDefinition object) => {
  object.id,
  switch (object.type) {
    EntityType.switchPad => '스위치',
    EntityType.powerSlider => '발판',
    EntityType.rotatingReflector => '반사판',
    EntityType.gate => '문',
    EntityType.crate => '상자',
    EntityType.weight => '돌',
    EntityType.bumper => '젤리',
    EntityType.stickySurface => '점착판',
    _ => object.type.name,
  },
  object.type.name,
};

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

const _fixedWhenDrainedTypes = <EntityType>{
  EntityType.hole,
  EntityType.wall,
  EntityType.switchPad,
  EntityType.gate,
  EntityType.powerSlider,
  EntityType.rotatingReflector,
};

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
      math.min(hole.size.x, hole.size.y) / 2 * hole.hitboxScale +
      _activeBallHitRadius;
  return ballSpawn.distanceTo(hole.position) <= captureRadius;
}

class _Shape {
  const _Shape.circle(this.center, this.radius)
    : isCircle = true,
      halfWidth = 0,
      halfHeight = 0,
      axisX = const Vec2(1, 0),
      axisY = const Vec2(0, 1);

  const _Shape.rectangle(this.center, this.halfWidth, this.halfHeight)
    : isCircle = false,
      radius = 0,
      axisX = const Vec2(1, 0),
      axisY = const Vec2(0, 1);

  const _Shape.orientedRectangle(
    this.center,
    this.halfWidth,
    this.halfHeight,
    this.axisX,
    this.axisY,
  ) : isCircle = false,
      radius = 0;

  final Vec2 center;
  final bool isCircle;
  final double radius;
  final double halfWidth;
  final double halfHeight;
  final Vec2 axisX;
  final Vec2 axisY;

  double projectionRadius(Vec2 axis) {
    return halfWidth * axis.dot(axisX).abs() +
        halfHeight * axis.dot(axisY).abs();
  }

  List<Vec2> get corners => [
    center + axisX * halfWidth + axisY * halfHeight,
    center - axisX * halfWidth + axisY * halfHeight,
    center - axisX * halfWidth - axisY * halfHeight,
    center + axisX * halfWidth - axisY * halfHeight,
  ];
}

_Shape? _shapeFor(PatternObjectDefinition object, {int? reflectorOrientation}) {
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
  if (object.type == EntityType.rotatingReflector) {
    final orientation = reflectorOrientation ?? object.reflectorOrientation;
    final angle = -math.pi / 2 + orientation * math.pi / 4;
    final normal = Vec2(math.cos(angle), math.sin(angle));
    final tangent = Vec2(-normal.y, normal.x);
    return _Shape.orientedRectangle(
      object.position,
      object.size.x / 2 * object.hitboxScale,
      object.size.y / 2 * object.hitboxScale,
      tangent,
      normal,
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
  return shape.corners.every(
    (corner) =>
        corner.x >= 0 &&
        corner.x <= width &&
        corner.y >= 0 &&
        corner.y <= height,
  );
}

bool _overlaps(_Shape first, _Shape second, {bool inclusive = false}) {
  const epsilon = 0.000001;
  if (first.isCircle && second.isCircle) {
    final distance = first.center.distanceTo(second.center);
    final limit = first.radius + second.radius;
    return inclusive ? distance <= limit + epsilon : distance < limit - epsilon;
  }
  if (!first.isCircle && !second.isCircle) {
    final axes = [first.axisX, first.axisY, second.axisX, second.axisY];
    for (final axis in axes) {
      final distance = (second.center - first.center).dot(axis).abs();
      final overlap =
          first.projectionRadius(axis) +
          second.projectionRadius(axis) -
          distance;
      if (inclusive ? overlap < -epsilon : overlap <= epsilon) return false;
    }
    return true;
  }
  final circle = first.isCircle ? first : second;
  final rectangle = first.isCircle ? second : first;
  final local = circle.center - rectangle.center;
  final localX = local.dot(rectangle.axisX);
  final localY = local.dot(rectangle.axisY);
  final nearestX = localX.clamp(-rectangle.halfWidth, rectangle.halfWidth);
  final nearestY = localY.clamp(-rectangle.halfHeight, rectangle.halfHeight);
  final nearest =
      rectangle.center +
      rectangle.axisX * nearestX +
      rectangle.axisY * nearestY;
  final distance = circle.center.distanceTo(nearest);
  return inclusive
      ? distance <= circle.radius + epsilon
      : distance < circle.radius - epsilon;
}

double _clearanceBetween(_Shape first, _Shape second) {
  if (first.isCircle && second.isCircle) {
    return first.center.distanceTo(second.center) -
        first.radius -
        second.radius;
  }
  final circle = first.isCircle ? first : second;
  final rectangle = first.isCircle ? second : first;
  final local = circle.center - rectangle.center;
  final localX = local.dot(rectangle.axisX);
  final localY = local.dot(rectangle.axisY);
  final nearestX = localX.clamp(-rectangle.halfWidth, rectangle.halfWidth);
  final nearestY = localY.clamp(-rectangle.halfHeight, rectangle.halfHeight);
  final nearest =
      rectangle.center +
      rectangle.axisX * nearestX +
      rectangle.axisY * nearestY;
  return circle.center.distanceTo(nearest) - circle.radius;
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
