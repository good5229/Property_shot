import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('대리 플레이 예시는 JSON schema의 필수·허용 root 계약과 일치한다', () {
    final schema =
        jsonDecode(
              File(
                'harness_docs/design/proxy_playtest.schema.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final markdown = File(
      'harness_docs/design/playtest_protocol.md',
    ).readAsStringSync();
    final match = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(markdown);
    expect(match, isNotNull);
    final example = jsonDecode(match!.group(1)!) as Map<String, Object?>;
    final required = (schema['required']! as List).cast<String>().toSet();
    final allowed = ((schema['properties']! as Map).keys)
        .cast<String>()
        .toSet();
    expect(example.keys.toSet(), containsAll(required));
    expect(example.keys.toSet().difference(allowed), isEmpty);
    expect(
      example['scenario'],
      isNull,
      reason: '내부 시나리오 정답은 agent 입력에 노출하지 않는다',
    );
    expect(
      (example['limitations']! as List),
      contains('agent_proxy_not_human'),
    );
  });
}
