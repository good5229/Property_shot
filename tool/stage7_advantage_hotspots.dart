// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();
  final stage = generatedStageCatalog.stageById('stage_persistent');
  final pattern = stage.patternById('stage_persistent_04');
  final initial = pattern
      .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
      .createState(6, productRules: true);
  final first = resolver.resolve(initial, _input(20, 0.90));
  print('first events=${first.events}');
  print('first impacts=${first.impacts.map((item) => item.entityId).toList()}');
  print(
    'first path=${first.path.map((item) => '${item.x.toStringAsFixed(0)},${item.y.toStringAsFixed(0)}').join(' -> ')}',
  );
  final canonicalSecond = resolver.resolve(first.state, _input(90, 0.98));
  print('second events=${canonicalSecond.events}');
  print(
    'second impacts=${canonicalSecond.impacts.map((item) => '${item.entityId}@${item.position.x.toStringAsFixed(0)},${item.position.y.toStringAsFixed(0)}').toList()}',
  );
  final counts = <String, ({int bypass, int prepared})>{};
  var bypass = 0;
  var prepared = 0;
  for (var degree = 0; degree < 360; degree += 4) {
    for (var powerStep = 1; powerStep <= 10; powerStep++) {
      final input = _input(degree, powerStep / 10);
      final direct = resolver.resolve(initial, input);
      final afterSetup = resolver.resolve(first.state, input);
      if (direct.state.phase == GamePhase.success && !_usesGimmick(direct)) {
        bypass++;
        _countPath(counts, direct.path, bypass: true);
      }
      if (afterSetup.state.phase == GamePhase.success) {
        prepared++;
        _countPath(counts, afterSetup.path, bypass: false);
      }
    }
  }
  final ranked = counts.entries.toList()
    ..sort((a, b) {
      final aScore = a.value.bypass * 3 - a.value.prepared;
      final bScore = b.value.bypass * 3 - b.value.prepared;
      return bScore.compareTo(aScore);
    });
  print('bypass=$bypass prepared=$prepared');
  for (final entry in ranked.take(20)) {
    print('${entry.key}\t${entry.value.bypass}\t${entry.value.prepared}');
  }
}

bool _usesGimmick(ShotResult result) {
  final touched = <String>{
    for (final impact in result.impacts) ...[
      impact.entityId,
      impact.sourceEntityId,
    ],
  };
  return result.events.contains('crate_pushed') ||
      result.events.contains('jelly_bounced') ||
      touched.contains('stopper_crate') ||
      touched.contains('stopper_bumper');
}

void _countPath(
  Map<String, ({int bypass, int prepared})> counts,
  List<Vec2> path, {
  required bool bypass,
}) {
  final visited = <String>{};
  for (final point in path) {
    final key = '${(point.x / 20).round() * 20},${(point.y / 20).round() * 20}';
    if (!visited.add(key)) continue;
    final current = counts[key] ?? (bypass: 0, prepared: 0);
    counts[key] = (
      bypass: current.bypass + (bypass ? 1 : 0),
      prepared: current.prepared + (bypass ? 0 : 1),
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
