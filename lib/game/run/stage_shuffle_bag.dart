import '../domain/stage_pattern.dart';
import 'stable_seed.dart';

/// 다음 draw를 재개하는 데 필요한 순수 상태다.
class StageShuffleBagState {
  factory StageShuffleBagState({
    required String stageId,
    required int cycle,
    required int drawIndex,
    required List<String> remainingPatternIds,
    required String? lastPatternId,
  }) {
    return StageShuffleBagState._(
      stageId: stageId,
      cycle: cycle,
      drawIndex: drawIndex,
      remainingPatternIds: List.unmodifiable(remainingPatternIds),
      lastPatternId: lastPatternId,
    );
  }

  const StageShuffleBagState._({
    required this.stageId,
    required this.cycle,
    required this.drawIndex,
    required this.remainingPatternIds,
    required this.lastPatternId,
  });

  factory StageShuffleBagState.initial(String stageId) {
    if (stageId.isEmpty) {
      throw const FormatException('셔플 백 상태의 stageId가 비어 있습니다.');
    }
    return StageShuffleBagState(
      stageId: stageId,
      cycle: 0,
      drawIndex: 0,
      remainingPatternIds: const [],
      lastPatternId: null,
    );
  }

  factory StageShuffleBagState.fromJson(Map<String, dynamic> json) {
    final stageId = json['stageId'];
    final cycle = json['cycle'];
    final drawIndex = json['drawIndex'];
    final remaining = json['remainingPatternIds'];
    final lastPatternId = json['lastPatternId'];

    if (stageId is! String) {
      throw const FormatException('셔플 백 상태의 stageId가 없습니다.');
    }
    if (stageId.isEmpty) {
      throw const FormatException('셔플 백 상태의 stageId가 비어 있습니다.');
    }
    if (cycle is! int || cycle < 0) {
      throw const FormatException('셔플 백 상태의 cycle이 올바르지 않습니다.');
    }
    if (drawIndex is! int || drawIndex < 0) {
      throw const FormatException('셔플 백 상태의 drawIndex가 올바르지 않습니다.');
    }
    if (remaining is! List) {
      throw const FormatException('셔플 백 상태의 remainingPatternIds가 배열이 아닙니다.');
    }

    final remainingPatternIds = <String>[];
    final seen = <String>{};
    for (final value in remaining) {
      if (value is! String || value.isEmpty || !seen.add(value)) {
        throw const FormatException('셔플 백 상태에 비어 있거나 중복된 patternId가 있습니다.');
      }
      remainingPatternIds.add(value);
    }

    if (lastPatternId != null &&
        (lastPatternId is! String || lastPatternId.isEmpty)) {
      throw const FormatException('셔플 백 상태의 lastPatternId가 올바르지 않습니다.');
    }
    if (drawIndex == 0 && lastPatternId != null) {
      throw const FormatException('첫 draw 이전에는 lastPatternId를 저장할 수 없습니다.');
    }
    if (drawIndex == 0 && (cycle != 0 || remainingPatternIds.isNotEmpty)) {
      throw const FormatException('첫 draw 상태의 cycle 또는 남은 패턴이 올바르지 않습니다.');
    }
    if (drawIndex > 0 && lastPatternId == null) {
      throw const FormatException('draw 이후에는 lastPatternId가 필요합니다.');
    }
    if (drawIndex > 0 && cycle == 0 && remainingPatternIds.isEmpty) {
      throw const FormatException('첫 cycle을 소비한 상태의 cycle이 올바르지 않습니다.');
    }
    if (lastPatternId != null && seen.contains(lastPatternId)) {
      throw const FormatException('직전 patternId가 남은 패턴 목록에 포함되어 있습니다.');
    }

    return StageShuffleBagState(
      stageId: stageId,
      cycle: cycle,
      drawIndex: drawIndex,
      remainingPatternIds: List.unmodifiable(remainingPatternIds),
      lastPatternId: lastPatternId as String?,
    );
  }

  final String stageId;
  final int cycle;
  final int drawIndex;
  final List<String> remainingPatternIds;
  final String? lastPatternId;

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'cycle': cycle,
      'drawIndex': drawIndex,
      'remainingPatternIds': List<String>.from(remainingPatternIds),
      'lastPatternId': lastPatternId,
    };
  }
}

/// 하나의 draw와 다음 저장 상태를 함께 반환한다.
class StagePatternDraw {
  const StagePatternDraw({
    required this.stageId,
    required this.patternId,
    required this.patternSeed,
    required this.cycle,
    required this.drawIndex,
    required this.pattern,
    required this.nextState,
  });

  final String stageId;
  final String patternId;
  final int patternSeed;
  final int cycle;
  final int drawIndex;
  final StagePattern pattern;
  final StageShuffleBagState nextState;

  Map<String, dynamic> toJson() {
    return {
      'stageId': stageId,
      'patternId': patternId,
      'patternSeed': patternSeed,
      'cycle': cycle,
      'drawIndex': drawIndex,
      'nextState': nextState.toJson(),
    };
  }
}

/// 스테이지별 패턴을 한 cycle에 정확히 한 번씩 소비하는 결정론적 셔플 백이다.
class StageShuffleBag {
  StageShuffleBag._();

  static StagePatternDraw draw({
    required StageDefinition stage,
    required StageShuffleBagState state,
    required int rootSeed,
  }) {
    _validateStage(stage);
    _validateState(stage, state);

    final bagCycle = state.cycle;
    final remaining = state.remainingPatternIds.toList();
    if (remaining.isEmpty) {
      final ids = stage.patterns.map((pattern) => pattern.patternId);
      remaining.addAll(
        StableRandom(
          StableSeed.bagSeed(
            rootSeed: rootSeed,
            stageId: stage.stageId,
            cycle: bagCycle,
          ),
        ).shuffled(ids),
      );

      if (remaining.length > 1 &&
          state.lastPatternId != null &&
          remaining.first == state.lastPatternId) {
        final first = remaining.first;
        remaining[0] = remaining[1];
        remaining[1] = first;
      }
    }

    final patternId = remaining.removeAt(0);
    final pattern = stage.patternById(patternId);
    final patternSeed = StableSeed.patternSeed(
      rootSeed: rootSeed,
      stageId: stage.stageId,
      cycle: bagCycle,
      drawIndex: state.drawIndex,
      patternId: patternId,
    );
    final nextState = StageShuffleBagState(
      stageId: stage.stageId,
      cycle: remaining.isEmpty ? bagCycle + 1 : bagCycle,
      drawIndex: state.drawIndex + 1,
      remainingPatternIds: List.unmodifiable(remaining),
      lastPatternId: patternId,
    );

    return StagePatternDraw(
      stageId: stage.stageId,
      patternId: patternId,
      patternSeed: patternSeed,
      cycle: bagCycle,
      drawIndex: state.drawIndex,
      pattern: pattern,
      nextState: nextState,
    );
  }

  static void _validateStage(StageDefinition stage) {
    _requireId(stage.stageId, 'stage.stageId');
    if (stage.patterns.isEmpty) {
      throw ArgumentError.value(stage.stageId, 'stage.stageId', '패턴이 없습니다.');
    }
    final ids = <String>{};
    for (final pattern in stage.patterns) {
      _requireId(pattern.patternId, 'patternId');
      if (!ids.add(pattern.patternId)) {
        throw ArgumentError.value(
          pattern.patternId,
          'patternId',
          '스테이지 안에서 중복될 수 없습니다.',
        );
      }
    }
  }

  static void _validateState(
    StageDefinition stage,
    StageShuffleBagState state,
  ) {
    if (state.stageId != stage.stageId) {
      throw ArgumentError.value(
        state.stageId,
        'state.stageId',
        '스테이지 ID가 일치하지 않습니다.',
      );
    }
    if (state.cycle < 0 || state.drawIndex < 0) {
      throw ArgumentError('cycle과 drawIndex는 음수일 수 없습니다.');
    }
    final patternIds = stage.patterns
        .map((pattern) => pattern.patternId)
        .toSet();
    final patternCount = stage.patterns.length;
    final expectedCycle = state.drawIndex ~/ patternCount;
    final positionInCycle = state.drawIndex % patternCount;
    if (state.cycle != expectedCycle) {
      throw ArgumentError('cycle은 drawIndex를 patternCount로 나눈 몫과 같아야 합니다.');
    }
    if (positionInCycle == 0 && state.remainingPatternIds.isNotEmpty) {
      throw ArgumentError('cycle 경계의 remainingPatternIds는 비어 있어야 합니다.');
    }
    if (positionInCycle != 0 &&
        state.remainingPatternIds.length != patternCount - positionInCycle) {
      throw ArgumentError('remainingPatternIds의 수가 현재 cycle 위치와 일치하지 않습니다.');
    }
    final seen = <String>{};
    for (final patternId in state.remainingPatternIds) {
      if (!patternIds.contains(patternId) || !seen.add(patternId)) {
        throw ArgumentError.value(
          patternId,
          'state.remainingPatternIds',
          '현재 스테이지의 고유한 patternId여야 합니다.',
        );
      }
    }
    if (state.lastPatternId != null &&
        (!patternIds.contains(state.lastPatternId) ||
            seen.contains(state.lastPatternId))) {
      throw ArgumentError.value(
        state.lastPatternId,
        'state.lastPatternId',
        '현재 스테이지의 마지막 패턴이어야 하며 남은 목록에 포함될 수 없습니다.',
      );
    }
    if (state.drawIndex == 0 && state.lastPatternId != null) {
      throw ArgumentError('첫 draw 이전에는 lastPatternId가 없어야 합니다.');
    }
    if (state.drawIndex == 0 &&
        (state.cycle != 0 || state.remainingPatternIds.isNotEmpty)) {
      throw ArgumentError('첫 draw 상태의 cycle과 남은 패턴은 비어 있어야 합니다.');
    }
    if (state.drawIndex > 0 && state.lastPatternId == null) {
      throw ArgumentError('draw 이후에는 lastPatternId가 필요합니다.');
    }
    if (state.drawIndex > 0 &&
        state.cycle == 0 &&
        state.remainingPatternIds.isEmpty) {
      throw ArgumentError('첫 cycle을 소비한 상태의 cycle이 올바르지 않습니다.');
    }
  }
}

void _requireId(String value, String name) {
  if (value.isEmpty) {
    throw ArgumentError.value(value, name, '비어 있을 수 없습니다.');
  }
}
