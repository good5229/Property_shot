import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../simulation/shot_resolver.dart';
import 'aim_direction_quantizer.dart';

enum IntentAssistStrength { off, standard, comfortable }

enum IntentAssistTargetKind { hole, mechanic, physical }

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
    'stage_rotating_reflector' ||
    'stage_property_shot' => const IntentAssistPolicy(
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
    this.targetKind,
    this.confidence = 0,
    this.resolvedResult,
  });

  final ShotInput rawInput;
  final ShotInput appliedInput;
  final double angleDeltaDegrees;
  final double powerDelta;
  final String? targetEntityId;
  final IntentAssistTargetKind? targetKind;

  /// 0은 단순 입력 안정화, 0보다 크면 후보군 안에서 목표가 얼마나
  /// 명확했는지를 뜻한다. 물리 결과나 성공 확률을 의미하지 않는다.
  final double confidence;
  final ShotResult? resolvedResult;

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
    ShotResult? rawResultHint,
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
    final holeForgiveness = forgivenessRadius(
      strength: strength,
      compactPointer: compactPointer,
      repeatedNearMisses: repeatedNearMisses,
    );
    if (policy.preserveRawTrajectory) {
      return _decision(
        raw,
        _preserveRawIntent(raw, holeForgiveness),
        resolvedResult: rawResultHint,
      );
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
      holeForgivenessRadius: holeForgiveness,
    ).normalized();
    final rawQuickArrival = shotResolver.quickFirstArrival(state, raw);
    final stableQuickArrival = shotResolver.quickFirstArrival(state, stable);
    final rawQuickTarget = _isRealTarget(state, rawQuickArrival.entityId);
    final rawQuickBoundary =
        policy.preserveBoundaryIntent &&
        _isFieldBoundary(rawQuickArrival.entityId);
    final stableQuickTarget = _isRealTarget(state, stableQuickArrival.entityId);

    // Only pay for complete physics when the straight first-arrival pass sees
    // evidence of a player target. An empty trajectory keeps the player's raw
    // direction, which is both cheaper and safer than silently quantizing an
    // intentional bank shot.
    if (rawQuickTarget || rawQuickBoundary || stableQuickTarget) {
      final rawResult = rawResultHint ?? shotResolver.resolve(state, raw);
      final rawArrival = shotResolver.firstArrivalFromResult(rawResult);
      final stableResult = shotResolver.resolve(state, stable);
      final stableArrival = shotResolver.firstArrivalFromResult(stableResult);
      if (rawResult.state.phase == GamePhase.success &&
          stableResult.state.phase != GamePhase.success) {
        return _decision(raw, _preserveRawIntent(raw, holeForgiveness));
      }
      if (_isRealTarget(state, rawArrival.entityId)) {
        return rawArrival.entityId == stableArrival.entityId
            ? _decision(raw, stable, resolvedResult: stableResult)
            : _decision(raw, _preserveRawIntent(raw, holeForgiveness));
      }
      if (policy.preserveBoundaryIntent &&
          _isFieldBoundary(rawArrival.entityId)) {
        return rawArrival.entityId == stableArrival.entityId
            ? _decision(raw, stable, resolvedResult: stableResult)
            : _decision(raw, _preserveRawIntent(raw, holeForgiveness));
      }
      if (_isRealTarget(state, stableArrival.entityId) &&
          rawArrival.entityId != stableArrival.entityId) {
        final target = state.entityById(stableArrival.entityId!);
        final targetKind = target == null ? null : _targetKind(target);
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
        return _decision(
          raw,
          stable,
          targetEntityId: stableArrival.entityId,
          targetKind: targetKind,
          confidence: 1,
          resolvedResult: stableResult,
        );
      }
      if (stableResult.state.phase == GamePhase.success ||
          _isRealTarget(state, stableArrival.entityId)) {
        return _decision(raw, stable, resolvedResult: stableResult);
      }
    }

    // A coarse pass may miss a corner contact. Confirm the raw first event
    // once before any nearby-target search so an input that already reaches a
    // real piece can never be redirected to a different puzzle answer.
    final rawFallbackResult = rawResultHint ?? shotResolver.resolve(state, raw);
    final rawFallbackArrival = shotResolver.firstArrivalFromResult(
      rawFallbackResult,
    );
    if (_isRealTarget(state, rawFallbackArrival.entityId) ||
        (policy.preserveBoundaryIntent &&
            _isFieldBoundary(rawFallbackArrival.entityId))) {
      return _decision(
        raw,
        _preserveRawIntent(raw, holeForgiveness),
        resolvedResult: _canReuseRawResult(raw, holeForgiveness)
            ? rawFallbackResult
            : null,
      );
    }

    // 최종 정렬의 앞 두 기준(각도 절댓값, 힘 절댓값) 순서로 후보를
    // 생성한다. 같은 순위 묶음에서 의도가 확정되면 더 먼 후보는 결과를
    // 바꿀 수 없으므로 즉시 끝낸다. 작은 포인터에서 최대 후보 전부를 물리
    // 시뮬레이션하던 비용을 줄이되 기존 우선순위와 모호성 규칙은 유지한다.
    for (var angleDistance = 0; angleDistance <= maxAngle; angleDistance++) {
      final angleSteps = angleDistance == 0
          ? const [0]
          : [-angleDistance, angleDistance];
      for (
        var powerDistance = 0;
        powerDistance <= maxPowerSteps;
        powerDistance++
      ) {
        if (angleDistance == 0 && powerDistance == 0) continue;
        final powerSteps = powerDistance == 0
            ? const [0]
            : [-powerDistance, powerDistance];
        final rankInputs =
            <({ShotInput input, int angleStep, int powerStep})>[];
        var quickTargetFound = false;
        for (final angleStep in angleSteps) {
          for (final powerStep in powerSteps) {
            final power = (stablePower + powerStep * 0.02)
                .clamp(0.12, 1.0)
                .toDouble();
            final direction = _rotateDegrees(
              stableDirection,
              angleStep.toDouble(),
            );
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
            rankInputs.add((
              input: candidateInput,
              angleStep: angleStep,
              powerStep: powerStep,
            ));
            final arrival = shotResolver.quickFirstArrival(
              state,
              candidateInput,
            );
            final targetId = arrival.entityId;
            if (!_isRealTarget(state, targetId)) continue;
            final target = state.entityById(targetId!);
            if (target == null || !_isEligibleTarget(target)) continue;
            final targetKind = _targetKind(target);
            final limits = _limitsFor(
              targetKind,
              maxAngle: maxAngle,
              maxPowerSteps: maxPowerSteps,
            );
            if (angleStep.abs() > limits.maxAngleDegrees ||
                powerStep.abs() > limits.maxPowerSteps) {
              continue;
            }
            quickTargetFound = true;
          }
        }
        if (!quickTargetFound) continue;
        final verified = <_Candidate>[];
        // The quick pass is only a rank-level filter. Once it sees any likely
        // target, exact-resolve every symmetric input in that rank so a coarse
        // sample can never hide an equally plausible competing target.
        for (final ranked in rankInputs) {
          final result = shotResolver.resolve(state, ranked.input);
          final arrival = shotResolver.firstArrivalFromResult(result);
          final targetId = arrival.entityId;
          if (!_isRealTarget(state, targetId)) continue;
          final target = state.entityById(targetId!);
          if (target == null || !_isEligibleTarget(target)) continue;
          final targetKind = _targetKind(target);
          final limits = _limitsFor(
            targetKind,
            maxAngle: maxAngle,
            maxPowerSteps: maxPowerSteps,
          );
          if (ranked.angleStep.abs() > limits.maxAngleDegrees ||
              ranked.powerStep.abs() > limits.maxPowerSteps) {
            continue;
          }
          final appliedCandidate = ShotInput(
            direction: ranked.input.direction,
            power: ranked.input.power,
            equippedTrait: ranked.input.equippedTrait,
            rawDirection: ranked.input.rawDirection,
            rawPower: ranked.input.rawPower,
            assistKind: ranked.input.assistKind,
            assistTargetId: targetId,
            holeForgivenessRadius: ranked.input.holeForgivenessRadius,
          ).normalized();
          verified.add(
            _Candidate(
              input: appliedCandidate,
              targetId: targetId,
              angleStep: ranked.angleStep,
              powerStep: ranked.powerStep,
              priority: _targetPriority(target),
              targetKind: targetKind,
              confidence: _candidateConfidence(
                angleStep: ranked.angleStep,
                powerStep: ranked.powerStep,
                limits: limits,
              ),
              result: result,
            ),
          );
        }
        if (verified.isEmpty) continue;
        verified.sort((left, right) => left.compareTo(right));
        final best = verified.first;
        if (verified
            .skip(1)
            .any(
              (candidate) =>
                  candidate.targetId != best.targetId &&
                  candidate.hasSameIntentRank(best),
            )) {
          // 같은 거리의 서로 다른 목표가 있으면 시스템이 의도를 추측하지 않는다.
          return _decision(
            raw,
            _preserveRawIntent(raw, holeForgiveness),
            resolvedResult: _canReuseRawResult(raw, holeForgiveness)
                ? rawFallbackResult
                : null,
          );
        }
        if (rawFallbackResult.state.phase == GamePhase.success &&
            best.result.state.phase != GamePhase.success) {
          return _decision(
            raw,
            _preserveRawIntent(raw, holeForgiveness),
            resolvedResult: _canReuseRawResult(raw, holeForgiveness)
                ? rawFallbackResult
                : null,
          );
        }
        return _decision(
          raw,
          best.input,
          targetEntityId: best.targetId,
          targetKind: best.targetKind,
          confidence: best.confidence,
          resolvedResult: best.result,
        );
      }
    }
    return _decision(
      raw,
      _preserveRawIntent(raw, holeForgiveness),
      resolvedResult: _canReuseRawResult(raw, holeForgiveness)
          ? rawFallbackResult
          : null,
    );
  }

  double forgivenessRadius({
    IntentAssistStrength strength = IntentAssistStrength.standard,
    bool compactPointer = false,
    int repeatedNearMisses = 0,
  }) {
    final adaptive = repeatedNearMisses >= 2;
    final radius =
        switch (strength) {
          IntentAssistStrength.off => 0.0,
          IntentAssistStrength.standard => compactPointer ? 8.0 : 6.0,
          IntentAssistStrength.comfortable => compactPointer ? 12.0 : 10.0,
        } +
        (adaptive ? 2.0 : 0.0);
    return radius.clamp(0, 16).toDouble();
  }

  bool _canReuseRawResult(ShotInput raw, double holeForgiveness) =>
      (raw.holeForgivenessRadius - holeForgiveness).abs() < 0.000001;

  IntentAssistDecision _decision(
    ShotInput raw,
    ShotInput applied, {
    String? targetEntityId,
    IntentAssistTargetKind? targetKind,
    double confidence = 0,
    ShotResult? resolvedResult,
  }) {
    return IntentAssistDecision(
      rawInput: raw,
      appliedInput: applied,
      angleDeltaDegrees: _signedAngleDegrees(raw.direction, applied.direction),
      powerDelta: applied.power - raw.power,
      targetEntityId: targetEntityId,
      targetKind: targetKind,
      confidence: confidence.clamp(0, 1).toDouble(),
      resolvedResult: resolvedResult,
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
    if (entity.type == EntityType.wall || entity.type == EntityType.gate) {
      return false;
    }
    return entity.type != EntityType.hole || entity.hitRadius > 0;
  }

  IntentAssistTargetKind _targetKind(EntityState entity) =>
      switch (entity.type) {
        EntityType.hole => IntentAssistTargetKind.hole,
        EntityType.switchPad ||
        EntityType.powerSlider ||
        EntityType.rotatingReflector ||
        EntityType.balloon => IntentAssistTargetKind.mechanic,
        _ => IntentAssistTargetKind.physical,
      };

  _TargetCorrectionLimits _limitsFor(
    IntentAssistTargetKind kind, {
    required int maxAngle,
    required int maxPowerSteps,
  }) => switch (kind) {
    // 홀은 최종 정답이므로 기믹보다 좁게 잡는다. 가장자리 여유가 별도로
    // 작동하기 때문에 큰 방향·힘 변경으로 자동 해결할 필요가 없다.
    IntentAssistTargetKind.hole => _TargetCorrectionLimits(
      maxAngleDegrees: math.min(maxAngle, 2),
      maxPowerSteps: math.min(maxPowerSteps, 1),
    ),
    // 스위치·발판·반사판은 플레이어가 실제로 가리킨 중간 목표이므로
    // 설정 상한 전체를 쓰되 첫 접촉 검증을 반드시 통과해야 한다.
    IntentAssistTargetKind.mechanic => _TargetCorrectionLimits(
      maxAngleDegrees: maxAngle,
      maxPowerSteps: maxPowerSteps,
    ),
    IntentAssistTargetKind.physical => _TargetCorrectionLimits(
      maxAngleDegrees: maxAngle,
      maxPowerSteps: math.min(maxPowerSteps, 2),
    ),
  };

  double _candidateConfidence({
    required int angleStep,
    required int powerStep,
    required _TargetCorrectionLimits limits,
  }) {
    final angleCost = limits.maxAngleDegrees == 0
        ? 0.0
        : angleStep.abs() / limits.maxAngleDegrees;
    final powerCost = limits.maxPowerSteps == 0
        ? 0.0
        : powerStep.abs() / limits.maxPowerSteps;
    return (1 - angleCost * 0.7 - powerCost * 0.3).clamp(0.05, 1);
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
    required this.targetKind,
    required this.confidence,
    required this.result,
  });

  final ShotInput input;
  final String targetId;
  final int angleStep;
  final int powerStep;
  final int priority;
  final IntentAssistTargetKind targetKind;
  final double confidence;
  final ShotResult result;

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

class _TargetCorrectionLimits {
  const _TargetCorrectionLimits({
    required this.maxAngleDegrees,
    required this.maxPowerSteps,
  });

  final int maxAngleDegrees;
  final int maxPowerSteps;
}
