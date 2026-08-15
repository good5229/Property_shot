import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/island_restoration.dart';
import 'package:property_shot/main.dart';

void main() {
  testWidgets('세 시설은 폐허·수리 중·완료 상태를 모양으로 구분한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 150));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFFFF9E8),
          body: RepaintBoundary(
            key: const Key('landmark_visual_states'),
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
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('관측소 폐허'), findsOneWidget);
    expect(find.bySemanticsLabel('등대 수리 중'), findsOneWidget);
    expect(find.bySemanticsLabel('다리 복구 완료'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('landmark_visual_states')),
      matchesGoldenFile('goldens/island_landmark_visual_states.png'),
    );
  });
}
