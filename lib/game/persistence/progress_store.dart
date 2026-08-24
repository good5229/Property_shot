import 'package:shared_preferences/shared_preferences.dart';

void requireSuccessfulProgressWrite(bool succeeded, String key) {
  if (!succeeded) {
    throw StateError('진행 기록 저장에 실패했습니다: $key');
  }
}

enum PersonalRecordKind { gimmickMastery, noAssistClear, noIslandSupportClear }

extension PersonalRecordKindLabel on PersonalRecordKind {
  String get label => switch (this) {
    PersonalRecordKind.gimmickMastery => '기믹 완수',
    PersonalRecordKind.noAssistClear => '보정 없이',
    PersonalRecordKind.noIslandSupportClear => '시설 지원 없이',
  };
}

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.clearedLevels,
    required this.unlockedLevel,
    required this.bestShots,
    required this.bonusGoals,
    required this.copyCoreCount,
    required this.copyCoreRewarded,
    required this.copyCoreRewardedStageIds,
    required this.discoveriesByStageId,
    this.personalRecords = const {},
  });

  final Set<int> clearedLevels;
  final int unlockedLevel;
  final Map<int, int> bestShots;
  final Set<int> bonusGoals;
  final int copyCoreCount;
  final bool copyCoreRewarded;
  final Set<String> copyCoreRewardedStageIds;
  final Map<String, Set<String>> discoveriesByStageId;
  final Map<int, Set<PersonalRecordKind>> personalRecords;
}

class ProgressStore {
  ProgressStore({required this.stageCount, Iterable<String>? stageIds})
    : stageIds = List.unmodifiable(
        stageIds == null || stageIds.length != stageCount
            ? [for (var index = 0; index < stageCount; index++) 'stage_$index']
            : stageIds,
      );

  static const saveVersion = 5;
  static const clearedLevelsKey = 'property_shot_cleared_levels';
  static const clearedStageIdsKey = 'property_shot_cleared_stage_ids';
  static const unlockedLevelKey = 'property_shot_unlocked_level';
  static const legacyUnlockedLevelKey = 'unlocked_level';
  static const saveVersionKey = 'property_shot_save_version';
  static const copyCoreCountKey = 'property_shot_copy_core_count';
  static const copyCoreRewardedKey = 'property_shot_copy_core_rewarded';
  static const copyCoreRewardedStageIdsKey =
      'property_shot_copy_core_rewarded_stage_ids';
  static const discoveryRecordsKey = 'property_shot_discovery_records';
  static const personalRecordsKey = 'property_shot_personal_records_v1';
  static const _discoverySeparator = '::';

  final int stageCount;
  final List<String> stageIds;
  Future<void> _writeTail = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<ProgressSnapshot> load() {
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final snapshot = read(preferences);
      await _write(preferences, snapshot);
      return snapshot;
    });
  }

  ProgressSnapshot read(SharedPreferences preferences) {
    final clearedLevels = _readIntSet(
      _safeStringList(preferences, clearedLevelsKey),
    );
    final clearedStageIds = _readStringSet(
      _safeStringList(preferences, clearedStageIdsKey),
    );
    for (var index = 0; index < stageIds.length; index++) {
      if (clearedStageIds.contains(stageIds[index])) {
        clearedLevels.add(index);
      }
    }
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
      final best =
          _safeInt(preferences, bestShotStageKey(stageIds[index])) ??
          _safeInt(preferences, bestShotKey(index));
      if (best != null && best > 0) {
        bestShots[index] = best;
      }
      if (_safeBool(preferences, bonusGoalKey(index)) == true) {
        bonusGoals.add(index);
      }
    }
    final copyCoreRewardedStageIds = _readStringSet(
      _safeStringList(preferences, copyCoreRewardedStageIdsKey),
    );
    final discoveriesByStageId = _readDiscoveryRecords(
      _safeStringList(preferences, discoveryRecordsKey),
    );
    final personalRecords = _readPersonalRecords(
      _safeStringList(preferences, personalRecordsKey),
    );

    return ProgressSnapshot(
      clearedLevels: clearedLevels,
      unlockedLevel: unlockedLevel,
      bestShots: bestShots,
      bonusGoals: bonusGoals,
      copyCoreCount: (_safeInt(preferences, copyCoreCountKey) ?? 0).clamp(
        0,
        999,
      ),
      copyCoreRewarded:
          _safeBool(preferences, copyCoreRewardedKey) == true ||
          copyCoreRewardedStageIds.isNotEmpty,
      copyCoreRewardedStageIds: copyCoreRewardedStageIds,
      discoveriesByStageId: discoveriesByStageId,
      personalRecords: personalRecords,
    );
  }

  Future<void> recordDiscoveries(
    int levelIndex,
    Iterable<String> milestoneIds,
  ) {
    if (levelIndex < 0 || levelIndex >= stageCount) {
      return Future<void>.value();
    }
    final normalized = milestoneIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty && !id.contains(_discoverySeparator))
        .toSet();
    if (normalized.isEmpty) return Future<void>.value();
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final current = read(preferences);
      final stageId = stageIds[levelIndex];
      final merged = <String, Set<String>>{
        for (final entry in current.discoveriesByStageId.entries)
          entry.key: {...entry.value},
      };
      merged.putIfAbsent(stageId, () => <String>{}).addAll(normalized);
      await _writeVersion(preferences);
      await _setStringList(
        preferences,
        discoveryRecordsKey,
        _encodeDiscoveryRecords(merged),
      );
    });
  }

  Future<void> recordStageClear(int levelIndex) {
    if (levelIndex < 0 || levelIndex >= stageCount) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final current = read(preferences);
      final clearedLevels = {...current.clearedLevels, levelIndex};
      final unlockedLevel = _maxInt(
        current.unlockedLevel,
        _unlockedLevelFromCleared(clearedLevels),
      );
      await _writeVersion(preferences);
      await _setStringList(
        preferences,
        clearedLevelsKey,
        (clearedLevels.toList()..sort()).map((index) => '$index').toList(),
      );
      await _setStringList(
        preferences,
        clearedStageIdsKey,
        (clearedLevels.toList()..sort())
            .map((index) => stageIds[index])
            .toList(),
      );
      await _setInt(preferences, unlockedLevelKey, _clampLevel(unlockedLevel));
      await _setInt(
        preferences,
        legacyUnlockedLevelKey,
        _clampLevel(unlockedLevel),
      );
    });
  }

  Future<void> recordCopyCore(
    int count,
    bool rewarded, {
    Iterable<String>? rewardedStageIds,
  }) {
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final ids = rewardedStageIds?.where(stageIds.contains).toSet().toList()
        ?..sort();
      await _writeVersion(preferences);
      await _setInt(preferences, copyCoreCountKey, count.clamp(0, 999));
      await _setBool(
        preferences,
        copyCoreRewardedKey,
        rewarded || (ids?.isNotEmpty ?? false),
      );
      if (ids != null) {
        await _setStringList(preferences, copyCoreRewardedStageIdsKey, ids);
      }
    });
  }

  Future<void> recordBestShot(int levelIndex, int shotCount) {
    if (levelIndex < 0 || levelIndex >= stageCount || shotCount <= 0) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final current = read(preferences);
      final previous = current.bestShots[levelIndex];
      if (previous != null && previous <= shotCount) {
        await _writeVersion(preferences);
        await _setInt(
          preferences,
          bestShotStageKey(stageIds[levelIndex]),
          previous,
        );
        await _setInt(preferences, bestShotKey(levelIndex), previous);
        return;
      }
      await _writeVersion(preferences);
      await _setInt(
        preferences,
        bestShotStageKey(stageIds[levelIndex]),
        shotCount,
      );
      await _setInt(preferences, bestShotKey(levelIndex), shotCount);
    });
  }

  Future<void> recordBonusGoal(int levelIndex) {
    if (levelIndex < 0 || levelIndex >= stageCount) {
      return Future<void>.value();
    }
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      await _writeVersion(preferences);
      await _setBool(preferences, bonusGoalKey(levelIndex), true);
    });
  }

  Future<void> recordPersonalRecords(
    int levelIndex,
    Iterable<PersonalRecordKind> records,
  ) {
    if (levelIndex < 0 || levelIndex >= stageCount) {
      return Future<void>.value();
    }
    final normalized = records.toSet();
    if (normalized.isEmpty) return Future<void>.value();
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      final current = read(preferences);
      final merged = <int, Set<PersonalRecordKind>>{
        for (final entry in current.personalRecords.entries)
          entry.key: {...entry.value},
      };
      merged
          .putIfAbsent(levelIndex, () => <PersonalRecordKind>{})
          .addAll(normalized);
      await _writeVersion(preferences);
      await _setStringList(
        preferences,
        personalRecordsKey,
        _encodePersonalRecords(merged),
      );
    });
  }

  Future<void> reset() {
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      await _remove(preferences, saveVersionKey);
      await _remove(preferences, clearedLevelsKey);
      await _remove(preferences, clearedStageIdsKey);
      await _remove(preferences, unlockedLevelKey);
      await _remove(preferences, legacyUnlockedLevelKey);
      await _remove(preferences, copyCoreCountKey);
      await _remove(preferences, copyCoreRewardedKey);
      await _remove(preferences, copyCoreRewardedStageIdsKey);
      await _remove(preferences, discoveryRecordsKey);
      await _remove(preferences, personalRecordsKey);
      for (var index = 0; index < stageCount; index++) {
        await _remove(preferences, bestShotKey(index));
        await _remove(preferences, bestShotStageKey(stageIds[index]));
        await _remove(preferences, bonusGoalKey(index));
      }
    });
  }

  Future<void> unlockAll() {
    return _enqueue(() async {
      final preferences = await SharedPreferences.getInstance();
      await _writeVersion(preferences);
      await _setStringList(preferences, clearedLevelsKey, [
        for (var index = 0; index < stageCount; index++) '$index',
      ]);
      await _setStringList(preferences, clearedStageIdsKey, stageIds);
      if (stageCount > 0) {
        await _setInt(preferences, unlockedLevelKey, stageCount - 1);
        await _setInt(preferences, legacyUnlockedLevelKey, stageCount - 1);
      }
    });
  }

  String bestShotKey(int levelIndex) => 'best_shots_level_$levelIndex';

  String bestShotStageKey(String stageId) => 'best_shots_stage_$stageId';

  String bonusGoalKey(int levelIndex) => 'bonus_goal_level_$levelIndex';

  int unlockedLevelFromCleared(Set<int> clearedLevels) {
    return _unlockedLevelFromCleared(clearedLevels);
  }

  Future<void> _writeVersion(SharedPreferences preferences) =>
      _setInt(preferences, saveVersionKey, saveVersion);

  Future<void> _write(
    SharedPreferences preferences,
    ProgressSnapshot snapshot,
  ) async {
    final clearedLevels =
        snapshot.clearedLevels
            .where((index) => index >= 0 && index < stageCount)
            .toList()
          ..sort();
    await _setInt(preferences, saveVersionKey, saveVersion);
    await _setStringList(
      preferences,
      clearedLevelsKey,
      clearedLevels.map((index) => '$index').toList(),
    );
    await _setStringList(
      preferences,
      clearedStageIdsKey,
      clearedLevels.map((index) => stageIds[index]).toList(),
    );
    await _setInt(
      preferences,
      unlockedLevelKey,
      _clampLevel(snapshot.unlockedLevel),
    );
    await _setInt(
      preferences,
      legacyUnlockedLevelKey,
      _clampLevel(snapshot.unlockedLevel),
    );
    await _setInt(
      preferences,
      copyCoreCountKey,
      snapshot.copyCoreCount.clamp(0, 999),
    );
    await _setBool(preferences, copyCoreRewardedKey, snapshot.copyCoreRewarded);
    await _setStringList(
      preferences,
      copyCoreRewardedStageIdsKey,
      snapshot.copyCoreRewardedStageIds.toList()..sort(),
    );
    await _setStringList(
      preferences,
      discoveryRecordsKey,
      _encodeDiscoveryRecords(snapshot.discoveriesByStageId),
    );
    await _setStringList(
      preferences,
      personalRecordsKey,
      _encodePersonalRecords(snapshot.personalRecords),
    );
    for (var index = 0; index < stageCount; index++) {
      final best = snapshot.bestShots[index];
      if (best == null) {
        await _remove(preferences, bestShotKey(index));
        await _remove(preferences, bestShotStageKey(stageIds[index]));
      } else {
        await _setInt(preferences, bestShotStageKey(stageIds[index]), best);
        await _setInt(preferences, bestShotKey(index), best);
      }
      await _setBool(
        preferences,
        bonusGoalKey(index),
        snapshot.bonusGoals.contains(index),
      );
    }
  }

  Future<void> _setInt(
    SharedPreferences preferences,
    String key,
    int value,
  ) async {
    requireSuccessfulProgressWrite(await preferences.setInt(key, value), key);
  }

  Future<void> _setBool(
    SharedPreferences preferences,
    String key,
    bool value,
  ) async {
    requireSuccessfulProgressWrite(await preferences.setBool(key, value), key);
  }

  Future<void> _setStringList(
    SharedPreferences preferences,
    String key,
    List<String> value,
  ) async {
    requireSuccessfulProgressWrite(
      await preferences.setStringList(key, value),
      key,
    );
  }

  Future<void> _remove(SharedPreferences preferences, String key) async {
    requireSuccessfulProgressWrite(await preferences.remove(key), key);
  }

  Map<String, Set<String>> _readDiscoveryRecords(List<String>? values) {
    final records = <String, Set<String>>{};
    for (final value in values ?? const <String>[]) {
      final separator = value.indexOf(_discoverySeparator);
      if (separator <= 0 || separator >= value.length - 2) continue;
      final stageId = value.substring(0, separator);
      final milestoneId = value.substring(
        separator + _discoverySeparator.length,
      );
      if (!stageIds.contains(stageId) || milestoneId.trim().isEmpty) continue;
      records.putIfAbsent(stageId, () => <String>{}).add(milestoneId);
    }
    return Map.unmodifiable({
      for (final entry in records.entries)
        entry.key: Set<String>.unmodifiable(entry.value),
    });
  }

  List<String> _encodeDiscoveryRecords(
    Map<String, Set<String>> discoveriesByStageId,
  ) {
    final records = <String>[];
    for (final stageId in stageIds) {
      final milestoneIds =
          discoveriesByStageId[stageId]?.toList() ?? <String>[];
      milestoneIds.sort();
      for (final milestoneId in milestoneIds) {
        final normalized = milestoneId.trim();
        if (normalized.isEmpty || normalized.contains(_discoverySeparator)) {
          continue;
        }
        records.add('$stageId$_discoverySeparator$normalized');
      }
    }
    return records;
  }

  Map<int, Set<PersonalRecordKind>> _readPersonalRecords(List<String>? values) {
    final records = <int, Set<PersonalRecordKind>>{};
    for (final value in values ?? const <String>[]) {
      final separator = value.indexOf(_discoverySeparator);
      if (separator <= 0 || separator >= value.length - 2) continue;
      final stageId = value.substring(0, separator);
      final index = stageIds.indexOf(stageId);
      if (index < 0) continue;
      try {
        final kind = PersonalRecordKind.values.byName(
          value.substring(separator + _discoverySeparator.length),
        );
        records.putIfAbsent(index, () => <PersonalRecordKind>{}).add(kind);
      } on ArgumentError {
        continue;
      }
    }
    return Map.unmodifiable({
      for (final entry in records.entries)
        entry.key: Set<PersonalRecordKind>.unmodifiable(entry.value),
    });
  }

  List<String> _encodePersonalRecords(
    Map<int, Set<PersonalRecordKind>> records,
  ) {
    final encoded = <String>[];
    for (var index = 0; index < stageIds.length; index++) {
      final kinds = records[index]?.toList() ?? <PersonalRecordKind>[];
      kinds.sort((left, right) => left.index.compareTo(right.index));
      for (final kind in kinds) {
        encoded.add('${stageIds[index]}$_discoverySeparator${kind.name}');
      }
    }
    return encoded;
  }

  Set<int> _readIntSet(List<String>? values) {
    return (values ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>()
        .where((index) => index >= 0 && index < stageCount)
        .toSet();
  }

  Set<String> _readStringSet(List<String>? values) {
    return (values ?? const <String>[])
        .where((value) => stageIds.contains(value))
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
