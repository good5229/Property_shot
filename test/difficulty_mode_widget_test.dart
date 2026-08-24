import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/run_difficulty_attribution_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/stage_chain_score_patterns.dart';

void main() {
  setUp(() {
    GameFeedback.resetForTesting();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('보통 모드는 조준 뒤에도 예상 도착 마커를 만들지 않는다', (tester) async {
    await _pumpGame(tester, difficulty: PlayerDifficulty.normal);

    await _aim(tester);

    expect(_game(tester).firstArrivalPreview, isNull);
    expect(find.byKey(const Key('precision_aim_controls')), findsNothing);
  });

  testWidgets('쉬움 모드는 조준 뒤 실제 판정 기반 예상 도착 마커를 만든다', (tester) async {
    await _pumpGame(tester, difficulty: PlayerDifficulty.easy);

    await _aim(tester);

    final expected = const ShotResolver().firstArrival(
      levels.first.createState(0, productRules: true),
      ShotInput(direction: const Vec2(80, -45).normalized(), power: 0.5),
    );
    final actual = _game(tester).firstArrivalPreview;
    expect(actual, isNotNull);
    expect(actual!.position.x, closeTo(expected.position.x, 0.000001));
    expect(actual.position.y, closeTo(expected.position.y, 0.000001));
    expect(
      tester.getSemantics(find.bySemanticsLabel('공을 조준하는 게임 화면')).value,
      contains('예상 첫 도착'),
    );
  });

  testWidgets('정밀 조작 도움은 쉬움에서만 보이고 힘을 한 칸씩 조절한다', (tester) async {
    await _pumpGame(tester, difficulty: PlayerDifficulty.easy);
    await tester.pump();
    expect(find.byKey(const Key('precision_aim_controls')), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    await tester.tap(find.byKey(const Key('precision_power_increase')));
    await tester.pump();
    expect(find.text('52%'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('precision_aim_controls')))
          .label,
      contains('정밀 조작 도움'),
    );
  });

  testWidgets('쉬움 클리어는 잠금만 해제하고 보통 최고 기록과 선택 도전을 덮지 않는다', (tester) async {
    final progress = _ProgressSpy();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          showStageSelector: false,
          loadGameAssets: false,
          difficulty: PlayerDifficulty.easy,
          progressStore: progress,
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.createGesture();
    await gesture.down(
      _logicalOffset(tester, 56, 456),
      timeStamp: const Duration(seconds: 1),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await gesture.up(timeStamp: const Duration(seconds: 1, milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    expect(progress.stageClearWrites, 1);
    expect(progress.bestShotWrites, 0);
    expect(progress.bonusGoalWrites, 0);
    await _expectAttributionCleared();
  });

  testWidgets('콜드 스타트는 저장된 쉬움 설정을 불러온 뒤 단계 난이도를 캡처한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameFeedback.settingsSchemaVersionKey: GameFeedback.settingsSchemaVersion,
      GameFeedback.playerDifficultyPreferenceKey: PlayerDifficulty.easy.name,
    });
    GameFeedback.resetForTesting();

    await tester.pumpWidget(
      PropertyShotApp(
        showHome: true,
        showDebugControls: false,
        progressStore: _ProgressSpy(),
      ),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.difficulty, PlayerDifficulty.easy);
    final preferences = await SharedPreferences.getInstance();
    final session = _session(preferences);
    final state = await session.loadState();
    expect(state, isNotNull);
    expect(
      RunDifficultyAttributionStore(preferences).loadFor(state!)?.difficulty,
      PlayerDifficulty.easy,
    );
  });

  testWidgets('쉬움 완료 뒤 설정을 보통으로 바꿔 재개해도 보통 기록에 쓰지 않는다', (tester) async {
    await _seedCompletedStage(
      completionDifficulty: PlayerDifficulty.easy,
      currentSetting: PlayerDifficulty.normal,
    );
    final progress = _ProgressSpy();

    await _resumeSeededRun(tester, progress);

    expect(progress.stageClearWrites, 1);
    expect(progress.bestShotWrites, 0);
    expect(progress.bonusGoalWrites, 0);
    await _expectAttributionCleared();
  });

  testWidgets('쉬움으로 시작한 같은 단계는 보통 설정으로 바꿔 재개해도 쉬움을 유지한다', (tester) async {
    await _seedPlayingStage(
      attributedDifficulty: PlayerDifficulty.easy,
      currentSetting: PlayerDifficulty.normal,
    );
    await _resumeSeededRun(tester, _ProgressSpy());

    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).difficulty,
      PlayerDifficulty.easy,
    );
    await _expectStoredAttribution(PlayerDifficulty.easy);
  });

  testWidgets('보통으로 시작한 같은 단계는 쉬움 설정으로 바꿔 재개해도 보통을 유지한다', (tester) async {
    await _seedPlayingStage(
      attributedDifficulty: PlayerDifficulty.normal,
      currentSetting: PlayerDifficulty.easy,
    );
    await _resumeSeededRun(tester, _ProgressSpy());

    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).difficulty,
      PlayerDifficulty.normal,
    );
    await _expectStoredAttribution(PlayerDifficulty.normal);
  });

  testWidgets('보통 완료 뒤 설정을 쉬움으로 바꿔 재개해도 보통 기록을 복원한다', (tester) async {
    await _seedCompletedStage(
      completionDifficulty: PlayerDifficulty.normal,
      currentSetting: PlayerDifficulty.easy,
    );
    final progress = _ProgressSpy();

    await _resumeSeededRun(tester, progress);

    expect(progress.stageClearWrites, 1);
    expect(progress.bestShotWrites, 1);
    expect(progress.bonusGoalWrites, 1);
    await _expectAttributionCleared();
  });

  testWidgets('귀속 메타데이터가 없는 구형 완료 상태는 잠금만 안전하게 복구한다', (tester) async {
    await _seedCompletedStage(
      completionDifficulty: null,
      currentSetting: PlayerDifficulty.normal,
    );
    final progress = _ProgressSpy();

    await _resumeSeededRun(tester, progress);

    expect(progress.stageClearWrites, 1);
    expect(progress.bestShotWrites, 0);
    expect(progress.bonusGoalWrites, 0);
    await _expectAttributionCleared();
  });

  for (final fixture in const [
    (
      name: '보통 귀속',
      attribution: PlayerDifficulty.normal,
      currentSetting: PlayerDifficulty.easy,
      competitiveWrites: 1,
    ),
    (
      name: '쉬움 귀속',
      attribution: PlayerDifficulty.easy,
      currentSetting: PlayerDifficulty.normal,
      competitiveWrites: 0,
    ),
    (
      name: '귀속 없음',
      attribution: null,
      currentSetting: PlayerDifficulty.normal,
      competitiveWrites: 0,
    ),
  ]) {
    testWidgets('성공 샷 crash recovery ${fixture.name}은 귀속대로 기록한다', (
      tester,
    ) async {
      await _seedSuccessfulShotCrash(
        attribution: fixture.attribution,
        currentSetting: fixture.currentSetting,
      );
      final progress = _ProgressSpy();

      await _resumeSeededRun(tester, progress);

      expect(progress.stageClearWrites, 1);
      expect(progress.bestShotWrites, fixture.competitiveWrites);
      expect(progress.bonusGoalWrites, fixture.competitiveWrites);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.containsKey(RunDifficultyAttributionStore.storageKey),
        isFalse,
      );
    });
  }

  for (final fixture in const [
    (
      name: '보통 귀속',
      attribution: PlayerDifficulty.normal,
      currentSetting: PlayerDifficulty.easy,
      competitiveWrites: 1,
    ),
    (
      name: '쉬움 귀속',
      attribution: PlayerDifficulty.easy,
      currentSetting: PlayerDifficulty.normal,
      competitiveWrites: 0,
    ),
    (
      name: '귀속 없음',
      attribution: null,
      currentSetting: PlayerDifficulty.normal,
      competitiveWrites: 0,
    ),
  ]) {
    testWidgets('직접 완료 ${fixture.name}은 귀속대로 기록한다', (tester) async {
      await _seedChainStagePlaying(
        attribution: fixture.attribution,
        currentSetting: fixture.currentSetting,
      );
      final progress = _ProgressSpy();
      await _resumeSeededRun(tester, progress);
      final screen = tester.widget<GameScreen>(find.byType(GameScreen));
      final solution = stageChainScoreSolutions.singleWhere(
        (candidate) => candidate.patternId == screen.levelOverride?.patternId,
      );

      await _launchShot(tester, solution.firstInput);
      await _launchShot(tester, solution.secondInput);
      await _pumpForAsyncWork(tester);

      expect(progress.stageClearWrites, 1);
      expect(progress.bestShotWrites, fixture.competitiveWrites);
      expect(progress.bonusGoalWrites, fixture.competitiveWrites);
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.containsKey(RunDifficultyAttributionStore.storageKey),
        isFalse,
      );
    });
  }
}

Future<void> _resumeSeededRun(
  WidgetTester tester,
  _ProgressSpy progress,
) async {
  GameFeedback.resetForTesting();
  await tester.pumpWidget(
    PropertyShotApp(
      showHome: true,
      showDebugControls: false,
      progressStore: progress,
    ),
  );
  await _pumpForAsyncWork(tester);
  await tester.tap(find.byKey(const Key('start_game_button')));
  await _pumpForAsyncWork(tester);
}

Future<void> _expectAttributionCleared() async {
  final preferences = await SharedPreferences.getInstance();
  expect(
    preferences.containsKey(RunDifficultyAttributionStore.storageKey),
    isFalse,
  );
}

Future<void> _expectStoredAttribution(PlayerDifficulty difficulty) async {
  final preferences = await SharedPreferences.getInstance();
  final state = await _session(preferences).loadState();
  expect(state, isNotNull);
  expect(
    RunDifficultyAttributionStore(preferences).loadFor(state!)?.difficulty,
    difficulty,
  );
}

Future<void> _seedCompletedStage({
  required PlayerDifficulty? completionDifficulty,
  required PlayerDifficulty currentSetting,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final session = _session(preferences);
  await session.selectStage(levels.first.id);
  final playingState = session.state!;
  if (completionDifficulty != null) {
    await RunDifficultyAttributionStore(
      preferences,
    ).save(playingState, completionDifficulty);
  }
  await session.completeCurrentStage(
    stageId: levels.first.id,
    nextStageId: levels[1].id,
    shotCount: 2,
    optionalChallengeAchieved: true,
  );
  await preferences.setInt(
    GameFeedback.settingsSchemaVersionKey,
    GameFeedback.settingsSchemaVersion,
  );
  await preferences.setString(
    GameFeedback.playerDifficultyPreferenceKey,
    currentSetting.name,
  );
}

Future<void> _seedPlayingStage({
  required PlayerDifficulty attributedDifficulty,
  required PlayerDifficulty currentSetting,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final session = _session(preferences);
  await session.selectStage(levels.first.id);
  expect(
    await RunDifficultyAttributionStore(
      preferences,
    ).save(session.state!, attributedDifficulty),
    isTrue,
  );
  await preferences.setInt(
    GameFeedback.settingsSchemaVersionKey,
    GameFeedback.settingsSchemaVersion,
  );
  await preferences.setString(
    GameFeedback.playerDifficultyPreferenceKey,
    currentSetting.name,
  );
}

Future<void> _seedSuccessfulShotCrash({
  required PlayerDifficulty? attribution,
  required PlayerDifficulty currentSetting,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final session = _session(preferences);
  final draw = await session.selectStage('stage_chain_score');
  final solution = stageChainScoreSolutions.singleWhere(
    (candidate) => candidate.patternId == draw.patternId,
  );
  if (attribution != null) {
    expect(
      await RunDifficultyAttributionStore(
        preferences,
      ).save(session.state!, attribution),
      isTrue,
    );
  }
  await session.recordShot(input: solution.firstInput);
  await session.recordShot(input: solution.secondInput);
  await preferences.setInt(
    GameFeedback.settingsSchemaVersionKey,
    GameFeedback.settingsSchemaVersion,
  );
  await preferences.setString(
    GameFeedback.playerDifficultyPreferenceKey,
    currentSetting.name,
  );
}

Future<void> _seedChainStagePlaying({
  required PlayerDifficulty? attribution,
  required PlayerDifficulty currentSetting,
}) async {
  final preferences = await SharedPreferences.getInstance();
  final session = _session(preferences);
  await session.selectStage('stage_chain_score');
  if (attribution != null) {
    expect(
      await RunDifficultyAttributionStore(
        preferences,
      ).save(session.state!, attribution),
      isTrue,
    );
  }
  await preferences.setInt(
    GameFeedback.settingsSchemaVersionKey,
    GameFeedback.settingsSchemaVersion,
  );
  await preferences.setString(
    GameFeedback.playerDifficultyPreferenceKey,
    currentSetting.name,
  );
}

Future<void> _launchShot(WidgetTester tester, ShotInput input) async {
  final game = _game(tester);
  final shotNumber = game.state.shotCount;
  final start = _logicalOffset(
    tester,
    game.state.activeBall.position.x,
    game.state.activeBall.position.y,
  );
  final rect = tester.getRect(find.byKey(const Key('aim_area')));
  final scale = rect.width / 360 < rect.height / 560
      ? rect.width / 360
      : rect.height / 560;
  final target =
      start +
      Offset(input.direction.x * 100 * scale, input.direction.y * 100 * scale);
  final downAt = Duration(seconds: 100 + shotNumber * 100);
  final chargeMillis = 450 + ((input.power - 0.12) / 0.055 * 80).round();
  final releaseAt = downAt + Duration(milliseconds: chargeMillis);
  final gesture = await tester.createGesture();
  await gesture.down(start, timeStamp: downAt);
  await tester.pump(const Duration(milliseconds: 460));
  await gesture.moveTo(target, timeStamp: releaseAt);
  await gesture.up(timeStamp: releaseAt);
  for (var frame = 0; frame < 100; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(
    game.state.shotCount,
    shotNumber + 1,
    reason: '충전 발사가 입력되어야 한다: ${game.state.message}',
  );
  final retry = find.byKey(const Key('failure_retry_button'));
  if (retry.evaluate().isNotEmpty) {
    await tester.tap(retry);
    await tester.pump();
  }
}

StagePatternSession _session(SharedPreferences preferences) =>
    StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 30; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpGame(
  WidgetTester tester, {
  required PlayerDifficulty difficulty,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        initialState: levels.first.createState(0, productRules: true),
        showStageSelector: false,
        loadGameAssets: false,
        difficulty: difficulty,
      ),
    ),
  );
  await tester.pump();
  await _game(tester).toBeLoaded();
}

Future<void> _aim(WidgetTester tester) async {
  final rect = tester.getRect(find.byKey(const Key('aim_area')));
  final scale = rect.width / logicalSize.x;
  final ball = levels.first
      .createState(0, productRules: true)
      .activeBall
      .position;
  final start = rect.topLeft + Offset(ball.x * scale, ball.y * scale);
  final gesture = await tester.startGesture(start);
  await gesture.moveTo(start + const Offset(80, -45));
  await gesture.up();
  await tester.pump();
}

PropertyShotGame _game(WidgetTester tester) {
  final state = tester.state<GameWidgetState<PropertyShotGame>>(
    find.byType(GameWidget<PropertyShotGame>),
  );
  return state.currentGame;
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

GameState _directClearState() => const GameState(
  levelIndex: 0,
  levelName: '클리어 테스트',
  ballSpawn: Vec2(56, 456),
  entities: [
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

class _ProgressSpy extends ProgressStore {
  _ProgressSpy() : super(stageCount: levels.length);

  int stageClearWrites = 0;
  int bestShotWrites = 0;
  int bonusGoalWrites = 0;

  @override
  Future<ProgressSnapshot> load() async => const ProgressSnapshot(
    clearedLevels: {},
    unlockedLevel: 0,
    bestShots: {},
    bonusGoals: {},
    copyCoreCount: 0,
    copyCoreRewarded: false,
    copyCoreRewardedStageIds: {},
    discoveriesByStageId: {},
  );

  @override
  Future<void> recordStageClear(int levelIndex) async => stageClearWrites++;

  @override
  Future<void> recordBestShot(int levelIndex, int shotCount) async =>
      bestShotWrites++;

  @override
  Future<void> recordBonusGoal(int levelIndex) async => bonusGoalWrites++;
}
