// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'stage_pattern_runtime_manifest.dart';

const _sourcePath = 'assets/stages/chapter_1.json';
const _generatedPath = 'lib/game/levels/generated_stage_catalog.dart';

void main(List<String> arguments) {
  final check = arguments.contains('--check');
  final validateRuntime = arguments.contains('--validate-runtime');
  final unknown = arguments.where(
    (argument) => argument != '--check' && argument != '--validate-runtime',
  );
  if (unknown.isNotEmpty) {
    stderr.writeln('알 수 없는 인자입니다: ${unknown.join(', ')}');
    exitCode = 2;
    return;
  }

  final catalog = _readCatalog();
  final catalogIssues = catalog.validate();
  if (catalogIssues.isNotEmpty) {
    stderr.writeln('스테이지 카탈로그 검증에 실패했습니다.');
    for (final issue in catalogIssues) {
      stderr.writeln('- $issue');
    }
    exitCode = 2;
    return;
  }

  final staticIssues = validateLegacyCatalog(catalog);
  if (staticIssues.isNotEmpty) {
    stderr.writeln('기준 패턴의 정적 배치 검증에 실패했습니다.');
    for (final issue in staticIssues) {
      stderr.writeln('- ${formatValidationIssue(issue)}');
    }
    exitCode = 2;
    return;
  }

  if (validateRuntime) {
    final runtimeIssues = validateRuntimeCatalog(catalog);
    if (runtimeIssues.isNotEmpty) {
      stderr.writeln('생산 패턴의 실행 검증에 실패했습니다.');
      for (final issue in runtimeIssues) {
        stderr.writeln('- ${formatValidationIssue(issue)}');
      }
      exitCode = 2;
      return;
    }
    stdout.writeln('생산 패턴 40개의 제한 실행 검증을 통과했습니다.');
  }

  final generated = _render(catalog);
  final output = File(_generatedPath);
  if (check) {
    if (!output.existsSync()) {
      stderr.writeln('생성 스냅샷이 없습니다: $_generatedPath');
      exitCode = 1;
      return;
    }
    final current = output.readAsStringSync();
    if (current != generated) {
      stderr.writeln(
        '생성 스냅샷이 원본 JSON과 다릅니다. '
        'dart run tool/generate_stage_catalog.dart 를 실행하세요.',
      );
      exitCode = 1;
      return;
    }
    stdout.writeln('스테이지 카탈로그 생성본이 최신입니다.');
    return;
  }

  output.parent.createSync(recursive: true);
  _writeAtomically(output, generated);
  stdout.writeln('스테이지 카탈로그 생성본을 갱신했습니다: $_generatedPath');
}

/// 원본 카탈로그의 기준 패턴을 기존 레거시 배치 정책으로 검사한다.
/// 패턴 수 3~4개 정책은 적용하지 않고, 각 패턴의 실제 배치 오류만 검사한다.
List<ValidationIssue> validateLegacyCatalog(StageCatalog catalog) {
  final validator = StagePatternValidator();
  final issues = <ValidationIssue>[];
  for (final stage in catalog.stages) {
    final report = validator.validateLegacyStage(stage);
    issues.addAll(
      report.issues.where(
        (issue) => issue.severity == ValidationSeverity.error,
      ),
    );
  }
  return issues;
}

/// 기존 대표 fixture를 실제 ShotResolver로 재생해 모든 생산 패턴을 검사한다.
List<ValidationIssue> validateRuntimeCatalog(
  StageCatalog catalog, {
  Map<String, List<PatternRuntimeScenario>>? manifest,
}) {
  final scenariosByPattern = manifest ?? buildRuntimeValidationManifest();
  final validator = StagePatternValidator();
  final issues = <ValidationIssue>[];
  for (final stage in catalog.stages) {
    for (final pattern in stage.patterns) {
      final scenarios = scenariosByPattern[pattern.patternId] ?? const [];
      final requiredShots = scenarios.fold<int>(
        0,
        (sum, scenario) => sum + scenario.inputs.length * 2,
      );
      final probe = ShotResolverPatternRuntimeProbe(
        representativeInputs: const [],
        representativeScenarios: scenarios,
        requireSolutionContract: true,
        maxProbeCount: math.max(1, scenarios.length),
        maxShots: math.max(2, requiredShots),
      );
      final evidence = probe.probe(stage: stage, pattern: pattern);
      final report = validator.validatePatternWithRuntimeEvidence(
        stage,
        pattern,
        evidence,
      );
      issues.addAll(
        report.issues.where(
          (issue) => issue.severity == ValidationSeverity.error,
        ),
      );
    }
  }
  return issues;
}

String formatValidationIssue(ValidationIssue issue) {
  return '오류 코드=${issue.codeName}, '
      '스테이지=${issue.stageId}, '
      '패턴=${issue.patternId ?? '-'}: '
      '${issue.message}';
}

void _writeAtomically(File output, String contents) {
  final suffix = DateTime.now().microsecondsSinceEpoch;
  final temporary = File('${output.path}.tmp.$suffix');
  File? backup;
  try {
    temporary.writeAsStringSync(contents, flush: true);
    try {
      // macOS를 포함한 POSIX에서는 같은 디렉터리의 rename이 기존 파일을
      // 완성된 파일로 원자적으로 교체한다.
      temporary.renameSync(output.path);
      return;
    } on FileSystemException {
      if (!output.existsSync()) {
        rethrow;
      }
      // 대상 교체를 지원하지 않는 환경에서는 백업 후 교체하고, 실패하면
      // 기존 파일을 복원해 반쪽짜리 생성 파일을 남기지 않는다.
      backup = File('${output.path}.bak.$suffix');
      output.renameSync(backup.path);
      try {
        temporary.renameSync(output.path);
      } catch (_) {
        if (!output.existsSync() && backup.existsSync()) {
          backup.renameSync(output.path);
        }
        rethrow;
      }
      backup.deleteSync();
      backup = null;
    }
  } finally {
    if (temporary.existsSync()) {
      temporary.deleteSync();
    }
    // 복원까지 실패한 경우에는 기존 파일을 보존한 백업을 삭제하지 않는다.
  }
}

StageCatalog _readCatalog() {
  try {
    return stageCatalogFromJson(File(_sourcePath).readAsStringSync());
  } on Object catch (error) {
    stderr.writeln('원본 스테이지 카탈로그를 읽을 수 없습니다: $error');
    exit(2);
  }
}

String _render(StageCatalog catalog) {
  const encoder = JsonEncoder.withIndent('  ');
  final json = encoder.convert(catalog.toJson());
  return [
    '// 자동 생성 파일입니다. 직접 편집하지 마세요.',
    '// assets/stages/chapter_1.json에서 결정론적으로 생성됩니다.',
    '// JSON 원본이 기준 데이터이며 이 Dart 파일은 동기 실행용 스냅샷입니다.',
    '',
    "import '../domain/stage_catalog.dart';",
    '',
    "const generatedStageCatalogJson = r'''",
    json,
    "''';",
    '',
    'final generatedStageCatalog = stageCatalogFromJson(generatedStageCatalogJson);',
    '',
  ].join('\n');
}
