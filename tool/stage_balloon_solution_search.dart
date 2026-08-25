import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main(List<String> arguments) {
  if (arguments.contains('--source-layouts')) {
    _searchSourceLayouts();
    return;
  }
  if (arguments.contains('--advantage-inputs')) {
    _printAdvantageInputs();
    return;
  }
  if (arguments.contains('--bypass-filter-layouts')) {
    _searchBypassFilterLayouts();
    return;
  }
  if (arguments.contains('--balloon3-sizes')) {
    _searchBalloon3Sizes();
    return;
  }
  if (arguments.contains('--balloon3-ui-grid')) {
    _auditBalloon3UiGrid();
    return;
  }
  final noneBypass = arguments.contains('--none-bypass');
  final sharpPop = arguments.contains('--sharp');
  final doubleBalloon = arguments.contains('--double-balloon');
  final patternArguments = arguments.where(
    (argument) => !argument.startsWith('--'),
  );
  final requestedPattern = patternArguments.isEmpty
      ? (noneBypass ? 'stage_balloon_03' : 'stage_balloon_04')
      : patternArguments.first;
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_balloon');
  final pattern = stage.patternById(requestedPattern);
  var state = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(3);
  if (sharpPop) {
    const traits = TraitResolver();
    state = traits.transferSelectedTrait(
      traits.selectSource(state, 'spike_source'),
    );
  }
  const resolver = ShotResolver();
  final candidates = <_Candidate>[];

  for (var degree = 0; degree < 360; degree += 2) {
    for (var powerStep = 12; powerStep <= 100; powerStep += 2) {
      final power = powerStep / 100;
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: _directionFor(degree),
          power: power,
          equippedTrait: state.equippedTrait,
        ),
      );
      final impactIds = result.impacts
          .map((impact) => impact.entityId)
          .toList();
      final matchesFamily = sharpPop
          ? result.events.contains('balloon_popped') &&
                result.events.contains('sharpness_consumed') &&
                (!doubleBalloon ||
                    (result.events.contains('balloon_bounced') &&
                        impactIds.contains('balloon_b') &&
                        impactIds.indexOf('balloon') >
                            impactIds.indexOf('balloon_b')))
          : noneBypass
          ? !result.events.contains('balloon_bounced') &&
                !result.events.contains('balloon_popped') &&
                !result.impacts.any((impact) => impact.entityId == 'balloon')
          : result.events.contains('balloon_bounced') &&
                !result.events.contains('balloon_popped');
      if (result.state.phase != GamePhase.success || !matchesFamily) {
        continue;
      }
      final neighborhood = _neighborhoodSuccesses(
        resolver: resolver,
        state: state,
        degree: degree,
        power: power,
      );
      if (neighborhood >= 3) {
        candidates.add(
          _Candidate(
            degree: degree,
            power: power,
            neighborhood: neighborhood,
            impacts: result.impacts.map((impact) => impact.entityId).toList(),
          ),
        );
      }
    }
  }

  candidates.sort((left, right) {
    final robustness = right.neighborhood.compareTo(left.neighborhood);
    if (robustness != 0) return robustness;
    return left.power.compareTo(right.power);
  });
  stdout.writeln(
    '$requestedPattern: robust ${sharpPop
        ? "sharp-pop"
        : noneBypass
        ? "none-bypass"
        : "balloon-bounce"} '
    'candidates=${candidates.length}',
  );
  for (final candidate in candidates.take(30)) {
    stdout.writeln(
      '  ${candidate.degree}/${candidate.power.toStringAsFixed(2)} '
      'near=${candidate.neighborhood}/15 '
      'impacts=${candidate.impacts.join(",")}',
    );
  }
}

void _auditBalloon3UiGrid() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_balloon');
  final pattern = stage.patternById('stage_balloon_03');
  final none = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(3, productRules: true);
  const traits = TraitResolver();
  final sharp = traits.transferSelectedTrait(
    traits.selectSource(none, 'spike_source'),
  );
  const resolver = ShotResolver();
  var noneCount = 0;
  var sharpCount = 0;
  for (var degree = 0; degree < 360; degree += 4) {
    for (var tick = 0; tick <= 16; tick++) {
      final power = (0.12 + 0.055 * tick).clamp(0.12, 1.0).toDouble();
      final input = ShotInput(direction: _directionFor(degree), power: power);
      if (resolver.resolve(none, input).state.phase == GamePhase.success) {
        noneCount++;
      }
      if (resolver
              .resolve(
                sharp,
                ShotInput(
                  direction: input.direction,
                  power: input.power,
                  equippedTrait: sharp.equippedTrait,
                ),
              )
              .state
              .phase ==
          GamePhase.success) {
        sharpCount++;
      }
    }
  }
  stdout.writeln(
    'stage_balloon_03 UI grid sharp=$sharpCount none=$noneCount '
    'ratio=${(sharpCount / math.max(1, noneCount)).toStringAsFixed(3)}',
  );
}

void _searchBalloon3Sizes() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_balloon');
  final pattern = stage.patternById('stage_balloon_03');
  final base = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(3, productRules: true);
  const traits = TraitResolver();
  const resolver = ShotResolver();
  for (final width in const [52.0, 58.0, 64.0, 70.0, 76.0, 82.0]) {
    for (final height in const [58.0, 64.0, 70.0, 76.0, 82.0, 88.0]) {
      final none = base.copyWith(
        entities: [
          for (final entity in base.entities)
            if (entity.id == 'balloon')
              entity.copyWith(size: Vec2(width, height))
            else
              entity,
        ],
      );
      final sharp = traits.transferSelectedTrait(
        traits.selectSource(none, 'spike_source'),
      );
      final noneCount = _gridSuccesses(resolver, none);
      final sharpCount = _gridSuccesses(resolver, sharp);
      final ratio = sharpCount / math.max(1, noneCount);
      if (sharpCount >= 9 && ratio >= 1.4) {
        stdout.writeln(
          'balloon=${width.toInt()}x${height.toInt()} '
          'sharp=$sharpCount none=$noneCount ratio=${ratio.toStringAsFixed(2)}',
        );
      }
    }
  }
}

void _searchBypassFilterLayouts() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_balloon');
  final pattern = stage.patternById('stage_balloon_03');
  final base = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(3, productRules: true);
  const resolver = ShotResolver();
  final candidates = <_FilterCandidate>[];

  for (final x in [125.0, 140.0, 155.0, 170.0]) {
    for (final y in [320.0, 340.0, 360.0, 380.0]) {
      for (final size in const [Vec2(14, 50), Vec2(18, 60), Vec2(22, 80)]) {
        final none = base.copyWith(
          entities: [
            for (final entity in base.entities)
              if (entity.id == 'balloon_03_bypass_filter')
                entity.copyWith(position: Vec2(x, y), size: size)
              else
                entity,
          ],
        );
        const traits = TraitResolver();
        final sharp = traits.transferSelectedTrait(
          traits.selectSource(none, 'spike_source'),
        );
        final sharpSuccesses = _gridSuccesses(resolver, sharp);
        final noneSuccesses = _gridSuccesses(resolver, none);
        final localNoneSuccesses = _localFamilySuccesses(
          resolver: resolver,
          state: none,
          degree: 202,
          power: 0.835,
        );
        final ratio = noneSuccesses == 0
            ? double.infinity
            : sharpSuccesses / noneSuccesses;
        if (sharpSuccesses >= 3 && ratio >= 1.4 && localNoneSuccesses >= 3) {
          candidates.add(
            _FilterCandidate(
              position: Vec2(x, y),
              size: size,
              sharpSuccesses: sharpSuccesses,
              noneSuccesses: noneSuccesses,
              localNoneSuccesses: localNoneSuccesses,
            ),
          );
        }
      }
    }
  }
  candidates.sort((left, right) {
    final local = right.localNoneSuccesses.compareTo(left.localNoneSuccesses);
    if (local != 0) return local;
    return right.ratio.compareTo(left.ratio);
  });
  stdout.writeln('valid bypass filters=${candidates.length}');
  for (final candidate in candidates.take(30)) {
    stdout.writeln(candidate);
  }
}

int _gridSuccesses(ShotResolver resolver, GameState state) {
  var successes = 0;
  for (var degree = 0; degree < 360; degree += 4) {
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: _directionFor(degree),
          power: powerStep / 10,
          equippedTrait: state.equippedTrait,
        ),
      );
      if (result.state.phase == GamePhase.success) successes++;
    }
  }
  return successes;
}

int _localFamilySuccesses({
  required ShotResolver resolver,
  required GameState state,
  required int degree,
  required double power,
}) {
  var successes = 0;
  for (final degreeDelta in [-2, 0, 2]) {
    for (final powerDelta in [-0.04, -0.02, 0.0, 0.02, 0.04]) {
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: _directionFor((degree + degreeDelta) % 360),
          power: power + powerDelta,
        ),
      );
      if (result.state.phase == GamePhase.success &&
          !result.events.contains('balloon_bounced') &&
          !result.events.contains('balloon_popped')) {
        successes++;
      }
    }
  }
  return successes;
}

void _printAdvantageInputs() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_balloon');
  final pattern = stage.patternById('stage_balloon_03');
  final none = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(3, productRules: true);
  const traits = TraitResolver();
  final sharp = traits.transferSelectedTrait(
    traits.selectSource(none, 'spike_source'),
  );
  const resolver = ShotResolver();
  for (final entry in [('none', none), ('sharp', sharp)]) {
    stdout.writeln('${entry.$1}:');
    for (var degree = 0; degree < 360; degree += 4) {
      for (var powerStep = 1; powerStep <= 10; powerStep++) {
        final input = ShotInput(
          direction: _directionFor(degree),
          power: powerStep / 10,
          equippedTrait: entry.$2.equippedTrait,
        );
        final result = resolver.resolve(entry.$2, input);
        if (result.state.phase == GamePhase.success) {
          stdout.writeln(
            '  $degree/${input.power.toStringAsFixed(1)} '
            'events=${result.events.join(",")} '
            'impacts=${result.impacts.map((impact) => impact.entityId).join(",")} '
            'path=${[for (var index = 0; index < result.path.length; index += 12) '${result.path[index].x.toStringAsFixed(0)}:${result.path[index].y.toStringAsFixed(0)}', if (result.path.isNotEmpty) '${result.path.last.x.toStringAsFixed(0)}:${result.path.last.y.toStringAsFixed(0)}'].join(">")}',
          );
        }
      }
    }
  }
}

void _searchSourceLayouts() {
  final catalog = StageCatalog.fromJsonString(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  final stage = catalog.stageById('stage_balloon');
  final pattern = stage.patternById('stage_balloon_03');
  final base = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(3, productRules: true);
  const resolver = ShotResolver();
  final candidates = <_LayoutCandidate>[];

  for (final x in [50.0, 80.0, 110.0, 140.0, 170.0, 200.0]) {
    for (final y in [60.0, 100.0, 140.0, 180.0, 220.0, 260.0]) {
      final none = base.copyWith(
        entities: [
          for (final entity in base.entities)
            if (entity.id == 'spike_source')
              entity.copyWith(position: Vec2(x, y))
            else
              entity,
        ],
      );
      const traits = TraitResolver();
      final sharp = traits.transferSelectedTrait(
        traits.selectSource(none, 'spike_source'),
      );
      var sharpSuccesses = 0;
      var noneSuccesses = 0;
      for (var degree = 0; degree < 360; degree += 4) {
        for (var powerStep = 1; powerStep <= 10; powerStep++) {
          final input = ShotInput(
            direction: _directionFor(degree),
            power: powerStep / 10,
          );
          if (resolver
                  .resolve(
                    sharp,
                    ShotInput(
                      direction: input.direction,
                      power: input.power,
                      equippedTrait: sharp.equippedTrait,
                    ),
                  )
                  .state
                  .phase ==
              GamePhase.success) {
            sharpSuccesses++;
          }
          if (resolver.resolve(none, input).state.phase == GamePhase.success) {
            noneSuccesses++;
          }
        }
      }
      candidates.add(
        _LayoutCandidate(
          position: Vec2(x, y),
          sharpSuccesses: sharpSuccesses,
          noneSuccesses: noneSuccesses,
        ),
      );
    }
  }
  candidates.sort((left, right) {
    final ratioOrder = right.ratio.compareTo(left.ratio);
    if (ratioOrder != 0) return ratioOrder;
    return right.sharpSuccesses.compareTo(left.sharpSuccesses);
  });
  for (final candidate in candidates.take(24)) {
    stdout.writeln(candidate);
  }
}

int _neighborhoodSuccesses({
  required ShotResolver resolver,
  required GameState state,
  required int degree,
  required double power,
}) {
  var successes = 0;
  for (final degreeDelta in [-2, 0, 2]) {
    for (final powerDelta in [-0.04, -0.02, 0.0, 0.02, 0.04]) {
      final candidatePower = power + powerDelta;
      if (candidatePower < 0.12 || candidatePower > 1) continue;
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: _directionFor((degree + degreeDelta) % 360),
          power: candidatePower,
          equippedTrait: state.equippedTrait,
        ),
      );
      if (result.state.phase == GamePhase.success) successes++;
    }
  }
  return successes;
}

Vec2 _directionFor(int degree) {
  final radians = degree * math.pi / 180;
  return Vec2(math.cos(radians), math.sin(radians));
}

class _Candidate {
  const _Candidate({
    required this.degree,
    required this.power,
    required this.neighborhood,
    required this.impacts,
  });

  final int degree;
  final double power;
  final int neighborhood;
  final List<String> impacts;
}

class _LayoutCandidate {
  const _LayoutCandidate({
    required this.position,
    required this.sharpSuccesses,
    required this.noneSuccesses,
  });

  final Vec2 position;
  final int sharpSuccesses;
  final int noneSuccesses;

  double get ratio =>
      noneSuccesses == 0 ? double.infinity : sharpSuccesses / noneSuccesses;

  @override
  String toString() =>
      'source=${position.x.toInt()},${position.y.toInt()} '
      'sharp=$sharpSuccesses none=$noneSuccesses '
      'ratio=${ratio.toStringAsFixed(2)}';
}

class _FilterCandidate {
  const _FilterCandidate({
    required this.position,
    required this.size,
    required this.sharpSuccesses,
    required this.noneSuccesses,
    required this.localNoneSuccesses,
  });

  final Vec2 position;
  final Vec2 size;
  final int sharpSuccesses;
  final int noneSuccesses;
  final int localNoneSuccesses;

  double get ratio =>
      noneSuccesses == 0 ? double.infinity : sharpSuccesses / noneSuccesses;

  @override
  String toString() =>
      'filter=${position.x.toInt()},${position.y.toInt()} '
      'size=${size.x.toInt()}x${size.y.toInt()} '
      'sharp=$sharpSuccesses none=$noneSuccesses '
      'ratio=${ratio.toStringAsFixed(2)} local=$localNoneSuccesses/15';
}
