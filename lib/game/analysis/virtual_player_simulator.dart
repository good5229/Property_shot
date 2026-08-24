import 'dart:math' as math;

import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../input/intent_assist_resolver.dart';
import '../simulation/shot_resolver.dart';

typedef VirtualPlayerMechanicCheck = bool Function(List<ShotResult> results);

class VirtualPlayerPersona {
  const VirtualPlayerPersona({
    required this.id,
    required this.label,
    required this.angleSigmaDegrees,
    required this.powerSigma,
    this.compactPointer = false,
    this.repeatedNearMisses = 0,
  });

  final String id;
  final String label;
  final double angleSigmaDegrees;
  final double powerSigma;
  final bool compactPointer;
  final int repeatedNearMisses;

  void validate() {
    if (id.isEmpty || label.isEmpty) {
      throw ArgumentError('가상 플레이어 식별자와 이름은 비어 있을 수 없습니다.');
    }
    if (!angleSigmaDegrees.isFinite ||
        angleSigmaDegrees < 0 ||
        angleSigmaDegrees > 45) {
      throw ArgumentError.value(
        angleSigmaDegrees,
        'angleSigmaDegrees',
        '0~45 범위의 유한한 값이어야 합니다.',
      );
    }
    if (!powerSigma.isFinite || powerSigma < 0 || powerSigma > 0.5) {
      throw ArgumentError.value(
        powerSigma,
        'powerSigma',
        '0~0.5 범위의 유한한 값이어야 합니다.',
      );
    }
    if (repeatedNearMisses < 0 || repeatedNearMisses > 20) {
      throw ArgumentError.value(
        repeatedNearMisses,
        'repeatedNearMisses',
        '0~20 범위여야 합니다.',
      );
    }
  }
}

const virtualPlayerPersonas = <VirtualPlayerPersona>[
  VirtualPlayerPersona(
    id: 'mobile_novice',
    label: '모바일 초보',
    angleSigmaDegrees: 5.5,
    powerSigma: 0.06,
    compactPointer: true,
    repeatedNearMisses: 2,
  ),
  VirtualPlayerPersona(
    id: 'typical_pc',
    label: '일반 PC',
    angleSigmaDegrees: 3,
    powerSigma: 0.035,
  ),
  VirtualPlayerPersona(
    id: 'precision_player',
    label: '정밀 조작',
    angleSigmaDegrees: 1.2,
    powerSigma: 0.015,
  ),
  VirtualPlayerPersona(
    id: 'keyboard_accessibility',
    label: '키보드·접근성',
    angleSigmaDegrees: 2,
    powerSigma: 0.025,
  ),
];

class VirtualPlayerScenario {
  VirtualPlayerScenario({
    required this.id,
    required this.initialState,
    required Iterable<ShotInput> canonicalShots,
    this.mechanicCheck,
    this.assistPolicy = const IntentAssistPolicy(),
  }) : canonicalShots = List.unmodifiable(canonicalShots) {
    if (id.isEmpty) throw ArgumentError.value(id, 'id', '비어 있을 수 없습니다.');
    if (this.canonicalShots.isEmpty) {
      throw ArgumentError.value(
        canonicalShots,
        'canonicalShots',
        '최소 한 발이 필요합니다.',
      );
    }
    for (final input in this.canonicalShots) {
      input.normalized();
    }
  }

  final String id;
  final GameState initialState;
  final List<ShotInput> canonicalShots;
  final VirtualPlayerMechanicCheck? mechanicCheck;
  final IntentAssistPolicy assistPolicy;
}

class VirtualPlayerSimulationResult {
  const VirtualPlayerSimulationResult({
    required this.scenarioId,
    required this.personaId,
    required this.assistStrength,
    required this.seed,
    required this.trials,
    required this.clears,
    required this.mechanicClears,
    required this.totalShots,
    required this.assistedShots,
    required this.targetSnaps,
    required this.localRescues,
    required this.safetyStops,
    required this.totalAbsoluteAngleCorrection,
    required this.totalAbsolutePowerCorrection,
  });

  final String scenarioId;
  final String personaId;
  final IntentAssistStrength assistStrength;
  final int seed;
  final int trials;
  final int clears;
  final int mechanicClears;
  final int totalShots;
  final int assistedShots;
  final int targetSnaps;
  final int localRescues;
  final int safetyStops;
  final double totalAbsoluteAngleCorrection;
  final double totalAbsolutePowerCorrection;

  double get clearRate => clears / trials;
  double get mechanicClearRate => mechanicClears / trials;
  double get assistActivationRate =>
      totalShots == 0 ? 0 : assistedShots / totalShots;
  double get targetSnapRate => totalShots == 0 ? 0 : targetSnaps / totalShots;
  double get localRescueRate => totalShots == 0 ? 0 : localRescues / totalShots;
  double get meanAbsoluteAngleCorrection =>
      assistedShots == 0 ? 0 : totalAbsoluteAngleCorrection / assistedShots;
  double get meanAbsolutePowerCorrection =>
      assistedShots == 0 ? 0 : totalAbsolutePowerCorrection / assistedShots;
  bool get safe => safetyStops == 0;
}

class VirtualPlayerSimulator {
  const VirtualPlayerSimulator({
    this.shotResolver = const ShotResolver(),
    this.intentAssistResolver = const IntentAssistResolver(),
  });

  final ShotResolver shotResolver;
  final IntentAssistResolver intentAssistResolver;

  VirtualPlayerSimulationResult run({
    required VirtualPlayerScenario scenario,
    required VirtualPlayerPersona persona,
    required IntentAssistStrength assistStrength,
    int trials = 200,
    int seed = 20260824,
  }) {
    persona.validate();
    if (trials < 1 || trials > 100000) {
      throw ArgumentError.value(trials, 'trials', '1~100000 범위여야 합니다.');
    }
    final random = math.Random(seed);
    var clears = 0;
    var mechanicClears = 0;
    var totalShots = 0;
    var assistedShots = 0;
    var targetSnaps = 0;
    var localRescues = 0;
    var safetyStops = 0;
    var totalAngleCorrection = 0.0;
    var totalPowerCorrection = 0.0;

    for (var trial = 0; trial < trials; trial++) {
      var state = scenario.initialState;
      final results = <ShotResult>[];
      for (final canonical in scenario.canonicalShots) {
        if (state.phase == GamePhase.success) break;
        final raw = _perturb(canonical, persona, random);
        final rawResult = shotResolver.resolve(state, raw);
        final decision = intentAssistResolver.resolve(
          state: state,
          rawInput: raw,
          strength: assistStrength,
          compactPointer: persona.compactPointer,
          repeatedNearMisses: persona.repeatedNearMisses,
          policy: scenario.assistPolicy,
        );
        final result = shotResolver.resolve(state, decision.appliedInput);
        totalShots++;
        if (decision.adjusted) {
          assistedShots++;
          totalAngleCorrection += decision.angleDeltaDegrees.abs();
          totalPowerCorrection += decision.powerDelta.abs();
        }
        if (decision.targetSnapped) targetSnaps++;
        if (rawResult.state.phase != GamePhase.success &&
            result.state.phase == GamePhase.success) {
          localRescues++;
        }
        safetyStops += result.chainSafetyDiagnostics.length;
        results.add(result);
        state = result.state;
      }
      if (state.phase == GamePhase.success) {
        clears++;
        final mechanicCheck = scenario.mechanicCheck;
        if (mechanicCheck == null || mechanicCheck(results)) {
          mechanicClears++;
        }
      }
    }

    return VirtualPlayerSimulationResult(
      scenarioId: scenario.id,
      personaId: persona.id,
      assistStrength: assistStrength,
      seed: seed,
      trials: trials,
      clears: clears,
      mechanicClears: mechanicClears,
      totalShots: totalShots,
      assistedShots: assistedShots,
      targetSnaps: targetSnaps,
      localRescues: localRescues,
      safetyStops: safetyStops,
      totalAbsoluteAngleCorrection: totalAngleCorrection,
      totalAbsolutePowerCorrection: totalPowerCorrection,
    );
  }

  ShotInput _perturb(
    ShotInput canonical,
    VirtualPlayerPersona persona,
    math.Random random,
  ) {
    final normalized = canonical.normalized();
    final angleNoise = _nextGaussian(random) * persona.angleSigmaDegrees;
    final powerNoise = _nextGaussian(random) * persona.powerSigma;
    final baseAngle = math.atan2(
      normalized.direction.y,
      normalized.direction.x,
    );
    final angle = baseAngle + angleNoise * math.pi / 180;
    return ShotInput(
      direction: Vec2(math.cos(angle), math.sin(angle)),
      power: (normalized.power + powerNoise).clamp(0.12, 1).toDouble(),
      equippedTrait: normalized.equippedTrait,
    );
  }

  double _nextGaussian(math.Random random) {
    final first = math.max(random.nextDouble(), 1e-12);
    final second = random.nextDouble();
    return math.sqrt(-2 * math.log(first)) * math.cos(2 * math.pi * second);
  }
}
