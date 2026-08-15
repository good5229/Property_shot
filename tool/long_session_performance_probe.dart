import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main(List<String> arguments) {
  final iterations = _iterations(arguments);
  const resolver = ShotResolver();
  final samples = <int>[];
  var pathPoints = 0;
  for (var index = 0; index < iterations; index++) {
    final levelIndex = index % levels.length;
    final radians = (index % 72) * 5 * 3.141592653589793 / 180;
    final input = ShotInput(
      direction: Vec2(math.cos(radians), math.sin(radians)),
      power: 0.2 + (index % 17) * 0.045,
    );
    final state = levels[levelIndex].createState(levelIndex);
    final stopwatch = Stopwatch()..start();
    final result = resolver.resolve(state, input);
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
    pathPoints += result.path.length;
  }
  final sorted = [...samples]..sort();
  int percentile(double ratio) =>
      sorted[((sorted.length - 1) * ratio).round()];
  stdout.writeln(
    const JsonEncoder.withIndent('  ').convert({
      'schema': 'property-shot-long-session-probe/v1',
      'iterations': iterations,
      'retained_samples': samples.length,
      'p50_us': percentile(0.50),
      'p95_us': percentile(0.95),
      'p99_us': percentile(0.99),
      'max_us': sorted.last,
      'resolved_path_points': pathPoints,
      'memory_contract': 'bounded_to_iterations',
      'note': '실기기 프레임 판정이 아닌 결정론적 resolver 장시간 진단값',
    }),
  );
}

int _iterations(List<String> arguments) {
  const fallback = 400;
  if (arguments.isEmpty) return fallback;
  final parsed = int.tryParse(arguments.single);
  if (parsed == null || parsed < 40 || parsed > 10000) {
    throw const FormatException('반복 수는 40~10000 사이의 정수여야 합니다.');
  }
  return parsed;
}
