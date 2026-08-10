import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/hint/demo_playback_plan.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/main.dart';

void main() {
  test('시연 플랜은 셔플 seed가 아닌 고정 bouncy 대표 fixture를 가리킨다', () {
    const plan = stageBouncy01DemoPlaybackPlan;
    expect(plan.stageId, 'stage_bouncy');
    expect(plan.patternId, 'stage_bouncy_01');
    expect(plan.fixtureId, 'stage_bouncy_01_bouncy_multi_wall_reflection');
    expect(plan.expectedEvents, [
      'bounced',
      'bounced',
      'bounced',
      'hole_entered',
    ]);
  });

  test('고정 시연 fixture는 탄성 이전과 벽 반사 사건을 실제 순서로 재생한다', () {
    final stage = generatedStageCatalog.stageById('stage_bouncy');
    final pattern = stage.patternById(stageBouncy01DemoPlaybackPlan.patternId);
    final initial = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(0);
    const traits = TraitResolver();
    final prepared = traits.transferSelectedTrait(
      traits.selectSource(initial, 'jelly'),
    );
    expect(prepared.activeBall.traits, contains(TraitType.bouncy));
    final result = const ShotResolver().resolve(
      prepared,
      ShotInput(
        direction: Vec2(
          math.cos(48 * math.pi / 180),
          math.sin(48 * math.pi / 180),
        ),
        power: 0.90,
        equippedTrait: prepared.equippedTrait,
      ),
    );
    expect(
      result.events,
      containsAll(stageBouncy01DemoPlaybackPlan.expectedEvents),
    );
    expect(
      result.impacts.where((impact) => impact.entityType == EntityType.wall),
      isNotEmpty,
    );
    expect(result.state.phase.name, 'success');
  });

  testWidgets('고정 demo query 진입점은 캠페인 홈 대신 bouncy_01과 열쇠를 연다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        demoPlanId: 'demo_bouncy_01_v1',
        loadGameAssets: false,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('demo_bouncy_01_screen')), findsOneWidget);
    expect(find.byKey(const Key('aim_area')), findsOneWidget);
    expect(find.byKey(const Key('verified_demo_launch')), findsOneWidget);
    expect(find.text('🔑 팁 잠김'), findsOneWidget);
    expect(find.bySemanticsLabel('힌트 열쇠'), findsOneWidget);
    expect(find.byKey(const Key('start_game_button')), findsNothing);
  });
}
