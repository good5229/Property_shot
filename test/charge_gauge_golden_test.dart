import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/launch_input_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    for (final side in ChargeGaugeSide.values) {
      for (final gaugeState in ChargeGaugeState.values) {
        testWidgets(
          '충전 게이지 ${gaugeState.name} ${side.name} Golden ${fixture.name}',
          (tester) async {
            GameFeedback.chargeGaugeSide = side;
            await _pumpGame(tester, fixture.width, fixture.height);
            final gesture = await _holdCharge(tester, gaugeState);

            await expectLater(
              find.byKey(const Key('game_screen_golden')),
              matchesGoldenFile(
                'goldens/charge_gauge_${gaugeState.name}_${side.name}_${fixture.name}.png',
              ),
            );
            await gesture.cancel();
            await tester.pump();
          },
        );
      }
    }
  }

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    for (final side in ChargeGaugeSide.values) {
      for (final gaugeState in const [
        ChargeGaugeState.warningRed,
        ChargeGaugeState.cancelledGray,
      ]) {
        testWidgets(
          '저모션 충전 게이지 ${gaugeState.name} ${side.name} Golden ${fixture.name}',
          (tester) async {
            GameFeedback.reducedMotionEnabled = true;
            GameFeedback.chargeGaugeSide = side;
            await _pumpGame(tester, fixture.width, fixture.height);
            final gesture = await _holdCharge(tester, gaugeState);

            await expectLater(
              find.byKey(const Key('game_screen_golden')),
              matchesGoldenFile(
                'goldens/charge_gauge_${gaugeState.name}_${side.name}_reduced_motion_${fixture.name}.png',
              ),
            );
            await gesture.cancel();
            await tester.pump();
          },
        );
      }
    }
  }

  for (final side in ChargeGaugeSide.values) {
    testWidgets('4단계 핵심 목표와 ${side.name} edge rail Golden', (tester) async {
      GameFeedback.chargeGaugeSide = side;
      await _pumpGame(tester, 390, 844, stageIndex: 3);
      final gesture = await _holdCharge(
        tester,
        ChargeGaugeState.warningRed,
        stageIndex: 3,
      );
      final railRect = tester.getRect(
        find.byKey(const Key('charge_gauge_rail')),
      );
      final balloon = find.bySemanticsLabel('풍선, 풍선');
      expect(balloon, findsOneWidget);
      expect(railRect.overlaps(tester.getRect(balloon)), isFalse);

      await expectLater(
        find.byKey(const Key('game_screen_golden')),
        matchesGoldenFile(
          'goldens/charge_gauge_stage4_warningRed_${side.name}_390x844.png',
        ),
      );
      await gesture.cancel();
      await tester.pump();
    });
  }
}

Future<void> _pumpGame(
  WidgetTester tester,
  double width,
  double height, {
  int stageIndex = 0,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  GameFeedback.hapticsEnabled = false;
  GameFeedback.soundEnabled = false;
  GameFeedback.backgroundMusicEnabled = false;
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('game_screen_golden'),
      child: PropertyShotApp(
        initialState: levels[stageIndex]
            .createState(stageIndex, productRules: true)
            .copyWith(message: '충전 상태를 확인하세요'),
        showStageSelector: false,
        fontFamilyOverride: 'GoldenNanumGothic',
        loadGameAssets: false,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<TestGesture> _holdCharge(
  WidgetTester tester,
  ChargeGaugeState state, {
  int stageIndex = 0,
}) async {
  final area = find.byKey(const Key('aim_area'));
  final ball = levels[stageIndex]
      .createState(stageIndex, productRules: true)
      .activeBall
      .position;
  final gesture = await tester.createGesture();
  await gesture.down(
    _logicalPosition(tester, area, ball.x, ball.y),
    timeStamp: Duration.zero,
  );
  await _pumpChargeFrames(tester, _holdDuration(state));
  if (state == ChargeGaugeState.cancelledGray) {
    await tester.pump(const Duration(milliseconds: 80));
  }
  final rail = find.byKey(const Key('charge_gauge_rail'));
  expect(rail, findsOneWidget);
  expect(
    find.byKey(Key('charge_gauge_${GameFeedback.chargeGaugeSide.name}')),
    findsOneWidget,
  );
  final expectedLabel = switch (state) {
    ChargeGaugeState.green => '약',
    ChargeGaugeState.yellow => '중',
    ChargeGaugeState.red => '강',
    ChargeGaugeState.warningRed => '주의',
    ChargeGaugeState.cancelledGray => '취소',
  };
  final expectedIcon = switch (state) {
    ChargeGaugeState.green => Icons.eco,
    ChargeGaugeState.yellow => Icons.bolt,
    ChargeGaugeState.red => Icons.local_fire_department,
    ChargeGaugeState.warningRed => Icons.warning_amber_rounded,
    ChargeGaugeState.cancelledGray => Icons.close,
  };
  expect(
    find.descendant(of: rail, matching: find.text(expectedLabel)),
    findsOneWidget,
  );
  expect(
    find.descendant(of: rail, matching: find.byIcon(expectedIcon)),
    findsOneWidget,
  );
  expect(
    tester
        .getSemantics(find.byKey(const Key('charge_gauge_live_state')))
        .getSemanticsData()
        .value,
    contains(_semanticStateLabel(state)),
  );
  return gesture;
}

Offset _logicalPosition(
  WidgetTester tester,
  Finder area,
  double logicalX,
  double logicalY,
) {
  final rect = tester.getRect(area);
  final scale = math.min(rect.width / 360, rect.height / 560);
  return Offset(
    rect.left + (rect.width - 360 * scale) / 2 + logicalX * scale,
    rect.top + (rect.height - 560 * scale) / 2 + logicalY * scale,
  );
}

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

String _semanticStateLabel(ChargeGaugeState state) {
  return switch (state) {
    ChargeGaugeState.green => '초록 · 약한 힘',
    ChargeGaugeState.yellow => '노랑 · 보통 힘',
    ChargeGaugeState.red => '빨강 · 강한 힘',
    ChargeGaugeState.warningRed => '경고 빨강 · 과충전 직전',
    ChargeGaugeState.cancelledGray => '회색 · 발사 취소',
  };
}

Duration _holdDuration(ChargeGaugeState state) {
  return switch (state) {
    ChargeGaugeState.green => const Duration(milliseconds: 640),
    ChargeGaugeState.yellow => const Duration(milliseconds: 1080),
    ChargeGaugeState.red => const Duration(milliseconds: 1440),
    ChargeGaugeState.warningRed => const Duration(milliseconds: 1680),
    ChargeGaugeState.cancelledGray => const Duration(milliseconds: 2280),
  };
}
