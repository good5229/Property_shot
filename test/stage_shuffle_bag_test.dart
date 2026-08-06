import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';
import 'package:property_shot/game/run/stable_seed.dart';

void main() {
  test('VM과 Web이 공유하는 seed와 첫 cycle의 고정 벡터를 보존한다', () {
    final stage = _stage('stage_seed', const ['a', 'b', 'c']);
    expect(StableSeed.hashString('속성 한방'), 3429975002);
    expect(
      StableSeed.bagSeed(
        rootSeed: 0x12345678,
        stageId: 'stage_seed',
        cycle: 0,
      ),
      543043666,
    );
    expect(
      StableSeed.patternSeed(
        rootSeed: 0x12345678,
        stageId: 'stage_seed',
        cycle: 0,
        drawIndex: 0,
        patternId: 'a',
      ),
      2148761172,
    );
    expect(_drawPatternIds(stage, 0x12345678, 3), ['a', 'c', 'b']);
  });

  test('같은 입력은 VM과 Web에서 같은 seed와 draw sequence를 만든다', () {
    final stage = _stage('stage_seed', const ['a', 'b', 'c']);
    final first = _drawSequence(stage, 0x12345678, 9);
    final second = _drawSequence(stage, 0x12345678, 9);

    expect(first, second);
    expect(StableSeed.hashString('속성 한방'), StableSeed.hashString('속성 한방'));
    expect(
      StableSeed.bagSeed(rootSeed: 1, stageId: 'stage_a', cycle: 0),
      isNot(StableSeed.bagSeed(rootSeed: 1, stageId: 'stage_b', cycle: 0)),
    );
  });

  test('한 cycle은 모든 patternId를 정확히 한 번 소비한다', () {
    final stage = _stage('stage_cycle', const ['a', 'b', 'c', 'd']);
    var state = StageShuffleBagState.initial(stage.stageId);
    final draws = <StagePatternDraw>[];
    for (var index = 0; index < stage.patterns.length; index++) {
      final draw = StageShuffleBag.draw(
        stage: stage,
        state: state,
        rootSeed: 77,
      );
      draws.add(draw);
      state = draw.nextState;
    }

    expect(draws.map((draw) => draw.patternId).toSet(), {'a', 'b', 'c', 'd'});
    expect(state.remainingPatternIds, isEmpty);
    expect(state.cycle, 1);
    expect(state.drawIndex, 4);
  });

  test('새 cycle의 첫 패턴은 가능하면 직전 패턴과 중복되지 않는다', () {
    final stage = _stage('stage_boundary', const ['a', 'b']);
    var state = StageShuffleBagState.initial(stage.stageId);
    StagePatternDraw? previous;
    for (var index = 0; index < 2; index++) {
      previous = StageShuffleBag.draw(stage: stage, state: state, rootSeed: 19);
      state = previous.nextState;
    }
    final nextCycle = StageShuffleBag.draw(
      stage: stage,
      state: state,
      rootSeed: 19,
    );

    expect(nextCycle.cycle, 1);
    expect(nextCycle.patternId, isNot(previous!.patternId));
  });

  test('패턴이 하나면 cycle 경계 반복을 허용한다', () {
    final stage = _stage('stage_single', const ['only']);
    var state = StageShuffleBagState.initial(stage.stageId);
    final first = StageShuffleBag.draw(
      stage: stage,
      state: state,
      rootSeed: 19,
    );
    state = first.nextState;
    final second = StageShuffleBag.draw(
      stage: stage,
      state: state,
      rootSeed: 19,
    );

    expect(first.patternId, 'only');
    expect(second.patternId, 'only');
    expect(second.cycle, 1);
    expect(second.patternSeed, isNot(first.patternSeed));
  });

  test('상태 JSON 왕복 후 이어 그린 sequence는 중단 없이 그린 결과와 같다', () {
    final stage = _stage('stage_resume', const ['a', 'b', 'c']);
    const rootSeed = 0x87654321;
    var uninterrupted = StageShuffleBagState.initial(stage.stageId);
    final expected = <String>[];
    final expectedSeeds = <int>[];
    for (var index = 0; index < 10; index++) {
      final draw = StageShuffleBag.draw(
        stage: stage,
        state: uninterrupted,
        rootSeed: rootSeed,
      );
      expected.add(draw.patternId);
      expectedSeeds.add(draw.patternSeed);
      uninterrupted = draw.nextState;
    }

    var resumed = StageShuffleBagState.initial(stage.stageId);
    for (var index = 0; index < 4; index++) {
      resumed = StageShuffleBag.draw(
        stage: stage,
        state: resumed,
        rootSeed: rootSeed,
      ).nextState;
    }
    final encoded = jsonEncode(resumed.toJson());
    resumed = StageShuffleBagState.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );

    final actual = <String>[];
    final actualSeeds = <int>[];
    for (var index = 4; index < 10; index++) {
      final draw = StageShuffleBag.draw(
        stage: stage,
        state: resumed,
        rootSeed: rootSeed,
      );
      actual.add(draw.patternId);
      actualSeeds.add(draw.patternSeed);
      resumed = draw.nextState;
    }

    expect(actual, expected.sublist(4));
    expect(actualSeeds, expectedSeeds.sublist(4));
    expect(resumed.toJson(), uninterrupted.toJson());
  });

  test('stage별 상태는 서로 독립되고 patternSeed도 stage를 구분한다', () {
    final stageA = _stage('stage_a', const ['same']);
    final stageB = _stage('stage_b', const ['same']);
    final drawA = StageShuffleBag.draw(
      stage: stageA,
      state: StageShuffleBagState.initial(stageA.stageId),
      rootSeed: 5,
    );
    final drawB = StageShuffleBag.draw(
      stage: stageB,
      state: StageShuffleBagState.initial(stageB.stageId),
      rootSeed: 5,
    );

    expect(drawA.stageId, 'stage_a');
    expect(drawB.stageId, 'stage_b');
    expect(drawA.patternSeed, isNot(drawB.patternSeed));
    expect(drawA.nextState.stageId, 'stage_a');
  });

  test('손상되거나 다른 스테이지의 상태를 거부한다', () {
    final stage = _stage('stage_valid', const ['a', 'b']);
    final initial = StageShuffleBagState.initial(stage.stageId);
    final valid = StageShuffleBag.draw(
      stage: stage,
      state: initial,
      rootSeed: 1,
    ).nextState;

    expect(
      () => StageShuffleBagState.fromJson({
        ...valid.toJson(),
        'remainingPatternIds': ['a', 'a'],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => StageShuffleBagState.fromJson({...valid.toJson(), 'stageId': ''}),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => StageShuffleBagState.fromJson({
        ...initial.toJson(),
        'remainingPatternIds': ['a'],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => StageShuffleBagState.fromJson({
        ...valid.toJson(),
        'lastPatternId': null,
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => StageShuffleBagState.fromJson({
        ...valid.toJson(),
        'cycle': 0,
        'remainingPatternIds': [],
      }),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => StageShuffleBag.draw(
        stage: stage,
        state: StageShuffleBagState(
          stageId: stage.stageId,
          cycle: 0,
          drawIndex: 1,
          remainingPatternIds: const [],
          lastPatternId: 'b',
        ),
        rootSeed: 1,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => StageShuffleBag.draw(
        stage: stage,
        state: StageShuffleBagState(
          stageId: stage.stageId,
          cycle: 1,
          drawIndex: 1,
          remainingPatternIds: const ['a'],
          lastPatternId: 'b',
        ),
        rootSeed: 1,
      ),
      throwsA(isA<ArgumentError>()),
    );
    final unknownState = StageShuffleBagState.fromJson({
      ...valid.toJson(),
      'remainingPatternIds': ['unknown'],
    });
    expect(
      () =>
          StageShuffleBag.draw(stage: stage, state: unknownState, rootSeed: 1),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => StageShuffleBag.draw(
        stage: stage,
        state: StageShuffleBagState.initial('other_stage'),
        rootSeed: 1,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(
      () => StageShuffleBag.draw(
        stage: StageDefinition(
          stageId: 'stage_valid',
          title: '잘못된 스테이지',
          patterns: [stage.patterns.first, stage.patterns.first],
        ),
        state: initial,
        rootSeed: 1,
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('nextInt는 1을 허용하고 0 이하만 거부한다', () {
    expect(StableRandom(1).nextInt(1), 0);
    expect(
      () => StableRandom(1).nextInt(0),
      throwsA(
        predicate<ArgumentError>(
          (error) => error.toString().contains('0보다 커야 합니다.'),
        ),
      ),
    );
  });

  test('셔플 상태는 입력 목록을 방어 복사하고 외부에서 수정할 수 없다', () {
    final input = <String>['a', 'b'];
    final state = StageShuffleBagState(
      stageId: 'stage_copy',
      cycle: 0,
      drawIndex: 0,
      remainingPatternIds: input,
      lastPatternId: null,
    );

    input[0] = 'changed';
    expect(state.remainingPatternIds, ['a', 'b']);
    expect(
      () => state.remainingPatternIds[0] = 'changed again',
      throwsA(isA<UnsupportedError>()),
    );
  });
}

StageDefinition _stage(String stageId, List<String> patternIds) {
  return StageDefinition(
    stageId: stageId,
    title: '테스트 스테이지',
    patterns: [
      for (final patternId in patternIds)
        StagePattern(
          patternId: patternId,
          weight: patternId == 'a' ? 100 : 0.1,
          parShots: 3,
          difficultyBand: '테스트',
          ballSpawn: const Vec2(24, 520),
          objects: const [],
        ),
    ],
  );
}

List<String> _drawSequence(StageDefinition stage, int rootSeed, int count) {
  var state = StageShuffleBagState.initial(stage.stageId);
  final sequence = <String>[];
  for (var index = 0; index < count; index++) {
    final draw = StageShuffleBag.draw(
      stage: stage,
      state: state,
      rootSeed: rootSeed,
    );
    sequence.add('${draw.patternId}:${draw.patternSeed}');
    state = draw.nextState;
  }
  return sequence;
}

List<String> _drawPatternIds(
  StageDefinition stage,
  int rootSeed,
  int count,
) {
  var state = StageShuffleBagState.initial(stage.stageId);
  final patternIds = <String>[];
  for (var index = 0; index < count; index++) {
    final draw = StageShuffleBag.draw(
      stage: stage,
      state: state,
      rootSeed: rootSeed,
    );
    patternIds.add(draw.patternId);
    state = draw.nextState;
  }
  return patternIds;
}
