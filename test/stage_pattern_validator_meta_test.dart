import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

import 'fixtures/invalid_patterns/invalid_pattern_fixtures.dart';

void main() {
  final fixtures = buildInvalidPatternFixtures();

  test('이름 있는 invalid fixture가 모두 기대 오류를 검출한다', () {
    const expectedFixtureNames = <String>{
      'invalid_overlap',
      'invalid_auto_clear',
      'invalid_no_route',
      'invalid_wall_moves',
      'invalid_infinite_bounce',
      'invalid_slider_tunneling',
      'invalid_non_deterministic',
      'invalid_hole_pass_through',
      'invalid_reward_required',
      'invalid_duplicate_object_id',
      'invalid_rotator_order',
      'invalid_soft_lock',
    };
    expect(
      fixtures.map((fixture) => fixture.name).toSet(),
      expectedFixtureNames,
    );

    final validator = StagePatternValidator();
    for (final fixture in fixtures) {
      final report = _validateFixture(validator, fixture);
      expect(
        _missingExpectedCodes(report, fixture.expectedCodes),
        isEmpty,
        reason: '${fixture.name}: ${report.issues}',
      );
    }
  });

  test('정상 fixture는 오탐 없이 통과한다', () {
    final pattern = StagePattern.fromLevelDefinition(
      levels.first,
      patternId: 'valid_fixture',
    );
    final stage = StageDefinition(
      stageId: 'valid_fixture_stage',
      title: '정상 패턴',
      patterns: [pattern],
    );
    final report = StagePatternValidator().validatePattern(
      stage,
      pattern,
      enforceProductionPolicy: false,
    );
    expect(report.isValid, isTrue, reason: '${report.issues}');
  });

  test('홀 통과 규칙을 실제로 끄면 fixture 계약이 변이를 잡는다', () {
    final fixture = fixtures.singleWhere(
      (candidate) => candidate.name == 'invalid_hole_pass_through',
    );
    final normal = _validateFixture(StagePatternValidator(), fixture);
    expect(_missingExpectedCodes(normal, fixture.expectedCodes), isEmpty);

    final mutated = _validateFixture(
      StagePatternValidator(
        runtimeRulePolicy: const RuntimeValidationRulePolicy(
          disabledCodes: {ValidationIssueCode.runtimeHolePassThrough},
        ),
      ),
      fixture,
    );
    expect(
      _missingExpectedCodes(mutated, fixture.expectedCodes),
      {ValidationIssueCode.runtimeHolePassThrough},
      reason: '실제 검증 규칙을 비활성화한 변이는 fixture 계약을 통과하면 안 됩니다.',
    );
  });

  test('no-route와 신규 기물 오류는 명시적 evidence가 있을 때만 생긴다', () {
    final base = StagePattern.fromLevelDefinition(
      levels.first,
      patternId: 'evidence_contract',
    );
    final stage = StageDefinition(
      stageId: 'evidence_contract_stage',
      title: 'evidence 계약',
      patterns: [base],
    );
    final validator = StagePatternValidator();
    const observedFailure = PatternRuntimeEvidence(
      probeCount: 4,
      maxProbeCount: 4,
      shotCount: 8,
      maxShots: 8,
      routeObserved: false,
    );
    final warningOnly = validator.validatePatternWithRuntimeEvidence(
      stage,
      base,
      observedFailure,
      enforceProductionPolicy: false,
    );
    expect(warningOnly.hasCode(ValidationIssueCode.runtimeNoRoute), isFalse);
    expect(
      warningOnly.hasCode(ValidationIssueCode.runtimeSliderTunneling),
      isFalse,
    );

    const definitive = PatternRuntimeEvidence(
      probeCount: 4,
      maxProbeCount: 4,
      shotCount: 8,
      maxShots: 8,
      definitiveNoRoute: true,
    );
    final proven = validator.validatePatternWithRuntimeEvidence(
      stage,
      base,
      definitive,
      enforceProductionPolicy: false,
    );
    expect(proven.hasCode(ValidationIssueCode.runtimeNoRoute), isTrue);
  });

  test('대표 입력 무이동만으로 soft lock을 만들지 않고 명시 evidence만 허용한다', () {
    final base = StagePattern.fromLevelDefinition(
      levels.first,
      patternId: 'soft_lock_contract',
    );
    final stage = StageDefinition(
      stageId: 'soft_lock_contract_stage',
      title: '소프트락 계약',
      patterns: [base],
    );
    final validator = StagePatternValidator();
    const observedOnly = PatternRuntimeEvidence(
      probeCount: 4,
      maxProbeCount: 4,
      shotCount: 8,
      maxShots: 8,
      allRepresentativeInputsNoMovement: true,
      launchUnavailable: false,
    );
    final observationReport = validator.validatePatternWithRuntimeEvidence(
      stage,
      base,
      observedOnly,
      enforceProductionPolicy: false,
    );
    expect(
      observationReport.hasCode(ValidationIssueCode.runtimeSoftLock),
      isFalse,
    );

    const explicit = PatternRuntimeEvidence(
      probeCount: 4,
      maxProbeCount: 4,
      shotCount: 8,
      maxShots: 8,
      allRepresentativeInputsNoMovement: true,
      launchUnavailable: true,
    );
    final explicitReport = validator.validatePatternWithRuntimeEvidence(
      stage,
      base,
      explicit,
      enforceProductionPolicy: false,
    );
    expect(explicitReport.hasCode(ValidationIssueCode.runtimeSoftLock), isTrue);
  });
}

ValidationReport _validateFixture(
  StagePatternValidator validator,
  InvalidPatternFixture fixture,
) {
  if (fixture.runtimeProbe != null) {
    final evidence = fixture.runtimeProbe!.probe(
      stage: fixture.stage,
      pattern: fixture.pattern,
    );
    return validator.validatePatternWithRuntimeEvidence(
      fixture.stage,
      fixture.pattern,
      evidence,
      enforceProductionPolicy: false,
    );
  }
  if (fixture.evidence == null) {
    return validator.validatePattern(
      fixture.stage,
      fixture.pattern,
      enforceProductionPolicy: false,
    );
  }
  return validator.validatePatternWithRuntimeEvidence(
    fixture.stage,
    fixture.pattern,
    fixture.evidence!,
    enforceProductionPolicy: false,
  );
}

Set<ValidationIssueCode> _missingExpectedCodes(
  ValidationReport report,
  Set<ValidationIssueCode> expected,
) {
  return expected.where((code) => !report.hasCode(code)).toSet();
}
