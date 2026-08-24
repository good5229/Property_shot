import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/replay/replay.dart';
import 'package:property_shot/game/run/run_reward.dart';

const _fingerprintA =
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _fingerprintB =
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

void main() {
  test('v1 문서는 모든 결정론 필드를 canonical JSON으로 왕복한다', () {
    final source = _document(
      mode: ReplayMode.dailyPractice,
      dateKey: '2026-08-08',
      challengeVersion: 'daily-v1',
      rootSeed: 0xffffffff,
      patternSeed: 0x80000000,
      recoveredPastBallIds: const ['ball_0'],
      acquiredRewardIds: const ['reward_b', 'reward_a'],
      consumedRewardUses: const [
        ReplayRewardUse(rewardId: 'reward_a', useKey: 'stage_2:attempt_1'),
      ],
      pendingTraitActions: const [
        ReplayTraitAction(
          sourceId: 'pending_stone',
          action: ReplayTraitActionKind.copy,
        ),
      ],
      shots: [
        ReplayShot(
          shotIndex: 0,
          ballId: 'ball_0',
          direction: const ReplayDirection(x: 707107, y: -707107),
          power: 875000,
          rawDirection: const ReplayDirection(x: 700000, y: -714143),
          rawPower: 869000,
          assistKind: ShotAssistKind.targetSnap,
          assistTargetId: 'gate_entry',
          holeForgivenessMilli: 6000,
          equippedTrait: TraitType.bouncy,
          traitActions: const [
            ReplayTraitAction(
              sourceId: 'stone',
              action: ReplayTraitActionKind.transfer,
            ),
          ],
        ),
      ],
      fingerprints: const [_fingerprintA],
    );

    final canonical = source.toCanonicalJson();
    final restored = ReplayDocument.fromCanonicalJson(canonical);

    expect(restored.toCanonicalJson(), canonical);
    expect(restored.inputEncodingVersion, replayInputEncodingVersion);
    expect(restored.outcomeFingerprintVersion, 'sha256-v1');
    expect(restored.rootSeed, 0xffffffff);
    expect(restored.patternSeed, 0x80000000);
    expect(restored.initialCloneCoreRewarded, isTrue);
    expect(restored.recoveredPastBallIds, ['ball_0']);
    expect(restored.acquiredRewardIds, ['reward_a', 'reward_b']);
    expect(restored.consumedRewardUseKeys, ['stage_2:attempt_1']);
    expect(restored.shots.single.ballId, 'ball_0');
    expect(restored.shots.single.equippedTrait, TraitType.bouncy);
    expect(restored.shots.single.powerValue, closeTo(0.875, 0.000001));
    expect(restored.shots.single.rawPowerValue, closeTo(0.869, 0.000001));
    expect(restored.shots.single.assistKind, ShotAssistKind.targetSnap);
    expect(restored.shots.single.assistTargetId, 'gate_entry');
    expect(restored.shots.single.holeForgivenessRadius, 6);
    expect(canonical, isNot(contains('runId')));
    expect(canonical, isNot(contains('timestamp')));
    expect(canonical, isNot(contains('frame')));
    expect(canonical, isNot(contains('screen')));
  });

  test('보정 증거의 비정상 값과 알 수 없는 종류는 거부한다', () {
    final base = _shot(0, 'ball_0').toJson();
    for (final invalid in [
      {...base, 'rawPower': -1},
      {...base, 'rawPower': ReplayFixedPoint.scale + 1},
      {...base, 'assistKind': 'magic'},
      {...base, 'assistTargetId': '홀 id'},
      {...base, 'holeForgivenessMilli': 16001},
      {
        ...base,
        'rawDirection': const {'x': 0, 'y': 0},
      },
    ]) {
      expect(
        () => ReplayShot.fromJson(invalid),
        throwsA(isA<ReplayFailure>()),
        reason: invalid.toString(),
      );
    }
  });

  test('normal은 dateKey/challengeVersion이 null이고 daily는 둘 다 요구한다', () {
    expect(
      () => _document(mode: ReplayMode.normal, dateKey: '2026-08-08'),
      throwsA(_failure(ReplayFailureCode.invalidDateChallenge)),
    );
    expect(
      () => _document(mode: ReplayMode.dailyOfficial),
      throwsA(_failure(ReplayFailureCode.invalidDateChallenge)),
    );
    expect(
      () => _document(
        mode: ReplayMode.dailyOfficial,
        dateKey: '2026-02-30',
        challengeVersion: 'daily-v1',
      ),
      throwsA(_failure(ReplayFailureCode.invalidDateChallenge)),
    );
    expect(
      _document(
        mode: ReplayMode.dailyOfficial,
        dateKey: '2026-08-08',
        challengeVersion: 'daily-v1',
      ).mode,
      ReplayMode.dailyOfficial,
    );
  });

  test('발사 64개와 pending 포함 속성 행동 128개 경계를 고정한다', () {
    final shots = List.generate(
      replayMaxShots,
      (index) => ReplayShot(
        shotIndex: index,
        ballId: 'ball_$index',
        direction: const ReplayDirection(x: 1000000, y: 0),
        power: 1,
        traitActions: const [
          ReplayTraitAction(
            sourceId: 'source_a',
            action: ReplayTraitActionKind.copy,
          ),
          ReplayTraitAction(
            sourceId: 'source_b',
            action: ReplayTraitActionKind.transfer,
          ),
        ],
      ),
    );
    expect(
      _document(
        shots: shots,
        fingerprints: List.filled(replayMaxShots, _fingerprintA),
      ).shots,
      hasLength(64),
    );
    expect(
      () => _document(
        shots: [...shots, shots.first],
        fingerprints: List.filled(65, _fingerprintA),
      ),
      throwsA(_failure(ReplayFailureCode.tooManyShots)),
    );
    expect(
      () => _document(
        pendingTraitActions: List.generate(
          replayMaxTraitActions + 1,
          (_) => const ReplayTraitAction(
            sourceId: 'source',
            action: ReplayTraitActionKind.copy,
          ),
        ),
      ),
      throwsA(_failure(ReplayFailureCode.tooManyTraitActions)),
    );
  });

  test('ballId는 필수·고유하고 shotIndex는 0부터 연속이어야 한다', () {
    expect(
      () => ReplayShot(
        shotIndex: 0,
        ballId: '공_0',
        direction: const ReplayDirection(x: 1, y: 0),
        power: 1,
      ),
      throwsA(_failure(ReplayFailureCode.invalidBallHistory)),
    );
    expect(
      () => _document(
        shots: [_shot(1, 'ball_1')],
        fingerprints: const [_fingerprintA],
      ),
      throwsA(_failure(ReplayFailureCode.invalidShotSequence)),
    );
    expect(
      () => _document(
        shots: [_shot(0, 'same_ball'), _shot(1, 'same_ball')],
        fingerprints: const [_fingerprintA, _fingerprintB],
      ),
      throwsA(_failure(ReplayFailureCode.invalidBallHistory)),
    );
  });

  test('회수 공은 앞선 shot ballId 부분집합이며 동적 snapshot을 저장하지 않는다', () {
    final document = _document(
      shots: [_shot(0, 'ball_0'), _shot(1, 'ball_1')],
      recoveredPastBallIds: const ['ball_0'],
      fingerprints: const [_fingerprintA, _fingerprintB],
    );
    final canonical = document.toCanonicalJson();

    // 위치·속도는 저장하지 않는다. stage 초기 상태부터 이 두 shot을 순서대로
    // 재생해야 ball_0의 동적 상태를 결정론적으로 복원할 수 있다.
    expect(document.shots.map((shot) => shot.ballId), ['ball_0', 'ball_1']);
    expect(canonical, isNot(contains('position')));
    expect(canonical, isNot(contains('velocity')));
    expect(
      () => _document(
        shots: [_shot(0, 'ball_0')],
        recoveredPastBallIds: const ['unknown_ball'],
        fingerprints: const [_fingerprintA],
      ),
      throwsA(_failure(ReplayFailureCode.invalidBallHistory)),
    );
  });

  test('보상 ID와 소비 use key는 bounded 고유 ASCII 목록이다', () {
    final document = _document(
      acquiredRewardIds: const ['reward_z', 'reward_a'],
      consumedRewardUses: const [
        ReplayRewardUse(rewardId: 'reward_z', useKey: 'stage_2:attempt_1'),
        ReplayRewardUse(rewardId: 'reward_a', useKey: 'stage_1:attempt_1'),
      ],
    );
    expect(document.acquiredRewardIds, ['reward_a', 'reward_z']);
    expect(document.consumedRewardUseKeys, [
      'stage_1:attempt_1',
      'stage_2:attempt_1',
    ]);
    expect(
      () => _document(acquiredRewardIds: const ['reward_a', 'reward_a']),
      throwsA(_failure(ReplayFailureCode.invalidRewardState)),
    );
    expect(
      () => _document(
        acquiredRewardIds: const ['reward_a'],
        consumedRewardUses: const [
          ReplayRewardUse(rewardId: 'reward_a', useKey: 'stage|첫사용'),
        ],
      ),
      throwsA(_failure(ReplayFailureCode.invalidRewardState)),
    );
    expect(
      () => _document(
        acquiredRewardIds: const ['reward_a'],
        consumedRewardUses: const [
          ReplayRewardUse(rewardId: 'reward_a', useKey: 'stage_1'),
          ReplayRewardUse(rewardId: 'reward_a', useKey: 'stage_1'),
        ],
      ),
      throwsA(_failure(ReplayFailureCode.invalidRewardState)),
    );
    expect(
      () => _document(
        acquiredRewardIds: const ['reward_a'],
        consumedRewardUses: const [
          ReplayRewardUse(rewardId: 'reward_b', useKey: 'stage_1'),
        ],
      ),
      throwsA(_failure(ReplayFailureCode.invalidRewardState)),
    );
    expect(
      () => _document(
        acquiredRewardIds: List.generate(129, (index) => 'reward_$index'),
      ),
      throwsA(_failure(ReplayFailureCode.invalidRewardState)),
    );
  });

  test('실제 RunState reward record와 stageId|attempt use key를 왕복한다', () {
    const rewardId = runRewardSpentBallRecoveryId;
    final selectionRecordId = runRewardSelectionRecordId(
      stageId: 'stage_heavy',
      patternSeed: 9,
      rewardId: rewardId,
    );
    const useKey = 'stage_heavy|2';
    final useRecordId = runRewardUseRecordId(selectionRecordId, useKey);
    final source = _document(
      acquiredRewardIds: [rewardId, selectionRecordId, useRecordId],
      consumedRewardUses: const [
        ReplayRewardUse(rewardId: rewardId, useKey: useKey),
      ],
    );

    final restored = ReplayDocument.fromCanonicalJson(source.toCanonicalJson());
    expect(restored.acquiredRewardIds, contains(useRecordId));
    expect(restored.consumedRewardUses.single.rewardId, rewardId);
    expect(restored.consumedRewardUses.single.useKey, useKey);
  });

  test('equippedTrait는 TraitType 폐쇄 집합으로 직렬화한다', () {
    final document = _document(
      shots: [
        ReplayShot(
          shotIndex: 0,
          ballId: 'ball_0',
          direction: const ReplayDirection(x: 1, y: 0),
          power: 1,
          equippedTrait: TraitType.sharp,
        ),
      ],
      fingerprints: const [_fingerprintA],
    );
    final json = jsonDecode(document.toCanonicalJson()) as Map<String, dynamic>;
    expect((json['shots'] as List).single['equippedTrait'], 'sharp');
    (json['shots'] as List).single['equippedTrait'] = 'unknown';
    expect(
      () => ReplayDocument.fromJson(json),
      throwsA(_failure(ReplayFailureCode.invalidDocument)),
    );
  });

  test('모든 정수는 32비트 seed·현실적 카운터 상한을 지킨다', () {
    expect(
      () => _document(rootSeed: 0x100000000),
      throwsA(_failure(ReplayFailureCode.invalidSeed)),
    );
    expect(
      () => _document(drawCycle: replayMaxDrawCounter + 1),
      throwsA(_failure(ReplayFailureCode.integerOutOfRange)),
    );
    expect(
      () => _document(drawIndex: replayMaxDrawCounter + 1),
      throwsA(_failure(ReplayFailureCode.integerOutOfRange)),
    );
    expect(
      () =>
          _document(initialCloneCoreCount: replayMaxInitialCloneCoreCount + 1),
      throwsA(_failure(ReplayFailureCode.integerOutOfRange)),
    );
    expect(
      () => ReplayShot(
        shotIndex: replayMaxShots,
        ballId: 'ball_64',
        direction: const ReplayDirection(x: 1, y: 0),
        power: 1,
      ),
      throwsA(_failure(ReplayFailureCode.invalidShotSequence)),
    );
  });

  test('원문 16KiB·raw list 경계를 객체 변환 전에 거부한다', () {
    expect(
      () => ReplayDocument.fromCanonicalJson(
        'x' * (replayDocumentMaxCanonicalBytes + 1),
      ),
      throwsA(_failure(ReplayFailureCode.payloadTooLarge)),
    );

    final tooManyShots = _jsonOf(_document());
    tooManyShots['shots'] = List.filled(replayMaxShots + 1, 1);
    expect(
      () => ReplayDocument.fromJson(tooManyShots),
      throwsA(_failure(ReplayFailureCode.tooManyShots)),
    );

    final tooManyActions = _jsonOf(_document());
    tooManyActions['pendingTraitActions'] = List.filled(
      replayMaxTraitActions + 1,
      1,
    );
    expect(
      () => ReplayDocument.fromJson(tooManyActions),
      throwsA(_failure(ReplayFailureCode.tooManyTraitActions)),
    );

    final tooManyRewardUses = _jsonOf(_document());
    tooManyRewardUses['consumedRewardUses'] = List.filled(
      replayMaxRewardStateEntries + 1,
      1,
    );
    expect(
      () => ReplayDocument.fromJson(tooManyRewardUses),
      throwsA(_failure(ReplayFailureCode.invalidRewardState)),
    );

    final tooManyRecovered = _jsonOf(_document());
    tooManyRecovered['recoveredPastBallIds'] = List.filled(
      replayMaxRecoveredPastBalls + 1,
      1,
    );
    expect(
      () => ReplayDocument.fromJson(tooManyRecovered),
      throwsA(_failure(ReplayFailureCode.invalidBallHistory)),
    );
  });

  test('canonical 원문과 unknown field를 엄격히 거부한다', () {
    final canonical = _document().toCanonicalJson();
    expect(
      () => ReplayDocument.fromCanonicalJson(' $canonical'),
      throwsA(_failure(ReplayFailureCode.invalidDocument)),
    );

    final json = _jsonOf(_document())..['runId'] = 'private_run';
    expect(
      () => ReplayDocument.fromJson(json),
      throwsA(_failure(ReplayFailureCode.invalidDocument)),
    );
  });

  test('outcome fingerprint는 sha256-v1과 소문자 64 hex로 고정한다', () {
    expect(
      replayOutcomeFingerprint('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
    expect(
      () => _document(outcomeFingerprintVersion: 'sha256-v2'),
      throwsA(_failure(ReplayFailureCode.unsupportedOutcomeFingerprintVersion)),
    );
    expect(
      () => _document(
        shots: [_shot(0, 'ball_0')],
        fingerprints: const ['deadbeef'],
      ),
      throwsA(_failure(ReplayFailureCode.invalidFingerprint)),
    );
  });

  test('ID와 버전 문자열은 개인정보를 담기 어려운 안전 문자만 허용한다', () {
    expect(
      () => _document(stageId: 'stage/user@example.com'),
      throwsA(_failure(ReplayFailureCode.invalidReference)),
    );
    expect(
      () => _document(challengeVersion: '오늘의도전'),
      throwsA(_failure(ReplayFailureCode.invalidDateChallenge)),
    );
    expect(
      () => _document(
        pendingTraitActions: const [
          ReplayTraitAction(
            sourceId: 'source 사용자',
            action: ReplayTraitActionKind.copy,
          ),
        ],
      ),
      throwsA(_failure(ReplayFailureCode.invalidDocument)),
    );
  });
}

ReplayShot _shot(int shotIndex, String ballId) => ReplayShot(
  shotIndex: shotIndex,
  ballId: ballId,
  direction: const ReplayDirection(x: 1, y: 0),
  power: 1,
);

ReplayDocument _document({
  ReplayMode mode = ReplayMode.normal,
  String? dateKey,
  String? challengeVersion,
  String outcomeFingerprintVersion = replayOutcomeFingerprintVersion,
  int rootSeed = 7,
  int patternSeed = 9,
  int drawCycle = 0,
  int drawIndex = 1,
  int initialCloneCoreCount = 1,
  String stageId = 'stage_heavy',
  Iterable<String> recoveredPastBallIds = const [],
  Iterable<String> acquiredRewardIds = const [],
  Iterable<ReplayRewardUse> consumedRewardUses = const [],
  Iterable<ReplayTraitAction> pendingTraitActions = const [],
  Iterable<ReplayShot> shots = const [],
  Iterable<String> fingerprints = const [],
}) {
  final actualShots = shots.toList();
  return ReplayDocument(
    outcomeFingerprintVersion: outcomeFingerprintVersion,
    mode: mode,
    dateKey: dateKey,
    challengeVersion: challengeVersion,
    rootSeed: rootSeed,
    resolverVersion: 'shot-resolver-v1',
    catalogFingerprint: 'catalog-v1-fingerprint',
    stageId: stageId,
    patternId: 'stage_heavy_01',
    patternSeed: patternSeed,
    drawCycle: drawCycle,
    drawIndex: drawIndex,
    initialCloneCoreCount: initialCloneCoreCount,
    initialCloneCoreRewarded: true,
    recoveredPastBallIds: recoveredPastBallIds,
    acquiredRewardIds: acquiredRewardIds,
    consumedRewardUses: consumedRewardUses,
    pendingTraitActions: pendingTraitActions,
    shots: actualShots,
    outcomeFingerprints: fingerprints.isEmpty
        ? List.filled(actualShots.length, _fingerprintA)
        : fingerprints,
  );
}

Map<String, dynamic> _jsonOf(ReplayDocument document) =>
    jsonDecode(document.toCanonicalJson()) as Map<String, dynamic>;

Matcher _failure(ReplayFailureCode code) {
  return predicate<ReplayFailure>(
    (failure) => failure.code == code,
    'ReplayFailure(${code.stableName})',
  );
}
