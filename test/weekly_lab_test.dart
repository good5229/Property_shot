import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/lab/physics_lab_creator.dart';
import 'package:property_shot/game/lab/weekly_lab.dart';
import 'package:property_shot/ui/physics_lab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('같은 주는 같은 안전한 공유 코드를 만들고 다음 주는 변경된다', () {
    final monday = WeeklyLabChallenge.forDate(DateTime.utc(2026, 8, 10));
    final sunday = WeeklyLabChallenge.forDate(DateTime.utc(2026, 8, 16));
    final next = WeeklyLabChallenge.forDate(DateTime.utc(2026, 8, 17));

    expect(monday.weekKey, '2026-08-10');
    expect(sunday.weekKey, monday.weekKey);
    expect(sunday.shareCode, monday.shareCode);
    expect(next.weekKey, '2026-08-17');
    expect(next.id, isNot(monday.id));
    final decoded = PhysicsLabShareCode.decode(monday.shareCode);
    expect(decoded.baseScenarioId, monday.draft.baseScenarioId);
    expect(decoded.goalPosition, monday.draft.goalPosition);
  });

  test('완료 기록은 손상값을 무시하고 최근 26주만 보존한다', () async {
    SharedPreferences.setMockInitialValues({
      WeeklyLabStore.storageKey: ['broken', '2026-01-05', '2026-01-05'],
    });
    final preferences = await SharedPreferences.getInstance();
    final store = WeeklyLabStore(preferences);
    expect(store.loadCompletedWeeks(), {'2026-01-05'});
    expect(() => store.complete('잘못된주'), throwsArgumentError);

    for (var week = 0; week < 30; week++) {
      final key = WeeklyLabChallenge.forDate(
        DateTime.utc(2026, 1, 5).add(Duration(days: week * 7)),
      ).weekKey;
      await store.complete(key);
    }
    expect(store.loadCompletedWeeks(), hasLength(26));
  });

  testWidgets('실험실은 주간 목표·공유·재도전 경로를 제공한다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(home: PhysicsLabScreen(onBack: () {}, loadGameAssets: false)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_lab_card')), findsOneWidget);
    expect(find.textContaining('이번 주 실험 ·'), findsOneWidget);
    expect(find.byKey(const Key('weekly_lab_copy_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('weekly_lab_play_button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('실험실 ·'), findsWidgets);
    expect(find.byKey(const Key('aim_area')), findsOneWidget);
  });
}
