import 'package:flutter/material.dart';

import '../game/domain/game_state.dart';
import '../game/lab/physics_lab.dart';
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
          onExit: () => setState(() => _active = null),
          onStageRequested: (_) async => setState(() => _active = null),
          showTutorialFailureHints: false,
          tutorialVariant: TutorialExperimentVariant.silent,
          difficulty: PlayerDifficulty.normal,
          loadGameAssets: widget.loadGameAssets,
          telemetry: LocalPlayTelemetry(persistLocally: false),
          progressPersistencePolicy: GameProgressPersistencePolicy.disabled,
        ),
      );
    }
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
}
