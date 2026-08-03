// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/levels.dart';

Map<String, Object?> _stateSnapshot(GameState state) {
  return {
    'levelIndex': state.levelIndex,
    'levelName': state.levelName,
    'ballSpawn': state.ballSpawn.toJson(),
    'phase': state.phase.name,
    'shotCount': state.shotCount,
    'score': state.score,
    'aimDirection': state.aimDirection.toJson(),
    'aimPower': state.aimPower,
    'entities': [
      for (final entity in state.entities)
        {
          'id': entity.id,
          'type': entity.type.name,
          'position': entity.position.toJson(),
          'size': entity.size.toJson(),
          'traits': entity.traits.map((trait) => trait.name).toList()..sort(),
          'movable': entity.movable,
          'solid': entity.solid,
          'active': entity.active,
          'open': entity.open,
          'pressed': entity.pressed,
          'visualState': entity.visualState,
          'hitboxScale': entity.hitboxScale,
          'restitution': entity.restitution,
          'linkId': entity.linkId,
        },
    ],
  };
}

void main() {
  final snapshot = {
    'schemaVersion': 1,
    'logicalSize': {'width': logicalSize.x, 'height': logicalSize.y},
    'stageCount': levels.length,
    'stages': [
      for (var index = 0; index < levels.length; index++)
        _stateSnapshot(levels[index].createState(index)),
    ],
  };
  const encoder = JsonEncoder.withIndent('  ');
  print(encoder.convert(snapshot));
}
