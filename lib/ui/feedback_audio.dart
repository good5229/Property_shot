import 'feedback_cue.dart';
import 'feedback_audio_stub.dart'
    if (dart.library.js_interop) 'feedback_audio_web.dart'
    as platform;

export 'feedback_cue.dart';

Future<void> playFeedbackCue(FeedbackCue cue) {
  return platform.playFeedbackCue(cue);
}
