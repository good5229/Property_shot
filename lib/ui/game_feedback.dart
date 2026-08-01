import 'dart:async';

import 'package:flutter/services.dart';

import '../game/domain/entity_state.dart';

/// 외부 오디오 파일 없이 플랫폼 기본 피드백을 조합한다.
/// 웹이나 무음·미지원 플랫폼에서 실패해도 게임 상태에는 영향을 주지 않는다.
class GameFeedback {
  final Map<String, DateTime> _lastPlayed = <String, DateTime>{};

  void traitSelected() {
    _emit(
      'trait_selected',
      haptic: HapticFeedback.selectionClick,
      sound: false,
    );
  }

  void traitTransferred() {
    _emit('trait_transferred', haptic: HapticFeedback.mediumImpact);
  }

  void traitCopied() {
    _emit('trait_copied', haptic: HapticFeedback.selectionClick);
  }

  void shotLaunched() {
    _emit('shot_launched', haptic: HapticFeedback.mediumImpact);
  }

  void collision(EntityType type) {
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
    );
  }

  void switchOpened() {
    _emit('switch_opened', haptic: HapticFeedback.heavyImpact);
  }

  void shotCleared() {
    _emit('shot_cleared', haptic: HapticFeedback.heavyImpact, alert: true);
  }

  void shotFailed() {
    _emit('shot_failed', haptic: HapticFeedback.mediumImpact, alert: true);
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
  }) {
    final now = DateTime.now();
    final previous = _lastPlayed[key];
    if (previous != null && now.difference(previous) < minimumInterval) {
      return;
    }
    _lastPlayed[key] = now;
    unawaited(
      Future.wait<void>([
        if (haptic != null) _safe(haptic),
        if (sound)
          _safe(
            () => SystemSound.play(
              alert ? SystemSoundType.alert : SystemSoundType.click,
            ),
          ),
      ]),
    );
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
