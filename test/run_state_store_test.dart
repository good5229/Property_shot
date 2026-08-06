import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/run_state.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';

void main() {
  test('빈 저장소는 null을 반환하고 첫 저장은 revision 1이 된다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);

    expect(await store.load(), isNull);
    expect(await store.save(_state(1)), 1);
    expect((await store.load())?.runId, 'run_1');
    expect(store.lastRevision, 1);
    expect(
      backend.values.keys,
      containsAll([RunStateStore.slotAKey, RunStateStore.activePointerKey]),
    );
  });

  test('연속·동시 저장은 queue를 거쳐 마지막 상태와 revision을 보존한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);

    await store.save(_state(1));
    await Future.wait([store.save(_state(2)), store.save(_state(3))]);

    expect(store.lastRevision, 3);
    expect((await store.load())?.rootSeed, 3);
  });

  test('후보 슬롯 기록 후 pointer 단계가 실패해도 높은 revision을 복구한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));

    backend.failBeforeWriteFor(RunStateStore.activePointerKey);
    await expectLater(store.save(_state(2)), throwsA(isA<StateError>()));

    expect((await store.load())?.rootSeed, 2);
    expect(backend.values[RunStateStore.activePointerKey], 'a');
  });

  test('후보 슬롯 쓰기 전에 중단되면 이전 슬롯을 유지한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));

    backend.failBeforeWriteFor(RunStateStore.slotBKey);
    await expectLater(store.save(_state(2)), throwsA(isA<StateError>()));

    expect((await store.load())?.rootSeed, 1);
  });

  test('두 revision 상태에서 후보 슬롯 read 장애가 나면 새 save를 중단한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));
    await store.save(_state(2));

    backend.failBeforeReadFor(RunStateStore.slotAKey);
    await expectLater(store.save(_state(3)), throwsA(isA<StateError>()));
    expect((await store.load())?.rootSeed, 2);

    backend.failBeforeReadFor(RunStateStore.activePointerKey);
    await expectLater(store.save(_state(3)), throwsA(isA<StateError>()));
    expect((await store.load())?.rootSeed, 2);
  });

  test('pointer를 기록한 뒤 장애가 나도 완결 후보가 다음 load에서 선택된다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));

    backend.failAfterWriteFor(RunStateStore.activePointerKey);
    await expectLater(store.save(_state(2)), throwsA(isA<StateError>()));

    expect((await store.load())?.rootSeed, 2);
  });

  test('후보 슬롯 기록 직후 종료되어도 후보가 완결됐으면 복구한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));

    backend.failAfterWriteFor(RunStateStore.slotBKey);
    await expectLater(store.save(_state(2)), throwsA(isA<StateError>()));

    expect((await store.load())?.rootSeed, 2);
  });

  test('후보 verify에서 손상되면 이전 슬롯을 유지한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));

    backend.corruptNextReadFor(RunStateStore.slotBKey);
    await expectLater(store.save(_state(2)), throwsA(isA<StateError>()));

    expect((await store.load())?.rootSeed, 1);
  });

  test('최신 checksum 손상은 이전 유효 슬롯로 되돌아간다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));
    await store.save(_state(2));

    final corrupted = backend.values[RunStateStore.slotBKey]!.replaceFirst(
      'checksum',
      'damaged',
    );
    backend.values[RunStateStore.slotBKey] = corrupted;

    expect((await store.load())?.rootSeed, 1);
  });

  test('pointer가 손상되거나 없어도 유효한 최고 revision을 선택한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));
    await store.save(_state(2));

    backend.values[RunStateStore.activePointerKey] = 'damaged';
    expect((await store.load())?.rootSeed, 2);

    backend.values.remove(RunStateStore.activePointerKey);
    expect((await store.load())?.rootSeed, 2);
  });

  test('reset은 두 슬롯과 pointer를 삭제하고 다시 null이 된다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));
    await store.save(_state(2));

    await store.reset();

    expect(await store.load(), isNull);
    expect(backend.values, isEmpty);
    expect(store.lastRevision, isNull);
  });

  test('RunState 전용 key는 기존 ProgressStore key를 침범하지 않는다', () async {
    SharedPreferences.setMockInitialValues({
      ProgressStore.unlockedLevelKey: 2,
      ProgressStore.clearedLevelsKey: ['0', '1'],
    });
    final preferences = await SharedPreferences.getInstance();
    final progress = ProgressStore(stageCount: 4);
    final store = RunStateStore(
      backend: SharedPreferencesRunStateBackend(preferences),
    );

    await store.save(_state(7));
    final snapshot = progress.read(preferences);

    expect(snapshot.unlockedLevel, 2);
    expect(snapshot.clearedLevels, {0, 1});
    expect(preferences.getInt(ProgressStore.unlockedLevelKey), 2);
    expect(preferences.getString(RunStateStore.activePointerKey), isNotNull);
    expect(preferences.getInt(ProgressStore.saveVersionKey), isNull);
  });

  test('첫 슬롯 삭제 후 두 번째 슬롯 직전 중단 시 남은 유효 슬롯을 복구한다', () async {
    final backend = MemoryRunStateBackend();
    final store = RunStateStore(backend: backend);
    await store.save(_state(1));
    await store.save(_state(2));

    backend.failBeforeRemoveFor(RunStateStore.slotBKey);
    await expectLater(store.reset(), throwsA(isA<StateError>()));

    expect((await store.load())?.rootSeed, 2);
  });
}

class MemoryRunStateBackend implements RunStateKeyValueBackend {
  final values = <String, String>{};
  final _failBeforeWrite = <String>{};
  final _failAfterWrite = <String>{};
  final _failBeforeRead = <String>{};
  final _failBeforeRemove = <String>{};
  final _corruptNextRead = <String>{};

  void failBeforeWriteFor(String key) => _failBeforeWrite.add(key);

  void failAfterWriteFor(String key) => _failAfterWrite.add(key);

  void failBeforeReadFor(String key) => _failBeforeRead.add(key);

  void failBeforeRemoveFor(String key) => _failBeforeRemove.add(key);

  void corruptNextReadFor(String key) => _corruptNextRead.add(key);

  @override
  Future<String?> read(String key) async {
    if (_failBeforeRead.remove(key)) {
      throw StateError('주입된 read 전 장애: $key');
    }
    final value = values[key];
    if (value != null && _corruptNextRead.remove(key)) {
      values[key] = '{"broken":true}';
      return values[key];
    }
    return value;
  }

  @override
  Future<void> write(String key, String value) async {
    if (_failBeforeWrite.remove(key)) {
      throw StateError('주입된 write 전 장애: $key');
    }
    values[key] = value;
    if (_failAfterWrite.remove(key)) {
      throw StateError('주입된 write 후 장애: $key');
    }
  }

  @override
  Future<void> remove(String key) async {
    if (_failBeforeRemove.remove(key)) {
      throw StateError('주입된 remove 전 장애: $key');
    }
    values.remove(key);
  }
}

RunState _state(int seed) {
  return RunState.initial(
    runId: 'run_$seed',
    rootSeed: seed,
    resolverVersion: 'resolver-1',
    currentDraw: _draw(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      rootSeed: seed,
    ),
    now: DateTime.utc(2026, 8, 6),
  );
}

StagePatternDraw _draw({
  required String stageId,
  required String patternId,
  required int rootSeed,
}) {
  final stage = StageDefinition(
    stageId: stageId,
    title: '테스트 스테이지',
    patterns: [
      StagePattern(
        patternId: patternId,
        weight: 1,
        parShots: 1,
        difficultyBand: '테스트',
        ballSpawn: const Vec2(24, 520),
        objects: const [],
      ),
    ],
  );
  return StageShuffleBag.draw(
    stage: stage,
    state: StageShuffleBagState.initial(stageId),
    rootSeed: rootSeed,
  );
}
