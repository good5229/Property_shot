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
          'assets/icons/stone_boulder.png',
          'assets/generated/jelly-bumper-v1.png',
          'assets/icons/crate.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('stage_route_map')), findsOneWidget);
      expect(find.byKey(const Key('map_hint_card')), findsOneWidget);
      await expectLater(
        find.byKey(const Key('stage_select_golden')),
        matchesGoldenFile('goldens/stage_select_${fixture.name}.png'),
      );
    });
  }
}
