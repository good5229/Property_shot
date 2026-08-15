import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'feedback_cue.dart';

/// Web Audio를 사용할 수 없는 Android/iOS/desktop에서도 사건별 피드백을
/// 구분할 수 있도록 짧은 PCM 톤을 메모리에서 만든다. 외부 파일 로딩이나
/// 네트워크가 없고, 재생 실패는 게임 진행에 영향을 주지 않는다.
Future<void> playFeedbackCue(FeedbackCue cue) async {
  // flutter_tester에는 audioplayers 플랫폼 채널이 없으므로 재생 객체 자체를
  // 만들지 않는다. 파형 생성 계약은 feedbackCueBytesForTesting으로 검증한다.
  if (WidgetsBinding.instance.runtimeType.toString().contains(
    'TestWidgetsFlutterBinding',
  )) {
    return;
  }
  final spec = _specFor(cue);
  final player = AudioPlayer();
  try {
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(BytesSource(_wavTone(spec)));
    await player.onPlayerComplete.first.timeout(
      const Duration(seconds: 1),
      onTimeout: () {},
    );
  } catch (_) {
    // 무음 모드, 지원하지 않는 플랫폼 또는 테스트 환경에서는 안전하게 무시한다.
  } finally {
    await player.dispose();
  }
}

@visibleForTesting
Uint8List feedbackCueBytesForTesting(FeedbackCue cue) =>
    _wavTone(_specFor(cue));

({double frequency, int milliseconds, double volume}) _specFor(
  FeedbackCue cue,
) => switch (cue) {
  FeedbackCue.ui => (frequency: 620, milliseconds: 45, volume: 0.16),
  FeedbackCue.trait => (frequency: 740, milliseconds: 90, volume: 0.18),
  FeedbackCue.copy => (frequency: 880, milliseconds: 140, volume: 0.2),
  FeedbackCue.copyCoreAwarded => (
    frequency: 960,
    milliseconds: 220,
    volume: 0.2,
  ),
  FeedbackCue.aimCharge => (frequency: 320, milliseconds: 80, volume: 0.13),
  FeedbackCue.launch => (frequency: 190, milliseconds: 110, volume: 0.24),
  FeedbackCue.lightCollision => (
    frequency: 520,
    milliseconds: 70,
    volume: 0.18,
  ),
  FeedbackCue.heavyCollision => (
    frequency: 110,
    milliseconds: 160,
    volume: 0.28,
  ),
  FeedbackCue.bouncyCollision => (
    frequency: 760,
    milliseconds: 180,
    volume: 0.2,
  ),
  FeedbackCue.stickyCollision => (
    frequency: 260,
    milliseconds: 200,
    volume: 0.18,
  ),
  FeedbackCue.jellyCollision => (
    frequency: 680,
    milliseconds: 130,
    volume: 0.2,
  ),
  FeedbackCue.switchPressed => (
    frequency: 420,
    milliseconds: 120,
    volume: 0.22,
  ),
  FeedbackCue.gateOpened => (frequency: 300, milliseconds: 220, volume: 0.22),
  FeedbackCue.holeEntered => (frequency: 520, milliseconds: 320, volume: 0.24),
  FeedbackCue.clear => (frequency: 660, milliseconds: 280, volume: 0.24),
  FeedbackCue.medal => (frequency: 1040, milliseconds: 200, volume: 0.2),
  FeedbackCue.discovery => (frequency: 920, milliseconds: 180, volume: 0.2),
  FeedbackCue.rewardActivated => (
    frequency: 820,
    milliseconds: 160,
    volume: 0.2,
  ),
  FeedbackCue.restoration => (frequency: 560, milliseconds: 340, volume: 0.24),
  FeedbackCue.labComplete => (frequency: 700, milliseconds: 240, volume: 0.22),
  FeedbackCue.fail => (frequency: 180, milliseconds: 160, volume: 0.18),
};

Uint8List _wavTone(({double frequency, int milliseconds, double volume}) spec) {
  const sampleRate = 12000;
  const headerLength = 44;
  final sampleCount = (sampleRate * spec.milliseconds / 1000).round();
  final dataLength = sampleCount * 2;
  final bytes = ByteData(headerLength + dataLength);

  void ascii(int offset, String value) {
    for (var index = 0; index < value.length; index++) {
      bytes.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  ascii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataLength, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(28, sampleRate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  bytes.setUint32(40, dataLength, Endian.little);

  for (var index = 0; index < sampleCount; index++) {
    final progress = index / sampleCount;
    final envelope = math.min(1.0, progress * 12) * (1 - progress);
    final wave = math.sin(2 * math.pi * spec.frequency * index / sampleRate);
    final sample = (wave * envelope * spec.volume * 32767).round();
    bytes.setInt16(headerLength + index * 2, sample, Endian.little);
  }
  return bytes.buffer.asUint8List();
}
