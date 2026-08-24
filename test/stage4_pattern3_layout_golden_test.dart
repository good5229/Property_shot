import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/main.dart';
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

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1440x900', width: 1440.0, height: 900.0),
  ]) {
    testWidgets('4단계 3번 요소 분리 배치 ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final stage = generatedStageCatalog.stageById('stage_balloon');
      final pattern = stage.patternById('stage_balloon_03');
      final level = pattern.toLevelDefinition(
        stageId: stage.stageId,
        stageTitle: stage.title,
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('stage4_pattern3_layout_golden'),
          child: PropertyShotApp(
            initialState: level.createState(3, productRules: true),
            showStageSelector: false,
            fontFamilyOverride: 'GoldenNanumGothic',
            loadGameAssets: true,
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

      expect(find.text('4. 풍선 터뜨리기'), findsOneWidget);
      expect(find.byKey(const Key('aim_area')), findsOneWidget);
      await expectLater(
        find.byKey(const Key('stage4_pattern3_layout_golden')),
        matchesGoldenFile(
          'goldens/stage4_pattern3_separated_${fixture.name}.png',
        ),
      );
    });
  }
}
