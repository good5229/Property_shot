import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/run/run_reward.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_screen.dart';
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

  for (final patternId in const ['stage_bouncy_01', 'stage_bouncy_03']) {
    testWidgets('$patternId 기믹 우회 방지 배치 Golden', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final stage = generatedStageCatalog.stageById('stage_bouncy');
      final pattern = stage.patternById(patternId);
      final level = pattern.toLevelDefinition(
        stageId: stage.stageId,
        stageTitle: stage.title,
      );

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('stage_bouncy_gimmick_golden'),
          child: PropertyShotApp(
            initialState: level.createState(1, productRules: true),
            showStageSelector: false,
            fontFamilyOverride: 'GoldenNanumGothic',
            loadGameAssets: false,
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(find.byKey(const Key('aim_area')));
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/generated/jelly-bumper-v1.png'),
          context,
        );
      });
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
        find.byType(GameWidget<PropertyShotGame>),
      );
      await gameWidgetState.currentGame.toBeLoaded();
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byKey(const Key('stage_bouncy_gimmick_golden')),
        matchesGoldenFile('goldens/${patternId}_gimmick_390x844.png'),
      );
    });
  }

  testWidgets('다음 스테이지에서도 청록·금색 공 꾸미기가 유지되는 Golden', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final stage = generatedStageCatalog.stageById('stage_bouncy');
    final pattern = stage.patternById('stage_bouncy_01');
    final level = pattern.toLevelDefinition(
      stageId: stage.stageId,
      stageTitle: stage.title,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'GoldenNanumGothic',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6B7A)),
          useMaterial3: true,
        ),
        home: RepaintBoundary(
          key: const Key('stage_bouncy_reward_ball_golden'),
          child: GameScreen(
            initialState: level.createState(1, productRules: true),
            showStageSelector: false,
            loadGameAssets: false,
            initialAcquiredRewards: const {runRewardBallAppearanceId},
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    );
    await gameWidgetState.currentGame.toBeLoaded();
    await tester.pump(const Duration(seconds: 1));

    expect(gameWidgetState.currentGame.ballRewardAppearance, isTrue);
    await expectLater(
      find.byKey(const Key('stage_bouncy_reward_ball_golden')),
      matchesGoldenFile('goldens/stage_bouncy_01_reward_ball_390x844.png'),
    );
  });
}
