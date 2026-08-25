import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:property_shot/game/analysis/failure_replay.dart';
import 'package:property_shot/game/analysis/stage_discovery.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/failure_replay_dialog.dart';
import 'package:property_shot/ui/game_feedback.dart';
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

  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

  testWidgets('저모션 실패 재생은 사용자가 누르기 전 정지 상태다', (tester) async {
    GameFeedback.reducedMotionEnabled = true;
    final before = levels.first.createState(0, productRules: true);
    const input = ShotInput(direction: Vec2(-1, 0), power: 0.2);
    final result = const ShotResolver().resolve(before, input);

    await tester.pumpWidget(
      MaterialApp(
        home: FailureReplayDialog(
          data: FailureReplayData(
            beforeState: before,
            input: input,
            result: result,
          ),
        ),
      ),
    );
    await tester.pump();

    final game = tester
        .widget<GameWidget<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        )
        .game!;
    expect(game.playbackSpeed, 0);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    testWidgets('실제 실패 인과 Golden ${fixture.name}', (tester) async {
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      GameFeedback.reducedMotionEnabled = true;
      final before = levels.first.createState(0, productRules: true);
      const input = ShotInput(direction: Vec2(-1, 0), power: 0.2);
      final result = const ShotResolver().resolve(before, input);
      expect(result.state.phase, GamePhase.planning);
      expect(result.impacts, isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
          home: MediaQuery(
            data: MediaQueryData(size: Size(fixture.width, fixture.height)),
            child: Scaffold(
              body: FailureReplayDialog(
                data: FailureReplayData(
                  beforeState: before,
                  input: input,
                  result: result,
                ),
                autoplay: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('충돌 순서'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('failure_replay_panel'))).height,
        fixture.height >= 700 ? 680 : fixture.height - 48,
      );
      await expectLater(
        find.byKey(const Key('failure_replay_dialog')),
        matchesGoldenFile('goldens/failure_replay_${fixture.name}.png'),
      );
    });

    testWidgets('실제 10단계 런 결과 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final preferences = await SharedPreferences.getInstance();
      final session = StagePatternSession(
        catalog: generatedStageCatalog,
        store: RunStateStore(
          backend: SharedPreferencesRunStateBackend(preferences),
        ),
        now: () => DateTime.utc(2026, 8, 8, 12),
      );
      await session.selectStage('stage_property_shot');
      await session.completeCurrentStage(
        stageId: 'stage_property_shot',
        shotCount: 3,
        chainScore: 1970,
      );
      final candidates = await session.prepareRewardSelection(
        stageId: 'stage_property_shot',
      );
      await session.selectReward(candidates.first.id);
      await session.completeRun();
      final progressStore = ProgressStore(
        stageCount: levels.length,
        stageIds: levels.map((level) => level.id),
      );
      for (var index = 0; index < levels.length; index++) {
        await progressStore.recordDiscoveries(
          index,
          stageDiscoveryMilestoneIds(index),
        );
      }

      await tester.pumpWidget(
        const PropertyShotApp(
          showHome: true,
          fontFamilyOverride: 'GoldenNanumGothic',
        ),
      );
      await _pumpForAsyncWork(tester);
      await tester.tap(find.byKey(const Key('start_game_button')));
      await _pumpForAsyncWork(tester);
      await _precacheFinaleAssets(tester);

      expect(find.text('1970점'), findsOneWidget);
      expect(find.text('3회'), findsOneWidget);
      expect(find.text('1개'), findsOneWidget);
      await expectLater(
        find.byKey(const Key('run_result_screen')),
        matchesGoldenFile('goldens/run_result_${fixture.name}.png'),
      );
    });
  }
}

Future<void> _precacheFinaleAssets(WidgetTester tester) async {
  final context = tester.element(find.byKey(const Key('run_result_screen')));
  await tester.runAsync(() async {
    for (final asset in const [
      'assets/generated/stage-icon-finale-v1.png',
      'assets/generated/island-observatory-v2.png',
      'assets/generated/island-lighthouse-v2.png',
      'assets/generated/island-bridge-v2.png',
      'assets/generated/nav-helm-v1.png',
      'assets/generated/nav-stage-map-v1.png',
    ]) {
      await precacheImage(AssetImage(asset), context);
    }
  });
  await tester.pump();
}

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
