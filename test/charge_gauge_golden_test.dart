import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
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
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    for (final gaugeState in ChargeGaugeState.values) {
      testWidgets('충전 게이지 ${gaugeState.name} Golden ${fixture.name}', (
        tester,
      ) async {
        await _pumpGame(tester, fixture.width, fixture.height);
        final game = _game(tester);
        game.setStateSnapshot(
          game.state.copyWith(aimPower: _representativePower(gaugeState)),
        );
        game.setChargeGaugeState(gaugeState, active: true);
        await tester.pump();

        await expectLater(
          find.byKey(const Key('game_screen_golden')),
          matchesGoldenFile(
            'goldens/charge_gauge_${gaugeState.name}_${fixture.name}.png',
          ),
        );
      });
    }
  }

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    for (final gaugeState in const [
      ChargeGaugeState.warningRed,
      ChargeGaugeState.cancelledGray,
    ]) {
      testWidgets('저모션 충전 게이지 ${gaugeState.name} Golden ${fixture.name}', (
        tester,
      ) async {
        GameFeedback.reducedMotionEnabled = true;
        addTearDown(() => GameFeedback.reducedMotionEnabled = false);
        await _pumpGame(tester, fixture.width, fixture.height);
        final game = _game(tester);
        game.setStateSnapshot(
          game.state.copyWith(aimPower: _representativePower(gaugeState)),
        );
        game.setChargeGaugeState(gaugeState, active: true);
        await tester.pump();

        await expectLater(
          find.byKey(const Key('game_screen_golden')),
          matchesGoldenFile(
            'goldens/charge_gauge_${gaugeState.name}_reduced_motion_${fixture.name}.png',
          ),
        );
      });
    }
  }
}

Future<void> _pumpGame(WidgetTester tester, double width, double height) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    RepaintBoundary(
      key: const Key('game_screen_golden'),
      child: PropertyShotApp(
        initialState: levels.first
            .createState(0, productRules: true)
            .copyWith(message: '충전 상태를 확인하세요'),
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
  await gameWidgetState.currentGame.toBeLoaded();
  await tester.pump(const Duration(milliseconds: 80));
}

PropertyShotGame _game(WidgetTester tester) {
  final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
    find.byType(GameWidget<PropertyShotGame>),
  );
  return gameWidgetState.currentGame;
}

double _representativePower(ChargeGaugeState state) {
  return switch (state) {
    ChargeGaugeState.green => 0.25,
    ChargeGaugeState.yellow => 0.55,
    ChargeGaugeState.red => 0.80,
    ChargeGaugeState.warningRed => 0.96,
    ChargeGaugeState.cancelledGray => 1.0,
  };
}
