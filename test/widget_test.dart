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
    expect(find.textContaining('속성을 공으로 옮겼습니다'), findsOneWidget);
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
    expect(find.textContaining('다른 플레이어 기록'), findsOneWidget);

    await tester.tap(find.byKey(const Key('next_stage_button')));
    await tester.pump();

    expect(find.textContaining('3. 연쇄 문 열기'), findsOneWidget);
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

  testWidgets('보기 모드를 위와 입체로 바꿀 수 있다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.byKey(const Key('view_mode_control')), findsOneWidget);
    await tester.tap(find.text('입체'));
    await tester.pump();

    expect(find.text('입체'), findsOneWidget);
    expect(find.byKey(const Key('view_angle_slider')), findsNothing);
    expect(find.byKey(const Key('view_azimuth_slider')), findsNothing);
    expect(find.byKey(const Key('view_rotate_right')), findsNothing);
  });

  testWidgets('주요 UI가 휴대폰과 태블릿 크기에서 표시된다', (tester) async {
    for (final size in [const Size(390, 844), const Size(768, 1024)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const PropertyShotApp());
      await tester.pump();

      expect(find.text('속성 한방'), findsOneWidget);
      expect(find.byKey(const Key('aim_area')), findsOneWidget);
      expect(find.byKey(const Key('view_mode_control')), findsOneWidget);
    }
    await tester.binding.setSurfaceSize(null);
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
