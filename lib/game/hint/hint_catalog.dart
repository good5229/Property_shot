import 'dart:convert';

import 'pattern_hint.dart';

/// `assets/stages/hints_v1.json`의 최상위 `version`과 `entries`를 읽는다.
///
/// `version`은 카탈로그 schema 버전, 각 entry의 `hintVersion`은 저장된
/// entitlement가 가리키는 개별 힌트 문구 버전이다. 생성본은
/// `generatedHintCatalogJson`/`generatedHintCatalog`이라는 안정 이름을 쓴다.
class HintCatalog {
  const HintCatalog({required this.version, required this.entries});

  final int version;
  final List<PatternHintEntry> entries;

  factory HintCatalog.fromJsonString(String source) {
    final value = jsonDecode(source);
    if (value is! Map) throw const FormatException('hint catalog 객체가 필요합니다.');
    final version = value['version'];
    final entries = value['entries'];
    if (version is! int || entries is! List) {
      throw const FormatException('hint catalog version/entries가 올바르지 않습니다.');
    }
    return HintCatalog(
      version: version,
      entries: List.unmodifiable(
        entries.map((item) {
          if (item is! Map) {
            throw const FormatException('hint entry 객체가 필요합니다.');
          }
          return PatternHintEntry.fromJson(Map<String, dynamic>.from(item));
        }),
      ),
    );
  }

  PatternHintEntry entryFor({
    required String stageId,
    required String patternId,
  }) {
    return entries.singleWhere(
      (entry) => entry.stageId == stageId && entry.patternId == patternId,
      orElse: () => throw ArgumentError('힌트가 없습니다: $stageId/$patternId'),
    );
  }
}
