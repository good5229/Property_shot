import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/analysis/failure_replay.dart';
import '../game/property_shot_game.dart';
import 'game_feedback.dart';

class FailureReplayDialog extends StatefulWidget {
  const FailureReplayDialog({
    super.key,
    required this.data,
    this.autoplay = true,
  });

  final FailureReplayData data;
  final bool autoplay;

  @override
  State<FailureReplayDialog> createState() => _FailureReplayDialogState();
}

class _FailureReplayDialogState extends State<FailureReplayDialog> {
  late final FailureReplayAnalysis _analysis;
  late final PropertyShotGame _game;
  bool _playing = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _analysis = const FailureReplayAnalyzer().analyze(widget.data);
    final collisionMarkers = _analysis.markers
        .where((marker) => marker.kind == FailureReplayMarkerKind.collision)
        .toList(growable: false);
    final traitMarkers = _analysis.markers
        .where((marker) => marker.kind == FailureReplayMarkerKind.trait)
        .toList(growable: false);
    final gimmickMarkers = _analysis.markers
        .where((marker) => marker.kind == FailureReplayMarkerKind.gimmick)
        .toList(growable: false);
    _game = PropertyShotGame(
      widget.data.result.state,
      loadVisualAssets: true,
      reducedMotion: GameFeedback.reducedMotionEnabled,
      screenShake: false,
      strongFlash: GameFeedback.strongFlashEnabled,
      replayCollisionMarkers: GameFeedback.collisionPathIconsEnabled
          ? collisionMarkers.map((marker) => marker.position).toList()
          : const [],
      replayTraitMarkers: GameFeedback.traitActivationEnabled
          ? traitMarkers.map((marker) => marker.position).toList()
          : const [],
      replayGimmickMarkers: GameFeedback.gimmickCausalityEnabled
          ? gimmickMarkers.map((marker) => marker.position).toList()
          : const [],
      replayLastContact: GameFeedback.lastContactHighlightEnabled
          ? _analysis.lastContact?.position
          : null,
      replayNearestHole: GameFeedback.nearestHoleEnabled
          ? _analysis.nearestHole
          : null,
      onAnimationFinished: () {
        if (!mounted) return;
        setState(() {
          _playing = false;
          _finished = true;
        });
      },
    );
    _startReplay(
      playing: widget.autoplay && !GameFeedback.reducedMotionEnabled,
    );
  }

  @override
  void dispose() {
    _game.setPlaybackSpeed(0);
    super.dispose();
  }

  double get _replaySpeed => GameFeedback.lastShotSlowMotionEnabled ? 0.5 : 1.0;

  void _startReplay({bool playing = true}) {
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
    _playing = playing;
    _finished = false;
    _game.setPlaybackSpeed(playing ? _replaySpeed : 0);
  }

  void _togglePlayback() {
    if (_finished) {
      setState(_startReplay);
      return;
    }
    setState(() {
      _playing = !_playing;
      _game.setPlaybackSpeed(_playing ? _replaySpeed : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = math.min(520.0, math.max(280.0, size.width - 32));
    final height = math.min(680.0, math.max(300.0, size.height - 48));
    return Dialog(
      key: const Key('failure_replay_dialog'),
      child: SizedBox(
        key: const Key('failure_replay_panel'),
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
                        GameFeedback.lastShotSlowMotionEnabled
                            ? '실패 직전 3초 · 반속도 재생'
                            : '실패 직전 3초 · 보통 속도 재생',
                        key: const Key('failure_replay_speed_label'),
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
                          if (GameFeedback.lastContactHighlightEnabled &&
                              _analysis.lastContact != null)
                            Chip(
                              key: const Key('failure_replay_last_contact'),
                              avatar: const Icon(Icons.adjust, size: 16),
                              label: Text(
                                '마지막 접촉: ${_analysis.lastContact!.label}',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (GameFeedback.collisionOrderEnabled &&
                          _analysis.markers.any(
                            (marker) =>
                                marker.kind ==
                                FailureReplayMarkerKind.collision,
                          )) ...[
                        const Text('충돌 순서'),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            for (final marker in _analysis.markers.where(
                              (marker) =>
                                  marker.kind ==
                                  FailureReplayMarkerKind.collision,
                            ))
                              Chip(
                                backgroundColor: marker.highlight
                                    ? const Color(0xFFFFE0A6)
                                    : null,
                                label: Text(marker.label),
                              ),
                          ],
                        ),
                      ],
                      if (GameFeedback.traitActivationEnabled &&
                          _analysis.markers.any(
                            (marker) =>
                                marker.kind == FailureReplayMarkerKind.trait,
                          ))
                        _MarkerGroup(
                          key: const Key('failure_replay_trait_markers'),
                          title: '속성 발동',
                          markers: _analysis.markers
                              .where(
                                (marker) =>
                                    marker.kind ==
                                    FailureReplayMarkerKind.trait,
                              )
                              .toList(),
                        ),
                      if (GameFeedback.gimmickCausalityEnabled &&
                          _analysis.markers.any(
                            (marker) =>
                                marker.kind == FailureReplayMarkerKind.gimmick,
                          ))
                        _MarkerGroup(
                          key: const Key('failure_replay_gimmick_markers'),
                          title: '기믹 인과',
                          markers: _analysis.markers
                              .where(
                                (marker) =>
                                    marker.kind ==
                                    FailureReplayMarkerKind.gimmick,
                              )
                              .toList(),
                        ),
                      if (GameFeedback.nearestHoleEnabled &&
                          _analysis.nearestHole != null) ...[
                        const SizedBox(height: 6),
                        const Text(
                          '홀과 가장 가까웠던 위치가 재생 화면에 표시되어 있어요.',
                          key: Key('failure_replay_nearest_hole'),
                        ),
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

class _MarkerGroup extends StatelessWidget {
  const _MarkerGroup({super.key, required this.title, required this.markers});

  final String title;
  final List<FailureReplayMarker> markers;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 4),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final marker in markers) Chip(label: Text(marker.label)),
            ],
          ),
        ],
      ),
    );
  }
}
