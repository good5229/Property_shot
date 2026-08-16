import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';

void main() {
  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

  testWidgets('정상 충전 release는 실제 발사 흐름에 들어간다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final rect = tester.getRect(area);
    final scale = rect.width / 360 < rect.height / 560
        ? rect.width / 360
        : rect.height / 560;
    final origin = Offset(
      rect.left + (rect.width - 360 * scale) / 2,
      rect.top + (rect.height - 560 * scale) / 2,
    );
    final gesture = await tester.createGesture();
    await gesture.down(
      origin + Offset(56 * scale, 456 * scale),
      timeStamp: Duration.zero,
    );
    await tester.pump(const Duration(milliseconds: 760));
    await gesture.up(timeStamp: const Duration(milliseconds: 760));
    await tester.pump();

    expect(_currentShotCount(tester), 1);
  });

  testWidgets('과충전 release는 시도와 물리 발사를 만들지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final rect = tester.getRect(area);
    final scale = rect.width / 360 < rect.height / 560
        ? rect.width / 360
        : rect.height / 560;
    final origin = Offset(
      rect.left + (rect.width - 360 * scale) / 2,
      rect.top + (rect.height - 560 * scale) / 2,
    );
    final gesture = await tester.createGesture();
    await gesture.down(
      origin + Offset(56 * scale, 456 * scale),
      timeStamp: Duration.zero,
    );
    await _pumpChargeFrames(tester, const Duration(milliseconds: 2280));
    expect(
      tester
          .getSemantics(find.byKey(const Key('charge_gauge_live_state')))
          .getSemanticsData()
          .value,
      '회색 · 발사 취소',
    );
    expect(find.textContaining('회색 · 발사 취소 · 손을 떼면 발사됩니다'), findsNothing);
    await gesture.up(timeStamp: const Duration(milliseconds: 2280));
    await tester.pump();

    expect(_currentShotCount(tester), 0);
    expect(
      tester
          .getSemantics(find.byKey(const Key('compact_message')))
          .getSemanticsData()
          .label,
      contains('과충전되어 발사를 취소했습니다'),
    );
    expect(find.byKey(const Key('charge_gauge_rail')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 449));
    expect(find.byKey(const Key('charge_gauge_rail')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2));
    expect(find.byKey(const Key('charge_gauge_rail')), findsNothing);
  });

  testWidgets('과충전 취소 뒤 새 포인터 입력은 초록에서 다시 시작해 발사한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final rect = tester.getRect(area);
    final scale = rect.width / 360 < rect.height / 560
        ? rect.width / 360
        : rect.height / 560;
    final ballPosition = Offset(
      rect.left + (rect.width - 360 * scale) / 2 + 56 * scale,
      rect.top + (rect.height - 560 * scale) / 2 + 456 * scale,
    );

    final overcharged = await tester.createGesture(pointer: 71);
    await overcharged.down(ballPosition, timeStamp: Duration.zero);
    await tester.pump(const Duration(milliseconds: 2200));
    await overcharged.up(timeStamp: const Duration(milliseconds: 2200));
    await tester.pump();
    expect(_currentShotCount(tester), 0);

    final retry = await tester.createGesture(pointer: 72);
    await retry.down(
      ballPosition,
      timeStamp: const Duration(milliseconds: 2300),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await retry.up(timeStamp: const Duration(milliseconds: 3060));
    await tester.pump();

    expect(_currentShotCount(tester), 1);
  });

  testWidgets('활성화 지연 450ms 전에는 rail을 숨기고 시작 시 최소 힘을 표시한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final gesture = await tester.createGesture();
    await gesture.down(_ballPosition(tester, area), timeStamp: Duration.zero);

    expect(find.byKey(const Key('charge_gauge_rail')), findsNothing);
    await tester.pump(const Duration(milliseconds: 449));
    expect(find.byKey(const Key('charge_gauge_rail')), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    expect(find.byKey(const Key('charge_gauge_rail')), findsOneWidget);
    expect(find.text('12%'), findsOneWidget);

    await gesture.up(timeStamp: const Duration(milliseconds: 450));
    await tester.pump();
  });

  testWidgets('liveRegion은 단계만 알리고 80ms 힘 퍼센트는 비-live로 분리한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final gesture = await tester.createGesture();
    await gesture.down(_ballPosition(tester, area), timeStamp: Duration.zero);
    await _pumpChargeFrames(tester, const Duration(milliseconds: 640));

    final live = find.byKey(const Key('charge_gauge_live_state'));
    final rail = find.byKey(const Key('charge_gauge_rail'));
    expect(tester.widget<Semantics>(live).properties.liveRegion, isTrue);
    expect(tester.widget<Semantics>(rail).properties.liveRegion, isNot(isTrue));
    final firstLiveValue = tester.getSemantics(live).getSemanticsData().value;
    final firstRailValue = tester.getSemantics(rail).getSemanticsData().value;
    expect(firstLiveValue, contains('초록 · 약한 힘'));
    expect(firstLiveValue, isNot(contains('퍼센트')));
    expect(firstRailValue, contains('퍼센트'));

    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getSemantics(live).getSemanticsData().value, firstLiveValue);
    expect(
      tester.getSemantics(rail).getSemanticsData().value,
      isNot(firstRailValue),
    );

    await gesture.cancel();
    await tester.pump();
  });

  testWidgets('warningRed만 시간에 따라 점멸한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final gesture = await tester.createGesture();
    await gesture.down(_ballPosition(tester, area), timeStamp: Duration.zero);
    await _pumpChargeFrames(tester, const Duration(milliseconds: 1680));

    final before = _flashOpacity(tester);
    await tester.pump(const Duration(milliseconds: 125));
    final after = _flashOpacity(tester);
    expect(after, isNot(closeTo(before, 0.001)));

    await gesture.cancel();
    await tester.pump();
  });

  for (final staticMode in const [
    (name: '저모션', reducedMotion: true, strongFlash: true),
    (name: '강한 점멸 끔', reducedMotion: false, strongFlash: false),
  ]) {
    testWidgets('warningRed는 ${staticMode.name}에서 정적이다', (tester) async {
      GameFeedback.reducedMotionEnabled = staticMode.reducedMotion;
      GameFeedback.strongFlashEnabled = staticMode.strongFlash;
      await tester.pumpWidget(const PropertyShotApp());
      await tester.pump();
      final area = find.byKey(const Key('aim_area'));
      final gesture = await tester.createGesture();
      await gesture.down(_ballPosition(tester, area), timeStamp: Duration.zero);
      await _pumpChargeFrames(tester, const Duration(milliseconds: 1680));

      expect(_flashOpacity(tester), 1);
      await tester.pump(const Duration(milliseconds: 125));
      expect(_flashOpacity(tester), 1);

      await gesture.cancel();
      await tester.pump();
    });
  }

  testWidgets('빨강 단계는 강한 점멸 설정에서도 정적이다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final gesture = await tester.createGesture();
    await gesture.down(_ballPosition(tester, area), timeStamp: Duration.zero);
    await _pumpChargeFrames(tester, const Duration(milliseconds: 1440));

    expect(_flashOpacity(tester), 1);
    await tester.pump(const Duration(milliseconds: 125));
    expect(_flashOpacity(tester), 1);

    await gesture.cancel();
    await tester.pump();
  });

  testWidgets('중앙 공에서는 left/right 설정이 서로 다른 floating 위치를 쓴다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final initial = levels.first.createState(0, productRules: true);
    final centered = initial.copyWith(
      entities: [
        for (final entity in initial.entities)
          entity.id == 'active_ball'
              ? entity.copyWith(position: const Vec2(180, 280))
              : entity,
      ],
    );
    final centers = <ChargeGaugeSide, double>{};
    for (final side in ChargeGaugeSide.values) {
      GameFeedback.chargeGaugeSide = side;
      await tester.pumpWidget(
        PropertyShotApp(
          initialState: centered,
          showStageSelector: false,
          loadGameAssets: false,
        ),
      );
      await tester.pump();
      final area = find.byKey(const Key('aim_area'));
      final gesture = await tester.createGesture();
      await gesture.down(
        _logicalPosition(tester, area, 180, 280),
        timeStamp: Duration.zero,
      );
      await _pumpChargeFrames(tester, const Duration(milliseconds: 600));
      centers[side] = tester
          .getRect(find.byKey(const Key('charge_gauge_rail')))
          .center
          .dx;
      await gesture.cancel();
      await tester.pump();
    }
    expect(
      centers[ChargeGaugeSide.left],
      lessThan(centers[ChargeGaugeSide.right]!),
    );
  });

  for (final stageIndex in const [0, 3]) {
    for (final side in ChargeGaugeSide.values) {
      testWidgets(
        '${stageIndex + 1}단계 핵심 목표와 ${side.name} floating rail은 겹치지 않는다',
        (tester) async {
          GameFeedback.chargeGaugeSide = side;
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final state = levels[stageIndex].createState(
            stageIndex,
            productRules: true,
          );
          await tester.pumpWidget(
            PropertyShotApp(
              initialState: state,
              showStageSelector: false,
              loadGameAssets: false,
            ),
          );
          await tester.pump();
          final area = find.byKey(const Key('aim_area'));
          final ball = state.activeBall.position;
          final gesture = await tester.createGesture();
          await gesture.down(
            _logicalPosition(tester, area, ball.x, ball.y),
            timeStamp: Duration.zero,
          );
          await _pumpChargeFrames(tester, const Duration(milliseconds: 1680));

          final railRect = tester.getRect(
            find.byKey(const Key('charge_gauge_rail')),
          );
          final target = stageIndex == 0
              ? find.bySemanticsLabel('홀, 목표 홀')
              : find.bySemanticsLabel('풍선, 풍선');
          expect(target, findsOneWidget);
          expect(railRect.width, lessThanOrEqualTo(40));
          expect(railRect.overlaps(tester.getRect(target)), isFalse);

          await gesture.cancel();
          await tester.pump();
        },
      );
    }
  }

  for (final fixture in const [
    (size: Size(320, 568), textScale: 1.5),
    (size: Size(375, 812), textScale: 1.0),
    (size: Size(390, 844), textScale: 1.0),
    (size: Size(430, 932), textScale: 1.0),
    (size: Size(768, 1024), textScale: 1.0),
    (size: Size(1024, 1366), textScale: 1.0),
  ]) {
    for (final side in ChargeGaugeSide.values) {
      testWidgets(
        '${fixture.size.width.toInt()}x${fixture.size.height.toInt()} ${side.name} 게이지는 SafeArea 안에서 터치를 가리지 않는다',
        (tester) async {
          GameFeedback.chargeGaugeSide = side;
          GameFeedback.reducedMotionEnabled = true;
          await tester.binding.setSurfaceSize(fixture.size);
          addTearDown(() {
            tester.binding.setSurfaceSize(null);
            tester.view.reset();
          });
          tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: fixture.size,
                textScaler: TextScaler.linear(fixture.textScale),
              ),
              child: const PropertyShotApp(),
            ),
          );
          await tester.pump();
          final area = find.byKey(const Key('aim_area'));
          final ballPosition = _ballPosition(tester, area);
          final gesture = await tester.createGesture();
          await gesture.down(ballPosition, timeStamp: Duration.zero);
          await _pumpChargeFrames(tester, const Duration(milliseconds: 1680));

          final rail = find.byKey(const Key('charge_gauge_rail'));
          expect(rail, findsOneWidget);
          expect(find.byKey(Key('charge_gauge_${side.name}')), findsOneWidget);
          final screenRect = tester.getRect(find.byType(Scaffold).last);
          final railRect = tester.getRect(rail);
          expect(screenRect.contains(railRect.topLeft), isTrue);
          expect(screenRect.contains(railRect.bottomRight), isTrue);
          // 게이지는 더 이상 화면 가장자리에 고정하지 않는다. 공 쪽에
          // 떠 있으면서도 보드/SafeArea 안에서만 움직여야 한다.
          expect(railRect.left, greaterThan(screenRect.left));
          expect(railRect.right, lessThan(screenRect.right));
          final boardRect = tester.getRect(find.byKey(const Key('aim_area')));
          final compactControls = find.byKey(
            const Key('compact_control_panel'),
          );
          // Compact 하단 조작 surface는 월드/열쇠가 놓이는 보드 위를 덮지
          // 않는다. 넓은 화면에서는 sidebar controls를 사용한다.
          if (compactControls.evaluate().isNotEmpty) {
            final controlsRect = tester.getRect(compactControls);
            expect(controlsRect.overlaps(boardRect), isFalse);
          }
          final devicePixelRatio = tester.view.devicePixelRatio;
          expect(
            railRect.top,
            greaterThanOrEqualTo(tester.view.padding.top / devicePixelRatio),
          );
          expect(
            railRect.bottom,
            lessThanOrEqualTo(
              fixture.size.height -
                  tester.view.padding.bottom / devicePixelRatio,
            ),
          );
          final semantics = tester.getSemantics(rail);
          expect(semantics.getSemanticsData().label, '충전 게이지');
          expect(
            semantics.getSemanticsData().value,
            contains(side == ChargeGaugeSide.right ? '오른쪽' : '왼쪽'),
          );
          expect(semantics.getSemanticsData().value, contains('퍼센트'));
          final liveSemantics = tester.getSemantics(
            find.byKey(const Key('charge_gauge_live_state')),
          );
          expect(liveSemantics.getSemanticsData().value, contains('과충전 직전'));
          expect(
            liveSemantics.getSemanticsData().value,
            isNot(contains('퍼센트')),
          );
          expect(tester.takeException(), isNull);

          await gesture.up(timeStamp: const Duration(milliseconds: 1680));
          await tester.pump();
          expect(_currentShotCount(tester), 1);
        },
      );
    }
  }
}

int _currentShotCount(WidgetTester tester) => tester
    .widget<GameWidget<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    )
    .game!
    .state
    .shotCount;

Future<void> _pumpChargeFrames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 80);
  var elapsed = Duration.zero;
  while (elapsed + frame <= duration) {
    await tester.pump(frame);
    elapsed += frame;
  }
  if (elapsed < duration) {
    await tester.pump(duration - elapsed);
  }
}

Offset _ballPosition(WidgetTester tester, Finder area) {
  return _logicalPosition(tester, area, 56, 456);
}

Offset _logicalPosition(
  WidgetTester tester,
  Finder area,
  double logicalX,
  double logicalY,
) {
  final rect = tester.getRect(area);
  final scale = rect.width / 360 < rect.height / 560
      ? rect.width / 360
      : rect.height / 560;
  return Offset(
    rect.left + (rect.width - 360 * scale) / 2 + logicalX * scale,
    rect.top + (rect.height - 560 * scale) / 2 + logicalY * scale,
  );
}

double _flashOpacity(WidgetTester tester) {
  return tester
      .widget<Opacity>(find.byKey(const Key('charge_gauge_flash_opacity')))
      .opacity;
}
