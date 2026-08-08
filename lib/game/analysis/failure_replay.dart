import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../domain/entity_state.dart';
import '../simulation/shot_resolver.dart';

/// 실패한 발사를 다시 계산하지 않고 화면으로만 재생하기 위한 입력 묶음이다.
class FailureReplayData {
  const FailureReplayData({
    required this.beforeState,
    required this.input,
    required this.result,
  });

  final GameState beforeState;
  final ShotInput input;
  final ShotResult result;
}

enum FailureCauseKind {
  power,
  blocked,
  missedHole,
  rejectedTrait,
  collision,
  stopped,
}

class FailureReplayMarker {
  const FailureReplayMarker({
    required this.pathIndex,
    required this.label,
    required this.position,
    this.entityType,
    this.highlight = false,
  });

  final int pathIndex;
  final String label;
  final Vec2 position;
  final EntityType? entityType;
  final bool highlight;
}

class FailureReplayAnalysis {
  const FailureReplayAnalysis({
    required this.kind,
    required this.title,
    required this.detail,
    required this.markers,
    this.lastContact,
    this.nearestHole,
  });

  final FailureCauseKind kind;
  final String title;
  final String detail;
  final List<FailureReplayMarker> markers;
  final FailureReplayMarker? lastContact;
  final Vec2? nearestHole;
}

class FailureReplayAnalyzer {
  const FailureReplayAnalyzer();

  FailureReplayAnalysis analyze(FailureReplayData data) {
    final events = data.result.events;
    final impacts = data.result.impacts;
    final path = data.result.path;
    final markers = <FailureReplayMarker>[];
    for (final event in data.result.physicsEvents) {
      if (event.kind == PhysicsEventKind.impact && event.impact != null) {
        final impact = event.impact!;
        markers.add(
          FailureReplayMarker(
            pathIndex: impact.pathIndex,
            label: _entityLabel(impact.entityType),
            position: impact.position,
            entityType: impact.entityType,
          ),
        );
      } else if (event.kind == PhysicsEventKind.stateChange &&
          event.visualState != null) {
        markers.add(
          FailureReplayMarker(
            pathIndex: event.pathIndex,
            label: _stateLabel(event.visualState!),
            position: event.position,
            entityType: event.targetType,
          ),
        );
      }
    }
    markers.sort((a, b) => a.pathIndex.compareTo(b.pathIndex));
    final lastContact = impacts.isEmpty
        ? null
        : _markerForImpact(impacts.last, highlight: true);
    if (lastContact != null && markers.isNotEmpty) {
      final index = markers.lastIndexWhere(
        (marker) =>
            marker.pathIndex == lastContact.pathIndex &&
            marker.entityType == lastContact.entityType,
      );
      if (index >= 0) {
        markers[index] = lastContact;
      } else {
        markers.add(lastContact);
      }
    }
    final hole = data.beforeState.entities.cast<EntityState?>().firstWhere(
      (entity) => entity?.type == EntityType.hole,
      orElse: () => null,
    );
    final nearestHole = hole == null || path.isEmpty
        ? null
        : path.reduce(
            (a, b) => a.distanceTo(hole.position) <= b.distanceTo(hole.position)
                ? a
                : b,
          );
    final kind = _kindFor(events);
    return FailureReplayAnalysis(
      kind: kind,
      title: _titleFor(kind),
      detail: _detailFor(kind, events),
      markers: List.unmodifiable(markers),
      lastContact: lastContact,
      nearestHole: nearestHole,
    );
  }

  FailureReplayMarker _markerForImpact(
    ShotImpact impact, {
    bool highlight = false,
  }) {
    return FailureReplayMarker(
      pathIndex: impact.pathIndex,
      label: _entityLabel(impact.entityType),
      position: impact.position,
      entityType: impact.entityType,
      highlight: highlight,
    );
  }

  FailureCauseKind _kindFor(List<String> events) {
    if (events.contains('power_low') || events.contains('power_high')) {
      return FailureCauseKind.power;
    }
    if (events.contains('crate_blocked')) {
      return FailureCauseKind.blocked;
    }
    if (events.contains('hole_rejected_trait') ||
        events.contains('hole_rejected_crate') ||
        events.contains('switch_rejected')) {
      return FailureCauseKind.rejectedTrait;
    }
    if (events.contains('bounced') ||
        events.any((event) => event.startsWith('chain_collision_'))) {
      return FailureCauseKind.collision;
    }
    if (events.contains('sticky_attached')) {
      return FailureCauseKind.stopped;
    }
    return FailureCauseKind.missedHole;
  }

  String _titleFor(FailureCauseKind kind) => switch (kind) {
    FailureCauseKind.power => '힘 조절이 필요해요',
    FailureCauseKind.blocked => '물체가 충분히 움직이지 않았어요',
    FailureCauseKind.missedHole => '홀까지 닿지 않았어요',
    FailureCauseKind.rejectedTrait => '속성 효과가 목표에 맞지 않았어요',
    FailureCauseKind.collision => '충돌 뒤 방향이 달라졌어요',
    FailureCauseKind.stopped => '공이 충돌 지점에 멈췄어요',
  };

  String _detailFor(FailureCauseKind kind, List<String> events) {
    if (kind == FailureCauseKind.power && events.contains('power_low')) {
      return '마지막 충돌까지 도달한 힘과 방향을 확인해 보세요.';
    }
    if (kind == FailureCauseKind.power && events.contains('power_high')) {
      return '강한 충돌 뒤의 반사 방향을 확인해 보세요.';
    }
    if (kind == FailureCauseKind.blocked) {
      return '물체에 닿은 면과 밀려난 거리를 확인해 보세요.';
    }
    if (kind == FailureCauseKind.rejectedTrait) {
      return '속성이 발동하거나 소모된 순간을 확인해 보세요.';
    }
    if (kind == FailureCauseKind.collision) {
      return '충돌 순서와 마지막 접촉 대상을 확인해 보세요.';
    }
    if (kind == FailureCauseKind.stopped) {
      return '멈춘 위치를 다음 발사의 발판으로 활용할 수도 있어요.';
    }
    return '홀과 가장 가까웠던 위치를 확인하고 입력을 조정해 보세요.';
  }

  String _stateLabel(String state) => switch (state) {
    'captured' => '홀 진입',
    'sharpness_consumed' => '뾰족함 소모',
    'pressed' => '스위치 작동',
    'open' => '문 열림',
    'stuck' => '점착',
    _ => '상태 변화',
  };

  String _entityLabel(EntityType type) => switch (type) {
    EntityType.ball => '과거 공',
    EntityType.hole => '홀',
    EntityType.wall => '벽',
    EntityType.crate => '상자',
    EntityType.bumper => '젤리',
    EntityType.stickySurface => '점착판',
    EntityType.weight => '무거운 돌',
    EntityType.switchPad => '스위치',
    EntityType.gate => '문',
    EntityType.balloon => '풍선',
    EntityType.spikeSource => '가시 성게',
    EntityType.powerSlider => '파워 발판',
    EntityType.rotatingReflector => '회전 반사판',
  };
}
