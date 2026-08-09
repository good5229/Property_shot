import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/persistence/daily_challenge_record_store.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/run/daily_challenge.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/daily_challenge_screen.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/play_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('홈에서 오늘의 도전 개요로 들어간다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      const PropertyShotApp(showHome: true, showDebugControls: false),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('daily_challenge_entry_button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('daily_challenge_entry_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_challenge_overview')), findsOneWidget);
    expect(find.text('오늘의 도전'), findsOneWidget);
    expect(find.textContaining('시드 코드'), findsOneWidget);
  });

  testWidgets('정식 도전 중복 탭은 하나의 시도만 만든다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MaterialApp(home: DailyChallengeScreen()));
    await tester.pumpAndSettle();

    final button = find.byKey(const Key('daily_official_button'));
    await tester.tap(button);
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 800));

    final preferences = await SharedPreferences.getInstance();
    final definition = DailyChallengeDefinition.fromDateTime(DateTime.now());
    final record = await DailyChallengeRecordStore(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
    ).load();
    expect(record.officialAttemptCount, 1);
    expect(record.activeAttemptId, 'attempt_1');
  });

  testWidgets('정식 도전은 저장된 쉬움 설정과 무관하게 보통 모드로 시작한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameFeedback.playerDifficulty = PlayerDifficulty.easy;
    addTearDown(GameFeedback.resetForTesting);
    await tester.pumpWidget(const MaterialApp(home: DailyChallengeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('daily_official_button')));
    await tester.pump(const Duration(milliseconds: 800));

    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).difficulty,
      PlayerDifficulty.normal,
    );
  });

  testWidgets('오늘의 도전 연습은 쉬움 설정을 사용하되 공식 기록과 분리된다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameFeedback.playerDifficulty = PlayerDifficulty.easy;
    addTearDown(GameFeedback.resetForTesting);
    await tester.pumpWidget(const MaterialApp(home: DailyChallengeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('daily_practice_button')));
    await tester.pump(const Duration(milliseconds: 800));

    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).difficulty,
      PlayerDifficulty.easy,
    );
    final preferences = await SharedPreferences.getInstance();
    final definition = DailyChallengeDefinition.fromDateTime(DateTime.now());
    final record = await DailyChallengeRecordStore(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
    ).load();
    expect(record.officialAttemptCount, 0);
    expect(record.activeAttemptId, isNull);
  });

  testWidgets('오늘의 도전 플레이 중 메인 메뉴로 나가도 공식 진행은 보존된다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    var exited = false;
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    await tester.pumpWidget(
      MaterialApp(
        home: DailyChallengeScreen(
          onExit: () => exited = true,
          now: () => DateTime.utc(2026, 8, 8, 12),
          telemetry: telemetry,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('daily_official_button')));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const Key('home_button')), findsOneWidget);
    expect(find.byTooltip('메인 메뉴'), findsOneWidget);
    expect(find.text('점수 0'), findsOneWidget);
    expect(
      telemetry.events.map((event) => event['event_code']),
      containsAllInOrder([
        'daily_challenge_started',
        'run_started',
        'stage_pattern_drawn',
        'stage_entered',
      ]),
    );

    await tester.tap(find.byKey(const Key('home_button')));
    await tester.pump();

    expect(exited, isTrue);
    final preferences = await SharedPreferences.getInstance();
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final record = await DailyChallengeRecordStore(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
    ).load();
    expect(record.activeAttemptId, 'attempt_1');
    expect(record.completed, isFalse);
  });

  testWidgets('연습은 공식 기록과 일반 진행 기록을 남기지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const MaterialApp(home: DailyChallengeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('daily_practice_button')));
    await tester.pump(const Duration(milliseconds: 800));

    final preferences = await SharedPreferences.getInstance();
    final definition = DailyChallengeDefinition.fromDateTime(DateTime.now());
    final record = await DailyChallengeRecordStore(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
    ).load();
    expect(record.officialAttemptCount, 0);
    expect(record.activeAttemptId, isNull);
    expect(preferences.containsKey('property_shot_cleared_levels'), isFalse);
    expect(preferences.containsKey('property_shot_unlocked_level'), isFalse);
    expect(preferences.containsKey('property_shot_copy_core_count'), isFalse);
  });

  testWidgets('활성 정식 시도는 앱 재시작 뒤 이어하기로 표시된다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final recordStore = DailyChallengeRecordStore(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
    );
    await recordStore.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: definition.officialRunId('attempt_1'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyChallengeScreen(now: () => DateTime.utc(2026, 8, 7, 15)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정식 도전 이어하기'), findsOneWidget);
  });

  testWidgets('앱 복귀 시 KST 날짜가 바뀌면 전날 화면을 이어하지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    var now = DateTime.utc(2026, 8, 8, 14, 59);
    await tester.pumpWidget(
      MaterialApp(home: DailyChallengeScreen(now: () => now)),
    );
    await tester.pumpAndSettle();
    expect(find.text('2026년 8월 8일'), findsOneWidget);

    now = DateTime.utc(2026, 8, 8, 15, 1);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_challenge_overview')), findsOneWidget);
    expect(find.text('2026년 8월 9일'), findsOneWidget);
  });

  testWidgets('열 단계 완료 뒤 runCompleted와 공식 기록을 복구한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final recordStore = DailyChallengeRecordStore(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
    );
    await recordStore.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: definition.officialRunId('attempt_1'),
    );
    final storage = DailyChallengeRunStateStorage.official(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
      attemptId: 'attempt_1',
    );
    final session = storage.createSession(catalog: generatedStageCatalog);
    for (var index = 0; index < generatedStageCatalog.stages.length; index++) {
      final stageId = generatedStageCatalog.stages[index].stageId;
      await session.selectStage(stageId);
      await session.completeCurrentStage(
        stageId: stageId,
        shotCount: 1,
        nextStageId: index + 1 < generatedStageCatalog.stages.length
            ? generatedStageCatalog.stages[index + 1].stageId
            : null,
      );
      final rewards = await session.prepareRewardSelection(stageId: stageId);
      await session.selectReward(rewards.first.id);
    }
    await session.completeRun();
    await recordStore.reconcileCompletedRun(runStateStorage: storage);

    await tester.pumpWidget(
      MaterialApp(
        home: DailyChallengeScreen(now: () => DateTime.utc(2026, 8, 8, 12)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('daily_run_result')), findsOneWidget);
    expect(find.text('오늘의 도전 완료!'), findsOneWidget);
    expect(find.text('발사 합계'), findsOneWidget);
    final restored = await recordStore.load();
    expect(restored.completed, isTrue);
    expect(restored.activeAttemptId, isNull);
    expect(restored.bestShotSum, 10);
  });

  testWidgets('완료된 이전 시도보다 활성 재시도를 우선해 이어간다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    await _completeOfficialRun(preferences, definition, 'attempt_1');
    final recordStore = DailyChallengeRecordStore(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
    );
    await recordStore.beginOfficialAttempt(
      attemptId: 'attempt_2',
      runId: definition.officialRunId('attempt_2'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DailyChallengeScreen(now: () => DateTime.utc(2026, 8, 8, 12)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('정식 도전 이어하기'), findsOneWidget);
    expect(find.byKey(const Key('daily_run_result')), findsNothing);
  });

  testWidgets('연습 결과는 공식 기록을 암시하지 않고 다시 연습을 제공한다', (tester) async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final record = DailyChallengeRecord.empty(definition);
    await tester.pumpWidget(
      MaterialApp(
        home: DailyChallengeResultView(
          score: 120,
          shots: 12,
          rewards: 3,
          mode: DailyChallengeMode.practice,
          record: record,
          onNewAttempt: () {},
          onBack: () {},
        ),
      ),
    );

    expect(find.text('연습 완료!'), findsOneWidget);
    expect(find.text('다시 연습'), findsOneWidget);
    expect(find.text('새 정식 시도'), findsNothing);
    expect(find.text('오늘의 최고 총점'), findsNothing);
  });

  testWidgets('320x700과 390x844 큰 글자 개요에 overflow가 없다', (tester) async {
    for (final fixture in const [
      (width: 320.0, height: 700.0),
      (width: 390.0, height: 844.0),
    ]) {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
            child: DailyChallengeScreen(
              now: () => DateTime.utc(2026, 8, 8, 12),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  test('제품 경계는 카탈로그 재배열과 단일 단계 완료를 거부한다', () async {
    final reordered = StageCatalog(
      schemaVersion: generatedStageCatalog.schemaVersion,
      stages: generatedStageCatalog.stages.reversed.toList(),
    );
    expect(() => validateDailyChallengeStageOrder(reordered), throwsStateError);

    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final storage = DailyChallengeRunStateStorage.practice(
      definition: definition,
    );
    final session = storage.createSession(catalog: generatedStageCatalog);
    await session.selectStage(generatedStageCatalog.stages.first.stageId);
    final state = await session.loadState();
    expect(
      () => validateDailyChallengeRunCompletable(state!),
      throwsStateError,
    );
  });

  testWidgets('오늘의 도전 GameScreen은 일반 ProgressStore 저장 정책을 호출하지 않는다', (
    tester,
  ) async {
    final spy = _SpyProgressStore();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: levels.first.createState(0, productRules: true),
          showStageSelector: false,
          loadGameAssets: false,
          progressStore: spy,
          progressPersistencePolicy: GameProgressPersistencePolicy.disabled,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(spy.loadCalls, 0);
    expect(spy.writeCalls, 0);
  });
}

Future<void> _completeOfficialRun(
  SharedPreferences preferences,
  DailyChallengeDefinition definition,
  String attemptId,
) async {
  final recordStore = DailyChallengeRecordStore(
    backend: SharedPreferencesRunStateBackend(preferences),
    definition: definition,
  );
  await recordStore.beginOfficialAttempt(
    attemptId: attemptId,
    runId: definition.officialRunId(attemptId),
  );
  final storage = DailyChallengeRunStateStorage.official(
    backend: SharedPreferencesRunStateBackend(preferences),
    definition: definition,
    attemptId: attemptId,
  );
  final session = storage.createSession(catalog: generatedStageCatalog);
  for (var index = 0; index < generatedStageCatalog.stages.length; index++) {
    final stageId = generatedStageCatalog.stages[index].stageId;
    await session.selectStage(stageId);
    await session.completeCurrentStage(
      stageId: stageId,
      shotCount: 1,
      nextStageId: index + 1 < generatedStageCatalog.stages.length
          ? generatedStageCatalog.stages[index + 1].stageId
          : null,
    );
    final rewards = await session.prepareRewardSelection(stageId: stageId);
    await session.selectReward(rewards.first.id);
  }
  await session.completeRun();
  await recordStore.reconcileCompletedRun(runStateStorage: storage);
}

class _SpyProgressStore extends ProgressStore {
  _SpyProgressStore() : super(stageCount: levels.length);

  int loadCalls = 0;
  int writeCalls = 0;

  @override
  Future<ProgressSnapshot> load() {
    loadCalls++;
    return Future.value(
      const ProgressSnapshot(
        clearedLevels: {},
        unlockedLevel: 0,
        bestShots: {},
        bonusGoals: {},
        copyCoreCount: 0,
        copyCoreRewarded: false,
        copyCoreRewardedStageIds: {},
      ),
    );
  }

  @override
  Future<void> recordStageClear(int levelIndex) async => writeCalls++;

  @override
  Future<void> recordBestShot(int levelIndex, int shotCount) async =>
      writeCalls++;

  @override
  Future<void> recordBonusGoal(int levelIndex) async => writeCalls++;

  @override
  Future<void> recordCopyCore(
    int count,
    bool rewarded, {
    Iterable<String>? rewardedStageIds,
  }) async => writeCalls++;

  @override
  Future<void> reset() async => writeCalls++;

  @override
  Future<void> unlockAll() async => writeCalls++;
}
