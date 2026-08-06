import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/ui/feedback_cue.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('충돌 재질에 따라 플랫폼 사운드 강도가 구분된다', () async {
    final cues = <SystemSoundType>[];
    final feedback = GameFeedback(soundPlayer: (type) async => cues.add(type));

    feedback.collision(EntityType.wall);
    feedback.collision(EntityType.bumper);
    await _flushFeedback();

    expect(cues, [SystemSoundType.alert, SystemSoundType.click]);
  });

  test('문 열림은 스위치와 구분된 알림 사운드를 낸다', () async {
    final cues = <SystemSoundType>[];
    final feedback = GameFeedback(soundPlayer: (type) async => cues.add(type));

    feedback.gateOpened();
    await _flushFeedback();

    expect(cues, [SystemSoundType.alert]);
  });

  test('젤리와 홀은 전용 합성 피드백 큐를 낸다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.collision(EntityType.bumper, emphasizeJelly: true);
    feedback.collision(EntityType.hole);
    await _flushFeedback();

    expect(cues, [FeedbackCue.jellyCollision, FeedbackCue.holeEntered]);
  });

  test('조준 충전과 복제 코어 획득은 전용 큐를 낸다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.aimChargeStarted();
    feedback.copyCoreAwarded(1);
    await _flushFeedback();

    expect(cues, [FeedbackCue.aimCharge, FeedbackCue.copyCoreAwarded]);
  });

  test('과충전 취소는 짧은 이중 피드백을 낸다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.overchargeCancelled();
    await _flushFeedback();

    expect(cues, [FeedbackCue.fail]);
  });

  test('클리어 보상은 별도 메달 피드백 큐를 낸다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.medalAwarded(3);
    await _flushFeedback();

    expect(cues, [FeedbackCue.medal]);
  });

  test('충돌 재질은 합성 피드백 큐도 구분한다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.collision(EntityType.wall);
    feedback.collision(EntityType.bumper);
    feedback.collision(EntityType.stickySurface);
    await _flushFeedback();

    expect(cues, [
      FeedbackCue.heavyCollision,
      FeedbackCue.bouncyCollision,
      FeedbackCue.stickyCollision,
    ]);
  });

  test('연속 효과음은 겹치지 않고 이벤트 순서를 지킨다', () async {
    final cues = <FeedbackCue>[];
    var active = 0;
    var maximumActive = 0;
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async {
        active++;
        maximumActive = active > maximumActive ? active : maximumActive;
        cues.add(cue);
        await Future<void>.delayed(const Duration(milliseconds: 4));
        active--;
      },
    );

    feedback.shotCleared();
    feedback.medalAwarded(3);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(maximumActive, 1);
    expect(cues, [FeedbackCue.clear, FeedbackCue.medal]);
  });

  test('소리와 진동 설정을 로컬 저장소에서 복원한다', () async {
    SharedPreferences.setMockInitialValues({
      GameFeedback.soundPreferenceKey: false,
      GameFeedback.hapticsPreferenceKey: false,
      GameFeedback.screenShakePreferenceKey: false,
      GameFeedback.reducedMotionPreferenceKey: true,
    });
    GameFeedback.soundEnabled = true;
    GameFeedback.hapticsEnabled = true;
    GameFeedback.screenShakeEnabled = true;
    GameFeedback.reducedMotionEnabled = false;

    await GameFeedback.loadPreferences();

    expect(GameFeedback.soundEnabled, isFalse);
    expect(GameFeedback.hapticsEnabled, isFalse);
    expect(GameFeedback.screenShakeEnabled, isFalse);
    expect(GameFeedback.reducedMotionEnabled, isTrue);
  });

  test('소리와 진동 설정 변경을 로컬 저장소에 기록한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await GameFeedback.setSoundEnabled(false);
    await GameFeedback.setHapticsEnabled(false);
    await GameFeedback.setScreenShakeEnabled(false);
    await GameFeedback.setReducedMotionEnabled(true);
    final preferences = await SharedPreferences.getInstance();

    expect(preferences.getBool(GameFeedback.soundPreferenceKey), isFalse);
    expect(preferences.getBool(GameFeedback.hapticsPreferenceKey), isFalse);
    expect(preferences.getBool(GameFeedback.screenShakePreferenceKey), isFalse);
    expect(
      preferences.getBool(GameFeedback.reducedMotionPreferenceKey),
      isTrue,
    );
    GameFeedback.soundEnabled = true;
    GameFeedback.hapticsEnabled = true;
    GameFeedback.screenShakeEnabled = true;
    GameFeedback.reducedMotionEnabled = false;
  });
}

Future<void> _flushFeedback() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
