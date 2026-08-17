import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/level_definition.dart';
import 'package:property_shot/game/hint/generated_hint_catalog.dart';
import 'package:property_shot/game/hint/pattern_hint.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/property_shot_game.dart';
import 'package:property_shot/game/run/run_hint_state.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/play_telemetry.dart';

void main() {
  final entry = generatedHintCatalog.entryFor(
    stageId: 'stage_bouncy',
    patternId: 'stage_bouncy_01',
  );
  final level = generatedStageCatalog
      .stageById(entry.stageId)
      .patternById(entry.patternId)
      .toLevelDefinition(stageId: entry.stageId, stageTitle: '탄성');

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('열쇠가 있는 패턴은 잠금 이유와 독자적 열쇠를 함께 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_app(level: level, entry: entry));
    await tester.pump();

    expect(find.byKey(const Key('pattern_hint_button')), findsOneWidget);
    expect(find.bySemanticsLabel('팁 잠김'), findsOneWidget);
    expect(find.bySemanticsLabel('힌트 열쇠'), findsOneWidget);
    final semantic = tester.getSemantics(
      find.byKey(const Key('pattern_hint_button')),
    );
    expect(semantic.getSemanticsData().hint, contains('열쇠'));
  });

  testWidgets('획득된 접근권은 L1을 열고 더 구체적인 L2로 진행한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var entitlement = _entitlement(entry, openedCount: 0);
    await tester.pumpWidget(
      _app(
        level: level,
        entry: entry,
        entitlement: entitlement,
        onOpen: ({int? requestedLevel}) async {
          entitlement = entitlement.copyWith(
            consumed: true,
            openedCount: entitlement.openedCount + 1,
            unlockedHintLevel: requestedLevel == null
                ? entitlement.unlockedHintLevel
                : requestedLevel.clamp(1, 2),
          );
          return entitlement;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('pattern_hint_button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('pattern_hint_sheet')), findsOneWidget);
    expect(find.text(entry.hints.first.text), findsOneWidget);

    final more = find.byKey(const Key('pattern_hint_more_button'));
    tester.widget<FilledButton>(more).onPressed!.call();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(entry.hints[1].text), findsOneWidget);
  });

  testWidgets('넓은 화면에서도 팁 시트는 읽기 좋은 폭으로 제한된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var entitlement = _entitlement(entry, openedCount: 0);
    await tester.pumpWidget(
      _app(
        level: level,
        entry: entry,
        entitlement: entitlement,
        onOpen: ({int? requestedLevel}) async {
          entitlement = entitlement.copyWith(consumed: true, openedCount: 1);
          return entitlement;
        },
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('pattern_hint_button')));
    await tester.pump(const Duration(milliseconds: 300));
    final sheet = tester.getSize(find.byKey(const Key('pattern_hint_sheet')));
    expect(sheet.width, lessThanOrEqualTo(480));
    expect(sheet.height, lessThan(500));
  });

  testWidgets('보상으로 복원된 접근권은 스테이지 진입 시 가용 이벤트를 한 번 기록한다', (tester) async {
    final telemetry = LocalPlayTelemetry();
    final entitlement = RunHintEntitlement(
      identity: HintIdentity(
        stageId: entry.stageId,
        patternId: entry.patternId,
        hintVersion: entry.hintVersion,
      ),
      sources: const [HintEntitlementSource.clearReward],
      acquiredAt: DateTime.utc(2026),
    );
    await tester.pumpWidget(
      _app(
        level: level,
        entry: entry,
        entitlement: entitlement,
        telemetry: telemetry,
      ),
    );
    await tester.pump();

    final available = telemetry.events.where(
      (event) => event['event_code'] == 'hint_available',
    );
    expect(available, hasLength(1));
    expect(available.single['hint_source'], 'clear_reward');
  });

  testWidgets('느린 열쇠 저장은 샷 진행을 막지 않고 성공 뒤에만 VFX와 팁을 연다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final stored = Completer<bool>();
    var collectionStarted = false;
    final testEntry = PatternHintEntry(
      stageId: entry.stageId,
      patternId: entry.patternId,
      hintVersion: entry.hintVersion,
      hints: entry.hints,
      intentTags: entry.intentTags,
      directClearPolicy: entry.directClearPolicy,
      key: const HintKeyDefinition(
        id: 'nonblocking_key',
        position: Vec2(100, 462),
        size: Vec2(28, 28),
        version: 1,
      ),
    );
    final entitlement = _entitlement(testEntry, openedCount: 0);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: level
              .createState(1, productRules: true)
              .copyWith(aimDirection: const Vec2(1, 0)),
          levelOverride: level,
          showStageSelector: false,
          loadGameAssets: false,
          patternHintEntry: testEntry,
          onHintKeyCollected: (_, _, _) {
            collectionStarted = true;
            return stored.future;
          },
          onHintEntitlementRead: () async => entitlement,
        ),
      ),
    );
    await tester.pump();

    final ball = _logicalOffset(tester, 58, 462);
    const pointerDownAt = Duration(seconds: 1);
    final gesture = await tester.createGesture();
    await gesture.down(ball, timeStamp: pointerDownAt);
    await tester.pump(const Duration(milliseconds: 560));
    await gesture.up(
      timeStamp: pointerDownAt + const Duration(milliseconds: 560),
    );
    for (var frame = 0; frame < 10 && !collectionStarted; frame++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(collectionStarted, isTrue);
    final game = tester
        .state<GameWidgetState<PropertyShotGame>>(
          find.byType(GameWidget<PropertyShotGame>),
        )
        .currentGame;
    expect(game.animationEndCursorForTest, greaterThan(0));
    expect(find.bySemanticsLabel('팁 잠김'), findsOneWidget);

    stored.complete(true);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.bySemanticsLabel('팁 보기'), findsOneWidget);
  });
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

Widget _app({
  required LevelDefinition level,
  required PatternHintEntry entry,
  RunHintEntitlement? entitlement,
  Future<RunHintEntitlement?> Function({int? requestedLevel})? onOpen,
  LocalPlayTelemetry? telemetry,
}) => MaterialApp(
  home: GameScreen(
    initialState: level.createState(1, productRules: true),
    levelOverride: level,
    showStageSelector: false,
    loadGameAssets: false,
    telemetry: telemetry,
    patternHintEntry: entry,
    initialHintEntitlement: entitlement,
    onHintOpened: onOpen,
  ),
);

RunHintEntitlement _entitlement(
  PatternHintEntry entry, {
  required int openedCount,
}) => RunHintEntitlement(
  identity: HintIdentity(
    stageId: entry.stageId,
    patternId: entry.patternId,
    hintVersion: entry.hintVersion,
  ),
  sources: const [HintEntitlementSource.stageKey],
  consumed: openedCount > 0,
  openedCount: openedCount,
  acquiredAt: DateTime.utc(2026),
);
