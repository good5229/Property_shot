import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/expedition/expedition_contract.dart';
import 'package:property_shot/main.dart';
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

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    GameFeedback.resetForTesting();
  });
  tearDown(GameFeedback.resetForTesting);

  testWidgets('홈에서 세 가지 탐사 목표를 고르고 첫 단계를 시작할 수 있다', (tester) async {
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

    await tester.tap(find.byKey(const Key('expedition_contract_discovery')));
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

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
