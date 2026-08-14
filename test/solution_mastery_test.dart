import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/solution_mastery.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('성공한 서로 다른 충돌 순서는 안정적인 별도 해법이 된다', () {
    final first = _route(EntityType.wall, events: const ['bounced']);
    final repeated = _route(EntityType.wall, events: const ['bounced']);
    final second = _route(
      EntityType.switchPad,
      events: const ['switch_pressed'],
    );
    expect(first.signature, repeated.signature);
    expect(second.signature, isNot(first.signature));
    expect(first.label, '벽 반사 해법');
    expect(second.label, '스위치·문 해법');
  });

  test('실패·빈 입력·불일치·과도한 결과는 해법으로 기록하지 않는다', () {
    final failure = levels.first
        .createState(0)
        .copyWith(phase: GamePhase.planning);
    expect(
      deriveSolutionRoute(
        inputs: const [],
        results: [ShotResult(state: failure, path: const [], events: const [])],
      ),
      isNull,
    );
    final successful = ShotResult(
      state: failure.copyWith(phase: GamePhase.success),
      path: const [],
      events: const [],
    );
    expect(
      deriveSolutionRoute(
        inputs: List.filled(
          33,
          const ShotInput(direction: Vec2(1, 0), power: 0.5),
        ),
        results: List.filled(33, successful),
      ),
      isNull,
    );
    expect(
      deriveSolutionRoute(
        inputs: const [
          ShotInput(direction: Vec2(1, 0), power: 0.5),
          ShotInput(direction: Vec2(0, 1), power: 0.5),
        ],
        results: [
          ShotResult(
            state: failure.copyWith(phase: GamePhase.success),
            path: const [],
            events: const [],
          ),
        ],
      ),
      isNull,
    );
  });

  test('저장은 중복을 제거하고 패턴별 상한과 재실행 복원을 지킨다', () async {
    final preferences = await SharedPreferences.getInstance();
    final store = SolutionMasteryStore(preferences);
    for (var index = 0; index < 6; index++) {
      final route = SolutionRoute(
        signature: index.toRadixString(16).padLeft(8, '0'),
        label: '해법 $index',
        firstInput: const ShotInput(direction: Vec2(1, 0), power: 0.5),
      );
      await store.record(
        stageId: 'stage_heavy',
        patternId: 'stage_heavy_01',
        route: route,
      );
      await store.record(
        stageId: 'stage_heavy',
        patternId: 'stage_heavy_01',
        route: route,
      );
    }
    final restored = await SolutionMasteryStore(
      preferences,
    ).loadFor('stage_heavy', 'stage_heavy_01');
    expect(restored, hasLength(maxSolutionRoutesPerPattern));
    expect(restored.map((entry) => entry.signature).toSet(), hasLength(4));
  });

  test('비정상 ID·서명·수치는 저장 전에 거부된다', () async {
    final store = SolutionMasteryStore(await SharedPreferences.getInstance());
    const validRoute = SolutionRoute(
      signature: '1234abcd',
      label: '벽 반사 해법',
      firstInput: ShotInput(direction: Vec2(1, 0), power: 0.5),
    );
    await expectLater(
      store.record(
        stageId: '../escape',
        patternId: 'stage_heavy_01',
        route: validRoute,
      ),
      throwsArgumentError,
    );
    await expectLater(
      store.record(
        stageId: 'stage_heavy',
        patternId: 'stage_heavy_01',
        route: const SolutionRoute(
          signature: 'not-a-hash',
          label: '',
          firstInput: ShotInput(
            direction: Vec2(double.nan, 0),
            power: double.nan,
          ),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('손상·초대형·타입 혼동 저장값은 제거하고 빈 상태로 복구한다', () async {
    final preferences = await SharedPreferences.getInstance();
    for (final raw in ['{bad', '"string"', '[{"stageId":7}]']) {
      await preferences.setString(SolutionMasteryStore.storageKey, raw);
      expect(
        await SolutionMasteryStore(
          preferences,
        ).loadFor('stage_heavy', 'stage_heavy_01'),
        isEmpty,
      );
      expect(preferences.containsKey(SolutionMasteryStore.storageKey), isFalse);
    }

    final overflow = List.generate(
      maxSolutionRoutesPerPattern + 1,
      (index) => const SolutionMasteryEntry(
        stageId: 'stage_heavy',
        patternId: 'stage_heavy_01',
        signature: '1234abcd',
        label: '벽 반사 해법',
        firstDirectionX: 1,
        firstDirectionY: 0,
        firstPower: 0.5,
      ).toJson()..['signature'] = index.toRadixString(16).padLeft(8, '0'),
    );
    await preferences.setString(
      SolutionMasteryStore.storageKey,
      jsonEncode(overflow),
    );
    expect(
      await SolutionMasteryStore(
        preferences,
      ).loadFor('stage_heavy', 'stage_heavy_01'),
      isEmpty,
    );
    expect(preferences.containsKey(SolutionMasteryStore.storageKey), isFalse);
  });

  test('해법 카드는 왕복하고 변조·잘못된 prefix·과도한 입력을 거부한다', () {
    const entry = SolutionMasteryEntry(
      stageId: 'stage_heavy',
      patternId: 'stage_heavy_01',
      signature: '1234abcd',
      label: '벽 반사 해법',
      firstDirectionX: 1,
      firstDirectionY: 0,
      firstPower: 0.5,
    );
    final code = SolutionShareCardCodec.encode(entry);
    expect(SolutionShareCardCodec.decode(code).signature, entry.signature);
    expect(
      () => SolutionShareCardCodec.decode('BAD-$code'),
      throwsFormatException,
    );
    expect(
      () => SolutionShareCardCodec.decode(
        '${code.substring(0, code.length - 1)}0',
      ),
      throwsFormatException,
    );
    expect(
      () => SolutionShareCardCodec.decode('PSS1-${'a' * 5000}'),
      throwsFormatException,
    );
  });
}

SolutionRoute _route(EntityType type, {List<String> events = const []}) {
  final state = levels.first.createState(0).copyWith(phase: GamePhase.success);
  return deriveSolutionRoute(
    inputs: const [ShotInput(direction: Vec2(1, 0), power: 0.5)],
    results: [
      ShotResult(
        state: state,
        path: const [Vec2.zero, Vec2(1, 0)],
        events: events,
        impacts: [
          ShotImpact(
            entityId: 'target',
            entityType: type,
            position: Vec2.zero,
            normal: const Vec2(-1, 0),
            pathIndex: 1,
            strength: 1,
          ),
        ],
      ),
    ],
  )!;
}
