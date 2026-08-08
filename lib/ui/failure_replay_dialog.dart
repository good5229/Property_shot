import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/analysis/failure_replay.dart';
import '../game/property_shot_game.dart';
import 'game_feedback.dart';

class FailureReplayDialog extends StatefulWidget {
  const FailureReplayDialog({super.key, required this.data});

  final FailureReplayData data;

  @override
  State<FailureReplayDialog> createState() => _FailureReplayDialogState();
}

class _FailureReplayDialogState extends State<FailureReplayDialog> {
  late final FailureReplayAnalysis _analysis;
  late final PropertyShotGame _game;
  bool _playing = true;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _analysis = const FailureReplayAnalyzer().analyze(widget.data);
    _game = PropertyShotGame(
      widget.data.result.state,
      loadVisualAssets: true,
      reducedMotion: GameFeedback.reducedMotionEnabled,
      screenShake: false,
      onAnimationFinished: () {
        if (!mounted) return;
        setState(() {
          _playing = false;
          _finished = true;
        });
      },
    )..setPlaybackSpeed(0.5);
    _startReplay();
  }

  void _startReplay() {
    _game.setStateSnapshot(
      widget.data.result.state,
      path: widget.data.result.path,
      transitionStart: widget.data.beforeState,
      moves: widget.data.result.moves,
      impacts: widget.data.result.impacts,
      physicsEvents: widget.data.result.physicsEvents,
      animationTransaction: true,
    );
    final start = math.max(
      0,
      _game.animationEndCursorForTest -
          PropertyShotGame.animationCursorUnitsPerSecond * 3,
    );
    _game.setAnimationCursorForReplay(start.toDouble());
    _playing = true;
    _finished = false;
  }

  void _togglePlayback() {
    if (_finished) {
      setState(_startReplay);
      return;
    }
    setState(() {
      _playing = !_playing;
      _game.setPlaybackSpeed(_playing ? 0.5 : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = math.min(520.0, math.max(280.0, size.width - 32));
    final height = math.min(560.0, math.max(300.0, size.height - 48));
    return Dialog(
      key: const Key('failure_replay_dialog'),
      child: SizedBox(
        width: width,
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _analysis.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_analysis.detail),
                      const SizedBox(height: 10),
                      Semantics(
                        label: '실패 직전 충돌 재생 화면',
                        container: true,
                        child: SizedBox(
                          key: const Key('failure_replay_view'),
                          height: 230,
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ColoredBox(
                              color: const Color(0xFFBFE8E3),
                              child: GameWidget(game: _game),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '실패 직전 3초 · 반속도 재생',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          FilledButton.icon(
                            key: const Key('failure_replay_play_button'),
                            onPressed: _togglePlayback,
                            icon: Icon(
                              _playing ? Icons.pause : Icons.play_arrow,
                            ),
                            label: Text(
                              _finished ? '다시 재생' : (_playing ? '일시정지' : '재생'),
                            ),
                          ),
                          if (_analysis.lastContact != null)
                            Chip(
                              avatar: const Icon(Icons.adjust, size: 16),
                              label: Text(
                                '마지막 접촉: ${_analysis.lastContact!.label}',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_analysis.markers.isNotEmpty) ...[
                        const Text('충돌 순서'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final marker in _analysis.markers)
                              Chip(
                                backgroundColor: marker.highlight
                                    ? const Color(0xFFFFE0A6)
                                    : null,
                                label: Text(marker.label),
                              ),
                          ],
                        ),
                      ],
                      if (_analysis.nearestHole != null) ...[
                        const SizedBox(height: 6),
                        const Text('홀과 가장 가까웠던 위치가 재생 화면에 포함되어 있어요.'),
                      ],
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  key: const Key('failure_replay_close_button'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
