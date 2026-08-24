import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
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
    (name: '320x568', width: 320.0, height: 568.0),
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1024x768', width: 1024.0, height: 768.0),
    (name: '1440x900', width: 1440.0, height: 900.0),
    (name: '1920x1080', width: 1920.0, height: 1080.0),
  ]) {
    testWidgets('섬 지도 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(
        fixture.name == '390x844'
            ? <String, Object>{
                ProgressStore.discoveryRecordsKey: [
                  '${levels[0].id}::heavy_equipped',
                  '${levels[0].id}::crate_moved',
                  '${levels[1].id}::bouncy_equipped',
                ],
              }
            : <String, Object>{},
      );
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('stage_select_golden'),
          child: PropertyShotApp(
            showHome: true,
            fontFamilyOverride: 'GoldenNanumGothic',
            weeklyReferenceDate: DateTime.utc(2026, 8, 24),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('stage_select_button')));
      await tester.pumpAndSettle();

      final context = tester.element(
        find.byKey(const Key('stage_select_screen')),
      );
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/generated/stage-icon-heavy-v1.png',
          'assets/generated/stage-icon-bouncy-v1.png',
          'assets/generated/stage-icon-chain-gate-v1.png',
          'assets/generated/stage-icon-sharp-balloon-v1.png',
          'assets/generated/stage-icon-property-transfer-v1.png',
          'assets/generated/stage-icon-speed-slider-v1.png',
          'assets/generated/stage-icon-persistent-ball-v1.png',
          'assets/generated/stage-icon-chain-score-v1.png',
          'assets/generated/stage-icon-rotating-reflector-v1.png',
          'assets/generated/stage-icon-finale-v1.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stage_route_map')), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(const Key('stage_select_content_column')))
            .width,
        fixture.width > 1180 ? 1180 : fixture.width,
      );
      expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
      expect(find.byKey(const Key('stage_tile_5')), findsOneWidget);
      expect(find.byKey(const Key('stage_tile_8')), findsOneWidget);
      expect(find.byKey(const Key('stage_tile_9')), findsOneWidget);
      expect(find.text('풍선은 밀리고, 뾰족한 공에는 터집니다.'), findsOneWidget);
      expect(find.text('약하게 쏜 뒤 발판에 들어가는 각도와 우회 길을 찾아 보세요.'), findsOneWidget);
      expect(find.text('반사판을 돌려 다음 공이 만날 면과 방향을 바꿔 보세요.'), findsOneWidget);
      expect(find.text('배운 속성과 기물을 엮어 나만의 경로를 완성해 보세요.'), findsOneWidget);
      expect(find.byKey(const Key('map_hint_card')), findsOneWidget);
      final expectedNavigationArt = fixture.width >= 600 ? 52.0 : 44.0;
      expect(
        tester.getSize(find.byKey(const Key('discovery_navigation_art'))),
        Size.square(expectedNavigationArt),
      );
      expect(
        tester.getSize(find.byKey(const Key('physics_lab_navigation_art'))),
        Size.square(expectedNavigationArt),
      );
      await tester.tap(find.byKey(const Key('discovery_atlas_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('discovery_atlas_sheet')), findsOneWidget);
      expect(find.byKey(const Key('discovery_atlas_stage_0')), findsOneWidget);
      expect(
        find.text('무거움 장착'),
        fixture.name == '390x844' ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.byKey(const Key('discovery_atlas_close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('island_restoration_card')), findsOneWidget);
      expect(
        find.byKey(const Key('weekly_research_goal_compact')),
        fixture.name == '320x568' ? findsOneWidget : findsNothing,
      );
      expect(
        find.byKey(const Key('weekly_research_goal')),
        fixture.name == '320x568' ? findsNothing : findsOneWidget,
      );
      for (final landmark in const ['observatory', 'lighthouse', 'bridge']) {
        expect(
          find.byKey(Key('island_landmark_art_$landmark')),
          findsOneWidget,
        );
      }
      final expectedLandmarkArt = fixture.name == '320x568'
          ? 44.0
          : fixture.width >= 600
          ? 78.0
          : 58.0;
      expect(
        tester.getSize(
          find.byKey(const Key('island_landmark_art_observatory')),
        ),
        Size.square(expectedLandmarkArt),
      );
      final expectedStageIcon = fixture.width >= 600
          ? 104.0
          : fixture.width >= 390
          ? 86.0
          : 80.0;
      expect(
        tester.getSize(find.byKey(const Key('stage_icon_0'))),
        Size.square(expectedStageIcon),
      );
      final observatorySemantics = tester
          .getSemantics(
            find.byKey(const Key('island_landmark_art_observatory')),
          )
          .getSemanticsData()
          .label;
      expect(
        observatorySemantics,
        contains(fixture.name == '390x844' ? '복구 완료' : '폐허'),
      );
      if (fixture.name == '320x568') {
        expect(
          find.byKey(const Key('island_restoration_expand')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('island_landmark_observatory')),
          findsNothing,
        );
      } else {
        expect(
          find.byKey(const Key('island_landmark_observatory')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('island_landmark_lighthouse')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('island_landmark_bridge')), findsOneWidget);
      }
      expect(
        find.byKey(const Key('island_benefit_observatory')),
        fixture.name == '390x844' ? findsOneWidget : findsNothing,
      );
      expect(
        find.textContaining('실패 원인과 충돌 순서를 자세히'),
        fixture.name == '390x844' ? findsOneWidget : findsNothing,
      );
      await expectLater(
        find.byKey(const Key('stage_select_golden')),
        matchesGoldenFile('goldens/stage_select_${fixture.name}.png'),
      );

      if (fixture.name != '320x568') {
        await tester.ensureVisible(find.byKey(const Key('stage_tile_8')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const Key('stage_select_golden')),
          matchesGoldenFile('goldens/stage_select_stage9_${fixture.name}.png'),
        );

        await tester.ensureVisible(find.byKey(const Key('stage_tile_9')));
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const Key('stage_select_golden')),
          matchesGoldenFile('goldens/stage_select_stage10_${fixture.name}.png'),
        );
      }
    });
  }
}
