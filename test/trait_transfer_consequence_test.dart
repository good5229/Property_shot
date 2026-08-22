import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/trait_transfer_ribbon.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  for (final fixture in const [
    (trait: TraitType.heavy, type: EntityType.weight),
    (trait: TraitType.bouncy, type: EntityType.bumper),
    (trait: TraitType.sticky, type: EntityType.stickySurface),
    (trait: TraitType.sharp, type: EntityType.spikeSource),
  ]) {
    test('${fixture.trait.label} 이전은 원본의 잃은 속성과 공의 획득을 함께 보존한다', () {
      final source = EntityState(
        id: 'source',
        type: fixture.type,
        position: const Vec2(100, 100),
        size: const Vec2(48, 48),
        traits: {fixture.trait},
        movableWhenDrained: true,
      );
      final state = GameState(
        levelIndex: 0,
        levelName: '양면 변화 테스트',
        ballSpawn: const Vec2(40, 200),
        entities: [
          const EntityState(
            id: 'active_ball',
            type: EntityType.ball,
            position: Vec2(40, 200),
            size: Vec2(24, 24),
            movable: true,
          ),
          source,
        ],
      );

      final resolver = const TraitResolver();
      final moved = resolver.transferSelectedTrait(
        resolver.selectSource(state, source.id),
      );
      final drained = moved.entityById(source.id)!;

      expect(drained.traits, isEmpty);
      expect(drained.drainedTraits, {fixture.trait});
      expect(drained.visualState, 'drained');
      expect(drained.movable, isTrue);
      expect(moved.activeBall.traits, {fixture.trait});
      expect(moved.equippedTrait, fixture.trait);
      expect(traitLossConsequence(source, fixture.trait), isNotEmpty);
    });
  }

  testWidgets('실제 속성 이전 직후 원본과 공의 변화를 한 리본으로 알린다', (tester) async {
    await tester.pumpWidget(
      PropertyShotApp(initialState: levels[4].createState(4)),
    );
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 178, 286));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer_button')));
    await tester.pump();

    expect(find.byKey(const Key('trait_transfer_ribbon')), findsOneWidget);
    expect(find.text('무거움 보유 → 비움'), findsOneWidget);
    expect(find.text('기본 → 무거움'), findsOneWidget);
    expect(find.textContaining('가벼워져 충돌하면 움직입니다'), findsOneWidget);
    expect(
      tester
          .getSemantics(
            find.byKey(const Key('trait_transfer_ribbon_semantics')),
          )
          .getSemanticsData()
          .label,
      allOf(contains('원본'), contains('무거움을 잃어'), contains('공은 무거움을 얻었습니다')),
    );

    await tester.pump(const Duration(seconds: 3));
    expect(find.byKey(const Key('trait_transfer_ribbon')), findsNothing);
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    testWidgets('양면 속성 변화 Golden ${fixture.name}', (tester) async {
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('trait_transfer_golden'),
          child: PropertyShotApp(
            initialState: levels[4].createState(4),
            showStageSelector: false,
            fontFamilyOverride: 'GoldenNanumGothic',
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pump(const Duration(seconds: 1));

      await tester.tapAt(_logicalOffset(tester, 178, 286));
      await tester.pump();
      await tester.tap(find.byKey(const Key('transfer_button')));
      await tester.pump();

      expect(find.byKey(const Key('trait_transfer_ribbon')), findsOneWidget);
      await expectLater(
        find.byKey(const Key('trait_transfer_golden')),
        matchesGoldenFile('goldens/trait_transfer_${fixture.name}.png'),
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
