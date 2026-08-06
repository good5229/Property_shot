import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  test('저장된 단계별 성공·실패 리플레이 픽스처를 동일하게 재생한다', () {
    final json =
        jsonDecode(
              File(
                'harness_docs/qa/replays/single_shot_fixtures.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final fixtures = [
      for (final item in (json['fixtures'] as List))
        ReplayFixture.fromJson(Map<String, Object?>.from(item as Map)),
    ];

    expect(json['schemaVersion'], 1);
    expect(fixtures, hasLength(levels.length * 4));
    expect(fixtures.map((fixture) => fixture.stageIndex).toSet(), {
      for (var index = 0; index < levels.length; index++) index,
    });
    expect(
      fixtures.where((fixture) => fixture.stageIndex == 4),
      everyElement(
        isA<ReplayFixture>().having(
          (fixture) => fixture.transferSourceId,
          '비워질 원본 ID',
          isNotNull,
        ),
      ),
    );
    expect(
      fixtures
          .where((fixture) => fixture.stageIndex == 6)
          .expand((fixture) => fixture.shots)
          .every((shot) => shot.power >= 0.12),
      isTrue,
    );
    for (final fixture in fixtures) {
      var state = levels[fixture.stageIndex].createState(
        fixture.stageIndex,
        productRules: true,
        copyCoreCount: fixture.copyCoreCount,
      );
      final transferSourceId = fixture.transferSourceId;
      if (transferSourceId != null) {
        const traits = TraitResolver();
        state = traits.transferSelectedTrait(
          traits.selectSource(state, transferSourceId),
        );
        final source = state.entityById(transferSourceId)!;
        expect(source.traits, isEmpty, reason: fixture.id);
        expect(source.movable, isTrue, reason: fixture.id);
        expect(source.visualState, 'drained', reason: fixture.id);
      }
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
