import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  test('저장된 단계별 다중샷 20개를 같은 순서로 재생한다', () {
    final json =
        jsonDecode(
              File(
                'harness_docs/qa/replays/multi_shot_fixtures.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final fixtures = [
      for (final item in (json['fixtures'] as List))
        ReplayFixture.fromJson(Map<String, Object?>.from(item as Map)),
    ];

    expect(json['schemaVersion'], 1);
    expect(fixtures, hasLength(levels.length * 5));
    expect(fixtures.map((fixture) => fixture.stageIndex).toSet(), {0, 1, 2, 3});
    expect(fixtures.every((fixture) => fixture.shots.isNotEmpty), isTrue);
    expect(fixtures.any((fixture) => fixture.shots.length == 2), isTrue);

    for (final fixture in fixtures) {
      var state = levels[fixture.stageIndex].createState(
        fixture.stageIndex,
        productRules: true,
        copyCoreCount: fixture.copyCoreCount,
      );
      for (var index = 0; index < fixture.shots.length; index++) {
        final result = const ShotResolver().resolve(
          state,
          fixture.shots[index].toInput(),
        );
        expect(
          shotResultFingerprint(result),
          fixture.expectedFingerprints[index],
          reason: fixture.id,
        );
        state = result.state;
      }
      expect(state.phase.name, fixture.expectedPhase, reason: fixture.id);
    }
  });
}
