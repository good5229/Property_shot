import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
  ]) {
    testWidgets('섬 지도 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('stage_select_golden'),
          child: const PropertyShotApp(
            showHome: true,
            fontFamilyOverride: 'GoldenNanumGothic',
          ),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('stage_select_button')));
      await tester.pump();

      final context = tester.element(
        find.byKey(const Key('stage_select_screen')),
      );
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/generated/jelly-bumper-v1.png',
          'assets/generated/crate-v2.png',
          'assets/generated/stone-v2.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stage_route_map')), findsOneWidget);
      expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
      expect(find.byKey(const Key('stage_tile_5')), findsOneWidget);
      expect(find.byKey(const Key('stage_tile_8')), findsOneWidget);
      expect(find.byKey(const Key('stage_tile_9')), findsOneWidget);
      expect(find.text('풍선은 밀리고, 뾰족한 공에는 터집니다.'), findsOneWidget);
      expect(find.text('약하게 쏜 뒤 발판에 들어가는 각도와 우회 길을 찾아 보세요.'), findsOneWidget);
      expect(find.text('반사판을 돌려 다음 공이 만날 면과 방향을 바꿔 보세요.'), findsOneWidget);
      expect(find.text('배운 속성과 기물을 엮어 나만의 경로를 완성해 보세요.'), findsOneWidget);
      expect(find.byKey(const Key('map_hint_card')), findsOneWidget);
      await expectLater(
        find.byKey(const Key('stage_select_golden')),
        matchesGoldenFile('goldens/stage_select_${fixture.name}.png'),
      );

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
    });
  }
}
