// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/analysis/stage_chain_challenge.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import '../test/fixtures/stage_chain_score_patterns.dart';

const _resolver = ShotResolver();
const _analyzer = CreativeChainScoreAnalyzer();
const _challengeEvaluator = StageChainChallengeEvaluator();

void main(List<String> arguments) {
  final records = <Map<String, Object?>>[];
  final stage = generatedStageCatalog.stageById('stage_chain_score');
  for (final solution in stageChainScoreSolutions) {
    final pattern = stage.patternById(solution.patternId);
    final initial = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(7, productRules: true);
    records.add(
      _record(
        patternId: pattern.patternId,
        routeTag: '직접 클리어',
        initial: initial,
        shots: [_shot(solution.directDegree, solution.directPower)],
        parShots: pattern.parShots,
      ),
    );
    records.add(
      _record(
        patternId: pattern.patternId,
        routeTag: '고연쇄',
        initial: initial,
        shots: [
          _shot(solution.firstDegree, solution.firstPower),
          _shot(solution.secondDegree, solution.secondPower),
        ],
        parShots: pattern.parShots,
      ),
    );
  }

  final output = const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': 1,
    'stageId': 'stage_chain_score',
    'fixtures': records,
  });
  final file = File('harness_docs/qa/replays/stage8_chain_score_fixtures.json');
  if (arguments.contains('--check')) {
    if (!file.existsSync() || file.readAsStringSync().trim() != output.trim()) {
      stderr.writeln('8단계 리플레이 픽스처가 생성 결과와 다릅니다.');
      exitCode = 1;
      return;
    }
    print('8단계 리플레이 픽스처 동기화 확인: ${records.length}개');
    return;
  }
  file.parent.createSync(recursive: true);
  file.writeAsStringSync('$output\n');
  print('8단계 리플레이 픽스처 ${records.length}개 생성: ${file.path}');
}

Map<String, Object?> _record({
  required String patternId,
  required String routeTag,
  required GameState initial,
  required List<ReplayShotFixture> shots,
  required int parShots,
}) {
  final results = <ShotResult>[];
  var state = initial;
  for (final shot in shots) {
    final result = _resolver.resolve(state, shot.toInput());
    results.add(result);
    state = result.state;
  }
  final fixture = ReplayFixture(
    id: '${patternId}_${routeTag == '고연쇄' ? 'chain' : 'direct'}',
    stageIndex: 7,
    routeTag: routeTag,
    shots: shots,
    expectedFingerprints: [
      for (final result in results) shotResultFingerprint(result),
    ],
    expectedPhase: state.phase.name,
  );
  final analysis = _analyzer.analyzeReplay(
    fixture,
    results,
    parShots: parShots,
    optionalChallengeIds: CreativeChainChallengeId.all,
  );
  final challengeAchieved = _challengeEvaluator.isAchieved(
    patternId: patternId,
    analysis: analysis,
    results: results,
  );
  final repeatedResults = _resolve(initial, shots);
  final safety = stage8ReplaySafety(
    initial: initial,
    shots: shots,
    results: results,
    repeated: repeatedResults,
  );
  if (safety.values.whereType<bool>().contains(false)) {
    throw StateError('$patternId $routeTag 리플레이 안전성 검증에 실패했습니다: $safety');
  }
  return {
    'patternId': patternId,
    'routeKind': routeTag == '고연쇄' ? 'chain' : 'direct',
    'fixture': fixture.toJson(),
    'expectedScore': analysis.totalScore,
    'expectedReplaySignature': analysis.replaySignature,
    'expectedChallengeAchieved': challengeAchieved,
    'expectedBreakdown': _breakdown(analysis.breakdown),
    'expectedSafety': safety,
  };
}

List<ShotResult> _resolve(GameState initial, List<ReplayShotFixture> shots) {
  final results = <ShotResult>[];
  var state = initial;
  for (final shot in shots) {
    final result = _resolver.resolve(state, shot.toInput());
    results.add(result);
    state = result.state;
  }
  return results;
}

/// 대표 리플레이의 물리 안전성 증거를 현재 결과에서 다시 계산한다.
/// 픽스처 생성기와 회귀 테스트가 같은 판정 계약을 사용하되,
/// 테스트는 생성된 JSON을 그대로 신뢰하지 않고 이 함수를 재실행한다.
Map<String, Object> stage8ReplaySafety({
  required GameState initial,
  required List<ReplayShotFixture> shots,
  required List<ShotResult> results,
  required List<ShotResult> repeated,
}) {
  final wallPositions = {
    for (final entity in initial.entities)
      if (entity.type == EntityType.wall) entity.id: entity.position,
  };
  final fingerprints = results.map(shotResultFingerprint).toList();
  final repeatedFingerprints = repeated.map(shotResultFingerprint).toList();
  final states = [initial, ...results.map((result) => result.state)];
  final statesBefore = [
    initial,
    ...results.take(results.length - 1).map((result) => result.state),
  ];
  final fieldCheck = _dynamicFieldCheck(states, statesBefore, results);
  final overlapCheck = _terminalOverlapCheck(states, initial, results);
  final tunnelingCheck = _tunnelingCheck(statesBefore, shots, results);
  final captureCheck = _captureFollowUpCheck(results);
  final activeBallCheck = _activeBallCheck(results);
  final followUpCheck = _followUpShotCheck(shots, results);
  return {
    'deterministic': _sameStrings(fingerprints, repeatedFingerprints),
    'finite': results.every(_isFiniteResult),
    'noChainSafetyStop': results.every(
      (result) =>
          result.chainSafetyDiagnostics.isEmpty &&
          result.physicsEvents.every(
            (event) => event.kind != PhysicsEventKind.chainSafetyStop,
          ),
    ),
    'wallsUnchanged':
        states
            .skip(1)
            .every(
              (state) => wallPositions.entries.every(
                (entry) => state.entityById(entry.key)?.position == entry.value,
              ),
            ) &&
        results.every(
          (result) => result.moves
              .where((move) => _isWallId(move.entityId, wallPositions.keys))
              .every(
                (move) =>
                    move.from.distanceTo(move.to) <= _safetyEpsilon &&
                    move.path.every(
                      (point) => point.distanceTo(move.from) <= _safetyEpsilon,
                    ),
              ),
        ),
    'uniqueEntityIds': states.every((state) {
      final ids = state.entities.map((entity) => entity.id).toList();
      return ids.toSet().length == ids.length;
    }),
    'dynamicObjectsInField': fieldCheck.safe,
    'initialNoForbiddenOverlaps': overlapCheck.initialSafe,
    'terminalNoForbiddenOverlaps': overlapCheck.terminalSafe,
    'noHighSpeedTunneling': tunnelingCheck.safe,
    'capturedBallsHaveNoFollowUp': captureCheck.safe,
    'nonSuccessShotsHaveActiveBall': activeBallCheck.safe,
    'multiShotNoSoftlock':
        activeBallCheck.safe &&
        followUpCheck.safe &&
        _hasConsistentShotProgress(initial, results),
    'terminalSuccess': results.last.state.phase == GamePhase.success,
    'shotCount': results.length,
    'physicsEventCount': results.fold<int>(
      0,
      (sum, result) => sum + result.physicsEvents.length,
    ),
    'safetyEvidence': {
      'checkedStateCount': states.length,
      'dynamicObjectCount': fieldCheck.dynamicObjectCount,
      'checkedMovementSegmentCount': fieldCheck.movementSegmentCount,
      'tunnelingCandidateCount': tunnelingCheck.candidateCount,
      if (fieldCheck.firstOutside != null)
        'firstFieldExit': fieldCheck.firstOutside,
      if (fieldCheck.firstMissingMover != null)
        'firstMissingMover': fieldCheck.firstMissingMover,
      if (overlapCheck.firstInitialPair != null)
        'firstInitialOverlap': overlapCheck.firstInitialPair,
      if (overlapCheck.firstTerminalPair != null)
        'firstTerminalOverlap': overlapCheck.firstTerminalPair,
      if (tunnelingCheck.firstUncovered != null)
        'firstTunnelingCandidate': tunnelingCheck.firstUncovered,
      'capturedBallCount': captureCheck.captureCount,
      'nonSuccessShotCount': activeBallCheck.nonSuccessShotCount,
      'verifiedFollowUpShotCount': followUpCheck.verifiedShotCount,
      if (followUpCheck.firstFailure != null)
        'firstFollowUpFailure': followUpCheck.firstFailure,
      'terminalWallContactIds': overlapCheck.terminalWallContacts.toList()
        ..sort(),
      'terminalBallId': 'spent_ball_${initial.shotCount + results.length}',
    },
  };
}

const _safetyEpsilon = 0.001;
const _tunnelingSampleDistance = 1.25;
const _terminalContactTolerance = 0.75;

class _FieldCheck {
  const _FieldCheck({
    required this.safe,
    required this.dynamicObjectCount,
    required this.movementSegmentCount,
    this.firstOutside,
    this.firstMissingMover,
  });

  final bool safe;
  final int dynamicObjectCount;
  final int movementSegmentCount;
  final String? firstOutside;
  final String? firstMissingMover;
}

class _OverlapCheck {
  const _OverlapCheck({
    required this.initialSafe,
    required this.terminalSafe,
    this.firstInitialPair,
    this.firstTerminalPair,
    this.terminalWallContacts = const {},
  });

  final bool initialSafe;
  final bool terminalSafe;
  final String? firstInitialPair;
  final String? firstTerminalPair;
  final Set<String> terminalWallContacts;
}

class _TunnelingCheck {
  const _TunnelingCheck({
    required this.safe,
    required this.candidateCount,
    this.firstUncovered,
  });

  final bool safe;
  final int candidateCount;
  final String? firstUncovered;
}

class _CaptureCheck {
  const _CaptureCheck({required this.safe, required this.captureCount});

  final bool safe;
  final int captureCount;
}

class _ActiveBallCheck {
  const _ActiveBallCheck({
    required this.safe,
    required this.nonSuccessShotCount,
  });

  final bool safe;
  final int nonSuccessShotCount;
}

class _FollowUpShotCheck {
  const _FollowUpShotCheck({
    required this.safe,
    required this.verifiedShotCount,
    this.firstFailure,
  });

  final bool safe;
  final int verifiedShotCount;
  final String? firstFailure;
}

_FieldCheck _dynamicFieldCheck(
  List<GameState> states,
  List<GameState> statesBefore,
  List<ShotResult> results,
) {
  var safe = true;
  var dynamicObjectCount = 0;
  var movementSegmentCount = 0;
  String? firstOutside;
  String? firstMissingMover;
  for (final state in states) {
    for (final entity in state.entities.where(_isDynamic)) {
      dynamicObjectCount++;
      final inside = _insideField(entity, entity.position);
      if (!inside) {
        firstOutside ??=
            'state=${state.shotCount} id=${entity.id} '
            'type=${entity.type.name} position=${entity.position} '
            'size=${entity.size} scale=${entity.hitboxScale}';
      }
      safe = safe && inside;
    }
  }
  for (var shotIndex = 0; shotIndex < results.length; shotIndex++) {
    final before = statesBefore[shotIndex];
    final result = results[shotIndex];
    final activeBall = before.entityById('active_ball');
    if (activeBall != null) {
      final points = result.path;
      movementSegmentCount += math.max(0, points.length - 1);
      for (final point in points) {
        final inside = _insideField(activeBall, point);
        if (!inside) {
          firstOutside ??=
              'path shot=${before.shotCount + 1} '
              'id=active_ball point=$point';
        }
        safe = safe && inside;
      }
    } else {
      safe = false;
    }
    for (final move in result.moves) {
      if (_isFieldBoundaryId(move.entityId)) continue;
      final mover =
          before.entityById(move.entityId) ??
          result.state.entityById(move.entityId);
      final points = move.path.length >= 2 ? move.path : [move.from, move.to];
      movementSegmentCount += math.max(0, points.length - 1);
      if (mover == null) {
        firstMissingMover ??=
            'shot=${before.shotCount + 1} id=${move.entityId}';
        safe = false;
        continue;
      }
      for (final point in points) {
        final inside = _insideField(mover, point);
        if (!inside) {
          firstOutside ??=
              'move shot=${before.shotCount + 1} '
              'id=${move.entityId} point=$point';
        }
        safe = safe && inside;
      }
    }
  }
  return _FieldCheck(
    safe: safe,
    dynamicObjectCount: dynamicObjectCount,
    movementSegmentCount: movementSegmentCount,
    firstOutside: firstOutside,
    firstMissingMover: firstMissingMover,
  );
}

_OverlapCheck _terminalOverlapCheck(
  List<GameState> states,
  GameState initial,
  List<ShotResult> results,
) {
  final terminalWallContacts = <String>{};
  String? firstTerminalPair;
  for (var index = 0; index < results.length; index++) {
    final state = states[index + 1];
    final ballId = 'spent_ball_${initial.shotCount + index + 1}';
    final allowedPairs = <String>{};
    for (final impact in results[index].impacts) {
      if (impact.entityType != EntityType.wall ||
          impact.sourceEntityId != 'active_ball') {
        continue;
      }
      final ball = state.entityById(ballId);
      final wall = state.entityById(impact.entityId);
      if (ball == null ||
          wall == null ||
          _penetrationDepth(ball, wall) > _terminalContactTolerance) {
        continue;
      }
      final pair = '$ballId:${impact.entityId}';
      allowedPairs.add(pair);
      terminalWallContacts.add(pair);
    }
    firstTerminalPair ??= _firstForbiddenOverlap(
      state,
      allowedPairs: allowedPairs,
    );
  }
  return _OverlapCheck(
    initialSafe: _hasNoForbiddenOverlaps(states.first),
    terminalSafe: firstTerminalPair == null,
    firstInitialPair: _firstForbiddenOverlap(states.first),
    firstTerminalPair: firstTerminalPair,
    terminalWallContacts: terminalWallContacts,
  );
}

_TunnelingCheck _tunnelingCheck(
  List<GameState> statesBefore,
  List<ReplayShotFixture> shots,
  List<ShotResult> results,
) {
  var safe = true;
  var candidateCount = 0;
  String? firstUncovered;
  for (var shotIndex = 0; shotIndex < results.length; shotIndex++) {
    final before = statesBefore[shotIndex];
    final result = results[shotIndex];
    final mover = before.entityById('active_ball');
    if (mover == null) {
      safe = false;
      continue;
    }
    final activeCheck = _checkPathForTunneling(
      result.path,
      mover,
      before.entities,
      result,
      sourceId: 'active_ball',
    );
    safe = safe && activeCheck.safe;
    candidateCount += activeCheck.candidateCount;
    firstUncovered ??= activeCheck.firstUncovered;
    for (final move in result.moves) {
      if (_isFieldBoundaryId(move.entityId)) continue;
      final moveMover =
          before.entityById(move.entityId) ??
          result.state.entityById(move.entityId);
      if (moveMover == null) {
        safe = false;
        continue;
      }
      final points = move.path.length >= 2 ? move.path : [move.from, move.to];
      final moveCheck = _checkPathForTunneling(
        points,
        moveMover,
        before.entities,
        result,
        sourceId: move.entityId,
      );
      safe = safe && moveCheck.safe;
      candidateCount += moveCheck.candidateCount;
      firstUncovered ??= moveCheck.firstUncovered;
    }
  }
  // 입력 수와 결과 수가 다르면 다중 발사 안전성을 입증할 수 없다.
  if (shots.length != results.length) safe = false;
  return _TunnelingCheck(
    safe: safe,
    candidateCount: candidateCount,
    firstUncovered: firstUncovered,
  );
}

_TunnelingCheck _checkPathForTunneling(
  List<Vec2> points,
  EntityState mover,
  List<EntityState> entities,
  ShotResult result, {
  required String sourceId,
}) {
  var safe = true;
  var candidateCount = 0;
  String? firstUncovered;
  for (var segmentIndex = 0; segmentIndex + 1 < points.length; segmentIndex++) {
    final from = points[segmentIndex];
    final to = points[segmentIndex + 1];
    final distance = from.distanceTo(to);
    if (distance <= _safetyEpsilon) continue;
    final samples = math.max(2, (distance / _tunnelingSampleDistance).ceil());
    for (final target in entities) {
      if (!_isTunnelingTarget(target, mover.id)) continue;
      final passedThrough = _interiorSampleOverlaps(
        from,
        to,
        samples,
        mover,
        target,
      );
      if (!passedThrough) continue;
      candidateCount++;
      final hasImpact = result.impacts.any(
        (impact) =>
            impact.sourceEntityId == sourceId && impact.entityId == target.id,
      );
      final existingBallCapture =
          target.type == EntityType.hole &&
          result.events.contains('existing_ball_hole_entered');
      final hasSliderActivation =
          target.type == EntityType.powerSlider &&
          result.powerSliderActivations.any(
            (activation) =>
                activation.sourceEntityId == sourceId &&
                activation.sliderEntityId == target.id,
          );
      if (!hasImpact && !existingBallCapture && !hasSliderActivation) {
        firstUncovered ??=
            'source=$sourceId target=${target.id} '
            'type=${target.type.name} resultShot=${result.state.shotCount}';
        safe = false;
      }
    }
  }
  return _TunnelingCheck(
    safe: safe,
    candidateCount: candidateCount,
    firstUncovered: firstUncovered,
  );
}

_CaptureCheck _captureFollowUpCheck(List<ShotResult> results) {
  var safe = true;
  var captureCount = 0;
  for (final result in results) {
    final captures = result.impacts.where(
      (impact) => impact.entityType == EntityType.hole,
    );
    for (final capture in captures) {
      captureCount++;
      final capturedId = capture.sourceEntityId;
      final captureEventIndex = result.physicsEvents.indexWhere(
        (event) =>
            event.kind == PhysicsEventKind.impact &&
            event.targetEntityId == capture.entityId &&
            event.sourceEntityId == capturedId &&
            event.pathIndex == capture.pathIndex,
      );
      final hasFollowUp =
          captureEventIndex < 0 ||
          result.physicsEvents.skip(captureEventIndex + 1).any((event) {
            if (event.kind == PhysicsEventKind.move &&
                event.targetEntityId == capturedId) {
              return true;
            }
            return event.kind == PhysicsEventKind.impact &&
                event.pathIndex >= capture.pathIndex &&
                (event.sourceEntityId == capturedId ||
                    event.targetEntityId == capturedId);
          });
      if (hasFollowUp) safe = false;
    }
  }
  return _CaptureCheck(safe: safe, captureCount: captureCount);
}

_ActiveBallCheck _activeBallCheck(List<ShotResult> results) {
  var safe = true;
  var nonSuccessShotCount = 0;
  for (final result in results) {
    if (result.state.phase == GamePhase.success) continue;
    nonSuccessShotCount++;
    final activeBall = result.state.entityById('active_ball');
    if (activeBall == null ||
        !activeBall.active ||
        !activeBall.movable ||
        result.state.phase != GamePhase.planning) {
      safe = false;
    }
  }
  return _ActiveBallCheck(safe: safe, nonSuccessShotCount: nonSuccessShotCount);
}

_FollowUpShotCheck _followUpShotCheck(
  List<ReplayShotFixture> shots,
  List<ShotResult> results,
) {
  var verifiedShotCount = 0;
  String? firstFailure;
  for (var index = 0; index < results.length; index++) {
    final current = results[index];
    if (current.state.phase == GamePhase.success) continue;
    if (index + 1 >= shots.length || index + 1 >= results.length) {
      firstFailure ??= 'shot=$index 다음 대표 입력이 없습니다.';
      continue;
    }
    final expectedNext = results[index + 1];
    final replayedNext = _resolver.resolve(
      current.state,
      shots[index + 1].toInput(),
    );
    final valid =
        _isFiniteResult(replayedNext) &&
        replayedNext.chainSafetyDiagnostics.isEmpty &&
        replayedNext.physicsEvents.every(
          (event) => event.kind != PhysicsEventKind.chainSafetyStop,
        ) &&
        replayedNext.state.shotCount == current.state.shotCount + 1 &&
        shotResultFingerprint(replayedNext) ==
            shotResultFingerprint(expectedNext);
    if (!valid) {
      firstFailure ??= 'shot=$index 다음 대표 입력 재생 결과가 일치하지 않습니다.';
      continue;
    }
    verifiedShotCount++;
  }
  final requiredCount = results
      .where((result) => result.state.phase != GamePhase.success)
      .length;
  return _FollowUpShotCheck(
    safe: firstFailure == null && verifiedShotCount == requiredCount,
    verifiedShotCount: verifiedShotCount,
    firstFailure: firstFailure,
  );
}

bool _hasConsistentShotProgress(GameState initial, List<ShotResult> results) {
  for (var index = 0; index < results.length; index++) {
    if (results[index].state.shotCount != initial.shotCount + index + 1) {
      return false;
    }
  }
  return true;
}

bool _isDynamic(EntityState entity) =>
    entity.active &&
    entity.movable &&
    entity.type != EntityType.wall &&
    !_isTerminalSettled(entity);

bool _isTerminalSettled(EntityState entity) =>
    entity.visualState == 'scored' ||
    entity.visualState == 'captured' ||
    entity.visualState == 'hole_captured';

bool _isFieldBoundaryId(String id) => id.startsWith('field_boundary_');

bool _isWallId(String id, Iterable<String> wallIds) =>
    _isFieldBoundaryId(id) || wallIds.contains(id);

bool _insideField(EntityState entity, Vec2 position) {
  if (entity.isCircle) {
    final radius = entity.hitRadius;
    return position.x - radius >= -_safetyEpsilon &&
        position.y - radius >= -_safetyEpsilon &&
        position.x + radius <= logicalSize.x + _safetyEpsilon &&
        position.y + radius <= logicalSize.y + _safetyEpsilon;
  }
  final halfWidth = entity.size.x * entity.hitboxScale / 2;
  final halfHeight = entity.size.y * entity.hitboxScale / 2;
  return position.x - halfWidth >= -_safetyEpsilon &&
      position.y - halfHeight >= -_safetyEpsilon &&
      position.x + halfWidth <= logicalSize.x + _safetyEpsilon &&
      position.y + halfHeight <= logicalSize.y + _safetyEpsilon;
}

bool _isTunnelingTarget(EntityState entity, String moverId) {
  if (!entity.active || entity.id == moverId) return false;
  if (entity.type == EntityType.gate && entity.open) return false;
  return entity.type == EntityType.hole ||
      entity.type == EntityType.powerSlider ||
      entity.solid;
}

bool _interiorSampleOverlaps(
  Vec2 from,
  Vec2 to,
  int samples,
  EntityState mover,
  EntityState target,
) {
  for (var index = 1; index < samples; index++) {
    final progress = index / samples;
    final point = Vec2(
      from.x + (to.x - from.x) * progress,
      from.y + (to.y - from.y) * progress,
    );
    if (_overlapsAt(mover, point, target, target.position)) return true;
  }
  return false;
}

bool _hasNoForbiddenOverlaps(
  GameState state, {
  Set<String> allowedPairs = const {},
}) {
  return _firstForbiddenOverlap(state, allowedPairs: allowedPairs) == null;
}

String? _firstForbiddenOverlap(
  GameState state, {
  Set<String> allowedPairs = const {},
}) {
  final objects = state.entities.where(_isForbiddenOverlapObject).toList();
  for (var firstIndex = 0; firstIndex < objects.length; firstIndex++) {
    for (
      var secondIndex = firstIndex + 1;
      secondIndex < objects.length;
      secondIndex++
    ) {
      final first = objects[firstIndex];
      final second = objects[secondIndex];
      final pair = '${first.id}:${second.id}';
      final reversePair = '${second.id}:${first.id}';
      if (allowedPairs.contains(pair) || allowedPairs.contains(reversePair)) {
        continue;
      }
      if (_overlapsAt(first, first.position, second, second.position)) {
        return '${first.id}:${second.id}';
      }
    }
  }
  return null;
}

bool _isForbiddenOverlapObject(EntityState entity) {
  if (!entity.active || entity.type == EntityType.hole) return false;
  if (_isTerminalSettled(entity)) return false;
  if (entity.type == EntityType.powerSlider) return false;
  if (entity.type == EntityType.gate && entity.open) return false;
  return entity.solid || entity.type == EntityType.ball;
}

bool _overlapsAt(
  EntityState first,
  Vec2 firstPosition,
  EntityState second,
  Vec2 secondPosition,
) {
  if (first.isCircle && second.isCircle) {
    return firstPosition.distanceTo(secondPosition) <
        first.hitRadius + second.hitRadius - _safetyEpsilon;
  }
  if (first.isCircle) {
    return _circleOverlapsRect(
      firstPosition,
      first.hitRadius,
      _rectAt(second, secondPosition),
    );
  }
  if (second.isCircle) {
    return _circleOverlapsRect(
      secondPosition,
      second.hitRadius,
      _rectAt(first, firstPosition),
    );
  }
  final firstRect = _rectAt(first, firstPosition);
  final secondRect = _rectAt(second, secondPosition);
  return firstRect.left < secondRect.right - _safetyEpsilon &&
      firstRect.right > secondRect.left + _safetyEpsilon &&
      firstRect.top < secondRect.bottom - _safetyEpsilon &&
      firstRect.bottom > secondRect.top + _safetyEpsilon;
}

double _penetrationDepth(EntityState first, EntityState second) {
  if (first.isCircle && second.isCircle) {
    return math.max(
      0,
      first.hitRadius +
          second.hitRadius -
          first.position.distanceTo(second.position),
    );
  }
  if (first.isCircle) {
    return _circleRectPenetration(
      first.position,
      first.hitRadius,
      _rectAt(second, second.position),
    );
  }
  if (second.isCircle) {
    return _circleRectPenetration(
      second.position,
      second.hitRadius,
      _rectAt(first, first.position),
    );
  }
  final firstRect = _rectAt(first, first.position);
  final secondRect = _rectAt(second, second.position);
  final horizontal = math.min(
    firstRect.right - secondRect.left,
    secondRect.right - firstRect.left,
  );
  final vertical = math.min(
    firstRect.bottom - secondRect.top,
    secondRect.bottom - firstRect.top,
  );
  return math.max(0, math.min(horizontal, vertical));
}

double _circleRectPenetration(Vec2 center, double radius, _Rect rect) {
  final nearestX = center.x.clamp(rect.left, rect.right).toDouble();
  final nearestY = center.y.clamp(rect.top, rect.bottom).toDouble();
  final distance = center.distanceTo(Vec2(nearestX, nearestY));
  if (distance > _safetyEpsilon) return math.max(0, radius - distance);
  final insideDistance = math.min(
    math.min(center.x - rect.left, rect.right - center.x),
    math.min(center.y - rect.top, rect.bottom - center.y),
  );
  return radius + math.max(0, insideDistance);
}

class _Rect {
  const _Rect(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;
}

_Rect _rectAt(EntityState entity, Vec2 position) {
  final halfWidth = entity.size.x * entity.hitboxScale / 2;
  final halfHeight = entity.size.y * entity.hitboxScale / 2;
  return _Rect(
    position.x - halfWidth,
    position.y - halfHeight,
    position.x + halfWidth,
    position.y + halfHeight,
  );
}

bool _circleOverlapsRect(Vec2 center, double radius, _Rect rect) {
  final nearestX = center.x.clamp(rect.left, rect.right).toDouble();
  final nearestY = center.y.clamp(rect.top, rect.bottom).toDouble();
  return center.distanceTo(Vec2(nearestX, nearestY)) < radius - _safetyEpsilon;
}

bool _sameStrings(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _isFiniteResult(ShotResult result) {
  bool vectorFinite(dynamic value) =>
      value.x.isFinite == true && value.y.isFinite == true;
  return result.path.every(vectorFinite) &&
      result.moves.every(
        (move) => vectorFinite(move.from) && vectorFinite(move.to),
      ) &&
      result.impacts.every(
        (impact) =>
            vectorFinite(impact.position) &&
            vectorFinite(impact.normal) &&
            impact.strength.isFinite,
      ) &&
      result.physicsEvents.every(
        (event) =>
            vectorFinite(event.position) &&
            vectorFinite(event.normal) &&
            vectorFinite(event.resultingVelocity) &&
            event.impulse.isFinite &&
            (event.remainingDistance?.isFinite ?? true) &&
            (event.remainingSpeed?.isFinite ?? true),
      );
}

Map<String, int> _breakdown(CreativeChainScoreBreakdown value) {
  return {
    'totalPoints': value.totalPoints,
    'causalDepth': value.causalDepth,
    'causalEventCount': value.causalEventCount,
    'distinctEntityTypes': value.distinctEntityTypes,
    'wallReflectionCount': value.wallReflectionCount,
    'pastBallCount': value.pastBallCount,
    'powerSliderCount': value.powerSliderCount,
    'movedEntityCount': value.movedEntityCount,
    'preparationShotCount': value.preparationShotCount,
    'qualifiedImpactCount': value.qualifiedImpactCount,
  };
}

ReplayShotFixture _shot(int degree, double power) {
  return ReplayShotFixture(angleRadians: degree * math.pi / 180, power: power);
}
