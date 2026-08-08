import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

import 'runtime_environment.dart';

const backgroundMusicAsset = 'audio/property_shot_island_loop.wav';

abstract interface class BackgroundTrackBackend {
  Future<void> start();

  Future<void> stop();

  Future<void> dispose();
}

class AssetBackgroundTrackBackend implements BackgroundTrackBackend {
  AssetBackgroundTrackBackend({AudioPlayer? player})
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<void> start() async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.setPlayerMode(PlayerMode.mediaPlayer);
    await _player.setVolume(0.16);
    await _player.play(AssetSource(backgroundMusicAsset));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

/// 설정 변경과 오디오 초기화 실패를 직렬화하는 배경 음악 상태 기계다.
class BackgroundMusicController with WidgetsBindingObserver {
  BackgroundMusicController({BackgroundTrackBackend? backend})
    : _backend = backend,
      _playbackSupported = backend != null || !isAutomatedFlutterTest;

  BackgroundTrackBackend? _backend;
  final bool _playbackSupported;
  bool _enabled = false;
  bool _playing = false;
  bool _foreground = true;
  bool _observingLifecycle = false;
  Future<void> _tail = Future<void>.value();

  bool get enabled => _enabled;

  bool get playing => _playing;

  Future<void> setEnabled(bool enabled) {
    _observeLifecycle();
    _enabled = enabled;
    return _enqueue(_synchronize);
  }

  Future<void> retry() => _enqueue(_synchronize);

  Future<void> dispose() {
    _enabled = false;
    return _enqueue(() async {
      if (_playing) {
        await _stopSafely();
      }
      await _backend?.dispose();
      _backend = null;
      if (_observingLifecycle) {
        WidgetsBinding.instance.removeObserver(this);
        _observingLifecycle = false;
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(synchronizeLifecycleState(state));
  }

  @visibleForTesting
  Future<void> synchronizeLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    return _enqueue(_synchronize);
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final next = _tail.then((_) => operation());
    _tail = next.catchError((Object _) {});
    return next;
  }

  Future<void> _synchronize() async {
    if (!_enabled || !_foreground) {
      if (_playing) await _stopSafely();
      return;
    }
    if (!_playbackSupported) return;
    if (_playing) return;
    try {
      final backend = _backend ??= AssetBackgroundTrackBackend();
      await backend.start();
      if (!_enabled) {
        await backend.stop();
        return;
      }
      _playing = true;
    } on Object {
      // 자동 재생 제한이나 플랫폼 초기화 실패 뒤 다음 사용자 입력에서 재시도한다.
      _playing = false;
    }
  }

  Future<void> _stopSafely() async {
    try {
      await _backend?.stop();
    } on Object {
      // 중지 실패가 설정 저장이나 게임 진행을 막지 않게 한다.
    } finally {
      _playing = false;
    }
  }

  void _observeLifecycle() {
    if (_observingLifecycle || isAutomatedFlutterTest) return;
    WidgetsBinding.instance.addObserver(this);
    _observingLifecycle = true;
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
  }
}

final BackgroundMusicController _backgroundMusic = BackgroundMusicController();

Future<void> setBackgroundMusicPlayback(bool enabled) {
  return _backgroundMusic.setEnabled(enabled);
}
