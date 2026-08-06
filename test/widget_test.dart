import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:property_shot/ui/game_feedback.dart';
import 'package:property_shot/ui/play_telemetry.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('실제 시작 흐름은 홈·섬 지도·플레이를 연결한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();

    expect(find.text('속성 한방'), findsOneWidget);
    expect(find.text('무거움 · 탄성 · 점착'), findsNothing);
    expect(find.byKey(const Key('start_game_button')), findsOneWidget);
    expect(find.byKey(const Key('stage_select_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pump();
    expect(find.text('섬 지도'), findsOneWidget);
    expect(find.byKey(const Key('stage_tile_0')), findsOneWidget);
    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.text('풍선은 밀리고, 뾰족한 공에는 터집니다.'), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('stage_tile_0')));
    await tester.pump();
    expect(find.byKey(const Key('aim_area')), findsOneWidget);
    expect(find.byKey(const Key('home_button')), findsOneWidget);
    expect(find.byKey(const Key('level_1')), findsNothing);

    await tester.tap(find.byKey(const Key('home_button')));
    await tester.pump();
    expect(find.byKey(const Key('start_game_button')), findsOneWidget);
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

  testWidgets('클리어 진행 상태가 섬 지도에서 4단계를 연다', (tester) async {
    SharedPreferences.setMockInitialValues({'property_shot_unlocked_level': 3});
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNothing);
    await tester.tap(find.byKey(const Key('stage_tile_3')));
    await tester.pump();

    expect(find.text('4. 풍선 터뜨리기'), findsOneWidget);
  });

  testWidgets('단계별 클리어 기록이 섬 지도 해금을 복원한다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'property_shot_cleared_levels': ['0', '1', '2', '3'],
    });
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNothing);
  });

  testWidgets('기존 게임 화면 해금 기록도 섬 지도에서 호환한다', (tester) async {
    SharedPreferences.setMockInitialValues({'unlocked_level': 3});
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('stage_select_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stage_tile_3')), findsOneWidget);
    expect(find.text('앞 섬을 먼저 클리어하세요'), findsNothing);
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
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('feedback_settings_button')));
    await tester.pumpAndSettle();
    expect(find.text('소리와 진동'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sound_toggle')));
    await tester.tap(find.byKey(const Key('haptics_toggle')));
    await tester.tap(find.byKey(const Key('screen_shake_toggle')));
    await tester.tap(find.byKey(const Key('reduced_motion_toggle')));
    await tester.pump();

    expect(GameFeedback.soundEnabled, isFalse);
    expect(GameFeedback.hapticsEnabled, isFalse);
    expect(GameFeedback.screenShakeEnabled, isFalse);
    expect(GameFeedback.reducedMotionEnabled, isTrue);
    expect(find.text('닫기'), findsOneWidget);
  });

  testWidgets('복제 코어가 없으면 실제 플레이 화면에 복사 행동을 노출하지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pump();
    await tester.tap(find.byKey(const Key('start_game_button')));
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
    expect(find.textContaining('추천 경로 설명'), findsOneWidget);
    await tester.tap(find.byKey(const Key('transfer_button')));
    await tester.pump();

    expect(find.textContaining('공 속성: 무거움'), findsOneWidget);
    expect(find.textContaining('추천 경로를 준비했습니다'), findsOneWidget);
    expect(find.text('공을 길게 눌러 발사해요'), findsOneWidget);
    expect(find.text('공을 길게 눌러 힘을 모으세요'), findsOneWidget);
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
    expect(find.textContaining('복사했습니다'), findsOneWidget);
    expect(find.textContaining('복제 코어 0개 남음'), findsOneWidget);
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

    expect(find.textContaining('시도 0'), findsOneWidget);
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

    expect(find.textContaining('시도 1'), findsOneWidget);
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

    expect(find.textContaining('시도 1'), findsOneWidget);
    expect(find.textContaining('시도 2'), findsNothing);
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

    expect(find.textContaining('시도 1'), findsOneWidget);
    expect(find.textContaining('시도 2'), findsNothing);
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
    expect(find.text('다시 조준'), findsOneWidget);
    expect(find.text('되감기'), findsOneWidget);
    expect(find.text('단계 처음부터'), findsOneWidget);

    await tester.tap(find.byKey(const Key('failure_retry_button')));
    await tester.pump();
    expect(find.byKey(const Key('failure_popup')), findsNothing);
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

    expect(find.textContaining('시도 0'), findsOneWidget);
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

    expect(find.textContaining('시도 0'), findsOneWidget);
    expect(find.textContaining('발사를 취소했습니다'), findsOneWidget);
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

    expect(find.textContaining('시도 0'), findsOneWidget);
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

    expect(find.textContaining('시도 0'), findsOneWidget);
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

    expect(find.textContaining('시도 0'), findsOneWidget);
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

    expect(find.textContaining('시도 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('공을 누르면 현재 속성 설명이 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    await tester.tapAt(_logicalOffset(tester, 56, 456));
    await tester.pump();

    expect(find.byKey(const Key('ball_info_panel')), findsOneWidget);
    expect(find.text('공 속성 없음'), findsOneWidget);
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
        .copyWith(phase: GamePhase.success, shotCount: 2, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    expect(find.byKey(const Key('clear_popup')), findsOneWidget);
    expect(find.textContaining('예시 기록'), findsOneWidget);
    expect(find.byKey(const Key('clear_stars')), findsOneWidget);
    expect(find.text('파 2회 · 3/3 별'), findsOneWidget);
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
      await loader.load();
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
    expect(find.textContaining('시도 0'), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('level_1')));
    await tester.pump();

    expect(find.textContaining('1. 무거움 익히기'), findsOneWidget);
  });

  testWidgets('마지막 단계 클리어는 처음부터 다시 행동을 표시한다', (tester) async {
    final clearState = levels[3]
        .createState(3)
        .copyWith(phase: GamePhase.success, shotCount: 4, message: '홀 진입 성공!');
    await tester.pumpWidget(PropertyShotApp(initialState: clearState));
    await tester.pump();

    expect(find.text('처음부터 다시'), findsOneWidget);
    expect(find.text('다음'), findsNothing);
  });

  testWidgets('실제 발사로 홀에 들어가면 클리어 팝업이 표시된다', (tester) async {
    await tester.pumpWidget(PropertyShotApp(initialState: _directClearState()));
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
    final compactObjective = tester.widget<Text>(
      find.byKey(const Key('compact_objective')),
    );
    expect(compactObjective.data, '무거움으로 상자를 밀어 홀로 보내기');
    expect(compactObjective.maxLines, 1);
    expect(find.byKey(const Key('compact_message')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('compact_message'))).data,
      contains('방향 조정'),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('compact_message'))).data,
      isNot(contains('상자를 밀어 홀로')),
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('compact_message'))).overflow,
      isNull,
    );
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
      tester.widget<Text>(find.byKey(const Key('compact_message'))).data,
      contains('길게 누르기'),
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

  testWidgets('현재 단계의 퍼즐 목표가 첫 화면에 표시된다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();

    expect(find.text('무거움으로 상자를 밀어 홀로 보내기'), findsOneWidget);
  });

  testWidgets('3단계는 스위치 경로와 점착의 고정 역할을 첫 화면에 표시한다', (tester) async {
    await tester.pumpWidget(
      PropertyShotApp(initialState: levels[2].createState(2)),
    );
    await tester.pump();

    expect(find.byKey(const Key('level_progress')), findsOneWidget);
    expect(find.text('무거움은 스위치 · 점착은 공 고정'), findsOneWidget);
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

const _testPointerDownAt = Duration(seconds: 1);

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
