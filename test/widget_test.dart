import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/main.dart';

void main() {
  testWidgets('속성을 선택해 공으로 옮길 수 있다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    await tester.tap(find.byKey(const Key('transfer_button')));
    await tester.pump();

    expect(find.textContaining('공: 무거움'), findsOneWidget);
    expect(find.textContaining('속성을 공에 담았습니다'), findsOneWidget);
  });

  testWidgets('속성을 선택해 공으로 복사할 수 있다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();
    await tester.tap(find.byKey(const Key('copy_button')));
    await tester.pump();

    expect(find.textContaining('공: 무거움'), findsOneWidget);
    expect(find.textContaining('복사했습니다'), findsOneWidget);
    expect(find.textContaining('선택:'), findsNothing);
  });

  testWidgets('드래그 조준만으로는 발사되지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final aimArea = find.byKey(const Key('aim_area'));
    await tester.drag(aimArea, const Offset(-80, 80));
    await tester.pump();

    expect(find.textContaining('샷 0'), findsOneWidget);
    expect(find.byKey(const Key('launch_button')), findsNothing);
  });

  testWidgets('공을 길게 눌러 힘 조준을 끝내면 자동 발사된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await tester.startGesture(_logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 760));
    await gesture.up();
    await tester.pump();

    expect(find.textContaining('샷 1'), findsOneWidget);
  });

  testWidgets('발사 애니메이션 중에는 두 번째 샷을 만들지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final first = await tester.startGesture(_logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 760));
    await first.up();
    await tester.pump(const Duration(milliseconds: 80));

    final second = await tester.startGesture(_logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 760));
    await second.up();
    await tester.pump(const Duration(milliseconds: 80));

    expect(find.textContaining('샷 1'), findsOneWidget);
    expect(find.textContaining('샷 2'), findsNothing);
  });

  testWidgets('일시정지 중에는 힘 조준으로 발사되지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tap(find.byKey(const Key('pause_button')));
    await tester.pump();

    final gesture = await tester.startGesture(_logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 760));
    await gesture.up();
    await tester.pump();

    expect(find.textContaining('샷 0'), findsOneWidget);
  });

  testWidgets('롱프레스가 취소되면 발사하지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    final gesture = await tester.startGesture(_logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 760));
    await gesture.cancel();
    await tester.pump();

    expect(find.textContaining('샷 0'), findsOneWidget);
    expect(find.textContaining('발사를 취소했습니다'), findsOneWidget);
  });

  testWidgets('공을 누르면 현재 속성 설명이 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 56, 456));
    await tester.pump();

    expect(find.byKey(const Key('ball_info_panel')), findsOneWidget);
    expect(find.textContaining('공 속성'), findsOneWidget);
  });

  testWidgets('물체를 누르면 물체 속성 설명이 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 78, 154));
    await tester.pump();

    expect(find.byKey(const Key('entity_info_panel')), findsOneWidget);
    expect(find.textContaining('무거움'), findsWidgets);
  });

  testWidgets('클리어 팝업의 다음 버튼은 다음 스테이지로 이동한다', (tester) async {
    final clearState = levels[1]
        .createState(1)
        .copyWith(phase: GamePhase.success, shotCount: 3, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect(find.textContaining('예시 기록'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next_stage_button')));
    await tester.pump();

    expect(find.textContaining('3. 연쇄 문 열기'), findsOneWidget);
  });

  testWidgets('기본 상태에서는 다음 단계가 잠겨 있다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.bySemanticsLabel('2단계 잠김. 1단계 클리어 후 열림'), findsOneWidget);
    await tester.tap(find.byKey(const Key('level_1')));
    await tester.pump();

    expect(find.textContaining('1. 무거움 익히기'), findsOneWidget);
  });

  testWidgets('마지막 단계 클리어는 처음부터 다시 행동을 표시한다', (tester) async {
    final clearState = levels[2]
        .createState(2)
        .copyWith(phase: GamePhase.success, shotCount: 4, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    expect(find.text('처음부터 다시'), findsOneWidget);
    expect(find.text('다음'), findsNothing);
  });

  testWidgets('실제 발사로 홀에 들어가면 클리어 팝업이 표시된다', (tester) async {
    await tester.pumpWidget(PropertyShotApp(initialState: _directClearState()));
    await tester.pump();

    final gesture = await tester.startGesture(_logicalOffset(tester, 56, 456));
    await tester.pump(const Duration(milliseconds: 920));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 2400));

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect(find.text('클리어!'), findsOneWidget);
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
    expect(find.bySemanticsLabel('벽, 상호작용 가능한 물체'), findsWidgets);
  });

  testWidgets('현재 단계의 퍼즐 목표가 첫 화면에 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.text('무거움을 옮겨 상자를 밀고 홀에 넣으세요.'), findsOneWidget);
  });
}

GameState _directClearState() {
  return const GameState(
    levelIndex: 0,
    levelName: '클리어 테스트',
    ballSpawn: Vec2(56, 456),
    entities: [
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
