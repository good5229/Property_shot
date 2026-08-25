// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main(List<String> arguments) {
  const resolver = ShotResolver();
  const traits = TraitResolver();
  final stage = generatedStageCatalog.stageById('stage_property_shot');

  if (arguments.contains('--D-first')) {
    final pattern = stage.patternById('stage_property_shot_d');
    _searchCurrentDFirst(resolver, _state(stage.stageId, stage.title, pattern));
    return;
  }

  for (final pattern in stage.patterns) {
    final initial = _state(stage.stageId, stage.title, pattern);
    final direct = _findSingle(resolver, initial);
    print('${pattern.patternId} direct=${_describe(direct)}');
    if (pattern.patternId == 'stage_property_shot_b') {
      final bypass = _findSingle(
        resolver,
        initial,
        forbiddenIds: const {'b_slider', 'b_reflector', 'b_bumper'},
        forbiddenEvents: const {
          'power_slider_activated',
          'reflector_rotated',
          'jelly_bounced',
        },
      );
      print('${pattern.patternId} bypass=${_describe(bypass)}');
      _searchCurrentBDirect(resolver, initial);
      _auditCurrentBNeighborhood(resolver, initial);
    }
    if (pattern.patternId == 'stage_property_shot_c') {
      _searchCurrentCBank(resolver, traits, initial);
    }

    if (pattern.patternId == 'stage_property_shot_a') {
      final selected = traits.selectSource(initial, 'a_stone');
      final transferred = traits.transferSelectedTrait(selected);
      final heavy = _findSingle(
        resolver,
        transferred,
        equippedTrait: TraitType.heavy,
      );
      print('${pattern.patternId} heavy_transfer=${_describe(heavy)}');
      for (final input in [
        _input(27, 0.86, TraitType.heavy),
        _input(236, 0.76, TraitType.heavy),
        _input(266, 0.20, TraitType.heavy),
      ]) {
        final result = resolver.resolve(transferred, input);
        print(
          '${pattern.patternId} heavy_candidate=${_inputLabel(input)} '
          'phase=${result.state.phase.name} events=${result.events} '
          'impacts=${result.impacts.map((i) => i.entityId).join(',')}',
        );
      }
    }
    for (final candidate in _knownCandidates[pattern.patternId] ?? const []) {
      var state = initial;
      if (pattern.patternId == 'stage_property_shot_c') {
        final selected = traits.selectSource(state, 'c_sticky');
        state = traits.transferSelectedTrait(selected);
      }
      final results = <ShotResult>[];
      for (final input in candidate) {
        final result = resolver.resolve(state, input);
        results.add(result);
        state = result.state;
        final spent = state.entityById('spent_ball_${state.shotCount}');
        print(
          '  shot=${_inputLabel(input)} end='
          '${result.path.last.x.toStringAsFixed(1)},'
          '${result.path.last.y.toStringAsFixed(1)} spent='
          '${spent == null ? '-' : '${spent.position.x.toStringAsFixed(1)},${spent.position.y.toStringAsFixed(1)}'}',
        );
      }
      print(
        '${pattern.patternId} candidate=${candidate.map(_inputLabel).join(' -> ')} '
        'phase=${results.last.state.phase.name} events=${results.map((r) => r.events).join(' | ')} '
        'impacts=${results.expand((r) => r.impacts.map((i) => '${i.entityId}@'
            '${i.position.x.toStringAsFixed(0)},${i.position.y.toStringAsFixed(0)}')).join(',')}',
      );
      for (final id in const [
        'a_crate',
        'a_switch',
        'a_gate',
        'b_bumper',
        'c_balloon',
        'c_sticky',
        'spent_ball_1',
      ]) {
        final entity = state.entityById(id);
        if (entity != null) {
          print(
            '  $id=${entity.position.x.toStringAsFixed(1)},'
            '${entity.position.y.toStringAsFixed(1)} '
            'pressed=${entity.pressed} open=${entity.open} '
            'state=${entity.visualState}',
          );
        }
      }
    }
  }

  if (arguments.contains('--배치-탐색') || arguments.contains('--A-탐색')) {
    _searchContractA(stage);
  }
  if (arguments.contains('--배치-탐색') || arguments.contains('--B-탐색')) {
    _searchContractB(stage);
  }
  if (arguments.contains('--배치-탐색') || arguments.contains('--C-탐색')) {
    _searchContractC(stage);
  }
}

void _searchCurrentBDirect(ShotResolver resolver, GameState initial) {
  var found = 0;
  for (var degree = 0; degree < 360 && found < 12; degree++) {
    for (var powerIndex = 6; powerIndex <= 50 && found < 12; powerIndex++) {
      final result = resolver.resolve(initial, _input(degree, powerIndex / 50));
      final ids = result.impacts.map((impact) => impact.entityId).toSet();
      if (result.state.phase == GamePhase.success &&
          result.events.contains('power_slider_activated') &&
          result.events.contains('slider_gate_opened') &&
          !ids.contains('b_reflector')) {
        print(
          'B_DIRECT degree=$degree power=${powerIndex * 2}% '
          'events=${result.events} impacts=${ids.join(',')}',
        );
        found++;
      }
    }
  }
}

void _auditCurrentBNeighborhood(ShotResolver resolver, GameState initial) {
  var matches = 0;
  for (var firstDegree = 309; firstDegree <= 315; firstDegree++) {
    for (var firstPower = 6; firstPower <= 9; firstPower++) {
      final first = resolver.resolve(
        initial,
        _input(firstDegree, firstPower / 50),
      );
      for (var secondDegree = 291; secondDegree <= 297; secondDegree++) {
        for (var secondPower = 43; secondPower <= 49; secondPower++) {
          final second = resolver.resolve(
            first.state,
            _input(secondDegree, secondPower / 50),
          );
          final ids = second.impacts.map((impact) => impact.entityId).toList();
          final reflectorIndex = ids.indexOf('b_reflector');
          final bumperIndex = ids.indexOf('b_bumper');
          if (first.powerSliderActivations.isNotEmpty &&
              first.reflectorRotations.isNotEmpty &&
              second.state.phase == GamePhase.success &&
              second.events.contains('jelly_bounced') &&
              reflectorIndex >= 0 &&
              bumperIndex > reflectorIndex) {
            if (matches < 20) {
              print(
                'B_NEAR first=$firstDegree/${firstPower * 2}% '
                'second=$secondDegree/${secondPower * 2}%',
              );
            }
            matches++;
          }
        }
      }
    }
  }
  print('B_NEAR total=$matches');
}

void _searchCurrentCBank(
  ShotResolver resolver,
  TraitResolver traits,
  GameState initial,
) {
  final prepared = traits.transferSelectedTrait(
    traits.selectSource(initial, 'c_sticky'),
  );
  final first = resolver.resolve(prepared, _input(0, 0.12, TraitType.sticky));
  final canonical = resolver.resolve(first.state, _input(12, 0.86));
  final canonicalIds = canonical.impacts
      .map((impact) => impact.entityId)
      .toList();
  var found = 0;
  for (var degree = 0; degree < 360 && found < 12; degree++) {
    for (var powerIndex = 6; powerIndex <= 50 && found < 12; powerIndex++) {
      final result = resolver.resolve(
        first.state,
        _input(degree, powerIndex / 50),
      );
      final ids = result.impacts.map((impact) => impact.entityId).toList();
      if (result.state.phase == GamePhase.success &&
          !_sameList(ids, canonicalIds)) {
        print(
          'C_BANK degree=$degree power=${powerIndex * 2}% '
          'events=${result.events} impacts=${ids.join(',')}',
        );
        found++;
      }
    }
  }
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var index = 0; index < a.length; index++) {
    if (a[index] != b[index]) return false;
  }
  return true;
}

void _searchCurrentDFirst(ShotResolver resolver, GameState initial) {
  final candidates = <({int degree, double power, int local})>[];
  for (var degree = 260; degree <= 300; degree++) {
    for (var powerIndex = 15; powerIndex <= 30; powerIndex++) {
      final power = powerIndex / 50;
      final centerFirst = resolver.resolve(initial, _input(degree, power));
      if (centerFirst.state.phase == GamePhase.success) continue;
      final centerSecond = resolver.resolve(
        centerFirst.state,
        _input(307, 0.86),
      );
      if (!_matchesCurrentD(centerFirst, centerSecond)) continue;
      var local = 0;
      for (final degreeDelta in const [-2, 0, 2]) {
        for (final powerDelta in const [-0.04, -0.02, 0.0, 0.02, 0.04]) {
          final first = resolver.resolve(
            initial,
            _input(degree + degreeDelta, power + powerDelta),
          );
          if (first.state.phase == GamePhase.success) continue;
          final second = resolver.resolve(first.state, _input(307, 0.86));
          if (_matchesCurrentD(first, second)) {
            local++;
          }
        }
      }
      if (local >= 3) {
        candidates.add((degree: degree, power: power, local: local));
      }
    }
  }
  candidates.sort((left, right) => right.local.compareTo(left.local));
  for (final candidate in candidates.take(20)) {
    print(
      'D_FIRST degree=${candidate.degree} '
      'power=${candidate.power.toStringAsFixed(2)} local=${candidate.local}/15',
    );
  }
}

bool _matchesCurrentD(ShotResult first, ShotResult second) {
  final ids = [
    ...first.impacts,
    ...second.impacts,
  ].map((impact) => impact.entityId).toSet();
  final sliders = [
    ...first.powerSliderActivations,
    ...second.powerSliderActivations,
  ];
  return first.state.phase != GamePhase.success &&
      second.state.phase == GamePhase.success &&
      sliders.isNotEmpty &&
      ids.contains('d_stone') &&
      ids.contains('spent_ball_1');
}

void _searchContractA(StageDefinition stage) {
  const resolver = ShotResolver();
  const traits = TraitResolver();
  final pattern = stage.patternById('stage_property_shot_a');
  final initial = _state(stage.stageId, stage.title, pattern);
  final prepared = traits.transferSelectedTrait(
    traits.selectSource(initial, 'a_stone'),
  );
  var found = 0;
  for (var firstDegree = 0; firstDegree < 360 && found < 12; firstDegree++) {
    for (var firstPower = 6; firstPower <= 50 && found < 12; firstPower++) {
      final first = resolver.resolve(
        prepared,
        _input(firstDegree, firstPower / 50, TraitType.heavy),
      );
      final cratePressed = first.impacts.any(
        (impact) =>
            impact.sourceEntityId == 'a_crate' && impact.entityId == 'a_switch',
      );
      if (first.state.phase != GamePhase.planning ||
          !first.events.contains('switch_pressed') ||
          !cratePressed) {
        continue;
      }
      var paired = false;
      for (
        var secondDegree = 0;
        secondDegree < 360 && !paired;
        secondDegree++
      ) {
        for (var secondPower = 6; secondPower <= 50; secondPower++) {
          final second = resolver.resolve(
            first.state,
            _input(secondDegree, secondPower / 50),
          );
          if (second.state.phase != GamePhase.success) continue;
          print(
            'A_SEARCH first=$firstDegree/${firstPower * 2}% '
            'second=$secondDegree/${secondPower * 2}% '
            'events=${[...first.events, ...second.events]} impacts='
            '${[...first.impacts, ...second.impacts].map((impact) => '${impact.sourceEntityId}>${impact.entityId}').join(',')}',
          );
          found++;
          paired = true;
          break;
        }
      }
    }
  }
}

void _searchContractB(StageDefinition stage) {
  const resolver = ShotResolver();
  final pattern = stage.patternById('stage_property_shot_b');
  final initial = _state(stage.stageId, stage.title, pattern);
  var found = 0;
  for (var y = 100; y <= 260 && found < 12; y += 20) {
    for (var x = 180; x <= 320 && found < 12; x += 20) {
      final moved = _moveEntity(
        initial,
        'b_bumper',
        Vec2(x.toDouble(), y.toDouble()),
      );
      final first = resolver.resolve(moved, _input(312, 0.12));
      if (first.state.phase != GamePhase.planning ||
          first.reflectorRotations.isEmpty ||
          first.powerSliderActivations.isEmpty) {
        continue;
      }
      for (var degree = 0; degree < 360 && found < 12; degree += 2) {
        for (var power = 6; power <= 50 && found < 12; power += 2) {
          final second = resolver.resolve(
            first.state,
            _input(degree, power / 50),
          );
          final ids = second.impacts.map((impact) => impact.entityId).toSet();
          if (second.state.phase == GamePhase.success &&
              ids.contains('b_reflector') &&
              ids.contains('b_bumper') &&
              second.events.contains('jelly_bounced')) {
            print(
              'B_SEARCH bumper=$x,$y second=$degree/${power * 2}% '
              'events=${second.events} impacts=${second.impacts.map((impact) => '${impact.sourceEntityId}>${impact.entityId}@${impact.position.x.toStringAsFixed(0)},${impact.position.y.toStringAsFixed(0)}').join(',')}',
            );
            found++;
          }
        }
      }
    }
  }
}

void _searchContractC(StageDefinition stage) {
  const resolver = ShotResolver();
  const traits = TraitResolver();
  final pattern = stage.patternById('stage_property_shot_c');
  final initial = _state(stage.stageId, stage.title, pattern);
  final targetPositions = <Vec2>[
    const Vec2(100, 480),
    const Vec2(120, 480),
    const Vec2(140, 480),
    const Vec2(160, 480),
    const Vec2(180, 480),
    const Vec2(200, 480),
  ];
  var found = 0;
  for (final position in targetPositions) {
    final withTarget = _moveEntity(initial, 'c_sticky_target', position);
    final prepared = traits.transferSelectedTrait(
      traits.selectSource(withTarget, 'c_sticky'),
    );
    final first = resolver.resolve(prepared, _input(0, 0.12, TraitType.sticky));
    if (first.state.phase != GamePhase.planning ||
        !first.events.contains('sticky_attached') ||
        !first.impacts.any((impact) => impact.entityId == 'c_sticky_target')) {
      continue;
    }
    for (var degree = 0; degree < 360 && found < 16; degree++) {
      for (var powerIndex = 6; powerIndex <= 50 && found < 16; powerIndex++) {
        final second = resolver.resolve(
          first.state,
          _input(degree, powerIndex / 50),
        );
        final spentHit = second.impacts.any(
          (impact) => impact.entityId == 'spent_ball_1',
        );
        final crateBalloon = second.impacts.any(
          (impact) =>
              impact.sourceEntityId == 'c_crate' &&
              impact.entityId == 'c_balloon',
        );
        if (second.state.phase == GamePhase.success &&
            spentHit &&
            crateBalloon) {
          print(
            'C_SEARCH target=${position.x.toInt()},${position.y.toInt()} '
            'second=$degree/${powerIndex * 2}% events=${second.events} impacts='
            '${second.impacts.map((impact) => '${impact.sourceEntityId}>${impact.entityId}@${impact.position.x.toStringAsFixed(0)},${impact.position.y.toStringAsFixed(0)}').join(',')}',
          );
          found++;
        }
      }
    }
  }
}

GameState _moveEntity(GameState state, String id, Vec2 position) {
  return state.copyWith(
    entities: [
      for (final entity in state.entities)
        if (entity.id == id) entity.copyWith(position: position) else entity,
    ],
  );
}

({ShotInput input, ShotResult result})? _findSingle(
  ShotResolver resolver,
  GameState state, {
  Set<String> forbiddenIds = const {},
  Set<String> forbiddenEvents = const {},
  TraitType? equippedTrait,
}) {
  for (var degree = 0; degree < 360; degree++) {
    for (var powerIndex = 6; powerIndex <= 50; powerIndex++) {
      final input = _input(degree, powerIndex / 50, equippedTrait);
      final result = resolver.resolve(state, input);
      final impactIds = result.impacts
          .expand((impact) => [impact.sourceEntityId, impact.entityId])
          .toSet();
      if (result.state.phase == GamePhase.success &&
          impactIds.intersection(forbiddenIds).isEmpty &&
          result.events.toSet().intersection(forbiddenEvents).isEmpty) {
        return (input: input, result: result);
      }
    }
  }
  return null;
}

String _describe(({ShotInput input, ShotResult result})? found) {
  if (found == null) return '없음';
  return '${_inputLabel(found.input)} 성공 '
      'events=${found.result.events.join(',')} '
      'impacts=${found.result.impacts.map((i) => i.entityId).join(',')}';
}

GameState _state(String stageId, String title, StagePattern pattern) => pattern
    .toLevelDefinition(stageId: stageId, stageTitle: title)
    .createState(9, productRules: true);

ShotInput _input(int degree, double power, [TraitType? trait]) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
    equippedTrait: trait,
  );
}

String _inputLabel(ShotInput input) {
  final degree =
      (math.atan2(input.direction.y, input.direction.x) * 180 / math.pi)
          .round();
  return '$degree/${(input.power * 100).round()}%';
}

final _knownCandidates = <String, List<List<ShotInput>>>{
  'stage_property_shot_a': [
    [_input(27, 0.86, TraitType.heavy), _input(43, 0.88)],
    [_input(266, 0.20)],
  ],
  'stage_property_shot_b': [
    [_input(312, 0.12), _input(203, 0.70)],
    [_input(239, 0.74)],
  ],
  'stage_property_shot_c': [
    [_input(0, 0.12, TraitType.sticky), _input(346, 0.86)],
    [_input(298, 0.38)],
  ],
  'stage_property_shot_d': [
    [_input(280, 0.42), _input(312, 0.84)],
    [_input(266, 0.32)],
  ],
};
