import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/island_restoration.dart';
import 'package:property_shot/main.dart';

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

  testWidgets('세 시설은 폐허·수리 중·완료 상태를 모양으로 구분한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 150));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: Scaffold(
          backgroundColor: const Color(0xFFFFF9E8),
          body: RepaintBoundary(
            key: const Key('landmark_visual_states'),
            child: ColoredBox(
              color: const Color(0xFFFFF9E8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final progress in const [0.0, 0.5, 1.0])
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final landmark in IslandLandmark.values)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: buildIslandLandmarkIllustrationForTesting(
                              landmark: landmark,
                              progress: progress,
                              size: 38,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(
      find.byKey(const Key('landmark_visual_states')),
    );
    await tester.runAsync(() async {
      for (final asset in const [
        'assets/generated/island-observatory-v1.png',
        'assets/generated/island-lighthouse-v1.png',
        'assets/generated/island-bridge-v1.png',
      ]) {
        await precacheImage(AssetImage(asset), context);
      }
    });
    await tester.pump();

    expect(find.bySemanticsLabel('관측소 폐허'), findsOneWidget);
    expect(find.bySemanticsLabel('등대 수리 중'), findsOneWidget);
    expect(find.bySemanticsLabel('다리 복구 완료'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('landmark_visual_states')),
      matchesGoldenFile('goldens/island_landmark_visual_states.png'),
    );
  });

  for (final landmark in IslandLandmark.values) {
    testWidgets('${landmark.label} 복구 완료는 새 지원을 함께 알린다', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var continued = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
          home: Scaffold(
            backgroundColor: const Color(0xFFBFE8E3),
            body: Center(
              child: buildIslandRestorationCelebrationForTesting(
                landmark: landmark,
                onContinue: () => continued = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('island_restoration_celebration_${landmark.name}')),
        findsOneWidget,
      );
      expect(find.text('${landmark.label} 복구 완료'), findsOneWidget);
      expect(find.text('새 지원 해금 · ${landmark.benefitLabel}'), findsOneWidget);
      expect(find.text(landmark.benefitDescription), findsOneWidget);
      expect(
        tester
            .getSemantics(
              find.byKey(
                Key('island_restoration_celebration_${landmark.name}'),
              ),
            )
            .getSemanticsData()
            .label,
        contains(landmark.benefitLabel),
      );
      await expectLater(
        find.byKey(Key('island_restoration_celebration_${landmark.name}')),
        matchesGoldenFile(
          'goldens/island_restoration_celebration_${landmark.name}_390x844.png',
        ),
      );
      await tester.tap(
        find.byKey(const Key('island_restoration_celebration_continue')),
      );
      await tester.pump();
      expect(continued, isTrue);
    });
  }
}
