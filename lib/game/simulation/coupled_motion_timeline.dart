import 'dart:math' as math;

import '../domain/geometry.dart';

typedef MotionPositionSampler = Vec2 Function(String entityId, double cursor);

/// 화면 재생에서 함께 풀어야 하는 두 동적 물체의 접촉 제약이다.
///
/// [normal]은 target에서 source를 향한다. 두 중심의 법선 간격이
/// [separation]보다 작아지면 같은 하위 스텝에서 양쪽 위치를 경로 구동
/// 강성에 따른 [sourceCorrectionWeight], [targetCorrectionWeight]로 보정한다.
class CoupledMotionContact {
  const CoupledMotionContact({
    required this.sourceEntityId,
    required this.targetEntityId,
    required this.normal,
    required this.separation,
    required this.sourceCorrectionWeight,
    required this.targetCorrectionWeight,
    required this.startCursor,
    required this.endCursor,
  });

  final String sourceEntityId;
  final String targetEntityId;
  final Vec2 normal;
  final double separation;
  final double sourceCorrectionWeight;
  final double targetCorrectionWeight;
  final double startCursor;
  final double endCursor;
}

/// 판정 결과 경로를 240Hz 고정 하위 스텝에서 결합된 강체 운동으로 재생한다.
///
/// 게임 판정은 결정론적인 경로를 유지하되, 화면에서는 각 경로를 독립적으로
/// 재생하지 않는다. 모든 동적 물체를 같은 시간축에 올리고 비관통 접촉
/// 제약을 함께 반복해서 푼 뒤, 렌더 프레임은 이 고정 스텝 사이를 보간한다.
/// 따라서 30/45/60 FPS가 같은 궤적을 본다.
class CoupledMotionTimeline {
  CoupledMotionTimeline._({
    required this.cursorUnitsPerSecond,
    required this.stepCursor,
    required this.endCursor,
    required this.samplesByEntity,
  });

  static const int simulationHertz = 60;
  static const int subSteps = 4;
  static const int solverIterations = 4;
  static const double _contactSlop = 0.35;
  static const double _contactReleaseSlop = 4.0;
  static const double _positionCorrection = 1.0;
  static const double _positionErrorDecay = 12.0;

  final double cursorUnitsPerSecond;
  final double stepCursor;
  final double endCursor;
  final Map<String, List<Vec2>> samplesByEntity;

  static CoupledMotionTimeline build({
    required Iterable<String> entityIds,
    required Iterable<CoupledMotionContact> contacts,
    required MotionPositionSampler sampleRawPosition,
    required double endCursor,
    required double cursorUnitsPerSecond,
  }) {
    final ids = List<String>.unmodifiable(entityIds.toSet());
    final orderedContacts = List<CoupledMotionContact>.from(contacts)
      ..sort((first, second) {
        final byStart = first.startCursor.compareTo(second.startCursor);
        if (byStart != 0) return byStart;
        final bySource = first.sourceEntityId.compareTo(second.sourceEntityId);
        if (bySource != 0) return bySource;
        return first.targetEntityId.compareTo(second.targetEntityId);
      });
    final stepSeconds = 1 / (simulationHertz * subSteps);
    final stepCursor = cursorUnitsPerSecond * stepSeconds;
    final sampleCount = math.max(2, (endCursor / stepCursor).ceil() + 1);
    final samples = <String, List<Vec2>>{for (final id in ids) id: <Vec2>[]};
    final offsets = <String, Vec2>{for (final id in ids) id: Vec2.zero};

    for (var sampleIndex = 0; sampleIndex < sampleCount; sampleIndex++) {
      final cursor = math.min(endCursor, sampleIndex * stepCursor);
      final raw = <String, Vec2>{
        for (final id in ids) id: sampleRawPosition(id, cursor),
      };
      final positions = <String, Vec2>{
        for (final id in ids) id: raw[id]! + offsets[id]!,
      };
      final constrainedIds = <String>{};

      for (var iteration = 0; iteration < solverIterations; iteration++) {
        for (final contact in orderedContacts) {
          // 기록된 충돌 직전에도 형상 간격을 검사한다. 판정 경로의 한 점이
          // 이미 접촉면 안쪽에 들어온 뒤 제약을 켜면 첫 프레임에 큰 위치
          // 보정이 필요해진다. 실제 접촉이 없는 동안에는 아래 간격 검사가
          // 아무 일도 하지 않으므로, 이 방식이 speculative contact 역할을 한다.
          if (cursor > contact.endCursor + _contactSlop) {
            continue;
          }
          final sourcePosition = positions[contact.sourceEntityId];
          final targetPosition = positions[contact.targetEntityId];
          if (sourcePosition == null || targetPosition == null) continue;
          final normal = contact.normal.length <= 0.0001
              ? (sourcePosition - targetPosition).normalized()
              : contact.normal.normalized();
          if (normal == Vec2.zero) continue;
          final relative = sourcePosition - targetPosition;
          final normalSeparation = relative.dot(normal);
          final tangent = relative - normal * normalSeparation;
          if (tangent.length > contact.separation + _contactSlop) continue;
          final rawSource = raw[contact.sourceEntityId]!;
          final rawTarget = raw[contact.targetEntityId]!;
          final rawRelative = rawSource - rawTarget;
          final rawNormalSeparation = rawRelative.dot(normal);
          final maintainsRecordedContact =
              rawNormalSeparation <= contact.separation + _contactSlop;

          final correctionWeightSum =
              contact.sourceCorrectionWeight + contact.targetCorrectionWeight;
          if (correctionWeightSum <= 0.000001) continue;

          if (maintainsRecordedContact ||
              normalSeparation <= contact.separation + _contactReleaseSlop) {
            // 접촉 오차가 0인 하위 스텝도 제약을 유지한다. 여기서 접촉을
            // 해제하면 다음 스텝에 보정 오프셋이 감쇠하고, 그 다음 스텝에
            // 다시 관통을 고치는 on/off 진동이 생긴다.
            constrainedIds
              ..add(contact.sourceEntityId)
              ..add(contact.targetEntityId);
          }
          final penetration = contact.separation - normalSeparation;
          if (penetration <= 0 && !maintainsRecordedContact) continue;
          final correction =
              penetration * _positionCorrection / correctionWeightSum;
          positions[contact.sourceEntityId] =
              sourcePosition +
              normal * (correction * contact.sourceCorrectionWeight);
          positions[contact.targetEntityId] =
              targetPosition -
              normal * (correction * contact.targetCorrectionWeight);
        }
      }

      final positionDecay = math.exp(-_positionErrorDecay * stepSeconds);
      for (final id in ids) {
        final nextOffset = positions[id]! - raw[id]!;
        offsets[id] = constrainedIds.contains(id)
            ? nextOffset
            : nextOffset * positionDecay;
        samples[id]!.add(raw[id]! + offsets[id]!);
      }
    }

    // 확정 상태로 전환되는 마지막 샘플은 판정 좌표와 정확히 같아야 한다.
    // 남은 화면 오차가 다음 프레임의 state 교체에서 한꺼번에 사라지거나,
    // 홀 중심에서 수 픽셀 벗어나 포획 연출을 막지 않도록 한다.
    for (final id in ids) {
      samples[id]![samples[id]!.length - 1] = sampleRawPosition(id, endCursor);
    }

    return CoupledMotionTimeline._(
      cursorUnitsPerSecond: cursorUnitsPerSecond,
      stepCursor: stepCursor,
      endCursor: endCursor,
      samplesByEntity: Map.unmodifiable({
        for (final entry in samples.entries)
          entry.key: List<Vec2>.unmodifiable(entry.value),
      }),
    );
  }

  Vec2? positionAt(String entityId, double cursor) {
    final samples = samplesByEntity[entityId];
    if (samples == null || samples.isEmpty) return null;
    if (cursor >= endCursor) return samples.last;
    final sample = (cursor.clamp(0.0, endCursor) / stepCursor).clamp(
      0.0,
      samples.length - 1.0,
    );
    final index = sample.floor();
    if (index >= samples.length - 1) return samples.last;
    final local = sample - index;
    final from = samples[index];
    final to = samples[index + 1];
    return Vec2(
      from.x + (to.x - from.x) * local,
      from.y + (to.y - from.y) * local,
    );
  }
}
