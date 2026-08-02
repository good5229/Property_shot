import 'dart:math' as math;
import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
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
import 'game_feedback.dart';
import 'play_telemetry.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    this.initialState,
    this.showStageSelector = true,
    this.telemetry,
    this.onExit,
    this.onCopyCoreEarned,
    this.onLevelUnlocked,
  });

  final GameState? initialState;
  final bool showStageSelector;
  final LocalPlayTelemetry? telemetry;
  final VoidCallback? onExit;
  final ValueChanged<int>? onCopyCoreEarned;
  final ValueChanged<int>? onLevelUnlocked;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final _shotResolver = const ShotResolver();
  final _traitResolver = const TraitResolver();
  final _feedback = GameFeedback();
  late final LocalPlayTelemetry _telemetry;
  late GameState _state;
  late PropertyShotGame _game;
  bool _showBallInfo = false;
  String? _inspectedEntityId;
  Timer? _chargeTimer;
  Timer? _pressActivationTimer;
  Offset? _pointerDownPosition;
  int? _activePointer;
  bool _pointerOnBall = false;
  bool _pointerMoved = false;
  bool _isCharging = false;
  bool _isAnimatingShot = false;
  bool _showClearPopup = false;
  bool _showFailurePopup = false;
  String _failureAdvice = '';
  bool _bestShotsLoaded = false;
  Future<void>? _bestShotsLoadFuture;
  final Map<int, int> _bestShots = {};
  int _unlockedLevel = 0;
  late int _stageCopyCoreAtStart;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _telemetry = widget.telemetry ?? LocalPlayTelemetry();
    _state =
        widget.initialState ??
        levels.first
            .createState(0, productRules: true)
            .copyWith(message: _levelIntroMessage(0));
    _stageCopyCoreAtStart = _state.copyCoreCount;
    if (widget.initialState != null) {
      _unlockedLevel = levels.length - 1;
    }
    _game = PropertyShotGame(
      _state,
      onAnimationFinished: _onAnimationFinished,
      onAnimationImpact: _onAnimationImpact,
      onShotImpact: _onShotImpact,
    );
    _showClearPopup = _state.phase == GamePhase.success;
    _bestShotsLoadFuture = _loadBestShots();
    _telemetry.record('단계 시작', stage: _state.levelIndex);
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
    final storedUnlocked = preferences.getInt(_unlockedLevelKey) ?? 0;
    _unlockedLevel = math
        .max(_unlockedLevel, storedUnlocked.clamp(0, levels.length - 1).toInt())
        .toInt();
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

  void _unlockNextLevel(int levelIndex) {
    final next = math.min(levels.length - 1, levelIndex + 1);
    if (next <= _unlockedLevel) {
      return;
    }
    setState(() => _unlockedLevel = next);
    widget.onLevelUnlocked?.call(next);
    unawaited(
      SharedPreferences.getInstance().then(
        (preferences) => preferences.setInt(_unlockedLevelKey, next),
      ),
    );
  }

  void _setState(
    GameState next, {
    List<Vec2> path = const [],
    GameState? transitionStart,
    List<ShotAnimationMove> moves = const [],
    List<ShotImpact> impacts = const [],
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
        impacts: impacts,
        animationTransaction: path.isNotEmpty,
      );
    });
  }

  void _selectLevel(int index) {
    if (_isAnimatingShot || index > _unlockedLevel) {
      return;
    }
    _showBallInfo = false;
    _inspectedEntityId = null;
    _showClearPopup = false;
    _showFailurePopup = false;
    final sameStage = index == _state.levelIndex;
    final availableCores = sameStage
        ? _stageCopyCoreAtStart
        : _state.copyCoreCount;
    final next = levels[index]
        .createState(
          index,
          productRules: !widget.showStageSelector,
          copyCoreCount: availableCores,
          copyCoreRewarded: _state.copyCoreRewarded,
        )
        .copyWith(message: _levelIntroMessage(index));
    _stageCopyCoreAtStart = next.copyCoreCount;
    _setState(next);
    _telemetry.record('단계 시작', stage: index);
  }

  void _goNextLevel() {
    if (_state.levelIndex >= levels.length - 1) {
      _selectLevel(0);
      _setState(_state.copyWith(message: '모든 단계를 완료했습니다. 기록을 다시 도전하세요.'));
      return;
    }
    _unlockNextLevel(_state.levelIndex);
    _selectLevel(_state.levelIndex + 1);
  }

  void _selectTraitSource(String sourceId) {
    _feedback.traitSelected();
    _showBallInfo = false;
    _inspectedEntityId = sourceId;
    final next = _traitResolver.selectSource(_state, sourceId);
    _setState(
      _state.levelIndex == 0
          ? next.copyWith(message: '추천 경로 설명을 읽고 속성 옮기기를 시도해 보세요.')
          : next,
    );
  }

  void _transferTrait() {
    _feedback.traitTransferred();
    _showBallInfo = false;
    _inspectedEntityId = null;
    final next = _traitResolver
        .transferSelectedTrait(_state)
        .copyWith(
          message: _state.levelIndex == 0
              ? '추천 경로를 준비했습니다. 공을 길게 눌렀다 손을 떼면 자동 발사됩니다.'
              : '속성을 공에 담았습니다. 길게 눌러 힘을 모은 뒤 손을 떼면 자동 발사됩니다.',
        );
    _telemetry.record(
      '속성 이전',
      stage: _state.levelIndex,
      trait: next.equippedTrait?.label,
      action: '이전',
    );
    _setState(next);
  }

  void _copyTrait() {
    _feedback.traitCopied();
    _showBallInfo = false;
    _inspectedEntityId = null;
    final next = _traitResolver.copySelectedTrait(_state);
    final remaining = _state.copyCoreCount > 0
        ? '복제 코어 ${next.copyCoreCount}개 남음'
        : '복사 ${next.copyCharges}회 남음';
    _setState(
      next.copyWith(
        message:
            '원본에 속성을 남기고 공에 복사했습니다. $remaining. 길게 눌러 힘을 모은 뒤 손을 떼면 자동 발사됩니다.',
      ),
    );
    _telemetry.record(
      '속성 복사',
      stage: _state.levelIndex,
      trait: next.equippedTrait?.label,
      action: '복제 코어',
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
    _telemetry.record(
      '발사',
      stage: _state.levelIndex,
      attempt: _state.shotCount + 1,
      angle: math.atan2(_state.aimDirection.y, _state.aimDirection.x),
      power: _state.aimPower,
      trait: _state.equippedTrait?.label,
    );
    _feedback.shotLaunched();
    _showBallInfo = false;
    _inspectedEntityId = null;
    _showFailurePopup = false;
    _failureAdvice = _failureAdviceFor(result.events);
    _isAnimatingShot = true;
    _setState(
      result.state,
      path: result.path,
      transitionStart: _state,
      moves: result.moves,
      impacts: result.impacts,
    );
    if (result.state.phase == GamePhase.success) {
      _unlockNextLevel(result.state.levelIndex);
      unawaited(
        _recordBestShot(result.state.levelIndex, result.state.shotCount),
      );
    }
  }

  void _onAnimationFinished() {
    if (!mounted || !_isAnimatingShot) {
      return;
    }
    final cleared = _state.phase == GamePhase.success;
    if (cleared &&
        !widget.showStageSelector &&
        !_state.copyCoreRewarded &&
        levels[_state.levelIndex].copyCoreReward > 0) {
      final reward = levels[_state.levelIndex].copyCoreReward;
      _state = _state.copyWith(
        copyCharges: _state.copyCharges + reward,
        copyChargeLimit: _state.copyChargeLimit + reward,
        copyCoreCount: _state.copyCoreCount + reward,
        copyCoreRewarded: true,
        message: '섬의 보상으로 복제 코어 $reward개를 얻었습니다.',
      );
      _stageCopyCoreAtStart = _state.copyCoreCount;
      widget.onCopyCoreEarned?.call(reward);
    }
    setState(() {
      _isAnimatingShot = false;
      _showClearPopup = cleared;
      _showFailurePopup = !cleared;
    });
    if (cleared) {
      _telemetry.record(
        '클리어',
        stage: _state.levelIndex,
        attempt: _state.shotCount,
        result: '성공',
      );
      _feedback.shotCleared();
    } else {
      _telemetry.record(
        '실패',
        stage: _state.levelIndex,
        attempt: _state.shotCount,
        result: '재도전 가능',
      );
      _feedback.shotFailed();
    }
  }

  void _onAnimationImpact(ShotAnimationMove move) {
    if (!mounted || !_isAnimatingShot || move.visualState == 'opening') {
      return;
    }
    if (move.visualState == 'pressed') {
      _feedback.switchOpened();
    }
    _telemetry.record(
      '연쇄 이동',
      stage: _state.levelIndex,
      target: move.entityId,
      result: move.visualState,
    );
  }

  void _onShotImpact(ShotImpact impact) {
    if (!mounted || !_isAnimatingShot) {
      return;
    }
    _feedback.collision(impact.entityType);
    _telemetry.record(
      '충돌',
      stage: _state.levelIndex,
      target: impact.entityType.name,
    );
  }

  void _rewind() {
    if (_isAnimatingShot) {
      return;
    }
    _showFailurePopup = false;
    _telemetry.record('되감기', stage: _state.levelIndex);
    _setState(_shotResolver.rewind(_state));
  }

  void _togglePause() {
    if (_isAnimatingShot) {
      return;
    }
    if (_state.phase == GamePhase.paused) {
      _feedback.paused(false);
      _setState(
        _state.copyWith(phase: GamePhase.planning, message: '계획을 계속하세요.'),
      );
    } else if (_state.phase == GamePhase.planning) {
      _feedback.paused(true);
      _setState(_state.copyWith(phase: GamePhase.paused, message: '일시정지'));
    }
  }

  void _updateAim(Offset localPosition, Size fieldSize) {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
      return;
    }
    final logical = _toLogicalPosition(localPosition, fieldSize);
    final aim = logical - _state.activeBall.position;
    _setState(
      _state.copyWith(
        aimDirection: aim.normalized(),
        message: '방향 설정 완료 · 공을 길게 눌러 힘을 모으세요',
      ),
    );
  }

  void _nudgeAim(double radians) {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
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

  void _adjustPower(double delta) {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
      return;
    }
    final nextPower = (_state.aimPower + delta).clamp(0.12, 1.0);
    _setState(
      _state.copyWith(
        aimPower: nextPower,
        message: '힘 ${(nextPower * 100).round()}%',
      ),
    );
  }

  void _handleSemanticEntity(String entityId) {
    if (_isAnimatingShot) {
      return;
    }
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
      EntityType.wall => '움직이지 않는 장애물',
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

  void _handleSystemBack() {
    if (_showBallInfo || _inspectedEntityId != null) {
      _dismissInfo();
      return;
    }
    if (_showClearPopup) {
      _showClearPopup = false;
      _setState(
        _state.copyWith(phase: GamePhase.planning, message: '다시 조준할 수 있습니다.'),
      );
      return;
    }
    if (_showFailurePopup) {
      setState(() {
        _showFailurePopup = false;
      });
    }
  }

  void _handleFieldTap(Offset localPosition, Size fieldSize) {
    if (_isAnimatingShot) {
      return;
    }
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

  void _handlePointerDown(int pointer, Offset localPosition, Size fieldSize) {
    if (_state.phase != GamePhase.planning || _isAnimatingShot) {
      return;
    }
    if (_activePointer != null) {
      return;
    }
    _activePointer = pointer;
    _pressActivationTimer?.cancel();
    _pointerDownPosition = localPosition;
    _pointerMoved = false;
    final logical = _toLogicalPosition(localPosition, fieldSize);
    _pointerOnBall = logical.distanceTo(_state.activeBall.position) <= 42;
    if (_pointerOnBall) {
      _setState(_state.copyWith(message: '공을 길게 눌러 힘을 모으세요'));
      _pressActivationTimer = Timer(const Duration(milliseconds: 450), () {
        if (!mounted || _pointerDownPosition == null || !_pointerOnBall) {
          return;
        }
        _startPowerCharge(_pointerDownPosition!, fieldSize);
      });
    }
  }

  void _handlePointerMove(int pointer, Offset localPosition, Size fieldSize) {
    if (pointer != _activePointer) {
      return;
    }
    final down = _pointerDownPosition;
    if (down == null || _isAnimatingShot) {
      return;
    }
    if ((down - localPosition).distance >= 8) {
      _pointerMoved = true;
      if (_pointerOnBall) {
        _pointerOnBall = false;
        _pressActivationTimer?.cancel();
        _pressActivationTimer = null;
      }
      _updateAim(localPosition, fieldSize);
    }
  }

  void _handlePointerUp(int pointer, Offset localPosition, Size fieldSize) {
    if (pointer != _activePointer) {
      return;
    }
    final down = _pointerDownPosition;
    final wasCharging = _isCharging;
    _pressActivationTimer?.cancel();
    _pressActivationTimer = null;
    _pointerDownPosition = null;
    _activePointer = null;
    _pointerOnBall = false;
    if (wasCharging) {
      _stopPowerCharge();
      _pointerMoved = false;
      return;
    }
    if (down != null && !_pointerMoved) {
      _handleFieldTap(localPosition, fieldSize);
    } else if (_state.phase == GamePhase.planning && !_isAnimatingShot) {
      _setState(_state.copyWith(message: '조준 고정'));
    }
    _pointerMoved = false;
  }

  void _handlePointerCancel({bool showCancellation = true, int? pointer}) {
    if (pointer != null && pointer != _activePointer) {
      return;
    }
    final hadPointer = _pointerDownPosition != null;
    _pressActivationTimer?.cancel();
    _pressActivationTimer = null;
    _pointerDownPosition = null;
    _activePointer = null;
    _pointerOnBall = false;
    _pointerMoved = false;
    if (_isCharging) {
      _cancelPowerCharge(showMessage: showCancellation);
    } else if (hadPointer &&
        showCancellation &&
        _state.phase == GamePhase.planning) {
      _setState(_state.copyWith(message: '발사를 취소했습니다'));
    }
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
    _setState(
      _state.copyWith(aimPower: 0.12, message: '힘 모으는 중 · 손을 떼면 발사됩니다'),
    );
    _chargeTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) {
        return;
      }
      final nextPower = (_state.aimPower + 0.055).clamp(0.12, 1.0);
      _setState(
        _state.copyWith(
          aimPower: nextPower,
          message: '힘 ${(nextPower * 100).round()}% · 손을 떼면 발사됩니다',
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

  void _cancelPowerCharge({bool showMessage = true}) {
    _isCharging = false;
    _chargeTimer?.cancel();
    _chargeTimer = null;
    _pressActivationTimer?.cancel();
    _pressActivationTimer = null;
    if (showMessage) {
      _feedback.cancelled();
    }
    if (mounted && showMessage && _state.phase == GamePhase.planning) {
      _setState(_state.copyWith(message: '발사를 취소했습니다'));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _handlePointerCancel(showCancellation: false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _chargeTimer?.cancel();
    _pressActivationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inspectedEntity = _inspectedEntityId == null
        ? null
        : _state.entityById(_inspectedEntityId!);
    final screenSize = MediaQuery.sizeOf(context);
    final compactLayout = screenSize.width <= 800;
    final contentWidth = compactLayout
        ? screenSize.width
        : math.min(screenSize.width * 0.78, 760.0);
    final clearPopupOpen = _state.phase == GamePhase.success && _showClearPopup;
    final failurePopupOpen =
        _showFailurePopup && !_showBallInfo && inspectedEntity == null;
    final popupOpen =
        _showBallInfo ||
        inspectedEntity != null ||
        failurePopupOpen ||
        clearPopupOpen;
    final inputBlocked = popupOpen || _isAnimatingShot;
    return PopScope<void>(
      canPop: !popupOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && popupOpen) {
          _handleSystemBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFBFE8E3),
        appBar: widget.showStageSelector
            ? AppBar(
                title: const Text('속성 한방'),
                backgroundColor: const Color(0xFF24352D),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    key: const Key('pause_button'),
                    tooltip: _state.phase == GamePhase.paused ? '계속' : '멈춤',
                    onPressed: _togglePause,
                    icon: Icon(
                      _state.phase == GamePhase.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                    ),
                  ),
                ],
              )
            : null,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: _GameplayBackdrop()),
              AbsorbPointer(
                absorbing: inputBlocked,
                child: ExcludeSemantics(
                  excluding: inputBlocked,
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      height: math.max(
                        0,
                        screenSize.height -
                            (widget.showStageSelector ? kToolbarHeight : 0),
                      ),
                      child: Column(
                        children: [
                          if (!compactLayout)
                            _Hud(
                              state: _state,
                              unlockedLevel: _unlockedLevel,
                              onSelectLevel: _selectLevel,
                              showStageSelector: widget.showStageSelector,
                              onPause: _togglePause,
                              onExit: widget.onExit,
                            ),
                          if (compactLayout)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                              child: _Hud(
                                compact: true,
                                state: _state,
                                unlockedLevel: _unlockedLevel,
                                onSelectLevel: _selectLevel,
                                showStageSelector: widget.showStageSelector,
                                onPause: _togglePause,
                                onExit: widget.onExit,
                              ),
                            ),
                          Expanded(
                            child: AbsorbPointer(
                              absorbing: inputBlocked,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compactLayout ? 0 : 12,
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final semanticLaunch =
                                        CustomSemanticsAction(label: '공 발사');
                                    final semanticAimRight =
                                        CustomSemanticsAction(
                                          label: '오른쪽으로 조준',
                                        );
                                    final semanticAimLeft =
                                        CustomSemanticsAction(label: '왼쪽으로 조준');
                                    final semanticAimUp = CustomSemanticsAction(
                                      label: '위쪽으로 조준',
                                    );
                                    final semanticAimDown =
                                        CustomSemanticsAction(
                                          label: '아래쪽으로 조준',
                                        );
                                    final fieldSize = constraints.biggest;
                                    final scale = math.min(
                                      fieldSize.width / logicalSize.x,
                                      fieldSize.height / logicalSize.y,
                                    );
                                    final boardSize = Size(
                                      logicalSize.x * scale,
                                      logicalSize.y * scale,
                                    );
                                    return Align(
                                      alignment: Alignment.topCenter,
                                      child: SizedBox(
                                        width: boardSize.width,
                                        height: boardSize.height,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            Positioned(
                                              left: 0,
                                              top: 0,
                                              width: boardSize.width,
                                              height: boardSize.height,
                                              child: Listener(
                                                key: const Key('aim_area'),
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onPointerDown: (event) =>
                                                    _handlePointerDown(
                                                      event.pointer,
                                                      event.localPosition,
                                                      boardSize,
                                                    ),
                                                onPointerMove: (event) =>
                                                    _handlePointerMove(
                                                      event.pointer,
                                                      event.localPosition,
                                                      boardSize,
                                                    ),
                                                onPointerUp: (event) =>
                                                    _handlePointerUp(
                                                      event.pointer,
                                                      event.localPosition,
                                                      boardSize,
                                                    ),
                                                onPointerCancel: (event) =>
                                                    _handlePointerCancel(
                                                      pointer: event.pointer,
                                                    ),
                                                child: Semantics(
                                                  container: true,
                                                  label: '공을 조준하는 게임 화면',
                                                  value:
                                                      '힘 ${(_state.aimPower * 100).round()}퍼센트',
                                                  increasedValue:
                                                      '힘 ${((_state.aimPower + 0.055).clamp(0.0, 1.0) * 100).round()}퍼센트',
                                                  decreasedValue:
                                                      '힘 ${((_state.aimPower - 0.055).clamp(0.0, 1.0) * 100).round()}퍼센트',
                                                  hint:
                                                      '증감 동작은 힘을 조절하고, 사용자 지정 동작으로 방향을 조절하세요',
                                                  onIncrease: () =>
                                                      _adjustPower(0.055),
                                                  onDecrease: () =>
                                                      _adjustPower(-0.055),
                                                  customSemanticsActions: {
                                                    semanticLaunch: _launch,
                                                    semanticAimRight: () =>
                                                        _nudgeAim(math.pi / 18),
                                                    semanticAimLeft: () =>
                                                        _nudgeAim(
                                                          -math.pi / 18,
                                                        ),
                                                    semanticAimUp: () =>
                                                        _nudgeAim(
                                                          -math.pi / 18,
                                                        ),
                                                    semanticAimDown: () =>
                                                        _nudgeAim(math.pi / 18),
                                                  },
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    child: GameWidget(
                                                      game: _game,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            for (final entity
                                                in _state.entities)
                                              if (entity.active)
                                                Positioned(
                                                  left:
                                                      (entity.position.x -
                                                          entity.size.x / 2) *
                                                      scale,
                                                  top:
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
                                                    button: true,
                                                    label: _semanticEntityLabel(
                                                      entity,
                                                    ),
                                                    hint:
                                                        entity.traits.isNotEmpty
                                                        ? '선택하면 속성 정보를 확인할 수 있습니다'
                                                        : '선택하면 물체 정보를 확인할 수 있습니다',
                                                    onTap: () =>
                                                        _handleSemanticEntity(
                                                          entity.id,
                                                        ),
                                                    child:
                                                        const SizedBox.expand(),
                                                  ),
                                                ),
                                            if (compactLayout)
                                              Positioned(
                                                left: 6,
                                                right: 6,
                                                bottom: 6,
                                                child: _ControlPanel(
                                                  compact: true,
                                                  state: _state,
                                                  onRewind: _rewind,
                                                  onReset: () => _selectLevel(
                                                    _state.levelIndex,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (!compactLayout)
                            _ControlPanel(
                              state: _state,
                              onRewind: _rewind,
                              onReset: () => _selectLevel(_state.levelIndex),
                            ),
                        ],
                      ),
                    ),
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
                    copyCharges: _state.copyCharges,
                    copyCoreCount: _state.copyCoreCount,
                    onTransfer: inspectedEntity.traits.isEmpty
                        ? null
                        : _transferTrait,
                    onCopy:
                        inspectedEntity.traits.isEmpty ||
                            _state.copyCharges <= 0
                        ? null
                        : _copyTrait,
                  ),
                ),
              if (failurePopupOpen)
                _FailurePopup(
                  state: _state,
                  advice: _failureAdvice,
                  onRetry: () => setState(() => _showFailurePopup = false),
                  onRewind: _rewind,
                  onReset: () {
                    _showFailurePopup = false;
                    _selectLevel(_state.levelIndex);
                  },
                ),
              if (clearPopupOpen)
                _ClearPopup(
                  state: _state,
                  bestShot: _bestShots[_state.levelIndex],
                  onNext: _goNextLevel,
                  onRetry: () => _selectLevel(_state.levelIndex),
                  isFinal: _state.levelIndex >= levels.length - 1,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameplayBackdrop extends StatelessWidget {
  const _GameplayBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GameplayBackdropPainter());
  }
}

class _GameplayBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFBFE8E3),
    );

    final sand = Paint()..color = const Color(0xFFF6D995);
    final shore = Path()
      ..moveTo(-20, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.72,
        size.width * 0.58,
        size.height * 0.81,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.9,
        size.width + 20,
        size.height * 0.76,
      )
      ..lineTo(size.width + 20, size.height + 20)
      ..lineTo(-20, size.height + 20)
      ..close();
    canvas.drawPath(shore, sand);

    final shoreEdge = Path()
      ..moveTo(-20, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.72,
        size.width * 0.58,
        size.height * 0.81,
      )
      ..quadraticBezierTo(
        size.width * 0.84,
        size.height * 0.9,
        size.width + 20,
        size.height * 0.76,
      );
    canvas.drawPath(
      shoreEdge,
      Paint()
        ..color = const Color(0x559E743B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );

    final sandTexture = Paint()
      ..color = const Color(0x1F9E743B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var index = 0; index < 4; index++) {
      final y = size.height * (0.84 + index * 0.045);
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.08, y, size.width * 0.18, 10),
        math.pi * 0.12,
        math.pi * 0.72,
        false,
        sandTexture,
      );
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.68, y + 5, size.width * 0.2, 10),
        math.pi * 0.12,
        math.pi * 0.72,
        false,
        sandTexture,
      );
    }

    final wave = Paint()
      ..color = const Color(0x664EAAA5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var index = 0; index < 3; index++) {
      final y = size.height * (0.08 + index * 0.09);
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.04, y, size.width * 0.18, 12),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
      canvas.drawArc(
        Rect.fromLTWH(size.width * 0.78, y + 16, size.width * 0.18, 12),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        wave,
      );
    }

    final shell = Paint()
      ..color = const Color(0x99EF765E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (final point in [
      Offset(size.width * 0.12, size.height * 0.9),
      Offset(size.width * 0.82, size.height * 0.93),
      Offset(size.width * 0.68, size.height * 0.86),
    ]) {
      canvas.drawArc(
        Rect.fromCenter(center: point, width: 16, height: 10),
        math.pi,
        math.pi,
        false,
        shell,
      );
      for (var ray = -1; ray <= 1; ray++) {
        canvas.drawLine(
          point.translate(ray * 3.5, 0),
          point.translate(ray * 2.2, -4),
          shell,
        );
      }
    }

    _drawTidePool(canvas, size);
    _drawBeachLeaves(canvas, size);
    _drawStarfish(canvas, size);
  }

  void _drawTidePool(Canvas canvas, Size size) {
    final pool = Rect.fromLTWH(
      size.width * 0.68,
      size.height * 0.865,
      size.width * 0.22,
      size.height * 0.058,
    );
    canvas.drawOval(pool, Paint()..color = const Color(0x6685CEC7));
    canvas.drawArc(
      pool.deflate(4),
      math.pi * 1.05,
      math.pi * 0.9,
      false,
      Paint()
        ..color = const Color(0x779EE3D9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final glint = Paint()..color = const Color(0x88FFFFFF);
    canvas.drawOval(
      Rect.fromLTWH(
        pool.left + pool.width * 0.2,
        pool.top + pool.height * 0.28,
        pool.width * 0.18,
        2.5,
      ),
      glint,
    );
    canvas.drawOval(
      Rect.fromLTWH(
        pool.left + pool.width * 0.58,
        pool.top + pool.height * 0.58,
        pool.width * 0.12,
        2,
      ),
      glint,
    );
  }

  void _drawBeachLeaves(Canvas canvas, Size size) {
    final base = Offset(size.width * 0.15, size.height * 0.91);
    canvas.drawOval(
      Rect.fromCenter(
        center: base.translate(0, 5),
        width: size.width * 0.15,
        height: 7,
      ),
      Paint()..color = const Color(0x223B5F48),
    );
    final leaf = Paint()..color = const Color(0xAA62A86B);
    final vein = Paint()
      ..color = const Color(0x66507F5B)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final entry in const [
      (angle: -2.15, width: 18.0, height: 7.0),
      (angle: -1.42, width: 21.0, height: 8.0),
      (angle: -0.78, width: 16.0, height: 7.0),
    ]) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(entry.angle);
      final leafRect = Rect.fromCenter(
        center: Offset(entry.width * 0.34, 0),
        width: entry.width,
        height: entry.height,
      );
      canvas.drawOval(leafRect, leaf);
      canvas.drawLine(Offset.zero, Offset(entry.width * 0.66, 0), vein);
      canvas.restore();
    }
  }

  void _drawStarfish(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.48, size.height * 0.935);
    final path = Path();
    for (var index = 0; index < 10; index++) {
      final radius = index.isEven ? 9.0 : 3.8;
      final angle = -math.pi / 2 + index * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xB5EF765E));
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x558C5544)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    final dot = Paint()..color = const Color(0x99FFE4A5);
    canvas.drawCircle(center.translate(0, -1), 1.4, dot);
    canvas.drawCircle(center.translate(-3, 3), 1, dot);
    canvas.drawCircle(center.translate(3, 3), 1, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClearPopup extends StatelessWidget {
  const _ClearPopup({
    required this.state,
    required this.onNext,
    required this.onRetry,
    required this.isFinal,
    this.bestShot,
  });

  final GameState state;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final bool isFinal;
  final int? bestShot;

  @override
  Widget build(BuildContext context) {
    final rows = _leaderboardRows(state);
    final level = levels[state.levelIndex];
    final stars = _starsForShot(state.shotCount, level.parShots);
    return FocusScope(
      autofocus: true,
      child: Semantics(
        container: true,
        namesRoute: true,
        label: '클리어 결과 팝업',
        child: Container(
          key: const Key('clear_popup'),
          color: const Color(0x88000000),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final panelHeight = math
                    .min(540.0, math.max(1, constraints.maxHeight - 48))
                    .toDouble();
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.96, end: 1),
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: SizedBox(
                          width: double.infinity,
                          height: panelHeight,
                          child: Container(
                            key: const Key('clear_panel'),
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
                              children: [
                                Expanded(
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      18,
                                      18,
                                      8,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '클리어!',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.headlineSmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text('${state.shotCount}번 만에 성공'),
                                        const SizedBox(height: 8),
                                        Row(
                                          key: const Key('clear_stars'),
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            for (
                                              var index = 0;
                                              index < 3;
                                              index++
                                            )
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 2,
                                                    ),
                                                child: Icon(
                                                  index < stars
                                                      ? Icons.star_rounded
                                                      : Icons
                                                            .star_border_rounded,
                                                  color: index < stars
                                                      ? const Color(0xFFF0AE34)
                                                      : const Color(0xFFB7B6A9),
                                                  size: 32,
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          '파 ${level.parShots}회 · $stars/3 별',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: const Color(0xFF6A5947),
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          level.bonusGoal,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: const Color(0xFF5D6657),
                                              ),
                                        ),
                                        if (!isFinal) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            '${state.levelIndex + 2}단계가 열렸습니다.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: const Color(
                                                    0xFF236B4A,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                        if (bestShot != null) ...[
                                          const SizedBox(height: 4),
                                          Text('내 최고 기록 $bestShot회'),
                                        ],
                                        const SizedBox(height: 14),
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(
                                              alpha: 0.74,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE4C56A),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text('예시 기록 · 온라인 순위 아님'),
                                              const SizedBox(height: 2),
                                              Text(
                                                '현재는 데모용 기록만 표시합니다.',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                              const SizedBox(height: 8),
                                              for (
                                                var i = 0;
                                                i < rows.length;
                                                i++
                                              )
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 3,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 28,
                                                        child: Text(
                                                          '${i + 1}위',
                                                        ),
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          rows[i].name,
                                                        ),
                                                      ),
                                                      Text('${rows[i].shots}회'),
                                                    ],
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    18,
                                    0,
                                    18,
                                    18,
                                  ),
                                  child: Column(
                                    children: [
                                      FilledButton.icon(
                                        key: const Key('next_stage_button'),
                                        autofocus: true,
                                        onPressed: onNext,
                                        icon: const Icon(Icons.arrow_forward),
                                        label: Text(isFinal ? '처음부터 다시' : '다음'),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        key: const Key('retry_stage_button'),
                                        onPressed: onRetry,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('기록 다시 도전'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FailurePopup extends StatelessWidget {
  const _FailurePopup({
    required this.state,
    required this.advice,
    required this.onRetry,
    required this.onRewind,
    required this.onReset,
  });

  final GameState state;
  final String advice;
  final VoidCallback onRetry;
  final VoidCallback onRewind;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      autofocus: true,
      child: Semantics(
        container: true,
        namesRoute: true,
        label: '발사 실패 결과 팝업',
        child: Container(
          key: const Key('failure_popup'),
          color: const Color(0x55000000),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 132),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(context).height - 150,
              ),
              child: Material(
                color: const Color(0xFFF7FAF3),
                borderRadius: BorderRadius.circular(14),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.sports_golf,
                            color: Color(0xFFB34B36),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '이번 발사 결과',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text('${state.shotCount}회'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(state.message),
                      const SizedBox(height: 2),
                      Text(
                        advice,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF46584E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          FilledButton.icon(
                            key: const Key('failure_retry_button'),
                            autofocus: true,
                            onPressed: onRetry,
                            icon: const Icon(Icons.ads_click, size: 16),
                            label: const Text('다시 조준'),
                          ),
                          OutlinedButton.icon(
                            key: const Key('failure_rewind_button'),
                            onPressed: onRewind,
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('되감기'),
                          ),
                          TextButton.icon(
                            key: const Key('failure_reset_button'),
                            onPressed: onReset,
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('단계 처음부터'),
                          ),
                        ],
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

const _unlockedLevelKey = 'unlocked_level';

String _levelObjective(int levelIndex) {
  return switch (levelIndex) {
    0 => '추천: 무거움을 옮겨 상자를 밀어 보세요. 다른 충돌 경로도 홀에 닿으면 성공합니다.',
    1 => '추천: 탄성을 옮겨 벽에 반사시켜 보세요. 다른 각도와 경로도 시도할 수 있습니다.',
    _ => '추천: 무거움으로 스위치를 눌러 문을 열어 보세요. 점착은 공을 고정하는 선택지입니다.',
  };
}

String _compactLevelObjective(int levelIndex) {
  return switch (levelIndex) {
    0 => '무거움으로 상자를 밀어 홀로 보내기',
    1 => '탄성으로 벽에 반사해 홀로 보내기',
    _ => '스위치와 문을 열어 홀로 가기',
  };
}

int _starsForShot(int shotCount, int parShots) {
  if (shotCount <= parShots) {
    return 3;
  }
  if (shotCount <= parShots + 2) {
    return 2;
  }
  return 1;
}

String? _levelProgressHint(GameState state) {
  if (state.levelIndex != 2) {
    return null;
  }
  final hasAnchor = state.entities.any(
    (entity) =>
        entity.type == EntityType.ball &&
        entity.visualState == 'stuck' &&
        !entity.movable,
  );
  if (!hasAnchor) {
    return '추천 경로: 무거움으로 스위치를 누르는 길을 살펴보세요. 점착은 공을 고정합니다.';
  }
  final hasHeavy = state.activeBall.traits.contains(TraitType.heavy);
  if (!hasHeavy) {
    return '점착 공이 고정되었습니다. 다음 공에 무거움을 옮기거나 다른 길을 찾아보세요.';
  }
  return '무거운 공으로 스위치를 누르고 열린 문을 지나 홀로 가 보세요.';
}

String? _compactLevelProgressHint(GameState state) {
  if (state.levelIndex != 2) {
    return null;
  }
  final hasAnchor = state.entities.any(
    (entity) =>
        entity.type == EntityType.ball &&
        entity.visualState == 'stuck' &&
        !entity.movable,
  );
  if (!hasAnchor) {
    return '무거움은 스위치 · 점착은 공 고정';
  }
  final hasHeavy = state.activeBall.traits.contains(TraitType.heavy);
  if (!hasHeavy) {
    return '고정한 공을 발판으로 무거움 옮기기';
  }
  return '무거운 공으로 스위치 → 열린 문 → 홀';
}

String _levelIntroMessage(int levelIndex) {
  return switch (levelIndex) {
    0 => '상자를 밀어 홀로 → 방향 조정 · 길게 누르기 · 손 떼기',
    1 => '첫 반사면 찾기 → 방향 조정 · 길게 누르기 · 손 떼기',
    _ => '스위치와 문 살피기 → 여러 경로로 도전',
  };
}

String _failureAdviceFor(List<String> events) {
  if (events.contains('hole_rejected_trait')) {
    return '홀에 닿지 못했어요. 속성을 활용하거나 다른 각도와 충돌 경로를 시도해 보세요.';
  }
  if (events.contains('hole_rejected_crate')) {
    return '홀에 닿지 못했어요. 상자와의 충돌을 활용하거나 다른 경로를 시도해 보세요.';
  }
  if (events.contains('crate_blocked')) {
    return '상자가 움직이지 않았습니다. 더 강한 힘이나 다른 면을 노려 보세요.';
  }
  if (events.contains('power_low')) {
    return '힘이 부족했어요. 공 주변 게이지를 조금 더 채워 다시 시도해 보세요.';
  }
  if (events.contains('power_high')) {
    return '힘이 너무 셌어요. 게이지를 한 칸 낮추고 충돌 면을 바꿔 보세요.';
  }
  if (events.contains('switch_rejected_sticky')) {
    return '점착판 없이도 다른 경로를 시도할 수 있어요. 스위치는 무거운 공에 반응합니다.';
  }
  if (events.contains('switch_rejected')) {
    return '스위치에는 무거움이 필요합니다. 속성을 다시 확인하세요.';
  }
  if (events.contains('sticky_attached')) {
    return '붙은 공을 다음 충돌의 발판으로 활용해 보세요.';
  }
  if (events.contains('crate_pushed')) {
    return '상자의 이동 방향을 보고 다음 각도를 조금 바꿔 보세요.';
  }
  if (events.any(
    (event) => event == 'bounced' || event.startsWith('chain_collision_'),
  )) {
    return '맞은 면이 달라지면 반사 방향도 달라집니다. 조준점을 조금 옮겨 보세요.';
  }
  if (events.contains('momentum_transfer')) {
    return '남은 공도 다음 발사의 충돌 재료로 활용할 수 있습니다.';
  }
  return '남은 공의 위치를 살펴보고 힘과 방향을 다시 정해 보세요.';
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
      _LeaderboardRow('돌돌이', 6),
    ],
  };
  final rows = [...base, _LeaderboardRow('나', state.shotCount)]
    ..sort((a, b) => a.shots.compareTo(b.shots));
  return rows.take(4).toList();
}

class _Hud extends StatelessWidget {
  const _Hud({
    this.compact = false,
    required this.state,
    required this.unlockedLevel,
    required this.onSelectLevel,
    this.showStageSelector = true,
    required this.onPause,
    this.onExit,
  });

  final bool compact;
  final GameState state;
  final int unlockedLevel;
  final ValueChanged<int> onSelectLevel;
  final bool showStageSelector;
  final VoidCallback onPause;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    final progressHint = _levelProgressHint(state);
    final compactProgressHint = _compactLevelProgressHint(state);
    if (compact) {
      return Container(
        key: const Key('compact_hud'),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: const Color(0xE6F7FAF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xAA708278)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.levelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text('시도 ${state.shotCount}'),
                const SizedBox(width: 6),
                Text('점수 ${state.score}'),
                if (!showStageSelector && onExit != null)
                  IconButton(
                    key: const Key('home_button'),
                    tooltip: '섬 지도',
                    onPressed: onExit,
                    icon: const Icon(Icons.map_outlined),
                    visualDensity: VisualDensity.compact,
                  ),
                if (!showStageSelector)
                  IconButton(
                    key: const Key('pause_button'),
                    tooltip: state.phase == GamePhase.paused ? '계속' : '멈춤',
                    onPressed: onPause,
                    icon: Icon(
                      state.phase == GamePhase.paused
                          ? Icons.play_arrow
                          : Icons.pause,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 2),
            if (showStageSelector)
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < levels.length; i++)
                      Semantics(
                        label: i <= unlockedLevel
                            ? '${i + 1}단계 선택'
                            : '${i + 1}단계 잠김. ${unlockedLevel + 1}단계 클리어 후 열림',
                        button: i <= unlockedLevel,
                        selected: state.levelIndex == i,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: ChoiceChip(
                            key: Key('level_$i'),
                            label: Text('${i + 1}'),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            selected: state.levelIndex == i,
                            onSelected: i <= unlockedLevel
                                ? (_) => onSelectLevel(i)
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Text(
              _compactLevelObjective(state.levelIndex),
              key: const Key('compact_objective'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF46584E),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (compactProgressHint != null)
              Text(
                compactProgressHint,
                key: const Key('level_progress'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF2F8A62),
                  fontWeight: FontWeight.w700,
                ),
              ),
            Semantics(
              liveRegion: true,
              label: '게임 안내: ${state.message}',
              child: Text(
                state.message,
                key: const Key('compact_message'),
                maxLines: 2,
                softWrap: true,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }
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
              Text('시도 ${state.shotCount}'),
              const SizedBox(width: 12),
              Text('점수 ${state.score}'),
              if (!showStageSelector && onExit != null)
                IconButton(
                  key: const Key('home_button'),
                  tooltip: '섬 지도',
                  onPressed: onExit,
                  icon: const Icon(Icons.map_outlined),
                  visualDensity: VisualDensity.compact,
                ),
              if (!showStageSelector)
                IconButton(
                  key: const Key('pause_button'),
                  tooltip: state.phase == GamePhase.paused ? '계속' : '멈춤',
                  onPressed: onPause,
                  icon: Icon(
                    state.phase == GamePhase.paused
                        ? Icons.play_arrow
                        : Icons.pause,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
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
          const _AimInstruction(),
          if (progressHint != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                progressHint,
                key: const Key('level_progress'),
                softWrap: true,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF2F8A62),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (showStageSelector)
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < levels.length; i++)
                        Semantics(
                          label: i <= unlockedLevel
                              ? '${i + 1}단계 선택'
                              : '${i + 1}단계 잠김. ${unlockedLevel + 1}단계 클리어 후 열림',
                          button: i <= unlockedLevel,
                          selected: state.levelIndex == i,
                          child: ChoiceChip(
                            key: Key('level_$i'),
                            label: Text('${i + 1}'),
                            selected: state.levelIndex == i,
                            onSelected: i <= unlockedLevel
                                ? (_) => onSelectLevel(i)
                                : null,
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

class _AimInstruction extends StatelessWidget {
  const _AimInstruction();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF2F6F57),
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.touch_app, size: 16, color: const Color(0xFF2F6F57)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '손가락을 움직여 조준하고, 공을 0.45초 이상 누른 뒤 손을 떼세요.',
              key: const Key('aim_instruction'),
              softWrap: true,
              style: style,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    this.compact = false,
    required this.state,
    required this.onRewind,
    required this.onReset,
  });

  final bool compact;
  final GameState state;
  final VoidCallback onRewind;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        key: const Key('compact_control_panel'),
        padding: const EdgeInsets.fromLTRB(8, 4, 4, 4),
        decoration: BoxDecoration(
          color: const Color(0xE6F7FAF3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xAA708278)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                state.selectedTrait == null
                    ? '물체를 눌러 속성을 고르세요'
                    : '선택: ${state.selectedTrait!.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            Text(
              '공: ${state.equippedTrait?.label ?? '없음'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            IconButton(
              key: const Key('rewind_button'),
              tooltip: '되감기',
              visualDensity: VisualDensity.compact,
              onPressed: onRewind,
              icon: const Icon(Icons.undo, size: 20),
            ),
            IconButton(
              key: const Key('reset_button'),
              tooltip: '다시',
              visualDensity: VisualDensity.compact,
              onPressed: onReset,
              icon: const Icon(Icons.refresh, size: 20),
            ),
          ],
        ),
      );
    }
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
      child: FocusScope(
        autofocus: true,
        child: Stack(
          children: [
            const ModalBarrier(
              color: Color(0x22000000),
              dismissible: false,
              semanticsLabel: '정보 팝업이 열려 있습니다',
            ),
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
                              autofocus: true,
                              tooltip: '닫기',
                              onPressed: onClose,
                              icon: const Icon(Icons.close, size: 18),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFF24352D),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(48, 48),
                                tapTargetSize: MaterialTapTargetSize.padded,
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
      ),
    );
  }
}

class _EntityInfoPanel extends StatelessWidget {
  const _EntityInfoPanel({
    required this.entity,
    required this.copyCharges,
    required this.copyCoreCount,
    this.onTransfer,
    this.onCopy,
  });

  final EntityState entity;
  final int copyCharges;
  final int copyCoreCount;
  final VoidCallback? onTransfer;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final trait = entity.traits.isEmpty ? null : entity.traits.first;
    final hasCopyCore = copyCoreCount > 0;
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
                  if (copyCharges > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      hasCopyCore
                          ? '옮기기: 원본에서 사라짐 · 복제 코어: 원본에 유지됨'
                          : '옮기기: 원본에서 사라짐 · 복사: 원본에 유지됨',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF59685F),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasCopyCore
                          ? '복제 코어 $copyCoreCount개 남음'
                          : '복사 $copyCharges회 남음',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF59685F),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
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
                          label: const Text('떼어 공에 옮기기'),
                          style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      if (copyCharges > 0)
                        Semantics(
                          label: hasCopyCore
                              ? '선택한 ${trait.label} 속성을 복제 코어로 공에 복사하기'
                              : '선택한 ${trait.label} 속성을 원본에 남기고 공으로 복사하기',
                          button: true,
                          child: OutlinedButton.icon(
                            key: const Key('copy_button'),
                            onPressed: onCopy,
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text(
                              hasCopyCore ? '복제 코어로 공에 담기' : '원본에 남기고 공에 복사하기',
                            ),
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
    EntityType.crate => 'assets/generated/crate-v2.png',
    EntityType.weight => 'assets/generated/stone-v2.png',
    EntityType.bumper => 'assets/generated/jelly-bumper-v1.png',
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
      return '다음 발사와 충돌할 수 있는 공입니다.';
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
      return '무거운 공만 누를 수 있습니다. 누르면 반짝이며 문이 열립니다.';
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
