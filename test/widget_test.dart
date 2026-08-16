import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/run/run_reward.dart';
import 'package:property_shot/game/run/run_state.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/game/run/stage_shuffle_bag.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/play_telemetry.dart';
import 'package:property_shot/ui/run_difficulty_attribution_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/stage_chain_score_patterns.dart';
import 'fixtures/stage_drained_patterns.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('실제 시작 흐름은 홈·섬 지도·플레이를 연결한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      ProgressStore.clearedLevelsKey: <String>['0'],
      ProgressStore.clearedStageIdsKey: <String>['stage_heavy'],
    });
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    await tester.pumpWidget(
      PropertyShotApp(showHome: true, telemetry: telemetry),
    );
    await tester.pump();

    expect(find.text('속성 한방'), findsOneWidget);
    expect(find.text('무거움 · 탄성 · 점착'), findsNothing);
    expect(find.byKey(const Key('start_game_button')), findsOneWidget);
    expect(find.byKey(const Key('stage_select_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pump();
    expect(find.text('섬 지도'), findsOneWidget);
    expect(find.byKey(const Key('next_goal_card')), findsOneWidget);
    expect(find.text('지금 해볼 만한 목표'), findsOneWidget);
    expect(find.textContaining('추천 이유'), findsOneWidget);
    expect(find.byKey(const Key('stage_tile_0')), findsOneWidget);
    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.byKey(const Key('stage_tile_7')), findsOneWidget);
    expect(find.byKey(const Key('stage_tile_8')), findsOneWidget);
    expect(find.byKey(const Key('stage_tile_9')), findsOneWidget);
    expect(find.text('풍선은 밀리고, 뾰족한 공에는 터집니다.'), findsOneWidget);
    expect(find.text('짧게 넣거나 벽과 기물을 이어 더 높은 연쇄 점수에 도전해 보세요.'), findsOneWidget);
    expect(find.text('반사판을 돌려 다음 공이 만날 면과 방향을 바꿔 보세요.'), findsOneWidget);
    expect(find.text('배운 속성과 기물을 엮어 나만의 경로를 완성해 보세요.'), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNWidgets(levels.length - 2));

    await tester.tap(find.byKey(const Key('stage_tile_0')));
    await _pumpUntilFound(tester, find.byKey(const Key('aim_area')));
    expect(find.byKey(const Key('aim_area')), findsOneWidget);
    expect(find.byKey(const Key('home_button')), findsOneWidget);
    expect(find.byKey(const Key('compact_objective')), findsOneWidget);
    expect(find.textContaining('발견 0/3 · 무거움'), findsOneWidget);
    expect(find.byKey(const Key('level_1')), findsNothing);
    expect(
      telemetry.events.map((event) => event['event_code']),
      containsAllInOrder([
        'run_started',
        'stage_pattern_drawn',
        'stage_entered',
      ]),
    );
    final patternDrawn = telemetry.events.lastWhere(
      (event) => event['event_code'] == 'stage_pattern_drawn',
    );
    expect(patternDrawn['pattern_id'], isNotEmpty);
    expect(patternDrawn['seed'], isA<int>());

    await tester.tap(find.byKey(const Key('home_button')));
    await tester.pump();
    expect(find.byKey(const Key('stage_abandon_dialog')), findsOneWidget);
    expect(find.text('이 스테이지를 포기할까요?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage_abandon_confirm_button')));
    await tester.pump();
    expect(find.byKey(const Key('start_game_button')), findsOneWidget);
  });

  testWidgets('홈의 내 런 보상은 선택 이력과 실제 도움 상태를 보여준다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'unlocked_level': 1,
    });
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preferences = await SharedPreferences.getInstance();
    final store = RunStateStore(
      backend: SharedPreferencesRunStateBackend(preferences),
    );
    var selected = false;
    for (var offset = 0; offset < 128 && !selected; offset++) {
      await store.reset();
      final session = StagePatternSession(
        catalog: generatedStageCatalog,
        store: store,
        now: () => DateTime.fromMicrosecondsSinceEpoch(offset, isUtc: true),
      );
      await session.selectStage('stage_heavy');
      await session.completeCurrentStage(
        stageId: 'stage_heavy',
        nextStageId: 'stage_bouncy',
        shotCount: 2,
      );
      final rewards = await session.prepareRewardSelection(
        stageId: 'stage_heavy',
      );
      if (rewards.any((reward) => reward.id == runRewardPrecisionChargeId)) {
        await session.selectReward(runRewardPrecisionChargeId);
        selected = true;
      }
    }
    expect(selected, isTrue);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();
    expect(
      find.byKey(const Key('reward_inventory_entry_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reward_inventory_entry_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('reward_inventory_screen')), findsOneWidget);
    expect(find.textContaining('다음 사용 계획'), findsWidgets);
    expect(find.textContaining('사용하면'), findsWidgets);
    expect(find.text('정밀 충전 조절'), findsOneWidget);
    expect(find.text('런 동안 계속 활성'), findsOneWidget);
    expect(find.textContaining('충전 속도를 25% 늦춰'), findsOneWidget);
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any(
            (image) =>
                image.image is AssetImage &&
                (image.image as AssetImage).assetName ==
                    'assets/generated/power-slider-v1.png',
          ),
      isTrue,
    );
    expect(
      find.byKey(const Key('reward_inventory_usage_precision_charge_control')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('reward_inventory_back_button')));
    await tester.pump();
    expect(find.byKey(const Key('home_screen_golden')), findsOneWidget);
  });

  testWidgets('저장된 런 완료 상태는 새 런을 만들지 않고 결과 화면을 복원한다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
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

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('run_result_screen')), findsOneWidget);
    expect(find.text('첫 번째 섬 완주!'), findsOneWidget);
    expect(find.text('1970점'), findsOneWidget);
    expect(find.text('3회'), findsOneWidget);
    expect(find.text('1개'), findsOneWidget);
  });

  testWidgets('기록 보호로 줄인 클리어 횟수는 보상 선택 대기 상태에서도 복원된다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final store = RunStateStore(
      backend: SharedPreferencesRunStateBackend(preferences),
    );
    late StagePatternSession session;
    var foundReward = false;
    for (var offset = 0; offset < 128; offset++) {
      await store.reset();
      session = StagePatternSession(
        catalog: generatedStageCatalog,
        store: store,
        now: () => DateTime.fromMicrosecondsSinceEpoch(offset, isUtc: true),
      );
      await session.selectStage('stage_heavy');
      await session.completeCurrentStage(
        stageId: 'stage_heavy',
        nextStageId: 'stage_chain_score',
        shotCount: 1,
      );
      final rewards = await session.prepareRewardSelection(
        stageId: 'stage_heavy',
      );
      if (!rewards.any((reward) => reward.id == runRewardStageRecordGuardId)) {
        continue;
      }
      await session.selectReward(runRewardStageRecordGuardId);
      foundReward = true;
      break;
    }
    expect(foundReward, isTrue);
    final draw = await session.selectStage('stage_chain_score');
    final solution = stageChainScoreSolutions.singleWhere(
      (candidate) => candidate.patternId == draw.patternId,
    );
    await session.recordShot(
      input: const ShotInput(direction: Vec2(0, 1), power: 0.12),
    );
    await session.recordShot(input: solution.directInput);
    final completion = await session.completeCurrentStage(
      stageId: 'stage_chain_score',
      shotCount: 2,
      applyStageRecordGuard: true,
    );
    expect(completion.shotCount, 1);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.initialState?.shotCount, 1);
    expect(_currentShotCount(tester), 1);
    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
  });

  testWidgets('회전 반사판 접근성 설명은 충돌당 90도 회전을 안내한다', (tester) async {
    final state = GameState(
      levelIndex: 0,
      levelName: '회전 반사판 접근성 시험',
      ballSpawn: const Vec2(60, 520),
      entities: const [
        EntityState(
          id: 'active_ball',
          type: EntityType.ball,
          position: Vec2(60, 520),
          size: Vec2(24, 24),
          movable: true,
        ),
        EntityState(
          id: 'reflector',
          type: EntityType.rotatingReflector,
          position: Vec2(180, 280),
          size: Vec2(76, 12),
          reflectorOrientation: 2,
          reflectorRotationCount: 3,
        ),
      ],
    );
    await tester.pumpWidget(
      PropertyShotApp(initialState: state, showStageSelector: false),
    );
    await tester.pump();

    final semantics = tester.getSemantics(
      find.bySemanticsLabel(RegExp('회전 반사판.*90도')),
    );
    expect(semantics.getSemanticsData().label, contains('다음 충돌부터 90도 방향 변경'));
    expect(semantics.getSemanticsData().label, isNot(contains('45도')));

    await tester.tapAt(_logicalOffset(tester, 180, 280));
    await tester.pump();
    expect(find.byKey(const Key('entity_info_panel')), findsOneWidget);
    expect(find.text('현재 세로 방향 · 3회 회전'), findsOneWidget);
    expect(
      find.byKey(const Key('entity_thumbnail_rotatingReflector')),
      findsOneWidget,
    );
  });

  testWidgets('스테이지 포기는 취소할 수 있고 확인한 뒤에만 화면을 나간다', (tester) async {
    var exited = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: levels.first.createState(0),
          showStageSelector: false,
          onExit: () => exited = true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('stage_abandon_button')));
    await tester.pump();
    expect(find.byKey(const Key('stage_abandon_dialog')), findsOneWidget);
    expect(exited, isFalse);

    await tester.tap(find.byKey(const Key('stage_abandon_cancel_button')));
    await tester.pump();
    expect(find.byKey(const Key('stage_abandon_dialog')), findsNothing);
    expect(exited, isFalse);

    await tester.tap(find.byKey(const Key('stage_abandon_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stage_abandon_confirm_button')));
    await tester.pump();
    expect(exited, isTrue);
  });

  testWidgets('9단계 화면은 현재 반사와 다음 충돌 회전을 한글로 안내한다', (tester) async {
    await tester.pumpWidget(
      PropertyShotApp(
        initialState: levels[8].createState(8, productRules: true),
        showStageSelector: false,
      ),
    );
    await tester.pump();

    expect(find.text('9. 판을 돌려 놓아라'), findsOneWidget);
    expect(find.textContaining('반사판 회전 → 다음 경로'), findsOneWidget);
    expect(find.byKey(const Key('hud_progress_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hud_progress_button')));
    await tester.pump();
    expect(find.text('진행 상황'), findsOneWidget);
    expect(find.text('현재 면 반사 · 충돌 뒤 90도 회전'), findsWidgets);
  });

  testWidgets('상단 정보는 생성 이미지 아이콘을 누를 때 좁은 설명 팝업으로 열린다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      PropertyShotApp(
        initialState: levels[1].createState(1, productRules: true),
        showStageSelector: false,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('hud_info_actions')), findsOneWidget);
    expect(find.byKey(const Key('hud_objective_button')), findsOneWidget);
    expect(find.byKey(const Key('hud_controls_button')), findsOneWidget);
    expect(find.byKey(const Key('hud_status_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hud_objective_button')));
    await tester.pump();
    expect(find.text('이번 스테이지 목표'), findsOneWidget);
    final dialogContent = tester.getSize(
      find.byKey(const Key('hud_info_dialog_content')),
    );
    expect(dialogContent.width, lessThanOrEqualTo(360));
    expect(
      tester
          .widgetList<Image>(find.byType(Image))
          .any(
            (image) =>
                image.image is AssetImage &&
                (image.image as AssetImage).assetName ==
                    'assets/generated/nav-stage-map-v1.png',
          ),
      isTrue,
    );
  });

  testWidgets('10단계 화면은 새 기믹 없이 자유로운 종합 경로를 안내한다', (tester) async {
    await tester.pumpWidget(
      PropertyShotApp(
        initialState: levels[9].createState(9, productRules: true),
        showStageSelector: false,
      ),
    );
    await tester.pump();

    expect(find.text('10. 속성 한방'), findsOneWidget);
    expect(find.textContaining('속성 → 기믹 연계 → 홀'), findsOneWidget);
    expect(find.byKey(const Key('hud_progress_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hud_progress_button')));
    await tester.pump();
    expect(find.text('진행 상황'), findsOneWidget);
    expect(find.text('직접 성공 · 속성 · 연쇄 모두 가능'), findsWidgets);
  });

  testWidgets('섬 지도는 진행 경로와 실제 한 번 탭 동작을 안내한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pump();

    expect(find.byKey(const Key('stage_route_map')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('map_hint_card')),
      280,
      scrollable: find.byType(Scrollable),
    );
    expect(find.byKey(const Key('map_hint_card')), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const Key('stage_tile_0')),
    );
    expect(semantics.getSemanticsData().hint, '한 번 누르면 스테이지를 시작합니다');
  });

  testWidgets('진행 중인 다른 스테이지가 있으면 선택 제한 이유와 이어하기를 안내한다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    await session.selectStage(levels[1].id);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_tile_0')));
    await _pumpForAsyncWork(tester);

    expect(
      find.text(
        '다른 스테이지가 진행 중이어서 이 섬을 선택할 수 없어요. '
        '현재 스테이지를 먼저 이어서 플레이해 주세요.',
      ),
      findsOneWidget,
    );
    expect(find.text('이어하기'), findsOneWidget);

    await tester.tap(find.text('이어하기'));
    await _pumpForAsyncWork(tester);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).levelOverride?.id,
      levels[1].id,
    );
    expect(find.textContaining('다른 스테이지가 진행 중'), findsNothing);
  });

  testWidgets('스테이지 제한 안내는 지도에서 나가면 다른 화면을 가리지 않는다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    await session.selectStage(levels[1].id);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_tile_0')));
    await _pumpForAsyncWork(tester);
    expect(find.textContaining('다른 스테이지가 진행 중'), findsOneWidget);

    await tester.tap(find.byTooltip('처음 화면'));
    await tester.pump();
    expect(find.byKey(const Key('home_screen_golden')), findsOneWidget);
    expect(find.textContaining('다른 스테이지가 진행 중'), findsNothing);
  });

  testWidgets('320 화면은 복구 현황을 접어 첫 스테이지를 첫 화면에 노출한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const Key('stage_select_screen'))).width,
      320,
    );
    expect(find.byKey(const Key('island_restoration_expand')), findsOneWidget);
    final firstStage = tester.getRect(find.byKey(const Key('stage_tile_0')));
    expect(firstStage.top, lessThan(568));
    expect(firstStage.height, greaterThanOrEqualTo(100));
    expect(tester.takeException(), isNull);
  });

  testWidgets('영구 발견 기록은 재시작 뒤 섬 지도 진행도로 복원된다', (tester) async {
    SharedPreferences.setMockInitialValues({
      ProgressStore.discoveryRecordsKey: [
        '${levels[0].id}::heavy_equipped',
        '${levels[0].id}::crate_moved',
        '${levels[1].id}::bouncy_equipped',
        '${levels[0].id}::폐기된_발견',
      ],
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    expect(find.textContaining('발견 3 / 30'), findsOneWidget);
    expect(find.text('발견 2/3 · 추천 파 ${levels[0].parShots}회'), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNWidgets(levels.length - 1));
  });

  testWidgets('클리어 진행 상태가 섬 지도에서 4단계를 연다', (tester) async {
    SharedPreferences.setMockInitialValues({'property_shot_unlocked_level': 3});
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNWidgets(levels.length - 4));
    await tester.ensureVisible(find.byKey(const Key('stage_tile_3')));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_tile_3')));
    await tester.pump();

    expect(find.text('4. 풍선 터뜨리기'), findsOneWidget);
  });

  testWidgets('단계별 클리어 기록이 섬 지도 해금을 복원한다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'property_shot_cleared_levels': ['0', '1', '2', '3'],
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNWidgets(levels.length - 5));
  });

  testWidgets('모든 단계 클리어 기록은 재시작 뒤 섬 지도 전체 해금을 복원한다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'property_shot_cleared_stage_ids': [for (final level in levels) level.id],
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    for (var index = 0; index < levels.length; index++) {
      expect(find.byKey(Key('stage_tile_$index')), findsOneWidget);
    }
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNothing);
  });

  testWidgets('8단계에서 추첨한 패턴은 앱 화면을 다시 만든 뒤에도 복원된다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'property_shot_cleared_stage_ids': [for (final level in levels) level.id],
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);
    for (var scroll = 0; scroll < 2; scroll++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('stage_tile_7')));
    await _pumpForAsyncWork(tester);

    final firstPattern = tester
        .widget<GameScreen>(find.byType(GameScreen))
        .levelOverride
        ?.patternId;
    expect(firstPattern, startsWith('stage_chain_score_'));

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpForAsyncWork(tester);
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);
    for (var scroll = 0; scroll < 2; scroll++) {
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byKey(const Key('stage_tile_7')));
    await _pumpForAsyncWork(tester);

    expect(
      tester
          .widget<GameScreen>(find.byType(GameScreen))
          .levelOverride
          ?.patternId,
      firstPattern,
    );
  });

  testWidgets('홈 시작은 저장된 8단계 샷을 재생해 같은 보드 상태를 복원한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    final draw = await session.selectStage('stage_chain_score');
    final savedInput = const ShotInput(direction: Vec2(0, 1), power: 0.12);
    await session.recordShot(input: savedInput);
    final level = draw.pattern.toLevelDefinition(
      stageId: draw.stageId,
      stageTitle: generatedStageCatalog.stageById(draw.stageId).title,
    );
    final expected = const ShotResolver().resolve(
      level.createState(7, productRules: true),
      savedInput,
    );

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.levelOverride?.patternId, draw.patternId);
    expect(screen.initialShotResults, hasLength(1));
    expect(screen.initialShotInputs, hasLength(1));
    expect(screen.initialShotInputs.single.direction, savedInput.direction);
    expect(screen.initialShotInputs.single.power, savedInput.power);
    expect(screen.initialState?.shotCount, expected.state.shotCount);
    expect(
      shotResultFingerprint(screen.initialShotResults.single),
      shotResultFingerprint(expected),
    );
    expect(
      screen.initialState?.activeBall.position,
      expected.state.activeBall.position,
    );

    await tester.tap(find.byKey(const Key('rewind_button')).first);
    await _pumpForAsyncWork(tester);

    final rewoundSession = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    await rewoundSession.loadState();
    expect(rewoundSession.currentShotInputs, isEmpty);
    expect(_currentShotCount(tester), 0);
  });

  testWidgets('홈 시작은 복제와 옮기기를 소비 전 코어 수에서 재생한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    final draw = await session.selectStage(
      'stage_chain_score',
      initialCloneCoreCount: 1,
    );
    final source = draw.pattern.objects.firstWhere(
      (object) => object.traits.isNotEmpty,
    );
    final actions = [
      RunTraitActionRecord(sourceId: source.id, action: RunTraitAction.copy),
      RunTraitActionRecord(
        sourceId: source.id,
        action: RunTraitAction.transfer,
      ),
    ];
    for (final action in actions) {
      await session.recordTraitAction(
        sourceId: action.sourceId,
        action: action.action,
      );
    }
    final input = ShotInput(
      direction: const Vec2(0.8, -0.6),
      power: 0.34,
      equippedTrait: source.traits.first,
    );
    await session.recordShot(input: input);
    final stage = generatedStageCatalog.stageById(draw.stageId);
    final level = draw.pattern.toLevelDefinition(
      stageId: stage.stageId,
      stageTitle: stage.title,
    );
    var expectedState = level.createState(
      7,
      productRules: true,
      copyCoreCount: 1,
    );
    const traitResolver = TraitResolver();
    for (final action in actions) {
      expectedState = traitResolver.selectSource(
        expectedState,
        action.sourceId,
      );
      expectedState = switch (action.action) {
        RunTraitAction.copy => traitResolver.copySelectedTrait(expectedState),
        RunTraitAction.transfer => traitResolver.transferSelectedTrait(
          expectedState,
        ),
      };
    }
    final expected = const ShotResolver().resolve(expectedState, input);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.initialShotResults, hasLength(1));
    expect(screen.initialShotInputs, hasLength(1));
    expect(screen.initialShotInputs.single.direction, input.direction);
    expect(screen.initialShotInputs.single.power, input.power);
    expect(screen.initialShotInputs.single.equippedTrait, input.equippedTrait);
    expect(screen.initialState?.copyCoreCount, 0);
    expect(
      screen.initialState?.entityById(source.id)?.traits,
      expected.state.entityById(source.id)?.traits,
    );
    expect(
      shotResultFingerprint(screen.initialShotResults.single),
      shotResultFingerprint(expected),
    );
  });

  testWidgets('성공 샷 저장 직후 종료해도 런 완료와 지도 기록을 복구한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    final draw = await session.selectStage('stage_chain_score');
    final solution = stageChainScoreSolutions.singleWhere(
      (candidate) => candidate.patternId == draw.patternId,
    );
    final level = draw.pattern.toLevelDefinition(
      stageId: draw.stageId,
      stageTitle: generatedStageCatalog.stageById(draw.stageId).title,
    );
    final expected = const ShotResolver().resolve(
      level.createState(7, productRules: true),
      solution.directInput,
    );
    expect(expected.state.phase, GamePhase.success);
    await session.recordShot(input: solution.directInput);
    expect(session.state?.phase, RunPhase.playing);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    final restoredSession = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    final restoredRun = await restoredSession.loadState();
    final progress = await ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((stage) => stage.id),
    ).load();
    expect(restoredRun?.phase, RunPhase.rewardSelectionPending);
    expect(restoredRun?.rewardCandidateIds, hasLength(3));
    expect(restoredRun?.shotsPerStage['stage_chain_score'], 1);
    expect(progress.clearedLevels, contains(7));

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('next_stage_button')))
          .onPressed,
      isNull,
    );
    final rewardButton = find.byKey(
      Key('run_reward_${restoredRun!.rewardCandidateIds.first}'),
    );
    await tester.ensureVisible(rewardButton);
    await tester.tap(rewardButton);
    await _pumpForAsyncWork(tester);

    final selectedRun = await StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    ).loadState();
    expect(selectedRun?.phase, RunPhase.rewardSelectionCompleted);
    expect(selectedRun?.selectedRewardId, restoredRun.rewardCandidateIds.first);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('next_stage_button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('비워진 원본 성공 샷 직후 종료해도 보너스와 최고 기록을 복구한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    final solution = stageDrainedRepresentativeSolutions.first;
    late StagePatternDraw draw;
    for (var index = 0; index < 4; index++) {
      draw = await session.selectStage('stage_drained');
      if (draw.patternId == solution.patternId) break;
      await session.completeCurrentStage(
        stageId: 'stage_drained',
        shotCount: 3,
      );
    }
    expect(draw.patternId, solution.patternId);
    expect(
      await RunDifficultyAttributionStore(
        preferences,
      ).save(session.state!, PlayerDifficulty.normal),
      isTrue,
    );
    final source = draw.pattern.objects.firstWhere(
      (object) => object.id == solution.strategyId,
    );
    await session.recordTraitAction(
      sourceId: source.id,
      action: RunTraitAction.transfer,
    );
    final input = ShotInput(
      direction: solution.direction,
      power: solution.power,
      equippedTrait: source.traits.first,
    );
    await session.recordShot(input: input);
    expect(session.state?.phase, RunPhase.playing);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    final restoredSession = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    final restoredRun = await restoredSession.loadState();
    final progress = await ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((stage) => stage.id),
    ).load();
    expect(restoredRun?.phase, RunPhase.rewardSelectionPending);
    expect(restoredRun?.rewardCandidateIds, hasLength(3));
    expect(
      restoredRun?.optionalChallenges['stage_drained:${solution.patternId}'],
      isTrue,
    );
    expect(progress.clearedLevels, contains(4));
    expect(progress.bestShots[4], 1);
    expect(progress.bonusGoals, contains(4));
  });

  testWidgets('클리어 완료 뒤 종료해도 복제 코어 보상을 한 번만 복구한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final rewardIndex = levels.indexWhere((level) => level.copyCoreReward > 0);
    expect(rewardIndex, greaterThanOrEqualTo(0));
    expect(rewardIndex, lessThan(levels.length - 1));
    final rewardLevel = levels[rewardIndex];
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    await session.selectStage(rewardLevel.id);
    await session.completeCurrentStage(
      stageId: rewardLevel.id,
      nextStageId: levels[rewardIndex + 1].id,
      shotCount: 1,
    );
    expect(session.state?.cloneCoreCount, 0);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final firstScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(firstScreen.initialState?.copyCoreCount, rewardLevel.copyCoreReward);
    final firstRestored = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    final firstRun = await firstRestored.loadState();
    expect(firstRun?.cloneCoreCount, rewardLevel.copyCoreReward);
    expect(
      firstRun?.acquiredRewards,
      contains('stage_clone_core:${rewardLevel.id}'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final secondScreen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(
      secondScreen.initialState?.copyCoreCount,
      rewardLevel.copyCoreReward,
    );
  });

  testWidgets('구형 복제 코어는 첫 RunState로 옮긴 뒤 그 기록만 기준으로 삼는다', (tester) async {
    SharedPreferences.setMockInitialValues({
      ProgressStore.copyCoreCountKey: 2,
      ProgressStore.copyCoreRewardedKey: true,
    });
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final migratedSession = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    final migrated = await migratedSession.loadState();
    expect(migrated?.cloneCoreCount, 2);
    expect(
      migrated?.acquiredRewards,
      contains(stageCloneCoreRewardId(legacyCloneCoreRewardStageId)),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpForAsyncWork(tester);
    await preferences.setInt(ProgressStore.copyCoreCountKey, 99);
    await preferences.setBool(ProgressStore.copyCoreRewardedKey, false);
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(screen.initialState?.copyCoreCount, 2);
    final mirrored = await ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((stage) => stage.id),
    ).load();
    expect(mirrored.copyCoreCount, 2);
    expect(mirrored.copyCoreRewarded, isTrue);
    expect(mirrored.copyCoreRewardedStageIds, {legacyCloneCoreRewardStageId});
  });

  testWidgets('표식 없는 구형 완료 런은 복제 코어를 늘리지 않고 지급 상태만 옮긴다', (tester) async {
    final rewardIndex = levels.indexWhere(
      (level) => level.id == legacyCloneCoreRewardStageId,
    );
    expect(rewardIndex, greaterThanOrEqualTo(0));
    expect(levels[rewardIndex].copyCoreReward, greaterThan(0));
    SharedPreferences.setMockInitialValues({
      ProgressStore.copyCoreCountKey: 2,
      ProgressStore.copyCoreRewardedKey: true,
    });
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    await session.selectStage(levels[rewardIndex].id, initialCloneCoreCount: 2);
    await session.completeCurrentStage(
      stageId: levels[rewardIndex].id,
      nextStageId: levels[rewardIndex + 1].id,
      shotCount: 1,
    );
    expect(session.state?.acquiredRewards, isEmpty);

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final restoredSession = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    final restored = await restoredSession.loadState();
    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    expect(restored?.cloneCoreCount, 2);
    expect(
      restored?.acquiredRewards,
      contains(stageCloneCoreRewardId(legacyCloneCoreRewardStageId)),
    );
    expect(
      restored?.acquiredRewards,
      contains(stageCloneCoreRewardId(levels[rewardIndex].id)),
    );
    expect(screen.initialState?.copyCoreCount, 2);
    expect(screen.initialState?.copyCoreRewarded, isTrue);
    final mirrored = await ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((level) => level.id),
    ).load();
    expect(mirrored.copyCoreCount, 2);
    expect(mirrored.copyCoreRewardedStageIds, {legacyCloneCoreRewardStageId});
  });

  testWidgets('런 완료 뒤 지도 저장 전에 종료해도 클리어 기록을 복구한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
      now: () => DateTime.utc(2026, 8, 7, 8),
    );
    await session.selectStage(levels.first.id);
    expect(
      await RunDifficultyAttributionStore(
        preferences,
      ).save(session.state!, PlayerDifficulty.normal),
      isTrue,
    );
    await session.completeCurrentStage(
      stageId: levels.first.id,
      nextStageId: levels[1].id,
      shotCount: 2,
      optionalChallengeAchieved: true,
    );
    final beforeRecovery = await ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((stage) => stage.id),
    ).load();
    expect(beforeRecovery.clearedLevels, isNot(contains(0)));

    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    final recovered = await ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((stage) => stage.id),
    ).load();
    expect(recovered.clearedLevels, contains(0));
    expect(recovered.unlockedLevel, greaterThanOrEqualTo(1));
    expect(recovered.bestShots[0], 2);
    expect(recovered.bonusGoals, contains(0));
    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).levelOverride?.id,
      levels.first.id,
    );
    expect(
      tester
          .widget<GameScreen>(find.byType(GameScreen))
          .initialRewardCandidates,
      hasLength(3),
    );
  });

  testWidgets('지도 저장 실패 전에는 다음 단계를 해금하지 않고 재시도 뒤에만 연다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final preferences = await SharedPreferences.getInstance();
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(
        backend: SharedPreferencesRunStateBackend(preferences),
      ),
    );
    await session.selectStage(levels.first.id);
    await session.completeCurrentStage(
      stageId: levels.first.id,
      nextStageId: levels[1].id,
      shotCount: 2,
    );
    final store = _FailOnceStageClearProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((level) => level.id),
    );

    await tester.pumpWidget(
      PropertyShotApp(
        key: const ValueKey('첫 저장 시도'),
        showHome: true,
        progressStore: store,
      ),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    expect(store.stageClearAttempts, 1);
    expect(find.byType(GameScreen), findsNothing);
    expect(find.text('단계 정보를 불러오지 못했습니다. 다시 시도해 주세요.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);
    expect(find.text('1 / ${levels.length}'), findsOneWidget);

    await tester.pumpWidget(
      PropertyShotApp(
        key: const ValueKey('저장 재시도'),
        showHome: true,
        progressStore: store,
      ),
    );
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('start_game_button')));
    await _pumpForAsyncWork(tester);

    expect(store.stageClearAttempts, 2);
    expect(find.byType(GameScreen), findsOneWidget);
    expect(
      tester.widget<GameScreen>(find.byType(GameScreen)).levelOverride?.id,
      levels.first.id,
    );
    expect(
      tester
          .widget<GameScreen>(find.byType(GameScreen))
          .initialRewardCandidates,
      hasLength(3),
    );
    final progress = await store.load();
    expect(progress.clearedLevels, contains(0));
    expect(progress.unlockedLevel, 1);
  });

  testWidgets('기존 게임 화면 해금 기록도 섬 지도에서 호환한다', (tester) async {
    SharedPreferences.setMockInitialValues({'unlocked_level': 3});
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNWidgets(levels.length - 4));
  });

  testWidgets('홈의 첫 섬 시작 버튼은 첫 스테이지 플레이로 이동한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();

    await tester.tap(find.byKey(const Key('start_game_button')));
    await tester.pump();

    expect(find.byKey(const Key('aim_area')), findsOneWidget);
    expect(find.byKey(const Key('home_button')), findsOneWidget);
    expect(find.text('1. 무거움 익히기'), findsOneWidget);
  });

  testWidgets('홈 설정에서 효과음과 진동을 각각 끌 수 있다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    addTearDown(() {
      GameFeedback.soundEnabled = true;
      GameFeedback.hapticsEnabled = true;
      GameFeedback.screenShakeEnabled = true;
      GameFeedback.reducedMotionEnabled = false;
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await _pumpForAsyncWork(tester);

    await tester.tap(find.byKey(const Key('feedback_settings_button')));
    await _pumpForAsyncWork(tester);
    expect(find.text('게임 설정'), findsOneWidget);

    for (final key in const [
      Key('sound_toggle'),
      Key('haptics_toggle'),
      Key('screen_shake_toggle'),
      Key('reduced_motion_toggle'),
    ]) {
      await tester.ensureVisible(find.byKey(key));
      await tester.pump();
      await tester.tap(find.byKey(key));
    }
    await tester.pump();

    expect(GameFeedback.soundEnabled, isFalse);
    expect(GameFeedback.hapticsEnabled, isFalse);
    expect(GameFeedback.screenShakeEnabled, isFalse);
    expect(GameFeedback.reducedMotionEnabled, isTrue);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('복제 코어가 없으면 실제 플레이 화면에 복사 행동을 노출하지 않는다', (tester) async {
    final state = levels[0].createState(0, productRules: true);
    await tester.pumpWidget(
      PropertyShotApp(initialState: state, showStageSelector: false),
    );
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    expect(find.byKey(const Key('transfer_button')), findsOneWidget);
    expect(find.byKey(const Key('copy_button')), findsNothing);
    expect(find.textContaining('복사 0회'), findsNothing);
  });

  testWidgets('복제 코어를 보유하면 속성 팝업에 선택 행동이 표시된다', (tester) async {
    final state = levels[0].createState(
      0,
      productRules: true,
      copyCoreCount: 1,
    );
    await tester.pumpWidget(
      PropertyShotApp(initialState: state, showStageSelector: false),
    );
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    expect(find.text('복제 코어로 공에 담기'), findsOneWidget);
    expect(find.text('복제 코어 1개 남음'), findsOneWidget);
  });

  testWidgets('단계 초기화는 진입 시점의 복제 코어를 복원한다', (tester) async {
    final state = levels[0].createState(
      0,
      productRules: true,
      copyCoreCount: 1,
    );
    await tester.pumpWidget(
      PropertyShotApp(initialState: state, showStageSelector: false),
    );
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    await tester.tap(find.byKey(const Key('copy_button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('reset_button')));
    await tester.pump();
    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    expect(find.text('복제 코어 1개 남음'), findsOneWidget);
  });

  testWidgets('속성을 선택해 공으로 옮길 수 있다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.textContaining('1. 무거움 익히기'), findsOneWidget);
    expect(find.byKey(const Key('compact_message')), findsOneWidget);
    expect(find.byKey(const Key('tutorial_coach_mark')), findsOneWidget);
    expect(find.text('바위를 눌러 무거움을 골라요'), findsOneWidget);

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('추천 경로 설명')), findsWidgets);
    await tester.tap(find.byKey(const Key('transfer_button')));
    await tester.pump();

    expect(find.textContaining('공 속성: 무거움'), findsOneWidget);
    expect(find.textContaining('무거움 · 상자 밀기 · 무게 스위치'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('compact_message')))
          .getSemanticsData()
          .label,
      contains('추천 경로를 준비했습니다'),
    );
    expect(find.text('상자를 밀도록 조준해 발사해요'), findsOneWidget);
    expect(find.text('공을 길게 눌러 힘을 모으세요'), findsOneWidget);
  });

  testWidgets('2단계 첫 화면은 젤리 탄성과 반사를 행동으로 안내한다', (tester) async {
    await tester.pumpWidget(
      PropertyShotApp(
        initialState: levels[1].createState(1, productRules: true),
        showStageSelector: false,
      ),
    );
    await tester.pump();

    expect(find.text('젤리를 눌러 탄성을 골라요'), findsOneWidget);
    final board = tester.getRect(find.byKey(const Key('aim_area')));
    final coach = tester.getRect(find.byKey(const Key('tutorial_coach_mark')));
    expect(coach.left, greaterThanOrEqualTo(board.left));
    expect(coach.right, lessThanOrEqualTo(board.right));
  });

  testWidgets('3단계 첫 화면은 무거움과 스위치의 인과를 행동으로 안내한다', (tester) async {
    await tester.pumpWidget(
      PropertyShotApp(
        initialState: levels[2].createState(2, productRules: true),
        showStageSelector: false,
      ),
    );
    await tester.pump();

    expect(find.text('쇳덩이를 눌러 무거움을 골라요'), findsOneWidget);
  });

  test('네 속성은 발동 조건과 소모 규칙을 짧게 안내한다', () {
    expect(TraitType.heavy.compactEffect, contains('무게 스위치'));
    expect(TraitType.bouncy.compactEffect, contains('때마다'));
    expect(TraitType.bouncy.description, contains('탄성을 유지'));
    expect(TraitType.sticky.compactEffect, contains('첫 유효 표면'));
    expect(TraitType.sharp.compactEffect, contains('소모'));
  });

  testWidgets('속성 행동은 런 저장이 끝난 뒤에만 화면에 적용된다', (tester) async {
    final persisted = Completer<void>();
    String? savedSourceId;
    RunTraitAction? savedAction;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: levels[0].createState(0, productRules: true),
          levelOverride: levels[0],
          showStageSelector: false,
          loadGameAssets: false,
          onTraitActionCommitted: (sourceId, action) {
            savedSourceId = sourceId;
            savedAction = action;
            return persisted.future;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer_button')));
    await tester.pump();

    expect(savedSourceId, 'anvil');
    expect(savedAction, RunTraitAction.transfer);
    expect(find.textContaining('공 속성: 없음'), findsOneWidget);
    persisted.complete();
    await _pumpForAsyncWork(tester);
    expect(find.textContaining('공 속성: 무거움'), findsOneWidget);
  });

  testWidgets('속성을 선택해 공으로 복사할 수 있다', (tester) async {
    final state = levels[0].createState(
      0,
      productRules: true,
      copyCoreCount: 1,
    );
    await tester.pumpWidget(PropertyShotApp(initialState: state));
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    expect(find.text('복제 코어 1개 남음'), findsOneWidget);
    await tester.tap(find.byKey(const Key('copy_button')));
    await tester.pump();

    expect(find.textContaining('공 속성: 무거움'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('compact_message')))
          .getSemanticsData()
          .label,
      contains('복사했습니다'),
    );
    expect(find.byKey(const Key('copy_button')), findsNothing);
    expect(find.textContaining('선택:'), findsNothing);
  });

  testWidgets('이전과 복사의 원본 결과를 구분해 안내한다', (tester) async {
    final state = levels[0].createState(
      0,
      productRules: true,
      copyCoreCount: 1,
    );
    await tester.pumpWidget(PropertyShotApp(initialState: state));
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    expect(find.text('속성 옮기기'), findsOneWidget);
    expect(find.text('복제 코어로 공에 담기'), findsOneWidget);
    expect(find.textContaining('원본에서 사라짐'), findsOneWidget);
    expect(find.textContaining('원본에 유지됨'), findsOneWidget);
  });

  testWidgets('드래그 조준만으로는 발사되지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final aimArea = find.byKey(const Key('aim_area'));
    await tester.drag(aimArea, const Offset(-80, 80));
    await tester.pump();

    expect(_currentShotCount(tester), 0);
    expect(find.byKey(const Key('launch_button')), findsNothing);
  });

  testWidgets('공을 길게 눌러 힘 조준을 끝내면 자동 발사된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump();

    expect(_currentShotCount(tester), 1);
  });

  testWidgets('발사 입력 지연은 손을 뗀 뒤 비동기 저장과 물리 판정을 포함한다', (tester) async {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    final shotCommit = Completer<bool>();
    var commitStarted = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          telemetry: telemetry,
          onShotCommitted: (_, _) {
            commitStarted = true;
            return shotCommit.future;
          },
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    expect(commitStarted, isTrue);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    shotCommit.complete(true);
    await _pumpForAsyncWork(tester, frames: 2);

    final released = telemetry.events.lastWhere(
      (event) => event['event_code'] == 'shot_released',
    );
    expect(released['input_latency_ms'], greaterThanOrEqualTo(20));
  });

  testWidgets('멀티터치는 첫 포인터만 발사 입력으로 인정한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final first = await tester.createGesture(pointer: 41);
    await first.down(
      _logicalOffset(tester, 56, 456),
      timeStamp: _testPointerDownAt,
    );
    final second = await tester.createGesture(pointer: 42);
    await second.down(
      _logicalOffset(tester, 120, 400),
      timeStamp: const Duration(milliseconds: 1100),
    );
    await second.up(timeStamp: const Duration(milliseconds: 1200));

    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(first, const Duration(milliseconds: 760));
    await tester.pump();

    expect(_currentShotCount(tester), 1);
  });

  testWidgets('발사 애니메이션 중에는 두 번째 샷을 만들지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final first = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(first, const Duration(milliseconds: 760));
    await tester.pump(const Duration(milliseconds: 80));

    final second = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(second, const Duration(milliseconds: 760));
    await tester.pump(const Duration(milliseconds: 80));

    expect(_currentShotCount(tester), 1);
  });

  testWidgets('발사 애니메이션 중에는 물체 정보 팝업이 열리지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump(const Duration(milliseconds: 80));

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    expect(find.byKey(const Key('entity_info_panel')), findsNothing);
  });

  testWidgets('실패한 샷은 재조준과 복구 행동을 보여준다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump(const Duration(milliseconds: 6500));

    expect(find.byKey(const Key('failure_popup')), findsOneWidget);
    expect(find.text('바로 다시 조준'), findsOneWidget);
    expect(find.byKey(const Key('failure_replay_button')), findsOneWidget);
    expect(find.text('되감기'), findsOneWidget);
    expect(find.text('단계 처음부터'), findsOneWidget);

    await tester.tap(find.byKey(const Key('failure_replay_button')));
    await tester.pump();
    expect(find.byKey(const Key('failure_replay_dialog')), findsOneWidget);
    expect(find.text('충돌 순서'), findsOneWidget);
    await tester.tap(find.byKey(const Key('failure_replay_close_button')));
    await tester.pump();

    await tester.tap(find.byKey(const Key('failure_retry_button')));
    await tester.pump();
    expect(find.byKey(const Key('failure_popup')), findsNothing);
    expect(find.byKey(const Key('previous_aim_semantics')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('직전 조준이 회색으로 남아 있습니다')), findsWidgets);
    final game = tester
        .widget<GameWidget<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        )
        .game!;
    expect(game.previousAimInput, isNotNull);
    expect(game.previousAimInput!.direction, const Vec2(1, 0));
    expect(game.previousShotPath.length, greaterThanOrEqualTo(2));

    await tester.tap(find.byKey(const Key('rewind_button')).first);
    await tester.pump();
    expect(game.previousAimInput, isNull);
    expect(game.previousShotPath, isEmpty);
    expect(find.byKey(const Key('previous_aim_semantics')), findsNothing);
  });

  testWidgets('직전 조준 비교를 끄면 재시도 후 비교선을 남기지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      GameFeedback.settingsSchemaVersionKey: GameFeedback.settingsSchemaVersion,
      GameFeedback.previousAimComparisonPreferenceKey: false,
    });
    GameFeedback.previousAimComparisonEnabled = false;
    addTearDown(GameFeedback.resetForTesting);
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump(const Duration(milliseconds: 6500));

    await tester.tap(find.byKey(const Key('failure_retry_button')));
    await tester.pump();

    final game = tester
        .widget<GameWidget<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        )
        .game!;
    expect(game.previousAimInput, isNull);
    expect(find.byKey(const Key('previous_aim_semantics')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('각도나 힘 한 가지만')), findsWidgets);
  });

  testWidgets('인과를 만든 다중 샷 실패는 준비 상태 연습과 기록 분리를 제공한다', (tester) async {
    final initial = _practiceCheckpointBaseState();
    final prepared = initial.copyWith(
      shotCount: 1,
      equippedTrait: TraitType.heavy,
      history: [initial],
      message: '첫 샷에서 무거움 인과를 확인했습니다.',
    );
    var assistedMarked = false;
    var rewound = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: prepared,
          initialShotInputs: const [
            ShotInput(
              direction: Vec2(1, 0),
              power: 0.5,
              equippedTrait: TraitType.heavy,
            ),
          ],
          initialShotResults: [
            ShotResult(
              state: prepared,
              path: const [Vec2(56, 456), Vec2(110, 456)],
              events: const ['heavy_equipped'],
            ),
          ],
          onPracticeAssistUsed: () async {
            assistedMarked = true;
            return true;
          },
          onShotRewound: () async {
            rewound = true;
            return const <String>{};
          },
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump(const Duration(milliseconds: 6500));

    expect(
      find.byKey(const Key('failure_prepared_retry_button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('failure_rewind_button')), findsNothing);
    await tester.tap(find.byKey(const Key('failure_prepared_retry_button')));
    await _pumpForAsyncWork(tester);

    expect(assistedMarked, isTrue);
    expect(rewound, isTrue);
    expect(find.byKey(const Key('failure_popup')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('최고 기록은 연습 기록으로 분리')), findsWidgets);
    expect(_currentShotCount(tester), 1);
  });

  testWidgets('일시정지 중에는 힘 조준으로 발사되지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tap(find.byKey(const Key('pause_button')));
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump();

    expect(_currentShotCount(tester), 0);
  });

  testWidgets('롱프레스가 취소되면 발사하지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await gesture.cancel();
    await tester.pump();

    expect(_currentShotCount(tester), 0);
    expect(
      tester
          .getSemantics(find.byKey(const Key('compact_message')))
          .getSemanticsData()
          .label,
      contains('발사를 취소했습니다'),
    );
  });

  testWidgets('롱프레스가 활성화되기 전에 취소되면 발사하지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 120));
    await gesture.cancel();
    await tester.pump();

    expect(_currentShotCount(tester), 0);
  });

  testWidgets('앱 생명주기 전환 중 충전은 취소되고 복귀 후 발사되지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump();

    expect(_currentShotCount(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('화면 크기 변경 중 활성 포인터는 취소되고 복귀 후 발사되지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    tester.binding.handleMetricsChanged();
    await tester.pump();
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 760));
    await tester.pump();

    expect(_currentShotCount(tester), 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('화면 밖으로 이동한 포인터도 Listener의 종료 경로로 정리된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await gesture.moveTo(
      const Offset(-20, -20),
      timeStamp: const Duration(milliseconds: 1760),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 1761));
    await tester.pump();

    expect(_currentShotCount(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('공을 누르면 현재 속성 설명이 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 56, 456));
    await tester.pump();

    expect(find.byKey(const Key('ball_info_panel')), findsOneWidget);
    expect(find.text('공 속성 없음'), findsOneWidget);
    expect(find.byKey(const Key('ball_thumbnail_asset')), findsOneWidget);
  });

  testWidgets('물체를 누르면 물체 속성 설명이 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    expect(find.byKey(const Key('entity_info_panel')), findsOneWidget);
    expect(find.textContaining('무거움'), findsWidgets);
    final popupImages = tester.widgetList<Image>(
      find.descendant(
        of: find.byKey(const Key('entity_info_panel')),
        matching: find.byType(Image),
      ),
    );
    expect(
      popupImages.any(
        (image) =>
            image.image is AssetImage &&
            (image.image as AssetImage).assetName.startsWith(
              'assets/generated/',
            ),
      ),
      isTrue,
    );
  });

  testWidgets('과거 공을 누르면 순번·속성·고정 상태만 표시한다', (tester) async {
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
    );
    await tester.pumpWidget(
      PropertyShotApp(initialState: state, showStageSelector: false),
    );
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 180, 380));
    await tester.pump();

    expect(find.byKey(const Key('entity_info_panel')), findsOneWidget);
    expect(find.text('첫 번째 공'), findsOneWidget);
    expect(find.textContaining('점착으로 고정됨'), findsOneWidget);
    expect(find.byKey(const Key('transfer_button')), findsNothing);
    expect(find.byKey(const Key('copy_button')), findsNothing);
  });

  testWidgets('클리어 팝업의 다음 버튼은 다음 스테이지로 이동한다', (tester) async {
    final clearState = levels[1]
        .createState(1)
        .copyWith(phase: GamePhase.success, shotCount: 2, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect(find.textContaining('예시 기록'), findsOneWidget);
    expect(find.byKey(const Key('clear_stars')), findsOneWidget);
    expect(find.text('파 3회 · 3/3 별'), findsOneWidget);
    expect(find.byKey(const Key('retry_stage_button')), findsOneWidget);
    expect(find.bySemanticsLabel('공을 조준하는 게임 화면'), findsNothing);

    await tester.tap(find.byKey(const Key('next_stage_button')));
    await tester.pump();

    expect(find.textContaining('3. 연쇄 문 열기'), findsOneWidget);
  });

  testWidgets('활성 공이 없는 단계4 성공 상태도 축약 HUD 예외 없이 표시된다', (tester) async {
    final clearState = levels[3]
        .createState(3)
        .copyWith(
          phase: GamePhase.success,
          entities: [
            for (final entity in levels[3].createState(3).entities)
              if (entity.id != 'active_ball') entity,
          ],
          message: '홀 진입 성공!',
        );
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('클리어 팝업은 로컬에 저장된 추가 도전 달성을 표시한다', (tester) async {
    SharedPreferences.setMockInitialValues({'bonus_goal_level_1': true});
    final clearState = levels[1]
        .createState(1)
        .copyWith(phase: GamePhase.success, shotCount: 2, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('bonus_goal_status')), findsOneWidget);
    expect(find.text('추가 도전 달성'), findsOneWidget);
  });

  testWidgets('클리어 패널은 모바일에서 내용 중심 높이를 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final clearState = levels[1]
        .createState(1)
        .copyWith(phase: GamePhase.success, shotCount: 3, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    final panel = tester.getRect(find.byKey(const Key('clear_panel')));
    final next = tester.getRect(find.byKey(const Key('next_stage_button')));
    expect(panel.height, lessThan(600));
    expect(next.bottom, lessThanOrEqualTo(844));
    expect(tester.takeException(), isNull);
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
  ]) {
    testWidgets('최신 레벨 파를 반영한 클리어 팝업 Golden ${fixture.name}', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final loader = FontLoader('ClearPopupNanumGothic')
        ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
        ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
        ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
      final materialIcons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await Future.wait([loader.load(), materialIcons.load()]);
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final clearState = _directClearState().copyWith(
        phase: GamePhase.success,
        shotCount: 1,
        message: '홀 진입 성공!',
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('clear_popup_golden'),
          child: PropertyShotApp(
            initialState: clearState,
            showStageSelector: false,
            fontFamilyOverride: 'ClearPopupNanumGothic',
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('clear_popup')), findsOneWidget);
      expect(find.text('파 2회 · 3/3 별'), findsOneWidget);
      await expectLater(
        find.byKey(const Key('clear_popup_golden')),
        matchesGoldenFile('goldens/clear_popup_${fixture.name}.png'),
      );
    });
  }

  testWidgets('클리어 결과에서 기록 다시 도전은 같은 단계로 돌아간다', (tester) async {
    final clearState = levels[0]
        .createState(0)
        .copyWith(phase: GamePhase.success, shotCount: 5, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    await tester.tap(find.byKey(const Key('retry_stage_button')));
    await tester.pump();

    expect(find.byKey(const Key('clear_popup')), findsNothing);
    expect(find.byKey(const Key('aim_area')), findsOneWidget);
    expect(_currentShotCount(tester), 0);
  });

  testWidgets('클리어 결과 이동 중에는 기록 다시 도전을 함께 저장하지 않는다', (tester) async {
    final navigation = Completer<void>();
    var nextCalls = 0;
    var retryCalls = 0;
    final clearState = _directClearState().copyWith(
      phase: GamePhase.success,
      shotCount: 1,
      message: '홀 진입 성공!',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: clearState,
          showStageSelector: false,
          loadGameAssets: false,
          onStageRequested: (_) async {
            nextCalls++;
            await navigation.future;
          },
          onStageRestarted: () async {
            retryCalls++;
          },
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('next_stage_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('retry_stage_button')));
    await tester.pump();

    expect(nextCalls, 1);
    expect(retryCalls, 0);
    navigation.complete();
    await _pumpForAsyncWork(tester);
  });

  testWidgets('클리어 팝업을 뒤로가기로 닫으면 다시 조준할 수 있다', (tester) async {
    final clearState = levels[1]
        .createState(1)
        .copyWith(phase: GamePhase.success, shotCount: 3, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.byKey(const Key('clear_popup')), findsNothing);
    expect(find.byKey(const Key('aim_area')), findsOneWidget);
  });

  testWidgets('기본 상태에서는 다음 단계가 잠겨 있다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.bySemanticsLabel('2단계 잠김. 1단계 클리어 후 열림'), findsOneWidget);
    expect(find.textContaining('1. 무거움 익히기'), findsOneWidget);
  });

  testWidgets('마지막 단계 클리어는 런 결과 행동을 표시한다', (tester) async {
    final lastIndex = levels.length - 1;
    final clearState = levels[lastIndex]
        .createState(lastIndex)
        .copyWith(phase: GamePhase.success, shotCount: 4, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    expect(find.text('런 결과 보기'), findsOneWidget);
    expect(find.text('다음'), findsNothing);
  });

  testWidgets('실제 발사로 홀에 들어가면 클리어 팝업이 표시된다', (tester) async {
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    await tester.pumpWidget(
      PropertyShotApp(initialState: _directClearState(), telemetry: telemetry),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect(find.text('클리어!'), findsOneWidget);
    expect(
      telemetry.events.map((event) => event['event_code']),
      containsAllInOrder([
        'shot_released',
        'collision_chain_completed',
        'stage_cleared',
      ]),
    );
    final released = telemetry.events.lastWhere(
      (event) => event['event_code'] == 'shot_released',
    );
    expect(released['pattern_id'], isNotEmpty);
    expect(released['resolver_version'], 'shot-resolver-v1');
    expect(released['causal_chain'], isA<List<Object?>>());
    expect(released['nearest_hole_distance'], isA<double>());
    expect(released['input_latency_ms'], isA<double>());
    expect(released['input_latency_ms'], greaterThanOrEqualTo(0));
    expect(
      telemetry.events.where((event) => event['event_code'] == 'stage_cleared'),
      hasLength(1),
    );
    final firedShotId = telemetry.events.singleWhere(
      (event) => event['event_code'] == 'shot_fired',
    )['shot_id'];
    final collisionShotIds = telemetry.events
        .where((event) => event['event_code'] == 'collision_resolved')
        .map((event) => event['shot_id'])
        .toSet();
    expect(firedShotId, 1);
    expect(collisionShotIds, {firedShotId});
  });

  testWidgets('1단계 직접 성공도 점수를 계산해 일반 런 저장 흐름에 전달한다', (tester) async {
    CreativeChainScoreAnalysis? recordedAnalysis;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          loadGameAssets: false,
          onLevelCleared: (_, analysis, _, _) async {
            recordedAnalysis = analysis;
          },
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    final analysis = recordedAnalysis;
    expect(analysis, isNotNull);
    expect(analysis!.clearReached, isTrue);
    expect(analysis.breakdown.clearBasePoints, 1000);
    expect(analysis.breakdown.causalDepth, 0);
    expect(analysis.breakdown.distinctEntityIds, 0);
    expect(
      analysis.totalScore,
      analysis.breakdown.clearBasePoints + analysis.breakdown.minimumShotBonus,
    );
    expect(find.text('연쇄 점수 ${analysis.totalScore}점'), findsOneWidget);
  });

  testWidgets('클리어 팝업은 런과 다음 패턴 저장이 끝난 뒤 표시된다', (tester) async {
    final persisted = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          loadGameAssets: false,
          onLevelCleared: (_, _, _, _) => persisted.future,
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    expect(find.byKey(const Key('clear_popup')), findsNothing);
    persisted.complete();
    await _pumpForAsyncWork(tester);
    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
  });

  testWidgets('런 완료 저장이 실패하면 클리어 팝업과 다음 이동을 열지 않는다', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          loadGameAssets: false,
          onLevelCleared: (_, _, _, _) async {
            attempts++;
            if (attempts == 1) {
              throw StateError('저장 실패 주입');
            }
          },
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    expect(find.byKey(const Key('clear_popup')), findsNothing);
    expect(
      find.byKey(const Key('clear_persistence_error_popup')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('failure_popup')), findsNothing);
    expect(find.text('클리어 기록을 저장하지 못했습니다'), findsOneWidget);
    expect(find.byKey(const Key('failure_rewind_button')), findsNothing);
    expect(find.byKey(const Key('failure_reset_button')), findsNothing);
    expect(find.text('다음'), findsNothing);

    await tester.tap(find.byKey(const Key('clear_persistence_retry_button')));
    await _pumpForAsyncWork(tester);

    expect(attempts, 2);
    expect(
      find.byKey(const Key('clear_persistence_error_popup')),
      findsNothing,
    );
    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
  });

  testWidgets('최고 기록 저장이 한 번 실패해도 저장 다시 시도에서 실제 기록한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FailOnceBestShotProgressStore(stageCount: levels.length);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          loadGameAssets: false,
          progressStore: store,
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    expect(store.bestShotAttempts, 1);
    expect(
      find.byKey(const Key('clear_persistence_error_popup')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('clear_persistence_retry_button')));
    await _pumpForAsyncWork(tester);

    expect(store.bestShotAttempts, 2);
    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    final progress = await store.load();
    expect(progress.bestShots[0], 1);
  });

  testWidgets('초기 진행 기록 로드가 실패해도 발사와 이후 저장을 계속할 수 있다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FailOnceLoadProgressStore(stageCount: levels.length);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          loadGameAssets: false,
          progressStore: store,
        ),
      ),
    );
    await tester.pump();

    expect(store.loadAttempts, 1);
    expect(tester.takeException(), isNull);
    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));
    await _pumpForAsyncWork(tester);

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect((await store.load()).bestShots[0], 1);
  });

  testWidgets('보너스 저장이 한 번 실패해도 저장 다시 시도에서 실제 기록한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = _FailOnceBonusProgressStore(stageCount: levels.length);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          loadGameAssets: false,
          progressStore: store,
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    expect(store.bonusAttempts, 1);
    expect(
      find.byKey(const Key('clear_persistence_error_popup')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('clear_persistence_retry_button')));
    await _pumpForAsyncWork(tester);

    expect(store.bonusAttempts, 2);
    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    final progress = await store.load();
    expect(progress.bonusGoals, contains(0));
  });

  testWidgets('복제 코어 보상 저장 실패는 같은 클리어를 다시 저장한 뒤 보상을 재시도한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final rewardIndex = levels.indexWhere((level) => level.copyCoreReward > 0);
    expect(rewardIndex, greaterThanOrEqualTo(0));
    var clearAttempts = 0;
    var rewardAttempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(levelIndex: rewardIndex),
          loadGameAssets: false,
          showStageSelector: false,
          onLevelCleared: (_, _, _, _) async {
            clearAttempts++;
          },
          onCopyCoreEarned: (_, _) async {
            rewardAttempts++;
            if (rewardAttempts == 1) {
              throw StateError('복제 코어 보상 저장 실패 주입');
            }
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));

    expect(clearAttempts, 1);
    expect(rewardAttempts, 1);
    expect(find.text('복제 코어 보상을 저장하지 못했습니다'), findsOneWidget);
    expect(find.byKey(const Key('clear_popup')), findsNothing);
    expect(
      find.byKey(const Key('clear_persistence_error_popup')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('clear_persistence_retry_button')));
    await _pumpForAsyncWork(tester);

    expect(clearAttempts, 2);
    expect(rewardAttempts, 2);
    expect(
      find.byKey(const Key('clear_persistence_error_popup')),
      findsNothing,
    );
    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
  });

  testWidgets('다음 단계 요청 저장이 실패하면 클리어 팝업을 유지하고 다시 누를 수 있다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState().copyWith(
            phase: GamePhase.success,
            shotCount: 1,
          ),
          loadGameAssets: false,
          onStageRequested: (_) async {
            attempts++;
            throw StateError('다음 단계 저장 실패 주입');
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    await tester.tap(find.byKey(const Key('next_stage_button')));
    await tester.pump();

    expect(attempts, 1);
    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect(_currentGameState(tester).message, contains('다음 단계 기록을 저장하지 못했습니다'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('실제 클리어 결과가 주입된 저장소에 기록되고 다시 읽힌다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = ProgressStore(stageCount: levels.length);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _directClearState(),
          progressStore: store,
        ),
      ),
    );
    await tester.pump();

    final gesture = await _startTimedGesture(
      tester,
      _logicalOffset(tester, 56, 456),
    );
    await tester.pump(const Duration(milliseconds: 920));
    await _releaseTimedGesture(gesture, const Duration(milliseconds: 920));
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );

    final progress = await store.load();
    expect(progress.clearedLevels, contains(0));
    expect(progress.unlockedLevel, 1);
    expect(progress.bestShots[0], 1);
  });

  testWidgets('게임은 위에서 내려다보는 보기로 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.byKey(const Key('aim_area')), findsOneWidget);
  });

  testWidgets('주요 UI가 휴대폰과 태블릿 크기에서 표시된다', (tester) async {
    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const PropertyShotApp());
      await tester.pump();

      expect(find.text('속성 한방'), findsOneWidget);
      expect(find.byKey(const Key('aim_area')), findsOneWidget);
      expect(find.byKey(const Key('aim_area')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('좁은 화면은 보드 우선 축약 레이아웃을 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final board = tester.getRect(find.byKey(const Key('aim_area')));
    expect(board.width, greaterThanOrEqualTo(240));
    expect(find.byKey(const Key('compact_hud')), findsOneWidget);
    expect(find.byKey(const Key('compact_control_panel')), findsOneWidget);
    expect(find.byKey(const Key('compact_objective')), findsOneWidget);
    final compactObjective = tester
        .getSemantics(find.byKey(const Key('compact_objective')))
        .getSemanticsData()
        .label;
    expect(compactObjective, '발견 0/3 · 무거움 → 상자 → 홀');
    expect(find.byKey(const Key('compact_message')), findsOneWidget);
    final compactMessage = tester
        .getSemantics(find.byKey(const Key('compact_message')))
        .getSemanticsData()
        .label;
    expect(compactMessage, contains('방향 조정'));
    expect(compactMessage, isNot(contains('상자를 밀어 홀로')));
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('제품 라우터의 축약 화면에도 첫 발사 순서가 표시된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start_game_button')));
    await tester.pump();

    expect(
      tester
          .getSemantics(find.byKey(const Key('compact_message')))
          .getSemanticsData()
          .label,
      contains('무거움을 옮겨 상자를 밀고'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('화면 계측기는 단계 시작과 속성 이전 이벤트를 보존한다', (tester) async {
    final telemetry = LocalPlayTelemetry();
    await tester.pumpWidget(
      PropertyShotApp(
        initialState: levels[0].createState(0, productRules: true),
        showStageSelector: false,
        telemetry: telemetry,
      ),
    );
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    expect(
      telemetry.events.map((event) => event['event_code']),
      containsAllInOrder([
        'stage_enter',
        'hint_exposed',
        'object_inspected',
        'attribute_transfer_opened',
      ]),
    );
    expect(
      telemetry.events.lastWhere(
        (event) => event['event_code'] == 'object_inspected',
      )['object_id'],
      'anvil',
    );

    await tester.tap(find.byKey(const Key('info_close_button')));
    await tester.pump();
    expect(telemetry.events.last['event_code'], 'attribute_action_cancelled');

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer_button')));
    await tester.pump();

    expect(
      telemetry.events.map((event) => event['유형']),
      containsAllInOrder(['단계 시작', '속성 이전']),
    );
    expect(
      telemetry.events.map((event) => event['event_code']),
      containsAllInOrder([
        'stage_entered',
        'property_popup_opened',
        'property_transferred',
      ]),
    );
    final transfer = telemetry.events.lastWhere(
      (event) => event['event_code'] == 'attribute_transferred',
    );
    expect(transfer['object_id'], 'anvil');
    expect(transfer['attribute_before'], '무거움');
    expect(telemetry.exportJson(), contains('무거움'));
  });

  testWidgets('좁은 화면의 정보 팝업과 닫기 버튼이 화면 안에 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    final popup = tester.getRect(find.byKey(const Key('entity_info_panel')));
    final close = tester.getRect(find.byKey(const Key('info_close_button')));
    expect(popup.left, greaterThanOrEqualTo(0));
    expect(popup.right, lessThanOrEqualTo(320));
    expect(close.left, greaterThanOrEqualTo(0));
    expect(close.right, lessThanOrEqualTo(320));
    expect(close.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('좁은 화면의 클리어 팝업과 다음 버튼이 화면 안에 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    final clearState = levels[1]
        .createState(1)
        .copyWith(phase: GamePhase.success, shotCount: 3, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    final popup = tester.getRect(find.byKey(const Key('clear_popup')));
    final next = tester.getRect(find.byKey(const Key('next_stage_button')));
    expect(popup.left, greaterThanOrEqualTo(0));
    expect(popup.right, lessThanOrEqualTo(320));
    expect(next.left, greaterThanOrEqualTo(0));
    expect(next.right, lessThanOrEqualTo(320));
    expect(next.bottom, lessThanOrEqualTo(568));
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('휴대폰 화면 크기별 팝업과 안전영역 경계를 지킨다', (tester) async {
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.reset();
    });
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);

    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
    ]) {
      await tester.binding.setSurfaceSize(size);
      final clearState = levels[1]
          .createState(1)
          .copyWith(
            phase: GamePhase.success,
            shotCount: 3,
            message: '홀 진입 성공!',
          );
      await tester.pumpWidget(
        PropertyShotApp(key: ValueKey('clear_$size'), initialState: clearState),
      );
      await tester.pump();

      final popup = tester.getRect(find.byKey(const Key('clear_popup')));
      final next = tester.getRect(find.byKey(const Key('next_stage_button')));
      _expectInsideViewport(popup, size);
      _expectInsideViewport(next, size);
      expect(find.text('클리어!'), findsOneWidget);

      await tester.pumpWidget(PropertyShotApp(key: ValueKey('normal_$size')));
      await tester.pump();
      await tester.tapAt(_logicalOffset(tester, 78, 154));
      await tester.pump();

      final info = tester.getRect(find.byKey(const Key('entity_info_panel')));
      final close = tester.getRect(find.byKey(const Key('info_close_button')));
      _expectInsideViewport(info, size);
      _expectInsideViewport(close, size);
      expect(close.bottom, lessThanOrEqualTo(info.bottom));
      expect(find.textContaining('무거움'), findsWidgets);
    }
  });

  testWidgets('휴대폰 화면 크기별 HUD와 컨트롤이 잘리지 않고 겹치지 않는다', (tester) async {
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.reset();
    });
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);

    for (final size in [
      const Size(320, 568),
      const Size(390, 844),
      const Size(768, 1024),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const PropertyShotApp());
      await tester.pump();

      final hud = tester.getRect(find.byKey(const Key('compact_hud')));
      final board = tester.getRect(find.byKey(const Key('aim_area')));
      final controls = tester.getRect(
        find.byKey(const Key('compact_control_panel')),
      );
      final rewind = tester.getRect(find.byKey(const Key('rewind_button')));
      final reset = tester.getRect(find.byKey(const Key('reset_button')));
      _expectInsideViewport(hud, size);
      _expectInsideViewport(board, size);
      _expectInsideViewport(controls, size);
      _expectInsideViewport(rewind, size);
      _expectInsideViewport(reset, size);
      expect(hud.overlaps(controls), isFalse);
      expect(rewind.overlaps(reset), isFalse);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('게임 화면에 한글 접근성 안내가 노출된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.bySemanticsLabel('공을 조준하는 게임 화면'), findsOneWidget);
    expect(find.bySemanticsLabel('1단계 선택'), findsWidgets);
  });

  testWidgets('게임판의 핵심 요소가 한국어 접근성 대상으로 노출된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.bySemanticsLabel('공, 현재 속성 없음'), findsOneWidget);
    expect(find.bySemanticsLabel('무거운 돌, 무거움 속성 보유'), findsOneWidget);
    expect(find.bySemanticsLabel('홀, 목표 홀'), findsOneWidget);
    expect(find.bySemanticsLabel('벽, 움직이지 않는 장애물'), findsWidgets);
  });

  testWidgets('휴대폰 크기별 핵심 요소의 접근성 의미가 유지된다', (tester) async {
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.view.reset();
    });
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);

    for (final size in [const Size(320, 568), const Size(390, 844)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(PropertyShotApp(key: ValueKey('a11y_$size')));
      await tester.pump();

      expect(find.bySemanticsLabel('공을 조준하는 게임 화면'), findsOneWidget);
      expect(find.bySemanticsLabel('공, 현재 속성 없음'), findsOneWidget);
      expect(find.bySemanticsLabel('무거운 돌, 무거움 속성 보유'), findsOneWidget);
      expect(find.bySemanticsLabel('홀, 목표 홀'), findsOneWidget);
      expect(find.bySemanticsLabel('벽, 움직이지 않는 장애물'), findsWidgets);
      expect(find.bySemanticsLabel('1단계 선택'), findsWidgets);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('현재 단계의 퍼즐 목표가 상단 정보 아이콘에 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final objective = tester
        .getSemantics(find.byKey(const Key('compact_objective')))
        .getSemanticsData()
        .label;
    expect(objective, contains('발견 0/3 · 무거움'));
    expect(find.byKey(const Key('hud_status_button')), findsOneWidget);
  });

  testWidgets('3단계는 스위치 경로와 점착의 고정 역할을 첫 화면에 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      PropertyShotApp(initialState: levels[2].createState(2)),
    );
    await tester.pump();

    expect(find.byKey(const Key('hud_progress_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('hud_progress_button')));
    await tester.pump();
    expect(find.text('진행 상황'), findsOneWidget);
    expect(find.byKey(const Key('level_progress')), findsOneWidget);
    expect(find.text('무거움은 스위치 · 점착은 공 고정'), findsWidgets);
  });
}

class _FailOnceBestShotProgressStore extends ProgressStore {
  _FailOnceBestShotProgressStore({required super.stageCount});

  int bestShotAttempts = 0;

  @override
  Future<void> recordBestShot(int levelIndex, int shotCount) async {
    bestShotAttempts++;
    if (bestShotAttempts == 1) {
      throw StateError('최고 기록 저장 실패 주입');
    }
    await super.recordBestShot(levelIndex, shotCount);
  }
}

class _FailOnceStageClearProgressStore extends ProgressStore {
  _FailOnceStageClearProgressStore({
    required super.stageCount,
    required super.stageIds,
  });

  int stageClearAttempts = 0;

  @override
  Future<void> recordStageClear(int levelIndex) async {
    stageClearAttempts++;
    if (stageClearAttempts == 1) {
      throw StateError('지도 저장 실패 주입');
    }
    await super.recordStageClear(levelIndex);
  }
}

class _FailOnceLoadProgressStore extends ProgressStore {
  _FailOnceLoadProgressStore({required super.stageCount});

  int loadAttempts = 0;

  @override
  Future<ProgressSnapshot> load() async {
    loadAttempts++;
    if (loadAttempts == 1) {
      throw StateError('초기 진행 기록 로드 실패 주입');
    }
    return super.load();
  }
}

class _FailOnceBonusProgressStore extends ProgressStore {
  _FailOnceBonusProgressStore({required super.stageCount});

  int bonusAttempts = 0;

  @override
  Future<void> recordBonusGoal(int levelIndex) async {
    bonusAttempts++;
    if (bonusAttempts == 1) {
      throw StateError('보너스 저장 실패 주입');
    }
    await super.recordBonusGoal(levelIndex);
  }
}

GameState _directClearState({int levelIndex = 0}) {
  return GameState(
    levelIndex: levelIndex,
    levelName: '클리어 테스트',
    ballSpawn: const Vec2(56, 456),
    entities: const [
      EntityState(
        id: 'active_ball',
        type: EntityType.ball,
        position: Vec2(56, 456),
        size: Vec2(24, 24),
        movable: true,
      ),
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(220, 456),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}

const _testPointerDownAt = Duration(seconds: 1);

GameState _currentGameState(WidgetTester tester) => tester
    .widget<GameWidget<PropertyShotGame>>(
      find.byType(GameWidget<PropertyShotGame>),
    )
    .game!
    .state;

int _currentShotCount(WidgetTester tester) =>
    _currentGameState(tester).shotCount;

Future<void> _pumpForAsyncWork(
  WidgetTester tester, {
  int frames = 20,
  Duration step = const Duration(milliseconds: 50),
}) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(step);
  }
}

GameState _practiceCheckpointBaseState() => const GameState(
  levelIndex: 0,
  levelName: '준비 상태 연습 테스트',
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
      id: 'test_wall',
      type: EntityType.wall,
      position: Vec2(180, 456),
      size: Vec2(24, 150),
    ),
    EntityState(
      id: 'hole',
      type: EntityType.hole,
      position: Vec2(300, 100),
      size: Vec2(34, 34),
      solid: false,
    ),
  ],
);

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int frames = 40,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

Future<TestGesture> _startTimedGesture(
  WidgetTester tester,
  Offset position,
) async {
  final gesture = await tester.createGesture();
  await gesture.down(position, timeStamp: _testPointerDownAt);
  return gesture;
}

Future<void> _releaseTimedGesture(TestGesture gesture, Duration heldFor) =>
    gesture.up(timeStamp: _testPointerDownAt + heldFor);

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

void _expectInsideViewport(Rect rect, Size viewport) {
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(viewport.width));
  expect(rect.bottom, lessThanOrEqualTo(viewport.height));
}
