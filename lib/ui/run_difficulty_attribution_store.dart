import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../game/run/run_state.dart';
import 'game_feedback.dart';

class RunDifficultyAttribution {
  const RunDifficultyAttribution({
    required this.runId,
    required this.stageId,
    required this.patternId,
    required this.patternSeed,
    required this.difficulty,
  });

  final String runId;
  final String stageId;
  final String patternId;
  final int patternSeed;
  final PlayerDifficulty difficulty;

  bool matches(RunState state) =>
      state.runId == runId &&
      state.currentStageId == stageId &&
      state.currentPatternId == patternId &&
      state.currentPatternSeed == patternSeed;

  Map<String, Object> toJson() => {
    'runId': runId,
    'stageId': stageId,
    'patternId': patternId,
    'patternSeed': patternSeed,
    'difficulty': difficulty.name,
  };

  static RunDifficultyAttribution? fromJson(Object? value) {
    if (value is! Map ||
        value['runId'] is! String ||
        value['stageId'] is! String ||
        value['patternId'] is! String ||
        value['patternSeed'] is! int ||
        value['difficulty'] is! String) {
      return null;
    }
    final difficulty = switch (value['difficulty']) {
      'normal' => PlayerDifficulty.normal,
      'easy' => PlayerDifficulty.easy,
      _ => null,
    };
    if (difficulty == null) return null;
    return RunDifficultyAttribution(
      runId: value['runId'] as String,
      stageId: value['stageId'] as String,
      patternId: value['patternId'] as String,
      patternSeed: value['patternSeed'] as int,
      difficulty: difficulty,
    );
  }
}

/// RunState/replay schema를 바꾸지 않고 진행 중 단계의 난이도 귀속만 보존한다.
class RunDifficultyAttributionStore {
  const RunDifficultyAttributionStore(this.preferences);

  static const storageKey =
      'property_shot_pending_completion_difficulty_attribution_v1';

  final SharedPreferences preferences;
  static final Expando<_RunDifficultyAttributionOperationCoordinator>
  _coordinators = Expando<_RunDifficultyAttributionOperationCoordinator>();

  Future<bool> save(RunState state, PlayerDifficulty difficulty) =>
      _coordinator.enqueue(() async {
        final existing = _loadForUncoordinated(state);
        if (existing != null) {
          // 같은 단계 identity의 난이도는 최초 시작 시점 값으로 고정한다.
          return true;
        }
        final attribution = _fromState(state, difficulty);
        if (attribution == null) return false;
        final written = await preferences.setString(
          storageKey,
          jsonEncode(attribution.toJson()),
        );
        if (!written) return false;
        final restored = _loadForUncoordinated(state);
        return restored != null && restored.difficulty == difficulty;
      });

  /// 결과에 영향을 주는 연습 도움을 사용한 단계는 이후 설정을 다시 꺼도
  /// 경쟁 기록으로 되돌아가지 않도록 assisted(easy) 귀속으로 단조 전환한다.
  Future<bool> markAssisted(RunState state) => _coordinator.enqueue(() async {
    final existing = _loadForUncoordinated(state);
    if (existing?.difficulty == PlayerDifficulty.easy) return true;
    final attribution = _fromState(state, PlayerDifficulty.easy);
    if (attribution == null) return false;
    final written = await preferences.setString(
      storageKey,
      jsonEncode(attribution.toJson()),
    );
    if (!written) return false;
    return _loadForUncoordinated(state)?.difficulty == PlayerDifficulty.easy;
  });

  RunDifficultyAttribution? loadFor(RunState state) =>
      _loadForUncoordinated(state);

  RunDifficultyAttribution? _loadForUncoordinated(RunState state) {
    final raw = preferences.getString(storageKey);
    if (raw == null) return null;
    try {
      final attribution = RunDifficultyAttribution.fromJson(jsonDecode(raw));
      return attribution?.matches(state) == true ? attribution : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> clearFor(RunState state) => _coordinator.enqueue(() async {
    if (_loadForUncoordinated(state) != null) {
      final removed = await preferences.remove(storageKey);
      if (!removed && preferences.containsKey(storageKey)) {
        throw StateError('완료 난이도 귀속 삭제에 실패했습니다.');
      }
    }
  });

  _RunDifficultyAttributionOperationCoordinator get _coordinator =>
      _coordinators[preferences] ??=
          _RunDifficultyAttributionOperationCoordinator();

  RunDifficultyAttribution? _fromState(
    RunState state,
    PlayerDifficulty difficulty,
  ) {
    final stageId = state.currentStageId;
    final patternId = state.currentPatternId;
    final patternSeed = state.currentPatternSeed;
    if (stageId == null || patternId == null || patternSeed == null) {
      return null;
    }
    return RunDifficultyAttribution(
      runId: state.runId,
      stageId: stageId,
      patternId: patternId,
      patternSeed: patternSeed,
      difficulty: difficulty,
    );
  }
}

class _RunDifficultyAttributionOperationCoordinator {
  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await operation());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}
