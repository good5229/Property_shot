import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/counterfactual_shot_advice.dart';
import 'package:property_shot/game/analysis/failure_replay.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  final state = GameState(
    levelIndex: 0,
    levelName: 'test',
    ballSpawn: const Vec2(0, 0),
    entities: const [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2.zero,
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(100, 0),
        size: Vec2(48, 48),
        solid: false,
      ),
    ],
  );
  const input = ShotInput(direction: Vec2(1, 0), power: .5);
  ShotResult resultAt(double distance) => ShotResult(
    state: state,
    path: [Vec2(100 - distance, 0)],
    events: const [],
  );

  test('가까운 복수 후보가 좋아질 때 한 축의 방향만 제안한다', () {
    var calls = 0;
    final coach = CounterfactualShotCoach(
      resolve: (before, candidate) {
        calls++;
        final angle = math.atan2(candidate.direction.y, candidate.direction.x);
        return resultAt(angle > 0 ? 55 : 100);
      },
    );
    final advice = coach.analyze(
      stageId: 'stage_heavy',
      failure: FailureReplayData(
        beforeState: state,
        input: input,
        result: resultAt(100),
      ),
    );
    expect(calls, lessThanOrEqualTo(12));
    expect(advice?.axis, CounterfactualAdviceAxis.angle);
    expect(advice?.direction, CounterfactualAdviceDirection.clockwise);
    expect(advice?.message, contains('시계 방향'));
    expect(advice?.message, isNot(matches(RegExp(r'\d|%|도'))));
  });

  test('양쪽이 같은 정도로 좋아지면 임의 조언을 만들지 않는다', () {
    final coach = CounterfactualShotCoach(
      resolve: (before, candidate) {
        final angle = math.atan2(candidate.direction.y, candidate.direction.x);
        return resultAt(angle.abs() > .01 ? 55 : 100);
      },
    );
    final advice = coach.analyze(
      stageId: 'stage_heavy',
      failure: FailureReplayData(
        beforeState: state,
        input: input,
        result: resultAt(100),
      ),
    );
    expect(advice, isNull);
  });

  test('한 개의 운 좋은 후보나 판정기 예외는 조언으로 채택하지 않는다', () {
    var calls = 0;
    final lucky = CounterfactualShotCoach(
      resolve: (before, candidate) {
        calls++;
        if (calls == 1) return resultAt(50);
        throw StateError('손상된 후보');
      },
    );
    expect(
      lucky.analyze(
        stageId: 'stage_heavy',
        failure: FailureReplayData(
          beforeState: state,
          input: input,
          result: resultAt(100),
        ),
      ),
      isNull,
    );
    expect(calls, lessThanOrEqualTo(12));
  });

  test('기존 기믹 성과를 다른 동점 기믹으로 바꾼 후보는 거부한다', () {
    ShotResult withEvent(String event, double distance) => ShotResult(
      state: state,
      path: [Vec2(100 - distance, 0)],
      events: [event],
    );
    final coach = CounterfactualShotCoach(
      resolve: (before, candidate) => withEvent('balloon_popped', 40),
    );
    final advice = coach.analyze(
      stageId: 'stage_property_shot',
      failure: FailureReplayData(
        beforeState: state,
        input: input,
        result: withEvent('switch_pressed', 100),
      ),
    );
    expect(advice, isNull);
  });

  test('파워 경계의 중복 후보를 제거하고 각 축은 다른 입력을 바꾸지 않는다', () {
    final seen = <ShotInput>[];
    final coach = CounterfactualShotCoach(
      resolve: (before, candidate) {
        seen.add(candidate);
        return resultAt(100);
      },
    );
    coach.analyze(
      stageId: 'stage_heavy',
      failure: FailureReplayData(
        beforeState: state,
        input: const ShotInput(direction: Vec2(1, 0), power: 1),
        result: resultAt(100),
      ),
    );
    expect(seen, hasLength(10), reason: '상한 파워로 clamp된 3개 후보는 1개다.');
    for (final candidate in seen.take(6)) {
      expect(candidate.power, 1);
    }
    for (final candidate in seen.skip(6)) {
      expect(candidate.direction, const Vec2(1, 0));
    }
  });

  test(
    '생산 40패턴은 두 번 분석해도 예외 없이 같은 결과를 낸다',
    () {
      const resolver = ShotResolver();
      final coach = CounterfactualShotCoach();
      var patternCount = 0;
      for (
        var stageIndex = 0;
        stageIndex < generatedStageCatalog.stages.length;
        stageIndex++
      ) {
        final stage = generatedStageCatalog.stages[stageIndex];
        for (final pattern in stage.patterns) {
          patternCount++;
          final before = pattern
              .toLevelDefinition(
                stageId: stage.stageId,
                stageTitle: stage.title,
              )
              .createState(stageIndex, productRules: true);
          final candidate = ShotInput(
            direction: const Vec2(1, 0),
            power: .5,
            equippedTrait: before.equippedTrait,
          );
          final baseline = resolver.resolve(before, candidate);
          final failure = FailureReplayData(
            beforeState: before,
            input: candidate,
            result: baseline,
          );
          final first = coach.analyze(stageId: stage.stageId, failure: failure);
          final second = coach.analyze(
            stageId: stage.stageId,
            failure: failure,
          );
          expect(first?.axis, second?.axis, reason: pattern.patternId);
          expect(
            first?.direction,
            second?.direction,
            reason: pattern.patternId,
          );
          expect(first?.message, second?.message, reason: pattern.patternId);
          if (first != null) {
            expect(first.message, isNot(matches(RegExp(r'\d|%|도'))));
          }
        }
      }
      expect(patternCount, 40);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
