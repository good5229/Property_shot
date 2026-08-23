import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

const _manifestPath =
    'submission/openai_game_builders_track1/challenge_period_manifest.json';
const _submissionCopyPath =
    'submission/openai_game_builders_track1/submission_fields_ko.md';

void main() {
  late Map<String, Object?> manifest;

  setUpAll(() {
    manifest =
        jsonDecode(File(_manifestPath).readAsStringSync())
            as Map<String, Object?>;
  });

  test('제출 필수 정보와 공식 심사축을 고정한다', () {
    final submission = manifest['submission']! as Map<String, Object?>;
    final intro = submission['gameIntro']! as String;
    final playUrl = Uri.parse(submission['playUrl']! as String);

    expect(intro.runes.length, lessThanOrEqualTo(200));
    expect(playUrl.scheme, 'https');
    expect(playUrl.host, isNotEmpty);
    expect(submission['demoVideo'], 'deferred_by_user');
    expect((manifest['officialCriteria']! as List<Object?>).toSet(), {
      'Playability',
      'Originality',
      'Codex Collaboration',
      'Release Potential',
      'Presentation',
    });
    expect(_containsKeyRecursively(manifest, 'commitId'), isFalse);
  });

  test('신규 기능 완료일은 챌린지 기간 안에 있다', () {
    final window = manifest['challengeWindow']! as Map<String, Object?>;
    final start = DateTime.parse(window['startsOn']! as String);
    final end = DateTime.parse(window['endsOn']! as String);
    final features = manifest['newDuringChallenge']! as List<Object?>;

    expect(features, isNotEmpty);
    for (final item in features) {
      final feature = item! as Map<String, Object?>;
      final completed = DateTime.parse(feature['completedOn']! as String);
      expect(completed.isBefore(start), isFalse, reason: '${feature['id']}');
      expect(completed.isAfter(end), isFalse, reason: '${feature['id']}');
      expect((feature['criteria']! as List<Object?>), isNotEmpty);
    }
  });

  test('썸네일은 16:9 PNG이며 권장 용량 이하다', () async {
    final submission = manifest['submission']! as Map<String, Object?>;
    final file = File(submission['thumbnail']! as String);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    expect(frame.image.width, 1920);
    expect(frame.image.height, 1080);
    expect(bytes.length, lessThan(10 * 1024 * 1024));
    codec.dispose();
  });

  test('복사 가능한 한국어 제출 문안이 핵심 경로를 포함한다', () {
    final copy = File(_submissionCopyPath).readAsStringSync();

    expect(copy, contains('https://good5229.github.io/Property_shot/'));
    expect(copy, contains('60초 핵심 체험'));
    expect(copy, contains('Codex Puzzle Forge'));
    expect(copy, contains('이번 반복에서 제작하지 않았습니다'));
    expect(copy, isNot(contains('TODO')));
  });
}

bool _containsKeyRecursively(Object? value, String key) {
  if (value is Map<String, Object?>) {
    if (value.containsKey(key)) return true;
    return value.values.any((item) => _containsKeyRecursively(item, key));
  }
  if (value is List<Object?>) {
    return value.any((item) => _containsKeyRecursively(item, key));
  }
  return false;
}
