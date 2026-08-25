import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/expedition/expedition_contract.dart';
import 'package:property_shot/game/hint/generated_hint_catalog.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/run/campaign_stage_selection.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures/stage_heavy_patterns.dart';

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
    SharedPreferences.setMockInitialValues(<String, Object>{
      'unlocked_level': 1,
    });
    GameFeedback.resetForTesting();
  });
  tearDown(GameFeedback.resetForTesting);

  test('탐사 RunState reset은 캠페인 저장을 지우거나 덮어쓰지 않는다', () async {
    final preferences = await SharedPreferences.getInstance();
    final shared = SharedPreferencesRunStateBackend(preferences);
    final campaign = _session(shared);
    final expedition = _session(
      NamespacedRunStateBackend(
        delegate: shared,
        namespace: 'property_shot_expedition:',
      ),
    );
    await campaign.selectStage('stage_heavy');
    await expedition.selectStage('stage_heavy');
    await campaign.recordShot(
      input: const ShotInput(direction: Vec2(1, 0), power: 0.4),
    );
    await expedition.recordShot(
      input: const ShotInput(direction: Vec2(0, 1), power: 0.6),
    );

    await expedition.reset();

    final restoredCampaign = _session(shared);
    final restoredExpedition = _session(
      NamespacedRunStateBackend(
        delegate: shared,
        namespace: 'property_shot_expedition:',
      ),
    );
    await restoredCampaign.loadState();
    await restoredExpedition.loadState();
    expect(restoredCampaign.currentShotInputs, hasLength(1));
    expect(restoredCampaign.currentShotInputs.single.power, 0.4);
    expect(restoredExpedition.state, isNull);
  });

  testWidgets('홈에서 다섯 가지 탐사 목표를 고르고 첫 단계를 시작할 수 있다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        fontFamilyOverride: 'GoldenNanumGothic',
      ),
    );
    await _pumpForAsyncWork(tester);

    final entry = find.byKey(const Key('expedition_entry_button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();

    expect(find.byKey(const Key('expedition_contract_screen')), findsOneWidget);
    expect(find.text('발견 탐사'), findsOneWidget);
    expect(find.text('정밀 탐사'), findsOneWidget);
    expect(find.text('연쇄 탐사'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('expedition_contract_creative')),
      findsOneWidget,
    );
    expect(find.text('창의 탐사'), findsOneWidget);
    expect(
      find.byKey(const Key('expedition_contract_restoration')),
      findsOneWidget,
    );
    expect(find.text('섬 복구 최종 탐사'), findsOneWidget);
    expect(find.textContaining('10단계를 해금하면'), findsOneWidget);

    final discovery = find.byKey(const Key('expedition_contract_discovery'));
    final scrollAnimation = Scrollable.ensureVisible(
      tester.element(discovery),
      alignment: 0.5,
      duration: const Duration(milliseconds: 150),
    );
    await tester.pumpAndSettle();
    await scrollAnimation;
    await tester.tap(discovery);
    await _pumpForAsyncWork(tester);
    expect(find.textContaining('진행 0/3 · 달성 0/3'), findsOneWidget);
    expect(find.text('지금 플레이할 수 있어요'), findsOneWidget);
    expect(find.text('앞 단계를 클리어하면 열려요'), findsNWidgets(2));
    expect(find.byKey(const Key('expedition_play_0')), findsOneWidget);
  });

  testWidgets('탐사 진행은 앱을 다시 열어도 복원되고 목표 실패도 진행을 막지 않는다', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    final store = ExpeditionContractStore(preferences);
    await store.start(
      type: ExpeditionContractType.precision,
      startIndex: 0,
      allStageIds: const ['stage_heavy', 'stage_bouncy', 'stage_chain_gate'],
    );
    await store.record(
      const ExpeditionStageOutcome(
        stageId: 'stage_heavy',
        shotCount: 4,
        parShots: 2,
        discoveryCount: 3,
        gimmickCount: 4,
        chainScore: 1400,
      ),
    );

    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        fontFamilyOverride: 'GoldenNanumGothic',
      ),
    );
    await _pumpForAsyncWork(tester);
    final entry = find.byKey(const Key('expedition_entry_button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await _pumpForAsyncWork(tester);

    expect(find.textContaining('진행 1/3 · 달성 0/3'), findsOneWidget);
    expect(find.text('클리어 완료 · 목표는 다음에 재도전 가능'), findsOneWidget);
  });

  testWidgets('캠페인 성공 샷이 있어도 새 탐사는 spawn의 0발 planning 상태로 시작한다', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final campaignSession = _session(
      SharedPreferencesRunStateBackend(preferences),
    );
    final campaignDraw = await campaignSession.selectStage(
      'stage_heavy',
      drawPolicy: CampaignStageSelectionPolicy.drawTutorialBaselineFirst,
    );
    final representative = stageHeavyRepresentatives.firstWhere(
      (fixture) =>
          fixture.patternId == campaignDraw.pattern.patternId &&
          fixture.strategyId == 'none',
    );
    final successfulInput = ShotInput(
      direction: representative.direction,
      power: representative.power,
    );
    final campaignLevel = campaignDraw.pattern.toLevelDefinition(
      stageId: campaignDraw.stageId,
      stageTitle: generatedStageCatalog.stageById(campaignDraw.stageId).title,
    );
    expect(
      const ShotResolver()
          .resolve(
            campaignLevel.createState(0, productRules: true),
            successfulInput,
          )
          .state
          .phase,
      GamePhase.success,
    );
    await campaignSession.recordShot(input: successfulInput);
    expect(campaignSession.currentShotInputs, hasLength(1));

    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        loadGameAssets: false,
        fontFamilyOverride: 'GoldenNanumGothic',
      ),
    );
    await _pumpForAsyncWork(tester);
    await tester.ensureVisible(
      find.byKey(const Key('expedition_entry_button')),
    );
    await tester.tap(find.byKey(const Key('expedition_entry_button')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('expedition_contract_discovery')));
    await _pumpForAsyncWork(tester);
    await tester.tap(find.byKey(const Key('expedition_play_0')));
    await _pumpForAsyncWork(tester);

    final screen = tester.widget<GameScreen>(find.byType(GameScreen));
    final initial = screen.initialState!;
    final hole = initial.entities.singleWhere(
      (entity) => entity.type == EntityType.hole,
    );
    expect(screen.initialShotInputs, isEmpty);
    expect(screen.initialShotResults, isEmpty);
    expect(initial.phase, GamePhase.planning);
    expect(initial.shotCount, 0);
    expect(initial.activeBall.position, initial.ballSpawn);
    expect(
      initial.activeBall.position.distanceTo(hole.position),
      greaterThan(initial.activeBall.hitRadius + hole.hitRadius),
    );

    final restoredCampaign = _session(
      SharedPreferencesRunStateBackend(preferences),
    );
    await restoredCampaign.loadState();
    expect(restoredCampaign.currentShotInputs, hasLength(1));
  });

  testWidgets('탐사 코드를 입력하면 같은 목표와 세 단계를 새로 시작한다', (tester) async {
    final source = ExpeditionContractProgress(
      id: 'source',
      type: ExpeditionContractType.chain,
      stageIds: const ['stage_heavy', 'stage_bouncy', 'stage_chain_gate'],
      completedStageIds: const {'stage_heavy'},
    );
    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        fontFamilyOverride: 'GoldenNanumGothic',
      ),
    );
    await _pumpForAsyncWork(tester);
    final entry = find.byKey(const Key('expedition_entry_button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();
    await tester.tap(find.byKey(const Key('expedition_import_button')));
    await tester.pump();

    expect(find.byKey(const Key('expedition_import_dialog')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('expedition_import_field')),
      ExpeditionShareCodec.encode(source),
    );
    await tester.tap(find.byKey(const Key('expedition_import_confirm')));
    await _pumpForAsyncWork(tester);

    expect(find.text('연쇄 탐사'), findsOneWidget);
    expect(find.textContaining('진행 0/3 · 달성 0/3'), findsOneWidget);
    final restored = await ExpeditionContractStore(
      await SharedPreferences.getInstance(),
    ).load();
    expect(restored?.stageIds, source.stageIds);
    expect(restored?.completedCount, 0);
  });

  testWidgets('탐사 선택 화면 320x568 Golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        fontFamilyOverride: 'GoldenNanumGothic',
      ),
    );
    await _pumpForAsyncWork(tester);
    final entry = find.byKey(const Key('expedition_entry_button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pump();

    await expectLater(
      find.byKey(const Key('expedition_contract_screen')),
      matchesGoldenFile('goldens/expedition_contract_select_320x568.png'),
    );
  });

  testWidgets('진행 중 탐사 화면 390x844 Golden', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final preferences = await SharedPreferences.getInstance();
    final store = ExpeditionContractStore(preferences);
    await store.start(
      type: ExpeditionContractType.chain,
      startIndex: 0,
      allStageIds: const ['stage_heavy', 'stage_bouncy', 'stage_chain_gate'],
    );
    await store.record(
      const ExpeditionStageOutcome(
        stageId: 'stage_heavy',
        shotCount: 2,
        parShots: 2,
        discoveryCount: 3,
        gimmickCount: 3,
        chainScore: 1500,
      ),
    );

    await tester.pumpWidget(
      const PropertyShotApp(
        showHome: true,
        fontFamilyOverride: 'GoldenNanumGothic',
      ),
    );
    await _pumpForAsyncWork(tester);
    final entry = find.byKey(const Key('expedition_entry_button'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await _pumpForAsyncWork(tester);

    await expectLater(
      find.byKey(const Key('expedition_contract_screen')),
      matchesGoldenFile('goldens/expedition_contract_active_390x844.png'),
    );
  });
}

StagePatternSession _session(RunStateKeyValueBackend backend) =>
    StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: backend),
      fixedRootSeed: 0x12345678,
      fixedRunId: 'expedition-isolation-fixture',
      fixedResolverVersion: 'shot-resolver-v1',
      hintVersionResolver: (stageId, patternId) => generatedHintCatalog
          .entryFor(stageId: stageId, patternId: patternId)
          .hintVersion,
    );

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
