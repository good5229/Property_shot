import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/ui/feedback_cue.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('충돌 재질에 따라 플랫폼 사운드 강도가 구분된다', () {
    final cues = <SystemSoundType>[];
    final feedback = GameFeedback(soundPlayer: (type) async => cues.add(type));

    feedback.collision(EntityType.wall);
    feedback.collision(EntityType.bumper);

    expect(cues, [SystemSoundType.alert, SystemSoundType.click]);
  });

  test('문 열림은 스위치와 구분된 알림 사운드를 낸다', () {
    final cues = <SystemSoundType>[];
    final feedback = GameFeedback(soundPlayer: (type) async => cues.add(type));

    feedback.gateOpened();

    expect(cues, [SystemSoundType.alert]);
  });

  test('충돌 재질은 합성 피드백 큐도 구분한다', () {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.collision(EntityType.wall);
    feedback.collision(EntityType.bumper);
    feedback.collision(EntityType.stickySurface);

    expect(cues, [
      FeedbackCue.heavyCollision,
      FeedbackCue.bouncyCollision,
      FeedbackCue.stickyCollision,
    ]);
  });

  test('소리와 진동 설정을 로컬 저장소에서 복원한다', () async {
    SharedPreferences.setMockInitialValues({
      GameFeedback.soundPreferenceKey: false,
      GameFeedback.hapticsPreferenceKey: false,
    });
    GameFeedback.soundEnabled = true;
    GameFeedback.hapticsEnabled = true;

    await GameFeedback.loadPreferences();

    expect(GameFeedback.soundEnabled, isFalse);
    expect(GameFeedback.hapticsEnabled, isFalse);
  });

  test('소리와 진동 설정 변경을 로컬 저장소에 기록한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await GameFeedback.setSoundEnabled(false);
    await GameFeedback.setHapticsEnabled(false);
    final preferences = await SharedPreferences.getInstance();

    expect(preferences.getBool(GameFeedback.soundPreferenceKey), isFalse);
    expect(preferences.getBool(GameFeedback.hapticsPreferenceKey), isFalse);
    GameFeedback.soundEnabled = true;
    GameFeedback.hapticsEnabled = true;
  });
}
