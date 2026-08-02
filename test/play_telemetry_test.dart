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
    expect(telemetry.exportJson(), isNot(contains('사용자')));
    expect(telemetry.exportCsv(), startsWith('시간,유형,단계'));
    expect(telemetry.exportCsv(), contains('발사'));
  });
}
