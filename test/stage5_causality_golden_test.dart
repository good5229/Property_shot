import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
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

  for (final variant in const ['selected', 'drained', 'result']) {
    for (final fixture in const [
      (name: '390x844', width: 390.0, height: 844.0),
      (name: '768x1024', width: 768.0, height: 1024.0),
    ]) {
      testWidgets('5단계 $variant Golden ${fixture.name}', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await tester.binding.setSurfaceSize(
          Size(fixture.width, fixture.height),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('stage5_causality_golden'),
            child: PropertyShotApp(
              initialState: _stage5State(variant),
              showStageSelector: false,
              fontFamilyOverride: 'GoldenNanumGothic',
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

        if (variant == 'selected') {
          await tester.tapAt(_logicalOffset(tester, 178, 286));
          await tester.pump();
          expect(find.byKey(const Key('entity_info_panel')), findsOneWidget);
          expect(find.textContaining('옮기면 공은 무거움 능력을 얻고'), findsOneWidget);
        }
        if (variant == 'drained') {
          expect(find.textContaining('원본은 이제 움직일 수 있습니다'), findsOneWidget);
        }
        if (variant == 'result') {
          expect(find.byKey(const Key('clear_popup')), findsOneWidget);
          expect(find.text('처음부터 다시'), findsOneWidget);
        }

        await expectLater(
          find.byKey(const Key('stage5_causality_golden')),
          matchesGoldenFile('goldens/stage5_${variant}_${fixture.name}.png'),
        );
      });
    }
  }
}

GameState _stage5State(String variant) {
  final base = levels[4].createState(4, productRules: true);
  if (variant == 'selected') {
    return base;
  }
  const traits = TraitResolver();
  final drained = traits.transferSelectedTrait(
    traits.selectSource(base, 'drain_weight'),
  );
  if (variant == 'result') {
    return drained.copyWith(
      phase: GamePhase.success,
      shotCount: 2,
      message: '공과 비워진 원본을 함께 이용해 홀에 도달했습니다.',
    );
  }
  return drained.copyWith(message: '무거움 능력은 공으로 옮겨졌고, 원본은 이제 움직일 수 있습니다.');
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
