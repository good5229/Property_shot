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
import 'package:property_shot/ui/debug_labels.dart';
import 'package:property_shot/ui/play_telemetry.dart';
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
      'activated',
      'popup',
      'reduced',
      'vertical',
    ]) {
      testWidgets('파워 슬라이더 $variant Golden ${fixture.name}', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        GameFeedback.reducedMotionEnabled = variant == 'reduced';
        addTearDown(() {
          GameFeedback.reducedMotionEnabled = false;
          tester.binding.setSurfaceSize(null);
        });
        await tester.binding.setSurfaceSize(
          Size(fixture.width, fixture.height),
        );
        final initial = _sliderState(
          direction: variant == 'vertical'
              ? const Vec2(0, 1)
              : const Vec2(1, 0),
        );
        final telemetry = LocalPlayTelemetry();
        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('power_slider_golden'),
            child: PropertyShotApp(
              initialState: initial,
              showStageSelector: false,
              fontFamilyOverride: 'GoldenNanumGothic',
              loadGameAssets: false,
              telemetry: telemetry,
            ),
          ),
        );
        await tester.pump();
        final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        );
        final game = gameWidgetState.currentGame;
        await game.toBeLoaded();
        if (variant == 'popup') {
          await tester.runAsync(
            () => precacheImage(
              const AssetImage('assets/generated/power-slider-v1.png'),
              tester.element(find.byType(GameWidget<PropertyShotGame>)),
            ),
          );
          await tester.pump();
        }

        if (variant == 'activated' || variant == 'reduced') {
          final result = const ShotResolver().resolve(
            initial,
            const ShotInput(direction: Vec2(1, 0), power: 0.45),
          );
          game.setStateSnapshot(
            result.state,
            path: result.path,
            transitionStart: initial,
            impacts: result.impacts,
            moves: result.moves,
            physicsEvents: result.physicsEvents,
          );
          for (var frame = 0; frame < 10; frame++) {
            await tester.pump(const Duration(milliseconds: 34));
          }
        } else if (variant == 'popup') {
          final sliderTarget = find.bySemanticsLabel(RegExp('^파워 슬라이더, 기준'));
          expect(sliderTarget, findsOneWidget);
          final aimRect = tester.getRect(find.byKey(const Key('aim_area')));
          final aimScale = math.min(aimRect.width / 360, aimRect.height / 560);
          final aimOrigin = Offset(
            aimRect.left + (aimRect.width - 360 * aimScale) / 2,
            aimRect.top + (aimRect.height - 560 * aimScale) / 2,
          );
          for (final point in const [
            (x: 150.0, y: 260.0),
            (x: 170.0, y: 260.0),
            (x: 190.0, y: 260.0),
            (x: 150.0, y: 280.0),
            (x: 170.0, y: 280.0),
            (x: 190.0, y: 280.0),
            (x: 150.0, y: 300.0),
            (x: 170.0, y: 300.0),
            (x: 190.0, y: 300.0),
          ]) {
            await tester.tapAt(
              aimOrigin + Offset(point.x * aimScale, point.y * aimScale),
            );
            await tester.pump();
            if (find
                .byKey(const Key('info_close_button'))
                .evaluate()
                .isNotEmpty) {
              break;
            }
          }
          expect(
            find.text('기물을 기준 속력까지 올립니다. 진행 방향은 유지되고 같은 접촉에는 한 번만 적용됩니다.'),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('entity_thumbnail_powerSlider')),
            findsOneWidget,
          );
          await tester.pump(const Duration(milliseconds: 100));
        } else {
          await tester.pump(const Duration(milliseconds: 80));
        }

        await expectLater(
          find.byKey(const Key('power_slider_golden')),
          matchesGoldenFile(
            'goldens/power_slider_${variant}_${fixture.name}.png',
          ),
        );
      });
    }
  }

  testWidgets('물리 이벤트 재생 시 파워 슬라이더 피드백은 같은 ID로 한 번만 전달된다', (tester) async {
    final initial = _sliderState();
    final received = <PhysicsEvent>[];
    final game = PropertyShotGame(
      initial,
      loadVisualAssets: false,
      onPhysicsEvent: received.add,
    );
    await tester.pumpWidget(GameWidget<PropertyShotGame>(game: game));
    await tester.pump();
    await game.toBeLoaded();
    final result = const ShotResolver().resolve(
      initial,
      const ShotInput(direction: Vec2(1, 0), power: 0.45),
    );
    game.setStateSnapshot(
      result.state,
      path: result.path,
      transitionStart: initial,
      impacts: result.impacts,
      moves: result.moves,
      physicsEvents: result.physicsEvents,
    );
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 34));
    }
    final sliderEvents = received.where(
      (event) => event.kind == PhysicsEventKind.powerSliderActivation,
    );
    expect(sliderEvents, hasLength(1));
    expect(sliderEvents.single.resultingVelocity.length, greaterThan(0));
  });

  test('파워 슬라이더 텔레메트리는 한글 사건과 안정 필드를 기록한다', () {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    telemetry.record(
      '파워 슬라이더 작동',
      stage: 0,
      eventCode: 'power_slider_activated',
      target: 'slider',
      objectId: 'active_ball',
      contactId: 'active_ball:slider',
      speed: 30,
      speedBefore: 18,
      speedAfter: 30,
      referenceSpeed: 30,
    );
    final event = telemetry.events.single;
    expect(event['유형'], '파워 슬라이더 작동');
    expect(event['event_code'], 'power_slider_activated');
    expect(event['contact_id'], 'active_ball:slider');
    expect(event['speed_after'], 30);
    expect(debugEntityLabel('slider'), '파워 슬라이더');
    expect(debugEntityTypeLabel('powerSlider'), '파워 슬라이더');
    expect(debugPhysicsEventLabel('powerSliderActivation'), '파워 슬라이더 작동');
  });
}

GameState _sliderState({Vec2 direction = const Vec2(1, 0)}) {
  const active = EntityState(
    id: 'active_ball',
    type: EntityType.ball,
    position: Vec2(40, 280),
    size: Vec2(24, 24),
    movable: true,
    solid: true,
  );
  return GameState(
    levelIndex: 0,
    levelName: '파워 슬라이더 시험',
    ballSpawn: Vec2(40, 280),
    message: '파란 영역을 지나면 공의 힘이 유지됩니다.',
    entities: [
      active,
      EntityState(
        id: 'power_slider',
        type: EntityType.powerSlider,
        position: Vec2(170, 280),
        size: Vec2(52, 64),
        solid: false,
        direction: direction,
        referenceSpeed: 30,
        allowedTargets: {EntityType.ball},
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(310, 455),
        size: Vec2(38, 38),
        solid: false,
      ),
    ],
  );
}
