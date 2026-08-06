import 'dart:convert';

import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

/// Validator 메타 테스트가 공유하는 이름 있는 invalid fixture다.
class InvalidPatternFixture {
  const InvalidPatternFixture({
    required this.name,
    required this.stage,
    required this.pattern,
    required this.expectedCodes,
    this.evidence,
    this.runtimeProbe,
  });

  final String name;
  final StageDefinition stage;
  final StagePattern pattern;
  final Set<ValidationIssueCode> expectedCodes;

  /// 값이 있으면 실제 probe를 실행한다. [evidence]와 동시에 사용하지 않는다.
  final PatternRuntimeProbe? runtimeProbe;

  /// EntityType이 아직 없는 기능은 scripted evidence 계약으로만 검증한다.
  final PatternRuntimeEvidence? evidence;
}

List<InvalidPatternFixture> buildInvalidPatternFixtures() {
  return [
    _staticFixture(
      'invalid_overlap',
      expectedCodes: {ValidationIssueCode.initialObjectOverlap},
      mutate: (json) {
        final objects = _objects(json);
        final crate = _objectById(objects, 'crate_a');
        final anvil = _objectById(objects, 'anvil');
        anvil['position'] = crate['position'];
      },
    ),
    _actualRuntimeFixture(
      'invalid_auto_clear',
      expectedCodes: {
        ValidationIssueCode.ballSpawnOverlapsHole,
        ValidationIssueCode.runtimeAutoClear,
      },
      mutate: (json) {
        final hole = _objectById(_objects(json), 'hole');
        json['ballSpawn'] = Map<String, dynamic>.from(
          hole['position'] as Map<String, dynamic>,
        );
      },
    ),
    _actualRuntimeFixture(
      'invalid_no_route',
      expectedCodes: {ValidationIssueCode.runtimeNoRoute},
      mutate: (json) {
        final objects = _objects(json);
        final barrier =
            Map<String, dynamic>.from(_objectById(objects, 'wall_top'))
              ..['id'] = 'route_barrier'
              ..['position'] = const {'x': 180.0, 'y': 300.0}
              ..['size'] = const {'x': 360.0, 'y': 24.0}
              ..['hitboxScale'] = 1.0;
        final hole = Map<String, dynamic>.from(_objectById(objects, 'hole'));
        json['objects'] = [hole, barrier];
      },
    ),
    _staticFixture(
      'invalid_wall_moves',
      expectedCodes: {ValidationIssueCode.wallIsMovable},
      mutate: (json) {
        _objectById(_objects(json), 'wall_left')['movable'] = true;
      },
    ),
    _runtimeFixture(
      'invalid_infinite_bounce',
      expectedCodes: {ValidationIssueCode.runtimeInfiniteBounce},
      evidence: const PatternRuntimeEvidence(
        probeCount: 3,
        maxProbeCount: 3,
        shotCount: 6,
        maxShots: 6,
        safetyStop: true,
        infiniteBounce: true,
      ),
    ),
    _runtimeFixture(
      'invalid_slider_tunneling',
      expectedCodes: {ValidationIssueCode.runtimeSliderTunneling},
      evidence: const PatternRuntimeEvidence(
        probeCount: 1,
        maxProbeCount: 1,
        shotCount: 2,
        maxShots: 2,
        sliderApplicable: true,
        sliderTunneling: true,
      ),
    ),
    _runtimeFixture(
      'invalid_non_deterministic',
      expectedCodes: {ValidationIssueCode.runtimeNonDeterministic},
      evidence: const PatternRuntimeEvidence(
        probeCount: 2,
        maxProbeCount: 2,
        shotCount: 4,
        maxShots: 4,
        nonDeterministic: true,
      ),
    ),
    _runtimeFixture(
      'invalid_hole_pass_through',
      expectedCodes: {ValidationIssueCode.runtimeHolePassThrough},
      evidence: const PatternRuntimeEvidence(
        probeCount: 2,
        maxProbeCount: 2,
        shotCount: 4,
        maxShots: 4,
        holePassThrough: true,
      ),
    ),
    _staticFixture(
      'invalid_reward_required',
      expectedCodes: {ValidationIssueCode.requiredReward},
      mutate: (json) {
        (json['metadata'] as Map<String, dynamic>)['required_reward'] =
            'heavy_core';
      },
    ),
    _staticFixture(
      'invalid_duplicate_object_id',
      expectedCodes: {ValidationIssueCode.duplicateObjectId},
      mutate: (json) {
        final objects = _objects(json);
        final duplicate = Map<String, dynamic>.from(
          _objectById(objects, 'crate_a'),
        )..['position'] = const {'x': 78.0, 'y': 380.0};
        objects.add(duplicate);
      },
    ),
    _runtimeFixture(
      'invalid_rotator_order',
      expectedCodes: {ValidationIssueCode.runtimeRotatorOrder},
      evidence: const PatternRuntimeEvidence(
        probeCount: 1,
        maxProbeCount: 1,
        shotCount: 2,
        maxShots: 2,
        rotatorApplicable: true,
        rotatorOrderViolation: true,
      ),
    ),
    _runtimeFixture(
      'invalid_soft_lock',
      expectedCodes: {ValidationIssueCode.runtimeSoftLock},
      evidence: const PatternRuntimeEvidence(
        probeCount: 4,
        maxProbeCount: 4,
        shotCount: 8,
        maxShots: 8,
        allRepresentativeInputsNoMovement: true,
        launchUnavailable: true,
      ),
    ),
  ];
}

InvalidPatternFixture _staticFixture(
  String name, {
  required Set<ValidationIssueCode> expectedCodes,
  required void Function(Map<String, dynamic> json) mutate,
}) {
  final json = _baseJson(name);
  mutate(json);
  final pattern = StagePattern.fromJson(json);
  return InvalidPatternFixture(
    name: name,
    stage: _stage(pattern),
    pattern: pattern,
    expectedCodes: expectedCodes,
  );
}

InvalidPatternFixture _runtimeFixture(
  String name, {
  required Set<ValidationIssueCode> expectedCodes,
  required PatternRuntimeEvidence evidence,
}) {
  final pattern = StagePattern.fromJson(_baseJson(name));
  return InvalidPatternFixture(
    name: name,
    stage: _stage(pattern),
    pattern: pattern,
    expectedCodes: expectedCodes,
    evidence: evidence,
  );
}

InvalidPatternFixture _actualRuntimeFixture(
  String name, {
  required Set<ValidationIssueCode> expectedCodes,
  required void Function(Map<String, dynamic> json) mutate,
}) {
  final json = _baseJson(name);
  mutate(json);
  final pattern = StagePattern.fromJson(json);
  return InvalidPatternFixture(
    name: name,
    stage: _stage(pattern),
    pattern: pattern,
    expectedCodes: expectedCodes,
    runtimeProbe: ShotResolverPatternRuntimeProbe(),
  );
}

Map<String, dynamic> _baseJson(String patternId) {
  final pattern = StagePattern.fromLevelDefinition(
    levels.first,
    patternId: patternId,
  );
  return Map<String, dynamic>.from(
    jsonDecode(jsonEncode(pattern.toJson())) as Map<String, dynamic>,
  );
}

StageDefinition _stage(StagePattern pattern) {
  return StageDefinition(
    stageId: 'validator_fixture_stage',
    title: '검증용 패턴',
    patterns: [pattern],
  );
}

List<Map<String, dynamic>> _objects(Map<String, dynamic> json) {
  return (json['objects'] as List).cast<Map<String, dynamic>>();
}

Map<String, dynamic> _objectById(
  List<Map<String, dynamic>> objects,
  String id,
) {
  return objects.firstWhere((object) => object['id'] == id);
}
