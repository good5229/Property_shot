import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/run_difficulty_attribution_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

  test('완료 귀속은 이후 사용자 설정 변경과 무관하게 쉬움을 복원한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    await session.selectStage(generatedStageCatalog.stages.first.stageId);
    final state = session.state!;
    final store = RunDifficultyAttributionStore(preferences);

    expect(await store.save(state, PlayerDifficulty.easy), isTrue);
    GameFeedback.playerDifficulty = PlayerDifficulty.normal;

    expect(store.loadFor(state)?.difficulty, PlayerDifficulty.easy);
  });

  test('완료 귀속은 이후 사용자 설정 변경과 무관하게 보통을 복원한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    await session.selectStage(generatedStageCatalog.stages.first.stageId);
    final state = session.state!;
    final store = RunDifficultyAttributionStore(preferences);

    expect(await store.save(state, PlayerDifficulty.normal), isTrue);
    GameFeedback.playerDifficulty = PlayerDifficulty.easy;

    expect(store.loadFor(state)?.difficulty, PlayerDifficulty.normal);
  });

  test('구형 완료 트랜잭션처럼 metadata가 없으면 경쟁 기록 귀속을 추정하지 않는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    await session.selectStage(generatedStageCatalog.stages.first.stageId);

    expect(
      RunDifficultyAttributionStore(preferences).loadFor(session.state!),
      isNull,
    );
  });

  test('같은 단계 identity는 쉬움 최초 귀속을 보통 설정으로 덮어쓰지 않는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = _session(preferences);
    await session.selectStage(generatedStageCatalog.stages.first.stageId);
    final state = session.state!;
    final store = RunDifficultyAttributionStore(preferences);

    expect(await store.save(state, PlayerDifficulty.easy), isTrue);
    expect(await store.save(state, PlayerDifficulty.normal), isTrue);

    expect(store.loadFor(state)?.difficulty, PlayerDifficulty.easy);
  });

  test('같은 단계 identity는 보통 최초 귀속을 쉬움 설정으로 덮어쓰지 않는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = _session(preferences);
    await session.selectStage(generatedStageCatalog.stages.first.stageId);
    final state = session.state!;
    final store = RunDifficultyAttributionStore(preferences);

    expect(await store.save(state, PlayerDifficulty.normal), isTrue);
    expect(await store.save(state, PlayerDifficulty.easy), isTrue);

    expect(store.loadFor(state)?.difficulty, PlayerDifficulty.normal);
  });

  test('성공한 완료 트랜잭션 뒤 귀속 sidecar를 제거한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = _session(preferences);
    await session.selectStage(generatedStageCatalog.stages.first.stageId);
    final state = session.state!;
    final store = RunDifficultyAttributionStore(preferences);
    expect(await store.save(state, PlayerDifficulty.normal), isTrue);

    await store.clearFor(state);

    expect(store.loadFor(state), isNull);
    expect(
      preferences.containsKey(RunDifficultyAttributionStore.storageKey),
      isFalse,
    );
  });

  test('실제로 새 단계 identity가 시작되면 새 난이도 snapshot을 저장한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = _session(preferences);
    final firstStage = generatedStageCatalog.stages[0].stageId;
    final secondStage = generatedStageCatalog.stages[1].stageId;
    await session.selectStage(firstStage);
    final store = RunDifficultyAttributionStore(preferences);
    expect(await store.save(session.state!, PlayerDifficulty.easy), isTrue);
    await session.completeCurrentStage(
      stageId: firstStage,
      nextStageId: secondStage,
      shotCount: 2,
    );
    await session.selectStage(secondStage);

    expect(await store.save(session.state!, PlayerDifficulty.normal), isTrue);

    expect(store.loadFor(session.state!)?.difficulty, PlayerDifficulty.normal);
  });
}

StagePatternSession _session(SharedPreferences preferences) =>
    StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
