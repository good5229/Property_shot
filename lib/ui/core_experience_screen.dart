import 'package:flutter/material.dart';

import '../game/domain/level_definition.dart';
import '../game/domain/shot_input.dart';
import '../game/domain/trait.dart';
import '../game/levels/generated_stage_catalog.dart';
import '../game/simulation/shot_resolver.dart';
import 'app_language.dart';
import 'game_feedback.dart';
import 'game_screen.dart';
import 'play_telemetry.dart';

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

  LevelDefinition createLevel({AppLanguage language = AppLanguage.korean}) {
    final stage = generatedStageCatalog.stageById(stageId);
    return stage
        .patternById(patternId)
        .toLevelDefinition(
          stageId: stageId,
          stageTitle: _sceneCopy(id: patternId, language: language).title,
        );
  }

  StageObjectiveEvidence evaluateObjective(
    List<ShotResult> results,
    List<ShotInput> inputs,
  ) {
    final satisfied = switch (patternId) {
      'stage_heavy_01' =>
        inputs.any((input) => input.equippedTrait == TraitType.heavy) &&
            results.any(
              (result) => result.moves.any(
                (move) => move.entityId == 'crate_a' && move.from != move.to,
              ),
            ),
      'stage_drained_01' =>
        inputs.any((input) => input.equippedTrait == TraitType.heavy) &&
            results.any(
              (result) => result.moves.any(
                (move) =>
                    move.entityId == 'drain_weight' && move.from != move.to,
              ),
            ),
      'stage_persistent_01' =>
        results.length >= 2 &&
            results
                .skip(1)
                .any(
                  (result) => result.impacts.any(
                    (impact) =>
                        impact.entityId == 'spent_ball_1' ||
                        impact.sourceEntityId == 'spent_ball_1',
                  ),
                ),
      _ => false,
    };
    return StageObjectiveEvidence(
      satisfied: satisfied,
      guidance: switch (patternId) {
        'stage_heavy_01' => '바위의 무거움을 옮긴 공으로 상자를 움직인 뒤 홀에 넣어 보세요.',
        'stage_drained_01' => '무거움을 옮겨 가벼워진 원본 돌을 실제로 움직인 뒤 홀에 넣어 보세요.',
        'stage_persistent_01' => '첫 공을 남긴 뒤 새 공으로 그 공을 맞혀 홀까지 이어 보세요.',
        _ => '장면 목표를 수행한 뒤 다시 홀에 넣어 보세요.',
      },
    );
  }
}

({String title, String objective, String startMessage}) _sceneCopy({
  required String id,
  required AppLanguage language,
}) {
  if (!language.isEnglish) {
    final scene = coreExperienceScenes.singleWhere(
      (candidate) => candidate.patternId == id,
    );
    return (
      title: scene.title,
      objective: scene.objective,
      startMessage: scene.startMessage,
    );
  }
  return switch (id) {
    'stage_heavy_01' => (
      title: 'Scene 1 · Steal Weight',
      objective: 'Move weight into the ball and push the crate aside',
      startMessage: 'Tap the stone, transfer Weight, then launch the ball.',
    ),
    'stage_drained_01' => (
      title: 'Scene 2 · The Drained Source',
      objective: 'Use both the powered ball and the changed source object',
      startMessage: 'Watch how both the ball and the drained object change.',
    ),
    'stage_persistent_01' => (
      title: 'Scene 3 · Turn Failure into a Tool',
      objective: 'Use the first ball as a bumper or stopper for the next shot',
      startMessage: 'A missed ball stays. Use it to reshape the next route.',
    ),
    _ => throw ArgumentError.value(id, 'id', 'Unknown core experience scene'),
  };
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
    this.language = AppLanguage.korean,
    this.telemetry,
  }) : assert(initialSceneIndex >= 0),
       assert(initialSceneIndex < coreExperienceScenes.length);

  final VoidCallback onExit;
  final VoidCallback onContinueCampaign;
  final bool loadGameAssets;
  final AppLanguage language;
  final LocalPlayTelemetry? telemetry;

  @visibleForTesting
  final int initialSceneIndex;

  @override
  State<CoreExperienceScreen> createState() => _CoreExperienceScreenState();
}

class _CoreExperienceScreenState extends State<CoreExperienceScreen> {
  late int _sceneIndex = widget.initialSceneIndex;
  bool _completed = false;
  bool _exitRecorded = false;
  final Stopwatch _experienceElapsed = Stopwatch();
  final Stopwatch _sceneElapsed = Stopwatch();

  @override
  void initState() {
    super.initState();
    _experienceElapsed.start();
    _sceneElapsed.start();
    _record('핵심 체험 진입', 'core_experience_entered');
    _recordSceneEntered();
  }

  void _record(
    String type,
    String eventCode, {
    int? elapsedMs,
    String? result,
  }) {
    final scene = coreExperienceScenes[_sceneIndex];
    widget.telemetry?.record(
      type,
      stage: scene.levelIndex,
      eventCode: eventCode,
      routeTag: 'core_experience',
      elapsedMs: elapsedMs,
      result: result,
      target: scene.patternId,
    );
  }

  void _recordSceneEntered() {
    _record('핵심 장면 진입', 'core_scene_entered');
  }

  void _exit() {
    if (!_exitRecorded) {
      _exitRecorded = true;
      _record(
        '핵심 체험 이탈',
        'core_experience_abandoned',
        elapsedMs: _experienceElapsed.elapsedMilliseconds,
        result: 'scene_${_sceneIndex + 1}',
      );
    }
    widget.onExit();
  }

  void _advance() {
    _record(
      '핵심 장면 완료',
      'core_scene_completed',
      elapsedMs: _sceneElapsed.elapsedMilliseconds,
      result: 'scene_${_sceneIndex + 1}',
    );
    if (_sceneIndex >= coreExperienceScenes.length - 1) {
      _record(
        '핵심 체험 완료',
        'core_experience_completed',
        elapsedMs: _experienceElapsed.elapsedMilliseconds,
      );
      setState(() => _completed = true);
      return;
    }
    setState(() => _sceneIndex += 1);
    _sceneElapsed
      ..reset()
      ..start();
    _recordSceneEntered();
  }

  @override
  Widget build(BuildContext context) {
    if (_completed) {
      return _CoreExperienceComplete(
        onExit: _exit,
        onContinueCampaign: widget.onContinueCampaign,
        onReplay: () {
          _record('핵심 체험 다시 시작', 'core_experience_replayed');
          setState(() {
            _sceneIndex = 0;
            _completed = false;
          });
          _experienceElapsed
            ..reset()
            ..start();
          _sceneElapsed
            ..reset()
            ..start();
          _exitRecorded = false;
          _recordSceneEntered();
        },
        language: widget.language,
      );
    }

    final scene = coreExperienceScenes[_sceneIndex];
    final copy = _sceneCopy(id: scene.patternId, language: widget.language);
    final level = scene.createLevel(language: widget.language);
    final initialState = level
        .createState(scene.levelIndex, productRules: true)
        .copyWith(message: copy.startMessage);
    final isLast = _sceneIndex == coreExperienceScenes.length - 1;

    return GameScreen(
      key: ValueKey('core_experience_${scene.patternId}'),
      initialState: initialState,
      levelOverride: level,
      showStageSelector: false,
      telemetry: widget.telemetry,
      onExit: _exit,
      exitToMainMenu: true,
      progressPersistencePolicy: GameProgressPersistencePolicy.disabled,
      difficulty: PlayerDifficulty.easy,
      loadGameAssets: widget.loadGameAssets,
      showTutorialFailureHints: true,
      showDiscoveryHud: false,
      objectiveOverride: widget.language.isEnglish
          ? 'CORE PLAY ${_sceneIndex + 1}/${coreExperienceScenes.length} · ${copy.objective}'
          : '핵심 체험 ${_sceneIndex + 1}/${coreExperienceScenes.length} · ${copy.objective}',
      exitTooltipOverride: widget.language.pick('핵심 체험 나가기', 'Exit core play'),
      sequencePosition: _sceneIndex,
      sequenceLength: coreExperienceScenes.length,
      nextActionLabel: isLast
          ? widget.language.pick('체험 마치기', 'FINISH CORE PLAY')
          : widget.language.pick('다음 장면', 'NEXT SCENE'),
      onStageRequested: (_) async => _advance(),
      objectiveEvidenceEvaluator: scene.evaluateObjective,
    );
  }
}

class _CoreExperienceComplete extends StatelessWidget {
  const _CoreExperienceComplete({
    required this.onExit,
    required this.onContinueCampaign,
    required this.onReplay,
    required this.language,
  });

  final VoidCallback onExit;
  final VoidCallback onContinueCampaign;
  final VoidCallback onReplay;
  final AppLanguage language;

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
                        language.pick(
                          '핵심 규칙을 모두 발견했습니다',
                          'YOU DISCOVERED THE CORE RULES',
                        ),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF173F43),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        language.pick(
                          '속성을 옮기면 공과 원본이 함께 달라지고, 한 번 바뀐 장면은 다음 해법으로 남습니다.',
                          'Moving a trait changes both the ball and its source. Every changed object remains part of the next solution.',
                        ),
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
                        Row(
                          children: [
                            Expanded(
                              child: _ExperienceSummaryCard(
                                asset:
                                    'assets/generated/stage-icon-heavy-v1.png',
                                title: language.pick('속성 강탈', 'STEAL A TRAIT'),
                                body: language.pick(
                                  '사물의 성질을 공에 옮겨 새로운 물리 역할을 만듭니다.',
                                  'Move an object’s trait into the ball to create a new physics role.',
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _ExperienceSummaryCard(
                                asset:
                                    'assets/generated/stage-icon-property-transfer-v1.png',
                                title: language.pick(
                                  '양면 변화',
                                  'TWO-SIDED CHANGE',
                                ),
                                body: language.pick(
                                  '공이 얻은 속성과 원본이 잃은 속성을 함께 이용합니다.',
                                  'Use what the ball gains and what the source loses.',
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _ExperienceSummaryCard(
                                asset:
                                    'assets/generated/stage-icon-persistent-ball-v1.png',
                                title: language.pick(
                                  '상태 재사용',
                                  'REUSE THE STATE',
                                ),
                                body: language.pick(
                                  '빗나간 공과 바뀐 장면도 다음 샷의 도구로 남습니다.',
                                  'Missed balls and changed objects remain tools for the next shot.',
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _ExperienceSummaryCard(
                              asset: 'assets/generated/stage-icon-heavy-v1.png',
                              title: language.pick('속성 강탈', 'STEAL A TRAIT'),
                              body: language.pick(
                                '사물의 성질을 공에 옮겨 새로운 물리 역할을 만듭니다.',
                                'Move an object’s trait into the ball to create a new physics role.',
                              ),
                            ),
                            SizedBox(height: 12),
                            _ExperienceSummaryCard(
                              asset:
                                  'assets/generated/stage-icon-property-transfer-v1.png',
                              title: language.pick('양면 변화', 'TWO-SIDED CHANGE'),
                              body: language.pick(
                                '공이 얻은 속성과 원본이 잃은 속성을 함께 이용합니다.',
                                'Use what the ball gains and what the source loses.',
                              ),
                            ),
                            SizedBox(height: 12),
                            _ExperienceSummaryCard(
                              asset:
                                  'assets/generated/stage-icon-persistent-ball-v1.png',
                              title: language.pick('상태 재사용', 'REUSE THE STATE'),
                              body: language.pick(
                                '빗나간 공과 바뀐 장면도 다음 샷의 도구로 남습니다.',
                                'Missed balls and changed objects remain tools for the next shot.',
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      _JudgeJourneySteps(language: language),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: mathMin(constraints.maxWidth, 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton(
                              key: const Key('core_continue_campaign_button'),
                              onPressed: onContinueCampaign,
                              child: Text(
                                language.pick(
                                  '첫 항해로 이어가기',
                                  'CONTINUE TO FIRST VOYAGE',
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              key: const Key('core_replay_button'),
                              onPressed: onReplay,
                              child: Text(
                                language.pick(
                                  '핵심 체험 다시 하기',
                                  'REPLAY CORE PLAY',
                                ),
                              ),
                            ),
                            TextButton(
                              key: const Key('core_home_button'),
                              onPressed: onExit,
                              child: Text(language.pick('홈으로', 'BACK HOME')),
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

class _JudgeJourneySteps extends StatelessWidget {
  const _JudgeJourneySteps({required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        asset: 'assets/generated/stage-icon-property-transfer-v1.png',
        label: language.pick('핵심 규칙', 'CORE RULES'),
        completed: true,
      ),
      (
        asset: 'assets/generated/nav-helm-v1.png',
        label: language.pick('첫 항해', 'FIRST VOYAGE'),
        completed: false,
      ),
      (
        asset: 'assets/generated/island-observatory-v2.png',
        label: language.pick('섬 변화', 'ISLAND CHANGE'),
        completed: false,
      ),
    ];
    return Semantics(
      container: true,
      label: language.pick(
        '심사 경로. 핵심 규칙 완료, 다음 첫 항해, 이후 섬 변화',
        'Judge route. Core rules complete, then first voyage, then island change.',
      ),
      child: Row(
        key: const Key('judge_journey_steps'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            Flexible(
              child: _JudgeJourneyStep(
                asset: items[index].asset,
                label: items[index].label,
                completed: items[index].completed,
              ),
            ),
            if (index < items.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Color(0xFF397172),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

@visibleForTesting
Widget buildJudgeJourneyStepsForTesting({
  AppLanguage language = AppLanguage.korean,
}) => _JudgeJourneySteps(language: language);

class _JudgeJourneyStep extends StatelessWidget {
  const _JudgeJourneyStep({
    required this.asset,
    required this.label,
    required this.completed,
  });

  final String asset;
  final String label;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 76, maxWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: completed ? const Color(0xFFE0F4DE) : const Color(0xFFF7FAF3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed ? const Color(0xFF4A8B66) : const Color(0xFF8CA8A1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            asset,
            width: 42,
            height: 42,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
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
