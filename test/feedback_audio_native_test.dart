import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/feedback_audio_stub.dart';
import 'package:property_shot/ui/feedback_cue.dart';

void main() {
  test('모바일 피드백 큐는 유효한 WAV이며 사건별 파형이 다르다', () {
    final launch = feedbackCueBytesForTesting(FeedbackCue.launch);
    final clear = feedbackCueBytesForTesting(FeedbackCue.clear);
    final heavy = feedbackCueBytesForTesting(FeedbackCue.heavyCollision);

    expect(String.fromCharCodes(launch.take(4)), 'RIFF');
    expect(String.fromCharCodes(launch.skip(8).take(4)), 'WAVE');
    expect(launch.length, greaterThan(44));
    expect(clear.length, isNot(launch.length));
    expect(heavy, isNot(equals(launch)));
  });

  test('속성 충돌과 세 시설 복구 패턴은 모두 고유한 PCM 결과를 만든다', () {
    final cues = [
      FeedbackCue.heavyCollision,
      FeedbackCue.bouncyCollision,
      FeedbackCue.stickyCollision,
      FeedbackCue.sharpCollision,
      FeedbackCue.observatoryRestored,
      FeedbackCue.lighthouseRestored,
      FeedbackCue.bridgeRestored,
    ];
    final fingerprints = <String>{};
    for (final cue in cues) {
      final bytes = feedbackCueBytesForTesting(cue);
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF');
      expect(bytes.length, greaterThan(44));
      fingerprints.add('${bytes.length}:${_checksum(bytes)}');
    }
    expect(fingerprints.length, cues.length);
  });
}

int _checksum(Iterable<int> bytes) =>
    bytes.fold(0, (hash, byte) => ((hash * 16777619) ^ byte) & 0x7fffffff);
