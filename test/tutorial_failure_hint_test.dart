import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/tutorial_failure_hint.dart';

void main() {
  test('1~4단계 인과 힌트는 기믹 순서만 말하고 방향·힘 정답을 포함하지 않는다', () {
    final hints = [
      for (var index = 0; index < 4; index++)
        tutorialCausalHintForStage(index)!,
    ];

    expect(hints[0], contains('무거움 → 상자'));
    expect(hints[1], contains('탄성 → 벽 반사'));
    expect(hints[2], contains('무거움 → 스위치 → 문'));
    expect(hints[3], contains('뾰족함 → 풍선 → 스위치'));
    for (final hint in hints) {
      expect(hint, isNot(contains('도')));
      expect(hint, isNot(contains('%')));
      expect(hint, isNot(contains('예상 도착')));
    }
    expect(tutorialCausalHintForStage(4), isNull);
  });

  test('3단계 지속 힌트는 두 번 실패한 뒤에만 열린다', () {
    expect(persistentTutorialHintFor(levelIndex: 2, failedShots: 1), isNull);
    expect(
      persistentTutorialHintFor(levelIndex: 2, failedShots: 2),
      contains('무거움 → 스위치 → 문'),
    );
    expect(persistentTutorialHintFor(levelIndex: 1, failedShots: 2), isNull);
  });

  for (var levelIndex = 0; levelIndex < 4; levelIndex++) {
    testWidgets('${levelIndex + 1}단계 실패 팝업은 인과 힌트를 보여주고 재조준 시 닫힌다', (
      tester,
    ) async {
      await _pumpStage(tester, levelIndex: levelIndex);
      await _fireDefaultShot(tester, levels[levelIndex].ballSpawn);

      final hint = tutorialCausalHintForStage(levelIndex)!;
      expect(find.byKey(const Key('failure_popup')), findsOneWidget);
      expect(find.textContaining(hint), findsOneWidget);

      await tester.tap(find.byKey(const Key('failure_retry_button')));
      await tester.pump();
      expect(find.byKey(const Key('failure_popup')), findsNothing);
      expect(find.textContaining(hint), findsNothing);
    });
  }

  testWidgets('일일 도전용 비활성화 경로는 캠페인 실패 힌트를 노출하지 않는다', (tester) async {
    await _pumpStage(tester, levelIndex: 0, showTutorialFailureHints: false);
    await _fireDefaultShot(tester, levels.first.ballSpawn);

    expect(find.byKey(const Key('failure_popup')), findsOneWidget);
    expect(find.textContaining('무거움 → 상자'), findsNothing);
  });

  testWidgets('작은 화면에서 3단계 두 실패 지속 카드는 의미 정보와 함께 들어온다', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = levels[2].createState(2).copyWith(shotCount: 2);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: state,
          levelOverride: levels[2],
          showStageSelector: false,
          loadGameAssets: false,
        ),
      ),
    );
    await tester.pump();

    final persistentHint = persistentTutorialHintFor(
      levelIndex: 2,
      failedShots: 2,
    )!;
    expect(find.byKey(const Key('persistent_tutorial_hint')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('계속 표시되는 연쇄 힌트.*무거움.*스위치.*문')),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(persistentHint), findsNothing);
    final hintText = tester.widget<Text>(find.text(persistentHint));
    expect(hintText.maxLines, 3);
    expect(hintText.overflow, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('3단계 지속 카드는 한 실패·성공 상태·비활성화에서 숨는다', (tester) async {
    Future<void> pump({required int shots, bool enabled = true}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            initialState: levels[2].createState(2).copyWith(shotCount: shots),
            levelOverride: levels[2],
            showStageSelector: false,
            showTutorialFailureHints: enabled,
            loadGameAssets: false,
          ),
        ),
      );
      await tester.pump();
    }

    await pump(shots: 1);
    expect(find.byKey(const Key('persistent_tutorial_hint')), findsNothing);

    await pump(shots: 2, enabled: false);
    expect(find.byKey(const Key('persistent_tutorial_hint')), findsNothing);
  });
}

Future<void> _pumpStage(
  WidgetTester tester, {
  required int levelIndex,
  bool showTutorialFailureHints = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: GameScreen(
        initialState: levels[levelIndex].createState(levelIndex),
        levelOverride: levels[levelIndex],
        showStageSelector: false,
        showTutorialFailureHints: showTutorialFailureHints,
        loadGameAssets: false,
      ),
    ),
  );
  await tester.pump();
}

Future<void> _fireDefaultShot(WidgetTester tester, Vec2 ballSpawn) async {
  final area = find.byKey(const Key('aim_area'));
  final rect = tester.getRect(area);
  final scale = rect.width / 360 < rect.height / 560
      ? rect.width / 360
      : rect.height / 560;
  final origin = Offset(
    rect.left + (rect.width - 360 * scale) / 2,
    rect.top + (rect.height - 560 * scale) / 2,
  );
  final gesture = await tester.createGesture();
  await gesture.down(
    origin + Offset(ballSpawn.x * scale, ballSpawn.y * scale),
    timeStamp: Duration.zero,
  );
  await tester.pump(const Duration(milliseconds: 760));
  await gesture.up(timeStamp: const Duration(milliseconds: 760));
  await tester.pump(const Duration(milliseconds: 7000));
}
