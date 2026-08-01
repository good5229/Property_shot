import 'dart:math' as math;
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Timer? _animationUnlockTimer;
  bool _isCharging = false;
  bool _isAnimatingShot = false;
  bool _showClearPopup = false;
  bool _bestShotsLoaded = false;
  Future<void>? _bestShotsLoadFuture;
  final Map<int, int> _bestShots = {};

  @override
  void initState() {
    super.initState();
    _state =
        widget.initialState ??
        levels.first.createState(0).copyWith(message: _levelIntroMessage(0));
    _game = PropertyShotGame(_state);
    _showClearPopup = _state.phase == GamePhase.success;
    _bestShotsLoadFuture = _loadBestShots();
  }

  Future<void> _loadBestShots() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    final loaded = <int, int>{};
    for (var index = 0; index < levels.length; index++) {
      final best = preferences.getInt(_bestShotKey(index));
      if (best != null) {
        loaded[index] = best;
      }
    }
    setState(
      () => _bestShots
        ..clear()
        ..addAll(loaded),
    );
    _bestShotsLoaded = true;
  }

  Future<void> _recordBestShot(int levelIndex, int shotCount) async {
    if (!_bestShotsLoaded) {
      _bestShotsLoadFuture ??= _loadBestShots();
      await _bestShotsLoadFuture;
      if (!mounted) {
        return;
      }
    }
    final current = _bestShots[levelIndex];
    if (current != null && current <= shotCount) {
      return;
    }
    setState(() => _bestShots[levelIndex] = shotCount);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_bestShotKey(levelIndex), shotCount);
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
    if (_isAnimatingShot) {
      return;
    }
    _showBallInfo = false;
    _inspectedEntityId = null;
    _clearPopupTimer?.cancel();
    _showClearPopup = false;
    _setState(
      levels[index]
          .createState(index)
          .copyWith(message: _levelIntroMessage(index)),
    );
  }

  void _goNextLevel() {
    final nextIndex = (_state.levelIndex + 1) % levels.length;
    _selectLevel(nextIndex);
  }

  void _selectTraitSource(String sourceId) {
    unawaited(HapticFeedback.selectionClick());
    _showBallInfo = false;
    _inspectedEntityId = sourceId;
    _setState(_traitResolver.selectSource(_state, sourceId));
  }

  void _transferTrait() {
    unawaited(HapticFeedback.mediumImpact());
    _showBallInfo = false;
    _inspectedEntityId = null;
    _setState(
      _traitResolver
          .transferSelectedTrait(_state)
          .copyWith(message: '속성을 공에 담았습니다. 공을 길게 누르고 방향을 정하세요.'),
    );
  }

  void _copyTrait() {
    unawaited(HapticFeedback.selectionClick());
    _showBallInfo = false;
    _inspectedEntityId = null;
    _setState(
      _traitResolver
          .copySelectedTrait(_state)
          .copyWith(message: '속성을 공에 복사했습니다. 공을 길게 누르고 방향을 정하세요.'),
    );
  }

  void _launch() {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
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
    _feedbackForShot(result);
    _showBallInfo = false;
    _inspectedEntityId = null;
    _clearPopupTimer?.cancel();
    _animationUnlockTimer?.cancel();
    _isAnimatingShot = true;
    _setState(
      result.state,
      path: result.path,
      transitionStart: _state,
      moves: result.moves,
    );
    var animationFrames = result.path.length;
    for (final move in result.moves) {
      final moveFrames = move.path.length < 2
          ? 12
          : (move.path.length * 2).clamp(12, 96);
      animationFrames = math.max(
        animationFrames,
        move.triggerPathIndex + moveFrames,
      );
    }
    final delayMs = (animationFrames * 38 + result.moves.length * 140).clamp(
      900,
      6000,
    );
    if (result.state.phase == GamePhase.success) {
      unawaited(
        _recordBestShot(result.state.levelIndex, result.state.shotCount),
      );
      _animationUnlockTimer = Timer(Duration(milliseconds: delayMs), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _isAnimatingShot = false;
          _showClearPopup = true;
        });
      });
    } else {
      _animationUnlockTimer = Timer(Duration(milliseconds: delayMs), () {
        if (!mounted) {
          return;
        }
        setState(() => _isAnimatingShot = false);
      });
    }
  }

  void _feedbackForShot(ShotResult result) {
    if (result.state.phase == GamePhase.success) {
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    if (result.events.any(
      (event) =>
          event == 'bounced' ||
          event == 'chain_push' ||
          event == 'momentum_transfer' ||
          event.startsWith('chain_collision_'),
    )) {
      unawaited(HapticFeedback.mediumImpact());
      return;
    }
    unawaited(HapticFeedback.lightImpact());
  }

  void _rewind() {
    if (_isAnimatingShot) {
      return;
    }
    _setState(_shotResolver.rewind(_state));
  }

  void _togglePause() {
    if (_isAnimatingShot) {
      return;
    }
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

  void _nudgeAim(double radians) {
    if (_state.phase != GamePhase.planning) {
      return;
    }
    final current = math.atan2(_state.aimDirection.y, _state.aimDirection.x);
    final next = current + radians;
    _setState(
      _state.copyWith(
        aimDirection: Vec2(math.cos(next), math.sin(next)),
        message: '접근성 조준 방향 조정',
      ),
    );
  }

  void _handleSemanticEntity(String entityId) {
    if (entityId == _state.activeBall.id) {
      setState(() {
        _showBallInfo = true;
        _inspectedEntityId = null;
      });
      return;
    }
    final entity = _state.entityById(entityId);
    if (entity == null || !entity.active) {
      return;
    }
    if (entity.traits.isNotEmpty) {
      _selectTraitSource(entity.id);
    }
    setState(() {
      _showBallInfo = false;
      _inspectedEntityId = entity.id;
    });
  }

  String _semanticEntityLabel(EntityState entity) {
    final name = _entityName(entity);
    final state = switch (entity.type) {
      EntityType.ball =>
        entity.traits.isEmpty
            ? '현재 속성 없음'
            : '${entity.traits.first.label} 속성 보유',
      EntityType.hole => '목표 홀',
      EntityType.switchPad => entity.pressed ? '눌림' : '누르기 전',
      EntityType.gate => entity.open ? '열림' : '닫힘',
      _ =>
        entity.traits.isEmpty
            ? '상호작용 가능한 물체'
            : '${entity.traits.first.label} 속성 보유',
    };
    return '$name, $state';
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
    return Vec2(projectedX, projectedY);
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
        }
        setState(() {
          _showBallInfo = false;
          _inspectedEntityId = entity.id;
        });
        return;
      }
    }
    setState(() {
      _showBallInfo = false;
      _inspectedEntityId = null;
    });
  }

  void _startPowerCharge(Offset localPosition, Size fieldSize) {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
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

  void _cancelPowerCharge() {
    _isCharging = false;
    _chargeTimer?.cancel();
    _chargeTimer = null;
    if (mounted && _state.phase == GamePhase.planning) {
      _setState(_state.copyWith(message: '발사를 취소했습니다'));
    }
  }

  @override
  void dispose() {
    _chargeTimer?.cancel();
    _clearPopupTimer?.cancel();
    _animationUnlockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspectedEntity = _inspectedEntityId == null
        ? null
        : _state.entityById(_inspectedEntityId!);
    final contentWidth = MediaQuery.sizeOf(context).width < 520
        ? MediaQuery.sizeOf(context).width
        : 520.0;
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
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    _Hud(state: _state, onSelectLevel: _selectLevel),
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: _showBallInfo || inspectedEntity != null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final semanticLaunch = CustomSemanticsAction(
                                label: '공 발사',
                              );
                              final fieldSize = constraints.biggest;
                              final scale = math.min(
                                fieldSize.width / logicalSize.x,
                                fieldSize.height / logicalSize.y,
                              );
                              final origin = Offset(
                                (fieldSize.width - logicalSize.x * scale) / 2,
                                (fieldSize.height - logicalSize.y * scale) / 2,
                              );
                              return Stack(
                                fit: StackFit.expand,
                                children: [
                                  GestureDetector(
                                    key: const Key('aim_area'),
                                    onTapUp: (details) => _handleFieldTap(
                                      details.localPosition,
                                      fieldSize,
                                    ),
                                    onLongPressStart: (details) =>
                                        _startPowerCharge(
                                          details.localPosition,
                                          fieldSize,
                                        ),
                                    onLongPressMoveUpdate: (details) =>
                                        _updateAim(
                                          details.localPosition,
                                          fieldSize,
                                        ),
                                    onLongPressEnd: (_) => _stopPowerCharge(),
                                    onLongPressCancel: _cancelPowerCharge,
                                    onPanUpdate: (details) => _updateAim(
                                      details.localPosition,
                                      fieldSize,
                                    ),
                                    onPanEnd: (_) {
                                      if (_state.phase == GamePhase.planning) {
                                        _setState(
                                          _state.copyWith(message: '조준 고정'),
                                        );
                                      }
                                    },
                                    child: Semantics(
                                      container: true,
                                      label: '공을 조준하는 게임 화면',
                                      value:
                                          '힘 ${(_state.aimPower * 100).round()}퍼센트',
                                      increasedValue:
                                          '힘 ${((_state.aimPower + 0.055).clamp(0.0, 1.0) * 100).round()}퍼센트',
                                      decreasedValue:
                                          '힘 ${((_state.aimPower - 0.055).clamp(0.0, 1.0) * 100).round()}퍼센트',
                                      hint: '손가락으로 방향과 힘을 정하거나 접근성 동작을 사용하세요',
                                      onIncrease: () => _nudgeAim(math.pi / 18),
                                      onDecrease: () =>
                                          _nudgeAim(-math.pi / 18),
                                      customSemanticsActions: {
                                        semanticLaunch: _launch,
                                      },
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Center(
                                          child: AspectRatio(
                                            aspectRatio:
                                                logicalSize.x / logicalSize.y,
                                            child: GameWidget(game: _game),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  for (final entity in _state.entities)
                                    if (entity.active)
                                      Positioned(
                                        left:
                                            origin.dx +
                                            (entity.position.x -
                                                    entity.size.x / 2) *
                                                scale,
                                        top:
                                            origin.dy +
                                            (entity.position.y -
                                                    entity.size.y / 2) *
                                                scale,
                                        width: math.max(
                                          32,
                                          entity.size.x * scale,
                                        ),
                                        height: math.max(
                                          32,
                                          entity.size.y * scale,
                                        ),
                                        child: Semantics(
                                          container: true,
                                          button:
                                              entity.type == EntityType.ball ||
                                              entity.traits.isNotEmpty,
                                          label: _semanticEntityLabel(entity),
                                          hint: entity.traits.isNotEmpty
                                              ? '선택하면 속성 정보를 확인할 수 있습니다'
                                              : null,
                                          onTap: () =>
                                              _handleSemanticEntity(entity.id),
                                          child: const SizedBox.expand(),
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    _ControlPanel(
                      state: _state,
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
                child: _EntityInfoPanel(
                  entity: inspectedEntity,
                  onTransfer: inspectedEntity.traits.isEmpty
                      ? null
                      : _transferTrait,
                  onCopy: inspectedEntity.traits.isEmpty ? null : _copyTrait,
                ),
              ),
            if (_state.phase == GamePhase.success && _showClearPopup)
              _ClearPopup(
                state: _state,
                bestShot: _bestShots[_state.levelIndex],
                onNext: _goNextLevel,
              ),
          ],
        ),
      ),
    );
  }
}

class _ClearPopup extends StatelessWidget {
  const _ClearPopup({required this.state, required this.onNext, this.bestShot});

  final GameState state;
  final VoidCallback onNext;
  final int? bestShot;

  @override
  Widget build(BuildContext context) {
    final rows = _leaderboardRows(state);
    return Semantics(
      container: true,
      namesRoute: true,
      label: '클리어 결과 팝업',
      child: Container(
        key: const Key('clear_popup'),
        color: const Color(0x88000000),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7DB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF503C2E),
                      width: 3,
                    ),
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
                      Text(
                        '클리어!',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 6),
                      Text('${state.shotCount}번 만에 성공'),
                      if (bestShot != null) ...[
                        const SizedBox(height: 4),
                        Text('내 최고 기록 $bestShot회'),
                      ],
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
                            const Text('예시 기록'),
                            const SizedBox(height: 8),
                            for (var i = 0; i < rows.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 3,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 28,
                                      child: Text('${i + 1}위'),
                                    ),
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

String _bestShotKey(int levelIndex) => 'best_shots_level_$levelIndex';

String _levelObjective(int levelIndex) {
  return switch (levelIndex) {
    0 => '무거움을 옮겨 상자를 밀고 홀에 넣으세요.',
    1 => '탄성을 활용해 벽에 반사시키고 홀을 노리세요.',
    _ => '무거운 공으로 스위치를 눌러 문을 연 뒤 홀에 넣으세요.',
  };
}

String _levelIntroMessage(int levelIndex) {
  return switch (levelIndex) {
    0 => '반짝이는 무거운 돌을 누르고, 옮기기를 선택하세요.',
    1 => '초록 젤리를 누르고, 탄성을 공에 담아보세요.',
    _ => '무거운 돌을 누르고, 옮기기로 스위치를 준비하세요.',
  };
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
  const _Hud({required this.state, required this.onSelectLevel});

  final GameState state;
  final ValueChanged<int> onSelectLevel;

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
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _levelObjective(state.levelIndex),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF46584E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (var i = 0; i < levels.length; i++)
                      Semantics(
                        label: '${i + 1}단계 선택',
                        button: true,
                        selected: state.levelIndex == i,
                        child: ChoiceChip(
                          key: Key('level_$i'),
                          label: Text('${i + 1}'),
                          selected: state.levelIndex == i,
                          onSelected: (_) => onSelectLevel(i),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF9AA89F)),
            ),
            child: Semantics(
              liveRegion: true,
              label: '게임 안내: ${state.message}',
              child: Text(state.message, softWrap: true),
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.state,
    required this.onRewind,
    required this.onReset,
  });

  final GameState state;
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: Text('공: ${state.equippedTrait?.label ?? '없음'}')),
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
    return Positioned.fill(
      child: Stack(
        children: [
          const ModalBarrier(color: Color(0x22000000), dismissible: false),
          Positioned(
            left: 18,
            right: 18,
            bottom: 128,
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    maxHeight: MediaQuery.sizeOf(context).height - 180,
                  ),
                  child: SingleChildScrollView(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Semantics(
                          container: true,
                          namesRoute: true,
                          label: '정보 팝업',
                          child: Material(
                            color: Colors.transparent,
                            child: child,
                          ),
                        ),
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
            ),
          ),
        ],
      ),
    );
  }
}

class _EntityInfoPanel extends StatelessWidget {
  const _EntityInfoPanel({required this.entity, this.onTransfer, this.onCopy});

  final EntityState entity;
  final VoidCallback? onTransfer;
  final VoidCallback? onCopy;

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
                ),
                if (trait != null) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [
                      Semantics(
                        label: '선택한 ${trait.label} 속성을 공으로 옮기기',
                        button: true,
                        child: FilledButton.icon(
                          key: const Key('transfer_button'),
                          onPressed: onTransfer,
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text('옮기기'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      Semantics(
                        label: '선택한 ${trait.label} 속성을 원본에 남기고 공으로 복사하기',
                        button: true,
                        child: OutlinedButton.icon(
                          key: const Key('copy_button'),
                          onPressed: onCopy,
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('복사'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
                Text(trait?.description ?? '속성 물체를 선택한 뒤 공으로 옮기세요.'),
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
    return Semantics(
      image: true,
      label: '${_entityName(entity)} 아이콘',
      child: _ThumbnailFrame(
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
      ),
    );
  }
}

class _BallThumbnail extends StatelessWidget {
  const _BallThumbnail({required this.trait});

  final TraitType? trait;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: trait == null ? '공 아이콘' : '${trait!.label} 공 아이콘',
      child: _ThumbnailFrame(
        backgroundColor: trait == null ? Colors.white : _traitUiColor(trait!),
        child: CustomPaint(
          painter: _GameBallIconPainter(trait),
          size: const Size(34, 34),
        ),
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
      return '부딪힌 공을 붙잡아 멈추게 하는 표면입니다.';
    case EntityType.weight:
      return '무거움 속성을 가진 돌입니다.';
    case EntityType.switchPad:
      return '공이 누르면 반짝이며 문을 여는 장치입니다.';
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
