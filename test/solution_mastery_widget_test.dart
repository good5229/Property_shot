import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/solution_mastery.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameFeedback.resetForTesting();
  });
  tearDown(GameFeedback.resetForTesting);

  testWidgets('클리어 결과에 해법 도장·다른 해법·공유 행동이 명확히 노출된다', (tester) async {
    var shared = false;
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClearResultPopup(
            state: levels.first
                .createState(0, productRules: true)
                .copyWith(phase: GamePhase.success, shotCount: 2),
            level: levels.first,
            onNext: () {},
            onRetry: () {},
            isFinal: false,
            bonusAchieved: false,
            solutionEntries: const [_entry],
            solutionTargetCount: 2,
            newSolutionStamp: true,
            onShareSolution: () => shared = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('solution_mastery_card')), findsOneWidget);
    expect(find.text('새 해법 도장 획득!'), findsOneWidget);
    expect(find.text('✓ 벽 반사 해법'), findsOneWidget);
    expect(find.textContaining('다른 충돌 순서'), findsOneWidget);
    final share = find.byKey(const Key('share_solution_card_button'));
    await tester.ensureVisible(share);
    await tester.tap(share);
    await tester.pump();
    expect(shared, isTrue);

    final retry = find.byKey(const Key('retry_stage_button'));
    await tester.ensureVisible(retry);
    expect(find.text('다른 해법 찾기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('저장된 해법으로 재진입하면 직전 성공 조준을 비교선으로 보여 준다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          showStageSelector: false,
          loadGameAssets: false,
          initialSolutionEntries: [_entry],
        ),
      ),
    );
    await tester.pump();
    final gameState = tester.state<GameWidgetState<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    );
    await gameState.currentGame.toBeLoaded();
    await tester.pump();

    expect(gameState.currentGame.previousAimInput, isNotNull);
    expect(
      tester
          .getSemantics(find.byKey(const Key('previous_aim_semantics')))
          .getSemanticsData()
          .label,
      contains('직전 성공 조준'),
    );
  });

  testWidgets('직전 조준 비교를 끄면 저장된 성공 조준도 표시하지 않는다', (tester) async {
    GameFeedback.previousAimComparisonEnabled = false;
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          showStageSelector: false,
          loadGameAssets: false,
          initialSolutionEntries: [_entry],
        ),
      ),
    );
    await tester.pump();
    final gameState = tester.state<GameWidgetState<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    );
    await gameState.currentGame.toBeLoaded();
    await tester.pump();

    expect(gameState.currentGame.previousAimInput, isNull);
    expect(find.byKey(const Key('previous_aim_semantics')), findsNothing);
  });

  testWidgets('저장한 해법 도장 수는 앱 재실행 후 섬 지도에서 확인할 수 있다', (tester) async {
    final store = SolutionMasteryStore(await SharedPreferences.getInstance());
    await store.record(
      stageId: 'stage_heavy',
      patternId: 'stage_heavy_01',
      route: const SolutionRoute(
        signature: '1234abcd',
        label: '벽 반사 해법',
        firstInput: ShotInput(direction: Vec2(1, 0), power: 0.5),
      ),
    );
    await tester.pumpWidget(
      const PropertyShotApp(showHome: true, loadGameAssets: false),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('stage_solution_stamps_0')), findsOneWidget);
    expect(find.text('해법 도장 1개'), findsOneWidget);
  });
}

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

const _entry = SolutionMasteryEntry(
  stageId: 'stage_heavy',
  patternId: 'stage_heavy_01',
  signature: '1234abcd',
  label: '벽 반사 해법',
  firstDirectionX: 0.2,
  firstDirectionY: -0.98,
  firstPower: 0.65,
);
