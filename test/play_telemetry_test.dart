import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/play_telemetry.dart';

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
    telemetry.sessionStart(stage: 0);
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
    expect(telemetry.exportJson(), contains('wall_top'));
    expect(telemetry.exportJson(), contains('is_replay'));
  });
}
