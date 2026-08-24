import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../simulation/shot_resolver.dart';
import 'aim_direction_quantizer.dart';

enum IntentAssistStrength { off, standard, comfortable }

class IntentAssistPolicy {
  const IntentAssistPolicy({
    this.preserveBoundaryIntent = false,
    this.preserveRawTrajectory = false,
  });

  factory IntentAssistPolicy.forStage(String? stageId) => switch (stageId) {
    'stage_chain_gate' ||
    'stage_balloon' ||
    'stage_drained' ||
    'stage_persistent' ||
    'stage_chain_score' => const IntentAssistPolicy(
      preserveBoundaryIntent: true,
      preserveRawTrajectory: true,
    ),
    _ => const IntentAssistPolicy(),
  };

  final bool preserveBoundaryIntent;
  final bool preserveRawTrajectory;
}

class IntentAssistDecision {
  const IntentAssistDecision({
    required this.rawInput,
    required this.appliedInput,
    required this.angleDeltaDegrees,
    required this.powerDelta,
    this.targetEntityId,
  });

  final ShotInput rawInput;
  final ShotInput appliedInput;
  final double angleDeltaDegrees;
  final double powerDelta;
  final String? targetEntityId;

  bool get adjusted => appliedInput.assistKind != ShotAssistKind.none;
  bool get targetSnapped =>
      appliedInput.assistKind == ShotAssistKind.targetSnap ||
      appliedInput.assistKind == ShotAssistKind.adaptiveTargetSnap;
}

/// 문자 그대로의 포인터 좌표보다 플레이어가 가리킨 가까운 물리 대상을
/// 우선한다. 후보도 반드시 실제 [ShotResolver]의 첫 사건으로 검증하므로
/// 벽을 통과하거나 다른 퍼즐 경로로 순간 이동하지 않는다.
class IntentAssistResolver {
  const IntentAssistResolver({this.shotResolver = const ShotResolver()});

  final ShotResolver shotResolver;

  IntentAssistDecision resolve({
    required GameState state,
    required ShotInput rawInput,
    IntentAssistStrength strength = IntentAssistStrength.standard,
    bool compactPointer = false,
    int repeatedNearMisses = 0,
    IntentAssistPolicy policy = const IntentAssistPolicy(),
  }) {
    final raw = rawInput.normalized();
    if (strength == IntentAssistStrength.off) {
      return IntentAssistDecision(
        rawInput: raw,
        appliedInput: raw,
        angleDeltaDegrees: 0,
        powerDelta: 0,
      );
    }

    final adaptive = repeatedNearMisses >= 2;
    final maxAngle =
        switch (strength) {
          IntentAssistStrength.off => 0,
          IntentAssistStrength.standard => compactPointer ? 4 : 3,
          IntentAssistStrength.comfortable => compactPointer ? 6 : 5,
        } +
        (adaptive ? 1 : 0);
    final maxPowerSteps =
        switch (strength) {
          IntentAssistStrength.off => 0,
          IntentAssistStrength.standard => 1,
          IntentAssistStrength.comfortable => 3,
        } +
        (adaptive ? 1 : 0);
    final holeForgiveness =
        switch (strength) {
          IntentAssistStrength.off => 0.0,
          IntentAssistStrength.standard => compactPointer ? 8.0 : 6.0,
          IntentAssistStrength.comfortable => compactPointer ? 12.0 : 10.0,
        } +
        (adaptive ? 2.0 : 0.0);
    if (policy.preserveRawTrajectory) {
      return _decision(raw, _preserveRawIntent(raw, holeForgiveness));
    }

    final stableDirection = quantizeAimDirection(raw.direction);
    final stablePower = _quantizePower(raw.power);
    var stable = ShotInput(
      direction: stableDirection,
      power: stablePower,
      equippedTrait: raw.equippedTrait,
      rawDirection: raw.direction,
      rawPower: raw.power,
      assistKind: _sameInput(raw, stableDirection, stablePower)
          ? ShotAssistKind.none
          : ShotAssistKind.stabilized,
      holeForgivenessRadius: holeForgiveness.clamp(0, 16).toDouble(),
    ).normalized();
    final rawResult = shotResolver.resolve(state, raw);
    final rawArrival = shotResolver.firstArrivalFromResult(rawResult);
    final stableResult = shotResolver.resolve(state, stable);
    final stableArrival = shotResolver.firstArrivalFromResult(stableResult);
    if (_isRealTarget(state, rawArrival.entityId)) {
      // 이미 기물을 향한 입력은 그 기물 자체가 플레이어 의도의 가장 강한
      // 증거다. 양자화가 첫 접촉을 바꾸면 원시 방향·힘을 보존한다.
      return rawArrival.entityId == stableArrival.entityId
          ? _decision(raw, stable)
          : _decision(raw, _preserveRawIntent(raw, holeForgiveness));
    }
    if (policy.preserveBoundaryIntent &&
        _isFieldBoundary(rawArrival.entityId)) {
      // 벽 반사는 핵심 퍼즐 입력이다. 경계 도착을 '아무 목표도 없음'으로
      // 오인해 가까운 기물로 돌리지 않고 미세 안정화까지만 허용한다.
      return rawArrival.entityId == stableArrival.entityId
          ? _decision(raw, stable)
          : _decision(raw, _preserveRawIntent(raw, holeForgiveness));
    }
    if (_isRealTarget(state, stableArrival.entityId) &&
        rawArrival.entityId != stableArrival.entityId) {
      stable = ShotInput(
        direction: stable.direction,
        power: stable.power,
        equippedTrait: stable.equippedTrait,
        rawDirection: stable.rawDirection,
        rawPower: stable.rawPower,
        assistKind: adaptive
            ? ShotAssistKind.adaptiveTargetSnap
            : ShotAssistKind.targetSnap,
        assistTargetId: stableArrival.entityId,
        holeForgivenessRadius: stable.holeForgivenessRadius,
      ).normalized();
      return _decision(raw, stable, targetEntityId: stableArrival.entityId);
    }
    if (stableResult.state.phase == GamePhase.success) {
      return _decision(raw, stable);
    }
    if (_isRealTarget(state, stableArrival.entityId)) {
      // 이미 플레이어가 실제 기물을 맞혔다면 다른 기물이나 더 좋은 해답으로
      // 돌리지 않는다. 힘·픽셀 흔들림 안정화만 적용한다.
      return _decision(raw, stable);
    }

    final candidates = <_Candidate>[];
    for (var angleStep = -maxAngle; angleStep <= maxAngle; angleStep++) {
      for (
        var powerStep = -maxPowerSteps;
        powerStep <= maxPowerSteps;
        powerStep++
      ) {
        if (angleStep == 0 && powerStep == 0) continue;
        final power = (stablePower + powerStep * 0.02)
            .clamp(0.12, 1.0)
            .toDouble();
        final direction = _rotateDegrees(stableDirection, angleStep.toDouble());
        final candidateInput = ShotInput(
          direction: direction,
          power: power,
          equippedTrait: raw.equippedTrait,
          rawDirection: raw.direction,
          rawPower: raw.power,
          assistKind: adaptive
              ? ShotAssistKind.adaptiveTargetSnap
              : ShotAssistKind.targetSnap,
          holeForgivenessRadius: holeForgiveness.clamp(0, 16).toDouble(),
        ).normalized();
        final result = shotResolver.resolve(state, candidateInput);
        final arrival = shotResolver.firstArrivalFromResult(result);
        final targetId = arrival.entityId;
        if (!_isRealTarget(state, targetId)) continue;
        final target = state.entityById(targetId!);
        if (target == null || !_isEligibleTarget(target)) continue;
        final appliedCandidate = ShotInput(
          direction: candidateInput.direction,
          power: candidateInput.power,
          equippedTrait: candidateInput.equippedTrait,
          rawDirection: candidateInput.rawDirection,
          rawPower: candidateInput.rawPower,
          assistKind: candidateInput.assistKind,
          assistTargetId: targetId,
          holeForgivenessRadius: candidateInput.holeForgivenessRadius,
        ).normalized();
        final candidate = _Candidate(
          input: appliedCandidate,
          targetId: targetId,
          angleStep: angleStep,
          powerStep: powerStep,
          priority: _targetPriority(target),
        );
        candidates.add(candidate);
      }
    }
    if (candidates.isEmpty) return _decision(raw, stable);
    candidates.sort((left, right) => left.compareTo(right));
    final best = candidates.first;
    if (candidates
        .skip(1)
        .any(
          (candidate) =>
              candidate.targetId != best.targetId &&
              candidate.hasSameIntentRank(best),
        )) {
      // 같은 거리의 서로 다른 목표가 있으면 시스템이 의도를 추측하지 않는다.
      return _decision(raw, stable);
    }
    return _decision(raw, best.input, targetEntityId: best.targetId);
  }

  IntentAssistDecision _decision(
    ShotInput raw,
    ShotInput applied, {
    String? targetEntityId,
  }) {
    return IntentAssistDecision(
      rawInput: raw,
      appliedInput: applied,
      angleDeltaDegrees: _signedAngleDegrees(raw.direction, applied.direction),
      powerDelta: applied.power - raw.power,
      targetEntityId: targetEntityId,
    );
  }

  bool _isRealTarget(GameState state, String? entityId) {
    if (entityId == null || entityId.startsWith('field_boundary_')) {
      return false;
    }
    return state.entityById(entityId) != null;
  }

  bool _isFieldBoundary(String? entityId) =>
      entityId?.startsWith('field_boundary_') ?? false;

  ShotInput _preserveRawIntent(ShotInput raw, double holeForgiveness) =>
      ShotInput(
        direction: raw.direction,
        power: raw.power,
        equippedTrait: raw.equippedTrait,
        rawDirection: raw.direction,
        rawPower: raw.power,
        assistKind: ShotAssistKind.stabilized,
        holeForgivenessRadius: holeForgiveness.clamp(0, 16).toDouble(),
      ).normalized();

  bool _isEligibleTarget(EntityState entity) {
    if (!entity.active || entity.id == 'active_ball') return false;
    if (entity.type == EntityType.gate && entity.open) return false;
    return entity.type != EntityType.hole || entity.hitRadius > 0;
  }

  int _targetPriority(EntityState entity) => switch (entity.type) {
    EntityType.hole => 0,
    EntityType.switchPad ||
    EntityType.powerSlider ||
    EntityType.rotatingReflector => 1,
    EntityType.balloon ||
    EntityType.bumper ||
    EntityType.stickySurface ||
    EntityType.crate ||
    EntityType.weight ||
    EntityType.spikeSource ||
    EntityType.ball => 2,
    EntityType.gate || EntityType.wall => 3,
  };

  double _quantizePower(double power) =>
      ((power / 0.02).round() * 0.02).clamp(0.12, 1.0).toDouble();

  bool _sameInput(ShotInput raw, Vec2 direction, double power) =>
      _signedAngleDegrees(raw.direction, direction).abs() < 0.0001 &&
      (raw.power - power).abs() < 0.0001;

  Vec2 _rotateDegrees(Vec2 direction, double degrees) {
    final angle =
        math.atan2(direction.y, direction.x) + degrees * math.pi / 180;
    return Vec2(math.cos(angle), math.sin(angle));
  }

  double _signedAngleDegrees(Vec2 from, Vec2 to) {
    final first = math.atan2(from.y, from.x);
    final second = math.atan2(to.y, to.x);
    var delta = (second - first) * 180 / math.pi;
    while (delta <= -180) {
      delta += 360;
    }
    while (delta > 180) {
      delta -= 360;
    }
    return delta;
  }
}

class _Candidate {
  const _Candidate({
    required this.input,
    required this.targetId,
    required this.angleStep,
    required this.powerStep,
    required this.priority,
  });

  final ShotInput input;
  final String targetId;
  final int angleStep;
  final int powerStep;
  final int priority;

  int compareTo(_Candidate other) {
    final angle = angleStep.abs().compareTo(other.angleStep.abs());
    if (angle != 0) return angle;
    final power = powerStep.abs().compareTo(other.powerStep.abs());
    if (power != 0) return power;
    final target = priority.compareTo(other.priority);
    if (target != 0) return target;
    final signedAngle = angleStep.compareTo(other.angleStep);
    if (signedAngle != 0) return signedAngle;
    final signedPower = powerStep.compareTo(other.powerStep);
    if (signedPower != 0) return signedPower;
    return targetId.compareTo(other.targetId);
  }

  bool hasSameIntentRank(_Candidate other) =>
      angleStep.abs() == other.angleStep.abs() &&
      powerStep.abs() == other.powerStep.abs();
}
