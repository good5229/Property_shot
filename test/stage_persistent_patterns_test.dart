import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

import 'fixtures/stage_persistent_patterns.dart';

void main() {
  const resolver = ShotResolver();
  late StageDefinition stage;

  setUpAll(() {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    stage = catalog.stageById('stage_persistent');
  });

  test('7단계는 과거 공 재활용을 배우는 네 패턴과 기준 패턴을 가진다', () {
    expect(stage.title, '7. 공은 사라지지 않는다');
    expect(stage.patterns.map((pattern) => pattern.patternId), [
      'stage_persistent_01',
      'stage_persistent_02',
      'stage_persistent_03',
      'stage_persistent_04',
    ]);
    expect(
      stage.patterns.where((pattern) => pattern.metadata['baseline'] == 'true'),
      hasLength(1),
    );
    expect(
      stage.patterns.every(
        (pattern) => pattern.acceptedStrategyIds.contains('none'),
      ),
      isTrue,
    );
    expect(
      stage.patterns.every((pattern) => pattern.solutionFamilies.length >= 2),
      isTrue,
    );
    expect(
      stage.patterns
          .expand((pattern) => pattern.objects)
          .where((object) => object.type.name == 'wall')
          .every((wall) => !wall.movable),
      isTrue,
    );
  });

  for (final solution in stagePersistentRepresentativeSolutions) {
    test('${solution.patternId} 대표 두 발은 과거 공 사건에서 홀 성공으로 이어진다', () {
      _expectUiPower(solution.firstPower);
      _expectUiPower(solution.secondPower);
      final pattern = stage.patternById(solution.patternId);
      final first = resolver.resolve(_state(pattern), solution.firstInput);
      expect(
        first.state.phase,
        GamePhase.planning,
        reason: first.events.join(' → '),
      );
      expect(first.state.shotCount, 1);
      final firstSpent = first.state.entityById('spent_ball_1');
      expect(firstSpent, isNotNull);
      if (solution.expectedFirstImpactId != null) {
        expect(
          first.impacts.any(
            (impact) => impact.entityId == solution.expectedFirstImpactId,
          ),
          isTrue,
          reason:
              '${solution.patternId}: ${first.impacts.map((item) => item.entityId)}',
        );
      }
      if (solution.patternId == 'stage_persistent_02') {
        expect(first.events, contains('switch_pressed'));
        expect(first.state.entityById('switch_hold')!.pressed, isTrue);
        expect(first.state.entityById('hold_gate')!.open, isTrue);
      }
      if (solution.requireFirstFixed) {
        expect(firstSpent!.visualState, 'stuck');
        expect(firstSpent.movable, isFalse);
      }

      final second = resolver.resolve(first.state, solution.secondInput);
      expect(
        second.state.phase,
        GamePhase.success,
        reason: '${solution.patternId}: ${second.events.join(' → ')}',
      );
      final pastBallImpactIndex = solution.expectedSecondImpactId == null
          ? -1
          : second.impacts.indexWhere(
              (impact) =>
                  impact.entityId == solution.expectedSecondImpactId ||
                  impact.sourceEntityId == solution.expectedSecondImpactId,
            );
      if (solution.expectedSecondImpactId != null) {
        expect(pastBallImpactIndex, greaterThanOrEqualTo(0));
      }
      if (solution.requireFirstMove) {
        expect(
          second.moves.any(
            (move) => move.entityId == 'spent_ball_1' && move.from != move.to,
          ),
          isTrue,
        );
      }
      final holeImpactIndex = second.impacts.indexWhere(
        (impact) =>
            impact.entityId == 'hole' &&
            (solution.expectedSecondHoleSourceId == null ||
                impact.sourceEntityId == solution.expectedSecondHoleSourceId),
      );
      expect(holeImpactIndex, greaterThanOrEqualTo(0));
      if (solution.expectedSecondImpactId != null) {
        expect(holeImpactIndex, greaterThan(pastBallImpactIndex));
        expect(
          second.physicsEvents.any(
            (event) =>
                event.kind == PhysicsEventKind.impact &&
                event.targetEntityId == 'spent_ball_1',
          ),
          isTrue,
        );
      }
      final withoutPreparation = resolver.resolve(
        _state(pattern),
        solution.secondInput,
      );
      expect(withoutPreparation.state.phase, isNot(GamePhase.success));
      if (solution.patternId == 'stage_persistent_02') {
        expect(second.state.entityById('switch_hold')!.pressed, isTrue);
        expect(second.state.entityById('hold_gate')!.open, isTrue);
      } else {
        expect(
          withoutPreparation.events,
          isNot(contains('existing_ball_hole_entered')),
        );
      }
    });
  }

  for (final solution in stagePersistentAlternativeSolutions) {
    test('${solution.patternId} ${solution.familyId} 대체 경로도 성공한다', () {
      _expectUiPower(solution.firstPower);
      final pattern = stage.patternById(solution.patternId);
      expect(
        pattern.solutionFamilies,
        contains(solution.familyId),
        reason: '${solution.patternId}/${solution.familyId} 대체 풀이 계열이 데이터에 없습니다.',
      );
      final result = resolver.resolve(_state(pattern), solution.firstInput);
      expect(
        result.state.phase,
        GamePhase.success,
        reason: '${solution.patternId}: ${result.events.join(' → ')}',
      );
    });
  }

  test('첫 공의 순번·속성·이동/고정 상태를 화면 계약에 사용할 수 있다', () {
    final pattern = stage.patternById('stage_persistent_03');
    final first = resolver.resolve(
      _state(pattern),
      stagePersistentRepresentativeSolutions[2].firstInput,
    );
    final spent = first.state.entityById('spent_ball_1')!;
    expect(spent.id, 'spent_ball_1');
    expect(spent.traits, contains(TraitType.sticky));
    expect(spent.visualState, 'stuck');
    expect(spent.movable, isFalse);
    expect(
      first.state.entities.where((entity) => entity.type.name == 'ball'),
      hasLength(2),
    );
  });
}

void _expectUiPower(double power) {
  expect(power, inInclusiveRange(0.12, 1));
  expect((power * 50 - (power * 50).round()).abs(), lessThan(0.000001));
}

GameState _state(StagePattern pattern) => pattern
    .toLevelDefinition(
      stageId: 'stage_persistent',
      stageTitle: '7. 공은 사라지지 않는다',
    )
    .createState(6, productRules: true);
