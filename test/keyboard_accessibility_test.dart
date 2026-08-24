import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/play_telemetry.dart';

void main() {
  testWidgets('보드 포커스에서 화살표 키로 힘과 방향을 조절한다', (tester) async {
    final semantics = tester.ensureSemantics();
    final telemetry = LocalPlayTelemetry(persistLocally: false);
    var committedShots = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: levels.first.createState(0),
          levelOverride: levels.first,
          showStageSelector: false,
          loadGameAssets: false,
          telemetry: telemetry,
          onShotCommitted: (_, _) async {
            committedShots += 1;
            return true;
          },
        ),
      ),
    );
    await tester.pump();
    final board = find.bySemanticsLabel('공을 조준하는 게임 화면');
    expect(board, findsOneWidget);
    expect(tester.getSemantics(board).value, contains('힘 50퍼센트'));

    tester
        .widget<Focus>(find.byKey(const Key('aim_keyboard_focus')))
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    final focusDecoration = tester.widget<DecoratedBox>(
      find.byKey(const Key('aim_focus_indicator')),
    );
    expect(
      (focusDecoration.decoration as BoxDecoration).border,
      isNotNull,
      reason: '키보드 입력 대상인 보드에 눈에 보이는 포커스 표시가 필요하다.',
    );
    expect(
      focusDecoration.position,
      DecorationPosition.foreground,
      reason: '포커스 테두리는 불투명한 게임 캔버스 앞에 그려져야 한다.',
    );
    expect(tester.getSemantics(board).value, contains('힘 52퍼센트'));

    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(tester.getSemantics(board).value, contains('힘 52퍼센트'));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.takeException(), isNull);

    tester
        .widget<Focus>(find.byKey(const Key('aim_keyboard_focus')))
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(committedShots, 1);
    expect(
      telemetry.events.where((event) => event['event_code'] == 'shot_fired'),
      hasLength(1),
    );
    semantics.dispose();
  });

  testWidgets('Escape는 충전을 취소하고 발사하지 않는다', (tester) async {
    var committedShots = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: levels.first.createState(0),
          levelOverride: levels.first,
          showStageSelector: false,
          loadGameAssets: false,
          telemetry: LocalPlayTelemetry(persistLocally: false),
          onShotCommitted: (_, _) async {
            committedShots += 1;
            return true;
          },
        ),
      ),
    );
    await tester.pump();
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('aim_area'))),
    );
    await tester.pump(const Duration(milliseconds: 550));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await gesture.up();
    await tester.pump();
    expect(committedShots, 0);
  });

  testWidgets('결과 팝업 뒤의 보드는 포커스와 Space 입력을 받지 않는다', (tester) async {
    var committedShots = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: levels.first
              .createState(0)
              .copyWith(phase: GamePhase.success),
          levelOverride: levels.first,
          showStageSelector: false,
          loadGameAssets: false,
          telemetry: LocalPlayTelemetry(persistLocally: false),
          onShotCommitted: (_, _) async {
            committedShots += 1;
            return true;
          },
        ),
      ),
    );
    await tester.pump();
    expect(find.text('클리어!'), findsOneWidget);
    final focus = tester
        .widget<Focus>(find.byKey(const Key('aim_keyboard_focus')))
        .focusNode!;
    focus.requestFocus();
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(committedShots, 0);
  });
}
