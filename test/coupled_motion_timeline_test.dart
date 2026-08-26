import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/simulation/coupled_motion_timeline.dart';

void main() {
  test('경로가 홀로 먼저 점프해도 공과 상자는 240Hz 접촉을 끊었다 붙이지 않는다', () {
    const separation = 30.8;
    const endCursor = 20.0;
    Vec2 rawPosition(String id, double cursor) {
      if (id == 'crate') {
        return Vec2(180, 300 - cursor * 4);
      }
      return cursor < 4 ? Vec2(180, 330.8 - cursor * 4) : const Vec2(180, 100);
    }

    final timeline = CoupledMotionTimeline.build(
      entityIds: const ['ball', 'crate'],
      contacts: const [
        CoupledMotionContact(
          sourceEntityId: 'ball',
          targetEntityId: 'crate',
          normal: Vec2(0, 1),
          separation: separation,
          sourceCorrectionWeight: 1 / 4.4,
          targetCorrectionWeight: 0.01 / 2,
          startCursor: 3,
          endCursor: endCursor,
        ),
      ],
      sampleRawPosition: rawPosition,
      endCursor: endCursor,
      cursorUnitsPerSecond: 34,
    );

    for (final framesPerSecond in [30, 45, 60]) {
      final frameCursor = 34 / framesPerSecond;
      Vec2? previousBall;
      var previousTravelDistance = 0.0;
      var maximumStep = 0.0;
      var maximumStepDelta = 0.0;
      double? previousStep;
      for (
        var cursor = 3.0;
        cursor < endCursor - frameCursor;
        cursor += frameCursor
      ) {
        final ball = timeline.positionAt('ball', cursor)!;
        final crate = timeline.positionAt('crate', cursor)!;
        final travelDistance = timeline.travelDistanceAt('ball', cursor)!;
        expect(
          travelDistance,
          greaterThanOrEqualTo(previousTravelDistance),
          reason: '$framesPerSecond FPS에서 구름 누적 거리가 역행함',
        );
        previousTravelDistance = travelDistance;
        final rawBall = rawPosition('ball', cursor);
        final rawCrate = rawPosition('crate', cursor);
        if ((rawBall - rawCrate).y <= separation) {
          expect(
            (ball - crate).y,
            closeTo(separation, 0.05),
            reason: '$framesPerSecond FPS에서 접촉 제약이 한 스텝씩 풀림',
          );
        }
        if (previousBall != null) {
          final step = ball.distanceTo(previousBall);
          maximumStep = math.max(maximumStep, step);
          if (previousStep != null) {
            maximumStepDelta = math.max(
              maximumStepDelta,
              (step - previousStep).abs(),
            );
          }
          previousStep = step;
        }
        previousBall = ball;
      }
      expect(maximumStep, lessThanOrEqualTo(10));
      expect(maximumStepDelta, lessThanOrEqualTo(6));
    }

    expect(
      timeline.positionAt('ball', endCursor),
      rawPosition('ball', endCursor),
    );
    expect(
      timeline.positionAt('crate', endCursor),
      rawPosition('crate', endCursor),
    );
    expect(timeline.travelDistanceAt('ball', endCursor), greaterThan(0));
  });

  test('누적 이동거리는 보간된 위치가 실제로 이동한 길이와 일치한다', () {
    final timeline = CoupledMotionTimeline.build(
      entityIds: const ['ball'],
      contacts: const [],
      sampleRawPosition: (_, cursor) => Vec2(cursor * 3, cursor * 4),
      endCursor: 10,
      cursorUnitsPerSecond: 34,
    );

    expect(timeline.travelDistanceAt('ball', 0), 0);
    expect(timeline.travelDistanceAt('ball', 5), closeTo(25, 0.02));
    expect(timeline.travelDistanceAt('ball', 10), closeTo(50, 0.02));
  });

  test('12개 연쇄의 240Hz 타임라인은 재생 전에 짧은 시간 안에 완성된다', () {
    const bodyCount = 12;
    final ids = [for (var index = 0; index < bodyCount; index++) 'body_$index'];
    final contacts = [
      for (var index = 0; index < bodyCount - 1; index++)
        CoupledMotionContact(
          sourceEntityId: ids[index],
          targetEntityId: ids[index + 1],
          normal: const Vec2(-1, 0),
          separation: 12,
          sourceCorrectionWeight: 0.5,
          targetCorrectionWeight: 0.005,
          startCursor: index.toDouble(),
          endCursor: 120,
        ),
    ];
    final stopwatch = Stopwatch()..start();

    final timeline = CoupledMotionTimeline.build(
      entityIds: ids,
      contacts: contacts,
      sampleRawPosition: (id, cursor) {
        final index = int.parse(id.substring('body_'.length));
        return Vec2(40 + index * 12 + cursor * 2, 80);
      },
      endCursor: 120,
      cursorUnitsPerSecond: 34,
    );
    stopwatch.stop();

    expect(timeline.samplesByEntity, hasLength(bodyCount));
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(150),
      reason: '12중 연쇄 타임라인 사전 계산이 발사 순간을 막아서는 안 된다.',
    );
  });
}
