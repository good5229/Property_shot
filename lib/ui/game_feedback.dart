import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/domain/entity_state.dart';
import '../game/input/intent_assist_resolver.dart';
import '../game/simulation/impact_metrics.dart';
import 'background_music.dart';
import 'feedback_audio.dart';

typedef SoundPlayer = Future<void> Function(SystemSoundType type);
typedef SoundCuePlayer = Future<void> Function(FeedbackCue cue);

enum ChargeGaugeSide { right, left }

enum PlayerDifficulty { normal, easy }

/// 외부 오디오 파일 없이 플랫폼 기본 피드백을 조합한다.
/// 웹이나 무음·미지원 플랫폼에서 실패해도 게임 상태에는 영향을 주지 않는다.
class GameFeedback {
  GameFeedback({SoundPlayer? soundPlayer, SoundCuePlayer? cuePlayer})
    : _soundPlayer = soundPlayer ?? _playSystemSound,
      _cuePlayer = cuePlayer ?? playFeedbackCue;

  static const soundPreferenceKey = 'property_shot_sound_enabled';
  static const backgroundMusicPreferenceKey =
      'property_shot_background_music_enabled';
  static const hapticsPreferenceKey = 'property_shot_haptics_enabled';
  static const reducedMotionPreferenceKey =
      'property_shot_reduced_motion_enabled';
  static const screenShakePreferenceKey = 'property_shot_screen_shake_enabled';
  static const screenShakeStrengthPreferenceKey =
      'property_shot_screen_shake_strength';
  static const lastShotSlowMotionPreferenceKey =
      'property_shot_last_shot_slow_motion_enabled';
  static const collisionOrderPreferenceKey =
      'property_shot_collision_order_enabled';
  static const lastContactHighlightPreferenceKey =
      'property_shot_last_contact_highlight_enabled';
  static const nearestHolePreferenceKey = 'property_shot_nearest_hole_enabled';
  static const traitActivationPreferenceKey =
      'property_shot_trait_activation_enabled';
  static const gimmickCausalityPreferenceKey =
      'property_shot_gimmick_causality_enabled';
  static const collisionPathIconsPreferenceKey =
      'property_shot_collision_path_icons_enabled';
  static const chainScoreDetailsPreferenceKey =
      'property_shot_chain_score_details_enabled';
  static const previousAimComparisonPreferenceKey =
      'property_shot_previous_aim_comparison_enabled';
  static const strongFlashPreferenceKey = 'property_shot_strong_flash_enabled';
  static const chargeGaugeSidePreferenceKey = 'property_shot_charge_gauge_side';
  static const playerDifficultyPreferenceKey =
      'property_shot_player_difficulty';
  static const intentAssistStrengthPreferenceKey =
      'property_shot_intent_assist_strength';
  static const helpRevisionPreferenceKey = 'property_shot_help_revision';
  static const helpAcknowledgedRevisionPreferenceKey =
      'property_shot_help_acknowledged_revision';
  static const settingsSchemaVersionKey =
      'property_shot_settings_schema_version';
  static const settingsSchemaVersion = 6;
  static bool soundEnabled = true;
  static bool backgroundMusicEnabled = true;
  static bool hapticsEnabled = true;
  static bool reducedMotionEnabled = false;
  static bool screenShakeEnabled = true;
  static bool lastShotSlowMotionEnabled = true;
  static bool collisionOrderEnabled = true;
  static bool lastContactHighlightEnabled = true;
  static bool nearestHoleEnabled = true;
  static bool traitActivationEnabled = true;
  static bool gimmickCausalityEnabled = true;
  static bool collisionPathIconsEnabled = true;
  static bool chainScoreDetailsEnabled = true;
  static bool previousAimComparisonEnabled = true;
  static bool strongFlashEnabled = true;
  static ChargeGaugeSide chargeGaugeSide = ChargeGaugeSide.right;
  static PlayerDifficulty playerDifficulty = PlayerDifficulty.normal;
  static IntentAssistStrength intentAssistStrength =
      IntentAssistStrength.standard;
  static int screenShakeStrength = 2;
  static int helpRevision = 0;
  static Future<void>? _preferenceWriteTail;

  @visibleForTesting
  static void resetForTesting() {
    soundEnabled = true;
    backgroundMusicEnabled = true;
    hapticsEnabled = true;
    reducedMotionEnabled = false;
    screenShakeEnabled = true;
    lastShotSlowMotionEnabled = true;
    collisionOrderEnabled = true;
    lastContactHighlightEnabled = true;
    nearestHoleEnabled = true;
    traitActivationEnabled = true;
    gimmickCausalityEnabled = true;
    collisionPathIconsEnabled = true;
    chainScoreDetailsEnabled = true;
    previousAimComparisonEnabled = true;
    strongFlashEnabled = true;
    chargeGaugeSide = ChargeGaugeSide.right;
    playerDifficulty = PlayerDifficulty.normal;
    intentAssistStrength = IntentAssistStrength.standard;
    screenShakeStrength = 2;
    helpRevision = 0;
    _preferenceWriteTail = null;
  }

  final SoundPlayer _soundPlayer;
  final SoundCuePlayer _cuePlayer;
  final Map<String, DateTime> _lastPlayed = <String, DateTime>{};
  Future<void>? _audioTail;

  static Future<void> _playSystemSound(SystemSoundType type) {
    return SystemSound.play(type);
  }

  static Future<void> loadPreferences() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      soundEnabled = preferences.getBool(soundPreferenceKey) ?? true;
      backgroundMusicEnabled =
          preferences.getBool(backgroundMusicPreferenceKey) ?? true;
      hapticsEnabled = preferences.getBool(hapticsPreferenceKey) ?? true;
      reducedMotionEnabled =
          preferences.getBool(reducedMotionPreferenceKey) ?? false;
      final storedScreenShakeEnabled = preferences.getBool(
        screenShakePreferenceKey,
      );
      final storedStrength = preferences.getInt(
        screenShakeStrengthPreferenceKey,
      );
      screenShakeStrength = storedStrength == null
          ? ((storedScreenShakeEnabled ?? true) ? 2 : 0)
          : storedStrength.clamp(0, 3).toInt();
      screenShakeEnabled = storedStrength == null
          ? (storedScreenShakeEnabled ?? true)
          : (storedScreenShakeEnabled ?? screenShakeStrength > 0) &&
                screenShakeStrength > 0;
      lastShotSlowMotionEnabled =
          preferences.getBool(lastShotSlowMotionPreferenceKey) ?? true;
      collisionOrderEnabled =
          preferences.getBool(collisionOrderPreferenceKey) ?? true;
      lastContactHighlightEnabled =
          preferences.getBool(lastContactHighlightPreferenceKey) ?? true;
      nearestHoleEnabled =
          preferences.getBool(nearestHolePreferenceKey) ?? true;
      traitActivationEnabled =
          preferences.getBool(traitActivationPreferenceKey) ?? true;
      gimmickCausalityEnabled =
          preferences.getBool(gimmickCausalityPreferenceKey) ?? true;
      collisionPathIconsEnabled =
          preferences.getBool(collisionPathIconsPreferenceKey) ?? true;
      chainScoreDetailsEnabled =
          preferences.getBool(chainScoreDetailsPreferenceKey) ?? true;
      previousAimComparisonEnabled =
          preferences.getBool(previousAimComparisonPreferenceKey) ?? true;
      strongFlashEnabled =
          preferences.getBool(strongFlashPreferenceKey) ?? true;
      final storedChargeGaugeSide = preferences.getString(
        chargeGaugeSidePreferenceKey,
      );
      final storedPlayerDifficulty = preferences.getString(
        playerDifficultyPreferenceKey,
      );
      final storedIntentAssistStrength = preferences.getString(
        intentAssistStrengthPreferenceKey,
      );
      chargeGaugeSide = _chargeGaugeSideFromStorage(storedChargeGaugeSide);
      playerDifficulty = _playerDifficultyFromStorage(storedPlayerDifficulty);
      intentAssistStrength = _intentAssistStrengthFromStorage(
        storedIntentAssistStrength,
      );
      helpRevision = (preferences.getInt(helpRevisionPreferenceKey) ?? 0)
          .clamp(0, 999999)
          .toInt();
      if (preferences.getInt(settingsSchemaVersionKey) !=
          settingsSchemaVersion) {
        await preferences.setInt(
          settingsSchemaVersionKey,
          settingsSchemaVersion,
        );
        await preferences.setInt(
          screenShakeStrengthPreferenceKey,
          screenShakeStrength,
        );
        await _writeCurrentSettings(preferences);
      } else {
        if (storedChargeGaugeSide != chargeGaugeSide.name) {
          await preferences.setString(
            chargeGaugeSidePreferenceKey,
            chargeGaugeSide.name,
          );
        }
        if (storedPlayerDifficulty != playerDifficulty.name) {
          await preferences.setString(
            playerDifficultyPreferenceKey,
            playerDifficulty.name,
          );
        }
        if (storedIntentAssistStrength != intentAssistStrength.name) {
          await preferences.setString(
            intentAssistStrengthPreferenceKey,
            intentAssistStrength.name,
          );
        }
      }
    } on Exception {
      // 설정 저장소를 사용할 수 없는 환경에서도 기본값으로 계속 실행한다.
    }
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _savePreference(soundPreferenceKey, enabled);
  }

  static Future<void> setBackgroundMusicEnabled(bool enabled) async {
    backgroundMusicEnabled = enabled;
    await _savePreference(backgroundMusicPreferenceKey, enabled);
    await setBackgroundMusicPlayback(enabled);
  }

  static Future<void> activateBackgroundMusic() async {
    await setBackgroundMusicPlayback(backgroundMusicEnabled);
  }

  static Future<void> setHapticsEnabled(bool enabled) async {
    hapticsEnabled = enabled;
    await _savePreference(hapticsPreferenceKey, enabled);
  }

  static Future<void> setReducedMotionEnabled(bool enabled) async {
    reducedMotionEnabled = enabled;
    await _savePreference(reducedMotionPreferenceKey, enabled);
  }

  static Future<void> setLastShotSlowMotionEnabled(bool enabled) =>
      _setBoolean(lastShotSlowMotionPreferenceKey, enabled, (value) {
        lastShotSlowMotionEnabled = value;
      });

  static Future<void> setCollisionOrderEnabled(bool enabled) =>
      _setBoolean(collisionOrderPreferenceKey, enabled, (value) {
        collisionOrderEnabled = value;
      });

  static Future<void> setLastContactHighlightEnabled(bool enabled) =>
      _setBoolean(lastContactHighlightPreferenceKey, enabled, (value) {
        lastContactHighlightEnabled = value;
      });

  static Future<void> setNearestHoleEnabled(bool enabled) =>
      _setBoolean(nearestHolePreferenceKey, enabled, (value) {
        nearestHoleEnabled = value;
      });

  static Future<void> setTraitActivationEnabled(bool enabled) =>
      _setBoolean(traitActivationPreferenceKey, enabled, (value) {
        traitActivationEnabled = value;
      });

  static Future<void> setGimmickCausalityEnabled(bool enabled) =>
      _setBoolean(gimmickCausalityPreferenceKey, enabled, (value) {
        gimmickCausalityEnabled = value;
      });

  static Future<void> setCollisionPathIconsEnabled(bool enabled) =>
      _setBoolean(collisionPathIconsPreferenceKey, enabled, (value) {
        collisionPathIconsEnabled = value;
      });

  static Future<void> setChainScoreDetailsEnabled(bool enabled) =>
      _setBoolean(chainScoreDetailsPreferenceKey, enabled, (value) {
        chainScoreDetailsEnabled = value;
      });

  static Future<void> setPreviousAimComparisonEnabled(bool enabled) =>
      _setBoolean(previousAimComparisonPreferenceKey, enabled, (value) {
        previousAimComparisonEnabled = value;
      });

  static Future<void> setStrongFlashEnabled(bool enabled) =>
      _setBoolean(strongFlashPreferenceKey, enabled, (value) {
        strongFlashEnabled = value;
      });

  static Future<void> setChargeGaugeSide(ChargeGaugeSide side) async {
    chargeGaugeSide = side;
    await _savePreferenceString(chargeGaugeSidePreferenceKey, side.name);
  }

  static Future<void> setPlayerDifficulty(PlayerDifficulty difficulty) async {
    playerDifficulty = difficulty;
    await _savePreferenceString(playerDifficultyPreferenceKey, difficulty.name);
  }

  static Future<void> setIntentAssistStrength(
    IntentAssistStrength strength,
  ) async {
    intentAssistStrength = strength;
    await _savePreferenceString(
      intentAssistStrengthPreferenceKey,
      strength.name,
    );
  }

  static Future<void> _setBoolean(
    String key,
    bool enabled,
    void Function(bool) apply,
  ) async {
    apply(enabled);
    await _savePreference(key, enabled);
  }

  static Future<void> setScreenShakeEnabled(bool enabled) async {
    screenShakeEnabled = enabled;
    if (!enabled) screenShakeStrength = 0;
    if (enabled && screenShakeStrength == 0) screenShakeStrength = 2;
    await _savePreference(screenShakePreferenceKey, enabled);
    await _savePreferenceInt(
      screenShakeStrengthPreferenceKey,
      screenShakeStrength,
    );
  }

  static Future<void> setScreenShakeStrength(int strength) async {
    screenShakeStrength = strength.clamp(0, 3).toInt();
    screenShakeEnabled = screenShakeStrength > 0;
    await _savePreferenceInt(
      screenShakeStrengthPreferenceKey,
      screenShakeStrength,
    );
    await _savePreference(screenShakePreferenceKey, screenShakeEnabled);
  }

  static Future<void> resetHelpPreferences() async {
    helpRevision = (helpRevision + 1).clamp(0, 999999).toInt();
    await _savePreferenceInt(helpRevisionPreferenceKey, helpRevision);
  }

  /// 설정에서 요청한 도움말을 다음 플레이 진입에서 정확히 한 번 소비한다.
  static Future<bool> consumeHelpReplayRequest() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final acknowledged =
          preferences.getInt(helpAcknowledgedRevisionPreferenceKey) ?? 0;
      if (helpRevision <= acknowledged) return false;
      await preferences.setInt(
        helpAcknowledgedRevisionPreferenceKey,
        helpRevision,
      );
      return true;
    } on Exception {
      return false;
    }
  }

  static Future<void> _savePreference(String key, bool value) async {
    await _enqueuePreferenceWrite(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(key, value);
    });
  }

  static Future<void> _savePreferenceInt(String key, int value) async {
    await _enqueuePreferenceWrite(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setInt(key, value);
    });
  }

  static Future<void> _savePreferenceString(String key, String value) async {
    await _enqueuePreferenceWrite(() async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, value);
    });
  }

  static Future<void> _writeCurrentSettings(
    SharedPreferences preferences,
  ) async {
    final values = <String, bool>{
      soundPreferenceKey: soundEnabled,
      backgroundMusicPreferenceKey: backgroundMusicEnabled,
      hapticsPreferenceKey: hapticsEnabled,
      reducedMotionPreferenceKey: reducedMotionEnabled,
      screenShakePreferenceKey: screenShakeEnabled,
      lastShotSlowMotionPreferenceKey: lastShotSlowMotionEnabled,
      collisionOrderPreferenceKey: collisionOrderEnabled,
      lastContactHighlightPreferenceKey: lastContactHighlightEnabled,
      nearestHolePreferenceKey: nearestHoleEnabled,
      traitActivationPreferenceKey: traitActivationEnabled,
      gimmickCausalityPreferenceKey: gimmickCausalityEnabled,
      collisionPathIconsPreferenceKey: collisionPathIconsEnabled,
      chainScoreDetailsPreferenceKey: chainScoreDetailsEnabled,
      previousAimComparisonPreferenceKey: previousAimComparisonEnabled,
      strongFlashPreferenceKey: strongFlashEnabled,
    };
    for (final entry in values.entries) {
      await preferences.setBool(entry.key, entry.value);
    }
    await preferences.setString(
      chargeGaugeSidePreferenceKey,
      chargeGaugeSide.name,
    );
    await preferences.setString(
      playerDifficultyPreferenceKey,
      playerDifficulty.name,
    );
    await preferences.setString(
      intentAssistStrengthPreferenceKey,
      intentAssistStrength.name,
    );
  }

  static ChargeGaugeSide _chargeGaugeSideFromStorage(String? stored) {
    return switch (stored) {
      'left' => ChargeGaugeSide.left,
      _ => ChargeGaugeSide.right,
    };
  }

  static PlayerDifficulty _playerDifficultyFromStorage(String? stored) {
    return switch (stored) {
      'easy' => PlayerDifficulty.easy,
      _ => PlayerDifficulty.normal,
    };
  }

  static IntentAssistStrength _intentAssistStrengthFromStorage(
    String? stored,
  ) => switch (stored) {
    'off' => IntentAssistStrength.off,
    'comfortable' => IntentAssistStrength.comfortable,
    _ => IntentAssistStrength.standard,
  };

  static Future<void> _enqueuePreferenceWrite(
    Future<void> Function() action,
  ) async {
    final previous = _preferenceWriteTail ?? Future<void>.value();
    final next = previous.then((_) async {
      try {
        await action();
      } on Exception {
        // 웹·테스트 환경의 저장소 실패는 피드백 자체를 중단시키지 않는다.
      }
    });
    _preferenceWriteTail = next;
    await next;
  }

  void traitSelected() {
    _emit(
      'trait_selected',
      haptic: HapticFeedback.selectionClick,
      cue: FeedbackCue.ui,
    );
  }

  void traitTransferred() {
    _emit(
      'trait_transferred',
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.trait,
    );
  }

  void traitCopied() {
    _emit(
      'trait_copied',
      haptic: HapticFeedback.selectionClick,
      cue: FeedbackCue.copy,
    );
  }

  void copyCoreAwarded(int amount) {
    if (amount <= 0) {
      return;
    }
    _emit(
      'copy_core_awarded',
      minimumInterval: const Duration(milliseconds: 240),
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.copyCoreAwarded,
      alert: true,
    );
  }

  void aimChargeStarted() {
    _emit(
      'aim_charge_started',
      minimumInterval: const Duration(milliseconds: 300),
      cue: FeedbackCue.aimCharge,
      sound: true,
    );
  }

  void shotLaunched() {
    _emit(
      'shot_launched',
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.launch,
    );
  }

  void collision(
    EntityType type, {
    bool emphasizeJelly = false,
    double impactStrength = 0,
  }) {
    final effectiveStrength = impactStrength > 0
        ? impactStrength
        : switch (type) {
            EntityType.wall ||
            EntityType.gate ||
            EntityType.weight ||
            EntityType.hole => 0.8,
            EntityType.crate ||
            EntityType.ball ||
            EntityType.switchPad ||
            EntityType.rotatingReflector ||
            EntityType.balloon => 0.55,
            _ => 0.3,
          };
    final tier = ImpactMetrics.tierFor(effectiveStrength);
    final strengthHaptic = switch (tier) {
      ImpactTier.tap => HapticFeedback.selectionClick,
      ImpactTier.light => HapticFeedback.lightImpact,
      ImpactTier.heavy => HapticFeedback.mediumImpact,
      ImpactTier.critical => HapticFeedback.heavyImpact,
    };
    final haptic = switch (type) {
      EntityType.stickySurface => HapticFeedback.selectionClick,
      EntityType.hole => HapticFeedback.heavyImpact,
      _ => strengthHaptic,
    };
    _emit(
      'collision_${type.name}',
      minimumInterval: const Duration(milliseconds: 70),
      haptic: haptic,
      cue: switch (type) {
        EntityType.bumper =>
          emphasizeJelly
              ? FeedbackCue.jellyCollision
              : FeedbackCue.bouncyCollision,
        EntityType.stickySurface => FeedbackCue.stickyCollision,
        EntityType.hole => FeedbackCue.holeEntered,
        _ =>
          tier == ImpactTier.heavy || tier == ImpactTier.critical
              ? FeedbackCue.heavyCollision
              : FeedbackCue.lightCollision,
      },
      alert:
          type == EntityType.hole ||
          tier == ImpactTier.heavy ||
          tier == ImpactTier.critical,
    );
  }

  void powerSliderActivated() {
    _emit(
      'power_slider_activated',
      minimumInterval: const Duration(milliseconds: 70),
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.bouncyCollision,
      alert: true,
    );
  }

  void reflectorRotated() {
    _emit(
      'reflector_rotated',
      minimumInterval: const Duration(milliseconds: 70),
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.bouncyCollision,
      alert: true,
    );
  }

  void balloonPopped() {
    _emit(
      'balloon_popped',
      minimumInterval: const Duration(milliseconds: 100),
      haptic: HapticFeedback.heavyImpact,
      cue: FeedbackCue.heavyCollision,
      alert: true,
    );
  }

  void mysteryRevealed() {
    _emit(
      'mystery_revealed',
      minimumInterval: const Duration(milliseconds: 100),
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.mysteryReveal,
      alert: true,
    );
  }

  void switchOpened() {
    _emit(
      'switch_opened',
      haptic: HapticFeedback.heavyImpact,
      cue: FeedbackCue.switchPressed,
    );
  }

  void gateOpened() {
    _emit(
      'gate_opened',
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.gateOpened,
      alert: true,
    );
  }

  void shotCleared() {
    _emit(
      'shot_cleared',
      haptic: HapticFeedback.heavyImpact,
      cue: FeedbackCue.clear,
      alert: true,
    );
  }

  void medalAwarded(int stars) {
    if (stars <= 0) {
      return;
    }
    _emit(
      'medal_awarded',
      minimumInterval: const Duration(milliseconds: 240),
      haptic: HapticFeedback.lightImpact,
      cue: FeedbackCue.medal,
    );
  }

  void discoveryMilestone() {
    _emit(
      'discovery_milestone',
      minimumInterval: const Duration(milliseconds: 220),
      haptic: HapticFeedback.lightImpact,
      cue: FeedbackCue.discovery,
    );
  }

  void rewardActivated() {
    _emit(
      'reward_activated',
      minimumInterval: const Duration(milliseconds: 180),
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.rewardActivated,
    );
  }

  void restorationCompleted() {
    _emit(
      'restoration_completed',
      minimumInterval: const Duration(milliseconds: 400),
      haptic: HapticFeedback.heavyImpact,
      cue: FeedbackCue.restoration,
      alert: true,
    );
  }

  void labCompleted() {
    _emit(
      'lab_completed',
      minimumInterval: const Duration(milliseconds: 300),
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.labComplete,
    );
  }

  void shotFailed() {
    _emit(
      'shot_failed',
      haptic: HapticFeedback.mediumImpact,
      cue: FeedbackCue.fail,
      alert: true,
    );
  }

  void paused(bool isPaused) {
    _emit(
      isPaused ? 'paused' : 'resumed',
      haptic: HapticFeedback.selectionClick,
      sound: false,
    );
  }

  void cancelled() {
    _emit(
      'cancelled',
      minimumInterval: const Duration(milliseconds: 250),
      haptic: HapticFeedback.lightImpact,
      sound: false,
    );
  }

  void overchargeCancelled() {
    // 과충전은 짧은 이중 신호로 상태를 확실히 알린다.
    _emit(
      'overcharge_cancelled',
      minimumInterval: const Duration(milliseconds: 250),
      haptic: _playOverchargeHaptic,
      cue: FeedbackCue.fail,
      alert: true,
    );
  }

  static Future<void> _playOverchargeHaptic() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.lightImpact();
  }

  void _emit(
    String key, {
    Duration minimumInterval = const Duration(milliseconds: 120),
    Future<void> Function()? haptic,
    bool sound = true,
    bool alert = false,
    FeedbackCue cue = FeedbackCue.ui,
  }) {
    final now = DateTime.now();
    final previous = _lastPlayed[key];
    if (previous != null && now.difference(previous) < minimumInterval) {
      return;
    }
    _lastPlayed[key] = now;
    if (haptic != null && hapticsEnabled) {
      unawaited(_safe(haptic));
    }
    if (sound && soundEnabled) {
      _queueAudio(cue: cue, alert: alert);
    }
    if (backgroundMusicEnabled) {
      unawaited(setBackgroundMusicPlayback(true));
    }
  }

  void _queueAudio({required FeedbackCue cue, required bool alert}) {
    final previous = _audioTail;
    final next = previous == null
        ? _playAudio(cue: cue, alert: alert)
        : previous.then((_) => _playAudio(cue: cue, alert: alert));
    _audioTail = next;
    unawaited(
      next.whenComplete(() {
        if (identical(_audioTail, next)) {
          _audioTail = null;
        }
      }),
    );
  }

  Future<void> _playAudio({required FeedbackCue cue, required bool alert}) {
    return Future.wait<void>([
      _safe(() => _cuePlayer(cue)),
      _safe(
        () =>
            _soundPlayer(alert ? SystemSoundType.alert : SystemSoundType.click),
      ),
    ]);
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException {
      // 브라우저·시뮬레이터 등에서 지원되지 않는 플랫폼 기본 기능이다.
    } on PlatformException {
      // 무음 모드나 플랫폼 정책으로 거부되어도 게임은 계속 진행한다.
    } on StateError {
      // 오디오 세션이 준비되지 않은 짧은 초기화 구간을 허용한다.
    }
  }
}
