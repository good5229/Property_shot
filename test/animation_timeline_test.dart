import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/impact_metrics.dart';

void main() {
  test('30·60·120·144Hz 업데이트에서 충돌 이벤트와 완료 콜백은 한 번씩만 발생한다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );

    for (final framesPerSecond in [30, 60, 120, 144]) {
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

  test('움직임용 엔티티 순서·조회 캐시는 샷마다 한 번만 만든다', () {
    const resolver = ShotResolver();
    final start = levels[4].createState(4);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(-0.8, -0.5), power: 0.82),
    );
    final game = PropertyShotGame(result.state, loadVisualAssets: false);
    game.onGameResize(Vector2(360, 520));
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
      animationTransaction: true,
    );

    expect(game.animationRenderCacheBuildCountForTest, 1);
    expect(game.animationRenderEntityCountForTest, start.entities.length);
    for (var frame = 0; frame < 24; frame++) {
      game.update(1 / 144);
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    }
    expect(game.animationRenderCacheBuildCountForTest, 1);
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

  test('일반 충돌은 보드를 움직이지 않고 핵심 사건만 30·45·60 FPS에서 작게 감쇠한다', () {
    const resolver = ShotResolver();
    final start = levels[0].createState(0);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, -0.4), power: 0.86),
    );
    final ordinaryImpact = result.impacts.firstWhere(
      (impact) =>
          impact.entityType != EntityType.hole &&
          impact.entityType != EntityType.balloon &&
          impact.entityType != EntityType.switchPad &&
          impact.entityType != EntityType.powerSlider &&
          impact.entityType != EntityType.rotatingReflector,
    );
    final cinematicImpact = ShotImpact(
      entityId: 'test_hole',
      entityType: EntityType.hole,
      position: result.path.last,
      normal: const Vec2(0, -1),
      pathIndex: ordinaryImpact.pathIndex,
      strength: ordinaryImpact.strength,
      impulse: ordinaryImpact.impulse,
    );

    for (final framesPerSecond in [30, 45, 60]) {
      final ordinaryGame = PropertyShotGame(result.state);
      ordinaryGame.setStateSnapshot(
        result.state,
        path: result.path,
        transitionStart: start,
        impacts: [ordinaryImpact],
        animationTransaction: true,
      );
      ordinaryGame.setAnimationCursorForTest(
        ordinaryImpact.pathIndex.toDouble(),
      );
      for (var frame = 0; frame < 5; frame++) {
        expect(
          ordinaryGame.screenShakeOffsetForTest(),
          ui.Offset.zero,
          reason: '$framesPerSecond FPS 일반 충돌이 보드 전체를 움직임',
        );
        ordinaryGame.update(1 / framesPerSecond);
      }

      final game = PropertyShotGame(result.state);
      game.setStateSnapshot(
        result.state,
        path: result.path,
        transitionStart: start,
        impacts: [cinematicImpact],
        animationTransaction: true,
      );
      game.setAnimationCursorForTest(cinematicImpact.pathIndex.toDouble());

      expect(
        game.screenShakeOffsetForTest(),
        ui.Offset.zero,
        reason: '$framesPerSecond FPS 충돌 첫 프레임에서 보드가 점프함',
      );

      var previous = ui.Offset.zero;
      var nonZeroFrames = 0;
      var maximumStep = 0.0;
      final sampleFrames =
          (PropertyShotGame.screenShakeDurationCursor /
                  PropertyShotGame.animationCursorUnitsPerSecond *
                  framesPerSecond)
              .ceil();
      for (var frame = 0; frame < sampleFrames; frame++) {
        game.update(1 / framesPerSecond);
        final offset = game.screenShakeOffsetForTest();
        if (offset != ui.Offset.zero) nonZeroFrames += 1;
        maximumStep = math.max(maximumStep, (offset - previous).distance);
        previous = offset;
      }

      expect(nonZeroFrames, greaterThanOrEqualTo(2));
      expect(
        maximumStep,
        lessThan(ImpactMetrics.cameraShake(cinematicImpact.impulse) * 0.25),
        reason: '$framesPerSecond FPS에서 인접 프레임 흔들림 차이가 너무 큼',
      );
      game.setAnimationCursorForTest(
        cinematicImpact.pathIndex +
            PropertyShotGame.screenShakeDurationCursor +
            0.01,
      );
      expect(game.screenShakeOffsetForTest(), ui.Offset.zero);
    }
  });

  test('30~60 FPS 불규칙 프레임에서도 커서와 충돌 사건이 연속·단일 재생된다', () {
    const resolver = ShotResolver();
    final start = levels[4].createState(4);
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(-0.8, -0.5), power: 0.82),
    );
    final eventIds = <String>[];
    var finished = 0;
    final game = PropertyShotGame(
      result.state,
      onPhysicsEvent: (event) => eventIds.add(event.eventId),
      onAnimationFinished: () => finished += 1,
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

    const frameDurations = <double>[
      1 / 60,
      1 / 45,
      1 / 30,
      1 / 50,
      1 / 35,
      1 / 60,
    ];
    var frame = 0;
    while (finished == 0 && frame < 4000) {
      final before = game.animationCursorForTest;
      final dt = frameDurations[frame % frameDurations.length];
      game.update(dt);
      final advanced = game.animationCursorForTest - before;
      expect(advanced, greaterThan(0));
      expect(
        advanced,
        lessThanOrEqualTo(
          PropertyShotGame.animationCursorUnitsPerSecond / 30 + 0.0001,
        ),
      );
      frame += 1;
    }

    expect(finished, 1);
    expect(eventIds, result.physicsEvents.map((event) => event.eventId));
    expect(eventIds.toSet(), hasLength(eventIds.length));
  });

  test('5개 오브젝트 연쇄 이동은 30·45·60 FPS에서 순간이동이 없다', () {
    const resolver = ShotResolver();
    final start = _longChainAnimationState();
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final movingIds = result.moves
        .map((move) => move.entityId)
        .where((id) => start.entityById(id) != null)
        .toSet();
    expect(movingIds.length, greaterThanOrEqualTo(5));

    for (final framesPerSecond in [30, 45, 60]) {
      final game = PropertyShotGame(result.state, loadVisualAssets: false);
      game.setStateSnapshot(
        result.state,
        path: result.path,
        transitionStart: start,
        moves: result.moves,
        impacts: result.impacts,
        physicsEvents: result.physicsEvents,
        animationTransaction: true,
      );
      final previous = <String, Vec2>{
        for (final id in movingIds) id: game.animatedEntityPositionForTest(id),
      };

      for (var frame = 0; frame < 4000; frame++) {
        game.update(1 / framesPerSecond);
        for (final id in movingIds) {
          final current = game.animatedEntityPositionForTest(id);
          final delta = current - previous[id]!;
          expect(
            delta.length,
            lessThanOrEqualTo(4.55),
            reason: '$framesPerSecond FPS에서 $id가 한 프레임에 순간이동함',
          );
          previous[id] = current;
        }
        if (game.animationCursorForTest >= game.animationEndCursorForTest) {
          break;
        }
      }
      game.onRemove();
    }
  });

  testWidgets('5중 연쇄의 래스터 본체는 계획 화면 캐시를 재사용한다', (tester) async {
    const resolver = ShotResolver();
    final start = _longChainAnimationState();
    final result = resolver.resolve(
      start,
      const ShotInput(direction: Vec2(1, 0), power: 1),
    );
    final game = PropertyShotGame(start);
    await tester.runAsync(game.onLoad);
    game.onGameResize(Vector2(390, 560));
    final planningRecorder = ui.PictureRecorder();
    game.render(ui.Canvas(planningRecorder));
    planningRecorder.endRecording().dispose();
    final prewarmedPictures = game.movingSpritePictureBuildCountForTest;
    expect(prewarmedPictures, greaterThan(0));

    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: start,
      moves: result.moves,
      impacts: result.impacts,
      physicsEvents: result.physicsEvents,
      animationTransaction: true,
    );
    for (var frame = 0; frame < 60; frame++) {
      game.update(1 / 60);
      final recorder = ui.PictureRecorder();
      game.render(ui.Canvas(recorder));
      recorder.endRecording().dispose();
    }

    expect(
      game.movingSpritePictureBuildCountForTest,
      prewarmedPictures,
      reason: '연쇄 충돌 중 crate 본체 그림을 프레임마다 다시 기록함',
    );
    game.onRemove();
  });

  test('불균일한 연쇄 경로도 위치와 재질 변형이 같은 거리 시간축을 사용한다', () {
    const start = GameState(
      levelIndex: 991,
      levelName: '연쇄 변형 시간축 회귀',
      ballSpawn: Vec2(20, 80),
      entities: [
        EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(20, 80),
          size: Vec2(24, 24),
          movable: true,
        ),
        EntityState(
          id: 'crate',
          type: EntityType.crate,
          position: Vec2(40, 80),
          size: Vec2(20, 20),
          movable: true,
        ),
      ],
    );
    const move = ShotAnimationMove(
      entityId: 'crate',
      from: Vec2(40, 80),
      to: Vec2(100, 80),
      triggerPathIndex: 1,
      path: [
        Vec2(40, 80),
        Vec2(40.1, 80),
        Vec2(60, 80),
        Vec2(60.1, 80),
        Vec2(100, 80),
      ],
    );

    for (final framesPerSecond in [30, 45, 60]) {
      final game = PropertyShotGame(start, loadVisualAssets: false);
      game.setStateSnapshot(
        start,
        path: const [Vec2(20, 80), Vec2(24, 80)],
        transitionStart: start,
        moves: const [move],
        animationTransaction: true,
      );
      game.setAnimationCursorForTest(1.75);
      var previous = game.animatedEntityMotionImpactForTest('crate');
      var maximumStep = 0.0;
      while (game.animationCursorForTest < 15.25) {
        game.update(1 / framesPerSecond);
        final current = game.animatedEntityMotionImpactForTest('crate');
        maximumStep = math.max(maximumStep, (current - previous).abs());
        previous = current;
      }
      expect(
        maximumStep,
        lessThan(0.2),
        reason: '$framesPerSecond FPS에서 불균일 경로 변형이 튐',
      );
      game.onRemove();
    }
  });
}

GameState _longChainAnimationState() {
  return const GameState(
    levelIndex: 992,
    levelName: '다중 연쇄 프레임 회귀',
    ballSpawn: Vec2(40, 80),
    entities: [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(40, 80),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'crate_a',
        type: EntityType.crate,
        position: Vec2(60, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_b',
        type: EntityType.crate,
        position: Vec2(75, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_c',
        type: EntityType.crate,
        position: Vec2(90, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_d',
        type: EntityType.crate,
        position: Vec2(105, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'crate_e',
        type: EntityType.crate,
        position: Vec2(120, 80),
        size: Vec2(10, 10),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(360, 260),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}
