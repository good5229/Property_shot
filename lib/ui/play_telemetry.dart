import 'dart:convert';

import '../game/domain/geometry.dart';

/// 실제 사용자 식별 정보 없이 내부 플레이 흐름만 기록하는 로컬 계측기다.
/// 서버 전송은 하지 않으며, 테스트 빌드에서 JSON/CSV 문자열로 내보낼 수 있다.
class LocalPlayTelemetry {
  LocalPlayTelemetry({String? sessionId, this.buildId = 'property-shot-dev'})
    : sessionId =
          sessionId ?? DateTime.now().toUtc().microsecondsSinceEpoch.toString();

  final String sessionId;
  final String buildId;
  final List<Map<String, Object?>> _events = [];

  List<Map<String, Object?>> get events => List.unmodifiable(_events);

  void record(
    String type, {
    required int stage,
    int? attempt,
    String? action,
    String? trait,
    double? angle,
    double? power,
    String? target,
    String? result,
    String? eventCode,
    int? shotId,
    String? objectId,
    String? objectType,
    String? attributeBefore,
    String? attributeAfter,
    Vec2? position,
    Vec2? velocity,
    Vec2? collisionNormal,
    double? speed,
    double? mass,
    double? impulse,
    bool? isReplay,
    String? fpsBucket,
    int? elapsedMs,
  }) {
    final event = <String, Object?>{
      '시간': DateTime.now().toUtc().toIso8601String(),
      '유형': type,
      '단계': stage + 1,
      'session_id': sessionId,
      'build_id': buildId,
      'event_code': eventCode ?? _eventCode(type),
    };
    if (attempt != null) event['시도'] = attempt;
    if (action != null) event['행동'] = action;
    if (trait != null) event['속성'] = trait;
    if (angle != null) event['각도'] = angle;
    if (power != null) event['힘'] = power;
    if (target != null) event['대상'] = target;
    if (result != null) event['결과'] = result;
    if (shotId != null) event['shot_id'] = shotId;
    if (objectId != null) event['object_id'] = objectId;
    if (objectType != null) event['object_type'] = objectType;
    if (attributeBefore != null) {
      event['attribute_before'] = attributeBefore;
    }
    if (attributeAfter != null) event['attribute_after'] = attributeAfter;
    if (position != null) event['position'] = position.toJson();
    if (velocity != null) event['velocity'] = velocity.toJson();
    if (collisionNormal != null) {
      event['collision_normal'] = collisionNormal.toJson();
    }
    if (speed != null) event['speed'] = speed;
    if (mass != null) event['mass'] = mass;
    if (impulse != null) event['impulse'] = impulse;
    if (isReplay != null) event['is_replay'] = isReplay;
    if (fpsBucket != null) event['fps_bucket'] = fpsBucket;
    if (elapsedMs != null) event['elapsed_ms'] = elapsedMs;
    _events.add(event);
  }

  void sessionStart({required int stage, String? experimentVariant}) {
    record(
      '세션 시작',
      stage: stage,
      eventCode: 'session_start',
      result: experimentVariant,
    );
  }

  void sessionEnd({required int stage}) {
    record('세션 종료', stage: stage, eventCode: 'session_end');
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_events);

  String exportCsv() {
    const columns = [
      '시간',
      '유형',
      '단계',
      '시도',
      '행동',
      '속성',
      '각도',
      '힘',
      '대상',
      '결과',
      'event_code',
      'session_id',
      'build_id',
      'shot_id',
      'object_id',
      'object_type',
      'attribute_before',
      'attribute_after',
      'position',
      'velocity',
      'collision_normal',
      'speed',
      'mass',
      'impulse',
      'is_replay',
      'fps_bucket',
      'elapsed_ms',
    ];
    final rows = <String>[columns.join(',')];
    for (final event in _events) {
      rows.add(columns.map((column) => _csvValue(event[column])).join(','));
    }
    return rows.join('\n');
  }

  static String _csvValue(Object? value) {
    final text = value?.toString() ?? '';
    if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
      return text;
    }
    return '"${text.replaceAll('"', '""')}"';
  }

  static String _eventCode(String type) {
    return switch (type) {
      '세션 시작' => 'session_start',
      '세션 종료' => 'session_end',
      '단계 시작' => 'stage_enter',
      '속성 확인' => 'object_inspected',
      '속성 이전 열기' => 'attribute_transfer_opened',
      '속성 이전' => 'attribute_transferred',
      '속성 복사' => 'attribute_copied',
      '속성 행동 취소' => 'attribute_action_cancelled',
      '조준 시작' => 'aim_started',
      '조준 방향 변경' => 'aim_direction_changed',
      '충전 시작' => 'charge_started',
      '충전 종료' => 'charge_released',
      '발사' => 'shot_fired',
      '충돌' => 'collision_resolved',
      '연쇄 이동' => 'object_started_moving',
      '물체 정지' => 'object_stopped',
      '속성 소모' => 'attribute_consumed',
      '스위치 작동' => 'switch_activated',
      '문 열림' => 'door_opened',
      '풍선 변형' => 'balloon_deformed',
      '풍선 터짐' => 'balloon_popped',
      '점착 정지' => 'ball_stuck',
      '홀 진입' => 'ball_entered_hole',
      '클리어' => 'stage_cleared',
      '실패' => 'stage_failed_or_reset',
      '힌트 노출' => 'hint_exposed',
      '재시도' => 'retry_pressed',
      '단계 종료' => 'stage_exit',
      _ => 'custom',
    };
  }
}
