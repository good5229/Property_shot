import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/run/run_state.dart';
import 'package:property_shot/game/run/run_hint_state.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';

void main() {
  test('복제 코어 보상 표식은 단계별 판정과 전역 마이그레이션 판정을 분리한다', () {
    final rewards = {
      stageCloneCoreRewardId('stage_a'),
      legacyStageCloneCoreRewardId,
    };

    expect(hasStageCloneCoreReward(rewards, 'stage_a'), isTrue);
    expect(hasStageCloneCoreReward(rewards, 'stage_b'), isFalse);
    expect(hasAnyStageCloneCoreReward(rewards), isTrue);
    expect(stageCloneCoreRewardStageIds(rewards), {'stage_a'});
  });

  test('모든 RunState 필드는 JSON Map과 문자열을 왕복한다', () {
    final original = _fullState();

    final fromMap = RunState.fromJson(original.toJson());
    final fromString = RunState.fromJsonString(original.toJsonString());

    expect(fromMap.toJson(), original.toJson());
    expect(fromString.toJson(), original.toJson());
    expect(fromString.startedAt.isUtc, isTrue);
    expect(fromString.updatedAt.isUtc, isTrue);
  });

  test('schema 1은 빈 힌트·열쇠 컬렉션을 가진 최신 schema로 명시 이행한다', () {
    final legacy = _state().toJson()
      ..['schemaVersion'] = 1
      ..remove('hintEntitlements')
      ..remove('keyCollections');

    final migrated = RunState.fromJson(legacy);

    expect(migrated.schemaVersion, currentRunStateSchemaVersion);
    expect(migrated.hintEntitlements, isEmpty);
    expect(migrated.keyCollections, isEmpty);
    expect(migrated.toJson()['schemaVersion'], currentRunStateSchemaVersion);
  });

  test('힌트 entitlement와 열쇠 수집은 canonical JSON으로 왕복한다', () {
    final identity = HintIdentity(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      hintVersion: 1,
    );
    final state = _state(
      hintEntitlements: [
        RunHintEntitlement(
          identity: identity,
          sources: const [
            HintEntitlementSource.clearReward,
            HintEntitlementSource.stageKey,
          ],
          unlockedHintLevel: 2,
          consumed: true,
          openedCount: 2,
          failedShotCount: 3,
          failureCountAtFirstOpen: 2,
          acquiredAt: DateTime.utc(2026, 8, 6),
        ),
      ],
      keyCollections: [
        KeyCollectionRecord(
          identity: identity,
          keyId: 'hint_key',
          sourceBallId: 'spent_ball_1',
          shotIndex: 1,
          acquiredAt: DateTime.utc(2026, 8, 6, 0, 1),
        ),
      ],
    );

    final restored = RunState.fromJson(state.toJson());
    expect(restored.toJson(), state.toJson());
    expect(restored.hintEntitlements.single.sources, {
      HintEntitlementSource.clearReward,
      HintEntitlementSource.stageKey,
    });
    expect(restored.hintEntitlements.single.failureCountAtFirstOpen, 2);
  });

  test('schema 2 entitlement는 첫 열람 실패 기준선을 nullable로 이행한다', () {
    final identity = HintIdentity(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      hintVersion: 1,
    );
    final legacy = _state(
      hintEntitlements: [
        RunHintEntitlement(
          identity: identity,
          sources: const [HintEntitlementSource.stageKey],
          consumed: true,
          openedCount: 1,
          failedShotCount: 3,
          acquiredAt: DateTime.utc(2026),
        ),
      ],
    ).toJson()..['schemaVersion'] = 2;
    final entitlement = (legacy['hintEntitlements'] as List).single as Map;
    entitlement.remove('failureCountAtFirstOpen');

    final migrated = RunState.fromJson(legacy);
    expect(migrated.schemaVersion, currentRunStateSchemaVersion);
    expect(migrated.hintEntitlements.single.failureCountAtFirstOpen, isNull);
  });

  test('invalid_hint_entitlement_restore: 현재 카탈로그에 없는 L3 복원은 거부한다', () {
    final json = _state().toJson();
    json['hintEntitlements'] = [
      {
        'identity': {
          'stageId': 'stage_1',
          'patternId': 'pattern_a',
          'hintVersion': 1,
        },
        'sources': ['stage_key'],
        'unlockedHintLevel': 3,
        'consumed': true,
        'openedCount': 3,
        'failedShotCount': 4,
        'failureCountAtFirstOpen': 2,
        'acquiredAt': DateTime.utc(2026).toIso8601String(),
      },
    ];

    expect(() => RunState.fromJson(json), throwsFormatException);
  });

  test('v2 L3 entitlement는 현재 L1-L2 계약에 맞춰 L2로 이관한다', () {
    final legacy = _state().toJson()..['schemaVersion'] = 2;
    legacy['hintEntitlements'] = [
      {
        'identity': {
          'stageId': 'stage_1',
          'patternId': 'pattern_a',
          'hintVersion': 1,
        },
        'sources': ['stage_key'],
        'unlockedHintLevel': 3,
        'consumed': true,
        'openedCount': 3,
        'failedShotCount': 4,
        'acquiredAt': DateTime.utc(2026).toIso8601String(),
      },
    ];

    final migrated = RunState.fromJson(legacy);

    expect(migrated.schemaVersion, currentRunStateSchemaVersion);
    expect(migrated.hintEntitlements.single.unlockedHintLevel, 2);
    expect(migrated.hintEntitlements.single.openedCount, 3);
    expect(migrated.hintEntitlements.single.failureCountAtFirstOpen, isNull);
  });

  test('힌트 열람 상태와 실패 기준선이 모순된 저장값은 복원을 거부한다', () {
    Map<String, dynamic> invalidEntitlement({
      required bool consumed,
      required int openedCount,
      int failedShotCount = 2,
      int? failureCountAtFirstOpen,
    }) {
      final result = <String, dynamic>{
        'identity': {
          'stageId': 'stage_1',
          'patternId': 'pattern_a',
          'hintVersion': 1,
        },
        'sources': ['stage_key'],
        'unlockedHintLevel': 1,
        'consumed': consumed,
        'openedCount': openedCount,
        'failedShotCount': failedShotCount,
        'acquiredAt': DateTime.utc(2026).toIso8601String(),
      };
      if (failureCountAtFirstOpen != null) {
        result['failureCountAtFirstOpen'] = failureCountAtFirstOpen;
      }
      return result;
    }

    for (final entitlement in [
      invalidEntitlement(consumed: false, openedCount: 1),
      invalidEntitlement(consumed: true, openedCount: 0),
      invalidEntitlement(
        consumed: false,
        openedCount: 0,
        failureCountAtFirstOpen: 1,
      ),
      invalidEntitlement(
        consumed: true,
        openedCount: 1,
        failedShotCount: 1,
        failureCountAtFirstOpen: 2,
      ),
    ]) {
      final json = _state().toJson()..['hintEntitlements'] = [entitlement];
      expect(() => RunState.fromJson(json), throwsFormatException);
    }
  });

  test('컬렉션은 생성자 입력과 외부 수정으로부터 방어된다', () {
    final currentDraw = _draw(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      rootSeed: 7,
    );
    final history = <PatternDrawRecord>[
      PatternDrawRecord.fromDraw(currentDraw),
    ];
    final rewards = <String>['reward_a', 'reward_b', 'reward_c'];
    final bags = <String, StageShuffleBagState>{
      'stage_1': currentDraw.nextState,
    };
    final state = _state(
      phase: RunPhase.rewardSelectionPending,
      rewardCandidateSeed: 42,
      patternDrawHistory: history,
      rewardCandidateIds: rewards,
      stageShuffleBags: bags,
    );

    history.clear();
    rewards[0] = 'changed';
    bags.clear();

    expect(state.patternDrawHistory, hasLength(1));
    expect(state.rewardCandidateIds, ['reward_a', 'reward_b', 'reward_c']);
    expect(state.stageShuffleBags.keys, ['stage_1']);
    expect(
      () => state.rewardCandidateIds[0] = 'changed again',
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => state.acquiredRewards.add('new'),
      throwsA(isA<UnsupportedError>()),
    );
  });

  test('phase별 보상 후보 조합과 current pattern을 검증한다', () {
    final base = _state(
      shotInputLog: [
        RunShotInput(
          stageId: 'stage_1',
          patternId: 'pattern_a',
          shotIndex: 0,
          direction: const Vec2(1, 0),
          power: 0.5,
        ),
      ],
    ).toJson();

    expect(
      () => RunState.fromJson({...base, 'phase': 'unknown'}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({...base, 'currentStageId': null}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({...base, 'cloneCoreCount': -1}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({...base, 'rootSeed': -1}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...base,
        'updatedAt': '2026-08-06T00:00:00+09:00',
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...base,
        'shotInputLog': [
          {
            ...((base['shotInputLog'] as List).first as Map),
            'power': double.nan,
          },
        ],
      }),
      throwsA(isA<FormatException>()),
    );

    final pending = {
      ...base,
      'phase': 'reward_selection_pending',
      'rewardCandidateSeed': 42,
      'rewardCandidateIds': ['reward_a', 'reward_b', 'reward_c'],
      'selectedRewardId': null,
    };
    expect(RunState.fromJson(pending).phase, RunPhase.rewardSelectionPending);
    expect(
      () => RunState.fromJson({...pending, 'selectedRewardId': 'reward_a'}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({...pending, 'rewardCandidateIds': []}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...pending,
        'rewardCandidateIds': ['reward_a', 'reward_b'],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...pending,
        'rewardCandidateIds': ['reward_a', 'reward_b', 'reward_c', 'reward_d'],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...pending,
        'phase': 'reward_selection_completed',
        'selectedRewardId': 'reward_a',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('RunState.initial은 소비된 current draw와 다음 bag을 함께 저장한다', () {
    final currentDraw = _draw(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      rootSeed: 7,
    );
    final state = RunState.initial(
      runId: 'run_initial',
      rootSeed: 7,
      resolverVersion: 'resolver-1',
      currentDraw: currentDraw,
      now: DateTime.utc(2026, 8, 6),
    );

    expect(state.currentPatternId, currentDraw.patternId);
    expect(state.currentPatternSeed, currentDraw.patternSeed);
    expect(state.patternDrawHistory, hasLength(1));
    expect(
      state.stageShuffleBags[currentDraw.stageId]!.toJson(),
      currentDraw.nextState.toJson(),
    );
  });

  test('current 또는 next가 history·소비 bag과 불일치하면 거부한다', () {
    final base = _state().toJson();
    expect(
      () => RunState.fromJson({...base, 'currentPatternId': 'pattern_other'}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...base,
        'stageShuffleBags': {
          'stage_1': {
            ...(base['stageShuffleBags'] as Map)['stage_1'] as Map,
            'lastPatternId': 'pattern_other',
          },
        },
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({...base, 'patternDrawHistory': const []}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...base,
        'nextStageId': 'stage_1',
        'nextStagePatternId': 'pattern_a',
        'nextStagePatternSeed': base['currentPatternSeed'],
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('샷 입력은 방향·힘·속성을 재현 가능한 타입으로 보존한다', () {
    final input = RunShotInput(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      patternSeed: 913,
      shotIndex: 3,
      direction: const Vec2(0.3, -0.8),
      power: 0.75,
      equippedTrait: TraitType.heavy,
      traitActions: const [
        RunTraitActionRecord(
          sourceId: 'heavy_stone',
          action: RunTraitAction.copy,
        ),
        RunTraitActionRecord(
          sourceId: 'heavy_stone',
          action: RunTraitAction.transfer,
        ),
      ],
    );

    final restored = RunShotInput.fromJson(input.toJson());
    expect(restored.toJson(), input.toJson());
    expect(restored.equippedTrait, TraitType.heavy);
    expect(restored.patternSeed, 913);
    expect(restored.traitActions, hasLength(2));
    expect(restored.traitActions.first.sourceId, 'heavy_stone');
    expect(restored.traitActions.first.action, RunTraitAction.copy);
    expect(restored.traitActions.last.action, RunTraitAction.transfer);
  });

  test('구형 샷 입력에는 새 속성 행동 필드가 없어도 된다', () {
    final restored = RunShotInput.fromJson({
      'stageId': 'stage_1',
      'patternId': 'pattern_a',
      'shotIndex': 0,
      'direction': const Vec2(1, 0).toJson(),
      'power': 0.4,
      'equippedTrait': null,
    });

    expect(restored.patternSeed, isNull);
    expect(restored.traitActions, isEmpty);
  });

  test('속성 원본과 행동 종류가 한쪽만 있으면 샷 입력을 거부한다', () {
    expect(
      () => RunShotInput.fromJson({
        'stageId': 'stage_1',
        'patternId': 'pattern_a',
        'shotIndex': 0,
        'direction': const Vec2(1, 0).toJson(),
        'power': 0.4,
        'equippedTrait': 'heavy',
        'traitSourceId': 'heavy_stone',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('추첨 이력과 다르거나 순번이 끊긴 샷 로그는 거부한다', () {
    final base = _state().toJson();
    final shot = RunShotInput(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      patternSeed: base['currentPatternSeed'] as int,
      shotIndex: 0,
      direction: const Vec2(1, 0),
      power: 0.5,
    ).toJson();

    expect(
      () => RunState.fromJson({
        ...base,
        'shotInputLog': [
          {...shot, 'patternSeed': 123456789},
        ],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => RunState.fromJson({
        ...base,
        'shotInputLog': [
          {...shot, 'shotIndex': 1},
        ],
      }),
      throwsA(isA<FormatException>()),
    );
  });
}

RunState _fullState() {
  return _state(
    phase: RunPhase.rewardSelectionCompleted,
    nextDraw: _draw(stageId: 'stage_2', patternId: 'pattern_b', rootSeed: 7),
    rewardCandidateSeed: 42,
    rewardCandidateIds: ['reward_a', 'reward_b', 'reward_c'],
    selectedRewardId: 'reward_b',
    acquiredRewards: ['reward_b'],
    cloneCoreCount: 2,
    shotsPerStage: {'stage_1': 3},
    chainScoresPerStage: {'stage_1': 180},
    optionalChallenges: {'stage_1:no_copy': true},
    totalScore: 180,
    replayReferences: {'stage_1': 'replay_1'},
    shotInputLog: [
      RunShotInput(
        stageId: 'stage_1',
        patternId: 'pattern_a',
        shotIndex: 0,
        direction: const Vec2(1, -1),
        power: 1,
        equippedTrait: TraitType.heavy,
      ),
    ],
  );
}

RunState _state({
  int rootSeed = 7,
  RunPhase phase = RunPhase.playing,
  StagePatternDraw? nextDraw,
  Iterable<PatternDrawRecord>? patternDrawHistory,
  Map<String, StageShuffleBagState>? stageShuffleBags,
  int? rewardCandidateSeed,
  Iterable<String> rewardCandidateIds = const [],
  String? selectedRewardId,
  Iterable<String> acquiredRewards = const [],
  int cloneCoreCount = 0,
  Map<String, int> shotsPerStage = const {},
  Map<String, int> chainScoresPerStage = const {},
  Map<String, bool> optionalChallenges = const {},
  int totalScore = 0,
  Map<String, String> replayReferences = const {},
  Iterable<RunShotInput> shotInputLog = const [],
  Iterable<RunHintEntitlement> hintEntitlements = const [],
  Iterable<KeyCollectionRecord> keyCollections = const [],
}) {
  final currentDraw = _draw(
    stageId: 'stage_1',
    patternId: 'pattern_a',
    rootSeed: rootSeed,
  );
  final history =
      patternDrawHistory?.toList() ??
      <PatternDrawRecord>[PatternDrawRecord.fromDraw(currentDraw)];
  if (patternDrawHistory == null) {
    if (nextDraw != null) {
      history.add(PatternDrawRecord.fromDraw(nextDraw));
    }
  }
  final bags = <String, StageShuffleBagState>{'stage_1': currentDraw.nextState};
  if (stageShuffleBags != null) {
    bags
      ..clear()
      ..addAll(stageShuffleBags);
  } else if (nextDraw != null) {
    bags[nextDraw.stageId] = nextDraw.nextState;
  }
  return RunState(
    schemaVersion: currentRunStateSchemaVersion,
    runId: 'run_1',
    rootSeed: rootSeed,
    resolverVersion: 'resolver-1',
    phase: phase,
    currentStageId: 'stage_1',
    currentPatternId: currentDraw.patternId,
    currentPatternSeed: currentDraw.patternSeed,
    nextStageId: nextDraw?.stageId,
    nextStagePatternId: nextDraw?.patternId,
    nextStagePatternSeed: nextDraw?.patternSeed,
    patternDrawHistory: history,
    stageShuffleBags: bags,
    rewardCandidateSeed: rewardCandidateSeed,
    rewardCandidateIds: rewardCandidateIds,
    selectedRewardId: selectedRewardId,
    acquiredRewards: acquiredRewards,
    cloneCoreCount: cloneCoreCount,
    shotsPerStage: shotsPerStage,
    chainScoresPerStage: chainScoresPerStage,
    optionalChallenges: optionalChallenges,
    totalScore: totalScore,
    replayReferences: replayReferences,
    shotInputLog: shotInputLog,
    hintEntitlements: hintEntitlements,
    keyCollections: keyCollections,
    startedAt: DateTime.utc(2026, 8, 6, 0, 0),
    updatedAt: DateTime.utc(2026, 8, 6, 0, 1),
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
