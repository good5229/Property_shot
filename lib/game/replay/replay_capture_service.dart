import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../analysis/replay_signature.dart';
import '../domain/game_state.dart';
import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../domain/stage_catalog.dart';
import '../domain/stage_pattern.dart';
import '../run/run_reward.dart';
import '../run/run_state.dart';
import '../simulation/shot_resolver.dart';
import '../simulation/trait_resolver.dart';
import 'replay_document.dart';
import 'replay_failure.dart';

/// 실제 런 기록과 순수 물리 리졸버 사이의 연결 계층이다.
///
/// 화면이나 Flame 객체를 참조하지 않는다. 같은 초기 패턴 상태에서 속성
/// 행동과 샷을 같은 순서로 적용해 논리 판정 자체를 캡처하고 검증한다.
class ReplayCaptureService {
  const ReplayCaptureService({
    this.resolver = const ShotResolver(),
    this.resolverVersion = 'shot-resolver-v1',
  });

  final ShotResolver resolver;
  final String resolverVersion;

  ReplayDocument capture({
    required RunState runState,
    required StageCatalog catalog,
    ReplayMode mode = ReplayMode.normal,
    String? dateKey,
    String? challengeVersion,
  }) {
    _validateRunStateReference(runState);
    _requireResolverVersion(runState.resolverVersion);
    final draw = _currentDraw(runState, catalog);
    final inputs = _currentShotInputs(runState);
    final recoveredPastBallIds = _recoveredPastBallIds(
      runState.acquiredRewards,
      draw.stageId,
    ).toList(growable: false);
    if (recoveredPastBallIds.isNotEmpty) {
      throw const ReplayFailure(ReplayFailureCode.unsupportedBetweenShotState);
    }
    final initialCloneCoreCount = _initialCloneCoreCount(runState, inputs);
    final initial = _initialGameState(
      catalog: catalog,
      draw: draw,
      initialCloneCoreCount: initialCloneCoreCount,
      initialCloneCoreRewarded: hasStageCloneCoreReward(
        runState.acquiredRewards,
        draw.stageId,
      ),
    );
    final playback = _playInputs(
      initial: initial,
      inputs: inputs,
      pendingTraitActions: runState.pendingTraitActions,
    );
    final document = ReplayDocument(
      mode: mode,
      dateKey: dateKey,
      challengeVersion: challengeVersion,
      rootSeed: runState.rootSeed,
      resolverVersion: runState.resolverVersion,
      catalogFingerprint: catalogFingerprint(catalog),
      stageId: draw.stageId,
      patternId: draw.patternId,
      patternSeed: draw.patternSeed,
      drawCycle: draw.cycle,
      drawIndex: draw.drawIndex,
      initialCloneCoreCount: initialCloneCoreCount,
      initialCloneCoreRewarded: hasStageCloneCoreReward(
        runState.acquiredRewards,
        draw.stageId,
      ),
      recoveredPastBallIds: recoveredPastBallIds,
      acquiredRewardIds: _acquiredRewardIds(runState.acquiredRewards),
      consumedRewardUses: _consumedRewardUses(runState.acquiredRewards),
      pendingTraitActions: _toReplayActions(runState.pendingTraitActions),
      shots: [
        for (var index = 0; index < inputs.length; index++)
          _toReplayShot(inputs[index], index),
      ],
      outcomeFingerprints: playback.fingerprints,
    );
    // 생성 직후 다시 재생해 캡처 결과의 지문도 검증한다.
    playbackDocument(document, catalog, service: this);
    return document;
  }

  ReplayPlaybackResult playback(
    ReplayDocument document,
    StageCatalog catalog, {
    RunState? expectedRunState,
  }) {
    if (document.resolverVersion != resolverVersion) {
      throw const ReplayFailure(ReplayFailureCode.resolverVersionMismatch);
    }
    if (document.catalogFingerprint != catalogFingerprint(catalog)) {
      throw const ReplayFailure(ReplayFailureCode.catalogFingerprintMismatch);
    }
    if (expectedRunState != null) {
      _validateExpectedRunState(document, expectedRunState, catalog);
    }
    final stage = _stageOrFailure(catalog, document.stageId);
    final pattern = _patternOrFailure(stage, document.patternId);
    if (pattern.patternId != document.patternId) {
      throw const ReplayFailure(ReplayFailureCode.patternMismatch);
    }
    final draw = PatternDrawRecord(
      stageId: document.stageId,
      patternId: document.patternId,
      patternSeed: document.patternSeed,
      cycle: document.drawCycle,
      drawIndex: document.drawIndex,
    );
    final initial = _initialGameState(
      catalog: catalog,
      draw: draw,
      initialCloneCoreCount: document.initialCloneCoreCount,
      initialCloneCoreRewarded: document.initialCloneCoreRewarded,
    );
    final result = _playInputs(
      initial: initial,
      inputs: [for (final shot in document.shots) _toRunShotInput(shot)],
      pendingTraitActions: _toRunActions(document.pendingTraitActions),
    );
    if (result.fingerprints.length != document.outcomeFingerprints.length) {
      throw const ReplayFailure(ReplayFailureCode.outcomeFingerprintMismatch);
    }
    for (var index = 0; index < result.fingerprints.length; index++) {
      if (result.fingerprints[index] != document.outcomeFingerprints[index]) {
        throw ReplayFailure(
          ReplayFailureCode.outcomeFingerprintMismatch,
          'shotIndex=$index',
        );
      }
    }
    return result;
  }

  static String catalogFingerprint(StageCatalog catalog) {
    final canonical = _canonicalJson(catalog.toJson());
    return sha256.convert(utf8.encode(canonical)).toString();
  }

  void _requireResolverVersion(String actual) {
    if (actual != resolverVersion) {
      throw const ReplayFailure(ReplayFailureCode.resolverVersionMismatch);
    }
  }

  void _validateRunStateReference(RunState state) {
    if (state.currentStageId == null ||
        state.currentPatternId == null ||
        state.currentPatternSeed == null) {
      throw const ReplayFailure(ReplayFailureCode.invalidInitialState);
    }
  }

  PatternDrawRecord _currentDraw(RunState state, StageCatalog catalog) {
    final stageId = state.currentStageId!;
    final patternId = state.currentPatternId!;
    final patternSeed = state.currentPatternSeed!;
    final stage = _stageOrFailure(catalog, stageId);
    _patternOrFailure(stage, patternId);
    final matches = state.patternDrawHistory.where(
      (draw) =>
          draw.stageId == stageId &&
          draw.patternId == patternId &&
          draw.patternSeed == patternSeed,
    );
    if (matches.length != 1) {
      throw const ReplayFailure(ReplayFailureCode.drawMismatch);
    }
    return matches.single;
  }

  List<RunShotInput> _currentShotInputs(RunState state) {
    final inputs =
        state.shotInputLog.where((input) {
            if (input.stageId != state.currentStageId ||
                input.patternId != state.currentPatternId) {
              return false;
            }
            return input.patternSeed == null ||
                input.patternSeed == state.currentPatternSeed;
          }).toList()
          ..sort((left, right) => left.shotIndex.compareTo(right.shotIndex));
    for (var index = 0; index < inputs.length; index++) {
      if (inputs[index].shotIndex != index) {
        throw const ReplayFailure(ReplayFailureCode.invalidShotSequence);
      }
    }
    return List.unmodifiable(inputs);
  }

  int _initialCloneCoreCount(RunState state, List<RunShotInput> inputs) {
    final copies = [
      ...state.pendingTraitActions,
      for (final input in inputs) ...input.traitActions,
    ].where((action) => action.action == RunTraitAction.copy).length;
    return state.cloneCoreCount + copies;
  }

  GameState _initialGameState({
    required StageCatalog catalog,
    required PatternDrawRecord draw,
    required int initialCloneCoreCount,
    required bool initialCloneCoreRewarded,
  }) {
    if (initialCloneCoreCount < 0) {
      throw const ReplayFailure(ReplayFailureCode.invalidInitialState);
    }
    final stage = _stageOrFailure(catalog, draw.stageId);
    final pattern = _patternOrFailure(stage, draw.patternId);
    final level = pattern.toLevelDefinition(
      stageId: stage.stageId,
      stageTitle: stage.title,
    );
    return level.createState(
      catalog.stages.indexOf(stage),
      productRules: true,
      copyCoreCount: initialCloneCoreCount,
      copyCoreRewarded: initialCloneCoreRewarded,
    );
  }

  ReplayPlaybackResult _playInputs({
    required GameState initial,
    required List<RunShotInput> inputs,
    required Iterable<RunTraitActionRecord> pendingTraitActions,
  }) {
    const traits = TraitResolver();
    var state = initial;
    final results = <ShotResult>[];
    final fingerprints = <String>[];
    for (final input in inputs) {
      state = _applyTraitActions(state, input.traitActions, traits);
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: input.direction,
          power: input.power,
          equippedTrait: input.equippedTrait,
          rawDirection: input.rawDirection,
          rawPower: input.rawPower,
          assistKind: input.assistKind,
          assistTargetId: input.assistTargetId,
          holeForgivenessRadius: input.holeForgivenessRadius,
        ),
      );
      results.add(result);
      fingerprints.add(replayOutcomeFingerprint(shotResultFingerprint(result)));
      state = result.state;
    }
    state = _applyTraitActions(state, pendingTraitActions, traits);
    return ReplayPlaybackResult(
      initialState: initial,
      shotResults: List.unmodifiable(results),
      finalState: state,
      fingerprints: List.unmodifiable(fingerprints),
    );
  }

  void _validateExpectedRunState(
    ReplayDocument document,
    RunState state,
    StageCatalog catalog,
  ) {
    _validateRunStateReference(state);
    _requireResolverVersion(state.resolverVersion);
    if (document.stageId != state.currentStageId) {
      throw const ReplayFailure(ReplayFailureCode.stageMismatch);
    }
    if (document.patternId != state.currentPatternId) {
      throw const ReplayFailure(ReplayFailureCode.patternMismatch);
    }
    if (document.patternSeed != state.currentPatternSeed) {
      throw const ReplayFailure(ReplayFailureCode.patternSeedMismatch);
    }
    final draw = _currentDraw(state, catalog);
    if (document.drawCycle != draw.cycle ||
        document.drawIndex != draw.drawIndex) {
      throw const ReplayFailure(ReplayFailureCode.drawMismatch);
    }
  }

  GameState _applyTraitActions(
    GameState state,
    Iterable<RunTraitActionRecord> actions,
    TraitResolver traits,
  ) {
    var next = state;
    for (final action in actions) {
      final selected = traits.selectSource(next, action.sourceId);
      next = switch (action.action) {
        RunTraitAction.transfer => traits.transferSelectedTrait(selected),
        RunTraitAction.copy => traits.copySelectedTrait(selected),
      };
    }
    return next;
  }

  ReplayShot _toReplayShot(RunShotInput input, int index) => ReplayShot(
    shotIndex: index,
    ballId: 'spent_ball_${index + 1}',
    direction: ReplayDirection.fromDoubles(
      input.direction.x,
      input.direction.y,
    ),
    power: ReplayFixedPoint.encode(input.power),
    equippedTrait: input.equippedTrait,
    rawDirection: input.rawDirection == null
        ? null
        : ReplayDirection.fromDoubles(
            input.rawDirection!.x,
            input.rawDirection!.y,
          ),
    rawPower: input.rawPower == null
        ? null
        : ReplayFixedPoint.encode(input.rawPower!),
    assistKind: input.assistKind,
    assistTargetId: input.assistTargetId,
    holeForgivenessMilli: (input.holeForgivenessRadius * 1000).round(),
    traitActions: _toReplayActions(input.traitActions),
  );

  RunShotInput _toRunShotInput(ReplayShot shot) => RunShotInput(
    stageId: 'replay_stage',
    patternId: 'replay_pattern',
    patternSeed: null,
    shotIndex: shot.shotIndex,
    direction: Vec2(shot.direction.xValue, shot.direction.yValue),
    power: shot.powerValue,
    equippedTrait: shot.equippedTrait,
    rawDirection: shot.rawDirection == null
        ? null
        : Vec2(shot.rawDirection!.xValue, shot.rawDirection!.yValue),
    rawPower: shot.rawPowerValue,
    assistKind: shot.assistKind,
    assistTargetId: shot.assistTargetId,
    holeForgivenessRadius: shot.holeForgivenessRadius,
    traitActions: _toRunActions(shot.traitActions),
  );

  List<ReplayTraitAction> _toReplayActions(
    Iterable<RunTraitActionRecord> actions,
  ) => [
    for (final action in actions)
      ReplayTraitAction(
        sourceId: action.sourceId,
        action: action.action == RunTraitAction.transfer
            ? ReplayTraitActionKind.transfer
            : ReplayTraitActionKind.copy,
      ),
  ];

  List<RunTraitActionRecord> _toRunActions(
    Iterable<ReplayTraitAction> actions,
  ) => [
    for (final action in actions)
      RunTraitActionRecord(
        sourceId: action.sourceId,
        action: action.action == ReplayTraitActionKind.transfer
            ? RunTraitAction.transfer
            : RunTraitAction.copy,
      ),
  ];

  Iterable<String> _recoveredPastBallIds(
    Iterable<String> acquiredRewards,
    String stageId,
  ) {
    final attempt = runStageAttemptNumber(acquiredRewards, stageId);
    final prefix = '$stageId|$attempt|';
    return RunRewardInventory(acquiredRewards)
        .useKeys(runRewardSpentBallRecoveryId)
        .where((key) => key.startsWith(prefix))
        .map((key) => key.substring(prefix.length));
  }

  Iterable<ReplayRewardUse> _consumedRewardUses(
    Iterable<String> acquiredRewards,
  ) sync* {
    final inventory = RunRewardInventory(acquiredRewards);
    for (final selection in inventory.selections) {
      final prefix = 'run_reward_used:${selection.recordId}:';
      for (final value in inventory.acquiredRewards) {
        if (value.startsWith(prefix)) {
          yield ReplayRewardUse(
            rewardId: selection.rewardId,
            useKey: _safeUseKey(value.substring(prefix.length)),
          );
        }
      }
    }
  }

  Iterable<String> _acquiredRewardIds(Iterable<String> acquiredRewards) sync* {
    final inventory = RunRewardInventory(acquiredRewards);
    final ids = <String>{
      for (final selection in inventory.selections) selection.rewardId,
    };
    final knownIds = defaultRunRewardCatalog.rewards
        .map((reward) => reward.id)
        .toSet();
    ids.addAll(inventory.acquiredRewards.where(knownIds.contains));
    yield* ids;
  }

  String _safeUseKey(String value) {
    if (RegExp(r'^[a-zA-Z0-9_.:|\-]{1,128}$').hasMatch(value)) {
      return value;
    }
    return 'sha256_${sha256.convert(utf8.encode(value))}';
  }

  StageDefinition _stageOrFailure(StageCatalog catalog, String stageId) {
    try {
      return catalog.stageById(stageId);
    } on Object {
      throw const ReplayFailure(ReplayFailureCode.stageMismatch);
    }
  }

  StagePattern _patternOrFailure(StageDefinition stage, String patternId) {
    try {
      return stage.patternById(patternId);
    } on Object {
      throw const ReplayFailure(ReplayFailureCode.patternMismatch);
    }
  }
}

class ReplayPlaybackResult {
  const ReplayPlaybackResult({
    required this.initialState,
    required this.shotResults,
    required this.finalState,
    required this.fingerprints,
  });

  final GameState initialState;
  final List<ShotResult> shotResults;
  final GameState finalState;
  final List<String> fingerprints;
}

ReplayPlaybackResult playbackDocument(
  ReplayDocument document,
  StageCatalog catalog, {
  ReplayCaptureService service = const ReplayCaptureService(),
}) => service.playback(document, catalog);

String _canonicalJson(Object? value) {
  Object? canonical(Object? item) {
    if (item is Map) {
      final entries = <String, Object?>{};
      for (final key in item.keys) {
        if (key is! String) throw ArgumentError('카탈로그 JSON의 key가 문자열이 아닙니다.');
        entries[key] = canonical(item[key]);
      }
      final keys = entries.keys.toList()..sort();
      return {for (final key in keys) key: entries[key]};
    }
    if (item is Iterable) return item.map(canonical).toList();
    return item;
  }

  return jsonEncode(canonical(value));
}
