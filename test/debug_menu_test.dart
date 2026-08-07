import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/debug_labels.dart';
import 'package:property_shot/ui/game_screen.dart';

void main() {
  testWidgets('개발 모드 진단 메뉴는 물리·저장 관찰 항목을 한글로 제공한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(
          initialState: null,
          showStageSelector: false,
          showDebugControls: true,
          loadGameAssets: false,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.byKey(const Key('debug_menu_button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('debug_menu_button')));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('개발 진단 메뉴'), findsOneWidget);
    expect(find.text('현재 단계 다시 시작'), findsOneWidget);
    expect(find.text('모든 단계 해금'), findsOneWidget);
    expect(find.text('히트박스 표시'), findsOneWidget);
    expect(find.text('충돌 법선 표시'), findsOneWidget);
    expect(find.text('프레임 통계 표시'), findsOneWidget);
    expect(find.text('원본 제거'), findsWidgets);
    expect(find.text('원본 복원'), findsWidgets);
    expect(find.byKey(const Key('debug_physics_metrics')), findsOneWidget);
    expect(find.text('리플레이 녹화'), findsOneWidget);
    expect(find.text('사운드 켜기'), findsOneWidget);
    expect(find.text('햅틱 켜기'), findsOneWidget);
    expect(find.text('상태 데이터 복사'), findsOneWidget);
    expect(find.text('이벤트 복사'), findsOneWidget);
    expect(find.textContaining('anvil'), findsNothing);
    expect(find.textContaining('spike_source'), findsNothing);
    expect(find.textContaining('무거운 돌'), findsWidgets);

    expect(find.byKey(const Key('debug_menu_close_button')), findsOneWidget);
  });

  test('진단용 내부 물체 ID는 한글 표시명으로 변환한다', () {
    expect(debugEntityLabel('anvil'), '무거운 돌');
    expect(debugEntityLabel('spike_source'), '뾰족함 원본');
    expect(debugEntityLabel('spent_ball_2'), '공');
    expect(debugEntityLabel('알 수 없는 ID'), '물체');
  });

  test('진단용 상태·종류·물리 사건도 한글 표시명으로 변환한다', () {
    expect(debugEntityTypeLabel('weight'), '무거운 돌');
    expect(debugEntityTypeLabel('spikeSource'), '뾰족함 원본');
    expect(debugPhaseLabel('charging'), '힘 모으기');
    expect(debugPhysicsEventLabel('impact'), '충돌');
    expect(debugPhysicsEventLabel('stateChange'), '상태 변경');
  });
}
