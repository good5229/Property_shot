// ignore_for_file: avoid_print

import 'package:property_shot/game/analysis/virtual_player_simulator.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/input/intent_assist_resolver.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

import '../test/fixtures/stage10_property_shot_patterns.dart';
import '../test/fixtures/stage9_rotating_reflector_patterns.dart';
import '../test/fixtures/stage_balloon_patterns.dart';
import '../test/fixtures/stage_bouncy_patterns.dart';
import '../test/fixtures/stage_chain_gate_patterns.dart';
import '../test/fixtures/stage_chain_score_patterns.dart';
import '../test/fixtures/stage_drained_patterns.dart';
import '../test/fixtures/stage_heavy_patterns.dart';
import '../test/fixtures/stage_persistent_patterns.dart';
import '../test/fixtures/stage_speed_patterns.dart';

const _trials = 80;
const _seed = 20260824;

void main() {
  const simulator = VirtualPlayerSimulator();
  final specs = _scenarioSpecs();
  final rows = <_ReportRow>[];

  for (final spec in specs) {
    for (final persona in virtualPlayerPersonas) {
      final direct = simulator.run(
        scenario: spec.scenario,
        persona: persona,
        assistStrength: IntentAssistStrength.off,
        trials: _trials,
        seed: _seed,
      );
      final standard = simulator.run(
        scenario: spec.scenario,
        persona: persona,
        assistStrength: IntentAssistStrength.standard,
        trials: _trials,
        seed: _seed,
      );
      rows.add(_ReportRow(spec, persona, direct, standard));
    }
  }

  final output = StringBuffer()
    ..writeln('# 입력 보정 가상 플레이어 QA')
    ..writeln()
    ..writeln('- 생성 기준: 실제 `ShotResolver`와 `IntentAssistResolver` 재생')
    ..writeln('- 고정 시드: `$_seed`')
    ..writeln('- 표본: 기준 패턴 × 프로필별 $_trials회')
    ..writeln('- 비교: 직접 입력(OFF) ↔ 정식 도전 기준(STANDARD)')
    ..writeln()
    ..writeln('## 프로필 합계')
    ..writeln()
    ..writeln('| 프로필 | OFF 클리어 | STANDARD 클리어 | 변화 | 기믹 준수 | 보정 발동 | 안전 중단 |')
    ..writeln('|---|---:|---:|---:|---:|---:|---:|');
  for (final persona in virtualPlayerPersonas) {
    final selected = rows.where((row) => row.persona.id == persona.id).toList();
    final directClears = selected.fold<int>(
      0,
      (sum, row) => sum + row.direct.clears,
    );
    final standardClears = selected.fold<int>(
      0,
      (sum, row) => sum + row.standard.clears,
    );
    final mechanicClears = selected.fold<int>(
      0,
      (sum, row) => sum + row.standard.mechanicClears,
    );
    final standardShots = selected.fold<int>(
      0,
      (sum, row) => sum + row.standard.totalShots,
    );
    final assistedShots = selected.fold<int>(
      0,
      (sum, row) => sum + row.standard.assistedShots,
    );
    final safetyStops = selected.fold<int>(
      0,
      (sum, row) => sum + row.standard.safetyStops,
    );
    final total = selected.length * _trials;
    output.writeln(
      '| ${persona.label} | ${_percent(directClears / total)} | '
      '${_percent(standardClears / total)} | '
      '${_signedPoints((standardClears - directClears) / total)} | '
      '${_percent(mechanicClears / total)} | '
      '${_percent(assistedShots / standardShots)} | $safetyStops |',
    );
  }

  output
    ..writeln()
    ..writeln('## 스테이지별 결과')
    ..writeln()
    ..writeln(
      '| 스테이지 | 프로필 | OFF | STANDARD | 변화 | 기믹 준수 | 발동 | 근접 실패 구제 | 안전 중단 OFF→STD |',
    )
    ..writeln('|---|---|---:|---:|---:|---:|---:|---:|---:|');
  for (final row in rows) {
    output.writeln(
      '| ${row.spec.label} | ${row.persona.label} | '
      '${_percent(row.direct.clearRate)} | ${_percent(row.standard.clearRate)} | '
      '${_signedPoints(row.standard.clearRate - row.direct.clearRate)} | '
      '${_percent(row.standard.mechanicClearRate)} | '
      '${_percent(row.standard.assistActivationRate)} | '
      '${_percent(row.standard.localRescueRate)} | '
      '${row.direct.safetyStops}→${row.standard.safetyStops} |',
    );
  }

  final regressions = rows
      .where((row) => row.standard.clearRate + 0.0001 < row.direct.clearRate)
      .toList();
  final lowMobile = rows
      .where(
        (row) =>
            row.persona.id == 'mobile_novice' && row.standard.clearRate < 0.4,
      )
      .toList();
  final safetyStopRows = rows
      .where(
        (row) => row.direct.safetyStops > 0 || row.standard.safetyStops > 0,
      )
      .toList();
  output
    ..writeln()
    ..writeln('## 자동 판정')
    ..writeln()
    ..writeln(
      '- 보정 역효과 후보: ${regressions.isEmpty ? '없음' : regressions.map((row) => row.spec.label).toSet().join(', ')}',
    )
    ..writeln(
      '- 모바일 초보 STANDARD 40% 미만: ${lowMobile.isEmpty ? '없음' : lowMobile.map((row) => row.spec.label).join(', ')}',
    )
    ..writeln(
      '- 안전 중단 OFF→STANDARD: '
      '${rows.fold<int>(0, (sum, row) => sum + row.direct.safetyStops)}→'
      '${rows.fold<int>(0, (sum, row) => sum + row.standard.safetyStops)}건'
      '${safetyStopRows.isEmpty ? '' : ' (${safetyStopRows.map((row) => '${row.spec.label}/${row.persona.label} ${row.direct.safetyStops}→${row.standard.safetyStops}건').join(', ')})'}',
    )
    ..writeln()
    ..writeln('## 적용 기준')
    ..writeln()
    ..writeln('1. 정식 오늘의 도전은 STANDARD로 고정해 기록 조건을 통일한다.')
    ..writeln('2. 연습·캠페인은 사용자 설정을 유지하고 반복 근접 실패 때만 적응 범위를 넓힌다.')
    ..writeln('3. STANDARD가 OFF보다 낮아진 조합은 출시 차단 회귀로 다룬다.')
    ..writeln('4. 모바일 초보 40% 미만 스테이지는 보정 상향보다 먼저 판독성·충돌 여유·대표 경로를 재검토한다.')
    ..writeln('5. 기믹 준수율이 클리어율보다 크게 낮으면 홀 보정이 아닌 기믹 목표 보정 정책을 별도로 설계한다.');

  print(output.toString());
  if (regressions.isNotEmpty) {
    throw StateError(
      'STANDARD가 OFF보다 낮은 조합이 있습니다: '
      '${regressions.map((row) => '${row.spec.label}/${row.persona.label}').join(', ')}',
    );
  }
  final directSafetyStops = rows.fold<int>(
    0,
    (sum, row) => sum + row.direct.safetyStops,
  );
  final standardSafetyStops = rows.fold<int>(
    0,
    (sum, row) => sum + row.standard.safetyStops,
  );
  if (standardSafetyStops > directSafetyStops) {
    throw StateError(
      'STANDARD가 새 안전 중단을 늘렸습니다: '
      '$directSafetyStops→$standardSafetyStops',
    );
  }
}

List<_ScenarioSpec> _scenarioSpecs() {
  final specs = <_ScenarioSpec>[];
  for (
    var stageIndex = 0;
    stageIndex < generatedStageCatalog.stages.length;
    stageIndex++
  ) {
    final stage = generatedStageCatalog.stages[stageIndex];
    final pattern = generatedStageCatalog.baselinePatternFor(stage);
    var state = pattern
        .toLevelDefinition(stageId: stage.stageId, stageTitle: stage.title)
        .createState(stageIndex, productRules: true);
    late final List<ShotInput> shots;
    late final VirtualPlayerMechanicCheck mechanicCheck;

    switch (stage.stageId) {
      case 'stage_heavy':
        final fixture = stageHeavyRepresentatives.firstWhere(
          (item) =>
              item.patternId == pattern.patternId && item.strategyId == 'anvil',
        );
        state = _transfer(state, 'anvil');
        shots = [_equipped(fixture.direction, fixture.power, state)];
        mechanicCheck = (results) => _events(results).contains('crate_pushed');
      case 'stage_bouncy':
        final fixture = stageBouncyRepresentatives.firstWhere(
          (item) =>
              item.patternId == pattern.patternId && item.strategyId == 'jelly',
        );
        state = _transfer(state, 'jelly');
        shots = [_equipped(fixture.direction, fixture.power, state)];
        mechanicCheck = (results) => _events(results).contains('bounced');
      case 'stage_chain_gate':
        final fixture = stageChainGateRepresentatives.firstWhere(
          (item) =>
              item.patternId == pattern.patternId && item.strategyId == 'steel',
        );
        state = _transfer(state, 'steel');
        shots = [_equipped(fixture.direction, fixture.power, state)];
        mechanicCheck = (results) =>
            _events(results).contains('switch_pressed');
      case 'stage_balloon':
        final fixture = stageBalloonRepresentatives.firstWhere(
          (item) =>
              item.patternId == pattern.patternId && item.strategyId == 'sharp',
        );
        state = _transfer(state, 'spike_source');
        shots = [_equipped(fixture.direction, fixture.power, state)];
        mechanicCheck = (results) =>
            _events(results).contains('balloon_popped');
      case 'stage_drained':
        final fixture = stageDrainedRepresentativeSolutions.firstWhere(
          (item) => item.patternId == pattern.patternId,
        );
        state = _transfer(state, fixture.strategyId);
        shots = [_equipped(fixture.direction, fixture.power, state)];
        mechanicCheck = (results) => results
            .expand((result) => result.moves)
            .any(
              (move) =>
                  move.entityId == fixture.strategyId && move.from != move.to,
            );
      case 'stage_speed':
        final fixture = stageSpeedRepresentativeSolutions.firstWhere(
          (item) => item.patternId == pattern.patternId,
        );
        shots = [ShotInput(direction: fixture.direction, power: fixture.power)];
        mechanicCheck = (results) =>
            results.any((result) => result.powerSliderActivations.isNotEmpty);
      case 'stage_persistent':
        final fixture = stagePersistentRepresentativeSolutions.firstWhere(
          (item) => item.patternId == pattern.patternId,
        );
        shots = [fixture.firstInput, fixture.secondInput];
        mechanicCheck = (results) => results
            .expand((result) => result.impacts)
            .any(
              (impact) =>
                  impact.entityId == 'spent_ball_1' ||
                  impact.sourceEntityId == 'spent_ball_1',
            );
      case 'stage_chain_score':
        final fixture = stageChainScoreSolutions.firstWhere(
          (item) => item.patternId == pattern.patternId,
        );
        shots = [fixture.firstInput, fixture.secondInput];
        mechanicCheck = (results) =>
            results
                .expand((result) => result.impacts)
                .map((impact) => impact.entityId)
                .toSet()
                .length >=
            3;
      case 'stage_rotating_reflector':
        final fixture = stage9RotatingReflectorSolutions.firstWhere(
          (item) => item.patternId == pattern.patternId,
        );
        shots = [fixture.firstInput, fixture.secondInput];
        mechanicCheck = (results) =>
            results.any((result) => result.reflectorRotations.isNotEmpty);
      case 'stage_property_shot':
        final fixture = stage10PropertyShotSolutions.firstWhere(
          (item) => item.patternId == pattern.patternId,
        );
        if (fixture.transferTrait != null) {
          final source = state.entities.firstWhere(
            (entity) => entity.traits.contains(fixture.transferTrait),
          );
          state = _transfer(state, source.id);
        }
        shots = [fixture.firstInput, fixture.secondInput];
        mechanicCheck = (results) {
          final events = _events(results);
          return fixture.expectedEvents.every(events.contains);
        };
      default:
        throw StateError('가상 플레이 시나리오가 없는 스테이지: ${stage.stageId}');
    }

    specs.add(
      _ScenarioSpec(
        label: stage.title,
        scenario: VirtualPlayerScenario(
          id: '${stage.stageId}/${pattern.patternId}',
          initialState: state,
          canonicalShots: shots,
          mechanicCheck: mechanicCheck,
          assistPolicy: IntentAssistPolicy.forStage(stage.stageId),
        ),
      ),
    );
  }
  return specs;
}

GameState _transfer(GameState state, String sourceId) {
  const resolver = TraitResolver();
  return resolver.transferSelectedTrait(resolver.selectSource(state, sourceId));
}

ShotInput _equipped(Vec2 direction, double power, GameState state) => ShotInput(
  direction: direction,
  power: power,
  equippedTrait: state.equippedTrait,
);

Set<String> _events(List<ShotResult> results) =>
    results.expand((result) => result.events).toSet();

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _signedPoints(double value) {
  final points = value * 100;
  return '${points >= 0 ? '+' : ''}${points.toStringAsFixed(1)}%p';
}

class _ScenarioSpec {
  const _ScenarioSpec({required this.label, required this.scenario});

  final String label;
  final VirtualPlayerScenario scenario;
}

class _ReportRow {
  const _ReportRow(this.spec, this.persona, this.direct, this.standard);

  final _ScenarioSpec spec;
  final VirtualPlayerPersona persona;
  final VirtualPlayerSimulationResult direct;
  final VirtualPlayerSimulationResult standard;
}
