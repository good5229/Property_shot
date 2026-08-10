import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/hint/hint_catalog.dart';
import 'package:property_shot/game/hint/pattern_hint.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';

void main() {
  late StageCatalog stages;
  late HintCatalog hints;

  setUpAll(() {
    stages = StageCatalog.fromJsonString(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    hints = HintCatalog.fromJsonString(
      File('assets/stages/hints_v1.json').readAsStringSync(),
    );
  });

  test('40개 생산 패턴에는 패턴별 구체적 L1/L2 힌트가 있다', () {
    expect(hints.entries, hasLength(40));
    final report = StagePatternValidator().validateHintCatalog(
      stages.stages,
      hints,
    );
    expect(report.isValid, isTrue, reason: report.issues.join('\n'));
    final demo = hints.entryFor(
      stageId: 'stage_bouncy',
      patternId: 'stage_bouncy_01',
    );
    expect(demo.directClearPolicy.allowed, isFalse);
    expect(demo.directClearPolicy.demoPreferred, isTrue);
    expect(demo.key, isNotNull);
  });

  test('요청된 hint/key/direct-clear invalid meta fixture를 모두 탐지한다', () {
    final stage = _stage();
    final validator = StagePatternValidator();
    final cases = <String, ({HintCatalog catalog, ValidationIssueCode code})>{
      'invalid_key_unreachable': (
        catalog: _catalog(
          key: const HintKeyDefinition(
            id: 'key',
            position: Vec2(300, 280),
            size: Vec2(28, 28),
            version: 1,
          ),
        ),
        code: ValidationIssueCode.keyUnreachable,
      ),
      'invalid_key_overlap': (
        catalog: _catalog(
          key: const HintKeyDefinition(
            id: 'key',
            position: Vec2(180, 280),
            size: Vec2(28, 28),
            version: 1,
          ),
        ),
        code: ValidationIssueCode.keyOverlapsSolid,
      ),
      'invalid_key_blocks_hole': (
        catalog: _catalog(
          key: const HintKeyDefinition(
            id: 'key',
            position: Vec2(300, 280),
            size: Vec2(28, 28),
            version: 1,
          ),
        ),
        code: ValidationIssueCode.keyOverlapsHole,
      ),
      'invalid_hint_missing': (
        catalog: const HintCatalog(version: 1, entries: []),
        code: ValidationIssueCode.hintMissing,
      ),
      'invalid_hint_wrong_pattern': (
        catalog: _catalog(refs: const {'not_in_this_pattern'}),
        code: ValidationIssueCode.hintUnknownReference,
      ),
      'invalid_hint_too_vague': (
        catalog: _catalog(refs: const {}),
        code: ValidationIssueCode.hintTooVague,
      ),
      'invalid_hint_exact_solution': (
        catalog: _catalog(text: '42도와 70% 힘으로 발사하세요.'),
        code: ValidationIssueCode.hintExactSolution,
      ),
      'invalid_hint_duplicate_level': (
        catalog: _catalog(hints: [_hint(1), _hint(1)]),
        code: ValidationIssueCode.hintInvalidLevel,
      ),
      'invalid_hint_noncontiguous_level': (
        catalog: _catalog(hints: [_hint(1), _hint(3)]),
        code: ValidationIssueCode.hintInvalidLevel,
      ),
      'invalid_hint_unexpected_l3': (
        catalog: _catalog(hints: [_hint(1), _hint(2), _hint(3)]),
        code: ValidationIssueCode.hintInvalidLevel,
      ),
    };
    for (final entry in cases.entries) {
      final report = validator.validateHintCatalog([
        stage,
      ], entry.value.catalog);
      expect(
        report.hasCode(entry.value.code),
        isTrue,
        reason: '${entry.key}: ${report.issues}',
      );
    }
    final direct = _directStage();
    final directReport = validator.validateHintCatalog(
      [direct],
      _catalogForStage(direct, policy: const DirectClearPolicy(allowed: false)),
    );
    expect(
      directReport.hasCode(ValidationIssueCode.demoDirectClear),
      isTrue,
      reason: 'invalid_demo_direct_clear: ${directReport.issues}',
    );
  });
}

StageDefinition _directStage() {
  const pattern = StagePattern(
    patternId: 'direct',
    weight: 1,
    parShots: 1,
    difficultyBand: 'test',
    ballSpawn: Vec2(60, 280),
    objects: [
      PatternObjectDefinition(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(300, 280),
        size: Vec2(72, 72),
        solid: false,
      ),
    ],
  );
  return const StageDefinition(
    stageId: 'direct_stage',
    title: 'direct',
    patterns: [pattern],
  );
}

StageDefinition _stage() {
  const pattern = StagePattern(
    patternId: 'fixture',
    weight: 1,
    parShots: 1,
    difficultyBand: 'test',
    ballSpawn: Vec2(60, 280),
    objects: [
      PatternObjectDefinition(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(300, 280),
        size: Vec2(40, 40),
        solid: false,
      ),
      PatternObjectDefinition(
        id: 'blocker',
        type: EntityType.wall,
        position: Vec2(180, 280),
        size: Vec2(28, 220),
      ),
    ],
  );
  return const StageDefinition(
    stageId: 'fixture_stage',
    title: 'fixture',
    patterns: [pattern],
  );
}

HintCatalog _catalog({
  DirectClearPolicy policy = const DirectClearPolicy(allowed: true),
  HintKeyDefinition? key,
  Set<String> refs = const {'hole'},
  String text = '홀 앞의 길을 먼저 살펴보세요.',
  List<PatternHint>? hints,
}) => HintCatalog(
  version: 1,
  entries: [
    PatternHintEntry(
      stageId: 'fixture_stage',
      patternId: 'fixture',
      hintVersion: 1,
      intentTags: const {'route'},
      directClearPolicy: policy,
      key: key,
      hints:
          hints ??
          [
            PatternHint(
              level: 1,
              text: text,
              intentTags: const {'route'},
              referencedObjectIds: refs,
            ),
            const PatternHint(
              level: 2,
              text: '벽과 홀의 관계를 이용해 보세요.',
              intentTags: {'bank'},
              referencedObjectIds: {'blocker', 'hole'},
            ),
          ],
    ),
  ],
);

PatternHint _hint(int level) => PatternHint(
  level: level,
  text: '벽과 홀의 관계를 이용해 보세요.',
  intentTags: const {'route'},
  referencedObjectIds: const {'blocker', 'hole'},
);

HintCatalog _catalogForStage(
  StageDefinition stage, {
  required DirectClearPolicy policy,
}) => HintCatalog(
  version: 1,
  entries: [
    PatternHintEntry(
      stageId: stage.stageId,
      patternId: stage.patterns.single.patternId,
      hintVersion: 1,
      intentTags: const {'route'},
      directClearPolicy: policy,
      hints: const [
        PatternHint(
          level: 1,
          text: '홀로 가는 길을 살펴보세요.',
          intentTags: {'route'},
          referencedObjectIds: {'hole'},
        ),
        PatternHint(
          level: 2,
          text: '홀의 앞쪽으로 공을 보내 보세요.',
          intentTags: {'route'},
          referencedObjectIds: {'hole'},
        ),
      ],
    ),
  ],
);
