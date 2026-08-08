import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/background_music.dart';

void main() {
  test('배경 음악은 활성화·비활성화를 한 번씩 재생기에 전달한다', () async {
    final backend = _FakeBackend();
    final controller = BackgroundMusicController(backend: backend);

    await controller.setEnabled(true);
    await controller.setEnabled(true);
    expect(controller.playing, isTrue);
    expect(backend.startCount, 1);

    await controller.setEnabled(false);
    await controller.setEnabled(false);
    expect(controller.playing, isFalse);
    expect(backend.stopCount, 1);
  });

  test('자동 재생 실패 뒤 같은 활성 설정으로 다시 시도한다', () async {
    final backend = _FakeBackend(failFirstStart: true);
    final controller = BackgroundMusicController(backend: backend);

    await controller.setEnabled(true);
    expect(controller.enabled, isTrue);
    expect(controller.playing, isFalse);

    await controller.retry();
    expect(controller.playing, isTrue);
    expect(backend.startCount, 2);
  });

  test('재생 시작 중 비활성화하면 시작 완료 직후 정지한다', () async {
    final gate = Completer<void>();
    final backend = _FakeBackend(startGate: gate.future);
    final controller = BackgroundMusicController(backend: backend);

    final start = controller.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    final stop = controller.setEnabled(false);
    gate.complete();
    await Future.wait([start, stop]);

    expect(controller.enabled, isFalse);
    expect(controller.playing, isFalse);
    expect(backend.stopCount, 1);
  });

  test('dispose는 재생을 멈추고 재생기를 해제한다', () async {
    final backend = _FakeBackend();
    final controller = BackgroundMusicController(backend: backend);
    await controller.setEnabled(true);

    await controller.dispose();

    expect(controller.playing, isFalse);
    expect(backend.stopCount, 1);
    expect(backend.disposeCount, 1);
  });

  test('앱이 백그라운드에 가면 멈추고 복귀하면 다시 재생한다', () async {
    final backend = _FakeBackend();
    final controller = BackgroundMusicController(backend: backend);
    await controller.setEnabled(true);

    await controller.synchronizeLifecycleState(AppLifecycleState.paused);
    expect(controller.playing, isFalse);
    expect(backend.stopCount, 1);

    await controller.synchronizeLifecycleState(AppLifecycleState.resumed);
    expect(controller.playing, isTrue);
    expect(backend.startCount, 2);
  });

  testWidgets('자체 생성 배경 음악이 유효한 WAV 번들 자산이다', (tester) async {
    final data = await rootBundle.load(
      'assets/audio/property_shot_island_loop.wav',
    );
    final bytes = data.buffer.asUint8List();

    expect(ascii.decode(bytes.sublist(0, 4)), 'RIFF');
    expect(ascii.decode(bytes.sublist(8, 12)), 'WAVE');
    expect(data.lengthInBytes, 705644);
  });
}

class _FakeBackend implements BackgroundTrackBackend {
  _FakeBackend({this.failFirstStart = false, this.startGate});

  final bool failFirstStart;
  final Future<void>? startGate;
  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Future<void> start() async {
    startCount++;
    if (startGate case final gate?) await gate;
    if (failFirstStart && startCount == 1) throw StateError('재생 실패');
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
  }
}
