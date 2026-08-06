// ignore_for_file: avoid_print

import 'dart:math' as math;

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

const _shots = ShotResolver();
const _traits = TraitResolver();
const _directOnly = bool.fromEnvironment('DIRECT_ONLY');

void main() {
  final stage = generatedStageCatalog.stageById('stage_drained');
  for (final pattern in stage.patterns) {
    _inspectPattern(pattern, stage.title);
  }
}

void _inspectPattern(StagePattern pattern, String stageTitle) {
  final level = pattern.toLevelDefinition(
    stageId: 'stage_drained',
    stageTitle: stageTitle,
  );
  final base = level.createState(4, productRules: true);
  final copyBase = level.createState(4, productRules: true, copyCoreCount: 1);
  final strategies = <({String id, GameState state, String? sourceId})>[
    (id: 'none', state: base, sourceId: null),
    for (final source in base.traitSources)
      (
        id: source.id,
        state: _traits.transferSelectedTrait(
          _traits.selectSource(base, source.id),
        ),
        sourceId: source.id,
      ),
    for (final source in copyBase.traitSources)
      (
        id: 'copy_${source.id}',
        state: _traits.copySelectedTrait(
          _traits.selectSource(copyBase, source.id),
        ),
        sourceId: null,
      ),
  ];

  print('\n${pattern.patternId}');
  for (final strategy in strategies) {
    final successes = <_Cell>[];
    final moved = <_Cell>[];
    if (!_directOnly) {
      for (var degree = 0; degree < 360; degree += 2) {
        final radians = degree * math.pi / 180;
        for (var powerStep = 10; powerStep <= 50; powerStep++) {
          final input = ShotInput(
            direction: Vec2(math.cos(radians), math.sin(radians)),
            power: powerStep / 50,
            equippedTrait: strategy.state.equippedTrait,
          );
          final result = _shots.resolve(strategy.state, input);
          if (result.state.phase != GamePhase.success) continue;
          final cell = _Cell(
            degree: degree,
            powerStep: powerStep,
            events: result.events,
          );
          successes.add(cell);
          if (strategy.sourceId != null &&
              result.moves.any(
                (move) =>
                    move.entityId == strategy.sourceId && move.from != move.to,
              )) {
            moved.add(cell);
          }
        }
      }
    }
    final preferred = moved.isNotEmpty ? moved : successes;
    final sample = preferred.isEmpty ? null : preferred[preferred.length ~/ 2];
    print(
      '  ${strategy.id}: 성공 ${successes.length}, 원본 이동 ${moved.length}, '
      '표본 ${sample == null ? "없음" : "${sample.degree}도/${(sample.powerStep / 50).toStringAsFixed(2)}"}, '
      '연결 ${_largestComponent(preferred)}',
    );
    if (sample != null) print('    사건: ${sample.events.join(',')}');
    if (strategy.sourceId != null) {
      final hole = strategy.state.entities.firstWhere(
        (entity) => entity.type.name == 'hole',
      );
      final direct = _shots.resolve(
        strategy.state,
        ShotInput(
          direction: hole.position - strategy.state.activeBall.position,
          power: 1,
          equippedTrait: strategy.state.equippedTrait,
        ),
      );
      print(
        '    직선: ${direct.state.phase.name}, ${direct.events.join(',')}, '
        '이동 ${direct.moves.map((move) => move.entityId).join(',')}, '
        '끝 ${direct.path.last.x.toStringAsFixed(1)}/${direct.path.last.y.toStringAsFixed(1)}, '
        '원본 ${direct.state.entityById(strategy.sourceId!)?.position}, '
        '공 ${direct.state.entities.where((entity) => entity.type.name == 'ball').map((entity) => '${entity.id}:${entity.position}').join('|')}',
      );
    }
  }
}

int _largestComponent(List<_Cell> cells) {
  final remaining = <(int, int)>{
    for (final cell in cells) (cell.degree ~/ 2, cell.powerStep),
  };
  var largest = 0;
  while (remaining.isNotEmpty) {
    final queue = <(int, int)>[remaining.first];
    remaining.remove(queue.first);
    var count = 0;
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      count++;
      for (final neighbor in [
        ((cell.$1 + 179) % 180, cell.$2),
        ((cell.$1 + 1) % 180, cell.$2),
        (cell.$1, cell.$2 - 1),
        (cell.$1, cell.$2 + 1),
      ]) {
        if (remaining.remove(neighbor)) queue.add(neighbor);
      }
    }
    largest = math.max(largest, count);
  }
  return largest;
}

class _Cell {
  const _Cell({
    required this.degree,
    required this.powerStep,
    required this.events,
  });

  final int degree;
  final int powerStep;
  final List<String> events;
}
