import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/domain/entity_state.dart';
import '../game/domain/game_state.dart';
import '../game/domain/geometry.dart';
import '../game/domain/shot_input.dart';
import '../game/domain/trait.dart';
import '../game/levels/levels.dart';
import '../game/property_shot_game.dart';
import '../game/simulation/shot_resolver.dart';
import '../game/simulation/trait_resolver.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.initialState});

  final GameState? initialState;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _shotResolver = const ShotResolver();
  final _traitResolver = const TraitResolver();
  late GameState _state;
  late PropertyShotGame _game;
  bool _showBallInfo = false;
  String? _inspectedEntityId;
  Timer? _chargeTimer;
  Timer? _clearPopupTimer;
  bool _isCharging = false;
  bool _showClearPopup = false;
  GameViewMode _viewMode = GameViewMode.top;

  @override
  void initState() {
    super.initState();
    _state = widget.initialState ?? levels.first.createState(0);
    _game = PropertyShotGame(_state);
    _showClearPopup = _state.phase == GamePhase.success;
  }

  void _setState(
    GameState next, {
    List<Vec2> path = const [],
    GameState? transitionStart,
    List<ShotAnimationMove> moves = const [],
  }) {
    setState(() {
      _state = next;
      if (next.phase != GamePhase.success) {
        _showClearPopup = false;
      }
      _game.setStateSnapshot(
        next,
        path: path,
        transitionStart: transitionStart,
        moves: moves,
      );
    });
  }

  void _selectLevel(int index) {
    _showBallInfo = false;
    _inspectedEntityId = null;
    _clearPopupTimer?.cancel();
    _showClearPopup = false;
    _setState(levels[index].createState(index));
  }

  void _goNextLevel() {
    final nextIndex = (_state.levelIndex + 1) % levels.length;
    _selectLevel(nextIndex);
  }

  void _setViewMode(GameViewMode mode) {
    setState(() {
      _viewMode = mode;
      _game.setViewMode(mode);
    });
  }

  void _selectTraitSource(String sourceId) {
    _showBallInfo = false;
    _inspectedEntityId = sourceId;
    _setState(_traitResolver.selectSource(_state, sourceId));
  }

  void _transferTrait() {
    _setState(_traitResolver.transferSelectedTrait(_state));
  }

  void _copyTrait() {
    _setState(_traitResolver.copySelectedTrait(_state));
  }

  void _launch() {
    if (_state.phase != GamePhase.planning) {
      return;
    }
    final result = _shotResolver.resolve(
      _state,
      ShotInput(
        direction: _state.aimDirection,
        power: _state.aimPower,
        equippedTrait: _state.equippedTrait,
      ),
    );
    _showBallInfo = false;
    _inspectedEntityId = null;
    _clearPopupTimer?.cancel();
    _setState(
      result.state,
      path: result.path,
      transitionStart: _state,
      moves: result.moves,
    );
    if (result.state.phase == GamePhase.success) {
      final delayMs = (result.path.length * 26).clamp(680, 2200);
      _clearPopupTimer = Timer(Duration(milliseconds: delayMs), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _showClearPopup = true;
        });
      });
    }
  }

  void _rewind() {
    _setState(_shotResolver.rewind(_state));
  }

  void _togglePause() {
    if (_state.phase == GamePhase.paused) {
      _setState(
        _state.copyWith(phase: GamePhase.planning, message: '계획을 계속하세요.'),
      );
    } else if (_state.phase == GamePhase.planning) {
      _setState(_state.copyWith(phase: GamePhase.paused, message: '일시정지'));
    }
  }

  void _updateAim(Offset localPosition, Size fieldSize) {
    if (_state.phase != GamePhase.planning) {
      return;
    }
    final logical = _toLogicalPosition(localPosition, fieldSize);
    final aim = logical - _state.activeBall.position;
    _setState(
      _state.copyWith(aimDirection: aim.normalized(), message: '방향 조정'),
    );
  }

  Vec2 _toLogicalPosition(Offset localPosition, Size fieldSize) {
    final scale =
        (fieldSize.width / logicalSize.x < fieldSize.height / logicalSize.y)
        ? fieldSize.width / logicalSize.x
        : fieldSize.height / logicalSize.y;
    final origin = Offset(
      (fieldSize.width - logicalSize.x * scale) / 2,
      (fieldSize.height - logicalSize.y * scale) / 2,
    );
    final projectedX = (localPosition.dx - origin.dx) / scale;
    final projectedY = (localPosition.dy - origin.dy) / scale;
    if (_viewMode == GameViewMode.top) {
      return Vec2(projectedX, projectedY);
    }
    const xScale = 0.88;
    const yScale = 0.70710678118;
    final yOffset = (logicalSize.y - logicalSize.y * yScale) / 2;
    const shear = 0.09899494936;
    final y = (projectedY - yOffset) / yScale;
    final x =
        ((projectedX - logicalSize.x / 2) - (y - logicalSize.y / 2) * shear) /
            xScale +
        logicalSize.x / 2;
    return Vec2(x, y);
  }

  void _dismissInfo() {
    setState(() {
      _showBallInfo = false;
      _inspectedEntityId = null;
    });
  }

  void _handleFieldTap(Offset localPosition, Size fieldSize) {
    final logical = _toLogicalPosition(localPosition, fieldSize);
    if (logical.distanceTo(_state.activeBall.position) <= 34) {
      setState(() {
        _showBallInfo = true;
        _inspectedEntityId = null;
      });
      return;
    }
    for (final entity in _state.entities) {
      if (entity.id == _state.activeBall.id || !entity.active) {
        continue;
      }
      final hit = entity.isCircle
          ? logical.distanceTo(entity.position) <= entity.radius + 10
          : entity.bounds.intersectsCircle(logical, 10);
      if (hit) {
        if (entity.traits.isNotEmpty) {
          _selectTraitSource(entity.id);
        } else {
          setState(() {
            _showBallInfo = false;
            _inspectedEntityId = entity.id;
          });
        }
        return;
      }
    }
    setState(() {
      _showBallInfo = false;
      _inspectedEntityId = null;
    });
  }

  void _startPowerCharge(Offset localPosition, Size fieldSize) {
    if (_state.phase != GamePhase.planning) {
      return;
    }
    final logical = _toLogicalPosition(localPosition, fieldSize);
    if (logical.distanceTo(_state.activeBall.position) > 42) {
      return;
    }
    _chargeTimer?.cancel();
    _isCharging = true;
    _setState(_state.copyWith(aimPower: 0.12, message: '힘 모으는 중'));
    _chargeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) {
        return;
      }
      final nextPower = (_state.aimPower + 0.055).clamp(0.12, 1.0);
      _setState(
        _state.copyWith(
          aimPower: nextPower,
          message: '힘 ${(nextPower * 100).round()}%',
        ),
      );
    });
  }

  void _stopPowerCharge() {
    final shouldLaunch = _isCharging && _state.phase == GamePhase.planning;
    _isCharging = false;
    _chargeTimer?.cancel();
    _chargeTimer = null;
    if (shouldLaunch) {
      _launch();
    }
  }

  @override
  void dispose() {
    _chargeTimer?.cancel();
    _clearPopupTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspectedEntity = _inspectedEntityId == null
        ? null
        : _state.entityById(_inspectedEntityId!);
    return Scaffold(
      backgroundColor: const Color(0xFFE3E8DF),
      appBar: AppBar(
        title: const Text('속성 한방'),
        backgroundColor: const Color(0xFF24352D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            key: const Key('pause_button'),
            tooltip: _state.phase == GamePhase.paused ? '계속' : '멈춤',
            onPressed: _togglePause,
            icon: Icon(
              _state.phase == GamePhase.paused ? Icons.play_arrow : Icons.pause,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    _Hud(
                      state: _state,
                      viewMode: _viewMode,
                      onSelectLevel: _selectLevel,
                      onViewModeChanged: _setViewMode,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              key: const Key('aim_area'),
                              onTapUp: (details) => _handleFieldTap(
                                details.localPosition,
                                constraints.biggest,
                              ),
                              onLongPressStart: (details) => _startPowerCharge(
                                details.localPosition,
                                constraints.biggest,
                              ),
                              onLongPressMoveUpdate: (details) => _updateAim(
                                details.localPosition,
                                constraints.biggest,
                              ),
                              onLongPressEnd: (_) => _stopPowerCharge(),
                              onPanUpdate: (details) => _updateAim(
                                details.localPosition,
                                constraints.biggest,
                              ),
                              onPanEnd: (_) =>
                                  _setState(_state.copyWith(message: '조준 고정')),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: GameWidget(game: _game),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    _ControlPanel(
                      state: _state,
                      onTransfer: _transferTrait,
                      onCopy: _copyTrait,
                      onRewind: _rewind,
                      onReset: () => _selectLevel(_state.levelIndex),
                    ),
                  ],
                ),
              ),
            ),
            if (_showBallInfo)
              _InfoPopup(
                onClose: _dismissInfo,
                child: _BallInfoPanel(state: _state),
              ),
            if (!_showBallInfo && inspectedEntity != null)
              _InfoPopup(
                onClose: _dismissInfo,
                child: _EntityInfoPanel(entity: inspectedEntity),
              ),
            if (_state.phase == GamePhase.success && _showClearPopup)
              _ClearPopup(state: _state, onNext: _goNextLevel),
          ],
        ),
      ),
    );
  }
}

class _ClearPopup extends StatelessWidget {
  const _ClearPopup({required this.state, required this.onNext});

  final GameState state;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final rows = _leaderboardRows(state);
    return Container(
      key: const Key('clear_popup'),
      color: const Color(0x88000000),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7DB),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF503C2E), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44000000),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('클리어!', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 6),
                Text('${state.shotCount}번 만에 성공'),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.74),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4C56A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('다른 플레이어 기록'),
                      const SizedBox(height: 8),
                      for (var i = 0; i < rows.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              SizedBox(width: 28, child: Text('${i + 1}위')),
                              Expanded(child: Text(rows[i].name)),
                              Text('${rows[i].shots}회'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  key: const Key('next_stage_button'),
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('다음'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardRow {
  const _LeaderboardRow(this.name, this.shots);

  final String name;
  final int shots;
}

List<_LeaderboardRow> _leaderboardRows(GameState state) {
  final base = switch (state.levelIndex) {
    0 => const [
      _LeaderboardRow('나무별', 2),
      _LeaderboardRow('몽글이', 3),
      _LeaderboardRow('민트공', 4),
    ],
    1 => const [
      _LeaderboardRow('반짝젤리', 2),
      _LeaderboardRow('두둥실', 4),
      _LeaderboardRow('초록길', 5),
    ],
    _ => const [
      _LeaderboardRow('문지기', 3),
      _LeaderboardRow('찰싹이', 5),
      _LeaderboardRow('돌돌샷', 6),
    ],
  };
  final rows = [...base, _LeaderboardRow('나', state.shotCount)]
    ..sort((a, b) => a.shots.compareTo(b.shots));
  return rows.take(4).toList();
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.state,
    required this.viewMode,
    required this.onSelectLevel,
    required this.onViewModeChanged,
  });

  final GameState state;
  final GameViewMode viewMode;
  final ValueChanged<int> onSelectLevel;
  final ValueChanged<GameViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.levelName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text('샷 ${state.shotCount}'),
              const SizedBox(width: 12),
              Text('점수 ${state.score}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SegmentedButton<GameViewMode>(
                key: const Key('view_mode_control'),
                segments: const [
                  ButtonSegment(
                    value: GameViewMode.top,
                    icon: Icon(Icons.grid_view),
                    label: Text('위', softWrap: false),
                  ),
                  ButtonSegment(
                    value: GameViewMode.quarter,
                    icon: Icon(Icons.view_in_ar),
                    label: Text('입체', softWrap: false),
                  ),
                ],
                selected: {viewMode},
                onSelectionChanged: (selection) =>
                    onViewModeChanged(selection.first),
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < levels.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    key: Key('level_$i'),
                    label: Text('${i + 1}'),
                    selected: state.levelIndex == i,
                    onSelected: (_) => onSelectLevel(i),
                  ),
                ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAF3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF9AA89F)),
                  ),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.state,
    required this.onTransfer,
    required this.onCopy,
    required this.onRewind,
    required this.onReset,
  });

  final GameState state;
  final VoidCallback onTransfer;
  final VoidCallback onCopy;
  final VoidCallback onRewind;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  state.selectedTrait == null
                      ? '물체를 눌러 속성을 고르세요'
                      : '선택: ${state.selectedTrait!.label}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                key: const Key('transfer_button'),
                onPressed: state.selectedTrait == null ? null : onTransfer,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('옮기기'),
              ),
              const SizedBox(width: 6),
              OutlinedButton.icon(
                key: const Key('copy_button'),
                onPressed: state.selectedTrait == null ? null : onCopy,
                icon: const Icon(Icons.copy),
                label: const Text('복사'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '공: ${state.equippedTrait?.label ?? '없음'}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                key: const Key('rewind_button'),
                tooltip: '되감기',
                onPressed: onRewind,
                icon: const Icon(Icons.undo),
              ),
              IconButton(
                key: const Key('reset_button'),
                tooltip: '다시',
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoPopup extends StatelessWidget {
  const _InfoPopup({required this.child, required this.onClose});

  final Widget child;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 18,
      right: 18,
      bottom: 128,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Material(color: Colors.transparent, child: child),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton.filled(
                    key: const Key('info_close_button'),
                    tooltip: '닫기',
                    onPressed: onClose,
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF24352D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EntityInfoPanel extends StatelessWidget {
  const _EntityInfoPanel({required this.entity});

  final EntityState entity;

  @override
  Widget build(BuildContext context) {
    final trait = entity.traits.isEmpty ? null : entity.traits.first;
    return Container(
      key: const Key('entity_info_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF59685F), width: 2),
      ),
      child: Row(
        children: [
          _EntityThumbnail(entity: entity),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _entityName(entity),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  trait == null
                      ? _entityDescription(entity)
                      : '${trait.label}: ${trait.description}',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BallInfoPanel extends StatelessWidget {
  const _BallInfoPanel({required this.state});

  final GameState state;

  @override
  Widget build(BuildContext context) {
    final trait = state.equippedTrait;
    return Container(
      key: const Key('ball_info_panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF24352D), width: 2),
      ),
      child: Row(
        children: [
          _BallThumbnail(trait: trait),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trait == null ? '공 속성 없음' : '공 속성: ${trait.label}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  trait?.description ?? '속성 물체를 선택한 뒤 공으로 옮기세요.',
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityThumbnail extends StatelessWidget {
  const _EntityThumbnail({required this.entity});

  final EntityState entity;

  @override
  Widget build(BuildContext context) {
    final trait = entity.traits.isEmpty ? null : entity.traits.first;
    final assetPath = _assetPath(entity);
    return _ThumbnailFrame(
      backgroundColor: trait == null
          ? const Color(0xFFE0E6E1)
          : _traitUiColor(trait),
      child: entity.type == EntityType.ball
          ? CustomPaint(
              painter: _GameBallIconPainter(trait),
              size: const Size(34, 34),
            )
          : assetPath == null
          ? CustomPaint(
              painter: _EntityIconPainter(entity),
              size: const Size(34, 34),
            )
          : Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset(assetPath, fit: BoxFit.contain),
            ),
    );
  }
}

class _BallThumbnail extends StatelessWidget {
  const _BallThumbnail({required this.trait});

  final TraitType? trait;

  @override
  Widget build(BuildContext context) {
    return _ThumbnailFrame(
      backgroundColor: trait == null ? Colors.white : _traitUiColor(trait!),
      child: CustomPaint(
        painter: _GameBallIconPainter(trait),
        size: const Size(34, 34),
      ),
    );
  }
}

class _ThumbnailFrame extends StatelessWidget {
  const _ThumbnailFrame({required this.child, required this.backgroundColor});

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF24352D), width: 1.5),
      ),
      child: ClipOval(child: Center(child: child)),
    );
  }
}

class _EntityIconPainter extends CustomPainter {
  const _EntityIconPainter(this.entity);

  final EntityState entity;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outline = Paint()
      ..color = const Color(0xFF24352D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    switch (entity.type) {
      case EntityType.hole:
        canvas.drawCircle(
          center.translate(-1, 3),
          9,
          Paint()..color = Colors.black87,
        );
        canvas.drawLine(
          center.translate(7, 3),
          center.translate(7, -12),
          Paint()
            ..color = const Color(0xFF6B4B35)
            ..strokeWidth = 2,
        );
        final flag = Path()
          ..moveTo(center.dx + 8, center.dy - 12)
          ..lineTo(center.dx + 21, center.dy - 8)
          ..lineTo(center.dx + 8, center.dy - 4)
          ..close();
        canvas.drawPath(flag, Paint()..color = const Color(0xFFFF6B6B));
      case EntityType.wall:
        final brick = Paint()..color = const Color(0xFF798A8C);
        for (var y = 7.0; y < 29; y += 9) {
          for (var x = y == 16 ? 1.0 : 6.0; x < 31; x += 13) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(x, y, 11, 7),
                const Radius.circular(2),
              ),
              brick,
            );
          }
        }
      case EntityType.bumper:
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 26, height: 20),
          Paint()..color = const Color(0xFF4EAF7C),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: center.translate(-3, -3),
            width: 12,
            height: 7,
          ),
          Paint()..color = const Color(0xAAFFFFFF),
        );
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 26, height: 20),
          outline,
        );
      case EntityType.stickySurface:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 26, height: 22),
            const Radius.circular(8),
          ),
          Paint()..color = const Color(0xFF8E5AA9),
        );
        final dot = Paint()..color = const Color(0xAAFFFFFF);
        canvas.drawCircle(center.translate(-7, -4), 3, dot);
        canvas.drawCircle(center.translate(5, 4), 4, dot);
        canvas.drawCircle(center.translate(9, -6), 2, dot);
      case EntityType.switchPad:
        final body = RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: 26, height: 16),
          const Radius.circular(7),
        );
        canvas.drawRRect(
          body,
          Paint()
            ..color = entity.pressed
                ? const Color(0xFF4EAF7C)
                : const Color(0xFFE2C044),
        );
        canvas.drawCircle(center, 5, Paint()..color = const Color(0xFFFFF2A8));
        canvas.drawRRect(body, outline);
      case EntityType.gate:
        final gatePaint = Paint()
          ..color = entity.open
              ? const Color(0x884EAF7C)
              : const Color(0xFFC24E3A)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          center.translate(-6, -11),
          center.translate(-6, 11),
          gatePaint,
        );
        canvas.drawLine(
          center.translate(6, -11),
          center.translate(6, 11),
          gatePaint,
        );
        canvas.drawLine(
          center.translate(-11, -8),
          center.translate(11, -8),
          outline,
        );
        canvas.drawLine(
          center.translate(-11, 8),
          center.translate(11, 8),
          outline,
        );
      case EntityType.ball:
      case EntityType.crate:
      case EntityType.weight:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _EntityIconPainter oldDelegate) =>
      oldDelegate.entity.type != entity.type ||
      oldDelegate.entity.open != entity.open ||
      oldDelegate.entity.pressed != entity.pressed;
}

class _GameBallIconPainter extends CustomPainter {
  const _GameBallIconPainter(this.trait);

  final TraitType? trait;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;
    final baseColor = trait == null ? Colors.white : _traitBallColor(trait!);
    final gradient = RadialGradient(
      center: const Alignment(-0.45, -0.55),
      radius: 0.96,
      colors: [
        Colors.white.withValues(alpha: 0.98),
        baseColor,
        Color.lerp(baseColor, const Color(0xFF152018), 0.22)!,
      ],
      stops: const [0.0, 0.58, 1.0],
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(3, radius * 0.72),
        width: radius * 1.6,
        height: radius * 0.42,
      ),
      Paint()..color = const Color(0x24000000),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF24352D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.7,
    );
    final eye = Paint()..color = const Color(0xFF3B302A);
    final blush = Paint()..color = const Color(0x44FF8EA1);
    canvas.drawCircle(center.translate(-4.2, -2.6), 1.45, eye);
    canvas.drawCircle(center.translate(4.2, -2.6), 1.45, eye);
    canvas.drawCircle(center.translate(-6.4, 3.6), 2.2, blush);
    canvas.drawCircle(center.translate(6.4, 3.6), 2.2, blush);
    canvas.drawArc(
      Rect.fromCenter(center: center.translate(0, 1), width: 7, height: 5),
      0.15,
      2.84,
      false,
      Paint()
        ..color = const Color(0xFF3B302A)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      center.translate(-4.2, -6.3),
      2.6,
      Paint()..color = const Color(0x88FFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _GameBallIconPainter oldDelegate) =>
      oldDelegate.trait != trait;
}

String? _assetPath(EntityState entity) {
  return switch (entity.type) {
    EntityType.crate => 'assets/icons/crate.png',
    EntityType.weight => 'assets/icons/stone_boulder.png',
    _ => null,
  };
}

String _entityName(EntityState entity) {
  switch (entity.type) {
    case EntityType.ball:
      return '공';
    case EntityType.hole:
      return '홀';
    case EntityType.wall:
      return '벽';
    case EntityType.crate:
      return '상자';
    case EntityType.bumper:
      return '젤리';
    case EntityType.stickySurface:
      return '점착판';
    case EntityType.weight:
      return '무거운 돌';
    case EntityType.switchPad:
      return '스위치';
    case EntityType.gate:
      return '문';
  }
}

String _entityDescription(EntityState entity) {
  switch (entity.type) {
    case EntityType.ball:
      return '다음 샷과 충돌할 수 있는 공입니다.';
    case EntityType.hole:
      return '공이 들어가야 하는 목표 지점입니다.';
    case EntityType.wall:
      return '움직이지 않는 고정 벽입니다. 공은 맞고 튕깁니다.';
    case EntityType.crate:
      return '충격을 받으면 밀릴 수 있는 상자입니다.';
    case EntityType.bumper:
      return '탄성을 가진 젤리 물체입니다.';
    case EntityType.stickySurface:
      return '점착 속성을 가진 표면입니다.';
    case EntityType.weight:
      return '무거움 속성을 가진 돌입니다.';
    case EntityType.switchPad:
      return '무거운 공이 누르면 문을 여는 장치입니다.';
    case EntityType.gate:
      return entity.open ? '열려 있는 문입니다.' : '닫힌 문입니다. 공은 맞고 튕깁니다.';
  }
}

Color _traitUiColor(TraitType trait) {
  switch (trait) {
    case TraitType.heavy:
      return const Color(0xFFB8C7D0);
    case TraitType.bouncy:
      return const Color(0xFFA9E7BF);
    case TraitType.sticky:
      return const Color(0xFFD2B5F0);
  }
}

Color _traitBallColor(TraitType trait) {
  switch (trait) {
    case TraitType.heavy:
      return const Color(0xFF4D6572);
    case TraitType.bouncy:
      return const Color(0xFF2EAD74);
    case TraitType.sticky:
      return const Color(0xFF8D5BB8);
  }
}
