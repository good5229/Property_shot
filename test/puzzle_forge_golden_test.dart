import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/puzzle_forge_screen.dart';

void main() {
  late PuzzleForgeSummary summary;

  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
    summary = await loadPuzzleForgeSummary();
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1440x900', width: 1440.0, height: 900.0),
  ]) {
    testWidgets('Puzzle Forge Golden ${fixture.name}', (tester) async {
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'GoldenNanumGothic', useMaterial3: true),
          home: RepaintBoundary(
            key: const Key('puzzle_forge_golden'),
            child: PuzzleForgeScreen(onBack: () {}, summary: summary),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (fixture.name == '390x844') {
        final context = tester.element(
          find.byKey(const Key('puzzle_forge_screen')),
        );
        await tester.runAsync(() async {
          for (final asset in const [
            'assets/generated/nav-helm-v1.png',
            'assets/generated/stage-icon-property-transfer-v1.png',
            'assets/generated/nav-stage-map-v1.png',
            'assets/generated/island-observatory-v2.png',
          ]) {
            await precacheImage(AssetImage(asset), context);
          }
        });
      }
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('puzzle_forge_golden')),
        matchesGoldenFile('goldens/puzzle_forge_${fixture.name}.png'),
      );
    });
  }
}
