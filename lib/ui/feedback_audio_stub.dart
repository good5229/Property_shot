import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'feedback_cue.dart';
import 'feedback_sound_spec.dart';

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
  final player = AudioPlayer();
  try {
    await player.setReleaseMode(ReleaseMode.release);
    await player.play(BytesSource(_wavTone(feedbackTonesFor(cue))));
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
    _wavTone(feedbackTonesFor(cue));

Uint8List _wavTone(List<FeedbackTone> tones) {
  const sampleRate = 12000;
  const headerLength = 44;
  final sampleCount = tones.fold<int>(
    0,
    (sum, tone) =>
        sum +
        (sampleRate * tone.milliseconds / 1000).round() +
        (sampleRate * tone.gapAfterMilliseconds / 1000).round(),
  );
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

  var outputIndex = 0;
  for (final tone in tones) {
    final toneSamples = (sampleRate * tone.milliseconds / 1000).round();
    for (var index = 0; index < toneSamples; index++) {
      final progress = index / toneSamples;
      final envelope = math.min(1.0, progress * 14) * (1 - progress);
      final phase = 2 * math.pi * tone.frequency * index / sampleRate;
      final wave = switch (tone.wave) {
        FeedbackWave.sine => math.sin(phase),
        FeedbackWave.triangle => 2 / math.pi * math.asin(math.sin(phase)),
        FeedbackWave.square => math.sin(phase) >= 0 ? 1.0 : -1.0,
        FeedbackWave.sawtooth =>
          2 * (tone.frequency * index / sampleRate % 1) - 1,
      };
      final nativeVolume = (tone.volume * 3.2).clamp(0.0, 0.32);
      final sample = (wave * envelope * nativeVolume * 32767).round();
      bytes.setInt16(headerLength + outputIndex * 2, sample, Endian.little);
      outputIndex++;
    }
    outputIndex += (sampleRate * tone.gapAfterMilliseconds / 1000).round();
  }
  return bytes.buffer.asUint8List();
}
