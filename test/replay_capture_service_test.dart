import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/replay/replay_capture_service.dart';
import 'package:property_shot/game/replay/replay_document.dart';
import 'package:property_shot/game/replay/replay_failure.dart';
import 'package:property_shot/game/run/run_reward.dart';
import 'package:property_shot/game/run/run_state.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';

void main() {
  test('RunState의 현재 패턴과 샷을 ReplayDocument로 캡처하고 재생한다', () async {
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 17,
      fixedRunId: 'replay-test-run',
      now: () => DateTime.utc(2026, 8, 8),
    );
    final draw = await session.selectStage('stage_heavy');
    final source = draw.pattern.objects.firstWhere(
      (object) => object.traits.isNotEmpty,
    );
    await session.recordTraitAction(
      sourceId: source.id,
      action: RunTraitAction.transfer,
    );
    await session.recordShot(
      input: ShotInput(
        direction: const Vec2(1, 0),
        power: 0.7,
        equippedTrait: source.traits.first,
        rawDirection: const Vec2(0.9998, 0.02),
        rawPower: 0.693,
        assistKind: ShotAssistKind.targetSnap,
        assistTargetId: source.id,
        holeForgivenessRadius: 6,
      ),
    );
    await session.recordShot(
      input: const ShotInput(direction: Vec2(-0.8, 0.6), power: 0.4),
    );

    const service = ReplayCaptureService();
    final document = service.capture(
      runState: session.state!,
      catalog: generatedStageCatalog,
    );
    final replayed = service.playback(
      document,
      generatedStageCatalog,
      expectedRunState: session.state,
    );

    expect(document.stageId, session.state!.currentStageId);
    expect(document.patternId, session.state!.currentPatternId);
    expect(document.patternSeed, session.state!.currentPatternSeed);
    expect(document.shots, hasLength(2));
    expect(document.shots.first.rawDirection, isNotNull);
    expect(document.shots.first.rawPowerValue, closeTo(0.693, 0.000001));
    expect(document.shots.first.assistKind, ShotAssistKind.targetSnap);
    expect(document.shots.first.assistTargetId, source.id);
    expect(document.shots.first.holeForgivenessRadius, 6);
    expect(document.outcomeFingerprints, everyElement(hasLength(64)));
    expect(replayed.shotResults, hasLength(2));
    expect(replayed.fingerprints, document.outcomeFingerprints);
    expect(replayed.finalState.shotCount, 2);
  });

  test('같은 리플레이를 100회 반복 재생해도 지문과 문서가 변하지 않는다', () async {
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 170,
      fixedRunId: 'replay-stress-run',
      now: () => DateTime.utc(2026, 8, 8),
    );
    await session.selectStage('stage_heavy');
    await session.recordShot(
      input: const ShotInput(direction: Vec2(1, 0), power: 0.7),
    );
    const service = ReplayCaptureService();
    final document = service.capture(
      runState: session.state!,
      catalog: generatedStageCatalog,
    );
    final canonicalBefore = replayCanonicalJson(document.toJson());

    for (var replay = 0; replay < 100; replay++) {
      final result = service.playback(
        document,
        generatedStageCatalog,
        expectedRunState: session.state,
      );
      expect(result.fingerprints, document.outcomeFingerprints);
      expect(result.finalState.shotCount, 1);
    }

    expect(replayCanonicalJson(document.toJson()), canonicalBefore);
  });

  test('resolver 버전 불일치와 catalog fingerprint 불일치를 조용히 허용하지 않는다', () async {
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 18,
      fixedRunId: 'replay-version-test',
    );
    await session.selectStage('stage_heavy');
    const service = ReplayCaptureService();
    final document = service.capture(
      runState: session.state!,
      catalog: generatedStageCatalog,
    );

    expect(
      () => const ReplayCaptureService(
        resolverVersion: 'shot-resolver-v2',
      ).playback(document, generatedStageCatalog),
      throwsA(_failure(ReplayFailureCode.resolverVersionMismatch)),
    );
    final altered = document.toJson()..['catalogFingerprint'] = 'other-catalog';
    final alteredDocument = ReplayDocument.fromJson(altered);
    expect(
      () => service.playback(alteredDocument, generatedStageCatalog),
      throwsA(_failure(ReplayFailureCode.catalogFingerprintMismatch)),
    );
  });

  test('기대 런과 pattern seed가 다르면 명시적인 오류 코드로 거부한다', () async {
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 19,
      fixedRunId: 'replay-seed-test',
    );
    await session.selectStage('stage_heavy');
    const service = ReplayCaptureService();
    final document = service.capture(
      runState: session.state!,
      catalog: generatedStageCatalog,
    );
    final changedSeed = (session.state!.currentPatternSeed! + 1) & 0xffffffff;
    final alteredJson = document.toJson()..['patternSeed'] = changedSeed;
    final alteredDocument = ReplayDocument.fromJson(alteredJson);

    expect(
      () => service.playback(
        alteredDocument,
        generatedStageCatalog,
        expectedRunState: session.state,
      ),
      throwsA(_failure(ReplayFailureCode.patternSeedMismatch)),
    );
  });

  test('한글 보상 사용 키는 안전한 결정론 토큰으로 캡처한다', () async {
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 20,
      fixedRunId: 'replay-reward-test',
    );
    await session.selectStage('stage_heavy');
    final state = session.state!;
    final selection = runRewardSelectionRecordId(
      stageId: state.currentStageId!,
      patternSeed: state.currentPatternSeed!,
      rewardId: runRewardFirstImpactGuideId,
    );
    final json = state.toJson()
      ..['acquiredRewards'] = [
        selection,
        runRewardUseRecordId(selection, '첫 충돌 안내 사용'),
      ];

    final document = const ReplayCaptureService().capture(
      runState: RunState.fromJson(json),
      catalog: generatedStageCatalog,
    );

    expect(document.acquiredRewardIds, [runRewardFirstImpactGuideId]);
    expect(document.consumedRewardUses, hasLength(1));
    expect(document.consumedRewardUses.single.useKey, startsWith('sha256_'));
  });

  test('회수 시점이 없는 과거 공 보상 기록은 임의 재생하지 않는다', () async {
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 21,
      fixedRunId: 'replay-recovery-test',
    );
    await session.selectStage('stage_heavy');
    final state = session.state!;
    final selection = runRewardSelectionRecordId(
      stageId: state.currentStageId!,
      patternSeed: state.currentPatternSeed!,
      rewardId: runRewardSpentBallRecoveryId,
    );
    final json = state.toJson()
      ..['acquiredRewards'] = [
        selection,
        runRewardUseRecordId(
          selection,
          '${state.currentStageId}|0|spent_ball_1',
        ),
      ];

    expect(
      () => const ReplayCaptureService().capture(
        runState: RunState.fromJson(json),
        catalog: generatedStageCatalog,
      ),
      throwsA(_failure(ReplayFailureCode.unsupportedBetweenShotState)),
    );
  });
}

Matcher _failure(ReplayFailureCode code) =>
    isA<ReplayFailure>().having((failure) => failure.code, 'code', code);
