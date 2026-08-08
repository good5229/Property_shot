import 'dart:convert';
import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
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
    _mutatedRuntimeFixture(
      'invalid_wall_moves',
      expectedCodes: {ValidationIssueCode.runtimeWallMoved},
      resolver: _WallMovingResolver(),
    ),
    _mutatedRuntimeFixture(
      'invalid_infinite_bounce',
      expectedCodes: {ValidationIssueCode.runtimeInfiniteBounce},
      resolver: const _SafetyStopResolver(),
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
    _mutatedRuntimeFixture(
      'invalid_non_deterministic',
      expectedCodes: {ValidationIssueCode.runtimeNonDeterministic},
      resolver: _NonDeterministicResolver(),
    ),
    _mutatedRuntimeFixture(
      'invalid_hole_pass_through',
      expectedCodes: {ValidationIssueCode.runtimeHolePassThrough},
      resolver: const _HolePassThroughResolver(),
      representativeInputs: [
        ShotInput(direction: _directionFor(62), power: 0.70),
      ],
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

InvalidPatternFixture _mutatedRuntimeFixture(
  String name, {
  required Set<ValidationIssueCode> expectedCodes,
  required ShotResolver resolver,
  List<ShotInput> representativeInputs =
      ShotResolverPatternRuntimeProbe.defaultRepresentativeInputs,
}) {
  final pattern = StagePattern.fromJson(_baseJson(name));
  return InvalidPatternFixture(
    name: name,
    stage: _stage(pattern),
    pattern: pattern,
    expectedCodes: expectedCodes,
    runtimeProbe: ShotResolverPatternRuntimeProbe(
      shotResolver: resolver,
      representativeInputs: representativeInputs,
      maxProbeCount: representativeInputs.length,
      maxShots: representativeInputs.length * 2,
    ),
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

Vec2 _directionFor(int degree) {
  final radians = degree * math.pi / 180;
  return Vec2(math.cos(radians), math.sin(radians));
}

class _WallMovingResolver extends ShotResolver {
  _WallMovingResolver();

  @override
  ShotResult resolve(GameState state, ShotInput rawInput) {
    final result = super.resolve(state, rawInput);
    final movedState = result.state.copyWith(
      entities: [
        for (final entity in result.state.entities)
          if (entity.type.name == 'wall')
            entity.copyWith(position: entity.position + const Vec2(1, 0))
          else
            entity,
      ],
    );
    return _copyResult(result, state: movedState);
  }
}

class _NonDeterministicResolver extends ShotResolver {
  _NonDeterministicResolver();

  var _callCount = 0;

  @override
  ShotResult resolve(GameState state, ShotInput rawInput) {
    final result = super.resolve(state, rawInput);
    _callCount++;
    if (_callCount.isOdd) return result;
    return _copyResult(
      result,
      state: result.state.copyWith(message: '${result.state.message} 변이'),
    );
  }
}

class _HolePassThroughResolver extends ShotResolver {
  const _HolePassThroughResolver();

  @override
  ShotResult resolve(GameState state, ShotInput rawInput) {
    final result = super.resolve(state, rawInput);
    return _copyResult(
      result,
      events: result.events
          .where((event) => event != 'hole_entered')
          .toList(growable: false),
    );
  }
}

class _SafetyStopResolver extends ShotResolver {
  const _SafetyStopResolver();

  @override
  ShotResult resolve(GameState state, ShotInput rawInput) {
    final result = super.resolve(state, rawInput);
    return _copyResult(
      result,
      events: [...result.events, 'chain_safety_stop'],
      chainSafetyDiagnostics: [
        ...result.chainSafetyDiagnostics,
        const ChainSafetyDiagnostic(
          targetEntityId: 'active_ball',
          pathIndex: 0,
          depth: 1,
          iterations: 1,
          remainingDistance: 1,
          remainingSpeed: 1,
        ),
      ],
    );
  }
}

ShotResult _copyResult(
  ShotResult result, {
  GameState? state,
  List<String>? events,
  List<ChainSafetyDiagnostic>? chainSafetyDiagnostics,
}) {
  return ShotResult(
    state: state ?? result.state,
    path: result.path,
    events: events ?? result.events,
    moves: result.moves,
    impacts: result.impacts,
    powerSliderActivations: result.powerSliderActivations,
    reflectorRotations: result.reflectorRotations,
    physicsEvents: result.physicsEvents,
    chainSafetyDiagnostics:
        chainSafetyDiagnostics ?? result.chainSafetyDiagnostics,
  );
}
