// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

import 'package:property_shot/game/hint/hint_catalog.dart';

const _sourcePath = 'assets/stages/hints_v1.json';
const _generatedPath = 'lib/game/hint/generated_hint_catalog.dart';

void main(List<String> arguments) {
  final check = arguments.contains('--check');
  if (arguments.any((argument) => argument != '--check')) {
    stderr.writeln('사용법: dart run tool/generate_hint_catalog.dart [--check]');
    exitCode = 2;
    return;
  }
  final source = File(_sourcePath).readAsStringSync();
  // 생성 전에 schema를 읽어 잘못된 JSON이 그대로 스냅샷에 들어가지 않게 한다.
  HintCatalog.fromJsonString(source);
  final pretty = const JsonEncoder.withIndent('  ').convert(jsonDecode(source));
  final rendered = [
    '// 자동 생성 파일입니다. 직접 편집하지 마세요.',
    '// assets/stages/hints_v1.json에서 결정론적으로 생성됩니다.',
    '// JSON 최상위 field는 version/entries, 생성 API는 generatedHintCatalogJson/generatedHintCatalog입니다.',
    '',
    "import 'hint_catalog.dart';",
    '',
    "const generatedHintCatalogJson = r'''",
    pretty,
    "''';",
    '',
    'final generatedHintCatalog = HintCatalog.fromJsonString(generatedHintCatalogJson);',
    '',
  ].join('\n');
  final output = File(_generatedPath);
  if (check) {
    if (!output.existsSync() || output.readAsStringSync() != rendered) {
      stderr.writeln('힌트 카탈로그 생성본이 원본 JSON과 다릅니다.');
      exitCode = 1;
      return;
    }
    print('힌트 카탈로그 생성본이 최신입니다.');
    return;
  }
  output.parent.createSync(recursive: true);
  output.writeAsStringSync(rendered);
  print('힌트 카탈로그 생성본을 갱신했습니다: $_generatedPath');
}
