// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main(List<String> arguments) {
  const resolver = ShotResolver();
  const traits = TraitResolver();
  final stage = generatedStageCatalog.stageById('stage_balloon');
  final stage3 = arguments.contains('--stage3');
  final pattern = stage.patternById(
    stage3 ? 'stage_balloon_03' : 'stage_balloon_02',
  );
  final none = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(3, productRules: true);
  final sharp = traits.transferSelectedTrait(
    traits.selectSource(none, 'spike_source'),
  );
  if (arguments.contains('--probe-gate')) {
    for (final x in const [282.0, 286.0, 290.0]) {
      final adjustedNone = _moveEntity(
        _resizeEntity(none, 'balloon_gate', const Vec2(62, 74)),
        'balloon_gate',
        Vec2(x, 176),
      );
      final adjustedSharp = _moveEntity(
        _resizeEntity(sharp, 'balloon_gate', const Vec2(62, 74)),
        'balloon_gate',
        Vec2(x, 176),
      );
      final noneCount = _countSuccesses(resolver, adjustedNone);
      final sharpCount = _countSuccesses(resolver, adjustedSharp);
      print(
        'gate62x74@$x,176 none=$noneCount sharp=$sharpCount '
        'ratio=${(sharpCount / noneCount).toStringAsFixed(3)}',
      );
    }
    return;
  }
  if (arguments.contains('--probe-tall-gate')) {
    for (final y in const [192.0, 200.0, 208.0]) {
      final adjustedNone = _moveEntity(
        _resizeEntity(none, 'balloon_gate', const Vec2(46, 110)),
        'balloon_gate',
        Vec2(274, y),
      );
      final adjustedSharp = _moveEntity(
        _resizeEntity(sharp, 'balloon_gate', const Vec2(46, 110)),
        'balloon_gate',
        Vec2(274, y),
      );
      final noneCount = _countSuccesses(resolver, adjustedNone);
      final sharpCount = _countSuccesses(resolver, adjustedSharp);
      print(
        'gate46x110@274,$y none=$noneCount sharp=$sharpCount '
        'ratio=${(sharpCount / noneCount).toStringAsFixed(3)}',
      );
    }
    return;
  }
  final counts = <String, ({int none, int sharp})>{};
  var noneSuccesses = 0;
  var sharpSuccesses = 0;
  for (var degree = 0; degree < 360; degree += 4) {
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final input = _input(degree, powerStep / 10);
      final noneResult = resolver.resolve(none, input);
      final sharpResult = resolver.resolve(
        sharp,
        ShotInput(
          direction: input.direction,
          power: input.power,
          equippedTrait: sharp.equippedTrait,
        ),
      );
      if (noneResult.state.phase == GamePhase.success) {
        noneSuccesses++;
        _countPath(counts, noneResult.path, none: true);
      }
      if (sharpResult.state.phase == GamePhase.success) {
        sharpSuccesses++;
        _countPath(counts, sharpResult.path, none: false);
      }
    }
  }
  final ranked = counts.entries.toList()
    ..sort((left, right) {
      final leftScore = left.value.none * 3 - left.value.sharp;
      final rightScore = right.value.none * 3 - right.value.sharp;
      return rightScore.compareTo(leftScore);
    });
  print('none=$noneSuccesses sharp=$sharpSuccesses');
  for (final entry in ranked.take(30)) {
    print('${entry.key}\t${entry.value.none}\t${entry.value.sharp}');
  }
  if (stage3) return;
  for (final scale in const [1.08, 1.10, 1.12, 1.14, 1.16, 1.18, 1.20]) {
    final adjustedNone = _replaceHole(none, scale);
    final adjustedSharp = _replaceHole(sharp, scale);
    final adjustedNoneCount = _countSuccesses(resolver, adjustedNone);
    final adjustedSharpCount = _countSuccesses(resolver, adjustedSharp);
    print(
      'holeScale=$scale none=$adjustedNoneCount sharp=$adjustedSharpCount '
      'ratio=${(adjustedSharpCount / adjustedNoneCount).toStringAsFixed(3)}',
    );
  }
  for (final dx in const [-8.0, -4.0, 0.0, 4.0, 8.0]) {
    for (final dy in const [-8.0, -4.0, 0.0, 4.0, 8.0]) {
      final movedNone = _moveHole(none, Vec2(300 + dx, 100 + dy));
      final movedSharp = _moveHole(sharp, Vec2(300 + dx, 100 + dy));
      final movedNoneCount = _countSuccesses(resolver, movedNone);
      final movedSharpCount = _countSuccesses(resolver, movedSharp);
      final ratio = movedSharpCount / movedNoneCount;
      if (ratio >= 1.4) {
        print(
          'hole=${300 + dx},${100 + dy} none=$movedNoneCount '
          'sharp=$movedSharpCount ratio=${ratio.toStringAsFixed(3)}',
        );
      }
    }
  }
  for (final dx in const [-12.0, -6.0, 0.0, 6.0, 12.0]) {
    for (final dy in const [-12.0, -6.0, 0.0, 6.0, 12.0]) {
      final movedNone = _moveEntity(none, 'balloon', Vec2(160 + dx, 260 + dy));
      final movedSharp = _moveEntity(
        sharp,
        'balloon',
        Vec2(160 + dx, 260 + dy),
      );
      final movedNoneCount = _countSuccesses(resolver, movedNone);
      final movedSharpCount = _countSuccesses(resolver, movedSharp);
      final ratio = movedSharpCount / movedNoneCount;
      if (ratio >= 1.4 && movedSharpCount >= 30) {
        print(
          'balloon=${160 + dx},${260 + dy} none=$movedNoneCount '
          'sharp=$movedSharpCount ratio=${ratio.toStringAsFixed(3)}',
        );
      }
    }
  }
  for (final width in const [38.0, 46.0, 54.0, 62.0]) {
    for (final height in const [74.0, 86.0, 98.0, 110.0]) {
      final resizedNone = _resizeEntity(
        none,
        'balloon_gate',
        Vec2(width, height),
      );
      final resizedSharp = _resizeEntity(
        sharp,
        'balloon_gate',
        Vec2(width, height),
      );
      final resizedNoneCount = _countSuccesses(resolver, resizedNone);
      final resizedSharpCount = _countSuccesses(resolver, resizedSharp);
      final ratio = resizedSharpCount / resizedNoneCount;
      if (ratio >= 1.4 && resizedSharpCount >= 30) {
        print(
          'gate=${width}x$height none=$resizedNoneCount '
          'sharp=$resizedSharpCount ratio=${ratio.toStringAsFixed(3)}',
        );
      }
    }
  }
  for (final x in const [274.0, 278.0, 282.0, 286.0]) {
    for (final y in const [168.0, 172.0, 176.0, 180.0, 184.0]) {
      final adjustedNone = _moveEntity(
        _resizeEntity(none, 'balloon_gate', const Vec2(46, 110)),
        'balloon_gate',
        Vec2(x, y),
      );
      final adjustedSharp = _moveEntity(
        _resizeEntity(sharp, 'balloon_gate', const Vec2(46, 110)),
        'balloon_gate',
        Vec2(x, y),
      );
      final noneCount = _countSuccesses(resolver, adjustedNone);
      final sharpCount = _countSuccesses(resolver, adjustedSharp);
      final ratio = sharpCount / noneCount;
      if (ratio >= 1.4 && sharpCount >= 30) {
        print(
          'gatePos=$x,$y none=$noneCount sharp=$sharpCount '
          'ratio=${ratio.toStringAsFixed(3)}',
        );
      }
    }
  }
}

GameState _replaceHole(GameState state, double hitboxScale) => state.copyWith(
  entities: [
    for (final entity in state.entities)
      if (entity.id == 'hole')
        entity.copyWith(hitboxScale: hitboxScale)
      else
        entity,
  ],
);

GameState _moveHole(GameState state, Vec2 position) => state.copyWith(
  entities: [
    for (final entity in state.entities)
      if (entity.id == 'hole') entity.copyWith(position: position) else entity,
  ],
);

GameState _moveEntity(GameState state, String id, Vec2 position) =>
    state.copyWith(
      entities: [
        for (final entity in state.entities)
          if (entity.id == id) entity.copyWith(position: position) else entity,
      ],
    );

GameState _resizeEntity(GameState state, String id, Vec2 size) =>
    state.copyWith(
      entities: [
        for (final entity in state.entities)
          if (entity.id == id) entity.copyWith(size: size) else entity,
      ],
    );

int _countSuccesses(ShotResolver resolver, GameState state) {
  var successes = 0;
  for (var degree = 0; degree < 360; degree += 4) {
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final input = _input(degree, powerStep / 10);
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: input.direction,
          power: input.power,
          equippedTrait: state.equippedTrait,
        ),
      );
      if (result.state.phase == GamePhase.success) successes++;
    }
  }
  return successes;
}

void _countPath(
  Map<String, ({int none, int sharp})> counts,
  List<Vec2> path, {
  required bool none,
}) {
  final visited = <String>{};
  for (final point in path) {
    final key = '${(point.x / 20).round() * 20},${(point.y / 20).round() * 20}';
    if (!visited.add(key)) continue;
    final current = counts[key] ?? (none: 0, sharp: 0);
    counts[key] = (
      none: current.none + (none ? 1 : 0),
      sharp: current.sharp + (none ? 0 : 1),
    );
  }
}

ShotInput _input(int degree, double power) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power,
  );
}
