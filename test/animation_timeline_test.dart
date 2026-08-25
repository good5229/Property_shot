import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/impact_metrics.dart';

void main() {
  test('30·60·120Hz 업데이트에서 충돌 이벤트와 완료 콜백은 한 번씩만 발생한다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );

    for (final framesPerSecond in [30, 60, 120]) {
      var finished = 0;
      final impactKeys = <String>{};
      final moveTriggerIndices = <int>[];
      final game = PropertyShotGame(
        result.state,
        onAnimationFinished: () => finished += 1,
        onAnimationImpact: (move) =>
            moveTriggerIndices.add(move.triggerPathIndex),
        onShotImpact: (impact) {
          impactKeys.add('${impact.entityId}:${impact.pathIndex}');
        },
      );
      game.setStateSnapshot(
        result.state,
        path: result.path,
        transitionStart: start,
        moves: result.moves,
        impacts: result.impacts,
        physicsEvents: result.physicsEvents,
        animationTransaction: true,
      );

      var frame = 0;
      while (finished == 0 && frame < 4000) {
        game.update(1 / framesPerSecond);
        frame += 1;
      }

      expect(finished, 1, reason: '$framesPerSecond Hz에서 완료되지 않음');
      expect(impactKeys.length, result.impacts.length);
      expect(moveTriggerIndices.length, result.moves.length);
      expect(
        moveTriggerIndices,
        [...moveTriggerIndices]..sort(),
        reason: '$framesPerSecond Hz에서 연쇄 이동 이벤트 순서가 뒤섞임',
      );
      game.update(1 / framesPerSecond);
      expect(finished, 1, reason: '$framesPerSecond Hz에서 완료 콜백 중복');
    }
  });

  test('공유 물리 이벤트 스트림은 애니메이션 콜백과 일대일로 재생된다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );
    final eventIds = <String>[];
    final game = PropertyShotGame(
      result.state,
      onPhysicsEvent: (event) => eventIds.add(event.eventId),
    );
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
      animationTransaction: true,
    );

    for (var frame = 0; frame < 4000; frame++) {
      game.update(1 / 60);
    }

    expect(eventIds, result.physicsEvents.map((event) => event.eventId));
    expect(eventIds.toSet(), hasLength(eventIds.length));
  });

  test('충돌과 이동 콜백은 같은 경로 시점에서 충돌을 먼저 방출한다', () {
    const resolver = ShotResolver();
    final start = levels[2].createState(2);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(0.8, -0.6), power: 0.92),
    );
    final callbacks = <String>[];
    final game = PropertyShotGame(
      result.state,
      onAnimationImpact: (move) =>
          callbacks.add('move:${move.triggerPathIndex}:${move.entityId}'),
      onShotImpact: (impact) =>
          callbacks.add('impact:${impact.pathIndex}:${impact.entityId}'),
    );
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      animationTransaction: true,
    );

    for (var frame = 0; frame < 4000; frame++) {
      game.update(1 / 60);
    }

    final expected =
        <({int pathIndex, int kind, int sequence, String value})>[
          for (var index = 0; index < result.impacts.length; index++)
            (
              pathIndex: result.impacts[index].pathIndex,
              kind: 0,
              sequence: index,
              value:
                  'impact:${result.impacts[index].pathIndex}:${result.impacts[index].entityId}',
            ),
          for (var index = 0; index < result.moves.length; index++)
            (
              pathIndex: result.moves[index].triggerPathIndex,
              kind: 1,
              sequence: index,
              value:
                  'move:${result.moves[index].triggerPathIndex}:${result.moves[index].entityId}',
            ),
        ]..sort((left, right) {
          final path = left.pathIndex.compareTo(right.pathIndex);
          if (path != 0) return path;
          final kind = left.kind.compareTo(right.kind);
          if (kind != 0) return kind;
          return left.sequence.compareTo(right.sequence);
        });

    expect(callbacks, expected.map((event) => event.value).toList());
  });

  test('백그라운드 복귀의 큰 시간 간격은 충돌 애니메이션을 건너뛰지 않는다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );
    var finished = 0;
    final impacts = <String>{};
    final game = PropertyShotGame(
      result.state,
      onAnimationFinished: () => finished += 1,
      onShotImpact: (impact) =>
          impacts.add('${impact.entityId}:${impact.pathIndex}'),
    );
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      animationTransaction: true,
    );

    game.update(0.6);

    expect(finished, 0);
    expect(impacts.length, lessThan(result.impacts.length));
  });

  test('애니메이션 마지막 경로 점을 그릴 때 다음 인덱스를 읽지 않는다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );
    final game = PropertyShotGame(result.state);
    game.onGameResize(Vector2(360, 520));
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      animationTransaction: true,
    );
    for (var frame = 0; frame < 4000; frame++) {
      game.update(1 / 60);
    }
    final recorder = ui.PictureRecorder();
    game.render(ui.Canvas(recorder));
    recorder.endRecording();
  });

  test('변하지 않는 보드 배경은 여러 프레임에서 한 번만 기록한다', () {
    final game = PropertyShotGame(
      levels[0].createState(0),
      loadVisualAssets: false,
    );
    game.onGameResize(Vector2(360, 520));

    for (var frame = 0; frame < 3; frame++) {
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    }

    expect(game.boardPictureBuildCountForTest, 1);
    game.onRemove();
  });

  test('강한 충돌에서도 애니메이션 시간축은 매 프레임 연속 진행한다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );
    final strongest = [...result.impacts]
      ..sort((left, right) => right.impulse.compareTo(left.impulse));
    final impact = strongest.first;
    expect(ImpactMetrics.tierFor(impact.impulse), isNot(ImpactTier.tap));

    final game = PropertyShotGame(result.state);
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
      animationTransaction: true,
    );
    game.setAnimationCursorForTest(impact.pathIndex.toDouble());
    final cursorAtImpact = game.animationCursorForTest;
    game.update(1 / 120);
    final cursorAfterFirstFrame = game.animationCursorForTest;
    game.update(1 / 60);
    final cursorAfterSecondFrame = game.animationCursorForTest;

    expect(cursorAfterFirstFrame, greaterThan(cursorAtImpact));
    expect(cursorAfterSecondFrame, greaterThan(cursorAfterFirstFrame));
    expect(
      cursorAfterFirstFrame - cursorAtImpact,
      closeTo(PropertyShotGame.animationCursorUnitsPerSecond / 120, 0.0001),
    );
    expect(
      cursorAfterSecondFrame - cursorAfterFirstFrame,
      closeTo(PropertyShotGame.animationCursorUnitsPerSecond / 60, 0.0001),
    );

    final reduced = PropertyShotGame(result.state, reducedMotion: true);
    reduced.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
      animationTransaction: true,
    );
    reduced.setAnimationCursorForTest(impact.pathIndex.toDouble());
    final reducedAt = reduced.animationCursorForTest;
    reduced.update(0.01);
    expect(reduced.animationCursorForTest, greaterThan(reducedAt));
  });
}
