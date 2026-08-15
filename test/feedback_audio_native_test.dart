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
}
