import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/main.dart';

void main() {
  for (final size in const [
    Size(1024, 768),
    Size(1024, 1366),
    Size(1440, 900),
    Size(1920, 1080),
  ]) {
    testWidgets('넓은 화면 ${size.width.toInt()}x${size.height.toInt()}에서 조작 콘솔이 보드 주변에 묶인다', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const PropertyShotApp(
          showHome: false,
          showStageSelector: false,
          loadGameAssets: false,
        ),
      );
      await tester.pump();

      final shell = tester.getRect(
        find.byKey(const Key('gameplay_content_shell')),
      );
      final board = tester.getRect(find.byKey(const Key('aim_area')));
      expect(shell.width, lessThanOrEqualTo(840.1));
      expect((shell.center.dx - board.center.dx).abs(), lessThan(0.1));
      expect(board.left - shell.left, lessThanOrEqualTo(145));
      expect(shell.right - board.right, lessThanOrEqualTo(145));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('랜드스케이프 화면의 튜토리얼 안내가 홀을 가리지 않는다', (tester) async {
    const size = Size(1024, 768);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = levels[2].createState(2, productRules: true);
    await tester.pumpWidget(
      PropertyShotApp(
        initialState: state,
        showStageSelector: false,
        loadGameAssets: false,
      ),
    );
    await tester.pump();

    final board = tester.getRect(find.byKey(const Key('aim_area')));
    final coach = tester.getRect(
      find.byKey(const Key('tutorial_coach_mark')),
    );
    final hole = state.entities.singleWhere((entity) => entity.id == 'hole');
    final scale = board.width / 360;
    final holeCenter =
        board.topLeft + Offset(hole.position.x * scale, hole.position.y * scale);
    final holeRect = Rect.fromCenter(
      center: holeCenter,
      width: hole.size.x * scale,
      height: hole.size.y * scale,
    );
    expect(coach.overlaps(holeRect), isFalse);
    expect(tester.takeException(), isNull);
  });
}
