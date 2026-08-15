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
    final agent = (example['agent']! as Map).cast<String, Object?>();
    expect(agent['prompt_version'], '2');
    expect(agent['profile'], 'mobile_touch');
    expect(agent['input_mode'], 'pointer');
  });

  test('네 입력 역할은 서로 다른 행동 제한과 위험 질문을 제공한다', () {
    final prompts = File(
      'harness_docs/design/proxy_playtest_prompts.md',
    ).readAsStringSync();
    final sections = <String, String>{};
    for (final profile in [
      'mobile_touch',
      'keyboard_only',
      'semantics_only',
      'abnormal_input',
    ]) {
      final match = RegExp(
        '## $profile\\n\\n([\\s\\S]*?)(?=\\n## |\$)',
      ).firstMatch(prompts);
      expect(match, isNotNull, reason: '$profile 전용 문구가 없습니다.');
      sections[profile] = match!.group(1)!.trim();
      expect(sections[profile]!.length, greaterThan(80));
    }
    expect(sections.values.toSet(), hasLength(4));
    expect(sections['mobile_touch'], contains('320×568'));
    expect(sections['mobile_touch'], contains('포인터'));
    expect(sections['keyboard_only'], contains('반복 Space'));
    expect(sections['keyboard_only'], contains('팝업'));
    expect(sections['semantics_only'], contains('live region'));
    expect(sections['semantics_only'], contains('픽셀 정보는 사용하지'));
    expect(sections['abnormal_input'], contains('변조된 코드'));
    expect(sections['abnormal_input'], contains('중복 보상'));
  });
}
