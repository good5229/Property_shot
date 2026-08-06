import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/run/run_state.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';

void main() {
  test('모든 RunState 필드는 JSON Map과 문자열을 왕복한다', () {
    final original = _fullState();

    final fromMap = RunState.fromJson(original.toJson());
    final fromString = RunState.fromJsonString(original.toJsonString());

    expect(fromMap.toJson(), original.toJson());
    expect(fromString.toJson(), original.toJson());
    expect(fromString.startedAt.isUtc, isTrue);
    expect(fromString.updatedAt.isUtc, isTrue);
  });

  test('컬렉션은 생성자 입력과 외부 수정으로부터 방어된다', () {
    final history = <PatternDrawRecord>[
      PatternDrawRecord(
        stageId: 'stage_1',
        patternId: 'pattern_a',
        patternSeed: 1,
        cycle: 0,
        drawIndex: 0,
      ),
    ];
    final rewards = <String>['reward_a'];
    final bags = <String, StageShuffleBagState>{
      'stage_1': StageShuffleBagState.initial('stage_1'),
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
    expect(state.rewardCandidateIds, ['reward_a']);
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
      'rewardCandidateIds': ['reward_a', 'reward_b'],
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
  });

  test('샷 입력은 방향·힘·속성을 재현 가능한 타입으로 보존한다', () {
    final input = RunShotInput(
      stageId: 'stage_1',
      patternId: 'pattern_a',
      shotIndex: 3,
      direction: const Vec2(0.3, -0.8),
      power: 0.75,
      equippedTrait: TraitType.heavy,
    );

    final restored = RunShotInput.fromJson(input.toJson());
    expect(restored.toJson(), input.toJson());
    expect(restored.equippedTrait, TraitType.heavy);
  });
}

RunState _fullState() {
  return _state(
    phase: RunPhase.rewardSelectionCompleted,
    nextStageId: 'stage_2',
    nextStagePatternId: 'pattern_b',
    nextStagePatternSeed: 12,
    patternDrawHistory: [
      PatternDrawRecord(
        stageId: 'stage_1',
        patternId: 'pattern_a',
        patternSeed: 11,
        cycle: 0,
        drawIndex: 0,
      ),
    ],
    rewardCandidateSeed: 42,
    rewardCandidateIds: ['reward_a', 'reward_b'],
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
  RunPhase phase = RunPhase.playing,
  String? nextStageId,
  String? nextStagePatternId,
  int? nextStagePatternSeed,
  Iterable<PatternDrawRecord> patternDrawHistory = const [],
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
}) {
  return RunState(
    schemaVersion: currentRunStateSchemaVersion,
    runId: 'run_1',
    rootSeed: 7,
    resolverVersion: 'resolver-1',
    phase: phase,
    currentStageId: 'stage_1',
    currentPatternId: 'pattern_a',
    currentPatternSeed: 11,
    nextStageId: nextStageId,
    nextStagePatternId: nextStagePatternId,
    nextStagePatternSeed: nextStagePatternSeed,
    patternDrawHistory: patternDrawHistory,
    stageShuffleBags:
        stageShuffleBags ??
        {'stage_1': StageShuffleBagState.initial('stage_1')},
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
    startedAt: DateTime.utc(2026, 8, 6, 0, 0),
    updatedAt: DateTime.utc(2026, 8, 6, 0, 1),
  );
}
