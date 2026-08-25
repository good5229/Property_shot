import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/island_restoration.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/input/intent_assist_resolver.dart';
import 'package:property_shot/ui/feedback_cue.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('모든 소리·진동 신호는 같은 의미의 시각·스크린리더 문구를 가진다', () {
    for (final cue in FeedbackCue.values) {
      expect(cue.visualLabel, isNotEmpty);
      expect(cue.semanticsLabel, contains(cue.visualLabel));
      expect(cue.requiresVisualAlternative, isTrue);
    }
  });
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

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

  test('미스터리 상자 공개는 충돌·스위치와 구분된 전용 큐를 낸다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.mysteryRevealed();
    await _flushFeedback();

    expect(cues, [FeedbackCue.mysteryReveal]);
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

  test('발견·보상·복구·실험 완료는 서로 다른 소리와 진동 사건을 낸다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.discoveryMilestone();
    feedback.rewardActivated();
    feedback.restorationCompleted(IslandLandmark.observatory);
    feedback.labCompleted();
    await _flushFeedback();

    expect(cues, [
      FeedbackCue.discovery,
      FeedbackCue.rewardActivated,
      FeedbackCue.observatoryRestored,
      FeedbackCue.labComplete,
    ]);
  });

  test('같은 벽 충돌도 공의 속성에 따라 네 가지 재질 큐를 구분한다', () async {
    final cues = <FeedbackCue>[];
    GameFeedback materialFeedback() => GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    materialFeedback().collision(
      EntityType.wall,
      impactStrength: 0.4,
      sourceTraits: const {TraitType.heavy},
    );
    materialFeedback().collision(
      EntityType.wall,
      impactStrength: 0.4,
      sourceTraits: const {TraitType.bouncy},
    );
    materialFeedback().collision(
      EntityType.wall,
      impactStrength: 0.4,
      sourceTraits: const {TraitType.sticky},
    );
    materialFeedback().collision(
      EntityType.wall,
      impactStrength: 0.4,
      sourceTraits: const {TraitType.sharp},
    );
    await _flushFeedback();

    expect(cues, [
      FeedbackCue.heavyCollision,
      FeedbackCue.bouncyCollision,
      FeedbackCue.stickyCollision,
      FeedbackCue.sharpCollision,
    ]);
  });

  test('관측소·등대·다리 복구는 서로 다른 완료 패턴을 낸다', () async {
    final cues = <FeedbackCue>[];
    final feedback = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    feedback.restorationCompleted(IslandLandmark.observatory);
    feedback.restorationCompleted(IslandLandmark.lighthouse);
    feedback.restorationCompleted(IslandLandmark.bridge);
    await _flushFeedback();

    expect(cues, [
      FeedbackCue.observatoryRestored,
      FeedbackCue.lighthouseRestored,
      FeedbackCue.bridgeRestored,
    ]);
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

  test('같은 재질도 실제 충격량에 따라 가벼운 타격과 강한 타격을 구분한다', () async {
    final cues = <FeedbackCue>[];
    final light = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );
    final heavy = GameFeedback(
      soundPlayer: (_) async {},
      cuePlayer: (cue) async => cues.add(cue),
    );

    light.collision(EntityType.wall, impactStrength: 0.18);
    heavy.collision(EntityType.wall, impactStrength: 0.92);
    await _flushFeedback();

    expect(cues, [FeedbackCue.lightCollision, FeedbackCue.heavyCollision]);
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
      GameFeedback.chargeGaugeSidePreferenceKey: 'left',
      GameFeedback.playerDifficultyPreferenceKey: 'easy',
      GameFeedback.intentAssistStrengthPreferenceKey: 'comfortable',
    });
    GameFeedback.soundEnabled = true;
    GameFeedback.hapticsEnabled = true;
    GameFeedback.screenShakeEnabled = true;
    GameFeedback.screenShakeStrength = 2;
    GameFeedback.reducedMotionEnabled = false;

    await GameFeedback.loadPreferences();

    expect(GameFeedback.soundEnabled, isFalse);
    expect(GameFeedback.hapticsEnabled, isFalse);
    expect(GameFeedback.screenShakeEnabled, isFalse);
    expect(GameFeedback.reducedMotionEnabled, isTrue);
    expect(GameFeedback.chargeGaugeSide, ChargeGaugeSide.left);
    expect(GameFeedback.playerDifficulty, PlayerDifficulty.easy);
    expect(GameFeedback.intentAssistStrength, IntentAssistStrength.comfortable);
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
    GameFeedback.screenShakeStrength = 2;
    GameFeedback.reducedMotionEnabled = false;
  });

  test('기존 화면 흔들림 설정을 새 강도와 스키마로 마이그레이션한다', () async {
    SharedPreferences.setMockInitialValues({
      GameFeedback.soundPreferenceKey: true,
      GameFeedback.screenShakePreferenceKey: false,
    });

    await GameFeedback.loadPreferences();
    final preferences = await SharedPreferences.getInstance();

    expect(GameFeedback.screenShakeStrength, 0);
    expect(
      preferences.getInt(GameFeedback.settingsSchemaVersionKey),
      GameFeedback.settingsSchemaVersion,
    );
    expect(
      preferences.getInt(GameFeedback.screenShakeStrengthPreferenceKey),
      0,
    );
  });

  test('화면 흔들림 강도와 도움말 다시 보기를 저장한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await GameFeedback.setScreenShakeStrength(3);
    await GameFeedback.resetHelpPreferences();
    final preferences = await SharedPreferences.getInstance();

    expect(GameFeedback.screenShakeEnabled, isTrue);
    expect(
      preferences.getInt(GameFeedback.screenShakeStrengthPreferenceKey),
      3,
    );
    expect(preferences.getInt(GameFeedback.helpRevisionPreferenceKey), 1);
    expect(await GameFeedback.consumeHelpReplayRequest(), isTrue);
    expect(await GameFeedback.consumeHelpReplayRequest(), isFalse);
    expect(
      preferences.getInt(GameFeedback.helpAcknowledgedRevisionPreferenceKey),
      1,
    );
    GameFeedback.screenShakeStrength = 2;
    GameFeedback.helpRevision = 0;
  });

  test('구형 스키마를 6으로 올리며 기존 설정과 의도 보정 기본값을 보존한다', () async {
    SharedPreferences.setMockInitialValues({
      GameFeedback.settingsSchemaVersionKey: 4,
      GameFeedback.lastShotSlowMotionPreferenceKey: false,
      GameFeedback.collisionOrderPreferenceKey: false,
      GameFeedback.lastContactHighlightPreferenceKey: false,
      GameFeedback.nearestHolePreferenceKey: false,
      GameFeedback.traitActivationPreferenceKey: false,
      GameFeedback.gimmickCausalityPreferenceKey: false,
      GameFeedback.collisionPathIconsPreferenceKey: false,
      GameFeedback.chainScoreDetailsPreferenceKey: false,
      GameFeedback.strongFlashPreferenceKey: false,
      GameFeedback.backgroundMusicPreferenceKey: false,
    });

    await GameFeedback.loadPreferences();
    final preferences = await SharedPreferences.getInstance();

    expect(GameFeedback.lastShotSlowMotionEnabled, isFalse);
    expect(GameFeedback.collisionOrderEnabled, isFalse);
    expect(GameFeedback.lastContactHighlightEnabled, isFalse);
    expect(GameFeedback.nearestHoleEnabled, isFalse);
    expect(GameFeedback.traitActivationEnabled, isFalse);
    expect(GameFeedback.gimmickCausalityEnabled, isFalse);
    expect(GameFeedback.collisionPathIconsEnabled, isFalse);
    expect(GameFeedback.chainScoreDetailsEnabled, isFalse);
    expect(GameFeedback.strongFlashEnabled, isFalse);
    expect(GameFeedback.backgroundMusicEnabled, isFalse);
    expect(GameFeedback.previousAimComparisonEnabled, isTrue);
    expect(GameFeedback.chargeGaugeSide, ChargeGaugeSide.right);
    expect(GameFeedback.playerDifficulty, PlayerDifficulty.normal);
    expect(GameFeedback.intentAssistStrength, IntentAssistStrength.standard);
    expect(
      preferences.getInt(GameFeedback.settingsSchemaVersionKey),
      GameFeedback.settingsSchemaVersion,
    );
    expect(
      preferences.getString(GameFeedback.chargeGaugeSidePreferenceKey),
      'right',
    );
    expect(
      preferences.getString(GameFeedback.playerDifficultyPreferenceKey),
      'normal',
    );
    expect(
      preferences.getString(GameFeedback.intentAssistStrengthPreferenceKey),
      'standard',
    );
    expect(
      preferences.getBool(GameFeedback.previousAimComparisonPreferenceKey),
      isTrue,
    );
  });

  test('새 개별 설정 변경은 각각의 안정 키에 저장된다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await GameFeedback.setLastShotSlowMotionEnabled(true);
    await GameFeedback.setCollisionOrderEnabled(true);
    await GameFeedback.setLastContactHighlightEnabled(true);
    await GameFeedback.setNearestHoleEnabled(true);
    await GameFeedback.setTraitActivationEnabled(true);
    await GameFeedback.setGimmickCausalityEnabled(true);
    await GameFeedback.setCollisionPathIconsEnabled(true);
    await GameFeedback.setChainScoreDetailsEnabled(true);
    await GameFeedback.setPreviousAimComparisonEnabled(false);
    await GameFeedback.setStrongFlashEnabled(true);
    await GameFeedback.setBackgroundMusicEnabled(false);
    await GameFeedback.setChargeGaugeSide(ChargeGaugeSide.left);
    await GameFeedback.setPlayerDifficulty(PlayerDifficulty.easy);
    await GameFeedback.setIntentAssistStrength(
      IntentAssistStrength.comfortable,
    );
    final preferences = await SharedPreferences.getInstance();

    for (final key in const [
      GameFeedback.lastShotSlowMotionPreferenceKey,
      GameFeedback.collisionOrderPreferenceKey,
      GameFeedback.lastContactHighlightPreferenceKey,
      GameFeedback.nearestHolePreferenceKey,
      GameFeedback.traitActivationPreferenceKey,
      GameFeedback.gimmickCausalityPreferenceKey,
      GameFeedback.collisionPathIconsPreferenceKey,
      GameFeedback.chainScoreDetailsPreferenceKey,
      GameFeedback.strongFlashPreferenceKey,
    ]) {
      expect(preferences.getBool(key), isTrue, reason: key);
    }
    expect(
      preferences.getBool(GameFeedback.backgroundMusicPreferenceKey),
      isFalse,
    );
    expect(
      preferences.getString(GameFeedback.chargeGaugeSidePreferenceKey),
      'left',
    );
    expect(
      preferences.getString(GameFeedback.playerDifficultyPreferenceKey),
      'easy',
    );
    expect(
      preferences.getString(GameFeedback.intentAssistStrengthPreferenceKey),
      'comfortable',
    );
    expect(
      preferences.getBool(GameFeedback.previousAimComparisonPreferenceKey),
      isFalse,
    );
  });

  test('알 수 없는 새 설정 값은 안전한 기본값으로 복원한다', () async {
    SharedPreferences.setMockInitialValues({
      GameFeedback.settingsSchemaVersionKey: GameFeedback.settingsSchemaVersion,
      GameFeedback.chargeGaugeSidePreferenceKey: 'center',
      GameFeedback.playerDifficultyPreferenceKey: 'expert',
      GameFeedback.intentAssistStrengthPreferenceKey: 'unlimited',
    });

    await GameFeedback.loadPreferences();

    expect(GameFeedback.chargeGaugeSide, ChargeGaugeSide.right);
    expect(GameFeedback.playerDifficulty, PlayerDifficulty.normal);
    expect(GameFeedback.intentAssistStrength, IntentAssistStrength.standard);
    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(GameFeedback.chargeGaugeSidePreferenceKey),
      'right',
    );
    expect(
      preferences.getString(GameFeedback.playerDifficultyPreferenceKey),
      'normal',
    );
    expect(
      preferences.getString(GameFeedback.intentAssistStrengthPreferenceKey),
      'standard',
    );
  });

  test('15개 설정을 30회 반복 변경해도 마지막 상태를 정확히 복원한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    for (var round = 0; round < 30; round++) {
      final enabled = round.isEven;
      await GameFeedback.setSoundEnabled(enabled);
      await GameFeedback.setBackgroundMusicEnabled(enabled);
      await GameFeedback.setHapticsEnabled(enabled);
      await GameFeedback.setReducedMotionEnabled(enabled);
      await GameFeedback.setScreenShakeStrength(enabled ? 3 : 0);
      await GameFeedback.setLastShotSlowMotionEnabled(enabled);
      await GameFeedback.setCollisionOrderEnabled(enabled);
      await GameFeedback.setLastContactHighlightEnabled(enabled);
      await GameFeedback.setNearestHoleEnabled(enabled);
      await GameFeedback.setTraitActivationEnabled(enabled);
      await GameFeedback.setGimmickCausalityEnabled(enabled);
      await GameFeedback.setCollisionPathIconsEnabled(enabled);
      await GameFeedback.setChainScoreDetailsEnabled(enabled);
      await GameFeedback.setPreviousAimComparisonEnabled(enabled);
      await GameFeedback.setStrongFlashEnabled(enabled);
    }

    GameFeedback.resetForTesting();
    await GameFeedback.loadPreferences();

    expect(GameFeedback.soundEnabled, isFalse);
    expect(GameFeedback.backgroundMusicEnabled, isFalse);
    expect(GameFeedback.hapticsEnabled, isFalse);
    expect(GameFeedback.reducedMotionEnabled, isFalse);
    expect(GameFeedback.screenShakeEnabled, isFalse);
    expect(GameFeedback.screenShakeStrength, 0);
    expect(GameFeedback.lastShotSlowMotionEnabled, isFalse);
    expect(GameFeedback.collisionOrderEnabled, isFalse);
    expect(GameFeedback.lastContactHighlightEnabled, isFalse);
    expect(GameFeedback.nearestHoleEnabled, isFalse);
    expect(GameFeedback.traitActivationEnabled, isFalse);
    expect(GameFeedback.gimmickCausalityEnabled, isFalse);
    expect(GameFeedback.collisionPathIconsEnabled, isFalse);
    expect(GameFeedback.chainScoreDetailsEnabled, isFalse);
    expect(GameFeedback.previousAimComparisonEnabled, isFalse);
    expect(GameFeedback.strongFlashEnabled, isFalse);
  });
}

Future<void> _flushFeedback() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
