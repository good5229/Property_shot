import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/expedition/expedition_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  const stages = [
    'stage_heavy',
    'stage_bouncy',
    'stage_chain_gate',
    'stage_balloon',
  ];

  test('탐사 계약은 정확히 세 개의 서로 다른 단계를 요구한다', () {
    expect(
      () => ExpeditionContractProgress(
        id: 'bad',
        type: ExpeditionContractType.discovery,
        stageIds: const ['a', 'b'],
      ),
      throwsArgumentError,
    );
    expect(
      () => ExpeditionContractProgress(
        id: 'bad',
        type: ExpeditionContractType.discovery,
        stageIds: const ['a', 'a', 'b'],
      ),
      throwsArgumentError,
    );
  });

  test('발견·정밀·연쇄·창의 목표는 서로 다른 성취를 판정한다', () {
    ExpeditionContractProgress progress(ExpeditionContractType type) =>
        ExpeditionContractProgress(
          id: type.name,
          type: type,
          stageIds: stages.take(3),
        );

    const outcome = ExpeditionStageOutcome(
      stageId: 'stage_heavy',
      shotCount: 3,
      parShots: 2,
      discoveryCount: 2,
      gimmickCount: 3,
      chainScore: 1100,
    );
    expect(
      progress(ExpeditionContractType.discovery).goalAchieved(outcome),
      isTrue,
    );
    expect(
      progress(ExpeditionContractType.precision).goalAchieved(outcome),
      isFalse,
    );
    expect(
      progress(ExpeditionContractType.chain).goalAchieved(outcome),
      isTrue,
    );
    expect(
      progress(ExpeditionContractType.creative).goalAchieved(outcome),
      isFalse,
    );
    expect(
      progress(ExpeditionContractType.creative).goalAchieved(
        const ExpeditionStageOutcome(
          stageId: 'stage_heavy',
          shotCount: 5,
          parShots: 2,
          discoveryCount: 0,
          gimmickCount: 1,
          chainScore: 1400,
        ),
      ),
      isTrue,
    );
  });

  test('시작·기록·재실행 복원은 별도 저장 키에서 유지된다', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = ExpeditionContractStore(preferences);
    final started = await store.start(
      type: ExpeditionContractType.precision,
      startIndex: 1,
      allStageIds: stages,
    );
    expect(started.stageIds, stages.skip(1).toList());

    await store.record(
      const ExpeditionStageOutcome(
        stageId: 'stage_bouncy',
        shotCount: 2,
        parShots: 2,
        discoveryCount: 0,
        gimmickCount: 0,
        chainScore: 0,
      ),
    );
    final restored = await ExpeditionContractStore(preferences).load();
    expect(restored?.completedStageIds, {'stage_bouncy'});
    expect(restored?.achievedStageIds, {'stage_bouncy'});
    expect(preferences.getKeys(), {ExpeditionContractStore.storageKey});
  });

  test('중복·계약 밖 결과는 진행도를 늘리지 않는다', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = ExpeditionContractStore(preferences);
    await store.start(
      type: ExpeditionContractType.discovery,
      startIndex: 0,
      allStageIds: stages,
    );
    const outcome = ExpeditionStageOutcome(
      stageId: 'stage_heavy',
      shotCount: 4,
      parShots: 2,
      discoveryCount: 1,
      gimmickCount: 1,
      chainScore: 0,
    );
    await store.record(outcome);
    await store.record(outcome);
    await store.record(
      const ExpeditionStageOutcome(
        stageId: 'outside',
        shotCount: 1,
        parShots: 1,
        discoveryCount: 3,
        gimmickCount: 5,
        chainScore: 2000,
      ),
    );
    final restored = await store.load();
    expect(restored?.completedCount, 1);
    expect(restored?.achievedCount, 0);
  });

  test('손상 데이터는 제거하고 안전하게 빈 상태로 복원한다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ExpeditionContractStore.storageKey: '{bad json',
    });
    final preferences = await SharedPreferences.getInstance();
    final store = ExpeditionContractStore(preferences);
    expect(await store.load(), isNull);
    expect(
      preferences.containsKey(ExpeditionContractStore.storageKey),
      isFalse,
    );
  });

  test('공유 코드는 목표와 세 단계만 보존하고 진행도는 새로 시작한다', () {
    final progress = ExpeditionContractProgress(
      id: 'source',
      type: ExpeditionContractType.chain,
      stageIds: stages.take(3),
      completedStageIds: const {'stage_heavy'},
      achievedStageIds: const {'stage_heavy'},
    );
    final code = ExpeditionShareCodec.encode(progress);
    final decoded = ExpeditionShareCodec.decode(code);
    expect(code, startsWith(ExpeditionShareCodec.prefix));
    expect(decoded.type, ExpeditionContractType.chain);
    expect(decoded.stageIds, stages.take(3));
    expect(decoded.completedCount, 0);
    expect(decoded.achievedCount, 0);
  });

  test('손상되거나 알 수 없는 단계가 있는 공유 코드를 거부한다', () async {
    final progress = ExpeditionContractProgress(
      id: 'source',
      type: ExpeditionContractType.discovery,
      stageIds: stages.take(3),
    );
    final code = ExpeditionShareCodec.encode(progress);
    expect(
      () =>
          ExpeditionShareCodec.decode('${code.substring(0, code.length - 1)}0'),
      throwsFormatException,
    );
    final preferences = await SharedPreferences.getInstance();
    final store = ExpeditionContractStore(preferences);
    expect(
      () => store.importCode(code, knownStageIds: const {'stage_heavy'}),
      throwsFormatException,
    );
  });
}
