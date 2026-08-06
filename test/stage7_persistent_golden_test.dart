import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/trait.dart';
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

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '393x852', width: 393.0, height: 852.0),
    (name: '430x932', width: 430.0, height: 932.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1024x1366', width: 1024.0, height: 1366.0),
  ]) {
    testWidgets('7단계 과거 공 정보 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final base = levels[6].createState(6, productRules: true);
      final spent = base.activeBall.copyWith(
        id: 'spent_ball_1',
        position: const Vec2(180, 380),
        traits: const {TraitType.sticky},
        movable: false,
        visualState: 'stuck',
      );
      final state = base.copyWith(
        entities: [...base.entities, spent],
        shotCount: 1,
        message: '과거 공 1개 · 다음 충돌 준비',
      );

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('stage7_persistent_golden'),
          child: PropertyShotApp(
            initialState: state,
            showStageSelector: false,
            fontFamilyOverride: 'GoldenNanumGothic',
            loadGameAssets: false,
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      final gameWidgetState = tester.state<GameWidgetState<PropertyShotGame>>(
        find.byType(GameWidget<PropertyShotGame>),
      );
      await gameWidgetState.currentGame.toBeLoaded();
      await tester.pump(const Duration(seconds: 1));

      await tester.tapAt(_logicalOffset(tester, 180, 380));
      await tester.pump();

      expect(find.text('첫 번째 공'), findsOneWidget);
      expect(find.textContaining('점착으로 고정됨'), findsOneWidget);
      expect(find.byKey(const Key('transfer_button')), findsNothing);
      await expectLater(
        find.byKey(const Key('stage7_persistent_golden')),
        matchesGoldenFile('goldens/stage7_persistent_${fixture.name}.png'),
      );
    });
  }
}

Offset _logicalOffset(WidgetTester tester, double x, double y) {
  final rect = tester.getRect(find.byKey(const Key('aim_area')));
  final scale = rect.width / 360 < rect.height / 560
      ? rect.width / 360
      : rect.height / 560;
  final origin = Offset(
    rect.left + (rect.width - 360 * scale) / 2,
    rect.top + (rect.height - 560 * scale) / 2,
  );
  return origin + Offset(x * scale, y * scale);
}
