import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../game/analysis/creative_chain_score.dart';
import '../game/levels/generated_stage_catalog.dart';
import '../game/property_shot_game.dart';
import '../game/replay/replay.dart';

class ReplayLibraryScreen extends StatefulWidget {
  const ReplayLibraryScreen({
    super.key,
    required this.store,
    required this.onBack,
    this.onReplayViewed,
  });

  final ReplayLibraryStore store;
  final VoidCallback onBack;
  final ValueChanged<ReplayDocument>? onReplayViewed;

  @override
  State<ReplayLibraryScreen> createState() => _ReplayLibraryScreenState();
}

class _ReplayLibraryScreenState extends State<ReplayLibraryScreen> {
  ReplayLibrarySnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final snapshot = await widget.store.load();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
        _error = null;
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '리플레이 기록을 불러오지 못했습니다.';
      });
    }
  }

  Future<void> _open(ReplayLibraryEntry entry) async {
    try {
      final document = await widget.store.readDocument(entry.replayId);
      if (document == null) throw StateError('리플레이 문서가 없습니다.');
      final playback = playbackDocument(document, generatedStageCatalog);
      widget.onReplayViewed?.call(document);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ReplayViewerScreen(
            entry: entry,
            document: document,
            playback: playback,
          ),
        ),
      );
    } on Object {
      _showMessage('현재 물리 버전에서 이 리플레이를 재생할 수 없습니다.');
    }
  }

  Future<void> _share(ReplayLibraryEntry entry) async {
    try {
      final document = await widget.store.readDocument(entry.replayId);
      if (document == null) throw StateError('리플레이 문서가 없습니다.');
      await Clipboard.setData(
        ClipboardData(text: ReplayShareCode.encode(document)),
      );
      _showMessage('공유 코드를 클립보드에 담았습니다.');
    } on Object {
      _showMessage('공유 코드를 만들지 못했습니다.');
    }
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리플레이 가져오기'),
        content: TextField(
          key: const Key('replay_share_code_input'),
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            labelText: '공유 코드',
            hintText: '받은 공유 코드를 붙여 넣으세요.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('검증하고 저장'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final document = ReplayShareCode.decode(raw);
      final playback = playbackDocument(document, generatedStageCatalog);
      final stage = generatedStageCatalog.stageById(document.stageId);
      final pattern = stage.patternById(document.patternId);
      final score = playback.shotResults.isEmpty
          ? 0
          : const CreativeChainScoreAnalyzer()
                .analyze(playback.shotResults, parShots: pattern.parShots)
                .totalScore;
      await widget.store.save(document: document, totalScore: score);
      await _load();
      _showMessage('검증된 리플레이를 저장했습니다.');
    } on Object {
      _showMessage('코드가 손상됐거나 현재 물리 버전과 맞지 않습니다.');
    }
  }

  Future<void> _delete(ReplayLibraryEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('리플레이 삭제'),
        content: const Text('이 기록을 기기에서 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.store.delete(entry.replayId);
    await _load();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final entries = _snapshot?.entries ?? const <ReplayLibraryEntry>[];
    return Scaffold(
      key: const Key('replay_library_screen'),
      backgroundColor: const Color(0xFFE9F4ED),
      appBar: AppBar(
        leading: IconButton(
          tooltip: '메인 메뉴로 돌아가기',
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('나의 리플레이'),
        actions: [
          IconButton(
            key: const Key('replay_import_button'),
            tooltip: '공유 코드 가져오기',
            onPressed: _import,
            icon: const Icon(Icons.input_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_error!),
              ),
            )
          : entries.isEmpty
          ? const Center(child: Text('아직 저장된 리플레이가 없습니다.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final stageNumber =
                    generatedStageCatalog.stages.indexWhere(
                      (stage) => stage.stageId == entry.stageId,
                    ) +
                    1;
                return Card(
                  child: ListTile(
                    key: ValueKey('replay_entry_${entry.replayId}'),
                    onTap: () => _open(entry),
                    leading: CircleAvatar(child: Text('$stageNumber')),
                    title: Text('$stageNumber단계 · ${entry.shotCount}발'),
                    subtitle: Text(
                      '${entry.totalScore}점 · ${_modeName(entry.mode)}'
                      '${_snapshot!.isBest(entry.replayId) ? ' · 최고 기록' : ''}',
                    ),
                    trailing: Wrap(
                      spacing: 2,
                      children: [
                        IconButton(
                          tooltip: '공유 코드 복사',
                          onPressed: () => _share(entry),
                          icon: const Icon(Icons.ios_share_rounded),
                        ),
                        IconButton(
                          tooltip: '삭제',
                          onPressed: () => _delete(entry),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class ReplayViewerScreen extends StatefulWidget {
  const ReplayViewerScreen({
    super.key,
    required this.entry,
    required this.document,
    required this.playback,
  });

  final ReplayLibraryEntry entry;
  final ReplayDocument document;
  final ReplayPlaybackResult playback;

  @override
  State<ReplayViewerScreen> createState() => _ReplayViewerScreenState();
}

class _ReplayViewerScreenState extends State<ReplayViewerScreen> {
  late final PropertyShotGame _game;
  int _shotIndex = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _game = PropertyShotGame(
      widget.playback.initialState,
      onAnimationFinished: _advance,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _advance());
  }

  void _advance() {
    if (!mounted) return;
    if (_shotIndex >= widget.playback.shotResults.length) {
      setState(() => _finished = true);
      return;
    }
    final result = widget.playback.shotResults[_shotIndex];
    final start = _shotIndex == 0
        ? widget.playback.initialState
        : widget.playback.shotResults[_shotIndex - 1].state;
    setState(() {
      _shotIndex += 1;
      _finished = false;
    });
    _game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
      animationTransaction: result.path.isNotEmpty,
    );
  }

  void _restart() {
    _game.setStateSnapshot(widget.playback.initialState);
    setState(() {
      _shotIndex = 0;
      _finished = false;
    });
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('replay_viewer_screen'),
      backgroundColor: const Color(0xFFE9F4ED),
      appBar: AppBar(
        title: const Text('리플레이 재생'),
        actions: [
          IconButton(
            key: const Key('replay_restart_button'),
            tooltip: '처음부터 다시 보기',
            onPressed: _restart,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 0.72,
                  child: GameWidget(game: _game),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _finished
                          ? '재생 완료 · ${widget.entry.totalScore}점'
                          : '${widget.playback.shotResults.length}발 중 $_shotIndex발',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (_finished)
                    FilledButton.icon(
                      onPressed: _restart,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('다시 보기'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _modeName(ReplayMode mode) => switch (mode) {
  ReplayMode.normal => '일반 런',
  ReplayMode.dailyOfficial => '오늘의 도전',
  ReplayMode.dailyPractice => '오늘의 도전 연습',
};
