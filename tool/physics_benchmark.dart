import 'dart:math' as math;
import 'dart:io';

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  const resolver = ShotResolver();
  const repetitions = 1000;

  for (var levelIndex = 0; levelIndex < levels.length; levelIndex++) {
    final state = levels[levelIndex].createState(levelIndex);
    var checksum = 0;
    final stopwatch = Stopwatch()..start();
    for (var iteration = 0; iteration < repetitions; iteration++) {
      final angle = (iteration % 360) * math.pi / 180;
      final result = resolver.resolve(
        state,
        ShotInput(
          direction: Vec2(math.cos(angle), math.sin(angle)),
          power: 0.35 + (iteration % 66) / 100,
          equippedTrait: state.equippedTrait,
        ),
      );
      checksum += result.path.length + result.events.length;
    }
    stopwatch.stop();
    final averageMicros = stopwatch.elapsedMicroseconds / repetitions;
    stdout.writeln(
      '${levels[levelIndex].name}: 총 ${stopwatch.elapsedMilliseconds}ms, '
      '1회 평균 ${averageMicros.toStringAsFixed(1)}µs, 확인값 $checksum',
    );
  }
}
