import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/game_screen.dart';

void main() {
  for (final fixture in const [
    (name: '390x844', size: Size(390, 844)),
    (name: '768x1024', size: Size(768, 1024)),
  ]) {
    testWidgets('해변 플레이 배경 Golden ${fixture.name}', (tester) async {
      await tester.binding.setSurfaceSize(fixture.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('gameplay_backdrop_golden'),
          child: SizedBox(
            width: fixture.size.width,
            height: fixture.size.height,
            child: CustomPaint(painter: GameplayBackdropPainter()),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(const Key('gameplay_backdrop_golden')),
        matchesGoldenFile('goldens/gameplay_backdrop_${fixture.name}.png'),
      );
    });
  }
}
