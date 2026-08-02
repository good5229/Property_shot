import 'dart:async';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/domain/entity_state.dart';
import 'feedback_audio.dart';

typedef SoundPlayer = Future<void> Function(SystemSoundType type);
typedef SoundCuePlayer = Future<void> Function(FeedbackCue cue);

/// 외부 오디오 파일 없이 플랫폼 기본 피드백을 조합한다.
/// 웹이나 무음·미지원 플랫폼에서 실패해도 게임 상태에는 영향을 주지 않는다.
class GameFeedback {
  GameFeedback({SoundPlayer? soundPlayer, SoundCuePlayer? cuePlayer})
    : _soundPlayer = soundPlayer ?? _playSystemSound,
      _cuePlayer = cuePlayer ?? playFeedbackCue;

  static const soundPreferenceKey = 'property_shot_sound_enabled';
  static const hapticsPreferenceKey = 'property_shot_haptics_enabled';
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

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
      hapticsEnabled = preferences.getBool(hapticsPreferenceKey) ?? true;
    } on Exception {
      // 설정 저장소를 사용할 수 없는 환경에서도 기본값으로 계속 실행한다.
    }
  }

  static Future<void> setSoundEnabled(bool enabled) async {
    soundEnabled = enabled;
    await _savePreference(soundPreferenceKey, enabled);
  }

  static Future<void> setHapticsEnabled(bool enabled) async {
    hapticsEnabled = enabled;
    await _savePreference(hapticsPreferenceKey, enabled);
  }

  static Future<void> _savePreference(String key, bool value) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(key, value);
    } on Exception {
      // 웹·테스트 환경의 저장소 실패는 피드백 자체를 중단시키지 않는다.
    }
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

  void collision(EntityType type, {bool emphasizeJelly = false}) {
    final haptic = switch (type) {
      EntityType.wall ||
      EntityType.gate ||
      EntityType.weight => HapticFeedback.heavyImpact,
      EntityType.crate ||
      EntityType.ball ||
      EntityType.switchPad => HapticFeedback.mediumImpact,
      EntityType.bumper => HapticFeedback.lightImpact,
      EntityType.stickySurface => HapticFeedback.selectionClick,
      EntityType.hole => HapticFeedback.heavyImpact,
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
        EntityType.wall ||
        EntityType.gate ||
        EntityType.weight => FeedbackCue.heavyCollision,
        _ => FeedbackCue.lightCollision,
      },
      alert:
          type == EntityType.wall ||
          type == EntityType.gate ||
          type == EntityType.weight ||
          type == EntityType.hole,
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
