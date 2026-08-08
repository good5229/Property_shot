import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/trait.dart';
import 'replay_failure.dart';

const int replayDocumentSchemaVersion = 1;
const int replayInputEncodingVersion = 1;
const String replayOutcomeFingerprintVersion = 'sha256-v1';
const int replayDocumentMaxCanonicalBytes = 16 * 1024;
const int replayMaxShots = 64;
const int replayMaxTraitActions = 128;
const int replayMaxRecoveredPastBalls = 64;
const int replayMaxRewardStateEntries = 128;
const int replayMaxDrawCounter = 1000000;
const int replayMaxInitialCloneCoreCount = 999;
const int replayMaxTokenLength = 128;

final RegExp _safeTokenPattern = RegExp(r'^[a-zA-Z0-9_.:|\-]+$');

enum ReplayMode {
  normal('normal'),
  dailyOfficial('daily_official'),
  dailyPractice('daily_practice');

  const ReplayMode(this.schemaName);

  final String schemaName;

  static ReplayMode fromSchemaName(String value) {
    for (final mode in values) {
      if (mode.schemaName == value) return mode;
    }
    throw const ReplayFailure(ReplayFailureCode.invalidMode);
  }
}

/// 방향과 힘은 고정 배율을 적용한 부호 있는 정수로 저장한다.
class ReplayFixedPoint {
  ReplayFixedPoint._();

  static const int scale = 1000000;

  static int encode(double value) {
    if (!value.isFinite || value < -1 || value > 1) {
      throw const ReplayFailure(ReplayFailureCode.invalidFixedPoint);
    }
    return (value * scale).round();
  }

  static double decode(int value) => value / scale;
}

class ReplayDirection {
  const ReplayDirection({required this.x, required this.y});

  factory ReplayDirection.fromDoubles(double x, double y) {
    return ReplayDirection(
      x: ReplayFixedPoint.encode(x),
      y: ReplayFixedPoint.encode(y),
    );
  }

  final int x;
  final int y;

  Map<String, int> toJson() => {'x': x, 'y': y};

  factory ReplayDirection.fromJson(Object? value) {
    if (value is! Map || !_hasOnlyKeys(value, const {'x', 'y'})) {
      throw const ReplayFailure(ReplayFailureCode.invalidFixedPoint);
    }
    final x = _requiredInt(value, 'x', ReplayFailureCode.invalidFixedPoint);
    final y = _requiredInt(value, 'y', ReplayFailureCode.invalidFixedPoint);
    _validateFixed(x);
    _validateFixed(y);
    if (x == 0 && y == 0) {
      throw const ReplayFailure(ReplayFailureCode.invalidFixedPoint);
    }
    return ReplayDirection(x: x, y: y);
  }

  double get xValue => ReplayFixedPoint.decode(x);
  double get yValue => ReplayFixedPoint.decode(y);
}

enum ReplayTraitActionKind {
  transfer('transfer'),
  copy('copy');

  const ReplayTraitActionKind(this.schemaName);

  final String schemaName;

  static ReplayTraitActionKind fromSchemaName(String value) {
    for (final action in values) {
      if (action.schemaName == value || action.name == value) return action;
    }
    throw const ReplayFailure(ReplayFailureCode.invalidDocument);
  }
}

class ReplayTraitAction {
  const ReplayTraitAction({required this.sourceId, required this.action});

  final String sourceId;
  final ReplayTraitActionKind action;

  Map<String, String> toJson() => {
    'sourceId': sourceId,
    'action': action.schemaName,
  };

  factory ReplayTraitAction.fromJson(Object? value) {
    if (value is! Map ||
        !_hasOnlyKeys(value, const {'sourceId', 'action'}) ||
        value['sourceId'] is! String ||
        value['action'] is! String) {
      throw const ReplayFailure(ReplayFailureCode.invalidDocument);
    }
    final sourceId = value['sourceId'] as String;
    if (!_isSafeToken(sourceId)) {
      throw const ReplayFailure(ReplayFailureCode.invalidDocument);
    }
    return ReplayTraitAction(
      sourceId: sourceId,
      action: ReplayTraitActionKind.fromSchemaName(value['action'] as String),
    );
  }
}

/// RunState의 consumeRewardUse(rewardId, useKey)에 대응하는 최소 기록이다.
class ReplayRewardUse {
  const ReplayRewardUse({required this.rewardId, required this.useKey});

  final String rewardId;
  final String useKey;

  Map<String, String> toJson() => {'rewardId': rewardId, 'useKey': useKey};

  factory ReplayRewardUse.fromJson(Object? value) {
    if (value is! Map ||
        !_hasOnlyKeys(value, const {'rewardId', 'useKey'}) ||
        value['rewardId'] is! String ||
        value['useKey'] is! String) {
      throw const ReplayFailure(ReplayFailureCode.invalidRewardState);
    }
    return ReplayRewardUse(
      rewardId: value['rewardId'] as String,
      useKey: value['useKey'] as String,
    );
  }
}

class ReplayShot {
  ReplayShot({
    required this.shotIndex,
    required this.ballId,
    required this.direction,
    required this.power,
    this.equippedTrait,
    Iterable<ReplayTraitAction> traitActions = const [],
  }) : traitActions = List.unmodifiable(traitActions) {
    if (shotIndex < 0 || shotIndex >= replayMaxShots) {
      throw const ReplayFailure(ReplayFailureCode.invalidShotSequence);
    }
    if (!_isSafeToken(ballId)) {
      throw const ReplayFailure(ReplayFailureCode.invalidBallHistory);
    }
    _validateDirection(direction);
    if (power < 0 || power > ReplayFixedPoint.scale) {
      throw const ReplayFailure(ReplayFailureCode.invalidFixedPoint);
    }
  }

  factory ReplayShot.fromJson(Object? value) {
    if (value is! Map ||
        !_hasOnlyKeys(value, const {
          'shotIndex',
          'ballId',
          'direction',
          'power',
          'equippedTrait',
          'traitActions',
        })) {
      throw const ReplayFailure(ReplayFailureCode.invalidDocument);
    }
    final trait = value['equippedTrait'];
    if (trait != null && trait is! String) {
      throw const ReplayFailure(ReplayFailureCode.invalidDocument);
    }
    final rawActions = value['traitActions'];
    if (rawActions is! List) {
      throw const ReplayFailure(ReplayFailureCode.invalidDocument);
    }
    if (rawActions.length > replayMaxTraitActions) {
      throw const ReplayFailure(ReplayFailureCode.tooManyTraitActions);
    }
    return ReplayShot(
      shotIndex: _requiredInt(
        value,
        'shotIndex',
        ReplayFailureCode.invalidShotSequence,
      ),
      ballId: _requiredString(value, 'ballId'),
      direction: ReplayDirection.fromJson(value['direction']),
      power: _requiredInt(value, 'power', ReplayFailureCode.invalidFixedPoint),
      equippedTrait: trait == null
          ? null
          : _traitFromSchemaName(trait as String),
      traitActions: rawActions.map(ReplayTraitAction.fromJson),
    );
  }

  final int shotIndex;
  final String ballId;
  final ReplayDirection direction;
  final int power;
  final TraitType? equippedTrait;
  final List<ReplayTraitAction> traitActions;

  Map<String, Object?> toJson() => {
    'shotIndex': shotIndex,
    'ballId': ballId,
    'direction': direction.toJson(),
    'power': power,
    'equippedTrait': equippedTrait == null
        ? null
        : _traitToSchemaName(equippedTrait!),
    'traitActions': traitActions.map((action) => action.toJson()).toList(),
  };

  double get powerValue => ReplayFixedPoint.decode(power);
}

/// 개인정보 없이 한 단계의 시도를 결정론적으로 기록하는 문서다.
class ReplayDocument {
  ReplayDocument({
    int schemaVersion = replayDocumentSchemaVersion,
    int inputEncodingVersion = replayInputEncodingVersion,
    this.outcomeFingerprintVersion = replayOutcomeFingerprintVersion,
    required this.mode,
    required this.dateKey,
    required this.challengeVersion,
    required this.rootSeed,
    required this.resolverVersion,
    required this.catalogFingerprint,
    required this.stageId,
    required this.patternId,
    required this.patternSeed,
    required this.drawCycle,
    required this.drawIndex,
    this.initialCloneCoreCount = 0,
    this.initialCloneCoreRewarded = false,
    Iterable<String> recoveredPastBallIds = const [],
    Iterable<String> acquiredRewardIds = const [],
    Iterable<ReplayRewardUse> consumedRewardUses = const [],
    Iterable<ReplayTraitAction> pendingTraitActions = const [],
    Iterable<ReplayShot> shots = const [],
    Iterable<String> outcomeFingerprints = const [],
  }) : schemaVersion = schemaVersion,
       inputEncodingVersion = inputEncodingVersion,
       recoveredPastBallIds = List.unmodifiable(
         _sortedValues(recoveredPastBallIds),
       ),
       acquiredRewardIds = List.unmodifiable(_sortedValues(acquiredRewardIds)),
       consumedRewardUses = List.unmodifiable(
         _sortedRewardUses(consumedRewardUses),
       ),
       pendingTraitActions = List.unmodifiable(pendingTraitActions),
       shots = List.unmodifiable(shots),
       outcomeFingerprints = List.unmodifiable(outcomeFingerprints) {
    if (schemaVersion != replayDocumentSchemaVersion) {
      throw const ReplayFailure(ReplayFailureCode.unsupportedDocumentVersion);
    }
    if (inputEncodingVersion != replayInputEncodingVersion) {
      throw const ReplayFailure(
        ReplayFailureCode.unsupportedInputEncodingVersion,
      );
    }
    if (outcomeFingerprintVersion != replayOutcomeFingerprintVersion) {
      throw const ReplayFailure(
        ReplayFailureCode.unsupportedOutcomeFingerprintVersion,
      );
    }
    _validateModeDateChallenge(mode, dateKey, challengeVersion);
    _validateSeed(rootSeed);
    _validateSeed(patternSeed);
    _validateId(resolverVersion, ReplayFailureCode.invalidReference);
    _validateId(catalogFingerprint, ReplayFailureCode.invalidReference);
    _validateId(stageId, ReplayFailureCode.invalidReference);
    _validateId(patternId, ReplayFailureCode.invalidReference);
    if (drawCycle < 0 ||
        drawCycle > replayMaxDrawCounter ||
        drawIndex < 0 ||
        drawIndex > replayMaxDrawCounter) {
      throw const ReplayFailure(ReplayFailureCode.integerOutOfRange);
    }
    if (initialCloneCoreCount < 0 ||
        initialCloneCoreCount > replayMaxInitialCloneCoreCount) {
      throw const ReplayFailure(ReplayFailureCode.integerOutOfRange);
    }
    if (this.recoveredPastBallIds.length > replayMaxRecoveredPastBalls ||
        this.recoveredPastBallIds.any((id) => !_isSafeToken(id)) ||
        this.recoveredPastBallIds.toSet().length !=
            this.recoveredPastBallIds.length) {
      throw const ReplayFailure(ReplayFailureCode.invalidBallHistory);
    }
    _validateBoundedUniqueTokens(
      this.acquiredRewardIds,
      replayMaxRewardStateEntries,
      ReplayFailureCode.invalidRewardState,
    );
    if (this.consumedRewardUses.length > replayMaxRewardStateEntries ||
        this.consumedRewardUses.any(
          (use) =>
              !_isSafeToken(use.rewardId) ||
              !_isSafeToken(use.useKey) ||
              !this.acquiredRewardIds.contains(use.rewardId),
        ) ||
        this.consumedRewardUses
                .map((use) => '${use.rewardId}\u0000${use.useKey}')
                .toSet()
                .length !=
            this.consumedRewardUses.length) {
      throw const ReplayFailure(ReplayFailureCode.invalidRewardState);
    }
    if (this.shots.length > replayMaxShots) {
      throw const ReplayFailure(ReplayFailureCode.tooManyShots);
    }
    final allActions = <ReplayTraitAction>[
      ...this.pendingTraitActions,
      for (final shot in this.shots) ...shot.traitActions,
    ];
    if (allActions.any((action) => !_isSafeToken(action.sourceId))) {
      throw const ReplayFailure(ReplayFailureCode.invalidDocument);
    }
    final ballIds = <String>{};
    for (var index = 0; index < this.shots.length; index++) {
      final shot = this.shots[index];
      if (shot.shotIndex != index) {
        throw const ReplayFailure(ReplayFailureCode.invalidShotSequence);
      }
      if (!ballIds.add(shot.ballId)) {
        throw const ReplayFailure(ReplayFailureCode.invalidBallHistory);
      }
    }
    if (!ballIds.containsAll(this.recoveredPastBallIds)) {
      throw const ReplayFailure(ReplayFailureCode.invalidBallHistory);
    }
    final actionCount = allActions.length;
    if (actionCount > replayMaxTraitActions) {
      throw const ReplayFailure(ReplayFailureCode.tooManyTraitActions);
    }
    if (outcomeFingerprints.length != this.shots.length) {
      throw const ReplayFailure(ReplayFailureCode.invalidFingerprint);
    }
    for (final fingerprint in this.outcomeFingerprints) {
      if (!_isFingerprint(fingerprint)) {
        throw const ReplayFailure(ReplayFailureCode.invalidFingerprint);
      }
    }
  }

  final int schemaVersion;
  final int inputEncodingVersion;
  final String outcomeFingerprintVersion;
  final ReplayMode mode;
  final String? dateKey;
  final String? challengeVersion;
  final int rootSeed;
  final String resolverVersion;
  final String catalogFingerprint;
  final String stageId;
  final String patternId;
  final int patternSeed;
  final int drawCycle;
  final int drawIndex;
  final int initialCloneCoreCount;
  final bool initialCloneCoreRewarded;

  /// 회수 대상을 식별할 뿐 위치·속도 같은 동적 상태는 저장하지 않는다.
  ///
  /// 재생기는 stage 초기 상태에서 [shots]를 shotIndex 순서로 결정론적으로
  /// 다시 실행해 과거 공의 동적 상태를 복원한 뒤 이 ID 목록을 적용해야 한다.
  final List<String> recoveredPastBallIds;
  final List<String> acquiredRewardIds;
  final List<ReplayRewardUse> consumedRewardUses;
  final List<ReplayTraitAction> pendingTraitActions;
  final List<ReplayShot> shots;
  final List<String> outcomeFingerprints;

  // 기존 런 용어와의 읽기 전용 별칭이며 직렬화하지 않는다.
  String? get date => dateKey;
  String? get challenge => challengeVersion;
  String get catalogVersion => catalogFingerprint;
  int get initialCoreCount => initialCloneCoreCount;
  int get recoveryBallCount => recoveredPastBallIds.length;
  bool get hasRecoveryBall => recoveredPastBallIds.isNotEmpty;
  List<String> get consumedRewardUseKeys =>
      List.unmodifiable(consumedRewardUses.map((use) => use.useKey));

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'inputEncodingVersion': inputEncodingVersion,
    'outcomeFingerprintVersion': outcomeFingerprintVersion,
    'mode': mode.schemaName,
    'dateKey': dateKey,
    'challengeVersion': challengeVersion,
    'rootSeed': rootSeed,
    'resolverVersion': resolverVersion,
    'catalogFingerprint': catalogFingerprint,
    'stageId': stageId,
    'patternId': patternId,
    'patternSeed': patternSeed,
    'drawCycle': drawCycle,
    'drawIndex': drawIndex,
    'initialCloneCoreCount': initialCloneCoreCount,
    'initialCloneCoreRewarded': initialCloneCoreRewarded,
    'recoveredPastBallIds': recoveredPastBallIds,
    'acquiredRewardIds': acquiredRewardIds,
    'consumedRewardUses': consumedRewardUses
        .map((use) => use.toJson())
        .toList(),
    'pendingTraitActions': pendingTraitActions
        .map((action) => action.toJson())
        .toList(),
    'shots': shots.map((shot) => shot.toJson()).toList(),
    'outcomeFingerprints': outcomeFingerprints,
  };

  String toCanonicalJson() {
    final value = replayCanonicalJson(toJson());
    if (utf8.encode(value).length > replayDocumentMaxCanonicalBytes) {
      throw const ReplayFailure(ReplayFailureCode.payloadTooLarge);
    }
    return value;
  }

  factory ReplayDocument.fromJson(Map<String, dynamic> json) {
    try {
      const allowed = <String>{
        'schemaVersion',
        'inputEncodingVersion',
        'outcomeFingerprintVersion',
        'mode',
        'dateKey',
        'challengeVersion',
        'rootSeed',
        'resolverVersion',
        'catalogFingerprint',
        'stageId',
        'patternId',
        'patternSeed',
        'drawCycle',
        'drawIndex',
        'initialCloneCoreCount',
        'initialCloneCoreRewarded',
        'recoveredPastBallIds',
        'acquiredRewardIds',
        'consumedRewardUses',
        'pendingTraitActions',
        'shots',
        'outcomeFingerprints',
      };
      if (json.keys.any((key) => !allowed.contains(key))) {
        throw const ReplayFailure(ReplayFailureCode.invalidDocument);
      }
      final rawShots = json['shots'];
      final rawFingerprints = json['outcomeFingerprints'];
      final rawRecoveredBallIds = json['recoveredPastBallIds'];
      final rawAcquiredRewardIds = json['acquiredRewardIds'];
      final rawConsumedRewardUses = json['consumedRewardUses'];
      final rawPendingActions = json['pendingTraitActions'];
      if (rawShots is! List ||
          rawFingerprints is! List ||
          rawRecoveredBallIds is! List ||
          rawAcquiredRewardIds is! List ||
          rawConsumedRewardUses is! List ||
          rawPendingActions is! List) {
        throw const ReplayFailure(ReplayFailureCode.invalidDocument);
      }
      if (rawShots.length > replayMaxShots ||
          rawFingerprints.length > replayMaxShots) {
        throw const ReplayFailure(ReplayFailureCode.tooManyShots);
      }
      if (rawRecoveredBallIds.length > replayMaxRecoveredPastBalls) {
        throw const ReplayFailure(ReplayFailureCode.invalidBallHistory);
      }
      if (rawAcquiredRewardIds.length > replayMaxRewardStateEntries ||
          rawConsumedRewardUses.length > replayMaxRewardStateEntries) {
        throw const ReplayFailure(ReplayFailureCode.invalidRewardState);
      }
      if (rawPendingActions.length > replayMaxTraitActions) {
        throw const ReplayFailure(ReplayFailureCode.tooManyTraitActions);
      }
      return ReplayDocument(
        schemaVersion: _requiredInt(
          json,
          'schemaVersion',
          ReplayFailureCode.invalidDocument,
        ),
        inputEncodingVersion: _requiredInt(
          json,
          'inputEncodingVersion',
          ReplayFailureCode.unsupportedInputEncodingVersion,
        ),
        outcomeFingerprintVersion: _requiredString(
          json,
          'outcomeFingerprintVersion',
        ),
        mode: ReplayMode.fromSchemaName(_requiredString(json, 'mode')),
        dateKey: _nullableString(json, 'dateKey'),
        challengeVersion: _nullableString(json, 'challengeVersion'),
        rootSeed: _requiredInt(json, 'rootSeed', ReplayFailureCode.invalidSeed),
        resolverVersion: _requiredString(json, 'resolverVersion'),
        catalogFingerprint: _requiredString(json, 'catalogFingerprint'),
        stageId: _requiredString(json, 'stageId'),
        patternId: _requiredString(json, 'patternId'),
        patternSeed: _requiredInt(
          json,
          'patternSeed',
          ReplayFailureCode.invalidSeed,
        ),
        drawCycle: _requiredInt(
          json,
          'drawCycle',
          ReplayFailureCode.invalidReference,
        ),
        drawIndex: _requiredInt(
          json,
          'drawIndex',
          ReplayFailureCode.invalidReference,
        ),
        initialCloneCoreCount: _requiredInt(
          json,
          'initialCloneCoreCount',
          ReplayFailureCode.invalidInitialState,
        ),
        initialCloneCoreRewarded: _requiredBool(
          json,
          'initialCloneCoreRewarded',
          ReplayFailureCode.invalidInitialState,
        ),
        recoveredPastBallIds: _requiredStringList(
          json,
          'recoveredPastBallIds',
          ReplayFailureCode.invalidBallHistory,
        ),
        acquiredRewardIds: _requiredStringList(
          json,
          'acquiredRewardIds',
          ReplayFailureCode.invalidRewardState,
        ),
        consumedRewardUses: rawConsumedRewardUses.map(ReplayRewardUse.fromJson),
        pendingTraitActions: rawPendingActions.map(ReplayTraitAction.fromJson),
        shots: rawShots.map(ReplayShot.fromJson),
        outcomeFingerprints: rawFingerprints.map((value) {
          if (value is! String) {
            throw const ReplayFailure(ReplayFailureCode.invalidFingerprint);
          }
          return value;
        }),
      );
    } on ReplayFailure {
      rethrow;
    } on Object catch (error) {
      throw ReplayFailure(ReplayFailureCode.invalidDocument, '$error');
    }
  }

  factory ReplayDocument.fromCanonicalJson(String value) {
    try {
      if (utf8.encode(value).length > replayDocumentMaxCanonicalBytes) {
        throw const ReplayFailure(ReplayFailureCode.payloadTooLarge);
      }
      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        throw const ReplayFailure(ReplayFailureCode.invalidDocument);
      }
      final document = ReplayDocument.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      if (document.toCanonicalJson() != value) {
        throw const ReplayFailure(ReplayFailureCode.invalidDocument);
      }
      return document;
    } on ReplayFailure {
      rethrow;
    } on Object catch (error) {
      throw ReplayFailure(ReplayFailureCode.invalidDocument, '$error');
    }
  }

  static ReplayParseResult<ReplayDocument> tryFromCanonicalJson(String value) {
    try {
      return ReplayParseResult.success(ReplayDocument.fromCanonicalJson(value));
    } on ReplayFailure catch (failure) {
      return ReplayParseResult.failure(failure);
    }
  }
}

void _validateModeDateChallenge(
  ReplayMode mode,
  String? dateKey,
  String? challengeVersion,
) {
  final isDaily = mode != ReplayMode.normal;
  if ((!isDaily && (dateKey != null || challengeVersion != null)) ||
      (isDaily && (dateKey == null || challengeVersion == null))) {
    throw const ReplayFailure(ReplayFailureCode.invalidDateChallenge);
  }
  if (dateKey != null) {
    final parsed = DateTime.tryParse('${dateKey}T00:00:00Z');
    if (!_isSafeToken(dateKey) ||
        parsed == null ||
        parsed.toUtc().toIso8601String() != '${dateKey}T00:00:00.000Z') {
      throw const ReplayFailure(ReplayFailureCode.invalidDateChallenge);
    }
  }
  if (challengeVersion != null && !_isSafeToken(challengeVersion)) {
    throw const ReplayFailure(ReplayFailureCode.invalidDateChallenge);
  }
}

void _validateSeed(int value) {
  if (value < 0 || value > 0xffffffff) {
    throw const ReplayFailure(ReplayFailureCode.invalidSeed);
  }
}

void _validateId(String value, ReplayFailureCode code) {
  if (!_isSafeToken(value)) throw ReplayFailure(code);
}

void _validateDirection(ReplayDirection direction) {
  _validateFixed(direction.x);
  _validateFixed(direction.y);
  if (direction.x == 0 && direction.y == 0) {
    throw const ReplayFailure(ReplayFailureCode.invalidFixedPoint);
  }
}

void _validateFixed(int value) {
  if (value < -ReplayFixedPoint.scale || value > ReplayFixedPoint.scale) {
    throw const ReplayFailure(ReplayFailureCode.invalidFixedPoint);
  }
}

bool _isFingerprint(String value) {
  return RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
}

bool _isSafeToken(String value) {
  return value.isNotEmpty &&
      value.length <= replayMaxTokenLength &&
      _safeTokenPattern.hasMatch(value);
}

void _validateBoundedUniqueTokens(
  List<String> values,
  int maxLength,
  ReplayFailureCode code,
) {
  if (values.length > maxLength ||
      values.toSet().length != values.length ||
      values.any((value) => !_isSafeToken(value))) {
    throw ReplayFailure(code);
  }
}

List<String> _sortedValues(Iterable<String> values) {
  final result = values.toList()..sort();
  return result;
}

List<ReplayRewardUse> _sortedRewardUses(Iterable<ReplayRewardUse> values) {
  final result = values.toList()
    ..sort((left, right) {
      final rewardOrder = left.rewardId.compareTo(right.rewardId);
      return rewardOrder != 0
          ? rewardOrder
          : left.useKey.compareTo(right.useKey);
    });
  return result;
}

bool _hasOnlyKeys(Map<Object?, Object?> value, Set<String> allowed) {
  return value.keys.every((key) => key is String && allowed.contains(key));
}

String _traitToSchemaName(TraitType trait) => switch (trait) {
  TraitType.heavy => 'heavy',
  TraitType.bouncy => 'bouncy',
  TraitType.sticky => 'sticky',
  TraitType.sharp => 'sharp',
};

TraitType _traitFromSchemaName(String value) => switch (value) {
  'heavy' => TraitType.heavy,
  'bouncy' => TraitType.bouncy,
  'sticky' => TraitType.sticky,
  'sharp' => TraitType.sharp,
  _ => throw const ReplayFailure(ReplayFailureCode.invalidDocument),
};

String replayOutcomeFingerprint(String canonicalOutcome) =>
    sha256.convert(utf8.encode(canonicalOutcome)).toString();

String _requiredString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw const ReplayFailure(ReplayFailureCode.invalidDocument);
  }
  return value;
}

String? _nullableString(Map<Object?, Object?> json, String key) {
  final value = json[key];
  if (value != null && value is! String) {
    throw const ReplayFailure(ReplayFailureCode.invalidDateChallenge);
  }
  return value as String?;
}

int _requiredInt(
  Map<Object?, Object?> json,
  String key,
  ReplayFailureCode code,
) {
  final value = json[key];
  if (value is! int) throw ReplayFailure(code);
  return value;
}

bool _requiredBool(
  Map<Object?, Object?> json,
  String key,
  ReplayFailureCode code,
) {
  final value = json[key];
  if (value is! bool) throw ReplayFailure(code);
  return value;
}

List<String> _requiredStringList(
  Map<Object?, Object?> json,
  String key,
  ReplayFailureCode code,
) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw ReplayFailure(code);
  }
  return value.cast<String>();
}

String replayCanonicalJson(Object? value) => jsonEncode(_canonicalValue(value));

Object? _canonicalValue(Object? value) {
  if (value is Map) {
    final entries = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw const ReplayFailure(ReplayFailureCode.invalidDocument);
      }
      entries[entry.key as String] = _canonicalValue(entry.value);
    }
    final keys = entries.keys.toList()..sort();
    return {for (final key in keys) key: entries[key]};
  }
  if (value is List) return value.map(_canonicalValue).toList();
  if (value is num && !value.isFinite) {
    throw const ReplayFailure(ReplayFailureCode.invalidDocument);
  }
  return value;
}
