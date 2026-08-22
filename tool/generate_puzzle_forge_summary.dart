// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'generate_stage_catalog.dart' as catalog_validation;

const _manifestPath = 'harness_docs/design/puzzle_forge_evidence.json';
const _catalogPath = 'assets/stages/chapter_1.json';
const _outputPath = 'assets/forge/puzzle_forge_summary.json';

void main(List<String> arguments) {
  final check = arguments.contains('--check');
  if (arguments.any((argument) => argument != '--check')) {
    stderr.writeln('알 수 없는 인자입니다: ${arguments.join(', ')}');
    exitCode = 2;
    return;
  }

  final manifest = _readMap(_manifestPath);
  final catalog = stageCatalogFromJson(File(_catalogPath).readAsStringSync());
  final generated = _generate(manifest, catalog);
  final rendered = '${const JsonEncoder.withIndent('  ').convert(generated)}\n';
  final output = File(_outputPath);

  if (check) {
    if (!output.existsSync() || output.readAsStringSync() != rendered) {
      stderr.writeln(
        'Puzzle Forge 요약이 원본·검증 결과와 다릅니다. '
        'dart run tool/generate_puzzle_forge_summary.dart 를 실행하세요.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('Puzzle Forge 생성 요약이 최신입니다.');
    return;
  }

  output.parent.createSync(recursive: true);
  output.writeAsStringSync(rendered, flush: true);
  stdout.writeln('Puzzle Forge 생성 요약을 갱신했습니다: $_outputPath');
}

Map<String, dynamic> _generate(
  Map<String, dynamic> manifest,
  StageCatalog catalog,
) {
  final staticIssues = catalog_validation.validateLegacyCatalog(catalog);
  if (staticIssues.isNotEmpty) {
    throw StateError('생산 카탈로그 정적 검증 실패: ${staticIssues.first}');
  }
  final runtimeIssues = catalog_validation.validateRuntimeCatalog(catalog);
  if (runtimeIssues.isNotEmpty) {
    throw StateError('생산 카탈로그 실행 검증 실패: ${runtimeIssues.first}');
  }

  final rawCandidates = manifest['candidates'];
  if (rawCandidates is! List || rawCandidates.isEmpty) {
    throw const FormatException('Puzzle Forge 후보가 비어 있습니다.');
  }
  final candidates = <Map<String, dynamic>>[];
  for (final raw in rawCandidates) {
    if (raw is! Map<String, dynamic>) {
      throw const FormatException('Puzzle Forge 후보는 객체여야 합니다.');
    }
    candidates.add(_evaluateCandidate(raw, catalog));
  }

  return <String, dynamic>{
    'schemaVersion': manifest['schemaVersion'],
    'title': manifest['title'],
    'source': <String, dynamic>{
      'humanManifest': _manifestPath,
      'productionCatalog': _catalogPath,
      'productionPatternCount': catalog.stages.fold<int>(
        0,
        (count, stage) => count + stage.patterns.length,
      ),
      'staticValidation': 'passed',
      'runtimeValidation': 'passed',
    },
    'roles': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': 'human_goal',
        'actor': '사람',
        'title': '재미 목표 설정',
        'body': manifest['humanGoal'],
      },
      <String, dynamic>{
        'id': 'codex_candidate',
        'actor': 'Codex',
        'title': '후보 제작',
        'body': manifest['codexRole'],
      },
      <String, dynamic>{
        'id': 'validator_gate',
        'actor': 'StagePatternValidator',
        'title': '결함 반려·통과',
        'body': manifest['validatorRole'],
      },
      <String, dynamic>{
        'id': 'human_adoption',
        'actor': '사람',
        'title': '최종 채택',
        'body': manifest['humanDecision'],
      },
    ],
    'candidates': candidates,
  };
}

Map<String, dynamic> _evaluateCandidate(
  Map<String, dynamic> raw,
  StageCatalog catalog,
) {
  final kind = _requiredString(raw, 'kind');
  final stageId = _requiredString(raw, 'stageId');
  final patternId = _requiredString(raw, 'patternId');
  final stage = catalog.stageById(stageId);
  final base = stage.patternById(patternId);
  final expectedCodes = _stringList(raw['expectedCodes']);

  if (kind == 'adopted') {
    final report = StagePatternValidator().validateLegacyStage(
      StageDefinition(stageId: stageId, title: stage.title, patterns: [base]),
    );
    final codes = _errorCodes(report);
    if (codes.isNotEmpty || expectedCodes.isNotEmpty) {
      throw StateError('채택 후보 $patternId의 정적 검증 결과가 예상과 다릅니다: $codes');
    }
    return _candidateOutput(raw, status: 'adopted', codes: codes);
  }

  final patternJson = jsonDecode(jsonEncode(base.toJson()));
  if (patternJson is! Map<String, dynamic>) {
    throw StateError('$patternId 패턴을 복제할 수 없습니다.');
  }
  switch (kind) {
    case 'ball_spawn_on_hole':
      final objects = patternJson['objects'] as List<dynamic>;
      final hole = objects.cast<Map<String, dynamic>>().firstWhere(
        (object) => object['type'] == 'hole',
      );
      patternJson['ballSpawn'] = Map<String, dynamic>.from(
        hole['position'] as Map<String, dynamic>,
      );
    case 'missing_link_target':
      final objects = patternJson['objects'] as List<dynamic>;
      final linked = objects.cast<Map<String, dynamic>>().firstWhere(
        (object) =>
            object['type'] == 'switch_pad' && object['linkId'] is String,
      );
      linked['linkId'] = 'forge_missing_target';
    default:
      throw FormatException('지원하지 않는 Puzzle Forge 후보 kind: $kind');
  }

  final candidate = StagePattern.fromJson(patternJson);
  final report = StagePatternValidator().validateLegacyStage(
    StageDefinition(
      stageId: stageId,
      title: stage.title,
      patterns: [candidate],
    ),
  );
  final codes = _errorCodes(report);
  if (!codes.toSet().containsAll(expectedCodes) || expectedCodes.isEmpty) {
    throw StateError('$patternId 후보 검출 코드가 예상과 다릅니다: $codes');
  }
  return _candidateOutput(raw, status: 'rejected', codes: codes);
}

Map<String, dynamic> _candidateOutput(
  Map<String, dynamic> raw, {
  required String status,
  required List<String> codes,
}) => <String, dynamic>{
  'id': raw['id'],
  'status': status,
  'stageId': raw['stageId'],
  'patternId': raw['patternId'],
  'proposal': raw['proposal'],
  'validatorCodes': codes,
  'humanDecision': raw['humanDecision'],
};

List<String> _errorCodes(ValidationReport report) =>
    report.issues
        .where((issue) => issue.severity == ValidationSeverity.error)
        .map((issue) => issue.codeName)
        .toSet()
        .toList()
      ..sort();

Map<String, dynamic> _readMap(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$path 최상위 값은 객체여야 합니다.');
  }
  return decoded;
}

String _requiredString(Map<String, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$key는 비어 있지 않은 문자열이어야 합니다.');
  }
  return value;
}

List<String> _stringList(Object? raw) {
  if (raw is! List || raw.any((value) => value is! String)) {
    throw const FormatException('expectedCodes는 문자열 배열이어야 합니다.');
  }
  return raw.cast<String>();
}
