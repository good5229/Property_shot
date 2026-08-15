import 'package:shared_preferences/shared_preferences.dart';

import '../run/stable_seed.dart';
import 'physics_lab.dart';
import 'physics_lab_creator.dart';

class WeeklyLabChallenge {
  const WeeklyLabChallenge({
    required this.weekKey,
    required this.draft,
    required this.scenario,
    required this.shareCode,
  });

  final String weekKey;
  final PhysicsLabDraft draft;
  final PhysicsLabScenario scenario;
  final String shareCode;

  String get id => 'weekly_lab_$weekKey';

  static WeeklyLabChallenge forDate(DateTime value) {
    final utc = value.toUtc();
    final monday = DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
    ).subtract(Duration(days: utc.weekday - DateTime.monday));
    final weekKey = [
      monday.year.toString().padLeft(4, '0'),
      monday.month.toString().padLeft(2, '0'),
      monday.day.toString().padLeft(2, '0'),
    ].join('-');
    final seed = StableSeed.hashString('property-shot-weekly-lab:$weekKey');
    final scenario = physicsLabScenarios[seed % physicsLabScenarios.length];
    final positions = LabGoalPosition.values;
    final goal =
        positions[(seed ~/ physicsLabScenarios.length) % positions.length];
    final draft = PhysicsLabDraft(
      baseScenarioId: scenario.id,
      goalPosition: goal,
    );
    final built = const PhysicsLabDraftValidator().build(draft);
    return WeeklyLabChallenge(
      weekKey: weekKey,
      draft: draft,
      scenario: built,
      shareCode: PhysicsLabShareCode.encode(draft),
    );
  }

  static List<WeeklyLabChallenge> recentCycle(DateTime value) {
    final current = forDate(value);
    final monday = DateTime.parse('${current.weekKey}T00:00:00Z');
    return List<WeeklyLabChallenge>.unmodifiable([
      for (var offset = 3; offset >= 0; offset--)
        forDate(monday.subtract(Duration(days: offset * 7))),
    ]);
  }

  int get cycleWeek {
    final monday = DateTime.parse('${weekKey}T00:00:00Z');
    final epochMonday = DateTime.utc(2026, 1, 5);
    final weeks = monday.difference(epochMonday).inDays ~/ 7;
    return (weeks % 4 + 4) % 4 + 1;
  }

  String get cycleTheme => switch (cycleWeek) {
    1 => '속성 관찰',
    2 => '반사 경로',
    3 => '인과 연결',
    4 => '자유 응용',
    _ => throw StateError('도달할 수 없는 주차입니다.'),
  };
}

class WeeklyLabStore {
  WeeklyLabStore(this.preferences);

  static const storageKey = 'property_shot_weekly_lab_completed_v1';
  static final RegExp _validWeek = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static const int _maximumRecords = 26;

  final SharedPreferences preferences;

  Set<String> loadCompletedWeeks() {
    final raw = preferences.getStringList(storageKey) ?? const <String>[];
    final sanitized = raw.where(_isValidWeekKey).toSet().toList()..sort();
    if (sanitized.length > _maximumRecords) {
      sanitized.removeRange(0, sanitized.length - _maximumRecords);
    }
    return Set.unmodifiable(sanitized);
  }

  Future<void> complete(String weekKey) async {
    if (!_isValidWeekKey(weekKey)) {
      throw ArgumentError.value(weekKey, 'weekKey', '주간 키 형식이 올바르지 않습니다.');
    }
    final completed = {...loadCompletedWeeks(), weekKey}.toList()..sort();
    if (completed.length > _maximumRecords) {
      completed.removeRange(0, completed.length - _maximumRecords);
    }
    await preferences.setStringList(storageKey, completed);
  }

  static bool _isValidWeekKey(String value) {
    if (!_validWeek.hasMatch(value)) return false;
    final parsed = DateTime.tryParse('${value}T00:00:00Z');
    return parsed != null &&
        parsed.weekday == DateTime.monday &&
        value ==
            '${parsed.year.toString().padLeft(4, '0')}-'
                '${parsed.month.toString().padLeft(2, '0')}-'
                '${parsed.day.toString().padLeft(2, '0')}';
  }
}
