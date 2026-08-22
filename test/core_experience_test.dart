import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/core_experience_screen.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('핵심 체험은 검증된 서로 다른 세 장면을 고정 순서로 사용한다', () {
    expect(coreExperienceScenes, hasLength(3));
    expect(coreExperienceScenes.map((scene) => scene.patternId), <String>[
      'stage_heavy_01',
      'stage_drained_01',
      'stage_persistent_01',
    ]);
    expect(
      coreExperienceScenes.map((scene) => scene.patternId).toSet(),
      hasLength(3),
    );

    for (final scene in coreExperienceScenes) {
      final level = scene.createLevel();
      final state = level.createState(scene.levelIndex, productRules: true);
      final hole = state.entities.singleWhere(
        (entity) => entity.type == EntityType.hole,
      );

      expect(level.stageId, scene.stageId);
      expect(level.patternId, scene.patternId);
      expect(state.phase, GamePhase.planning);
      expect(
        state.activeBall.position.distanceTo(hole.position),
        greaterThan((state.activeBall.size.x + hole.size.x) / 2),
        reason: '${scene.patternId}은 입력 전 자동 클리어 상태여서는 안 된다.',
      );
    }
  });

  testWidgets('홈의 최상위 핵심 체험 버튼이 저장과 분리된 실제 게임 화면을 연다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();

    expect(find.byKey(const Key('core_experience_button')), findsOneWidget);
    expect(find.text('60초 핵심 체험'), findsOneWidget);

    await tester.tap(find.byKey(const Key('core_experience_button')));
    await tester.pump();

    expect(find.byType(CoreExperienceScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(
      game.progressPersistencePolicy,
      GameProgressPersistencePolicy.disabled,
    );
    expect(game.sequencePosition, 0);
    expect(game.sequenceLength, 3);
    expect(game.objectiveOverride, contains('핵심 체험 1/3'));
    expect(game.showDiscoveryHud, isFalse);
  });

  testWidgets('각 핵심 장면은 현재 순서와 다음 행동을 명확히 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CoreExperienceScreen(
          initialSceneIndex: 2,
          loadGameAssets: false,
          onExit: () {},
          onContinueCampaign: () {},
        ),
      ),
    );
    await tester.pump();

    final game = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(game.sequencePosition, 2);
    expect(game.sequenceLength, 3);
    expect(game.nextActionLabel, '체험 마치기');
    expect(game.objectiveOverride, contains('핵심 체험 3/3'));
    expect(game.objectiveOverride, contains('남겨 둔 첫 공'));
  });
}
