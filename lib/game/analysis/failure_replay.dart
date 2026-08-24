import 'dart:math' as math;

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

enum FailureReplayMarkerKind { collision, trait, gimmick }

enum FailureReviewMarkerKind {
  firstDirectionChange,
  firstContact,
  lastContact,
  combinedContact,
}

class FailureReviewMarker {
  const FailureReviewMarker({
    required this.kind,
    required this.pathIndex,
    required this.position,
    required this.label,
  });

  final FailureReviewMarkerKind kind;
  final int pathIndex;
  final Vec2 position;
  final String label;
}

class FailureReplayMarker {
  const FailureReplayMarker({
    required this.pathIndex,
    required this.label,
    required this.position,
    this.entityType,
    this.highlight = false,
    this.kind = FailureReplayMarkerKind.collision,
  });

  final int pathIndex;
  final String label;
  final Vec2 position;
  final EntityType? entityType;
  final bool highlight;
  final FailureReplayMarkerKind kind;
}

class FailureReplayAnalysis {
  const FailureReplayAnalysis({
    required this.kind,
    required this.title,
    required this.detail,
    required this.markers,
    required this.reviewMarkers,
    required this.semanticSummary,
    this.firstDirectionChange,
    this.firstContact,
    this.lastContact,
    this.nearestHole,
  });

  final FailureCauseKind kind;
  final String title;
  final String detail;
  final List<FailureReplayMarker> markers;
  final List<FailureReviewMarker> reviewMarkers;
  final String semanticSummary;
  final FailureReviewMarker? firstDirectionChange;
  final FailureReplayMarker? firstContact;
  final FailureReplayMarker? lastContact;
  final Vec2? nearestHole;
}

class FailureActionAdvice {
  const FailureActionAdvice({
    required this.causeKey,
    required this.headline,
    required this.detail,
  });

  final String causeKey;
  final String headline;
  final String detail;

  String messageForAttempt(int repeatedCount) =>
      repeatedCount >= 2 ? '$headline $detail' : headline;
}

/// 실패 팝업의 첫 문장을 짧게 유지하면서 같은 실패가 반복됐을 때만
/// 실제로 바꿀 입력을 덧붙인다. 판정은 문자열 이벤트와 경로 기하를 함께
/// 사용하며 게임 상태는 변경하지 않는다.
class FailureActionAdvisor {
  const FailureActionAdvisor();

  FailureActionAdvice analyze(FailureReplayData data) {
    final events = data.result.events;
    if (events.contains('switch_rejected') ||
        events.contains('switch_rejected_sticky') ||
        events.contains('hole_rejected_trait') ||
        events.contains('hole_rejected_crate')) {
      return const FailureActionAdvice(
        causeKey: 'mechanic_required',
        headline: '기믹을 먼저 작동해야 해요.',
        detail: '속성과 작동 조건을 확인한 뒤 홀로 향하는 경로를 만드세요.',
      );
    }
    if (events.contains('crate_blocked')) {
      return const FailureActionAdvice(
        causeKey: 'blocked',
        headline: '움직일 공간이 부족해요.',
        detail: '상자의 다른 면을 노리거나 힘을 한 칸 높여 보세요.',
      );
    }
    if (_isNearHoleMiss(data)) {
      return const FailureActionAdvice(
        causeKey: 'near_hole',
        headline: '목표를 근소하게 지나쳤어요.',
        detail: '이전 조준선에서 각도를 한 칸만 홀 쪽으로 옮겨 보세요.',
      );
    }
    if (events.contains('power_low')) {
      return const FailureActionAdvice(
        causeKey: 'power_low',
        headline: '힘이 부족했어요.',
        detail: '충전 게이지를 한 칸 더 채운 뒤 같은 각도로 시도해 보세요.',
      );
    }
    if (events.contains('power_high')) {
      return const FailureActionAdvice(
        causeKey: 'power_high',
        headline: '힘이 너무 강했어요.',
        detail: '충전 게이지를 한 칸 낮추고 마지막 충돌 면을 확인하세요.',
      );
    }
    if (events.contains('bounced') ||
        events.any((event) => event.startsWith('chain_collision_'))) {
      return const FailureActionAdvice(
        causeKey: 'reflection',
        headline: '반사 각도가 예상과 달랐어요.',
        detail: '이전 궤적의 마지막 접촉점을 조금 옆으로 옮겨 보세요.',
      );
    }
    if (events.contains('sticky_attached')) {
      return const FailureActionAdvice(
        causeKey: 'stopped',
        headline: '공이 충돌 지점에 멈췄어요.',
        detail: '붙은 공을 다음 발사의 발판으로 사용할 수 있는지 살펴보세요.',
      );
    }
    return const FailureActionAdvice(
      causeKey: 'route',
      headline: '아직 홀까지 경로가 이어지지 않았어요.',
      detail: '이전 궤적에서 홀과 가장 가까웠던 지점을 기준으로 각도를 조정하세요.',
    );
  }

  bool _isNearHoleMiss(FailureReplayData data) {
    final hole = data.beforeState.entities.cast<EntityState?>().firstWhere(
      (entity) => entity?.type == EntityType.hole,
      orElse: () => null,
    );
    final ball = data.beforeState.entityById('active_ball');
    if (hole == null || ball == null || data.result.path.isEmpty) return false;
    var nearest = double.infinity;
    for (final point in data.result.path) {
      nearest = math.min(nearest, point.distanceTo(hole.position));
    }
    final edgeMiss = nearest - hole.hitRadius - ball.hitRadius;
    return edgeMiss > 0 && edgeMiss <= 24;
  }
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
            kind: FailureReplayMarkerKind.collision,
          ),
        );
      } else if (event.kind == PhysicsEventKind.powerSliderActivation) {
        markers.add(
          FailureReplayMarker(
            pathIndex: event.pathIndex,
            label: '파워 발판 작동',
            position: event.position,
            entityType: EntityType.powerSlider,
            kind: FailureReplayMarkerKind.gimmick,
          ),
        );
      } else if (event.kind == PhysicsEventKind.reflectorRotation) {
        markers.add(
          FailureReplayMarker(
            pathIndex: event.pathIndex,
            label: '회전 반사판 회전',
            position: event.position,
            entityType: EntityType.rotatingReflector,
            kind: FailureReplayMarkerKind.gimmick,
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
            kind: _markerKindForState(event.visualState!),
          ),
        );
      }
    }
    markers.sort((a, b) => a.pathIndex.compareTo(b.pathIndex));
    final validImpacts =
        impacts.indexed
            .where(
              (entry) =>
                  entry.$2.pathIndex >= 0 &&
                  entry.$2.pathIndex < path.length &&
                  _isFinite(entry.$2.position),
            )
            .toList()
          ..sort((left, right) {
            final byPath = left.$2.pathIndex.compareTo(right.$2.pathIndex);
            return byPath != 0 ? byPath : left.$1.compareTo(right.$1);
          });
    final firstContact = validImpacts.isEmpty
        ? null
        : _markerForImpact(validImpacts.first.$2);
    final lastContact = validImpacts.isEmpty
        ? null
        : _markerForImpact(validImpacts.last.$2, highlight: true);
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
    final firstDirectionChange = _firstDirectionChange(data, validImpacts);
    final reviewMarkers = _reviewMarkers(
      firstDirectionChange: firstDirectionChange,
      firstContact: firstContact,
      lastContact: lastContact,
    );
    final semanticLabels = reviewMarkers.map((marker) => marker.label).toList();
    return FailureReplayAnalysis(
      kind: kind,
      title: _titleFor(kind),
      detail: _detailFor(kind, events),
      markers: List.unmodifiable(markers),
      reviewMarkers: List.unmodifiable(reviewMarkers),
      semanticSummary: semanticLabels.isEmpty
          ? ''
          : '직전 발사: ${semanticLabels.join(', ')}',
      firstDirectionChange: firstDirectionChange,
      firstContact: firstContact,
      lastContact: lastContact,
      nearestHole: nearestHole,
    );
  }

  FailureReviewMarker? _firstDirectionChange(
    FailureReplayData data,
    List<(int, ShotImpact)> validImpacts,
  ) {
    final path = data.result.path.where(_isFinite).toList(growable: false);
    if (path.length < 2) return null;
    final initial = data.input.direction.normalized();
    if (initial.length <= 0.001) return null;
    final cosineThreshold = math.cos(8 * math.pi / 180);
    var travelled = 0.0;
    for (var index = 1; index < path.length; index++) {
      final delta = path[index] - path[index - 1];
      final length = delta.length;
      if (!length.isFinite || length < 0.5) continue;
      travelled += length;
      if (travelled < 6) continue;
      final direction = delta * (1 / length);
      if (direction.dot(initial) >= cosineThreshold) continue;
      final nearbyImpact = validImpacts.cast<(int, ShotImpact)?>().firstWhere(
        (entry) => (entry!.$2.pathIndex - index).abs() <= 1,
        orElse: () => null,
      );
      return FailureReviewMarker(
        kind: FailureReviewMarkerKind.firstDirectionChange,
        pathIndex: index,
        position: nearbyImpact?.$2.position ?? path[index - 1],
        label: '첫 방향 변화',
      );
    }
    return null;
  }

  List<FailureReviewMarker> _reviewMarkers({
    required FailureReviewMarker? firstDirectionChange,
    required FailureReplayMarker? firstContact,
    required FailureReplayMarker? lastContact,
  }) {
    final result = <FailureReviewMarker>[?firstDirectionChange];
    if (firstContact != null && lastContact != null) {
      final sameContact =
          firstContact.pathIndex == lastContact.pathIndex ||
          firstContact.position.distanceTo(lastContact.position) <= 1;
      if (sameContact) {
        result.add(
          FailureReviewMarker(
            kind: FailureReviewMarkerKind.combinedContact,
            pathIndex: firstContact.pathIndex,
            position: firstContact.position,
            label: '첫·마지막 충돌 ${firstContact.label}',
          ),
        );
      } else {
        result
          ..add(
            FailureReviewMarker(
              kind: FailureReviewMarkerKind.firstContact,
              pathIndex: firstContact.pathIndex,
              position: firstContact.position,
              label: '첫 충돌 ${firstContact.label}',
            ),
          )
          ..add(
            FailureReviewMarker(
              kind: FailureReviewMarkerKind.lastContact,
              pathIndex: lastContact.pathIndex,
              position: lastContact.position,
              label: '마지막 충돌 ${lastContact.label}',
            ),
          );
      }
    } else if (firstContact != null) {
      result.add(
        FailureReviewMarker(
          kind: FailureReviewMarkerKind.combinedContact,
          pathIndex: firstContact.pathIndex,
          position: firstContact.position,
          label: '충돌 ${firstContact.label}',
        ),
      );
    }
    return result.take(3).toList(growable: false);
  }

  bool _isFinite(Vec2 point) => point.x.isFinite && point.y.isFinite;

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
      kind: FailureReplayMarkerKind.collision,
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
    'opening' => '문 열리는 중',
    'rotated' => '회전 반사판 회전',
    'revealed' => '기믹 드러남',
    'stuck' => '점착',
    _ => '상태 변화',
  };

  FailureReplayMarkerKind _markerKindForState(String state) => switch (state) {
    'sharpness_consumed' || 'stuck' => FailureReplayMarkerKind.trait,
    'pressed' ||
    'open' ||
    'opening' ||
    'rotated' ||
    'revealed' => FailureReplayMarkerKind.gimmick,
    _ => FailureReplayMarkerKind.collision,
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
