// ignore_for_file: avoid_print, unnecessary_brace_in_string_interps

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'fixtures/stage10_property_shot_patterns.dart';

void main() {
  const resolver = ShotResolver();
  late StageDefinition stage;

  setUpAll(() {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_property_shot');
  });

  test('10단계는 A~D 안정 패턴과 보상 없는 복수 해법을 보존한다', () {
    expect(stage.title, '10. 속성 한방');
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_property_shot_a',
      'stage_property_shot_b',
      'stage_property_shot_c',
      'stage_property_shot_d',
    ]);
    expect(stage.patterns.map((pattern) => pattern.parShots), [2, 2, 3, 2]);
    expect(stage.patterns.map((pattern) => pattern.metadata['contract']), [
      'A',
      'B',
      'C',
      'D',
    ]);
    final contractA = stage.patternById('stage_property_shot_a');
    expect(contractA.metadata['bypassDifficulty'], 'precision');
    expect(contractA.metadata['bypassGrid'], 'angle±4/power±8');
    expect(contractA.metadata['bypassSuccessCeiling'], '18');
    final leftWall = contractA.objects.firstWhere(
      (object) => object.id == 'wall_left',
    );
    expect(leftWall.position, const Vec2(24, 280));
    expect(leftWall.size, const Vec2(24, 520));
    expect(leftWall.movable, isFalse);
    for (final pattern in stage.patterns) {
      final keyTypes = {
        for (final object in pattern.objects)
          if (object.type != EntityType.hole) object.type,
        EntityType.ball,
      };
      expect(
        keyTypes.length,
        inInclusiveRange(5, 8),
        reason: '${pattern.patternId}: $keyTypes',
      );
      expect(pattern.copyCharges, 0);
      expect(pattern.copyCoreReward, 0);
      expect(pattern.acceptedStrategyIds, contains('none'));
      expect(pattern.solutionFamilies.length, greaterThanOrEqualTo(2));
      expect(pattern.metadata, isNot(contains('required_reward')));
    }
  });

  test('첨부 A의 홀은 가장자리 접촉을 포획하고 시각 판정 크기를 축소하지 않는다', () {
    final pattern = stage.patternById('stage_property_shot_a');
    final holeDefinition = pattern.objects.firstWhere(
      (object) => object.type == EntityType.hole,
    );
    final hole = holeDefinition.toEntityState();
    expect(hole.hitboxScale, 1.06);

    final ballRadius = 12 * 0.88;
    final captureRadius = hole.radius + ballRadius;
    final edge = const ShotResolver().resolve(
      _holeEdgeState(hole, captureRadius - 0.25, const Vec2(1, 0)),
      const ShotInput(direction: Vec2(1, 0), power: 0.12),
    );
    final miss = const ShotResolver().resolve(
      _holeEdgeState(hole, captureRadius + 0.25, const Vec2(-1, 0)),
      const ShotInput(direction: Vec2(1, 0), power: 0.12),
    );

    expect(edge.events, contains('hole_entered'));
    expect(edge.state.phase, GamePhase.success);
    expect(miss.events, isNot(contains('hole_entered')));
    expect(miss.state.phase, isNot(GamePhase.success));
  });

  test('모든 배치는 production Validator·유한값·고정 벽 계약을 통과한다', () {
    final validator = StagePatternValidator();
    final probe = ShotResolverPatternRuntimeProbe();
    final report = validator.validate(stage);
    expect(report.isValid, isTrue, reason: report.issues.join('\n'));

    for (final pattern in stage.patterns) {
      final evidence = probe.probe(stage: stage, pattern: pattern);
      expect(evidence.autoClearDetected, isFalse, reason: pattern.patternId);
      expect(evidence.definitiveNoRoute, isFalse, reason: pattern.patternId);
      expect(evidence.wallMoved, isFalse, reason: pattern.patternId);
      expect(evidence.nonDeterministic, isFalse, reason: pattern.patternId);
      expect(evidence.finiteTime, isTrue, reason: pattern.patternId);
      expect(evidence.finiteCoordinates, isTrue, reason: pattern.patternId);
      expect(evidence.withinBudget, isTrue, reason: pattern.patternId);
      for (final wall in pattern.objects.where(
        (object) => object.type == EntityType.wall,
      )) {
        expect(wall.solid, isTrue, reason: '${pattern.patternId}/${wall.id}');
        expect(
          wall.movable,
          isFalse,
          reason: '${pattern.patternId}/${wall.id}',
        );
      }
    }
  });

  for (final solution in stage10PropertyShotSolutions) {
    test('${solution.patternId} 직접 경로 제약과 의도 연쇄가 실제 ShotResolver에서 성립한다', () {
      _expectUiPower(solution.directPower);
      _expectUiPower(solution.firstPower);
      _expectUiPower(solution.secondPower);
      final pattern = stage.patternById(solution.patternId);
      final initial = _state(pattern);

      final direct = resolver.resolve(initial, solution.directInput);
      if (solution.patternId == 'stage_property_shot_a' ||
          solution.patternId == 'stage_property_shot_c') {
        expect(
          direct.state.phase,
          isNot(GamePhase.success),
          reason:
              '${solution.contract}는 첫 샷의 속성 기믹으로 연결 문을 연 뒤에만 홀 경로가 열립니다.',
        );
      } else {
        expect(
          direct.state.phase,
          GamePhase.success,
          reason: '${solution.patternId} 직접: ${direct.events}',
        );
        _expectDirectBypass(solution, direct);
      }

      final prepared = _preparedState(pattern, solution);
      final first = resolver.resolve(prepared, solution.firstInput);
      final second = resolver.resolve(first.state, solution.secondInput);
      expect(
        first.state.phase,
        GamePhase.planning,
        reason: '${solution.patternId} 첫 샷: ${first.events}',
      );
      expect(
        second.state.phase,
        GamePhase.success,
        reason: '${solution.patternId} 연쇄: ${second.events}',
      );
      expect(
        pattern.solutionFamilies,
        contains(solution.familyId),
        reason: '${solution.patternId} 풀이 계열이 데이터에 없습니다.',
      );
      if (solution.directFamilyId case final directFamilyId?) {
        expect(
          pattern.solutionFamilies,
          contains(directFamilyId),
          reason: '${solution.patternId} 직접 대체 풀이 계열이 데이터에 없습니다.',
        );
      }
      if ((solution.openedGateBankDegree, solution.openedGateBankPower) case (
        final int degree,
        final double power,
      )) {
        final bank = resolver.resolve(first.state, _input(degree, power));
        expect(bank.state.phase, GamePhase.success);
        expect(pattern.solutionFamilies, contains('opened_gate_bank'));
        expect(
          bank.impacts.map((impact) => impact.entityId).toList(),
          isNot(equals(second.impacts.map((impact) => impact.entityId).toList())),
          reason: '${solution.patternId} 문 개방 뒤 대체 bank가 canonical과 같은 경로입니다.',
        );
      }
      for (final impactId in solution.expectedImpactIds) {
        expect(
          [...first.impacts, ...second.impacts].any(
            (impact) =>
                impact.entityId == impactId ||
                impact.sourceEntityId == impactId,
          ),
          isTrue,
          reason:
              '${solution.patternId} 충돌 근거=${second.impacts.map((i) => i.entityId)}',
        );
      }
      for (final event in solution.expectedEvents) {
        expect(
          [...first.events, ...second.events],
          contains(event),
          reason:
              '${solution.patternId} 사건=${[...first.events, ...second.events]}',
        );
      }
      if (solution.contract == 'A') {
        expect(prepared.activeBall.traits, contains(TraitType.heavy));
        expect(prepared.entityById('a_stone')!.traits, isEmpty);
        expect(prepared.entityById('a_stone')!.movable, isTrue);
        expect(second.state.entityById('a_switch')!.pressed, isTrue);
        expect(second.state.entityById('a_gate')!.open, isTrue);
        expect(
          [...first.impacts, ...second.impacts].any(
            (impact) =>
                impact.sourceEntityId == 'a_crate' &&
                impact.entityId == 'a_switch',
          ),
          isTrue,
        );
      }
      if (solution.contract == 'C') {
        expect(prepared.activeBall.traits, contains(TraitType.sticky));
        expect(
          prepared.entityById('c_sticky_target')!.traits,
          contains(TraitType.sticky),
        );
        expect(first.events, contains('sticky_attached'));
        expect(first.state.entityById('spent_ball_1')!.movable, isFalse);
        expect(first.state.entityById('spent_ball_1')!.visualState, 'stuck');
        expect(second.events, contains('spent_ball_bounced'));
        expect(second.events, contains('balloon_bounced'));
        expect(
          second.impacts.any(
            (impact) =>
                impact.sourceEntityId == 'c_crate' &&
                impact.entityId == 'c_balloon',
          ),
          isTrue,
        );

        final withoutTransferredTrait = resolver.resolve(
          initial,
          _input(solution.firstDegree, solution.firstPower),
        );
        expect(
          withoutTransferredTrait.events,
          isNot(contains('sticky_attached')),
        );
        expect(
          withoutTransferredTrait.state.entityById('spent_ball_1')?.visualState,
          isNot('stuck'),
          reason: '점착을 옮기지 않은 같은 입력은 일반 받침에 붙으면 안 됩니다.',
        );
      }
      if (solution.contract == 'B') {
        expect(first.powerSliderActivations, isNotEmpty);
        expect(first.reflectorRotations, isNotEmpty);
        expect(second.events, contains('jelly_bounced'));
        final reflectorIndex = second.impacts.indexWhere(
          (impact) => impact.entityId == 'b_reflector',
        );
        final bumperIndex = second.impacts.indexWhere(
          (impact) => impact.entityId == 'b_bumper',
        );
        expect(reflectorIndex, greaterThanOrEqualTo(0));
        expect(bumperIndex, greaterThan(reflectorIndex));

        final beforeRotation = resolver.resolve(initial, solution.secondInput);
        expect(
          _hasRotatedReflectorChain(beforeRotation),
          isFalse,
          reason: '회전 전 반사판으로 같은 연쇄가 재현되면 회전의 인과성이 없습니다.',
        );
      }
      if (solution.contract == 'D') {
        expect([
          ...first.powerSliderActivations,
          ...second.powerSliderActivations,
        ], isNotEmpty);
        expect(second.state.entityById('spent_ball_1'), isNotNull);
      }
      _expectFiniteAndWalls(initial, second.state, second.path);
      expect(second.chainSafetyDiagnostics, isEmpty);
    });

    test('${solution.patternId} 대표 연쇄는 같은 초기 상태에서 동일하게 재현된다', () {
      final pattern = stage.patternById(solution.patternId);
      final firstRun = _resolveRepresentative(pattern, solution, resolver);
      final secondRun = _resolveRepresentative(pattern, solution, resolver);
      expect(_resultSignature(firstRun.$1), _resultSignature(secondRun.$1));
      expect(_resultSignature(firstRun.$2), _resultSignature(secondRun.$2));
    });

    test('${solution.patternId} 대표 입력 주변에도 연결된 허용 영역이 있다', () {
      final pattern = stage.patternById(solution.patternId);
      final initial = _state(pattern);
      final directRegion = _directNeighborhood(initial, solution.directInput);
      if (solution.patternId == 'stage_property_shot_a' ||
          solution.patternId == 'stage_property_shot_c') {
        expect(directRegion.successCount, 0);
        expect(directRegion.largestConnectedRegion, 0);
      } else {
        expect(
          directRegion.successCount,
          greaterThanOrEqualTo(5),
          reason: '${solution.patternId} 직접 허용 폭=${directRegion}',
        );
        expect(
          directRegion.largestConnectedRegion,
          greaterThanOrEqualTo(3),
          reason: '${solution.patternId} 직접 연결 영역=${directRegion}',
        );
      }
      final directSuccessUpperBound = solution.directSuccessUpperBound;
      if (directSuccessUpperBound != null) {
        expect(
          directRegion.successCount,
          lessThanOrEqualTo(directSuccessUpperBound),
          reason: '${solution.patternId} 기믹 없는 직행이 너무 넓습니다: $directRegion',
        );
      }
      final directConnectedUpperBound = solution.directConnectedUpperBound;
      if (directConnectedUpperBound != null) {
        expect(
          directRegion.largestConnectedRegion,
          lessThanOrEqualTo(directConnectedUpperBound),
          reason:
              '${solution.patternId} 기믹 없는 직행 연결 영역이 너무 넓습니다: $directRegion',
        );
      }

      final prepared = _preparedState(pattern, solution);
      final preparedRegion = _preparedNeighborhood(
        prepared,
        solution,
        resolver,
      );
      expect(
        preparedRegion.successCount,
        greaterThanOrEqualTo(3),
        reason: '${solution.patternId} 연쇄 허용 폭=${preparedRegion}',
      );
      expect(
        preparedRegion.largestConnectedRegion,
        greaterThanOrEqualTo(2),
        reason: '${solution.patternId} 연쇄 연결 영역=${preparedRegion}',
      );
      expect(preparedRegion.firstInputCount, greaterThanOrEqualTo(2));
      expect(preparedRegion.secondInputCount, greaterThanOrEqualTo(2));
      // 이 fixture는 7^4 연쇄 조합과 9^2 직접 입력을 서로 다른 표본
      // 공간에서 탐색한다. 따라서 여기서는 각 경로의 절대적인 근방
      // 견고성만 확인하고, 공정한 동일 2D 격자 우위는 all-stage 계약이
      // 별도로 검증한다.
      final chainSuccessLowerBound = solution.chainSuccessLowerBound;
      if (chainSuccessLowerBound != null) {
        expect(
          preparedRegion.successCount,
          greaterThanOrEqualTo(chainSuccessLowerBound),
          reason: '${solution.patternId} 대표 연쇄 성공 영역이 좁습니다: $preparedRegion',
        );
      }
      final chainConnectedLowerBound = solution.chainConnectedLowerBound;
      if (chainConnectedLowerBound != null) {
        expect(
          preparedRegion.largestConnectedRegion,
          greaterThanOrEqualTo(chainConnectedLowerBound),
          reason: '${solution.patternId} 대표 연쇄 연결 영역이 좁습니다: $preparedRegion',
        );
      }
      print('${solution.patternId}: 직접 ${directRegion}, 연쇄 ${preparedRegion}');
    });
  }
}

GameState _holeEdgeState(EntityState hole, double distance, Vec2 direction) {
  final position = hole.position - direction.normalized() * distance;
  const ball = EntityState(
    id: 'active_ball',
    type: EntityType.ball,
    position: Vec2(0, 0),
    size: Vec2(24, 24),
    movable: true,
    hitboxScale: 0.88,
  );
  return GameState(
    levelIndex: 9,
    levelName: '10. 속성 한방 홀 경계',
    ballSpawn: position,
    entities: [
      ball.copyWith(position: position),
      hole,
    ],
  );
}

GameState _state(StagePattern pattern) => pattern
    .toLevelDefinition(stageId: 'stage_property_shot', stageTitle: '10. 속성 한방')
    .createState(9, productRules: true);

GameState _preparedState(
  StagePattern pattern,
  Stage10PropertyShotSolution solution,
) {
  final initial = _state(pattern);
  final sourceId = switch (solution.contract) {
    'A' => 'a_stone',
    'C' => 'c_sticky',
    _ => null,
  };
  if (sourceId == null) return initial;
  const traits = TraitResolver();
  return traits.transferSelectedTrait(traits.selectSource(initial, sourceId));
}

void _expectUiPower(double power) {
  expect(power, greaterThanOrEqualTo(0.12));
  expect(power, lessThanOrEqualTo(1));
  expect((power * 50).roundToDouble(), closeTo(power * 50, 0.0001));
}

void _expectFiniteAndWalls(
  GameState initial,
  GameState result,
  List<Vec2> path,
) {
  for (final point in path) {
    expect(point.x.isFinite && point.y.isFinite, isTrue);
  }
  for (final entity in result.entities) {
    expect(entity.position.x.isFinite && entity.position.y.isFinite, isTrue);
  }
  for (final wall in initial.entities.where(
    (entity) => entity.type == EntityType.wall,
  )) {
    final after = result.entityById(wall.id);
    expect(after?.position, wall.position, reason: wall.id);
    expect(after?.movable, isFalse, reason: wall.id);
  }
}

_Region _directNeighborhood(GameState state, ShotInput center) {
  final angle = _degree(center);
  final points = <_Point>{};
  for (var angleOffset = -4; angleOffset <= 4; angleOffset++) {
    for (var powerOffset = -4; powerOffset <= 4; powerOffset++) {
      final point = _Point(angleOffset, powerOffset);
      final result = const ShotResolver().resolve(
        state,
        _input(angle + angleOffset, center.power + powerOffset / 50),
      );
      if (result.state.phase == GamePhase.success) points.add(point);
    }
  }
  return _Region(
    successCount: points.length,
    largestConnectedRegion: _largestRegion(points),
    firstInputCount: points.length,
    secondInputCount: points.length,
  );
}

_Region _preparedNeighborhood(
  GameState initial,
  Stage10PropertyShotSolution solution,
  ShotResolver resolver,
) {
  final firstCenter = _degree(solution.firstInput);
  final secondCenter = _degree(solution.secondInput);
  final points = <_Point>{};
  final firstInputs = <_Point>{};
  final secondInputs = <_Point>{};
  for (var firstAngleOffset = -3; firstAngleOffset <= 3; firstAngleOffset++) {
    for (var firstPowerOffset = -3; firstPowerOffset <= 3; firstPowerOffset++) {
      final first = resolver.resolve(
        initial,
        _input(
          firstCenter + firstAngleOffset,
          solution.firstPower + firstPowerOffset / 50,
          solution.transferTrait,
        ),
      );
      if (first.state.phase == GamePhase.success) continue;
      for (
        var secondAngleOffset = -3;
        secondAngleOffset <= 3;
        secondAngleOffset++
      ) {
        for (
          var secondPowerOffset = -3;
          secondPowerOffset <= 3;
          secondPowerOffset++
        ) {
          final second = resolver.resolve(
            first.state,
            _input(
              secondCenter + secondAngleOffset,
              solution.secondPower + secondPowerOffset / 50,
            ),
          );
          if (!_matchesContract(solution, first, second)) continue;
          final point = _Point(
            firstAngleOffset * 7 + firstPowerOffset,
            secondAngleOffset * 7 + secondPowerOffset,
          );
          points.add(point);
          firstInputs.add(_Point(firstAngleOffset, firstPowerOffset));
          secondInputs.add(_Point(secondAngleOffset, secondPowerOffset));
        }
      }
    }
  }
  return _Region(
    successCount: points.length,
    largestConnectedRegion: _largestRegion(points),
    firstInputCount: firstInputs.length,
    secondInputCount: secondInputs.length,
  );
}

bool _matchesContract(
  Stage10PropertyShotSolution solution,
  ShotResult first,
  ShotResult second,
) {
  if (second.state.phase != GamePhase.success) return false;
  final impacts = [...first.impacts, ...second.impacts];
  final events = [...first.events, ...second.events];
  return switch (solution.contract) {
    'A' =>
      impacts.any(
            (impact) =>
                impact.sourceEntityId == 'a_crate' &&
                impact.entityId == 'a_switch',
          ) &&
          events.contains('switch_pressed'),
    'B' =>
      first.powerSliderActivations.isNotEmpty &&
          first.reflectorRotations.isNotEmpty &&
          events.contains('jelly_bounced') &&
          _impactBefore(second, 'b_reflector', 'b_bumper'),
    'C' =>
      first.events.contains('sticky_attached') &&
          second.events.contains('spent_ball_bounced') &&
          second.events.contains('balloon_bounced') &&
          impacts.any((impact) => impact.entityId == 'spent_ball_1') &&
          second.impacts.any(
            (impact) =>
                impact.sourceEntityId == 'c_crate' &&
                impact.entityId == 'c_balloon',
          ),
    'D' =>
      [
            ...first.powerSliderActivations,
            ...second.powerSliderActivations,
          ].isNotEmpty &&
          impacts.any((impact) => impact.entityId == 'd_stone') &&
          impacts.any((impact) => impact.entityId == 'spent_ball_1'),
    _ => false,
  };
}

void _expectDirectBypass(
  Stage10PropertyShotSolution solution,
  ShotResult direct,
) {
  final avoidedIds = switch (solution.contract) {
    'A' => const ['a_crate', 'a_switch'],
    'B' => const ['b_slider', 'b_reflector', 'b_bumper'],
    'C' => const ['c_sticky_target', 'spent_ball_1', 'c_crate', 'c_balloon'],
    'D' => const ['d_slider', 'd_stone', 'd_wall', 'spent_ball_1'],
    _ => const <String>[],
  };
  final avoidedEvents = switch (solution.contract) {
    'A' => const ['crate_pushed', 'switch_pressed'],
    'B' => const [
      'power_slider_activated',
      'reflector_rotated',
      'jelly_bounced',
    ],
    'C' => const ['sticky_attached', 'spent_ball_bounced', 'balloon_bounced'],
    'D' => const ['power_slider_activated', 'existing_ball_hole_entered'],
    _ => const <String>[],
  };
  final impactedIds = direct.impacts
      .expand((impact) => [impact.entityId, impact.sourceEntityId])
      .whereType<String>();
  for (final id in avoidedIds) {
    expect(impactedIds, isNot(contains(id)));
  }
  for (final event in avoidedEvents) {
    expect(direct.events, isNot(contains(event)));
  }
}

(ShotResult, ShotResult) _resolveRepresentative(
  StagePattern pattern,
  Stage10PropertyShotSolution solution,
  ShotResolver resolver,
) {
  final prepared = _preparedState(pattern, solution);
  final first = resolver.resolve(prepared, solution.firstInput);
  return (first, resolver.resolve(first.state, solution.secondInput));
}

List<Object?> _resultSignature(ShotResult result) => [
  result.state.phase,
  result.events.join('|'),
  result.impacts
      .map(
        (impact) =>
            '${impact.sourceEntityId}>${impact.entityId}@'
            '${impact.position.x.toStringAsFixed(4)},'
            '${impact.position.y.toStringAsFixed(4)}',
      )
      .join('|'),
  result.path
      .map(
        (point) =>
            '${point.x.toStringAsFixed(4)},${point.y.toStringAsFixed(4)}',
      )
      .join('|'),
  result.state.entities
      .map(
        (entity) =>
            '${entity.id}@${entity.position.x.toStringAsFixed(4)},'
            '${entity.position.y.toStringAsFixed(4)}:'
            '${entity.visualState}:${entity.open}:${entity.pressed}',
      )
      .join('|'),
];

bool _hasRotatedReflectorChain(ShotResult result) =>
    result.state.phase == GamePhase.success &&
    result.events.contains('jelly_bounced') &&
    _impactBefore(result, 'b_reflector', 'b_bumper');

bool _impactBefore(ShotResult result, String firstId, String secondId) {
  final first = result.impacts.indexWhere(
    (impact) => impact.entityId == firstId,
  );
  final second = result.impacts.indexWhere(
    (impact) => impact.entityId == secondId,
  );
  return first >= 0 && second > first;
}

int _degree(ShotInput input) {
  final value =
      math.atan2(input.direction.y, input.direction.x) * 180 / math.pi;
  return value.round();
}

ShotInput _input(int degree, double power, [TraitType? trait]) {
  final radians = degree * math.pi / 180;
  return ShotInput(
    direction: Vec2(math.cos(radians), math.sin(radians)),
    power: power.clamp(0.12, 1),
    equippedTrait: trait,
  );
}

class _Point {
  const _Point(this.x, this.y);

  final int x;
  final int y;

  Iterable<_Point> get neighbors sync* {
    yield _Point(x - 1, y);
    yield _Point(x + 1, y);
    yield _Point(x, y - 1);
    yield _Point(x, y + 1);
  }

  @override
  bool operator ==(Object other) =>
      other is _Point && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

int _largestRegion(Set<_Point> points) {
  final remaining = points.toSet();
  var largest = 0;
  while (remaining.isNotEmpty) {
    final queue = <_Point>[remaining.first];
    remaining.remove(queue.first);
    var count = 0;
    while (queue.isNotEmpty) {
      final point = queue.removeLast();
      count++;
      for (final neighbor in point.neighbors) {
        if (remaining.remove(neighbor)) queue.add(neighbor);
      }
    }
    largest = math.max(largest, count);
  }
  return largest;
}

class _Region {
  const _Region({
    required this.successCount,
    required this.largestConnectedRegion,
    required this.firstInputCount,
    required this.secondInputCount,
  });

  final int successCount;
  final int largestConnectedRegion;
  final int firstInputCount;
  final int secondInputCount;

  @override
  String toString() =>
      '성공 $successCount개, 최대 연결 $largestConnectedRegion개, '
      '첫 샷 $firstInputCount개, 둘째 샷 $secondInputCount개';
}
