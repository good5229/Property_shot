import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/run/run_reward.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('발사 취소 보조는 충전 중인 발사를 소비 없이 취소한다', (tester) async {
    final usedRewards = <String>[];
    final persisted = Completer<void>();
    await tester.pumpWidget(
      _gameApp(
        state: levels.first.createState(0, productRules: true),
        acquiredRewards: _acquired(runRewardShotCancelAssistId),
        onRewardUsed: (rewardId, _, _) async {
          usedRewards.add(rewardId);
          await persisted.future;
          return true;
        },
      ),
    );
    await tester.pump();

    final gesture = await _startGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    expect(
      find.byKey(const Key('cancel_launch_reward_button')),
      findsOneWidget,
    );

    tester
        .widget<IconButton>(
          find.byKey(const Key('cancel_launch_reward_button')),
        )
        .onPressed!();
    await tester.pump();
    await gesture.up(timeStamp: const Duration(milliseconds: 1800));
    await tester.pump();

    expect(find.textContaining('시도 0'), findsOneWidget);
    final blockedGesture = await _startGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await blockedGesture.up(timeStamp: const Duration(milliseconds: 2800));
    await tester.pump();
    expect(find.textContaining('시도 0'), findsOneWidget);
    expect(usedRewards, [runRewardShotCancelAssistId]);

    persisted.complete();
    await _pumpAsync(tester);

    expect(usedRewards, [runRewardShotCancelAssistId]);
    expect(find.textContaining('시도 0'), findsOneWidget);
    expect(find.textContaining('다시 조준할 수 있습니다'), findsOneWidget);
  });

  testWidgets('공 꾸미기 보상은 게임판의 공 렌더 설정에 연결된다', (tester) async {
    await tester.pumpWidget(
      _gameApp(
        state: levels.first.createState(0, productRules: true),
        acquiredRewards: _acquired(runRewardBallAppearanceId),
        onRewardUsed: (_, _, _) async => true,
      ),
    );
    await tester.pump();

    final gameWidget = tester.widget<GameWidget<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    );
    expect(gameWidget.game!.ballRewardAppearance, isTrue);
  });

  testWidgets('공 꾸미기 보상은 같은 화면의 기록 재도전에도 즉시 반영된다', (tester) async {
    var acquiredRewards = <String>{};
    late VoidCallback awardAppearance;
    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          awardAppearance = () => setState(
            () => acquiredRewards = _acquired(runRewardBallAppearanceId),
          );
          return _gameApp(
            state: levels.first.createState(0, productRules: true),
            acquiredRewards: acquiredRewards,
            onRewardUsed: (_, _, _) async => true,
          );
        },
      ),
    );
    await tester.pump();
    final game = tester
        .widget<GameWidget<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        )
        .game!;
    expect(game.ballRewardAppearance, isFalse);

    awardAppearance();
    await tester.pump();

    expect(game.ballRewardAppearance, isTrue);
  });

  testWidgets('첫 충돌 안내는 궤적 없이 대상만 알리고 발사 때 한 번 사용한다', (tester) async {
    final usedRewards = <String>[];
    await tester.pumpWidget(
      _gameApp(
        state: _directClearState(),
        acquiredRewards: _acquired(runRewardFirstImpactGuideId),
        onRewardUsed: (rewardId, _, _) async {
          usedRewards.add(rewardId);
          return true;
        },
      ),
    );
    await tester.pump();

    final aim = await _startGesture(tester, _logicalOffset(tester, 56, 456));
    await aim.moveTo(
      _logicalOffset(tester, 300, 456),
      timeStamp: const Duration(milliseconds: 1100),
    );
    await aim.up(timeStamp: const Duration(milliseconds: 1150));
    await tester.pump();

    expect(find.textContaining('첫 충돌 안내 · 홀'), findsOneWidget);
    final launch = await _startGesture(tester, _logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 920));
    await launch.up(timeStamp: const Duration(milliseconds: 1920));
    await tester.pump();
    expect(usedRewards, contains(runRewardFirstImpactGuideId));
  });

  testWidgets('선택 도전과 기록 보호는 실제 클리어 저장값을 바꾼다', (tester) async {
    bool? savedBonus;
    int? savedShots;
    bool? requestedChallengeGuard;
    bool? requestedRecordGuard;
    await tester.pumpWidget(
      _gameApp(
        state: _directClearState(levelIndex: 5).copyWith(shotCount: 2),
        acquiredRewards: {
          ..._acquired(runRewardOptionalChallengeGuardId, patternSeed: 2),
          ..._acquired(runRewardStageRecordGuardId, patternSeed: 3),
        },
        onRewardUsed: (_, _, _) async => true,
        onRunLevelCleared:
            (_, _, bonus, shots, applyChallengeGuard, applyRecordGuard) async {
              requestedChallengeGuard = applyChallengeGuard;
              requestedRecordGuard = applyRecordGuard;
              savedBonus = bonus || applyChallengeGuard;
              savedShots = applyRecordGuard ? shots - 1 : shots;
              return (
                optionalChallengeAchieved: savedBonus!,
                shotCount: savedShots!,
              );
            },
        onLevelCleared: (_, _, _, _) async {
          fail('런 저장 콜백이 있으면 구형 완료 콜백을 사용하지 않아야 합니다.');
        },
      ),
    );
    await tester.pump();

    final launch = await _startGesture(tester, _logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 920));
    await launch.up(timeStamp: const Duration(milliseconds: 1920));
    await _pumpAsync(tester);

    expect(requestedChallengeGuard, isTrue);
    expect(requestedRecordGuard, isTrue);
    expect(savedBonus, isTrue);
    expect(savedShots, 2);
  });

  testWidgets('실패 인과 강화와 과거 공 회수는 실패 팝업에 실제 행동을 더한다', (tester) async {
    final base = _impactFailureState();
    final state = base.copyWith(
      entities: [
        ...base.entities,
        const EntityState(
          id: 'spent_ball_1',
          type: EntityType.ball,
          position: Vec2(300, 100),
          size: Vec2(24, 24),
          movable: true,
        ),
      ],
    );
    await tester.pumpWidget(
      _gameApp(
        state: state,
        acquiredRewards: {
          ..._acquired(runRewardFailureCauseBoostId, patternSeed: 4),
          ..._acquired(runRewardSpentBallRecoveryId, patternSeed: 5),
        },
        onRewardUsed: (_, _, _) async => true,
      ),
    );
    await tester.pump();

    final launch = await _startGesture(tester, _logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 760));
    await launch.up(timeStamp: const Duration(milliseconds: 1760));
    await tester.pump(const Duration(milliseconds: 6500));

    expect(find.textContaining('충돌 순서:'), findsOneWidget);
    expect(find.byKey(const Key('recover_past_ball_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('recover_past_ball_button')));
    await _pumpAsync(tester);
    expect(find.textContaining('과거 공 1번을 회수했습니다'), findsOneWidget);
    expect(find.byKey(const Key('failure_popup')), findsNothing);
  });

  testWidgets('과거 공 회수 뒤 되감기는 새 시도 범위를 즉시 사용한다', (tester) async {
    const pastBall = EntityState(
      id: 'spent_ball_1',
      type: EntityType.ball,
      position: Vec2(200, 220),
      size: Vec2(24, 24),
      movable: true,
    );
    final beforeShot = levels.first
        .createState(0, productRules: true)
        .copyWith(
          entities: [
            ...levels.first.createState(0, productRules: true).entities,
            pastBall,
          ],
        );
    final current = beforeShot.copyWith(shotCount: 1, history: [beforeShot]);
    final acquired = _acquired(runRewardSpentBallRecoveryId, patternSeed: 9);
    final selectionRecord = runRewardSelectionRecordId(
      stageId: 'reward_source_9',
      patternSeed: 9,
      rewardId: runRewardSpentBallRecoveryId,
    );
    acquired.add(
      runRewardUseRecordId(
        selectionRecord,
        '${levels.first.id}|0|${pastBall.id}',
      ),
    );

    await tester.pumpWidget(
      _gameApp(
        state: current,
        acquiredRewards: acquired,
        onRewardUsed: (_, _, _) async => true,
        onShotRewound: () async => {
          ...acquired,
          runStageAttemptRecordId(levels.first.id, 1),
        },
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('rewind_button')).first);
    await _pumpAsync(tester);
    await tester.tapAt(_logicalOffset(tester, 200, 220));
    await tester.pump();

    expect(find.byKey(const Key('entity_info_panel')), findsOneWidget);
    expect(find.text('첫 번째 공'), findsOneWidget);
  });

  testWidgets('되감기 저장 중에는 과거 공 회수를 함께 저장하지 않는다', (tester) async {
    final base = _impactFailureState();
    final state = base.copyWith(
      entities: [
        ...base.entities,
        const EntityState(
          id: 'spent_ball_1',
          type: EntityType.ball,
          position: Vec2(300, 100),
          size: Vec2(24, 24),
          movable: true,
        ),
      ],
    );
    final persisted = Completer<void>();
    final usedRewards = <String>[];
    await tester.pumpWidget(
      _gameApp(
        state: state,
        acquiredRewards: _acquired(runRewardSpentBallRecoveryId),
        onRewardUsed: (rewardId, _, _) async {
          usedRewards.add(rewardId);
          return true;
        },
        onShotRewound: () async {
          await persisted.future;
          return const <String>{};
        },
      ),
    );
    await tester.pump();

    final launch = await _startGesture(tester, _logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 760));
    await launch.up(timeStamp: const Duration(milliseconds: 1760));
    await tester.pump(const Duration(milliseconds: 6500));
    await tester.tap(find.byKey(const Key('failure_rewind_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('recover_past_ball_button')));
    await tester.pump();

    expect(usedRewards, isEmpty);
    persisted.complete();
    await _pumpAsync(tester);
  });
}

Widget _gameApp({
  required GameState state,
  required Set<String> acquiredRewards,
  required Future<bool> Function(String, String, bool) onRewardUsed,
  Future<void> Function(int, dynamic, bool, int)? onLevelCleared,
  Future<StageCompletionResult> Function(int, dynamic, bool, int, bool, bool)?
  onRunLevelCleared,
  Future<Set<String>> Function()? onShotRewound,
}) {
  return MaterialApp(
    home: GameScreen(
      initialState: state,
      initialAcquiredRewards: acquiredRewards,
      loadGameAssets: false,
      onRunRewardUsed: onRewardUsed,
      onLevelCleared: onLevelCleared,
      onRunLevelCleared: onRunLevelCleared,
      onShotRewound: onShotRewound,
    ),
  );
}

Set<String> _acquired(String rewardId, {int patternSeed = 1}) => {
  rewardId,
  runRewardSelectionRecordId(
    stageId: 'reward_source_$patternSeed',
    patternSeed: patternSeed,
    rewardId: rewardId,
  ),
};

GameState _directClearState({int levelIndex = 0}) => GameState(
  levelIndex: levelIndex,
  levelName: '클리어 테스트',
  ballSpawn: const Vec2(56, 456),
  entities: const [
    EntityState(
      id: 'active_ball',
      type: EntityType.ball,
      position: Vec2(56, 456),
      size: Vec2(24, 24),
      movable: true,
    ),
    EntityState(
      id: 'hole',
      type: EntityType.hole,
      position: Vec2(220, 456),
      size: Vec2(34, 34),
      solid: false,
    ),
  ],
);

GameState _impactFailureState() => GameState(
  levelIndex: 0,
  levelName: '충돌 실패 테스트',
  ballSpawn: const Vec2(56, 456),
  entities: const [
    EntityState(
      id: 'active_ball',
      type: EntityType.ball,
      position: Vec2(56, 456),
      size: Vec2(24, 24),
      movable: true,
    ),
    EntityState(
      id: 'test_wall',
      type: EntityType.wall,
      position: Vec2(180, 456),
      size: Vec2(24, 150),
    ),
  ],
);

const _pointerDownAt = Duration(seconds: 1);

Future<TestGesture> _startGesture(WidgetTester tester, Offset position) async {
  final gesture = await tester.createGesture();
  await gesture.down(position, timeStamp: _pointerDownAt);
  return gesture;
}

Offset _logicalOffset(WidgetTester tester, double x, double y) {
  final rect = tester.getRect(find.byKey(const Key('aim_area')));
  final scale = rect.width / 360 < rect.height / 560
      ? rect.width / 360
      : rect.height / 560;
  final origin = Offset(
    rect.left + (rect.width - 360 * scale) / 2,
    rect.top + (rect.height - 560 * scale) / 2,
  );
  return origin + Offset(x * scale, y * scale);
}

Future<void> _pumpAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var index = 0; index < 20; index++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
