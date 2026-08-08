import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/replay_library_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/replay/replay_capture_service.dart';
import 'package:property_shot/game/replay/replay_document.dart';
import 'package:property_shot/game/replay/replay_failure.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';

void main() {
  test('구형 키만 있는 빈 상태에서 저장·읽기·삭제하고 기존 키를 보존한다', () async {
    final backend = _FaultBackend()..values['legacy_replay_key'] = '[]';
    final store = ReplayLibraryStore(
      backend: backend,
      now: () => DateTime.utc(2026, 8, 8, 1),
    );

    expect((await store.load()).entries, isEmpty);
    final saved = await store.save(document: _document(1), totalScore: 1200);
    final restored = await store.read(saved.replayId);

    expect(saved.replayId, replayLibraryIdForDocument(_document(1)));
    expect(restored?.stageId, 'stage_test');
    expect(restored?.totalScore, 1200);
    expect((await store.readDocument(saved.replayId))?.rootSeed, 1);
    expect(backend.values['legacy_replay_key'], '[]');
    expect(await store.delete(saved.replayId), isTrue);
    expect(await store.delete(saved.replayId), isFalse);
    expect((await store.load()).entries, isEmpty);
  });

  test('용량 초과 시 오래된 비최고 기록부터 정리한다', () async {
    var now = DateTime.utc(2026, 8, 8, 1);
    final store = ReplayLibraryStore(
      backend: _FaultBackend(),
      maxEntries: 2,
      now: () => now,
    );
    final oldLow = await store.save(document: _document(1), totalScore: 100);
    now = now.add(const Duration(minutes: 1));
    final best = await store.save(document: _document(2), totalScore: 300);
    now = now.add(const Duration(minutes: 1));
    final recentLow = await store.save(document: _document(3), totalScore: 200);

    final snapshot = await store.load();
    expect(snapshot.entries.map((entry) => entry.replayId), {
      best.replayId,
      recentLow.replayId,
    });
    expect(snapshot.isBest(best.replayId), isTrue);
    expect(snapshot.isBest(recentLow.replayId), isFalse);
    expect(await store.read(oldLow.replayId), isNull);
  });

  test('최신 슬롯 checksum 손상 시 직전 유효 revision으로 복구한다', () async {
    final backend = _FaultBackend();
    final store = ReplayLibraryStore(backend: backend);
    final first = await store.save(document: _document(1), totalScore: 100);
    await store.save(document: _document(2), totalScore: 200);
    backend.values[ReplayLibraryStore.slotBKey] = backend
        .values[ReplayLibraryStore.slotBKey]!
        .replaceFirst('checksum', 'damaged');

    final restored = await store.load();

    expect(restored.revision, 1);
    expect(restored.entries.single.replayId, first.replayId);
  });

  test('pointer 기록 전 중단되어도 완결된 새 슬롯을 복구한다', () async {
    final backend = _FaultBackend();
    final store = ReplayLibraryStore(backend: backend);
    await store.save(document: _document(1), totalScore: 100);
    backend.failBeforeWriteFor(ReplayLibraryStore.activePointerKey);

    await expectLater(
      store.save(document: _document(2), totalScore: 200),
      throwsA(isA<StateError>()),
    );

    final restored = await store.load();
    expect(restored.revision, 2);
    expect(restored.entries, hasLength(2));
  });

  test('과거 공 회수 시점이 없는 문서는 라이브러리에 저장하지 않는다', () async {
    final document = ReplayDocument(
      mode: ReplayMode.normal,
      dateKey: null,
      challengeVersion: null,
      rootSeed: 7,
      resolverVersion: 'shot-resolver-v1',
      catalogFingerprint: 'catalog',
      stageId: 'stage_test',
      patternId: 'pattern_test',
      patternSeed: 7,
      drawCycle: 0,
      drawIndex: 0,
      recoveredPastBallIds: const ['spent_ball_1'],
      shots: [
        ReplayShot(
          shotIndex: 0,
          ballId: 'spent_ball_1',
          direction: ReplayDirection.fromDoubles(1, 0),
          power: ReplayFixedPoint.encode(0.5),
        ),
      ],
      outcomeFingerprints: const [
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      ],
    );

    expect(
      () => ReplayLibraryStore(
        backend: _FaultBackend(),
      ).save(document: document, totalScore: 0),
      throwsA(
        isA<ReplayFailure>().having(
          (failure) => failure.code,
          'code',
          ReplayFailureCode.unsupportedBetweenShotState,
        ),
      ),
    );
  });

  test('현재 단계 replay reference를 원자 저장하고 새 세션에서 복원한다', () async {
    final backend = MemoryRunStateBackend();
    final runStore = RunStateStore(backend: backend);
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: runStore,
      fixedRootSeed: 31,
      fixedRunId: 'replay-reference-run',
      now: () => DateTime.utc(2026, 8, 8),
    );
    await session.selectStage('stage_heavy');
    final replayId = replayLibraryIdForDocument(_document(31));

    await session.recordCurrentStageReplayReference(
      stageId: 'stage_heavy',
      replayId: replayId,
    );
    final restored = await StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: backend),
    ).loadState();

    expect(restored?.replayReferences, {'stage_heavy': replayId});
  });

  test('실제 캡처 문서를 저장한 뒤 읽어 playback 지문을 재검증한다', () async {
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 37,
      fixedRunId: 'replay-library-integration',
      now: () => DateTime.utc(2026, 8, 8),
    );
    await session.selectStage('stage_heavy');
    await session.recordShot(
      input: const ShotInput(direction: Vec2(1, 0), power: 0.7),
    );
    const capture = ReplayCaptureService();
    final document = capture.capture(
      runState: session.state!,
      catalog: generatedStageCatalog,
    );
    final library = ReplayLibraryStore(backend: MemoryRunStateBackend());

    final entry = await library.save(document: document, totalScore: 900);
    final restored = await library.readDocument(entry.replayId);
    final playback = capture.playback(restored!, generatedStageCatalog);

    expect(playback.fingerprints, document.outcomeFingerprints);
    expect(playback.shotResults, hasLength(1));
  });
}

ReplayDocument _document(int seed) => ReplayDocument(
  mode: ReplayMode.normal,
  dateKey: null,
  challengeVersion: null,
  rootSeed: seed,
  resolverVersion: 'shot-resolver-v1',
  catalogFingerprint: 'catalog',
  stageId: 'stage_test',
  patternId: 'pattern_test',
  patternSeed: seed,
  drawCycle: 0,
  drawIndex: seed,
);

class _FaultBackend implements RunStateKeyValueBackend {
  final values = <String, String>{};
  final _failBeforeWrite = <String>{};

  void failBeforeWriteFor(String key) => _failBeforeWrite.add(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    if (_failBeforeWrite.remove(key)) {
      throw StateError('주입된 저장 중단: $key');
    }
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    values.remove(key);
  }
}
