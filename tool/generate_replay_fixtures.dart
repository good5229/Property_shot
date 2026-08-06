// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/analysis/replay_fixture.dart';
import 'package:property_shot/game/analysis/replay_signature.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

const resolver = ShotResolver();

void main() {
  final fixtures = <ReplayFixture>[];
  for (var stageIndex = 0; stageIndex < levels.length; stageIndex++) {
    final state = levels[stageIndex].createState(
      stageIndex,
      productRules: true,
      copyCoreCount: 1,
    );
    final candidates = _candidates(stageIndex, state);
    final successes = <_Candidate>[];
    final failures = <_Candidate>[];
    for (final candidate in candidates) {
      final result = resolver.resolve(
        candidate.initialState,
        candidate.shot.toInput(),
      );
      if (result.state.phase == GamePhase.success) {
        if (successes.length < 2) {
          successes.add(candidate);
        }
      } else if (failures.length < 2) {
        failures.add(candidate);
      }
      if (successes.length == 2 && failures.length == 2) {
        break;
      }
    }
    if (successes.length != 2 || failures.length != 2) {
      throw StateError('단계 ${stageIndex + 1}의 성공·실패 픽스처를 찾지 못했습니다.');
    }
    for (var index = 0; index < successes.length; index++) {
      fixtures.add(_fixture(stageIndex, successes[index], index));
    }
    for (var index = 0; index < failures.length; index++) {
      fixtures.add(_fixture(stageIndex, failures[index], index));
    }
  }

  final file = File('harness_docs/qa/replays/single_shot_fixtures.json');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ')
        .convert({'schemaVersion': 1, 'fixtures': <Map<String, Object?>>[]})
        .replaceFirst(
          '[]',
          jsonEncode(fixtures.map((item) => item.toJson()).toList()),
        ),
  );
  print('리플레이 픽스처 ${fixtures.length}개 생성: ${file.path}');
}

ReplayFixture _fixture(int stageIndex, _Candidate candidate, int index) {
  final state = candidate.initialState;
  final result = resolver.resolve(state, candidate.shot.toInput());
  final success = result.state.phase == GamePhase.success;
  return ReplayFixture(
    id: 'stage_${stageIndex + 1}_${success ? 'success' : 'failure'}_${index + 1}',
    stageIndex: stageIndex,
    routeTag: success ? candidate.routeTag : 'failure',
    shots: [candidate.shot],
    expectedFingerprints: [shotResultFingerprint(result)],
    expectedPhase: result.state.phase.name,
    copyCoreCount: state.copyCoreCount,
    transferSourceId: candidate.transferSourceId,
  );
}

Iterable<_Candidate> _candidates(int stageIndex, GameState state) sync* {
  if (stageIndex == 4) {
    const traits = TraitResolver();
    for (final source in state.traitSources) {
      final transferred = traits.transferSelectedTrait(
        traits.selectSource(state, source.id),
      );
      for (var degree = -180; degree < 180; degree += 5) {
        for (var step = 1; step <= 20; step++) {
          yield _Candidate(
            shot: ReplayShotFixture(
              angleRadians: degree * math.pi / 180,
              power: step / 20,
              equippedTrait: transferred.equippedTrait,
            ),
            routeTag: 'drained_source',
            initialState: transferred,
            transferSourceId: source.id,
          );
        }
      }
    }
    return;
  }
  final preferred = switch (stageIndex) {
    0 => TraitType.heavy,
    1 => TraitType.bouncy,
    2 => TraitType.sticky,
    3 => TraitType.sharp,
    _ => null,
  };
  final traits = <TraitType?>[
    preferred,
    null,
    ...TraitType.values.where((trait) => trait != preferred),
  ];
  for (final trait in traits) {
    for (var degree = -180; degree < 180; degree += 5) {
      final minimumStep = stageIndex == 6 ? 6 : 1;
      final maximumStep = stageIndex == 6 ? 50 : 20;
      final divisor = stageIndex == 6 ? 50 : 20;
      for (var step = minimumStep; step <= maximumStep; step++) {
        final shot = ReplayShotFixture(
          angleRadians: degree * math.pi / 180,
          power: step / divisor,
          equippedTrait: trait,
        );
        yield _Candidate(
          shot: shot,
          routeTag: _routeTag(stageIndex, trait, preferred),
          initialState: state,
        );
      }
    }
  }
}

String _routeTag(int stageIndex, TraitType? trait, TraitType? preferred) {
  if (trait == preferred && preferred != null) {
    return 'recommended';
  }
  if (trait == null) {
    return stageIndex == 0 ? 'direct' : 'alternate';
  }
  return 'alternate';
}

class _Candidate {
  const _Candidate({
    required this.shot,
    required this.routeTag,
    required this.initialState,
    this.transferSourceId,
  });

  final ReplayShotFixture shot;
  final String routeTag;
  final GameState initialState;
  final String? transferSourceId;
}
