import 'package:flutter/material.dart';

import '../game/domain/level_definition.dart';
import '../game/levels/generated_stage_catalog.dart';
import 'game_feedback.dart';
import 'game_screen.dart';

@immutable
class CoreExperienceScene {
  const CoreExperienceScene({
    required this.stageId,
    required this.patternId,
    required this.levelIndex,
    required this.title,
    required this.objective,
    required this.startMessage,
  });

  final String stageId;
  final String patternId;
  final int levelIndex;
  final String title;
  final String objective;
  final String startMessage;

  LevelDefinition createLevel() {
    final stage = generatedStageCatalog.stageById(stageId);
    return stage
        .patternById(patternId)
        .toLevelDefinition(stageId: stageId, stageTitle: title);
  }
}

const coreExperienceScenes = <CoreExperienceScene>[
  CoreExperienceScene(
    stageId: 'stage_heavy',
    patternId: 'stage_heavy_01',
    levelIndex: 0,
    title: '장면 1 · 무거움 강탈',
    objective: '무거움을 공에 옮겨 상자를 밀어 길을 만드세요',
    startMessage: '돌을 눌러 무거움을 옮긴 뒤 공을 발사하세요.',
  ),
  CoreExperienceScene(
    stageId: 'stage_drained',
    patternId: 'stage_drained_01',
    levelIndex: 4,
    title: '장면 2 · 비워진 원본',
    objective: '속성을 얻은 공과 속성을 잃은 원본을 함께 바꾸세요',
    startMessage: '공에 생긴 힘뿐 아니라 비워진 원본의 움직임도 살펴보세요.',
  ),
  CoreExperienceScene(
    stageId: 'stage_persistent',
    patternId: 'stage_persistent_01',
    levelIndex: 6,
    title: '장면 3 · 실패를 기물로',
    objective: '남겨 둔 첫 공을 다음 발사의 쿠션과 스토퍼로 쓰세요',
    startMessage: '첫 공이 빗나가도 사라지지 않습니다. 다음 공의 길을 만들어 보세요.',
  ),
];

class CoreExperienceScreen extends StatefulWidget {
  const CoreExperienceScreen({
    super.key,
    required this.onExit,
    required this.onContinueCampaign,
    this.loadGameAssets = true,
    this.initialSceneIndex = 0,
  }) : assert(initialSceneIndex >= 0),
       assert(initialSceneIndex < coreExperienceScenes.length);

  final VoidCallback onExit;
  final VoidCallback onContinueCampaign;
  final bool loadGameAssets;

  @visibleForTesting
  final int initialSceneIndex;

  @override
  State<CoreExperienceScreen> createState() => _CoreExperienceScreenState();
}

class _CoreExperienceScreenState extends State<CoreExperienceScreen> {
  late int _sceneIndex = widget.initialSceneIndex;
  bool _completed = false;

  void _advance() {
    if (_sceneIndex >= coreExperienceScenes.length - 1) {
      setState(() => _completed = true);
      return;
    }
    setState(() => _sceneIndex += 1);
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return _CoreExperienceComplete(
        onExit: widget.onExit,
        onContinueCampaign: widget.onContinueCampaign,
        onReplay: () => setState(() {
          _sceneIndex = 0;
          _completed = false;
        }),
      );
    }

    final scene = coreExperienceScenes[_sceneIndex];
    final level = scene.createLevel();
    final initialState = level
        .createState(scene.levelIndex, productRules: true)
        .copyWith(message: scene.startMessage);
    final isLast = _sceneIndex == coreExperienceScenes.length - 1;

    return GameScreen(
      key: ValueKey('core_experience_${scene.patternId}'),
      initialState: initialState,
      levelOverride: level,
      showStageSelector: false,
      onExit: widget.onExit,
      exitToMainMenu: true,
      progressPersistencePolicy: GameProgressPersistencePolicy.disabled,
      difficulty: PlayerDifficulty.easy,
      loadGameAssets: widget.loadGameAssets,
      showTutorialFailureHints: true,
      showDiscoveryHud: false,
      objectiveOverride:
          '핵심 체험 ${_sceneIndex + 1}/${coreExperienceScenes.length} · ${scene.objective}',
      exitTooltipOverride: '핵심 체험 나가기',
      sequencePosition: _sceneIndex,
      sequenceLength: coreExperienceScenes.length,
      nextActionLabel: isLast ? '체험 마치기' : '다음 장면',
      onStageRequested: (_) async => _advance(),
    );
  }
}

class _CoreExperienceComplete extends StatelessWidget {
  const _CoreExperienceComplete({
    required this.onExit,
    required this.onContinueCampaign,
    required this.onReplay,
  });

  final VoidCallback onExit;
  final VoidCallback onContinueCampaign;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('core_experience_complete'),
      backgroundColor: const Color(0xFFBFE8E3),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/generated/nav-helm-v1.png',
                        width: 104,
                        height: 104,
                        filterQuality: FilterQuality.high,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '핵심 규칙을 모두 발견했습니다',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF173F43),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '속성을 옮기면 공과 원본이 함께 달라지고, 한 번 바뀐 장면은 다음 해법으로 남습니다.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF285C5D),
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 22),
                      if (wide)
                        const Row(
                          children: [
                            Expanded(
                              child: _ExperienceSummaryCard(
                                asset:
                                    'assets/generated/stage-icon-heavy-v1.png',
                                title: '속성 강탈',
                                body: '사물의 성질을 공에 옮겨 새로운 물리 역할을 만듭니다.',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _ExperienceSummaryCard(
                                asset:
                                    'assets/generated/stage-icon-property-transfer-v1.png',
                                title: '양면 변화',
                                body: '공이 얻은 속성과 원본이 잃은 속성을 함께 이용합니다.',
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _ExperienceSummaryCard(
                                asset:
                                    'assets/generated/stage-icon-persistent-ball-v1.png',
                                title: '상태 재사용',
                                body: '빗나간 공과 바뀐 장면도 다음 샷의 도구로 남습니다.',
                              ),
                            ),
                          ],
                        )
                      else
                        const Column(
                          children: [
                            _ExperienceSummaryCard(
                              asset: 'assets/generated/stage-icon-heavy-v1.png',
                              title: '속성 강탈',
                              body: '사물의 성질을 공에 옮겨 새로운 물리 역할을 만듭니다.',
                            ),
                            SizedBox(height: 12),
                            _ExperienceSummaryCard(
                              asset:
                                  'assets/generated/stage-icon-property-transfer-v1.png',
                              title: '양면 변화',
                              body: '공이 얻은 속성과 원본이 잃은 속성을 함께 이용합니다.',
                            ),
                            SizedBox(height: 12),
                            _ExperienceSummaryCard(
                              asset:
                                  'assets/generated/stage-icon-persistent-ball-v1.png',
                              title: '상태 재사용',
                              body: '빗나간 공과 바뀐 장면도 다음 샷의 도구로 남습니다.',
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: mathMin(constraints.maxWidth, 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              key: const Key('core_continue_campaign_button'),
                              onPressed: onContinueCampaign,
                              child: const Text('전체 탐사 시작'),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              key: const Key('core_replay_button'),
                              onPressed: onReplay,
                              child: const Text('핵심 체험 다시 하기'),
                            ),
                            TextButton(
                              key: const Key('core_home_button'),
                              onPressed: onExit,
                              child: const Text('홈으로'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ExperienceSummaryCard extends StatelessWidget {
  const _ExperienceSummaryCard({
    required this.asset,
    required this.title,
    required this.body,
  });

  final String asset;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 174),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF3E7773), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(asset, width: 72, height: 72, fit: BoxFit.contain),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(body, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

double mathMin(double left, double right) => left < right ? left : right;
