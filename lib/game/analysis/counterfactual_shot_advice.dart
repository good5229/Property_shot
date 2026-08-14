import 'dart:math' as math;

import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../simulation/shot_resolver.dart';
import 'failure_replay.dart';

enum CounterfactualAdviceAxis { angle, power }

enum CounterfactualAdviceDirection {
  clockwise,
  counterClockwise,
  increase,
  decrease,
}

enum CounterfactualEvidenceKind { nextGimmick, robustClear, closerApproach }

class CounterfactualShotAdvice {
  const CounterfactualShotAdvice({
    required this.axis,
    required this.direction,
    required this.evidence,
  });
  final CounterfactualAdviceAxis axis;
  final CounterfactualAdviceDirection direction;
  final CounterfactualEvidenceKind evidence;
  String get message => switch (direction) {
    CounterfactualAdviceDirection.clockwise => '조준점을 시계 방향으로 조금 옮겨 보세요.',
    CounterfactualAdviceDirection.counterClockwise =>
      '조준점을 반시계 방향으로 조금 옮겨 보세요.',
    CounterfactualAdviceDirection.increase => '힘을 한 구간 더 모아 보세요.',
    CounterfactualAdviceDirection.decrease => '힘을 한 구간 덜 모아 보세요.',
  };
}

typedef CounterfactualResolve =
    ShotResult Function(GameState state, ShotInput input);

class CounterfactualShotCoach {
  CounterfactualShotCoach({CounterfactualResolve? resolve})
    : _resolve = resolve ?? const ShotResolver().resolve;
  final CounterfactualResolve _resolve;

  CounterfactualShotAdvice? analyze({
    required String stageId,
    required FailureReplayData failure,
  }) {
    final baseline = _evidence(stageId, failure.beforeState, failure.result);
    final groups = <_Group>[
      _angle(
        stageId,
        failure,
        baseline,
        CounterfactualAdviceDirection.counterClockwise,
        const [-3, -6, -9],
      ),
      _angle(
        stageId,
        failure,
        baseline,
        CounterfactualAdviceDirection.clockwise,
        const [3, 6, 9],
      ),
      _power(
        stageId,
        failure,
        baseline,
        CounterfactualAdviceDirection.decrease,
        const [-0.055, -0.110, -0.165],
      ),
      _power(
        stageId,
        failure,
        baseline,
        CounterfactualAdviceDirection.increase,
        const [0.055, 0.110, 0.165],
      ),
    ];
    final robust = groups.where((group) => group.robust).toList();
    if (robust.isEmpty) return null;
    for (final pair in const [
      (
        CounterfactualAdviceDirection.counterClockwise,
        CounterfactualAdviceDirection.clockwise,
      ),
      (
        CounterfactualAdviceDirection.decrease,
        CounterfactualAdviceDirection.increase,
      ),
    ]) {
      final a = robust.where((item) => item.direction == pair.$1).firstOrNull;
      final b = robust.where((item) => item.direction == pair.$2).firstOrNull;
      if (a != null && b != null && a.rank == b.rank) {
        return null;
      }
    }
    robust.sort((a, b) {
      final byRank = b.rank.compareTo(a.rank);
      if (byRank != 0) return byRank;
      return b.improvedCount.compareTo(a.improvedCount);
    });
    if (robust.length > 1 &&
        robust[0].rank == robust[1].rank &&
        robust[0].improvedCount == robust[1].improvedCount) {
      return null;
    }
    final best = robust.first;
    return CounterfactualShotAdvice(
      axis: best.axis,
      direction: best.direction,
      evidence: best.kind,
    );
  }

  _Group _angle(
    String stageId,
    FailureReplayData failure,
    _Evidence baseline,
    CounterfactualAdviceDirection direction,
    List<num> deltas,
  ) {
    final angle = math.atan2(
      failure.input.direction.y,
      failure.input.direction.x,
    );
    return _evaluate(
      stageId,
      failure,
      baseline,
      CounterfactualAdviceAxis.angle,
      direction,
      deltas.map((delta) {
        final next = angle + delta * math.pi / 180;
        return ShotInput(
          direction: Vec2(math.cos(next), math.sin(next)),
          power: failure.input.power,
          equippedTrait: failure.input.equippedTrait,
        );
      }),
    );
  }

  _Group _power(
    String stageId,
    FailureReplayData failure,
    _Evidence baseline,
    CounterfactualAdviceDirection direction,
    List<double> deltas,
  ) {
    final seen = <double>{};
    final candidates = <ShotInput>[];
    for (final delta in deltas) {
      final power = (failure.input.power + delta).clamp(0.12, 1.0);
      if (seen.add(power)) {
        candidates.add(
          ShotInput(
            direction: failure.input.direction,
            power: power,
            equippedTrait: failure.input.equippedTrait,
          ),
        );
      }
    }
    return _evaluate(
      stageId,
      failure,
      baseline,
      CounterfactualAdviceAxis.power,
      direction,
      candidates,
    );
  }

  _Group _evaluate(
    String stageId,
    FailureReplayData failure,
    _Evidence baseline,
    CounterfactualAdviceAxis axis,
    CounterfactualAdviceDirection direction,
    Iterable<ShotInput> candidates,
  ) {
    final improvements = <_Evidence>[];
    var nearestImproved = false;
    var index = 0;
    for (final input in candidates) {
      final ShotResult result;
      try {
        result = _resolve(failure.beforeState, input.normalized());
      } on Object {
        // 조언은 실패 화면의 보조 기능이다. 어떤 비정상 후보도
        // 재시도 흐름을 막지 않고 기존 정적 조언으로 돌아가야 한다.
        index++;
        continue;
      }
      if (result.chainSafetyDiagnostics.isNotEmpty ||
          result.path.any((p) => !p.x.isFinite || !p.y.isFinite)) {
        index++;
        continue;
      }
      final evidence = _evidence(stageId, failure.beforeState, result);
      if (evidence.improves(baseline)) {
        if (index == 0) nearestImproved = true;
        improvements.add(evidence);
      }
      index++;
    }
    final best = improvements.fold<_Evidence?>(
      null,
      (value, item) => value == null || item.rank > value.rank ? item : value,
    );
    return _Group(
      axis: axis,
      direction: direction,
      robust: nearestImproved && improvements.length >= 2,
      improvedCount: improvements.length,
      kind: best?.kind ?? CounterfactualEvidenceKind.closerApproach,
    );
  }
}

class _Group {
  const _Group({
    required this.axis,
    required this.direction,
    required this.robust,
    required this.improvedCount,
    required this.kind,
  });
  final CounterfactualAdviceAxis axis;
  final CounterfactualAdviceDirection direction;
  final bool robust;
  final int improvedCount;
  final CounterfactualEvidenceKind kind;
  int get rank => switch (kind) {
    CounterfactualEvidenceKind.nextGimmick => 3,
    CounterfactualEvidenceKind.robustClear => 2,
    CounterfactualEvidenceKind.closerApproach => 1,
  };
}

class _Evidence {
  const _Evidence(this.achievements, this.success, this.holeDistance);
  final Set<String> achievements;
  final bool success;
  final double holeDistance;
  CounterfactualEvidenceKind get kind => achievements.isNotEmpty
      ? CounterfactualEvidenceKind.nextGimmick
      : success
      ? CounterfactualEvidenceKind.robustClear
      : CounterfactualEvidenceKind.closerApproach;
  int get rank => achievements.length * 100 + (success ? 10 : 0);
  bool improves(_Evidence other) {
    if (!achievements.containsAll(other.achievements)) return false;
    if (achievements.length > other.achievements.length) {
      return true;
    }
    if (success && !other.success) return true;
    if (success != other.success ||
        !holeDistance.isFinite ||
        !other.holeDistance.isFinite) {
      return false;
    }
    return holeDistance + math.max(12, other.holeDistance * .1) <=
        other.holeDistance;
  }
}

_Evidence _evidence(String stageId, GameState before, ShotResult result) {
  final transitions = result.physicsEvents
      .where((event) => event.kind == PhysicsEventKind.stateChange)
      .map((event) => event.visualState ?? '')
      .toSet();
  final impacts = result.impacts.map((impact) => impact.entityType).toList();
  final movedIds = result.moves
      .where((move) => move.from != move.to)
      .map((move) => move.entityId)
      .toSet();
  final achievements = <String>{};
  switch (stageId) {
    case 'stage_heavy':
      if (impacts.contains(EntityType.crate)) achievements.add('crate_impact');
      if (movedIds.any((id) => id.contains('crate'))) {
        achievements.add('crate_moved');
      }
    case 'stage_bouncy':
      final count = impacts
          .where((type) => type == EntityType.wall || type == EntityType.gate)
          .length;
      for (var i = 1; i <= count; i++) {
        achievements.add('bounce_$i');
      }
    case 'stage_chain_gate':
      if (result.events.contains('switch_pressed')) {
        achievements.add('switch_pressed');
      }
      if (transitions.any((value) => value.contains('open'))) {
        achievements.add('gate_opened');
      }
    case 'stage_balloon':
      if (result.events.contains('balloon_popped')) {
        achievements.add('balloon_popped');
      }
      if (result.events.contains('switch_pressed')) {
        achievements.add('switch_pressed');
      }
    case 'stage_drained':
      achievements.addAll(movedIds.map((id) => 'moved:$id'));
    case 'stage_speed':
      for (var i = 1; i <= result.powerSliderActivations.length; i++) {
        achievements.add('slider_$i');
      }
      if (impacts.isNotEmpty) achievements.add('impact_after_launch');
    case 'stage_persistent':
      achievements.addAll(
        result.impacts
            .where((impact) => impact.sourceEntityId.startsWith('spent_ball_'))
            .map((impact) => 'spent:${impact.sourceEntityId}'),
      );
    case 'stage_chain_score':
      achievements.addAll(
        impacts
            .where((type) => type != EntityType.hole)
            .map((type) => 'target:${type.name}'),
      );
    case 'stage_rotating_reflector':
      for (var i = 1; i <= result.reflectorRotations.length; i++) {
        achievements.add('reflector_$i');
      }
      if (impacts.isNotEmpty) achievements.add('impact_after_launch');
    case 'stage_property_shot':
      if (result.powerSliderActivations.isNotEmpty) {
        achievements.add('power_slider');
      }
      if (result.reflectorRotations.isNotEmpty) {
        achievements.add('reflector');
      }
      achievements.addAll(
        result.events.where(
          (event) =>
              event == 'switch_pressed' ||
              event == 'balloon_popped' ||
              event == 'sticky_attached',
        ),
      );
  }
  final hole = before.entities.cast<EntityState?>().firstWhere(
    (entity) => entity?.type == EntityType.hole,
    orElse: () => null,
  );
  var distance = double.infinity;
  if (hole != null && result.path.isNotEmpty) {
    distance = result.path
        .map((point) => point.distanceTo(hole.position))
        .reduce(math.min);
  }
  return _Evidence(
    Set.unmodifiable(achievements),
    result.state.phase == GamePhase.success,
    distance,
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
