import 'dart:async';

import 'package:flutter/foundation.dart';

import 'feedback_audio.dart';

/// 기존 합성 효과음 경로를 재사용하는 웹 데모용 잔잔한 반복 모티프다.
class BackgroundMusicController {
  Timer? _timer;
  bool _enabled = false;

  Future<void> setEnabled(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    _timer?.cancel();
    _timer = null;
    if (!enabled || !kIsWeb) return;
    await _playSafely();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      unawaited(_playSafely());
    });
  }

  Future<void> _playSafely() async {
    try {
      await playFeedbackCue(FeedbackCue.aimCharge);
    } on Object {
      // 오디오 미지원 환경에서도 설정과 게임 진행은 유지한다.
    }
  }
}

final BackgroundMusicController _backgroundMusic = BackgroundMusicController();

Future<void> setBackgroundMusicPlayback(bool enabled) {
  return _backgroundMusic.setEnabled(enabled);
}
