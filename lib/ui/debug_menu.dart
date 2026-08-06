import 'dart:convert';

import 'package:flutter/material.dart';

import '../game/domain/game_state.dart';
import '../game/domain/trait.dart';
import '../game/levels/levels.dart';
import '../game/simulation/shot_resolver.dart';
import 'debug_labels.dart';
import 'tutorial_experiment.dart';

class DebugMenu extends StatefulWidget {
  const DebugMenu({
    super.key,
    required this.state,
    required this.recentEvents,
    required this.showHitboxes,
    required this.showNormals,
    required this.showIds,
    required this.showStats,
    required this.activeMass,
    required this.activeSpeed,
    required this.activeMomentum,
    required this.lastCollisionId,
    required this.recordingReplay,
    required this.hasReplay,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.tutorialVariant,
    required this.onSelectStage,
    required this.onRestartStage,
    required this.onResetProgress,
    required this.onUnlockAll,
    required this.onSetCopyCore,
    required this.onForceTrait,
    required this.onRemoveTrait,
    required this.onRestoreTrait,
    required this.onToggleHitboxes,
    required this.onToggleNormals,
    required this.onToggleIds,
    required this.onToggleStats,
    required this.onTutorialVariantChanged,
    required this.onCopyState,
    required this.onCopyEvents,
    required this.onToggleReplayRecording,
    required this.onPlayReplay,
    required this.onToggleSound,
    required this.onToggleHaptics,
  });

  final GameState state;
  final List<PhysicsEvent> recentEvents;
  final bool showHitboxes;
  final bool showNormals;
  final bool showIds;
  final bool showStats;
  final double activeMass;
  final double activeSpeed;
  final double activeMomentum;
  final String? lastCollisionId;
  final bool recordingReplay;
  final bool hasReplay;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final TutorialExperimentVariant tutorialVariant;
  final ValueChanged<int> onSelectStage;
  final VoidCallback onRestartStage;
  final VoidCallback onResetProgress;
  final VoidCallback onUnlockAll;
  final ValueChanged<int> onSetCopyCore;
  final ValueChanged<String> onForceTrait;
  final ValueChanged<String> onRemoveTrait;
  final ValueChanged<String> onRestoreTrait;
  final ValueChanged<bool> onToggleHitboxes;
  final ValueChanged<bool> onToggleNormals;
  final ValueChanged<bool> onToggleIds;
  final ValueChanged<bool> onToggleStats;
  final ValueChanged<TutorialExperimentVariant> onTutorialVariantChanged;
  final VoidCallback onCopyState;
  final VoidCallback onCopyEvents;
  final ValueChanged<bool> onToggleReplayRecording;
  final VoidCallback onPlayReplay;
  final ValueChanged<bool> onToggleSound;
  final ValueChanged<bool> onToggleHaptics;

  @override
  State<DebugMenu> createState() => _DebugMenuState();
}

class _DebugMenuState extends State<DebugMenu> {
  late final TextEditingController _copyCoreController = TextEditingController(
    text: '${widget.state.copyCoreCount}',
  );
  late bool _recordingReplay = widget.recordingReplay;
  late bool _soundEnabled = widget.soundEnabled;
  late bool _hapticsEnabled = widget.hapticsEnabled;

  @override
  void dispose() {
    _copyCoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final traitSources = widget.state.traitSources.toList();
    final baseState = levels[widget.state.levelIndex].createState(
      widget.state.levelIndex,
    );
    final sourceIds = {
      ...baseState.traitSources.map((source) => source.id),
      ...traitSources.map((source) => source.id),
    }.toList()..sort();
    final eventLines = widget.recentEvents.reversed
        .take(100)
        .map(_eventLabel)
        .toList();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    '개발 진단 메뉴',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  key: const Key('debug_menu_close_button'),
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            _DebugSection(
              title: '단계와 저장',
              child: Column(
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var index = 0; index < levels.length; index++)
                        ChoiceChip(
                          label: Text('${index + 1}단계'),
                          selected: index == widget.state.levelIndex,
                          onSelected: (_) => widget.onSelectStage(index),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onRestartStage,
                          icon: const Icon(Icons.refresh),
                          label: const Text('현재 단계 다시 시작'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onUnlockAll,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('모든 단계 해금'),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onResetProgress,
                          icon: const Icon(Icons.delete_sweep_outlined),
                          label: const Text('진행 기록 초기화'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          key: const Key('debug_copy_core_field'),
                          controller: _copyCoreController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: '복제 코어 수',
                            isDense: true,
                          ),
                          onSubmitted: (value) => widget.onSetCopyCore(
                            int.tryParse(value)?.clamp(0, 999) ?? 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _DebugSection(
              title: '속성과 실험 조건',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final sourceId in sourceIds)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${debugEntityLabel(sourceId)} · '
                              '${_traitLabel(sourceId, baseState)}',
                            ),
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              OutlinedButton(
                                key: Key('debug_remove_trait_$sourceId'),
                                onPressed: () => widget.onRemoveTrait(sourceId),
                                child: const Text('원본 제거'),
                              ),
                              OutlinedButton(
                                key: Key('debug_restore_trait_$sourceId'),
                                onPressed: () =>
                                    widget.onRestoreTrait(sourceId),
                                child: const Text('원본 복원'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  for (final source in traitSources)
                    OutlinedButton.icon(
                      onPressed: () => widget.onForceTrait(source.id),
                      icon: const Icon(Icons.auto_awesome),
                      label: Text('${debugEntityLabel(source.id)} 속성 강제 장착'),
                    ),
                  RadioGroup<TutorialExperimentVariant>(
                    groupValue: widget.tutorialVariant,
                    onChanged: (value) {
                      if (value != null) {
                        widget.onTutorialVariantChanged(value);
                      }
                    },
                    child: Column(
                      children: [
                        for (final variant in TutorialExperimentVariant.values)
                          RadioListTile<TutorialExperimentVariant>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(variant.label),
                            value: variant,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _DebugSection(
              title: '물리 표시',
              child: Column(
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('히트박스 표시'),
                    value: widget.showHitboxes,
                    onChanged: widget.onToggleHitboxes,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('충돌 법선 표시'),
                    value: widget.showNormals,
                    onChanged: widget.onToggleNormals,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('물체 ID 표시'),
                    value: widget.showIds,
                    onChanged: widget.onToggleIds,
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('프레임 통계 표시'),
                    value: widget.showStats,
                    onChanged: widget.onToggleStats,
                  ),
                  const Divider(),
                  SelectableText(
                    '공 질량 ${widget.activeMass.toStringAsFixed(2)} · '
                    '속도 ${widget.activeSpeed.toStringAsFixed(2)} · '
                    '운동량 ${widget.activeMomentum.toStringAsFixed(2)}\n'
                    '샷 식별자 ${widget.state.shotCount} · '
                    '충돌 식별자 ${widget.lastCollisionId ?? '없음'}',
                    key: const Key('debug_physics_metrics'),
                    style: const TextStyle(fontSize: 12, height: 1.35),
                  ),
                ],
              ),
            ),
            _DebugSection(
              title: '리플레이와 이벤트',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onCopyState,
                          icon: const Icon(Icons.content_copy),
                          label: const Text('상태 JSON 복사'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onCopyEvents,
                          icon: const Icon(Icons.event_note),
                          label: const Text('이벤트 복사'),
                        ),
                      ),
                    ],
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('리플레이 녹화'),
                    value: _recordingReplay,
                    onChanged: (value) {
                      setState(() => _recordingReplay = value);
                      widget.onToggleReplayRecording(value);
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.hasReplay ? widget.onPlayReplay : null,
                    icon: const Icon(Icons.replay),
                    label: Text(
                      widget.hasReplay ? '마지막 리플레이 재생' : '저장된 리플레이 없음',
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('사운드 켜기'),
                    value: _soundEnabled,
                    onChanged: (value) {
                      setState(() => _soundEnabled = value);
                      widget.onToggleSound(value);
                    },
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('햅틱 켜기'),
                    value: _hapticsEnabled,
                    onChanged: (value) {
                      setState(() => _hapticsEnabled = value);
                      widget.onToggleHaptics(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '최근 이벤트 ${eventLines.length}개',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    eventLines.isEmpty
                        ? '아직 물리 이벤트가 없습니다.'
                        : eventLines.join('\n'),
                    key: const Key('debug_physics_events'),
                    style: const TextStyle(fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
            _DebugSection(
              title: '현재 상태',
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert({
                  '단계': widget.state.levelIndex + 1,
                  '단계상태': _phaseLabel(widget.state.phase),
                  '발사횟수': widget.state.shotCount,
                  '공속성': widget.state.equippedTrait?.label ?? '없음',
                  '복제코어': widget.state.copyCoreCount,
                  '물체수': widget.state.entities.length,
                }),
                style: const TextStyle(fontSize: 12, height: 1.35),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _eventLabel(PhysicsEvent event) {
    final normal =
        '(${event.normal.x.toStringAsFixed(2)}, ${event.normal.y.toStringAsFixed(2)})';
    return '${_kindLabel(event.kind)} · '
        '${debugEntityLabel(event.sourceEntityId)} → '
        '${debugEntityLabel(event.targetEntityId)} · 법선 $normal · '
        '경로 ${event.pathIndex}';
  }

  String _kindLabel(PhysicsEventKind kind) {
    return switch (kind) {
      PhysicsEventKind.impact => '충돌',
      PhysicsEventKind.powerSliderActivation => '파워 슬라이더 작동',
      PhysicsEventKind.reflectorRotation => '회전 반사판 회전',
      PhysicsEventKind.stateChange => '상태 변경',
      PhysicsEventKind.move => '이동',
      PhysicsEventKind.chainSafetyStop => '연쇄 안전 중단',
    };
  }

  String _phaseLabel(GamePhase phase) {
    return switch (phase) {
      GamePhase.planning => '준비',
      GamePhase.resolving => '판정 중',
      GamePhase.success => '성공',
      GamePhase.paused => '일시정지',
    };
  }

  String _traitLabel(String sourceId, GameState baseState) {
    final current = widget.state.entityById(sourceId);
    final base = baseState.entityById(sourceId);
    final traits = current?.traits.isNotEmpty == true
        ? current!.traits
        : base?.traits ?? const {};
    return traits.isEmpty ? '속성 없음' : traits.first.label;
  }
}

class _DebugSection extends StatelessWidget {
  const _DebugSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
