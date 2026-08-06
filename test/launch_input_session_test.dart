import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/ui/launch_input_session.dart';

void main() {
  test('최초 포인터가 세션을 독점하고 다른 포인터는 무시된다', () {
    final session = LaunchInputSession();

    expect(
      session.begin(
        pointer: 1,
        logicalPosition: const Vec2(56, 456),
        timeStamp: Duration.zero,
        onBall: true,
      ),
      isTrue,
    );
    expect(
      session.begin(
        pointer: 2,
        logicalPosition: const Vec2(80, 450),
        timeStamp: const Duration(milliseconds: 10),
        onBall: false,
      ),
      isFalse,
    );
    expect(
      session.move(
        pointer: 2,
        logicalPosition: const Vec2(100, 450),
        timeStamp: const Duration(milliseconds: 20),
      ),
      isFalse,
    );
    expect(session.activePointer, 1);
    expect(session.isActive, isTrue);

    final ignoredRelease = session.release(
      pointer: 2,
      logicalPosition: const Vec2(100, 450),
      timeStamp: const Duration(milliseconds: 30),
    );
    expect(ignoredRelease.kind, LaunchInputReleaseKind.ignored);
    expect(session.activePointer, 1);

    session.release(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: const Duration(milliseconds: 40),
    );
    expect(
      session.begin(
        pointer: 2,
        logicalPosition: const Vec2(80, 450),
        timeStamp: const Duration(milliseconds: 50),
        onBall: false,
      ),
      isTrue,
    );
  });

  test('롱프레스 Timer가 늦어도 release 시각으로 힘을 재계산한다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );

    final releaseTime = const Duration(milliseconds: 930);
    final release = session.release(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: releaseTime,
    );

    expect(release.shouldLaunch, isTrue);
    expect(release.power, closeTo(0.12 + (480 / 80) * 0.055, 0.0000001));
    expect(release.chargeStartedAt, LaunchInputSession.activationDelay);
    expect(session.isActive, isFalse);
  });

  test('조준은 마지막 유효 논리 좌표를 저장하고 짧은 이동은 무시한다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );

    expect(
      session.move(
        pointer: 1,
        logicalPosition: const Vec2(60, 456),
        timeStamp: const Duration(milliseconds: 100),
      ),
      isFalse,
    );
    expect(
      session.move(
        pointer: 1,
        logicalPosition: const Vec2(150, 410),
        timeStamp: const Duration(milliseconds: 120),
      ),
      isTrue,
    );
    expect(
      session.move(
        pointer: 1,
        logicalPosition: const Vec2(230, 380),
        timeStamp: const Duration(milliseconds: 180),
      ),
      isTrue,
    );

    final release = session.release(
      pointer: 1,
      logicalPosition: const Vec2(240, 370),
      timeStamp: const Duration(milliseconds: 900),
    );
    expect(release.lastLogicalPosition, const Vec2(240, 370));
  });

  test('30·60·120Hz 표시 샘플링은 같은 입력 로그의 결과를 바꾸지 않는다', () {
    final results = [30, 60, 120].map(_replayWithDisplaySampling).toList();
    final reference = results.first;

    for (final result in results.skip(1)) {
      expect(result.power, closeTo(reference.power, 0.0000001));
      expect(result.aim, reference.aim);
      expect(result.launched, reference.launched);
    }
    expect(reference.launched, isTrue);
    final expectedAim = _directionFrom(const Vec2(228, 368));
    expect(reference.aim.x, closeTo(expectedAim.x, 0.0001));
    expect(reference.aim.y, closeTo(expectedAim.y, 0.0001));
    expect(reference.power, closeTo(0.12 + (350 / 80) * 0.055, 0.0000001));
  });

  test('충전 전 드래그는 롱프레스 발사 자격을 취소한다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );
    session.move(
      pointer: 1,
      logicalPosition: const Vec2(100, 456),
      timeStamp: const Duration(milliseconds: 100),
    );

    final release = session.release(
      pointer: 1,
      logicalPosition: const Vec2(100, 456),
      timeStamp: const Duration(milliseconds: 900),
    );
    expect(release.shouldLaunch, isFalse);
    expect(release.kind, LaunchInputReleaseKind.aimed);
  });

  test('게이지 경계는 힘 기준으로 초록·노랑·빨강·경고 빨강으로 전환된다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );

    expect(
      session.gaugeStateAt(const Duration(milliseconds: 450)),
      ChargeGaugeState.green,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 857)),
      ChargeGaugeState.green,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 858)),
      ChargeGaugeState.yellow,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 1293)),
      ChargeGaugeState.yellow,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 1295)),
      ChargeGaugeState.red,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 1584)),
      ChargeGaugeState.red,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 1585)),
      ChargeGaugeState.warningRed,
    );
  });

  test('경고 빨강은 pointer-down 2130ms까지 유지되고 이후 회색으로 래치된다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );

    expect(
      session.gaugeStateAt(const Duration(milliseconds: 2130)),
      ChargeGaugeState.warningRed,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 2131)),
      ChargeGaugeState.cancelledGray,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 1200)),
      ChargeGaugeState.cancelledGray,
    );
  });

  test('같은 포인터를 누르는 동안 게이지 상태는 과거 시각 조회에도 뒤로 가지 않는다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );

    expect(
      session.gaugeStateAt(const Duration(milliseconds: 1585)),
      ChargeGaugeState.warningRed,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 700)),
      ChargeGaugeState.warningRed,
    );
  });

  test('회색 release는 발사하지 않고 새 pointer down에서 초록으로 초기화된다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );

    final release = session.release(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: const Duration(milliseconds: 2131),
    );
    expect(release.kind, LaunchInputReleaseKind.overchargeCancelled);
    expect(release.shouldLaunch, isFalse);
    expect(release.gaugeState, ChargeGaugeState.cancelledGray);
    expect(session.isActive, isFalse);

    expect(
      session.begin(
        pointer: 2,
        logicalPosition: const Vec2(56, 456),
        timeStamp: const Duration(milliseconds: 2200),
        onBall: true,
      ),
      isTrue,
    );
    expect(
      session.gaugeStateAt(const Duration(milliseconds: 2200)),
      ChargeGaugeState.green,
    );
  });

  test('최대 힘에 도달한 직후의 경고 빨강 release는 정상 발사한다', () {
    final session = LaunchInputSession();
    session.begin(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: Duration.zero,
      onBall: true,
    );

    final release = session.release(
      pointer: 1,
      logicalPosition: const Vec2(56, 456),
      timeStamp: const Duration(milliseconds: 1730),
    );
    expect(release.kind, LaunchInputReleaseKind.launch);
    expect(release.gaugeState, ChargeGaugeState.warningRed);
    expect(release.power, closeTo(1.0, 0.0000001));
  });

  test('최대 안전 경계에서는 발사하고 1ms 뒤에는 과충전 취소한다', () {
    LaunchInputRelease releaseAt(int milliseconds) {
      final session = LaunchInputSession();
      session.begin(
        pointer: 1,
        logicalPosition: const Vec2(56, 456),
        timeStamp: Duration.zero,
        onBall: true,
      );
      return session.release(
        pointer: 1,
        logicalPosition: const Vec2(56, 456),
        timeStamp: Duration(milliseconds: milliseconds),
      );
    }

    expect(releaseAt(2130).kind, LaunchInputReleaseKind.launch);
    expect(releaseAt(2131).kind, LaunchInputReleaseKind.overchargeCancelled);
  });

  test('30·60·120Hz 표시 샘플링에서도 과충전 release 결과가 같다', () {
    for (final frequency in const [30, 60, 120]) {
      final session = LaunchInputSession();
      session.begin(
        pointer: 1,
        logicalPosition: const Vec2(56, 456),
        timeStamp: Duration.zero,
        onBall: true,
      );
      final intervalMicros = (Duration.microsecondsPerSecond / frequency)
          .round();
      for (var micros = 0; micros <= 2200000; micros += intervalMicros) {
        session.gaugeStateAt(Duration(microseconds: micros));
      }
      final release = session.release(
        pointer: 1,
        logicalPosition: const Vec2(56, 456),
        timeStamp: const Duration(milliseconds: 2200),
      );
      expect(
        release.kind,
        LaunchInputReleaseKind.overchargeCancelled,
        reason: '${frequency}Hz 표시 샘플링',
      );
    }
  });
}

class _ReplayResult {
  const _ReplayResult({
    required this.aim,
    required this.power,
    required this.launched,
  });

  final Vec2 aim;
  final double power;
  final bool launched;
}

_ReplayResult _replayWithDisplaySampling(int frequency) {
  final aimSession = LaunchInputSession();
  aimSession.begin(
    pointer: 1,
    logicalPosition: const Vec2(56, 456),
    timeStamp: Duration.zero,
    onBall: true,
  );
  aimSession.move(
    pointer: 1,
    logicalPosition: const Vec2(160, 420),
    timeStamp: const Duration(milliseconds: 120),
  );
  aimSession.move(
    pointer: 1,
    logicalPosition: const Vec2(228, 368),
    timeStamp: const Duration(milliseconds: 260),
  );
  final aimRelease = aimSession.release(
    pointer: 1,
    logicalPosition: const Vec2(228, 368),
    timeStamp: const Duration(milliseconds: 300),
  );
  if (aimRelease.kind != LaunchInputReleaseKind.aimed) {
    throw StateError('조준 드래그가 조준 종료로 끝나지 않았습니다.');
  }
  final aim = _directionFrom(aimRelease.lastLogicalPosition!);

  final launchSession = LaunchInputSession();
  launchSession.begin(
    pointer: 2,
    logicalPosition: const Vec2(56, 456),
    timeStamp: const Duration(milliseconds: 400),
    onBall: true,
  );
  final intervalMicros = (Duration.microsecondsPerSecond / frequency).round();
  for (var micros = 400000; micros <= 1200000; micros += intervalMicros) {
    launchSession.powerAt(Duration(microseconds: micros));
  }
  final launchRelease = launchSession.release(
    pointer: 2,
    logicalPosition: const Vec2(56, 456),
    timeStamp: const Duration(milliseconds: 1200),
  );
  return _ReplayResult(
    aim: aim,
    power: launchRelease.power!,
    launched: launchRelease.shouldLaunch,
  );
}

Vec2 _directionFrom(Vec2 position) {
  return (position - const Vec2(56, 456)).normalized();
}
