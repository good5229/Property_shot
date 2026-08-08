import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/daily_challenge_record_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/daily_challenge.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';

void main() {
  test('한국 표준시 자정 경계를 UTC 기준으로 정확히 나눈다', () {
    final before = DailyChallengeDefinition.fromDateTime(
      DateTime.utc(2026, 8, 8, 14, 59, 59, 999),
    );
    final after = DailyChallengeDefinition.fromDateTime(
      DateTime.utc(2026, 8, 8, 15),
    );

    expect(before.dateKey, '2026-08-08');
    expect(after.dateKey, '2026-08-09');
    expect(before.displayDate, '2026년 8월 8일');
  });

  test('같은 날짜와 해석기 버전은 시드와 짧은 코드를 동일하게 만든다', () {
    final first = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final second = DailyChallengeDefinition.fromDateTime(
      DateTime.utc(2026, 8, 8, 14),
    );
    final other = DailyChallengeDefinition.fromDateKey('2026-08-09');

    expect(first.rootSeed, second.rootSeed);
    expect(first.seedCode, second.seedCode);
    expect(first.rootSeed, isNot(other.rootSeed));
    expect(first.seedCode, hasLength(6));
    expect(first.challengeVersion, dailyChallengeVersion);
    expect(first.resolverVersion, dailyChallengePhysicsResolverVersion);
  });

  test('고정 시드의 공식 세션은 별도 저장소에서도 stage1과 보상 후보를 재현한다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final firstStorage = DailyChallengeRunStateStorage.official(
      backend: _MemoryBackend(),
      definition: definition,
      attemptId: 'attempt_1',
    );
    final secondStorage = DailyChallengeRunStateStorage.official(
      backend: _MemoryBackend(),
      definition: definition,
      attemptId: 'attempt_1',
    );
    final first = firstStorage.createSession(catalog: generatedStageCatalog);
    final second = secondStorage.createSession(catalog: generatedStageCatalog);

    final firstDraw = await first.selectStage('stage_heavy');
    final secondDraw = await second.selectStage('stage_heavy');
    await first.completeCurrentStage(stageId: 'stage_heavy', shotCount: 2);
    await second.completeCurrentStage(stageId: 'stage_heavy', shotCount: 2);
    final firstRewards = await first.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    final secondRewards = await second.prepareRewardSelection(
      stageId: 'stage_heavy',
    );

    expect(firstDraw.patternId, secondDraw.patternId);
    expect(firstDraw.patternSeed, secondDraw.patternSeed);
    expect(
      firstRewards.map((reward) => reward.id),
      secondRewards.map((reward) => reward.id),
    );
    expect(first.state!.rootSeed, definition.rootSeed);
    expect(first.state!.runId, 'daily_2026-08-08_official_attempt_1');
    expect(first.state!.resolverVersion, dailyChallengePhysicsResolverVersion);
  });

  test('단계별 chain score는 RunState totalScore에 누적되고 재개 뒤에도 유지된다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend();
    final storage = DailyChallengeRunStateStorage.official(
      backend: backend,
      definition: definition,
      attemptId: 'attempt_1',
    );
    final session = storage.createSession(catalog: generatedStageCatalog);

    await session.selectStage('stage_heavy');
    await session.completeCurrentStage(
      stageId: 'stage_heavy',
      shotCount: 2,
      chainScore: 120,
      nextStageId: 'stage_bouncy',
    );
    expect(session.state!.totalScore, 120);
    await session.prepareRewardSelection(stageId: 'stage_heavy');
    await session.selectReward(session.state!.rewardCandidateIds.first);

    await session.selectStage('stage_bouncy');
    await session.completeCurrentStage(
      stageId: 'stage_bouncy',
      shotCount: 1,
      chainScore: 280,
      nextStageId: 'stage_chain_gate',
    );
    expect(session.state!.chainScoresPerStage, {
      'stage_heavy': 120,
      'stage_bouncy': 280,
    });
    expect(session.state!.totalScore, 400);

    final resumed = storage.createSession(catalog: generatedStageCatalog);
    final restored = await resumed.loadState();
    expect(restored!.totalScore, 400);
    expect(restored.chainScoresPerStage['stage_heavy'], 120);
    expect(restored.chainScoresPerStage['stage_bouncy'], 280);
  });

  test('일반·정식·연습 RunState namespace가 서로 침범하지 않는다', () async {
    final backend = _MemoryBackend();
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final normal = RunStateStore(backend: backend);
    final official = DailyChallengeRunStateStorage.official(
      backend: backend,
      definition: definition,
      attemptId: 'attempt_1',
    );
    final practice = DailyChallengeRunStateStorage.practice(
      definition: definition,
    );

    await normalSession(normal).selectStage('stage_heavy');
    await official
        .createSession(catalog: generatedStageCatalog)
        .selectStage('stage_heavy');
    await practice
        .createSession(catalog: generatedStageCatalog)
        .selectStage('stage_heavy');

    expect((await normal.load())!.runId, isNot(startsWith('daily_')));
    expect((await official.loadSnapshot()).state!.runId, contains('official'));
    expect((await practice.loadSnapshot()).state!.runId, contains('practice'));
    expect(backend.values.keys, contains(RunStateStore.slotAKey));
    expect(
      backend.values.keys,
      contains('${official.namespace}${RunStateStore.slotAKey}'),
    );
    expect(
      backend.values.keys,
      isNot(contains('${practice.namespace}${RunStateStore.slotAKey}')),
    );
  });

  test('완료된 정식 시도는 불변이며 새 시도도 같은 결정론 입력을 쓴다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend();
    final storage = DailyChallengeRunStateStorage.official(
      backend: backend,
      definition: definition,
      attemptId: 'attempt_1',
    );
    final first = storage.createSession(catalog: generatedStageCatalog);
    final firstDraw = await first.selectStage('stage_heavy');
    await first.completeCurrentStage(stageId: 'stage_heavy', shotCount: 1);
    final firstRewards = await first.prepareRewardSelection(
      stageId: 'stage_heavy',
    );
    await first.selectReward(firstRewards.first.id);
    await first.completeRun();

    final next = storage.createSession(catalog: generatedStageCatalog);
    await expectLater(
      next.selectStage('stage_heavy'),
      throwsA(isA<StateError>()),
    );
    final retry = DailyChallengeRunStateStorage.official(
      backend: backend,
      definition: definition,
      attemptId: 'attempt_2',
    ).createSession(catalog: generatedStageCatalog);
    final nextDraw = await retry.selectStage('stage_heavy');
    await retry.completeCurrentStage(stageId: 'stage_heavy', shotCount: 1);
    final nextRewards = await retry.prepareRewardSelection(
      stageId: 'stage_heavy',
    );

    expect(retry.state!.rootSeed, definition.rootSeed);
    expect(retry.state!.runId, isNot(first.state!.runId));
    expect(nextDraw.patternId, firstDraw.patternId);
    expect(nextDraw.patternSeed, firstDraw.patternSeed);
    expect(
      nextRewards.map((reward) => reward.id),
      firstRewards.map((reward) => reward.id),
    );
  });

  test('정식 시도 수는 시작에서만 증가하고 최고 점수·최고 샷은 각각 max·min으로 남는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend();
    final first = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
      now: () => DateTime.utc(2026, 8, 8, 1),
    );

    expect((await first.load()).officialAttemptCount, 0);
    expect(
      (await first.beginOfficialAttempt(
        attemptId: 'attempt_1',
        runId: definition.officialRunId('attempt_1'),
      )).officialAttemptCount,
      1,
    );
    expect(
      (await first.reconcileCompletedRun(
        runStateStorage: await _completedOfficialRun(
          definition,
          'attempt_1',
          totalScore: 1200,
          totalShotSum: 18,
        ),
      )).bestTotalScore,
      1200,
    );
    await first.beginOfficialAttempt(
      attemptId: 'attempt_2',
      runId: definition.officialRunId('attempt_2'),
    );
    final worse = await first.reconcileCompletedRun(
      runStateStorage: await _completedOfficialRun(
        definition,
        'attempt_2',
        totalScore: 900,
        totalShotSum: 22,
      ),
    );
    expect(worse.officialAttemptCount, 2);
    expect(worse.bestTotalScore, 1200);
    expect(worse.bestShotSum, 18);

    final restored = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
    );
    final record = await restored.load();
    expect(record.completed, isTrue);
    expect(record.officialAttemptCount, 2);
    expect(record.bestTotalScore, 1200);
    expect(record.bestShotSum, 18);
  });

  test('연습 결과는 정식 기록을 바꾸지 않는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final store = DailyChallengeRecordStore(
      backend: _MemoryBackend(),
      definition: definition,
    );
    await store.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: definition.officialRunId('attempt_1'),
    );
    await store.reconcileCompletedRun(
      runStateStorage: await _completedOfficialRun(
        definition,
        'attempt_1',
        totalScore: 500,
        totalShotSum: 10,
      ),
    );
    final before = await store.load();
    final after = await store.recordPracticeResult(
      totalScore: 9999,
      totalShotSum: 1,
    );

    expect(after.toJson(), before.toJson());
  });

  test('정식 시작 전 완료와 미완료 RunState는 저장하지 않는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final store = DailyChallengeRecordStore(
      backend: _MemoryBackend(),
      definition: definition,
    );

    await expectLater(
      store.reconcileCompletedRun(
        runStateStorage: await _completedOfficialRun(
          definition,
          'attempt_1',
          totalScore: 100,
          totalShotSum: 10,
        ),
      ),
      throwsA(isA<StateError>()),
    );
    await store.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: definition.officialRunId('attempt_1'),
    );
    final unfinished = DailyChallengeRunStateStorage.official(
      backend: _MemoryBackend(),
      definition: definition,
      attemptId: 'attempt_1',
    );
    await unfinished
        .createSession(catalog: generatedStageCatalog)
        .selectStage('stage_heavy');
    await expectLater(
      store.reconcileCompletedRun(runStateStorage: unfinished),
      throwsA(isA<StateError>()),
    );
    expect((await store.load()).completed, isFalse);
  });

  test('기기 시계가 뒤로 가도 정식 기록 갱신 시각은 역행하지 않는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend();
    final first = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
      now: () => DateTime.utc(2026, 8, 8, 10),
    );
    final started = await first.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: definition.officialRunId('attempt_1'),
    );
    final reversedClock = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
      now: () => DateTime.utc(2026, 8, 8, 9),
    );

    final completed = await reversedClock.reconcileCompletedRun(
      runStateStorage: await _completedOfficialRun(
        definition,
        'attempt_1',
        totalScore: 100,
        totalShotSum: 10,
      ),
    );
    expect(completed.updatedAt, started.updatedAt);
  });

  test('손상된 날짜 기록은 해당 날짜 기본값으로 복구하고 다른 날짜는 보존한다', () async {
    final firstDefinition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final secondDefinition = DailyChallengeDefinition.fromDateKey('2026-08-09');
    final backend = _MemoryBackend();
    final first = DailyChallengeRecordStore(
      backend: backend,
      definition: firstDefinition,
    );
    final second = DailyChallengeRecordStore(
      backend: backend,
      definition: secondDefinition,
    );

    await second.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: secondDefinition.officialRunId('attempt_1'),
    );
    await second.reconcileCompletedRun(
      runStateStorage: await _completedOfficialRun(
        secondDefinition,
        'attempt_1',
        totalScore: 800,
        totalShotSum: 17,
      ),
    );
    await backend.write(first.slotAKey, '{"schemaVersion":1}');

    final recovered = await first.load();
    final preserved = await second.load();
    expect(recovered.officialAttemptCount, 0);
    expect(recovered.completed, isFalse);
    expect(preserved.officialAttemptCount, 1);
    expect(preserved.bestTotalScore, 800);
  });

  test('기록 backend 읽기 I/O 오류는 기본값으로 바꾸지 않고 전파한다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend()..readError = StateError('읽기 실패');
    final store = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
    );

    await expectLater(store.load(), throwsA(isA<StateError>()));
    expect(backend.values, isEmpty);
  });

  test('같은 정식 시도 시작과 완료 요청은 한 번만 반영된다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final store = DailyChallengeRecordStore(
      backend: _MemoryBackend(),
      definition: definition,
    );
    final runId = definition.officialRunId('attempt_1');

    await store.beginOfficialAttempt(attemptId: 'attempt_1', runId: runId);
    final duplicateStart = await store.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: runId,
    );
    expect(duplicateStart.officialAttemptCount, 1);

    final completedRun = await _completedOfficialRun(
      definition,
      'attempt_1',
      totalScore: 1400,
      totalShotSum: 16,
    );
    final completed = await store.reconcileCompletedRun(
      runStateStorage: completedRun,
    );
    final duplicateCompletion = await store.reconcileCompletedRun(
      runStateStorage: completedRun,
    );

    expect(duplicateCompletion.toJson(), completed.toJson());
    expect(duplicateCompletion.activeAttemptId, isNull);
    expect(duplicateCompletion.completedAttemptId, 'attempt_1');
  });

  test('다른 시도나 미완료 RunState는 현재 정식 런의 완료로 기록하지 않는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final store = DailyChallengeRecordStore(
      backend: _MemoryBackend(),
      definition: definition,
    );
    final runId = definition.officialRunId('attempt_1');
    await store.beginOfficialAttempt(attemptId: 'attempt_1', runId: runId);

    await expectLater(
      store.reconcileCompletedRun(
        runStateStorage: await _completedOfficialRun(
          definition,
          'attempt_2',
          totalScore: 100,
          totalShotSum: 10,
        ),
      ),
      throwsA(isA<StateError>()),
    );
    final unfinished = DailyChallengeRunStateStorage.official(
      backend: _MemoryBackend(),
      definition: definition,
      attemptId: 'attempt_1',
    );
    await unfinished
        .createSession(catalog: generatedStageCatalog)
        .selectStage('stage_heavy');
    await expectLater(
      store.reconcileCompletedRun(runStateStorage: unfinished),
      throwsA(isA<StateError>()),
    );
    final completed = await store.reconcileCompletedRun(
      runStateStorage: await _completedOfficialRun(
        definition,
        'attempt_1',
        totalScore: 100,
        totalShotSum: 10,
      ),
    );
    expect(completed.completed, isTrue);
  });

  test('공식 기록은 손상된 최신 슬롯 대신 이전 검증 슬롯으로 복구한다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend();
    final store = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
    );
    final runId = definition.officialRunId('attempt_1');
    await store.beginOfficialAttempt(attemptId: 'attempt_1', runId: runId);
    await store.reconcileCompletedRun(
      runStateStorage: await _completedOfficialRun(
        definition,
        'attempt_1',
        totalScore: 700,
        totalShotSum: 19,
      ),
    );
    backend.values[store.slotBKey] = '{"complete":false}';

    final recovered = await DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
    ).load();

    expect(recovered.officialAttemptCount, 1);
    expect(recovered.completed, isFalse);
    expect(recovered.activeAttemptId, 'attempt_1');
  });

  test('공식 기록 쓰기 오류는 성공처럼 처리하지 않는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend()..writeError = StateError('쓰기 실패');
    final store = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
    );

    await expectLater(
      store.beginOfficialAttempt(
        attemptId: 'attempt_1',
        runId: definition.officialRunId('attempt_1'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(backend.values, isEmpty);
  });

  test('활성 정식 시도는 명시적으로 포기하기 전 다른 시도로 교체되지 않는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final store = DailyChallengeRecordStore(
      backend: _MemoryBackend(),
      definition: definition,
    );
    await store.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: definition.officialRunId('attempt_1'),
    );

    await expectLater(
      store.beginOfficialAttempt(
        attemptId: 'attempt_2',
        runId: definition.officialRunId('attempt_2'),
      ),
      throwsA(isA<StateError>()),
    );
    await store.abandonOfficialAttempt(
      attemptId: 'attempt_1',
      runId: definition.officialRunId('attempt_1'),
    );
    final next = await store.beginOfficialAttempt(
      attemptId: 'attempt_2',
      runId: definition.officialRunId('attempt_2'),
    );

    expect(next.officialAttemptCount, 2);
    expect(next.activeAttemptId, 'attempt_2');
  });

  test('같은 backend의 여러 기록 인스턴스도 시작 갱신을 직렬화한다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend();
    final first = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
    );
    final second = DailyChallengeRecordStore(
      backend: backend,
      definition: definition,
    );
    final runId = definition.officialRunId('attempt_1');

    await Future.wait([
      first.beginOfficialAttempt(attemptId: 'attempt_1', runId: runId),
      second.beginOfficialAttempt(attemptId: 'attempt_1', runId: runId),
    ]);

    expect((await first.load()).officialAttemptCount, 1);
  });

  test('시도 수 없는 활성·완료 기록은 손상 후보로 거부한다', () {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final base = DailyChallengeRecord.empty(definition).toJson();

    expect(
      () => DailyChallengeRecord.fromJson({
        ...base,
        'activeAttemptId': 'attempt_1',
        'activeRunId': definition.officialRunId('attempt_1'),
      }),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('같은 날짜라도 도전·물리 버전이 다르면 공식 기록을 분리한다', () async {
    final backend = _MemoryBackend();
    final firstDefinition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final nextDefinition = DailyChallengeDefinition.fromDateKey(
      '2026-08-08',
      challengeVersion: 'daily-challenge-v2',
      resolverVersion: 'shot-resolver-v2',
    );
    final first = DailyChallengeRecordStore(
      backend: backend,
      definition: firstDefinition,
    );
    final next = DailyChallengeRecordStore(
      backend: backend,
      definition: nextDefinition,
    );
    await first.beginOfficialAttempt(
      attemptId: 'attempt_1',
      runId: firstDefinition.officialRunId('attempt_1'),
    );

    expect(first.keyPrefix, isNot(next.keyPrefix));
    expect((await next.load()).officialAttemptCount, 0);
  });

  test('연습 진행은 새 저장소에서 복원되지 않는다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final first = DailyChallengeRunStateStorage.practice(
      definition: definition,
    );
    await first
        .createSession(catalog: generatedStageCatalog)
        .selectStage('stage_heavy');

    final reopened = DailyChallengeRunStateStorage.practice(
      definition: definition,
    );
    expect((await reopened.loadSnapshot()).state, isNull);
  });

  test('정식 재도전은 이전 시도 RunState와 분리된다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final backend = _MemoryBackend();
    final firstStorage = DailyChallengeRunStateStorage.official(
      backend: backend,
      definition: definition,
      attemptId: 'attempt_1',
    );
    final first = firstStorage.createSession(catalog: generatedStageCatalog);
    await first.selectStage('stage_heavy');

    final secondStorage = DailyChallengeRunStateStorage.official(
      backend: backend,
      definition: definition,
      attemptId: 'attempt_2',
    );
    final second = secondStorage.createSession(catalog: generatedStageCatalog);
    await second.selectStage('stage_heavy');

    expect(firstStorage.namespace, isNot(secondStorage.namespace));
    expect(first.state!.runId, definition.officialRunId('attempt_1'));
    expect(second.state!.runId, definition.officialRunId('attempt_2'));
    expect(first.state!.rootSeed, second.state!.rootSeed);
  });

  test('열 단계 전체의 패턴과 보상 순서는 독립 기기에서도 같다', () async {
    final definition = DailyChallengeDefinition.fromDateKey('2026-08-08');
    final first = DailyChallengeRunStateStorage.official(
      backend: _MemoryBackend(),
      definition: definition,
      attemptId: 'attempt_1',
    ).createSession(catalog: generatedStageCatalog);
    final second = DailyChallengeRunStateStorage.official(
      backend: _MemoryBackend(),
      definition: definition,
      attemptId: 'attempt_1',
    ).createSession(catalog: generatedStageCatalog);

    expect(await _drawWholeDailyRun(first), await _drawWholeDailyRun(second));
  });
}

Future<List<String>> _drawWholeDailyRun(StagePatternSession session) async {
  final result = <String>[];
  for (final stage in generatedStageCatalog.stages) {
    final draw = await session.selectStage(stage.stageId);
    result.add('${draw.stageId}:${draw.patternId}:${draw.patternSeed}');
    await session.completeCurrentStage(stageId: stage.stageId, shotCount: 2);
    final rewards = await session.prepareRewardSelection(
      stageId: stage.stageId,
    );
    result.add(rewards.map((reward) => reward.id).join(','));
    await session.selectReward(rewards.first.id);
  }
  await session.completeRun();
  return result;
}

Future<DailyChallengeRunStateStorage> _completedOfficialRun(
  DailyChallengeDefinition definition,
  String attemptId, {
  required int totalScore,
  required int totalShotSum,
}) async {
  final stageCount = generatedStageCatalog.stages.length;
  if (totalShotSum < stageCount) {
    throw ArgumentError('완료 런의 발사 합계는 단계 수 이상이어야 합니다.');
  }
  final storage = DailyChallengeRunStateStorage.official(
    backend: _MemoryBackend(),
    definition: definition,
    attemptId: attemptId,
  );
  final session = storage.createSession(catalog: generatedStageCatalog);
  for (var index = 0; index < stageCount; index++) {
    final stage = generatedStageCatalog.stages[index];
    await session.selectStage(stage.stageId);
    await session.completeCurrentStage(
      stageId: stage.stageId,
      shotCount: index == 0 ? totalShotSum - stageCount + 1 : 1,
      chainScore: index == 0 ? totalScore : 0,
    );
    final rewards = await session.prepareRewardSelection(
      stageId: stage.stageId,
    );
    await session.selectReward(rewards.first.id);
  }
  await session.completeRun();
  return storage;
}

StagePatternSession normalSession(RunStateStore store) => StagePatternSession(
  catalog: generatedStageCatalog,
  store: store,
  now: () => DateTime.utc(2026, 8, 8),
);

class _MemoryBackend implements RunStateKeyValueBackend {
  final Map<String, String> values = <String, String>{};
  Object? readError;
  Object? writeError;

  @override
  Future<String?> read(String key) async {
    final error = readError;
    if (error != null) throw error;
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    final error = writeError;
    if (error != null) throw error;
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
