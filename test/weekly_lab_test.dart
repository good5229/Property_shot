import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/lab/physics_lab.dart';
import 'package:property_shot/game/lab/physics_lab_creator.dart';
import 'package:property_shot/game/lab/weekly_lab.dart';
import 'package:property_shot/game/analysis/weekly_research_goal.dart';
import 'package:property_shot/ui/physics_lab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('같은 주는 같은 안전한 공유 코드를 만들고 다음 주는 변경된다', () {
    final monday = WeeklyLabChallenge.forDate(DateTime.utc(2026, 8, 10));
    final sunday = WeeklyLabChallenge.forDate(
      DateTime.utc(2026, 8, 16, 14, 59),
    );
    final next = WeeklyLabChallenge.forDate(DateTime.utc(2026, 8, 16, 15));

    expect(monday.weekKey, '2026-08-10');
    expect(sunday.weekKey, monday.weekKey);
    expect(sunday.shareCode, monday.shareCode);
    expect(next.weekKey, '2026-08-17');
    expect(next.id, isNot(monday.id));
    final decoded = PhysicsLabShareCode.decode(monday.shareCode);
    expect(decoded.baseScenarioId, monday.draft.baseScenarioId);
    expect(decoded.goalPosition, monday.draft.goalPosition);
  });

  test('주제는 표시 문구가 아니라 실제 시나리오 풀을 제한한다', () {
    final cycle = WeeklyLabChallenge.recentCycle(DateTime.utc(2026, 8, 15));
    for (final challenge in cycle) {
      final allowed = switch (challenge.cycleWeek) {
        1 => const {
          'lab_heavy_crate_v1',
          'lab_sticky_chain_v1',
          'lab_sharp_balloon_v1',
        },
        2 => const {'lab_bouncy_second_rebound_v1'},
        3 => const {'lab_switch_gate_v1'},
        4 => physicsLabScenarios.map((item) => item.id).toSet(),
        _ => const <String>{},
      };
      expect(allowed, contains(challenge.draft.baseScenarioId));
    }
  });

  test('최근 네 주는 월요일 순으로 구성되고 네 가지 주제가 순환한다', () {
    final cycle = WeeklyLabChallenge.recentCycle(DateTime.utc(2026, 8, 15));
    expect(cycle, hasLength(4));
    expect(
      cycle.map((item) => DateTime.parse(item.weekKey).weekday),
      everyElement(DateTime.monday),
    );
    expect(cycle.map((item) => item.weekKey).toSet(), hasLength(4));
    expect(cycle.map((item) => item.cycleWeek).toSet(), {1, 2, 3, 4});
    expect(cycle.every((item) => item.cycleTheme.isNotEmpty), isTrue);
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
      MaterialApp(
        home: PhysicsLabScreen(
          onBack: () {},
          loadGameAssets: false,
          weeklyResearchGoal: WeeklyResearchGoal.forWeek(
            weekKey: '2026-08-24',
            cycleWeek: 4,
            stageCount: 10,
            unlockedLevel: 9,
            discoveryCount: 30,
            personalRecords: const {},
          ),
          weeklyResearchStageName: '최종 항해',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_lab_card')), findsOneWidget);
    expect(find.textContaining('이번 주 실험 ·'), findsOneWidget);
    expect(find.byKey(const Key('weekly_lab_copy_button')), findsOneWidget);
    expect(find.byKey(const Key('weekly_research_goal_lab')), findsOneWidget);
    expect(find.textContaining('시설 지원 없이'), findsOneWidget);

    await tester.tap(find.byKey(const Key('weekly_lab_play_button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('실험실 ·'), findsWidgets);
    expect(find.byKey(const Key('aim_area')), findsOneWidget);
  });

  testWidgets('관측소 성장 전에는 4주 기록 대신 정확한 해금 조건을 알린다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await tester.pumpWidget(
      MaterialApp(
        home: PhysicsLabScreen(
          onBack: () {},
          loadGameAssets: false,
          showWeeklyHistory: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('weekly_lab_four_week_cycle')), findsNothing);
    expect(
      find.byKey(const Key('weekly_history_locked_message')),
      findsOneWidget,
    );
    expect(find.textContaining('관측소를 성장시키면'), findsOneWidget);
  });
}
