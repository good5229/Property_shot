import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game/domain/game_state.dart';
import 'game/levels/levels.dart';
import 'game/persistence/progress_store.dart';
import 'ui/game_feedback.dart';
import 'ui/game_screen.dart';
import 'ui/game_ball_painter.dart';
import 'ui/play_telemetry.dart';
import 'ui/tutorial_experiment.dart';

String _stageIntroMessage(int levelIndex) {
  return switch (levelIndex) {
    0 => '방향 조정 · 길게 누르기 · 손 떼기',
    1 => '방향 조정 · 길게 누르기 · 손 떼기',
    2 => '스위치 살피기 · 여러 경로로 도전',
    3 => '풍선 확인 · 여러 경로로 도전',
    _ => '공과 원본의 변화를 함께 살펴보세요',
  };
}

void main() {
  runApp(const PropertyShotApp(showHome: true, showDebugControls: kDebugMode));
}

class PropertyShotApp extends StatelessWidget {
  const PropertyShotApp({
    super.key,
    this.initialState,
    this.showHome = false,
    this.showStageSelector = true,
    this.telemetry,
    this.fontFamilyOverride,
    this.loadGameAssets = true,
    this.showDebugControls = false,
    this.tutorialVariant = TutorialExperimentVariant.guided,
  });

  final GameState? initialState;
  final bool showHome;
  final bool showStageSelector;
  final LocalPlayTelemetry? telemetry;
  final String? fontFamilyOverride;
  final bool loadGameAssets;
  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '속성 한방',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: fontFamilyOverride ?? 'NanumGothic',
        fontFamilyFallback: const [
          'Apple SD Gothic Neo',
          'Noto Sans CJK KR',
          'Arial',
        ],
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6B7A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: showHome && initialState == null
          ? _PropertyShotRouter(
              showDebugControls: showDebugControls,
              tutorialVariant: tutorialVariant,
            )
          : GameScreen(
              initialState: initialState,
              showStageSelector: showStageSelector,
              telemetry: telemetry,
              loadGameAssets: loadGameAssets,
              tutorialVariant: tutorialVariant,
              showDebugControls: showDebugControls,
            ),
    );
  }
}

class _PropertyShotRouter extends StatefulWidget {
  const _PropertyShotRouter({
    required this.showDebugControls,
    required this.tutorialVariant,
  });

  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;

  @override
  State<_PropertyShotRouter> createState() => _PropertyShotRouterState();
}

class _PropertyShotRouterState extends State<_PropertyShotRouter> {
  int? _activeStage;
  bool _showStageSelect = false;
  int _copyCoreCount = 0;
  bool _copyCoreRewarded = false;
  int _unlockedLevel = 0;
  Set<int> _clearedLevels = <int>{};
  late TutorialExperimentVariant _tutorialVariant = widget.tutorialVariant;
  final _progressStore = ProgressStore(
    stageCount: levels.length,
    stageIds: levels.map((level) => level.id),
  );

  @override
  void initState() {
    super.initState();
    _loadCopyCore();
  }

  Future<void> _loadCopyCore() async {
    await GameFeedback.loadPreferences();
    try {
      final progress = await _progressStore.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _copyCoreCount = progress.copyCoreCount;
        _copyCoreRewarded = progress.copyCoreRewarded;
        _clearedLevels = progress.clearedLevels;
        _unlockedLevel = progress.unlockedLevel;
      });
    } on Exception {
      // 저장소를 사용할 수 없어도 기본 진행 상태로 홈을 표시한다.
    }
  }

  void _saveCopyCore() {
    unawaited(_progressStore.recordCopyCore(_copyCoreCount, _copyCoreRewarded));
  }

  void _startStage(int index) {
    if (index > _unlockedLevel) {
      return;
    }
    setState(() => _activeStage = index);
  }

  void _returnHome() {
    setState(() {
      _activeStage = null;
      _showStageSelect = false;
    });
  }

  void _earnCopyCore(int amount) {
    setState(() {
      _copyCoreCount += amount;
      _copyCoreRewarded = true;
    });
    _saveCopyCore();
  }

  void _recordLevelClear(int levelIndex) {
    if (levelIndex < 0 || levelIndex >= levels.length) {
      return;
    }
    final clearedLevels = {..._clearedLevels, levelIndex};
    setState(() {
      _clearedLevels = clearedLevels;
      _unlockedLevel = math.max(
        _unlockedLevel,
        _progressStore.unlockedLevelFromCleared(clearedLevels),
      );
    });
    unawaited(_progressStore.recordStageClear(levelIndex));
  }

  @override
  Widget build(BuildContext context) {
    final activeStage = _activeStage;
    if (activeStage != null) {
      return GameScreen(
        key: ValueKey('stage_$activeStage'),
        initialState: levels[activeStage]
            .createState(
              activeStage,
              productRules: true,
              copyCoreCount: _copyCoreCount,
              copyCoreRewarded: _copyCoreRewarded,
            )
            .copyWith(message: _stageIntroMessage(activeStage)),
        showStageSelector: false,
        onExit: _returnHome,
        onCopyCoreEarned: _earnCopyCore,
        onLevelCleared: _recordLevelClear,
        progressStore: _progressStore,
        tutorialVariant: _tutorialVariant,
        showDebugControls: widget.showDebugControls,
      );
    }
    if (_showStageSelect) {
      return _StageSelectScreen(
        onBack: () => setState(() => _showStageSelect = false),
        onSelectStage: _startStage,
        unlockedLevel: _unlockedLevel,
      );
    }
    return _HomeScreen(
      onStart: () => _startStage(0),
      onStageSelect: () => setState(() => _showStageSelect = true),
      showDebugControls: widget.showDebugControls,
      tutorialVariant: _tutorialVariant,
      onTutorialVariantChanged: (variant) {
        setState(() => _tutorialVariant = variant);
      },
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({
    required this.onStart,
    required this.onStageSelect,
    required this.showDebugControls,
    required this.tutorialVariant,
    required this.onTutorialVariantChanged,
  });

  final VoidCallback onStart;
  final VoidCallback onStageSelect;
  final bool showDebugControls;
  final TutorialExperimentVariant tutorialVariant;
  final ValueChanged<TutorialExperimentVariant> onTutorialVariantChanged;

  @override
  Widget build(BuildContext context) {
    final appFontFamily = Theme.of(context).textTheme.bodyLarge?.fontFamily;
    return Scaffold(
      key: const Key('home_screen_golden'),
      backgroundColor: const Color(0xFFBFE8E3),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _IslandBackdrop()),
            if (showDebugControls)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filledTonal(
                  key: const Key('tutorial_experiment_button'),
                  tooltip: '튜토리얼 실험 조건',
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _TutorialExperimentDialog(
                      selected: tutorialVariant,
                      onSelected: onTutorialVariantChanged,
                    ),
                  ),
                  icon: const Icon(Icons.science_outlined),
                ),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton.filledTonal(
                key: const Key('feedback_settings_button'),
                tooltip: '소리와 진동 설정',
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const _FeedbackSettingsDialog(),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const _HomePlayPreview(),
                      const SizedBox(height: 12),
                      Text(
                        '속성 한방',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: const Color(0xFF173F43),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '주변 물체의 성질을 공에 담아\n한 번의 샷으로 연쇄 반응을 완성하세요.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF285C5D),
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 26),
                      FilledButton.icon(
                        key: const Key('start_game_button'),
                        onPressed: onStart,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('첫 섬에서 시작하기'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          backgroundColor: const Color(0xFFEF765E),
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ).copyWith(fontFamily: appFontFamily),
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        key: const Key('stage_select_button'),
                        onPressed: onStageSelect,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('스테이지 선택'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          foregroundColor: const Color(0xFF245B60),
                          side: const BorderSide(color: Color(0xFF4D8580)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomePlayPreview extends StatelessWidget {
  const _HomePlayPreview();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '공과 상자와 무거운 돌이 있는 목표 홀 보드',
      child: Container(
        height: 174,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFFE3A1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFF3B7776), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33406B65),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PreviewBoardPainter()),
            ),
            Positioned(
              left: 34,
              top: 40,
              child: Image.asset(
                'assets/generated/stone-v2.png',
                width: 72,
                height: 54,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              left: 146,
              top: 92,
              child: Image.asset(
                'assets/generated/crate-v2.png',
                width: 56,
                height: 56,
                fit: BoxFit.contain,
              ),
            ),
            const Positioned(right: 26, top: 28, child: _PreviewHole()),
            Positioned(
              left: 66,
              bottom: 18,
              child: CustomPaint(
                painter: const GameBallIconPainter(null),
                size: const Size(54, 54),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewHole extends StatelessWidget {
  const _PreviewHole();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 70,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF122523),
              border: Border.all(color: const Color(0xFF4EAAA5), width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x6650C2B2),
                  blurRadius: 0,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          const Positioned(
            right: 3,
            top: 0,
            child: Icon(Icons.flag_rounded, color: Color(0xFFEF765E), size: 28),
          ),
        ],
      ),
    );
  }
}

class _PreviewBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x1F9B6E38)
      ..strokeWidth = 2;
    for (var y = 18.0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    final pebble = Paint()..color = const Color(0x559A9D73);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.42, 36),
        width: 18,
        height: 7,
      ),
      pebble,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.86, size.height * 0.78),
        width: 16,
        height: 6,
      ),
      pebble,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewBoardPainter oldDelegate) => false;
}

class _FeedbackSettingsDialog extends StatefulWidget {
  const _FeedbackSettingsDialog();

  @override
  State<_FeedbackSettingsDialog> createState() =>
      _FeedbackSettingsDialogState();
}

class _FeedbackSettingsDialogState extends State<_FeedbackSettingsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('소리와 진동'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile.adaptive(
            key: const Key('sound_toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('효과음'),
            value: GameFeedback.soundEnabled,
            onChanged: (enabled) async {
              setState(() => GameFeedback.soundEnabled = enabled);
              await GameFeedback.setSoundEnabled(enabled);
            },
          ),
          SwitchListTile.adaptive(
            key: const Key('haptics_toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('진동'),
            value: GameFeedback.hapticsEnabled,
            onChanged: (enabled) async {
              setState(() => GameFeedback.hapticsEnabled = enabled);
              await GameFeedback.setHapticsEnabled(enabled);
            },
          ),
          SwitchListTile.adaptive(
            key: const Key('screen_shake_toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('화면 흔들림'),
            value: GameFeedback.screenShakeEnabled,
            onChanged: (enabled) async {
              setState(() => GameFeedback.screenShakeEnabled = enabled);
              await GameFeedback.setScreenShakeEnabled(enabled);
            },
          ),
          SwitchListTile.adaptive(
            key: const Key('reduced_motion_toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('저모션 효과'),
            subtitle: const Text('충돌 인과는 유지하고 흔들림과 반복 효과를 줄입니다.'),
            value: GameFeedback.reducedMotionEnabled,
            onChanged: (enabled) async {
              setState(() => GameFeedback.reducedMotionEnabled = enabled);
              await GameFeedback.setReducedMotionEnabled(enabled);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _TutorialExperimentDialog extends StatefulWidget {
  const _TutorialExperimentDialog({
    required this.selected,
    required this.onSelected,
  });

  final TutorialExperimentVariant selected;
  final ValueChanged<TutorialExperimentVariant> onSelected;

  @override
  State<_TutorialExperimentDialog> createState() =>
      _TutorialExperimentDialogState();
}

class _TutorialExperimentDialogState extends State<_TutorialExperimentDialog> {
  late TutorialExperimentVariant _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('tutorial_experiment_dialog'),
      title: const Text('튜토리얼 실험 조건'),
      content: RadioGroup<TutorialExperimentVariant>(
        groupValue: _selected,
        onChanged: (next) {
          if (next == null) {
            return;
          }
          setState(() => _selected = next);
          widget.onSelected(next);
          Navigator.of(context).pop();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final variant in TutorialExperimentVariant.values)
              RadioListTile<TutorialExperimentVariant>(
                key: Key('tutorial_variant_${variant.code}'),
                contentPadding: EdgeInsets.zero,
                title: Text(variant.label),
                subtitle: Text(variant.description),
                value: variant,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _StageSelectScreen extends StatelessWidget {
  const _StageSelectScreen({
    required this.onBack,
    required this.onSelectStage,
    required this.unlockedLevel,
  });

  final VoidCallback onBack;
  final ValueChanged<int> onSelectStage;
  final int unlockedLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('stage_select_screen'),
      backgroundColor: const Color(0xFFBFE8E3),
      body: Stack(
        children: [
          const Positioned.fill(child: _IslandBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: '처음 화면',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      color: const Color(0xFF173F43),
                    ),
                    const Expanded(
                      child: Text(
                        '섬 지도',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF173F43),
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '실험 섬을 골라 속성의 반응을 직접 확인해 보세요.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF285C5D),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  key: const Key('stage_route_map'),
                  padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                  decoration: BoxDecoration(
                    color: const Color(0xB8FFFDF3),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0x6687B5A8),
                      width: 1.5,
                    ),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = constraints.maxWidth * 0.82;
                      const cardStep = 116.0;
                      final mapHeight = math.max(
                        350.0,
                        8 + levels.length * cardStep,
                      );
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.route_rounded,
                                  size: 18,
                                  color: Color(0xFF397372),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '첫 항해 진행',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: const Color(0xFF397372),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(unlockedLevel + 1).clamp(1, levels.length)} / ${levels.length}',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: const Color(0xFF52706A),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: mapHeight,
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: _StageRoutePainter(
                                        unlockedLevel: unlockedLevel,
                                      ),
                                    ),
                                  ),
                                ),
                                for (
                                  var index = 0;
                                  index < levels.length;
                                  index++
                                )
                                  Positioned(
                                    top: 8 + index * cardStep,
                                    left: index.isEven ? 0 : null,
                                    right: index.isOdd ? 0 : null,
                                    width: cardWidth,
                                    child: _StageTile(
                                      index: index,
                                      locked: index > unlockedLevel,
                                      onTap: () => onSelectStage(index),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  key: const Key('map_hint_card'),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xD9E8F4D9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x6695B98C)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.explore_rounded,
                        size: 28,
                        color: Color(0xFF4F8460),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '한 번의 발사, 여러 갈래의 길',
                              style: TextStyle(
                                color: Color(0xFF315C46),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '속성을 이용해도, 다른 충돌 경로를 찾아도 괜찮아요.',
                              style: TextStyle(
                                color: Color(0xFF52706A),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StageBalloonPainter extends CustomPainter {
  const _StageBalloonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final body = Paint()..color = const Color(0xFFF28A78);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.5,
        height: size.height * 0.58,
      ),
      body,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: size.width * 0.5,
        height: size.height * 0.58,
      ),
      Paint()
        ..color = const Color(0xFF24352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center.translate(-size.width * 0.1, -size.height * 0.12),
      size.width * 0.06,
      Paint()..color = const Color(0xCCFFF7DD),
    );
    canvas.drawLine(
      center.translate(0, size.height * 0.28),
      center.translate(size.width * 0.04, size.height * 0.48),
      Paint()
        ..color = const Color(0xFF6B4B35)
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _StageBalloonPainter oldDelegate) => false;
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.index,
    required this.onTap,
    this.locked = false,
  });

  final int index;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final descriptions = [
      '무거운 성질로 상자를 움직여 보세요.',
      '탄성 있는 반사로 방향을 바꿔 보세요.',
      '문과 스위치 사이의 연쇄를 실험해 보세요.',
      '풍선은 밀리고, 뾰족한 공에는 터집니다.',
      '공이 얻는 능력과 원본이 잃는 능력을 함께 이용해 보세요.',
    ];
    final assets = [
      'assets/icons/stone_boulder.png',
      'assets/generated/jelly-bumper-v1.png',
      'assets/icons/crate.png',
      '',
      'assets/icons/stone_boulder.png',
    ];
    final stageAsset = assets[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xF7FFFDF3),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('stage_tile_$index'),
          onTap: locked ? null : onTap,
          child: Semantics(
            button: !locked,
            label: '${index + 1}번 ${levels[index].name} 섬',
            hint: locked ? '앞 섬을 클리어하면 열립니다' : '한 번 누르면 스테이지를 시작합니다',
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE8AC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFDEA96B),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: ColorFiltered(
                                colorFilter: locked
                                    ? const ColorFilter.mode(
                                        Color(0x88909B94),
                                        BlendMode.saturation,
                                      )
                                    : const ColorFilter.mode(
                                        Colors.transparent,
                                        BlendMode.dst,
                                      ),
                                child: stageAsset.isEmpty
                                    ? const CustomPaint(
                                        painter: _StageBalloonPainter(),
                                      )
                                    : Image.asset(
                                        stageAsset,
                                        fit: BoxFit.contain,
                                      ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 4,
                          child: DecoratedBox(
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF765E),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(5),
                              child: Icon(
                                locked
                                    ? Icons.lock_rounded
                                    : Icons.flag_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          levels[index].name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: locked
                                    ? const Color(0xFF718078)
                                    : const Color(0xFF244A45),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          descriptions[index],
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: locked
                                    ? const Color(0xFF81918A)
                                    : const Color(0xFF52706A),
                                height: 1.25,
                              ),
                        ),
                        const SizedBox(height: 7),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x1F4EAAA5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            child: Text(
                              locked
                                  ? '앞 섬을 먼저 클리어하세요'
                                  : '추천 파 ${levels[index].parShots}회',
                              style: TextStyle(
                                color: locked
                                    ? const Color(0xFF718078)
                                    : const Color(0xFF397372),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked ? Icons.lock_outline_rounded : Icons.chevron_right,
                    color: const Color(0xFF5B8177),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StageRoutePainter extends CustomPainter {
  const _StageRoutePainter({required this.unlockedLevel});

  final int unlockedLevel;

  @override
  void paint(Canvas canvas, Size size) {
    final points = List.generate(
      levels.length,
      (index) =>
          Offset(size.width * (index.isEven ? 0.22 : 0.78), 58 + index * 116.0),
    );
    if (points.isEmpty) {
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      final previous = points[index - 1];
      final current = points[index];
      final midpoint = (previous.dy + current.dy) / 2;
      path.cubicTo(
        previous.dx,
        midpoint - 22,
        current.dx,
        midpoint + 22,
        current.dx,
        current.dy,
      );
    }
    final route = Paint()
      ..color = const Color(0x9C6B9D8B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final completed = Paint()
      ..color = const Color(0xE06FAE76)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, route);
    if (unlockedLevel > 0) {
      final progress = Path();
      final metric = path.computeMetrics().first;
      final length =
          metric.length * (unlockedLevel / (levels.length - 1)).clamp(0.0, 1.0);
      progress.addPath(metric.extractPath(0, length), Offset.zero);
      canvas.drawPath(progress, completed);
    }
    for (var index = 0; index < levels.length; index++) {
      canvas.drawCircle(
        points[index],
        5,
        Paint()
          ..color = index <= unlockedLevel
              ? const Color(0xFF6FAE76)
              : const Color(0x8890A59A),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StageRoutePainter oldDelegate) =>
      oldDelegate.unlockedLevel != unlockedLevel;
}

class _IslandBackdrop extends StatelessWidget {
  const _IslandBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _IslandBackdropPainter());
  }
}

class _IslandBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final water = Paint()..color = const Color(0xFFBFE8E3);
    canvas.drawRect(Offset.zero & size, water);
    final sand = Paint()..color = const Color(0xFFF6D995);
    final island = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.32,
        size.height * 0.58,
        size.width * 0.63,
        size.height * 0.72,
      )
      ..quadraticBezierTo(
        size.width * 0.88,
        size.height * 0.84,
        size.width + 20,
        size.height * 0.66,
      )
      ..lineTo(size.width + 20, size.height + 20)
      ..lineTo(-20, size.height + 20)
      ..close();
    canvas.drawPath(island, sand);
    final wave = Paint()
      ..color = const Color(0x664EAAA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < 4; index++) {
      final y = size.height * (0.16 + index * 0.09);
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.08, y, size.width * 0.22, 14),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.72, y + 18, size.width * 0.2, 14),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
