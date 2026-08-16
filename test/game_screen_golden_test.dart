import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:property_shot/game/levels/levels.dart';
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

  for (var stageIndex = 0; stageIndex < levels.length; stageIndex++) {
    for (final fixture in const [
      (name: '320x568', width: 320.0, height: 568.0),
      (name: '375x812', width: 375.0, height: 812.0),
      (name: '390x844', width: 390.0, height: 844.0),
      (name: '393x852', width: 393.0, height: 852.0),
      (name: '430x932', width: 430.0, height: 932.0),
      (name: '768x1024', width: 768.0, height: 1024.0),
      (name: '1024x768', width: 1024.0, height: 768.0),
      (name: '1024x1366', width: 1024.0, height: 1366.0),
      (name: '1440x900', width: 1440.0, height: 900.0),
      (name: '1920x1080', width: 1920.0, height: 1080.0),
    ]) {
      testWidgets('전체 플레이 화면 Golden ${stageIndex + 1}단계 ${fixture.name}', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await tester.binding.setSurfaceSize(
          Size(fixture.width, fixture.height),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('game_screen_golden'),
            child: PropertyShotApp(
              initialState: levels[stageIndex]
                  .createState(stageIndex, productRules: true)
                  .copyWith(
                    message: switch (stageIndex) {
                      3 => '풍선 확인 · 여러 경로로 도전',
                      4 => '공과 원본의 변화를 함께 살펴보세요',
                      _ => '방향 조정 · 길게 누르기 · 손 떼기',
                    },
                  ),
              showStageSelector: false,
              fontFamilyOverride: 'GoldenNanumGothic',
              loadGameAssets: false,
            ),
          ),
        );
        await tester.pump();

        final context = tester.element(find.byKey(const Key('aim_area')));
        await tester.runAsync(() async {
          for (final asset in const [
            'assets/generated/stone-v3.png',
            'assets/generated/crate-v3.png',
            'assets/generated/jelly-bumper-v2.png',
          ]) {
            await precacheImage(AssetImage(asset), context);
          }
        });
        // Flame의 onLoad와 실제 첫 렌더 프레임이 완료될 때까지 이벤트 루프를 진행한다.
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        );
        await gameWidgetState.currentGame.toBeLoaded();
        await tester.pump(const Duration(seconds: 1));

        expect(find.byKey(const Key('aim_area')), findsOneWidget);
        expect(find.byKey(const Key('compact_message')), findsOneWidget);
        expect(find.text(levels[stageIndex].name), findsOneWidget);
        await expectLater(
          find.byKey(const Key('game_screen_golden')),
          matchesGoldenFile(
            'goldens/game_screen_stage${stageIndex + 1}_${fixture.name}.png',
          ),
        );
      });
    }
  }
}
