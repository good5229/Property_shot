import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game/domain/game_state.dart';
import 'game/levels/levels.dart';
import 'ui/game_screen.dart';

void main() {
  runApp(const PropertyShotApp(showHome: true));
}

class PropertyShotApp extends StatelessWidget {
  const PropertyShotApp({super.key, this.initialState, this.showHome = false});

  final GameState? initialState;
  final bool showHome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '속성 한방',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
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
          ? const _PropertyShotRouter()
          : GameScreen(initialState: initialState),
    );
  }
}

class _PropertyShotRouter extends StatefulWidget {
  const _PropertyShotRouter();

  @override
  State<_PropertyShotRouter> createState() => _PropertyShotRouterState();
}

class _PropertyShotRouterState extends State<_PropertyShotRouter> {
  int? _activeStage;
  bool _showStageSelect = false;

  void _startStage(int index) {
    setState(() => _activeStage = index);
  }

  void _returnHome() {
    setState(() {
      _activeStage = null;
      _showStageSelect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeStage = _activeStage;
    if (activeStage != null) {
      return GameScreen(
        key: ValueKey('stage_$activeStage'),
        initialState: levels[activeStage].createState(activeStage),
        showStageSelector: false,
        onExit: _returnHome,
      );
    }
    if (_showStageSelect) {
      return _StageSelectScreen(
        onBack: () => setState(() => _showStageSelect = false),
        onSelectStage: _startStage,
      );
    }
    return _HomeScreen(
      onStart: () => _startStage(0),
      onStageSelect: () => setState(() => _showStageSelect = true),
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen({required this.onStart, required this.onStageSelect});

  final VoidCallback onStart;
  final VoidCallback onStageSelect;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBFE8E3),
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _IslandBackdrop()),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Semantics(
                        image: true,
                        label: '웃는 얼굴의 속성 공',
                        child: Image.asset(
                          'assets/icons/ball.png',
                          width: 112,
                          height: 112,
                        ),
                      ),
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
                          ),
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
                      const SizedBox(height: 18),
                      Text(
                        '무거움 · 탄성 · 점착',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: const Color(0xFF397372),
                          fontWeight: FontWeight.w800,
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

class _StageSelectScreen extends StatelessWidget {
  const _StageSelectScreen({required this.onBack, required this.onSelectStage});

  final VoidCallback onBack;
  final ValueChanged<int> onSelectStage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF4E9),
      appBar: AppBar(
        leading: IconButton(
          tooltip: '처음 화면',
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('섬 지도'),
        backgroundColor: const Color(0xFFEAF4E9),
        foregroundColor: const Color(0xFF173F43),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          children: [
            Text(
              '원하는 실험 섬을 골라 바로 도전하세요.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF285C5D),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            for (var index = 0; index < levels.length; index++)
              _StageTile(index: index, onTap: () => onSelectStage(index)),
          ],
        ),
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({required this.index, required this.onTap});

  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final descriptions = [
      '무거운 성질로 상자를 움직여 보세요.',
      '탄성 있는 반사로 방향을 바꿔 보세요.',
      '문과 스위치 사이의 연쇄를 실험해 보세요.',
    ];
    final assets = [
      'assets/icons/stone_boulder.png',
      'assets/generated/jelly-bumper-v1.png',
      'assets/icons/crate.png',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFFFFFCF0),
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('stage_tile_$index'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Image.asset(assets[index], width: 58, height: 58),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        levels[index].name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF244A45),
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        descriptions[index],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF52706A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFF5B8177)),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
