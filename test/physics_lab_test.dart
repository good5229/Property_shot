import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/lab/physics_lab.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/physics_lab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _testReferenceDate = DateTime.utc(2026, 8, 10);

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  test('다섯 실험은 고정 ID이며 공과 홀이 처음부터 겹치지 않는다', () {
    expect(physicsLabScenarios, hasLength(5));
    expect(physicsLabScenarios.map((item) => item.id).toSet(), hasLength(5));
    for (final scenario in physicsLabScenarios) {
      final state = scenario.level.createState(scenario.linkedStageIndex);
      final hole = state.entities.firstWhere(
        (item) => item.type == EntityType.hole,
      );
      expect(
        state.activeBall.position.distanceTo(hole.position),
        greaterThan(state.activeBall.hitRadius + hole.hitRadius),
      );
      expect(
        scenario.level.entities.map((item) => item.id).toSet().length,
        scenario.level.entities.length,
      );
    }
  });

  test('각 실험은 일반 조준 범위에서 목표 물리 사건을 만들 수 있다', () {
    const resolver = ShotResolver();
    for (final scenario in physicsLabScenarios) {
      final trait = switch (scenario.id) {
        'lab_heavy_crate_v1' || 'lab_switch_gate_v1' => TraitType.heavy,
        'lab_bouncy_second_rebound_v1' => TraitType.bouncy,
        'lab_sticky_chain_v1' => TraitType.sticky,
        'lab_sharp_balloon_v1' => TraitType.sharp,
        _ => null,
      };
      final initial = scenario.level.createState(scenario.linkedStageIndex);
      final source = initial.entities.firstWhere(
        (entity) => trait != null && entity.traits.contains(trait),
      );
      final state = const TraitResolver().transferSelectedTrait(
        const TraitResolver().selectSource(initial, source.id),
      );
      expect(state.equippedTrait, trait, reason: '${scenario.id} 속성 획득');
      var reachable = false;
      for (var degrees = 0; degrees < 360 && !reachable; degrees += 10) {
        final radians = degrees * math.pi / 180;
        for (var power = .2; power <= 1.001; power += .1) {
          final result = resolver.resolve(
            state,
            ShotInput(
              direction: Vec2(math.cos(radians), math.sin(radians)),
              power: power,
              equippedTrait: trait,
            ),
          );
          reachable = switch (scenario.id) {
            'lab_heavy_crate_v1' => result.moves.any(
              (move) => move.entityId == 'lab_crate' && move.from != move.to,
            ),
            'lab_bouncy_second_rebound_v1' =>
              result.impacts
                      .where(
                        (impact) =>
                            impact.entityType == EntityType.wall ||
                            impact.entityType == EntityType.gate,
                      )
                      .length >=
                  2,
            'lab_sticky_chain_v1' => result.events.contains('sticky_attached'),
            'lab_sharp_balloon_v1' => result.events.contains('balloon_popped'),
            'lab_switch_gate_v1' => result.events.contains('switch_pressed'),
            _ => false,
          };
          if (reachable) break;
        }
      }
      expect(reachable, isTrue, reason: scenario.id);
    }
  });

  testWidgets('실험실은 기록 비반영 안내와 다섯 실험을 노출한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: PhysicsLabScreen(
          onBack: () {},
          loadGameAssets: false,
          referenceDate: _testReferenceDate,
        ),
      ),
    );
    expect(find.byKey(const Key('physics_lab_screen')), findsOneWidget);
    expect(find.textContaining('캠페인 진행'), findsOneWidget);
    for (final scenario in physicsLabScenarios) {
      await tester.scrollUntilVisible(
        find.byKey(Key('physics_lab_${scenario.id}')),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byKey(Key('physics_lab_${scenario.id}')), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('물리 실험실 목록 Golden 390x844', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: PhysicsLabScreen(
          onBack: () {},
          loadGameAssets: false,
          referenceDate: _testReferenceDate,
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byKey(const Key('physics_lab_screen')),
      matchesGoldenFile('goldens/physics_lab_390x844.png'),
    );
  });

  testWidgets('물리 실험 화면 Golden 390x844', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
        home: PhysicsLabScreen(
          onBack: () {},
          loadGameAssets: false,
          referenceDate: _testReferenceDate,
        ),
      ),
    );
    await tester.tap(
      find.byKey(const Key('physics_lab_lab_bouncy_second_rebound_v1')),
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
    expect(find.textContaining('발견 0/3'), findsNothing);
    expect(find.byTooltip('실험 목록'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('공')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp('홀')), findsWidgets);
    await expectLater(
      find.byType(PhysicsLabScreen),
      matchesGoldenFile('goldens/physics_lab_active_390x844.png'),
    );
  });

  testWidgets('섬 지도에서 실험실로 들어갔다가 돌아온다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('physics_lab_button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('physics_lab_screen')), findsOneWidget);
    await tester.tap(find.byTooltip('섬 지도로'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage_select_screen')), findsOneWidget);
  });

  testWidgets('실험·초기화·나가기는 캠페인 저장 키를 바꾸지 않는다', (tester) async {
    final sentinels = <String, Object>{
      'property_shot_cleared_stage_ids': <String>['stage_heavy'],
      'property_shot_unlocked_level': 3,
      'best_shots_stage_stage_heavy': 2,
      'bonus_goal_level_0': true,
      'property_shot_copy_core_count': 4,
      'property_shot_discovery_records': <String>[
        'stage_heavy::heavy_equipped',
      ],
      'property_shot_run_state_slot_a': 'campaign-a',
      'property_shot_expedition_contract_v1': 'expedition-a',
      'property_shot_daily_record_v2_2026-08-15_fixture_slot_a': 'daily-a',
      'property_shot_daily_run_state_v1/2026-08-15/fixture/slot_a':
          'daily-run-a',
      'property_shot_solution_mastery_v1': 'solution-a',
      'property_shot_replay_library_v1_slot_a': 'replay-a',
      'property_shot_run_state_active_pointer': 'a',
    };
    SharedPreferences.setMockInitialValues(sentinels);
    final before = await SharedPreferences.getInstance();
    final beforeKeys = before.getKeys();
    final beforeValues = {for (final key in beforeKeys) key: before.get(key)};
    await tester.pumpWidget(
      MaterialApp(
        home: PhysicsLabScreen(
          onBack: () {},
          referenceDate: _testReferenceDate,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('physics_lab_lab_heavy_crate_v1')));
    await tester.pump();
    tester
        .widget<Focus>(find.byKey(const Key('aim_keyboard_focus')))
        .focusNode!
        .requestFocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(seconds: 5));
    final failureReset = find.byKey(const Key('failure_reset_button'));
    if (failureReset.evaluate().isNotEmpty) {
      await tester.tap(failureReset);
    } else {
      await tester.tap(find.byKey(const Key('reset_button')).first);
    }
    await tester.pump();
    await tester.tap(find.byTooltip('실험 목록'));
    await tester.pump();
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), beforeKeys);
    expect({
      for (final key in preferences.getKeys()) key: preferences.get(key),
    }, beforeValues);
    for (final entry in sentinels.entries) {
      final actual = entry.value is List<String>
          ? preferences.getStringList(entry.key)
          : preferences.get(entry.key);
      expect(actual, entry.value, reason: entry.key);
    }
  });
}
