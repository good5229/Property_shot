import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/domain/game_state.dart';
import '../game/lab/physics_lab.dart';
import '../game/lab/physics_lab_creator.dart';
import '../game/lab/weekly_lab.dart';
import 'game_feedback.dart';
import 'game_screen.dart';
import 'play_telemetry.dart';
import 'tutorial_experiment.dart';

class PhysicsLabScreen extends StatefulWidget {
  const PhysicsLabScreen({
    super.key,
    required this.onBack,
    this.loadGameAssets = true,
  });
  final VoidCallback onBack;
  final bool loadGameAssets;

  @override
  State<PhysicsLabScreen> createState() => _PhysicsLabScreenState();
}

class _PhysicsLabScreenState extends State<PhysicsLabScreen> {
  PhysicsLabScenario? _active;
  bool _activeIsWeekly = false;
  bool _creating = false;
  String _draftScenarioId = physicsLabScenarios.first.id;
  LabGoalPosition _draftGoal = LabGoalPosition.north;
  String? _creatorMessage;
  late final WeeklyLabChallenge _weekly = WeeklyLabChallenge.forDate(
    DateTime.now(),
  );
  Set<String> _completedWeeks = const {};

  @override
  void initState() {
    super.initState();
    _loadWeeklyProgress();
  }

  Future<void> _loadWeeklyProgress() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final completed = WeeklyLabStore(preferences).loadCompletedWeeks();
      if (mounted) setState(() => _completedWeeks = completed);
    } on Object {
      // 주간 진행을 불러오지 못해도 고정 실험은 계속 이용할 수 있다.
    }
  }

  Future<void> _completeWeekly() async {
    if (!_activeIsWeekly || _completedWeeks.contains(_weekly.weekKey)) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await WeeklyLabStore(preferences).complete(_weekly.weekKey);
      if (!mounted) return;
      setState(() => _completedWeeks = {..._completedWeeks, _weekly.weekKey});
      GameFeedback().labCompleted();
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주간 실험 완료를 저장하지 못했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  Future<void> _copyWeeklyCode() async {
    await Clipboard.setData(ClipboardData(text: _weekly.shareCode));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이번 주 실험 코드를 복사했습니다.')));
    }
  }

  PhysicsLabDraft get _draft => PhysicsLabDraft(
    baseScenarioId: _draftScenarioId,
    goalPosition: _draftGoal,
  );

  Future<void> _copyDraft() async {
    try {
      final code = PhysicsLabShareCode.encode(_draft);
      await Clipboard.setData(ClipboardData(text: code));
      if (mounted) setState(() => _creatorMessage = '공유 코드를 복사했습니다.');
    } on FormatException catch (error) {
      if (mounted) setState(() => _creatorMessage = error.message.toString());
    }
  }

  Future<void> _importDraft() async {
    final controller = TextEditingController();
    final raw = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('실험 코드 가져오기'),
        content: TextField(
          key: const Key('lab_share_code_input'),
          controller: controller,
          maxLines: 5,
          maxLength: physicsLabShareMaxCharacters,
          decoration: const InputDecoration(
            hintText: '속실1:로 시작하는 코드를 붙여 넣으세요.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            key: const Key('lab_import_confirm_button'),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('검증하고 열기'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (raw == null || raw.trim().isEmpty || !mounted) return;
    try {
      final draft = PhysicsLabShareCode.decode(raw);
      setState(() {
        _draftScenarioId = draft.baseScenarioId;
        _draftGoal = draft.goalPosition;
        _creatorMessage = '검증된 실험 코드를 불러왔습니다.';
      });
    } on FormatException catch (error) {
      setState(() => _creatorMessage = error.message.toString());
    }
  }

  void _playDraft() {
    final error = const PhysicsLabDraftValidator().validate(_draft);
    if (error != null) {
      setState(() => _creatorMessage = error);
      return;
    }
    setState(() {
      _active = const PhysicsLabDraftValidator().build(_draft);
      _creating = false;
      _creatorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scenario = _active;
    if (scenario != null) {
      final state = scenario.level
          .createState(scenario.linkedStageIndex)
          .copyWith(
            phase: GamePhase.planning,
            message: switch (scenario.id) {
              'lab_heavy_crate_v1' => '무거움을 옮긴 뒤 상자 쪽으로 발사해 보세요.',
              'lab_bouncy_second_rebound_v1' =>
                '탄성을 옮기고 두 벽을 이어 튕기는 방향을 찾아 보세요.',
              'lab_sticky_chain_v1' => '점착을 옮긴 공을 남긴 뒤 다음 공으로 건드려 보세요.',
              'lab_sharp_balloon_v1' => '뿠족함을 옮긴 뒤 풍선을 먼저 노려보세요.',
              'lab_switch_gate_v1' => '공으로 스위치를 먼저 누르고 문의 변화를 살펴보세요.',
              _ => scenario.question,
            },
          );
      return Semantics(
        container: true,
        namesRoute: true,
        label: '물리 실험실: ${scenario.title}',
        child: GameScreen(
          key: ValueKey(scenario.id),
          initialState: state,
          levelOverride: scenario.level,
          showStageSelector: false,
          exitToMainMenu: false,
          exitTooltipOverride: '실험 목록',
          objectiveOverride: scenario.question,
          showDiscoveryHud: false,
          onExit: () => setState(() {
            _active = null;
            _activeIsWeekly = false;
          }),
          onStageRequested: (_) async => setState(() {
            _active = null;
            _activeIsWeekly = false;
          }),
          onLevelCleared: (_, _, _, _) async => _completeWeekly(),
          showTutorialFailureHints: false,
          tutorialVariant: TutorialExperimentVariant.silent,
          difficulty: PlayerDifficulty.normal,
          loadGameAssets: widget.loadGameAssets,
          telemetry: LocalPlayTelemetry(persistLocally: false),
          progressPersistencePolicy: GameProgressPersistencePolicy.disabled,
        ),
      );
    }
    if (_creating) return _buildCreator(context);
    return Scaffold(
      key: const Key('physics_lab_screen'),
      backgroundColor: const Color(0xFFE8F4ED),
      appBar: AppBar(
        leading: IconButton(
          tooltip: '섬 지도로',
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('물리 실험실'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '기록 걱정 없이 물리 규칙을 직접 시험해 보세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text('실험 결과는 캠페인 진행·최고 기록·도감 발견에 반영되지 않습니다.'),
            const SizedBox(height: 14),
            Card(
              key: const Key('weekly_lab_card'),
              color: const Color(0xFFFFF3C7),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '이번 주 실험 · ${_weekly.weekKey}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (_completedWeeks.contains(_weekly.weekKey))
                          const Chip(label: Text('완료')),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(_weekly.scenario.title),
                    Text(_weekly.scenario.question),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          key: const Key('weekly_lab_play_button'),
                          onPressed: () => setState(() {
                            _active = _weekly.scenario;
                            _activeIsWeekly = true;
                          }),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(
                            _completedWeeks.contains(_weekly.weekKey)
                                ? '다시 실험'
                                : '이번 주 실험 시작',
                          ),
                        ),
                        OutlinedButton.icon(
                          key: const Key('weekly_lab_copy_button'),
                          onPressed: _copyWeeklyCode,
                          icon: const Icon(Icons.ios_share_rounded),
                          label: const Text('주간 코드 복사'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              key: const Key('physics_lab_create_button'),
              onPressed: () => setState(() => _creating = true),
              icon: const Icon(Icons.tune_rounded),
              label: const Text('나만의 실험 만들기'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('physics_lab_import_button'),
              onPressed: _importDraft,
              icon: const Icon(Icons.input_rounded),
              label: const Text('실험 코드 가져오기'),
            ),
            const SizedBox(height: 14),
            for (final scenario in physicsLabScenarios)
              Card(
                child: ListTile(
                  key: Key('physics_lab_${scenario.id}'),
                  leading: const CircleAvatar(
                    child: Icon(Icons.science_outlined),
                  ),
                  title: Text(
                    scenario.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(scenario.question),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => setState(() => _active = scenario),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreator(BuildContext context) {
    final selected = physicsLabScenarios.firstWhere(
      (item) => item.id == _draftScenarioId,
    );
    final validation = const PhysicsLabDraftValidator().validate(_draft);
    return Scaffold(
      key: const Key('physics_lab_creator'),
      backgroundColor: const Color(0xFFE8F4ED),
      appBar: AppBar(
        leading: IconButton(
          tooltip: '실험 목록',
          onPressed: () => setState(() => _creating = false),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('나만의 실험'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '검증된 규칙 안에서 목표 위치를 바꿔 새 경로를 만들어 보세요.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text('임의 기물·정답 데이터는 넣을 수 없으며, 실험 기록은 캠페인과 분리됩니다.'),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              key: const Key('lab_template_dropdown'),
              initialValue: _draftScenarioId,
              decoration: const InputDecoration(
                labelText: '실험 규칙',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final scenario in physicsLabScenarios)
                  DropdownMenuItem(
                    value: scenario.id,
                    child: Text(scenario.title),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _draftScenarioId = value;
                    _creatorMessage = null;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text('홀 위치', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<LabGoalPosition>(
              key: const Key('lab_goal_position'),
              segments: [
                for (final position in LabGoalPosition.values)
                  ButtonSegment(
                    value: position,
                    label: Text(position.label),
                    icon: const Icon(Icons.flag_outlined),
                  ),
              ],
              selected: {_draftGoal},
              onSelectionChanged: (selection) => setState(() {
                _draftGoal = selection.single;
                _creatorMessage = null;
              }),
            ),
            const SizedBox(height: 18),
            Card(
              color: validation == null
                  ? const Color(0xFFDDF3E5)
                  : const Color(0xFFFFE1D7),
              child: ListTile(
                leading: Icon(
                  validation == null
                      ? Icons.verified_rounded
                      : Icons.error_outline_rounded,
                ),
                title: Text(validation ?? '안전 검사 통과'),
                subtitle: Text(
                  '${selected.title} · ${_draftGoal.label} 목표 · ${selected.level.parShots}발 안에 관찰',
                ),
              ),
            ),
            if (_creatorMessage != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _creatorMessage!,
                  key: const Key('lab_creator_message'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const SizedBox(height: 14),
            FilledButton.icon(
              key: const Key('lab_play_draft_button'),
              onPressed: validation == null ? _playDraft : null,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('이 배치로 실험'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('lab_copy_draft_button'),
              onPressed: validation == null ? _copyDraft : null,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('공유 코드 복사'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('lab_creator_import_button'),
              onPressed: _importDraft,
              icon: const Icon(Icons.input_rounded),
              label: const Text('다른 코드 가져오기'),
            ),
          ],
        ),
      ),
    );
  }
}
