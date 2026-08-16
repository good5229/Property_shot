import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/domain/trait.dart';
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

  for (final stageIndex in List<int>.generate(
    levels.length,
    (index) => index,
  )) {
    for (final fixture in const [
      (name: '390x844', width: 390.0, height: 844.0),
      (name: '768x1024', width: 768.0, height: 1024.0),
    ]) {
      testWidgets('생성 스프라이트 전체 오브젝트 ${stageIndex + 1}단계 Golden ${fixture.name}', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await tester.binding.setSurfaceSize(
          Size(fixture.width, fixture.height),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('generated_gimmick_golden'),
            child: PropertyShotApp(
              initialState: levels[stageIndex].createState(
                stageIndex,
                productRules: true,
              ),
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

        expect(find.byKey(const Key('aim_area')), findsOneWidget);
        await expectLater(
          find.byKey(const Key('generated_gimmick_golden')),
          matchesGoldenFile(
            'goldens/generated_gimmick_stage${stageIndex + 1}_${fixture.name}.png',
          ),
        );
      });
    }
  }

  for (final trait in TraitType.values) {
    for (final fixture in const [
      (name: '390x844', width: 390.0, height: 844.0),
      (name: '768x1024', width: 768.0, height: 1024.0),
    ]) {
      testWidgets('속성 공 ${trait.name} Golden ${fixture.name}', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await tester.binding.setSurfaceSize(
          Size(fixture.width, fixture.height),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final base = levels.first.createState(0, productRules: true);
        final state = base.copyWith(
          entities: [
            for (final entity in base.entities)
              entity.id == 'active_ball'
                  ? entity.copyWith(traits: {trait})
                  : entity,
          ],
        );

        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('generated_gimmick_golden'),
            child: PropertyShotApp(
              initialState: state,
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

        await expectLater(
          find.byKey(const Key('generated_gimmick_golden')),
          matchesGoldenFile(
            'goldens/generated_ball_${trait.name}_${fixture.name}.png',
          ),
        );
      });
    }
  }
}
