import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
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

  const fixtures = [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '393x852', width: 393.0, height: 852.0),
    (name: '430x932', width: 430.0, height: 932.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1024x1366', width: 1024.0, height: 1366.0),
  ];

  for (final variant in const [
    'start',
    'popped',
    'switch_opening',
    'hole',
    'result',
  ]) {
    for (final fixture in fixtures) {
      testWidgets('4단계 $variant Golden ${fixture.name}', (tester) async {
        SharedPreferences.setMockInitialValues(<String, Object>{});
        await tester.binding.setSurfaceSize(
          Size(fixture.width, fixture.height),
        );
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          RepaintBoundary(
            key: const Key('stage4_causality_golden'),
            child: PropertyShotApp(
              initialState: _stage4State(variant),
              showStageSelector: false,
              fontFamilyOverride: 'GoldenNanumGothic',
              loadGameAssets: true,
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

        expect(find.byKey(const Key('aim_area')), findsOneWidget);
        await expectLater(
          find.byKey(const Key('stage4_causality_golden')),
          matchesGoldenFile('goldens/stage4_${variant}_${fixture.name}.png'),
        );
      });
    }
  }
}

GameState _stage4State(String variant) {
  final base = levels[3]
      .createState(3)
      .copyWith(
        message: switch (variant) {
          'start' => '풍선 확인 · 여러 경로로 도전',
          'popped' => '풍선이 터졌어요. 드러난 스위치를 맞혀 문을 열어 보세요.',
          'switch_opening' => '풍선 뒤 스위치가 눌려 문이 열렸습니다.',
          'hole' => '공이 홀에 들어갔어요!',
          _ => '성공했어요!',
        },
      );
  final entities = [
    for (final entity in base.entities)
      switch (variant) {
        'popped' when entity.id == 'active_ball' => entity.copyWith(
          position: const Vec2(199, 238),
          visualState: 'moving',
        ),
        'popped' when entity.id == 'balloon' => entity.copyWith(
          active: false,
          solid: false,
          visualState: 'popped',
        ),
        'popped' when entity.id == 'balloon_switch' => entity.copyWith(
          solid: true,
          visualState: 'revealed',
        ),
        'switch_opening' when entity.id == 'active_ball' => entity.copyWith(
            position: const Vec2(214, 214),
          visualState: 'moving',
        ),
        'switch_opening' when entity.id == 'balloon' => entity.copyWith(
          active: false,
          solid: false,
          visualState: 'popped',
        ),
        'switch_opening' when entity.id == 'balloon_switch' => entity.copyWith(
          pressed: true,
          solid: false,
          visualState: 'pressed',
        ),
        'switch_opening' when entity.id == 'balloon_gate' => entity.copyWith(
          open: false,
          solid: true,
          visualState: 'opening',
        ),
        'hole' when entity.id == 'active_ball' => entity.copyWith(
            position: const Vec2(300, 128),
          visualState: 'hole_captured',
        ),
        'result' when entity.id == 'active_ball' => entity.copyWith(
            position: const Vec2(300, 128),
          visualState: 'hole_captured',
        ),
        _ => entity,
      },
  ];
  return base.copyWith(
    entities: entities,
    phase: variant == 'result' ? GamePhase.success : GamePhase.planning,
  );
}
