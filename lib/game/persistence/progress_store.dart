import 'package:shared_preferences/shared_preferences.dart';

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.clearedLevels,
    required this.unlockedLevel,
    required this.bestShots,
    required this.bonusGoals,
    required this.copyCoreCount,
    required this.copyCoreRewarded,
  });

  final Set<int> clearedLevels;
  final int unlockedLevel;
  final Map<int, int> bestShots;
  final Set<int> bonusGoals;
  final int copyCoreCount;
  final bool copyCoreRewarded;
}

class ProgressStore {
  const ProgressStore({required this.stageCount});

  static const saveVersion = 1;
  static const clearedLevelsKey = 'property_shot_cleared_levels';
  static const unlockedLevelKey = 'property_shot_unlocked_level';
  static const legacyUnlockedLevelKey = 'unlocked_level';
  static const saveVersionKey = 'property_shot_save_version';
  static const copyCoreCountKey = 'property_shot_copy_core_count';
  static const copyCoreRewardedKey = 'property_shot_copy_core_rewarded';

  final int stageCount;

  Future<ProgressSnapshot> load() async {
    final preferences = await SharedPreferences.getInstance();
    final snapshot = read(preferences);
    await _write(preferences, snapshot);
    return snapshot;
  }

  ProgressSnapshot read(SharedPreferences preferences) {
    final clearedLevels = _readIntSet(
      _safeStringList(preferences, clearedLevelsKey),
    );
    final storedUnlocked = _clampLevel(
      _maxInt(
        _safeInt(preferences, unlockedLevelKey) ?? 0,
        _safeInt(preferences, legacyUnlockedLevelKey),
      ),
    );
    for (var index = 0; index < storedUnlocked; index++) {
      clearedLevels.add(index);
    }

    final unlockedLevel = _maxInt(
      storedUnlocked,
      _unlockedLevelFromCleared(clearedLevels),
    );
    final bestShots = <int, int>{};
    final bonusGoals = <int>{};
    for (var index = 0; index < stageCount; index++) {
      final best = _safeInt(preferences, bestShotKey(index));
      if (best != null && best > 0) {
        bestShots[index] = best;
      }
      if (_safeBool(preferences, bonusGoalKey(index)) == true) {
        bonusGoals.add(index);
      }
    }

    return ProgressSnapshot(
      clearedLevels: clearedLevels,
      unlockedLevel: unlockedLevel,
      bestShots: bestShots,
      bonusGoals: bonusGoals,
      copyCoreCount: (_safeInt(preferences, copyCoreCountKey) ?? 0).clamp(
        0,
        999,
      ),
      copyCoreRewarded: _safeBool(preferences, copyCoreRewardedKey) == true,
    );
  }

  Future<void> recordStageClear(int levelIndex) async {
    if (levelIndex < 0 || levelIndex >= stageCount) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final current = read(preferences);
    final clearedLevels = {...current.clearedLevels, levelIndex};
    final unlockedLevel = _maxInt(
      current.unlockedLevel,
      _unlockedLevelFromCleared(clearedLevels),
    );
    await _writeVersion(preferences);
    await preferences.setStringList(
      clearedLevelsKey,
      (clearedLevels.toList()..sort()).map((index) => '$index').toList(),
    );
    await preferences.setInt(unlockedLevelKey, _clampLevel(unlockedLevel));
    await preferences.setInt(
      legacyUnlockedLevelKey,
      _clampLevel(unlockedLevel),
    );
  }

  Future<void> recordCopyCore(int count, bool rewarded) async {
    final preferences = await SharedPreferences.getInstance();
    await _writeVersion(preferences);
    await preferences.setInt(copyCoreCountKey, count.clamp(0, 999));
    await preferences.setBool(copyCoreRewardedKey, rewarded);
  }

  Future<void> recordBestShot(int levelIndex, int shotCount) async {
    if (levelIndex < 0 || levelIndex >= stageCount || shotCount <= 0) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final current = read(preferences);
    final previous = current.bestShots[levelIndex];
    if (previous != null && previous <= shotCount) {
      await _writeVersion(preferences);
      return;
    }
    await _writeVersion(preferences);
    await preferences.setInt(bestShotKey(levelIndex), shotCount);
  }

  Future<void> recordBonusGoal(int levelIndex) async {
    if (levelIndex < 0 || levelIndex >= stageCount) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await _writeVersion(preferences);
    await preferences.setBool(bonusGoalKey(levelIndex), true);
  }

  Future<void> reset() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(saveVersionKey);
    await preferences.remove(clearedLevelsKey);
    await preferences.remove(unlockedLevelKey);
    await preferences.remove(legacyUnlockedLevelKey);
    await preferences.remove(copyCoreCountKey);
    await preferences.remove(copyCoreRewardedKey);
    for (var index = 0; index < stageCount; index++) {
      await preferences.remove(bestShotKey(index));
      await preferences.remove(bonusGoalKey(index));
    }
  }

  Future<void> unlockAll() async {
    final preferences = await SharedPreferences.getInstance();
    await _writeVersion(preferences);
    await preferences.setStringList(clearedLevelsKey, [
      for (var index = 0; index < stageCount; index++) '$index',
    ]);
    if (stageCount > 0) {
      await preferences.setInt(unlockedLevelKey, stageCount - 1);
      await preferences.setInt(legacyUnlockedLevelKey, stageCount - 1);
    }
  }

  String bestShotKey(int levelIndex) => 'best_shots_level_$levelIndex';

  String bonusGoalKey(int levelIndex) => 'bonus_goal_level_$levelIndex';

  int unlockedLevelFromCleared(Set<int> clearedLevels) {
    return _unlockedLevelFromCleared(clearedLevels);
  }

  Future<void> _writeVersion(SharedPreferences preferences) {
    return preferences.setInt(saveVersionKey, saveVersion);
  }

  Future<void> _write(
    SharedPreferences preferences,
    ProgressSnapshot snapshot,
  ) async {
    final clearedLevels =
        snapshot.clearedLevels
            .where((index) => index >= 0 && index < stageCount)
            .toList()
          ..sort();
    await preferences.setInt(saveVersionKey, saveVersion);
    await preferences.setStringList(
      clearedLevelsKey,
      clearedLevels.map((index) => '$index').toList(),
    );
    await preferences.setInt(
      unlockedLevelKey,
      _clampLevel(snapshot.unlockedLevel),
    );
    await preferences.setInt(
      legacyUnlockedLevelKey,
      _clampLevel(snapshot.unlockedLevel),
    );
    await preferences.setInt(
      copyCoreCountKey,
      snapshot.copyCoreCount.clamp(0, 999),
    );
    await preferences.setBool(copyCoreRewardedKey, snapshot.copyCoreRewarded);
    for (var index = 0; index < stageCount; index++) {
      final best = snapshot.bestShots[index];
      if (best == null) {
        await preferences.remove(bestShotKey(index));
      } else {
        await preferences.setInt(bestShotKey(index), best);
      }
      await preferences.setBool(
        bonusGoalKey(index),
        snapshot.bonusGoals.contains(index),
      );
    }
  }

  Set<int> _readIntSet(List<String>? values) {
    return (values ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .where((index) => index >= 0 && index < stageCount)
        .toSet();
  }

  int? _safeInt(SharedPreferences preferences, String key) {
    try {
      return preferences.getInt(key);
    } on Object {
      return null;
    }
  }

  List<String>? _safeStringList(SharedPreferences preferences, String key) {
    try {
      return preferences.getStringList(key);
    } on Object {
      return null;
    }
  }

  bool? _safeBool(SharedPreferences preferences, String key) {
    try {
      return preferences.getBool(key);
    } on Object {
      return null;
    }
  }

  int _clampLevel(int value) {
    return value.clamp(0, stageCount == 0 ? 0 : stageCount - 1);
  }

  int _unlockedLevelFromCleared(Set<int> clearedLevels) {
    var unlockedLevel = 0;
    while (unlockedLevel < stageCount - 1 &&
        clearedLevels.contains(unlockedLevel)) {
      unlockedLevel++;
    }
    return unlockedLevel;
  }

  static int _maxInt(int left, int? right) {
    return right == null || right < left ? left : right;
  }
}
