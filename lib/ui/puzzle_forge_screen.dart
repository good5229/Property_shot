import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';

const puzzleForgeSummaryAsset = 'assets/forge/puzzle_forge_summary.json';

@immutable
class PuzzleForgeSummary {
  const PuzzleForgeSummary({
    required this.title,
    required this.productionPatternCount,
    required this.roles,
    required this.candidates,
  });

  final String title;
  final int productionPatternCount;
  final List<PuzzleForgeRole> roles;
  final List<PuzzleForgeCandidate> candidates;

  factory PuzzleForgeSummary.fromJson(Map<String, dynamic> json) {
    final source = json['source'];
    final roles = json['roles'];
    final candidates = json['candidates'];
    if (json['schemaVersion'] != 1 ||
        source is! Map<String, dynamic> ||
        roles is! List ||
        candidates is! List) {
      throw const FormatException('지원하지 않는 Puzzle Forge 요약입니다.');
    }
    if (source['staticValidation'] != 'passed' ||
        source['runtimeValidation'] != 'passed') {
      throw const FormatException('검증을 통과하지 않은 Puzzle Forge 요약입니다.');
    }
    return PuzzleForgeSummary(
      title: _requiredString(json, 'title'),
      productionPatternCount: _requiredInt(source, 'productionPatternCount'),
      roles: List.unmodifiable(
        roles.map(
          (role) => PuzzleForgeRole.fromJson(_requiredMap(role, 'role')),
        ),
      ),
      candidates: List.unmodifiable(
        candidates.map(
          (candidate) => PuzzleForgeCandidate.fromJson(
            _requiredMap(candidate, 'candidate'),
          ),
        ),
      ),
    );
  }
}

@immutable
class PuzzleForgeRole {
  const PuzzleForgeRole({
    required this.id,
    required this.actor,
    required this.title,
    required this.body,
  });

  final String id;
  final String actor;
  final String title;
  final String body;

  factory PuzzleForgeRole.fromJson(Map<String, dynamic> json) =>
      PuzzleForgeRole(
        id: _requiredString(json, 'id'),
        actor: _requiredString(json, 'actor'),
        title: _requiredString(json, 'title'),
        body: _requiredString(json, 'body'),
      );
}

@immutable
class PuzzleForgeCandidate {
  const PuzzleForgeCandidate({
    required this.id,
    required this.status,
    required this.patternId,
    required this.proposal,
    required this.validatorCodes,
    required this.humanDecision,
  });

  final String id;
  final PuzzleForgeCandidateStatus status;
  final String patternId;
  final String proposal;
  final List<String> validatorCodes;
  final String humanDecision;

  factory PuzzleForgeCandidate.fromJson(Map<String, dynamic> json) {
    final rawStatus = _requiredString(json, 'status');
    final rawCodes = json['validatorCodes'];
    if (rawCodes is! List || rawCodes.any((code) => code is! String)) {
      throw const FormatException('validatorCodes가 올바르지 않습니다.');
    }
    final status = switch (rawStatus) {
      'rejected' => PuzzleForgeCandidateStatus.rejected,
      'adopted' => PuzzleForgeCandidateStatus.adopted,
      _ => throw FormatException('알 수 없는 후보 상태: $rawStatus'),
    };
    final codes = List<String>.unmodifiable(rawCodes.cast<String>());
    if ((status == PuzzleForgeCandidateStatus.rejected) == codes.isEmpty) {
      throw const FormatException('후보 상태와 Validator 코드가 일치하지 않습니다.');
    }
    return PuzzleForgeCandidate(
      id: _requiredString(json, 'id'),
      status: status,
      patternId: _requiredString(json, 'patternId'),
      proposal: _requiredString(json, 'proposal'),
      validatorCodes: codes,
      humanDecision: _requiredString(json, 'humanDecision'),
    );
  }
}

enum PuzzleForgeCandidateStatus { rejected, adopted }

Future<PuzzleForgeSummary> loadPuzzleForgeSummary({AssetBundle? bundle}) async {
  final source = await (bundle ?? rootBundle).loadString(
    puzzleForgeSummaryAsset,
  );
  final decoded = jsonDecode(source);
  if (decoded is! Map<String, dynamic>) {
    throw const FormatException('Puzzle Forge 요약 최상위 값이 올바르지 않습니다.');
  }
  return PuzzleForgeSummary.fromJson(decoded);
}

class PuzzleForgeScreen extends StatelessWidget {
  const PuzzleForgeScreen({
    super.key,
    required this.onBack,
    this.summary,
    this.language = AppLanguage.korean,
  });

  final VoidCallback onBack;
  final PuzzleForgeSummary? summary;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final provided = summary;
    if (provided != null) {
      return _PuzzleForgeView(
        summary: provided,
        onBack: onBack,
        language: language,
      );
    }
    return FutureBuilder<PuzzleForgeSummary>(
      future: loadPuzzleForgeSummary(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            key: const Key('puzzle_forge_error'),
            appBar: AppBar(leading: BackButton(onPressed: onBack)),
            body: Center(
              child: Text(
                language.pick(
                  '제작 과정 자료를 불러오지 못했습니다.',
                  'Could not load the creation evidence.',
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _PuzzleForgeView(
          summary: snapshot.requireData,
          onBack: onBack,
          language: language,
        );
      },
    );
  }
}

class _PuzzleForgeView extends StatelessWidget {
  const _PuzzleForgeView({
    required this.summary,
    required this.onBack,
    required this.language,
  });

  final PuzzleForgeSummary summary;
  final VoidCallback onBack;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('puzzle_forge_screen'),
      backgroundColor: const Color(0xFFBFE8E3),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F3DA),
        leading: BackButton(
          key: const Key('puzzle_forge_back_button'),
          onPressed: onBack,
        ),
        title: Text(
          language.pick(summary.title, 'CODEX PUZZLE FORGE'),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth < 420 ? 14 : 24,
              vertical: 20,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      language.pick(
                        'AI가 만든 후보를 바로 게임에 넣지 않습니다',
                        'AI CANDIDATES DO NOT SHIP UNREVIEWED',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF173F43),
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      language.pick(
                        '사람이 재미의 목표를 정하고, Codex가 후보를 만들고, 자동 검증이 결함을 반려한 뒤 사람이 최종 채택합니다.',
                        'A human sets the fun target. Codex builds candidates. Automated checks reject defects, and the human makes the final call.',
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF285C5D),
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.center,
                      child: Container(
                        key: const Key('forge_validation_badge'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F4DD),
                          border: Border.all(color: const Color(0xFF4F7A4C)),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          language.isEnglish
                              ? '${summary.productionPatternCount} PRODUCTION PATTERNS · STATIC + PHYSICS CHECKS PASSED'
                              : '생산 패턴 ${summary.productionPatternCount}개 · 정적 배치 + 실제 물리 실행 통과',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF345A32),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _RoleFlow(
                      roles: summary.roles,
                      horizontal: wide,
                      language: language,
                    ),
                    const SizedBox(height: 28),
                    Text(
                      language.pick('실제 후보 판정', 'REAL CANDIDATE DECISIONS'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF173F43),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (
                      var index = 0;
                      index < summary.candidates.length;
                      index++
                    ) ...[
                      _CandidateCard(
                        candidate: summary.candidates[index],
                        language: language,
                      ),
                      if (index < summary.candidates.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleFlow extends StatelessWidget {
  const _RoleFlow({
    required this.roles,
    required this.horizontal,
    required this.language,
  });

  final List<PuzzleForgeRole> roles;
  final bool horizontal;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var index = 0; index < roles.length; index++) {
      if (index > 0) {
        children.add(
          Icon(
            horizontal
                ? Icons.arrow_forward_rounded
                : Icons.arrow_downward_rounded,
            color: const Color(0xFF517E7A),
            size: 28,
          ),
        );
      }
      children.add(
        horizontal
            ? Expanded(
                child: _RoleCard(
                  role: roles[index],
                  index: index,
                  language: language,
                ),
              )
            : _RoleCard(role: roles[index], index: index, language: language),
      );
    }
    return Semantics(
      key: const Key('forge_role_flow'),
      container: true,
      label: roles
          .map((role) => _roleCopy(role, language).semantics)
          .join(language.pick(' 다음, ', ' then ')),
      excludeSemantics: true,
      child: horizontal
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.index,
    required this.language,
  });

  final PuzzleForgeRole role;
  final int index;
  final AppLanguage language;

  static const _assets = [
    'assets/generated/nav-helm-v1.png',
    'assets/generated/stage-icon-property-transfer-v1.png',
    'assets/generated/nav-stage-map-v1.png',
    'assets/generated/island-observatory-v2.png',
  ];

  @override
  Widget build(BuildContext context) {
    final copy = _roleCopy(role, language);
    return Container(
      key: Key('forge_role_${role.id}'),
      constraints: const BoxConstraints(minHeight: 168),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xEFFFF8E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4D7974), width: 1.4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            _assets[index % _assets.length],
            width: 52,
            height: 52,
            filterQuality: FilterQuality.high,
            excludeFromSemantics: true,
          ),
          const SizedBox(height: 8),
          Text(
            copy.actor,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6E5B2A),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          Text(
            copy.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 5),
          Text(
            copy.body,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.3, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.language});

  final PuzzleForgeCandidate candidate;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final adopted = candidate.status == PuzzleForgeCandidateStatus.adopted;
    final copy = _candidateCopy(candidate, language);
    final accent = adopted ? const Color(0xFF39704B) : const Color(0xFF9B483A);
    return Semantics(
      container: true,
      label:
          '${adopted ? language.pick('채택', 'Adopted') : language.pick('반려', 'Rejected')}. ${copy.proposal}. ${_validationReason(candidate, language)}. ${copy.humanDecision}',
      child: Container(
        key: Key('forge_candidate_${candidate.id}'),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: adopted ? const Color(0xFFEAF5DE) : const Color(0xFFFFE8DE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent, width: 1.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                adopted
                    ? language.pick('채택', 'ADOPTED')
                    : language.pick('반려', 'REJECTED'),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    copy.proposal,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _validationReason(candidate, language),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(copy.humanDecision),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _validationReason(PuzzleForgeCandidate candidate, AppLanguage language) {
  if (candidate.validatorCodes.isEmpty) {
    return language.pick(
      'Validator: 정적 배치와 실제 물리 실행 통과',
      'Validator: static layout and real physics passed',
    );
  }
  final labels = candidate.validatorCodes.map(
    (code) => switch (code) {
      'ball_spawn_overlaps_hole' => language.pick(
        '시작 공과 홀이 겹침',
        'ball spawn overlaps goal',
      ),
      'missing_linked_target' => language.pick(
        '스위치의 문 연결 대상 없음',
        'switch has no linked gate',
      ),
      _ => language.pick('검증 규칙 위반', 'validation rule violated'),
    },
  );
  return 'Validator: ${labels.join(' · ')}';
}

({String actor, String title, String body, String semantics}) _roleCopy(
  PuzzleForgeRole role,
  AppLanguage language,
) {
  if (!language.isEnglish) {
    return (
      actor: role.actor,
      title: role.title,
      body: role.body,
      semantics: '${role.actor}, ${role.title}. ${role.body}',
    );
  }
  final copy = switch (role.id) {
    'human_goal' => (
      actor: 'HUMAN',
      title: 'Set the fun target',
      body:
          'Make trait transfer change both objects, and turn a missed ball into the next solution.',
    ),
    'codex_candidate' => (
      actor: 'CODEX',
      title: 'Build candidates',
      body:
          'Turn the human target into layouts, hints, and testable pattern data.',
    ),
    'validator_gate' => (
      actor: 'STAGEPATTERNVALIDATOR',
      title: 'Reject or pass',
      body:
          'Check layouts and real ShotResolver evidence, then return stable defect codes.',
    ),
    'human_adoption' => (
      actor: 'HUMAN',
      title: 'Make the final call',
      body:
          'Review validation evidence and play intent, then adopt or request another candidate.',
    ),
    _ => (actor: role.actor, title: role.title, body: role.body),
  };
  return (
    actor: copy.actor,
    title: copy.title,
    body: copy.body,
    semantics: '${copy.actor}, ${copy.title}. ${copy.body}',
  );
}

({String proposal, String humanDecision}) _candidateCopy(
  PuzzleForgeCandidate candidate,
  AppLanguage language,
) {
  if (!language.isEnglish) {
    return (
      proposal: candidate.proposal,
      humanDecision: candidate.humanDecision,
    );
  }
  return switch (candidate.id) {
    'auto_clear_spawn' => (
      proposal: 'Move the ball near the goal to reduce first-entry friction',
      humanDecision: 'Rejected: the stage could end without player input.',
    ),
    'broken_causal_link' => (
      proposal: 'Expand the balloon-to-gate chain with an incorrect target',
      humanDecision:
          'Rejected: performing the cause would never open the result.',
    ),
    'persistent_ball_adopted' => (
      proposal: 'Keep the first ball as a bumper or stopper for the next shot',
      humanDecision:
          'Adopted into the 60-second core play after intent and checks passed.',
    ),
    _ => (proposal: candidate.proposal, humanDecision: candidate.humanDecision),
  };
}

Map<String, dynamic> _requiredMap(Object? value, String label) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$label 값이 올바르지 않습니다.');
  }
  return value;
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key 값이 올바르지 않습니다.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! int || value < 0) {
    throw FormatException('$key 값이 올바르지 않습니다.');
  }
  return value;
}
