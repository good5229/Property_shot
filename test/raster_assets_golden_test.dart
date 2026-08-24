import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/game_ball_painter.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'));
    await loader.load();
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    testWidgets('플레이 래스터 자산 Golden ${fixture.name}', (tester) async {
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('raster_assets_golden'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: ColoredBox(
              color: const Color(0xFFBFE8E3),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.82,
                  heightFactor: 0.72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6D995),
                      border: Border.all(
                        color: const Color(0xFF2D777A),
                        width: 10,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        const Positioned(
                          left: 20,
                          top: 42,
                          width: 72,
                          height: 58,
                          child: Image(
                            image: AssetImage('assets/generated/stone-v3.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Positioned(
                          right: 22,
                          top: 38,
                          width: 72,
                          height: 72,
                          child: CustomPaint(
                            painter: GameBallIconPainter(null),
                          ),
                        ),
                        const Positioned(
                          left: 92,
                          bottom: 48,
                          width: 70,
                          height: 70,
                          child: Image(
                            image: AssetImage('assets/generated/crate-v3.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 66,
                            height: 66,
                            child: Image(
                              image: AssetImage(
                                'assets/generated/mystery-crate-v1.png',
                              ),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 24,
                          bottom: 44,
                          width: 74,
                          height: 62,
                          child: Image(
                            image: AssetImage(
                              'assets/generated/jelly-bumper-v2.png',
                            ),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final context = tester.element(
        find.byKey(const Key('raster_assets_golden')),
      );
      await tester.runAsync(() async {
        for (final asset in const [
          'assets/generated/stone-v3.png',
          'assets/generated/crate-v3.png',
          'assets/generated/mystery-crate-v1.png',
          'assets/generated/jelly-bumper-v2.png',
        ]) {
          await precacheImage(AssetImage(asset), context);
        }
      });
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const Key('raster_assets_golden')),
        matchesGoldenFile('goldens/raster_assets_${fixture.name}.png'),
      );
    });
  }
}
