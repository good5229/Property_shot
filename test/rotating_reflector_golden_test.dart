import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    for (final variant in const [
      'default',
      'diagonal',
      'impact',
      'rotation_progress',
      'rotation_complete',
      'popup',
      'reduced',
    ]) {
      testWidgets('회전 반사판 $variant Golden ${fixture.name}', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        GameFeedback.reducedMotionEnabled = variant == 'reduced';
        addTearDown(() {
          GameFeedback.reducedMotionEnabled = false;
          tester.binding.setSurfaceSize(null);
        });
        await tester.binding.setSurfaceSize(
          Size(fixture.width, fixture.height),
        );

        final initial = _reflectorState(
          orientation: variant == 'diagonal' ? 1 : 0,
        );
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('rotating_reflector_golden'),
            child: PropertyShotApp(
              initialState: initial,
              showStageSelector: false,
              fontFamilyOverride: 'GoldenNanumGothic',
              loadGameAssets: false,
            ),
          ),
        );
        await tester.pump();
        final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        );
        final game = gameWidgetState.currentGame;
        await game.toBeLoaded();

        if (variant == 'impact' ||
            variant == 'rotation_progress' ||
            variant == 'rotation_complete' ||
            variant == 'reduced') {
          final result = const ShotResolver().resolve(
            initial,
            const ShotInput(direction: Vec2(0, -1), power: 1),
          );
          game.setStateSnapshot(
            result.state,
            path: result.path,
            transitionStart: initial,
            impacts: result.impacts,
            moves: result.moves,
            physicsEvents: result.physicsEvents,
          );
          final rotationEvent = result.physicsEvents.firstWhere(
            (event) => event.kind == PhysicsEventKind.reflectorRotation,
          );
          final rotation = rotationEvent.reflectorRotation!;
          final eventCursor = rotationEvent.pathIndex.toDouble();
          final duration = PropertyShotGame.reflectorRotationDuration;
          final cursor = switch (variant) {
            'impact' => math.max(0.0, eventCursor - 0.01),
            'rotation_progress' => eventCursor + duration / 2,
            _ => eventCursor + duration,
          };
          game.setAnimationCursorForTest(cursor);
          await tester.pump();
          final renderedOrientation = game.reflectorRenderOrientationForTest(
            'reflector',
          );
          if (variant == 'impact') {
            expect(
              renderedOrientation,
              closeTo(rotation.orientationBefore, 0.01),
            );
          } else if (variant == 'rotation_progress') {
            expect(
              renderedOrientation,
              closeTo(rotation.orientationBefore + 1, 0.01),
            );
          } else {
            expect(
              renderedOrientation,
              closeTo(rotation.orientationAfter, 0.01),
            );
          }
        } else if (variant == 'popup') {
          final aimRect = tester.getRect(find.byKey(const Key('aim_area')));
          final aimScale = math.min(aimRect.width / 360, aimRect.height / 560);
          final aimOrigin = Offset(
            aimRect.left + (aimRect.width - 360 * aimScale) / 2,
            aimRect.top + (aimRect.height - 560 * aimScale) / 2,
          );
          await tester.tapAt(
            aimOrigin + Offset(180 * aimScale, 280 * aimScale),
          );
          await tester.pump();
          expect(find.text('회전 반사판'), findsOneWidget);
        } else {
          await tester.pump(const Duration(milliseconds: 80));
        }

        await expectLater(
          find.byKey(const Key('rotating_reflector_golden')),
          matchesGoldenFile(
            'goldens/rotating_reflector_${variant}_${fixture.name}.png',
          ),
        );
      });
    }
  }

  testWidgets('90도 회전한 반사판은 세로 끝과 접근성 영역에서 선택된다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      PropertyShotApp(
        initialState: _reflectorState(orientation: 2),
        showStageSelector: false,
        fontFamilyOverride: 'GoldenNanumGothic',
        loadGameAssets: false,
      ),
    );
    await tester.pump();

    final semantic = find.bySemanticsLabel(RegExp('회전 반사판, 충돌 방향 반사'));
    expect(semantic, findsOneWidget);
    final semanticRect = tester.getRect(semantic);
    expect(semanticRect.height, greaterThan(semanticRect.width));

    final aimRect = tester.getRect(find.byKey(const Key('aim_area')));
    final aimScale = math.min(aimRect.width / 360, aimRect.height / 560);
    final aimOrigin = Offset(
      aimRect.left + (aimRect.width - 360 * aimScale) / 2,
      aimRect.top + (aimRect.height - 560 * aimScale) / 2,
    );
    await tester.tapAt(aimOrigin + Offset(180 * aimScale, 250 * aimScale));
    await tester.pump();

    expect(find.text('회전 반사판'), findsOneWidget);
  });

  testWidgets('다중 회전은 일반 모드에서 순차 진행하고 reduced 모드에서는 같은 path에 즉시 누적한다', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final initial = _reflectorState(orientation: 0);
    final result = const ShotResolver().resolve(
      initial,
      const ShotInput(direction: Vec2(0, -1), power: 1),
    );
    final first = result.reflectorRotations.first;
    final second = ReflectorRotation(
      sourceEntityId: first.sourceEntityId,
      reflectorEntityId: first.reflectorEntityId,
      contactId: '${first.contactId}:second',
      pathIndex: first.pathIndex,
      orientationBefore: 2,
      orientationAfter: 4,
      rotationCountBefore: 1,
      rotationCountAfter: 2,
      collisionNormal: first.collisionNormal,
      velocityBefore: first.velocityAfter,
      velocityAfter: first.velocityAfter,
    );
    final physicsEvents = buildPhysicsEvents(
      path: result.path,
      impacts: [
        result.impacts.firstWhere((impact) => impact.entityId == 'reflector'),
      ],
      moves: const [],
      chainSafetyDiagnostics: const [],
      reflectorRotations: [first, second],
    );
    final finalState = result.state.copyWith(
      entities: [
        for (final entity in result.state.entities)
          entity.id == 'reflector'
              ? entity.copyWith(
                  reflectorOrientation: 4,
                  reflectorRotationCount: 2,
                )
              : entity,
      ],
    );

    await tester.pumpWidget(
      PropertyShotApp(
        initialState: initial,
        showStageSelector: false,
        fontFamilyOverride: 'GoldenNanumGothic',
        loadGameAssets: false,
      ),
    );
    await tester.pump();
    final game = tester
        .state<GameWidgetState<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        )
        .currentGame;
    await game.toBeLoaded();
    game.setStateSnapshot(
      finalState,
      path: result.path,
      transitionStart: initial,
      impacts: result.impacts,
      physicsEvents: physicsEvents,
    );
    final path = first.pathIndex.toDouble();
    game.setAnimationCursorForTest(path + 4);
    expect(
      game.reflectorRenderOrientationForTest('reflector'),
      closeTo(1, 0.01),
    );
    game.setAnimationCursorForTest(path + 8);
    expect(
      game.reflectorRenderOrientationForTest('reflector'),
      closeTo(2, 0.01),
    );
    game.setAnimationCursorForTest(path + 12);
    expect(
      game.reflectorRenderOrientationForTest('reflector'),
      closeTo(3, 0.01),
    );
    game.setAnimationCursorForTest(path + 16);
    expect(
      game.reflectorRenderOrientationForTest('reflector'),
      closeTo(4, 0.01),
    );

    final reducedGame = PropertyShotGame(
      initial,
      loadVisualAssets: false,
      reducedMotion: true,
    );
    await tester.pumpWidget(GameWidget(game: reducedGame));
    await tester.pump();
    await reducedGame.toBeLoaded();
    reducedGame.setStateSnapshot(
      finalState,
      path: result.path,
      transitionStart: initial,
      impacts: result.impacts,
      physicsEvents: physicsEvents,
    );
    reducedGame.setAnimationCursorForTest(path);
    expect(
      reducedGame.reflectorRenderOrientationForTest('reflector'),
      closeTo(4, 0.01),
    );
    expect(
      reducedGame.animationEndCursorForTest,
      closeTo(math.max(result.path.length - 1, path), 0.01),
    );
  });
}

GameState _reflectorState({required int orientation}) {
  return GameState(
    levelIndex: 0,
    levelName: '회전 반사판 시험',
    message: '반사판에 닿으면 현재 방향으로 반사한 뒤 다음 충돌부터 회전합니다.',
    ballSpawn: const Vec2(180, 440),
    entities: [
      const EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(180, 440),
        size: Vec2(24, 24),
        movable: true,
        solid: true,
      ),
      EntityState(
        id: 'reflector',
        type: EntityType.rotatingReflector,
        position: const Vec2(180, 280),
        size: const Vec2(76, 12),
        reflectorOrientation: orientation,
        movable: false,
        solid: true,
        active: true,
      ),
      const EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(310, 470),
        size: Vec2(36, 36),
        solid: false,
      ),
    ],
  );
}
