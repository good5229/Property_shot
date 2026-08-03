import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/play_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('로컬 플레이 계측은 개인정보 없이 JSON과 CSV로 내보낼 수 있다', () {
    final telemetry = LocalPlayTelemetry();
    telemetry.record(
      '발사',
      stage: 0,
      attempt: 1,
      action: '이전',
      trait: '무거움',
      angle: -1.2,
      power: 0.8,
    );
    telemetry.record('충돌', stage: 0, target: 'wall', result: '반사');

    expect(telemetry.events, hasLength(2));
    expect(telemetry.exportJson(), contains('무거움'));
    expect(telemetry.events.first['event_code'], 'shot_fired');
    expect(telemetry.events.first['session_id'], isNotEmpty);
    expect(telemetry.events.first['build_id'], 'property-shot-dev');
    expect(telemetry.exportJson(), isNot(contains('사용자')));
    expect(telemetry.exportCsv(), startsWith('시간,유형,단계'));
    expect(telemetry.exportCsv(), contains('event_code'));
    expect(telemetry.exportCsv(), contains('발사'));
  });

  test('세션과 물리 필드를 내부 코드로 내보낸다', () {
    final telemetry = LocalPlayTelemetry(sessionId: '검증 세션');
    telemetry.sessionStart(stage: 0, experimentVariant: 'guided');
    telemetry.record(
      '충돌',
      stage: 0,
      eventCode: 'collision_resolved',
      objectId: 'wall_top',
      objectType: 'wall',
      impulse: 0.7,
      isReplay: true,
    );
    telemetry.sessionEnd(stage: 0);

    expect(telemetry.events.map((event) => event['event_code']), [
      'session_start',
      'collision_resolved',
      'session_end',
    ]);
    expect(telemetry.events.first['결과'], 'guided');
    expect(telemetry.exportJson(), contains('wall_top'));
    expect(telemetry.exportJson(), contains('is_replay'));
  });

  test('최종 실험 계획의 필수 이벤트 코드가 한글 유형과 함께 유지된다', () {
    final telemetry = LocalPlayTelemetry(sessionId: '이벤트 검증');
    const types = {
      '단계 시작': 'stage_enter',
      '속성 확인': 'object_inspected',
      '속성 이전 열기': 'attribute_transfer_opened',
      '속성 이전': 'attribute_transferred',
      '속성 복사': 'attribute_copied',
      '속성 행동 취소': 'attribute_action_cancelled',
      '조준 시작': 'aim_started',
      '조준 방향 변경': 'aim_direction_changed',
      '충전 시작': 'charge_started',
      '충전 종료': 'charge_released',
      '발사': 'shot_fired',
      '충돌': 'collision_resolved',
      '연쇄 이동': 'object_started_moving',
      '물체 정지': 'object_stopped',
      '속성 소모': 'attribute_consumed',
      '스위치 작동': 'switch_activated',
      '문 열림': 'door_opened',
      '풍선 변형': 'balloon_deformed',
      '풍선 터짐': 'balloon_popped',
      '점착 정지': 'ball_stuck',
      '홀 진입': 'ball_entered_hole',
      '클리어': 'stage_cleared',
      '실패': 'stage_failed_or_reset',
      '힌트 노출': 'hint_exposed',
      '재시도': 'retry_pressed',
      '단계 종료': 'stage_exit',
    };

    for (final type in types.keys) {
      telemetry.record(type, stage: 0);
    }

    expect(telemetry.events.map((event) => event['event_code']), types.values);
  });

  test('플레이 계측은 개인정보 없이 로컬 저장소에 보관되고 복원된다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final telemetry = LocalPlayTelemetry(
      sessionId: '저장 검증',
      store: LocalPlayTelemetryStore(maxEvents: 2),
    );

    telemetry.record('발사', stage: 0, eventCode: 'shot_fired');
    telemetry.record('충돌', stage: 0, eventCode: 'collision_resolved');
    telemetry.record('클리어', stage: 0, eventCode: 'stage_cleared');
    await telemetry.flush();

    final restored = await telemetry.loadPersisted();
    expect(restored, hasLength(2));
    expect(restored.map((event) => event['event_code']), [
      'collision_resolved',
      'stage_cleared',
    ]);
    expect(restored.every((event) => !event.containsKey('사용자')), isTrue);

    await telemetry.clearPersisted();
    expect(await telemetry.loadPersisted(), isEmpty);
  });

  test('동시에 기록된 로컬 계측 이벤트의 순서를 보존한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = LocalPlayTelemetryStore();
    final telemetry = LocalPlayTelemetry(store: store);

    telemetry.record('첫 이벤트', stage: 0);
    telemetry.record('둘째 이벤트', stage: 0);
    telemetry.record('셋째 이벤트', stage: 0);
    await telemetry.flush();

    final restored = await store.load();
    expect(restored.map((event) => event['유형']), ['첫 이벤트', '둘째 이벤트', '셋째 이벤트']);
  });
}
