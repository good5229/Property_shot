import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stage_catalog.dart';
import '../domain/stage_pattern.dart';
import '../persistence/run_state_store.dart';
import 'run_state.dart';
import 'stable_seed.dart';
import 'stage_pattern_session.dart';

/// 오늘의 도전 날짜·패턴·보상 정의를 고정하는 버전이다.
const String dailyChallengeVersion = 'daily-challenge-v2-short';

/// 실제 물리 판정에 사용하는 해석기 버전이다.
const String dailyChallengePhysicsResolverVersion = 'shot-resolver-v1';

/// 서버 없이도 모든 기기에서 같은 날짜를 해석하기 위한 고정 시차다.
const Duration koreanStandardTimeOffset = Duration(hours: 9);

enum DailyChallengeMode {
  official('official'),
  practice('practice');

  const DailyChallengeMode(this.schemaName);

  final String schemaName;
}

/// 한 번에 완주 가능한 세 장면짜리 일일 변주다.
class DailyChallengeVariant {
  const DailyChallengeVariant({
    required this.id,
    required this.title,
    required this.summary,
    required this.stageIds,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> stageIds;

  StageCatalog selectFrom(StageCatalog source) {
    if (stageIds.length != 3 || stageIds.toSet().length != 3) {
      throw StateError('일일 변주는 서로 다른 세 장면이어야 합니다: $id');
    }
    final selected = <StageDefinition>[];
    for (final stageId in stageIds) {
      selected.add(source.stageById(stageId));
    }
    return StageCatalog(schemaVersion: source.schemaVersion, stages: selected);
  }
}

const List<DailyChallengeVariant> dailyChallengeVariants = [
  DailyChallengeVariant(
    id: 'trait_foundations',
    title: '속성 입문 항로',
    summary: '무거움과 탄성을 옮기고, 비워진 원본까지 다시 활용합니다.',
    stageIds: ['stage_heavy', 'stage_bouncy', 'stage_drained'],
  ),
  DailyChallengeVariant(
    id: 'causal_devices',
    title: '장치 연쇄 항로',
    summary: '문과 풍선, 남은 공을 차례로 연결해 길을 엽니다.',
    stageIds: ['stage_chain_gate', 'stage_balloon', 'stage_persistent'],
  ),
  DailyChallengeVariant(
    id: 'momentum_routes',
    title: '속도와 반사 항로',
    summary: '가속과 회전 반사, 연쇄 충돌로 짧은 고득점 경로를 만듭니다.',
    stageIds: ['stage_speed', 'stage_rotating_reflector', 'stage_chain_score'],
  ),
  DailyChallengeVariant(
    id: 'property_mastery',
    title: '속성 종합 항로',
    summary: '속성 강탈과 비워진 원본, 과거 공을 한 항해에서 조합합니다.',
    stageIds: ['stage_property_shot', 'stage_drained', 'stage_persistent'],
  ),
];

/// 기기 현지 시간대와 무관한 한국 표준시 날짜다.
class DailyChallengeDate {
  DailyChallengeDate._(this.year, this.month, this.day) {
    if (year < 1 || month < 1 || month > 12 || day < 1 || day > 31) {
      throw ArgumentError('유효하지 않은 한국 표준시 날짜입니다.');
    }
  }

  factory DailyChallengeDate.fromDateTime(DateTime instant) {
    final kst = instant.toUtc().add(koreanStandardTimeOffset);
    return DailyChallengeDate._(kst.year, kst.month, kst.day);
  }

  factory DailyChallengeDate.fromKey(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('오늘의 도전 날짜 키가 올바르지 않습니다: $value');
    }
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final candidate = DateTime.utc(year, month, day);
    if (candidate.year != year ||
        candidate.month != month ||
        candidate.day != day) {
      throw FormatException('오늘의 도전 날짜가 올바르지 않습니다: $value');
    }
    return DailyChallengeDate._(year, month, day);
  }

  final int year;
  final int month;
  final int day;

  String get key =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  String get displayText => '$year년 $month월 $day일';

  @override
  bool operator ==(Object other) =>
      other is DailyChallengeDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => key;
}

/// 날짜·해석기 버전으로부터 모든 오늘의 도전 입력을 결정한다.
class DailyChallengeDefinition {
  DailyChallengeDefinition({
    required this.date,
    this.challengeVersion = dailyChallengeVersion,
    this.resolverVersion = dailyChallengePhysicsResolverVersion,
  }) : rootSeed = _rootSeed(date, challengeVersion, resolverVersion),
       seedCode = _seedCode(
         _rootSeed(date, challengeVersion, resolverVersion),
       ) {
    if (challengeVersion.trim().isEmpty) {
      throw ArgumentError.value(
        challengeVersion,
        'challengeVersion',
        '비어 있을 수 없습니다.',
      );
    }
    if (resolverVersion.trim().isEmpty) {
      throw ArgumentError.value(
        resolverVersion,
        'resolverVersion',
        '비어 있을 수 없습니다.',
      );
    }
  }

  factory DailyChallengeDefinition.fromDateTime(
    DateTime instant, {
    String challengeVersion = dailyChallengeVersion,
    String resolverVersion = dailyChallengePhysicsResolverVersion,
  }) {
    return DailyChallengeDefinition(
      date: DailyChallengeDate.fromDateTime(instant),
      challengeVersion: challengeVersion,
      resolverVersion: resolverVersion,
    );
  }

  factory DailyChallengeDefinition.fromDateKey(
    String dateKey, {
    String challengeVersion = dailyChallengeVersion,
    String resolverVersion = dailyChallengePhysicsResolverVersion,
  }) {
    return DailyChallengeDefinition(
      date: DailyChallengeDate.fromKey(dateKey),
      challengeVersion: challengeVersion,
      resolverVersion: resolverVersion,
    );
  }

  final DailyChallengeDate date;
  final String challengeVersion;
  final String resolverVersion;
  final int rootSeed;
  final String seedCode;

  DailyChallengeVariant get variant =>
      dailyChallengeVariants[date.day % dailyChallengeVariants.length];

  StageCatalog selectCatalog(StageCatalog source) => variant.selectFrom(source);

  String get dateKey => date.key;
  String get displayDate => date.displayText;

  String officialRunId(String attemptId) {
    _validateAttemptId(attemptId);
    return 'daily_${dateKey}_official_$attemptId';
  }

  static int _rootSeed(
    DailyChallengeDate date,
    String challengeVersion,
    String physicsResolverVersion,
  ) {
    final versionSeed = StableSeed.hashString(
      physicsResolverVersion,
      seed: StableSeed.hashString(challengeVersion),
    );
    return StableSeed.deriveSeed(
      rootSeed: versionSeed,
      stageId: date.key,
      cycle: 0,
      drawIndex: 0,
      purpose: 'daily_challenge_root_seed',
    );
  }

  /// 사용자에게 보여 줄 짧은 숫자 코드다. 표시는 한글 문구와 함께 사용한다.
  static String _seedCode(int seed) =>
      (seed % 1000000).toString().padLeft(6, '0');
}

/// 날짜와 모드별로 일반 런과 분리된 RunState 저장소를 만든다.
class DailyChallengeRunStateStorage {
  DailyChallengeRunStateStorage._({
    required this.definition,
    required this.mode,
    required this.attemptId,
    required this._store,
  });

  factory DailyChallengeRunStateStorage.official({
    required RunStateKeyValueBackend backend,
    required DailyChallengeDefinition definition,
    required String attemptId,
  }) {
    _validateAttemptId(attemptId);
    const mode = DailyChallengeMode.official;
    final namespace = _namespaceFor(definition, mode, attemptId);
    return DailyChallengeRunStateStorage._(
      definition: definition,
      mode: mode,
      attemptId: attemptId,
      store: RunStateStore(
        backend: NamespacedRunStateBackend(
          delegate: backend,
          namespace: namespace,
        ),
      ),
    );
  }

  factory DailyChallengeRunStateStorage.officialFromPreferences({
    required SharedPreferences preferences,
    required DailyChallengeDefinition definition,
    required String attemptId,
  }) {
    return DailyChallengeRunStateStorage.official(
      backend: SharedPreferencesRunStateBackend(preferences),
      definition: definition,
      attemptId: attemptId,
    );
  }

  /// 연습 진행은 기기 저장소를 받지 않아 앱 종료 뒤 복원될 수 없다.
  factory DailyChallengeRunStateStorage.practice({
    required DailyChallengeDefinition definition,
  }) {
    const mode = DailyChallengeMode.practice;
    return DailyChallengeRunStateStorage._(
      definition: definition,
      mode: mode,
      attemptId: null,
      store: RunStateStore(
        backend: NamespacedRunStateBackend(
          delegate: MemoryRunStateBackend(),
          namespace: _namespaceFor(definition, mode, null),
        ),
      ),
    );
  }

  final DailyChallengeDefinition definition;
  final DailyChallengeMode mode;
  final String? attemptId;
  final RunStateStore _store;

  String get namespace => _namespaceFor(definition, mode, attemptId);

  StagePatternSession createSession({
    required StageCatalog catalog,
    DateTime Function()? now,
  }) {
    return StagePatternSession(
      catalog: catalog,
      store: _store,
      now: now,
      fixedRootSeed: definition.rootSeed,
      fixedRunId: mode == DailyChallengeMode.official
          ? definition.officialRunId(attemptId!)
          : 'daily_${definition.dateKey}_practice',
      fixedResolverVersion: definition.resolverVersion,
    );
  }

  /// 공식 기록 대조에 필요한 검증된 최신 상태만 읽기 전용으로 노출한다.
  Future<DailyChallengeRunSnapshot> loadSnapshot() async {
    final state = await _store.load();
    return DailyChallengeRunSnapshot(
      state: state,
      revision: _store.lastRevision,
    );
  }
}

class DailyChallengeRunSnapshot {
  const DailyChallengeRunSnapshot({
    required this.state,
    required this.revision,
  });

  final RunState? state;
  final int? revision;
}

String _namespaceFor(
  DailyChallengeDefinition definition,
  DailyChallengeMode mode,
  String? attemptId,
) =>
    'property_shot_daily_run_state_v1/'
    '${definition.challengeVersion}/${definition.resolverVersion}/'
    '${definition.dateKey}/${mode.schemaName}/'
    '${attemptId == null ? '' : '$attemptId/'}';

void _validateAttemptId(String attemptId) {
  if (!RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(attemptId)) {
    throw ArgumentError.value(
      attemptId,
      'attemptId',
      '영문, 숫자, 밑줄, 붙임표로 된 1~80자여야 합니다.',
    );
  }
}
