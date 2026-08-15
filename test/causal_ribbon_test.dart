import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/stage_discovery.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_screen.dart';
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

  testWidgets('리본은 완료·다음·대기 인과를 한 줄로 구분한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 120));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const milestones = [
      StageDiscoveryMilestone(
        id: 'heavy_equipped',
        label: '무거움 장착',
        achieved: true,
      ),
      StageDiscoveryMilestone(
        id: 'crate_moved',
        label: '상자 움직임',
        achieved: false,
      ),
      StageDiscoveryMilestone(
        id: 'hole_reached',
        label: '홀 도착',
        achieved: false,
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('causal_ribbon_golden'),
              child: buildCausalRibbonForTesting(milestones: milestones),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('causal_step_0')), findsOneWidget);
    expect(find.byKey(const Key('causal_step_1')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('무거움 장착 완료.*상자 움직임 대기')),
      findsOneWidget,
    );
    await expectLater(
      find.byKey(const Key('causal_ribbon_golden')),
      matchesGoldenFile('goldens/causal_ribbon_progress.png'),
    );
  });

  testWidgets('첫 기믹을 발견한 뒤에만 보드 위 리본이 나타난다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const PropertyShotApp(
        initialState: GameState(
          levelIndex: 0,
          levelName: '인과 리본 테스트',
          ballSpawn: Vec2(56, 456),
          entities: [
            EntityState(
              id: 'active_ball',
              type: EntityType.ball,
              position: Vec2(56, 456),
              size: Vec2(24, 24),
              movable: true,
              traits: {TraitType.heavy},
            ),
            EntityState(
              id: 'hole',
              type: EntityType.hole,
              position: Vec2(300, 100),
              size: Vec2(34, 34),
              solid: false,
            ),
          ],
        ),
        showStageSelector: false,
        loadGameAssets: false,
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('causal_ribbon')), findsOneWidget);
    expect(find.text('무거움 장착'), findsWidgets);
  });
}
