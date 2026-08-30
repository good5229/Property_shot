import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  final catalog = stageCatalogFromJson(
    File('assets/stages/chapter_1.json').readAsStringSync(),
  );
  const resolver = ShotResolver();
  final stage = catalog.stageById('stage_speed');
  if (const bool.fromEnvironment('GUARD_SEARCH') ||
      const bool.fromEnvironment('ADVANTAGE_AUDIT')) {
    final pattern = stage.patternById('stage_speed_03');
    final state = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(5, productRules: true);
    if (const bool.fromEnvironment('GUARD_SEARCH')) {
      _searchStage3Guard(state, resolver);
    } else {
      _auditStage3Advantage(state, resolver);
    }
    return;
  }

  for (final pattern in stage.patterns) {
    final state = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(5, productRules: true);
    final sliders = pattern.objects
        .where((object) => object.type.name == 'powerSlider')
        .map((object) => object.id)
        .toSet();
    final all = <_Shot>{};
    final sliderShots = <_Shot>[];
    final weakSliderShots = <_Shot>[];
    final bypassShots = <_Shot>[];
    final wallSliderShots = <_Shot>[];
    final crateSliderShots = <_Shot>[];
    final sliderIds = <String, List<_Shot>>{
      for (final id in sliders) id: <_Shot>[],
    };
    final sliderSources = <String, int>{};

    for (var degree = 0; degree < 360; degree += 2) {
      final radians = degree * math.pi / 180;
      final direction = Vec2(math.cos(radians), math.sin(radians));
      for (var powerStep = 6; powerStep <= 50; powerStep++) {
        final power = powerStep / 50;
        final result = resolver.resolve(
          state,
          ShotInput(direction: direction, power: power),
        );
        if (result.state.phase != GamePhase.success) continue;
        final shot = _Shot(
          degree: degree,
          power: power,
          sliderIds: result.powerSliderActivations
              .map((activation) => activation.sliderEntityId)
              .toSet(),
          sliderSources: result.powerSliderActivations
              .map((activation) => activation.sourceEntityId)
              .toSet(),
          speedBefore: result.powerSliderActivations.isEmpty
              ? 0
              : result.powerSliderActivations.first.speedBefore,
          speedAfter: result.powerSliderActivations.isEmpty
              ? 0
              : result.powerSliderActivations.first.speedAfter,
          impacts: result.impacts.map((impact) => impact.entityId).toSet(),
          moves: result.moves.map((move) => move.entityId).toSet(),
          events: result.events.toSet(),
          contactIds: result.powerSliderActivations
              .map((activation) => activation.contactId)
              .toList(growable: false),
        );
        all.add(shot);
        if (shot.sliderIds.isEmpty) {
          bypassShots.add(shot);
        } else {
          sliderShots.add(shot);
          if (power <= 0.4) weakSliderShots.add(shot);
          for (final id in shot.sliderIds) {
            sliderIds[id]?.add(shot);
          }
          for (final source in shot.sliderSources) {
            sliderSources[source] = (sliderSources[source] ?? 0) + 1;
          }
          if (shot.impacts.any((id) => id.contains('wall'))) {
            wallSliderShots.add(shot);
          }
          if (shot.sliderSources.any((id) => id.contains('crate'))) {
            crateSliderShots.add(shot);
          }
        }
      }
    }

    final representative = _firstBy(sliderShots, (shot) {
      if (pattern.patternId.endsWith('_02')) {
        return shot.impacts.contains('bank_wall');
      }
      if (pattern.patternId.endsWith('_03')) {
        return shot.events.contains('crate_pushed') &&
            !shot.events.contains('chain_safety_stop');
      }
      return true;
    });
    stdout.writeln(
      jsonEncode({
        'patternId': pattern.patternId,
        'successes': all.length,
        'sliderSuccesses': sliderShots.length,
        'weakSliderSuccesses': weakSliderShots.length,
        'bypassSuccesses': bypassShots.length,
        'wallSliderSuccesses': wallSliderShots.length,
        'crateSliderSuccesses': crateSliderShots.length,
        'sliderIds': {
          for (final entry in sliderIds.entries) entry.key: entry.value.length,
        },
        'sliderSources': sliderSources,
        'leftSlider': _firstBy(
          sliderShots,
          (shot) =>
              shot.sliderIds.length == 1 &&
              shot.sliderIds.contains('left_slider'),
        )?.toJson(),
        'rightSlider': _firstBy(
          sliderShots,
          (shot) =>
              shot.sliderIds.length == 1 &&
              shot.sliderIds.contains('right_slider'),
        )?.toJson(),
        'representative': representative?.toJson(),
        'weak': _firstBy(
          weakSliderShots,
          (shot) => pattern.patternId.endsWith('_02')
              ? shot.impacts.contains('bank_wall')
              : pattern.patternId.endsWith('_03')
              ? true
              : true,
        )?.toJson(),
        'bypass': bypassShots.isEmpty ? null : bypassShots.first.toJson(),
        'cratePushSuccess': _firstBy(
          all,
          (shot) => shot.events.contains('crate_pushed'),
        )?.toJson(),
      }),
    );
  }
}

void _searchStage3Guard(GameState state, ShotResolver resolver) {
  for (final restitution in const [0.68, 0.72, 0.76, 0.78, 0.84, 0.92, 1.0]) {
    final variant = state.copyWith(
      entities: [
        for (final entity in state.entities)
          if (entity.id == 'speed_03_direct_guard')
            entity.copyWith(restitution: restitution)
          else
            entity,
      ],
    );
    var slider = 0;
    var bypass = 0;
    for (var degree = 0; degree < 360; degree += 4) {
      final radians = degree * math.pi / 180;
      for (var powerStep = 1; powerStep <= 10; powerStep++) {
        final result = resolver.resolve(
          variant,
          ShotInput(
            direction: Vec2(math.cos(radians), math.sin(radians)),
            power: powerStep / 10,
          ),
        );
        if (result.state.phase != GamePhase.success) continue;
        if (result.powerSliderActivations.isEmpty) {
          bypass++;
        } else {
          slider++;
        }
      }
    }
    final alternative = resolver.resolve(
      variant,
      ShotInput(
        direction: Vec2(
          math.cos(68 * math.pi / 180),
          math.sin(68 * math.pi / 180),
        ),
        power: 0.70,
      ),
    );
    stdout.writeln(
      'guard restitution=$restitution slider=$slider bypass=$bypass '
      'ratio=${(slider / math.max(1, bypass)).toStringAsFixed(2)} '
      'alternative=${alternative.state.phase.name}',
    );
  }
}

void _auditStage3Advantage(GameState state, ShotResolver resolver) {
  for (var degree = 0; degree < 360; degree += 4) {
    final radians = degree * math.pi / 180;
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: Vec2(math.cos(radians), math.sin(radians)),
          power: powerStep / 10,
        ),
      );
      if (result.state.phase != GamePhase.success) continue;
      stdout.writeln(
        '${result.powerSliderActivations.isEmpty ? 'BYPASS' : 'SLIDER'} '
        '$degree/${powerStep * 10}% '
        '${result.impacts.map((impact) => impact.entityId).join('>')}',
      );
    }
  }
}

_Shot? _firstBy(Iterable<_Shot> shots, bool Function(_Shot) predicate) {
  for (final shot in shots) {
    if (predicate(shot)) return shot;
  }
  return null;
}

class _Shot {
  const _Shot({
    required this.degree,
    required this.power,
    required this.sliderIds,
    required this.sliderSources,
    required this.speedBefore,
    required this.speedAfter,
    required this.impacts,
    required this.moves,
    required this.events,
    required this.contactIds,
  });

  final int degree;
  final double power;
  final Set<String> sliderIds;
  final Set<String> sliderSources;
  final double speedBefore;
  final double speedAfter;
  final Set<String> impacts;
  final Set<String> moves;
  final Set<String> events;
  final List<String> contactIds;

  Map<String, Object> toJson() => {
    'degree': degree,
    'power': double.parse(power.toStringAsFixed(3)),
    'sliderIds': sliderIds.toList()..sort(),
    'sliderSources': sliderSources.toList()..sort(),
    'speedBefore': double.parse(speedBefore.toStringAsFixed(3)),
    'speedAfter': double.parse(speedAfter.toStringAsFixed(3)),
    'impacts': impacts.toList()..sort(),
    'moves': moves.toList()..sort(),
    'events': events.toList()..sort(),
    'contactIds': contactIds,
  };
}
