import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/level_definition.dart';
import 'package:property_shot/game/hint/generated_hint_catalog.dart';
import 'package:property_shot/game/hint/pattern_hint.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/run/run_hint_state.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final entry = generatedHintCatalog.entryFor(
    stageId: 'stage_bouncy',
    patternId: 'stage_bouncy_01',
  );
  final level = generatedStageCatalog
      .stageById(entry.stageId)
      .patternById(entry.patternId)
      .toLevelDefinition(stageId: entry.stageId, stageTitle: '탄성');

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

  testWidgets('compact locked hint/key Golden', (tester) async {
    await _pumpGame(
      tester,
      level: level,
      entry: entry,
      size: const Size(320, 568),
    );

    expect(find.text('팁 잠김'), findsOneWidget);
    expect(find.bySemanticsLabel('힌트 열쇠'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('hint_key_golden')),
      matchesGoldenFile('goldens/hint_key_locked_320x568.png'),
    );
  });

  testWidgets('locked hint/key Golden', (tester) async {
    await _pumpGame(
      tester,
      level: level,
      entry: entry,
      size: const Size(390, 844),
    );

    expect(find.text('팁 잠김'), findsOneWidget);
    expect(find.bySemanticsLabel('힌트 열쇠'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('hint_key_golden')),
      matchesGoldenFile('goldens/hint_key_locked_390x844.png'),
    );
  });

  testWidgets('available hint Golden', (tester) async {
    await _pumpGame(
      tester,
      level: level,
      entry: entry,
      size: const Size(390, 844),
      entitlement: _entitlement(entry),
      collectedKeyIds: {entry.key!.id},
    );

    expect(find.text('팁 보기'), findsOneWidget);
    expect(find.bySemanticsLabel('힌트 열쇠'), findsNothing);
    await expectLater(
      find.byKey(const Key('hint_key_golden')),
      matchesGoldenFile('goldens/hint_key_available_390x844.png'),
    );
  });

  testWidgets('desktop available hint lantern Golden', (tester) async {
    await _pumpGame(
      tester,
      level: level,
      entry: entry,
      size: const Size(1440, 900),
      entitlement: _entitlement(entry),
      collectedKeyIds: {entry.key!.id},
    );

    final lantern = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('pattern_hint_button')),
        matching: find.byType(Image),
      ),
    );
    expect(lantern.filterQuality, FilterQuality.high);
    expect(find.text('팁 보기'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('hint_key_golden')),
      matchesGoldenFile('goldens/hint_key_available_1440x900.png'),
    );
  });

  testWidgets('hint L1/L2 sheet Golden', (tester) async {
    var entitlement = _entitlement(entry);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'GoldenNanumGothic',
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6B7A)),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: ColoredBox(
            color: const Color(0xFF385C55),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: RepaintBoundary(
                key: const Key('hint_key_sheet_golden'),
                child: buildPatternHintSheetForTesting(
                  entry: entry,
                  entitlement: entitlement,
                  onMore: (currentLevel) async {
                    entitlement = entitlement.copyWith(
                      consumed: true,
                      openedCount: entitlement.openedCount + 1,
                      unlockedHintLevel: (currentLevel + 1).clamp(
                        1,
                        entry.hints.length,
                      ),
                    );
                    return entitlement;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text(entry.hints[0].text), findsOneWidget);
    expect(find.byKey(const Key('pattern_hint_sheet')), findsOneWidget);
    await expectLater(
      find.byKey(const Key('hint_key_sheet_golden')),
      matchesGoldenFile('goldens/hint_key_sheet_l1_390x844.png'),
    );

    await tester.tap(find.byKey(const Key('pattern_hint_more_button')));
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text(entry.hints[1].text), findsOneWidget);
    expect(find.byKey(const Key('pattern_hint_sheet')), findsOneWidget);
    await expectLater(
      find.byKey(const Key('hint_key_sheet_golden')),
      matchesGoldenFile('goldens/hint_key_sheet_l2_390x844.png'),
    );
  });

  testWidgets('collected-key VFX then disappearance Golden', (tester) async {
    await _pumpGame(
      tester,
      level: level,
      entry: entry,
      size: const Size(390, 844),
      entitlement: _entitlement(entry),
      collectedKeyIds: {entry.key!.id},
      debugHintKeyVfxId: entry.key!.id,
    );

    expect(find.bySemanticsLabel('힌트 열쇠'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('hint_key_golden')),
      matchesGoldenFile('goldens/hint_key_collected_vfx_390x844.png'),
    );

    await _pumpGame(
      tester,
      level: level,
      entry: entry,
      size: const Size(390, 844),
      entitlement: _entitlement(entry),
      collectedKeyIds: {entry.key!.id},
    );
    expect(find.bySemanticsLabel('힌트 열쇠'), findsNothing);
    await expectLater(
      find.byKey(const Key('hint_key_golden')),
      matchesGoldenFile('goldens/hint_key_collected_hidden_390x844.png'),
    );
  });

  testWidgets('reduced-motion key is static Golden', (tester) async {
    GameFeedback.reducedMotionEnabled = true;
    await _pumpGame(
      tester,
      level: level,
      entry: entry,
      size: const Size(390, 844),
    );

    expect(find.bySemanticsLabel('힌트 열쇠'), findsOneWidget);
    await expectLater(
      find.byKey(const Key('hint_key_golden')),
      matchesGoldenFile('goldens/hint_key_locked_reduced_motion_390x844.png'),
    );
  });
}

Future<void> _pumpGame(
  WidgetTester tester, {
  required LevelDefinition level,
  required PatternHintEntry entry,
  required Size size,
  RunHintEntitlement? entitlement,
  Set<String> collectedKeyIds = const {},
  String? debugHintKeyVfxId,
  Future<RunHintEntitlement?> Function({int? requestedLevel})? onOpen,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          RepaintBoundary(key: const Key('hint_key_golden'), child: child!),
      theme: ThemeData(
        fontFamily: 'GoldenNanumGothic',
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6B7A)),
        useMaterial3: true,
      ),
      home: GameScreen(
        initialState: level.createState(1, productRules: true),
        levelOverride: level,
        showStageSelector: false,
        loadGameAssets: false,
        patternHintEntry: entry,
        initialHintEntitlement: entitlement,
        initialCollectedHintKeyIds: collectedKeyIds,
        onHintOpened: onOpen,
        debugHintKeyVfxId: debugHintKeyVfxId,
      ),
    ),
  );
  await tester.pump();
  final context = tester.element(find.byType(GameScreen));
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/generated/hint-lantern-v2.png'),
      context,
    );
    await precacheImage(
      const AssetImage('assets/generated/hint-key-v1.png'),
      context,
    );
  });
  final gameWidget = tester.state<GameWidgetState<PropertyShotGame>>(
    find.byType(GameWidget<PropertyShotGame>),
  );
  await gameWidget.currentGame.toBeLoaded();
  await tester.pump(const Duration(milliseconds: 300));
}

RunHintEntitlement _entitlement(PatternHintEntry entry) => RunHintEntitlement(
  identity: HintIdentity(
    stageId: entry.stageId,
    patternId: entry.patternId,
    hintVersion: entry.hintVersion,
  ),
  sources: const [HintEntitlementSource.stageKey],
  acquiredAt: DateTime.utc(2026),
);
