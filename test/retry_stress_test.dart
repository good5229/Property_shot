import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('클리어 뒤 재도전을 20회 반복해도 입력 화면과 콜백이 하나씩 복구된다', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    var restartCalls = 0;

    for (var retry = 0; retry < 20; retry++) {
      final clearState = levels.first.createState(0).copyWith(
        phase: GamePhase.success,
        shotCount: retry + 1,
        message: '홀 진입 성공!',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            key: ValueKey('재도전_$retry'),
            initialState: clearState,
            showStageSelector: false,
            loadGameAssets: false,
            onStageRestarted: () async {
              restartCalls++;
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('retry_stage_button')), findsOneWidget);
      await tester.tap(find.byKey(const Key('retry_stage_button')));
      await tester.pump();

      expect(restartCalls, retry + 1);
      expect(find.byKey(const Key('clear_popup')), findsNothing);
      expect(find.byKey(const Key('aim_area')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
