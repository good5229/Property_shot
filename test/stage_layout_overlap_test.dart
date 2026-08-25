import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/hidden_mechanic_state.dart';
import 'package:property_shot/game/domain/stage_pattern.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/validation/stage_layout_overlap_audit.dart';

void main() {
  test('생산 중인 모든 스테이지는 서로 다른 초기 시각 요소가 겹치지 않는다', () {
    final overlaps = <StageLayoutOverlap>[
      for (final stage in generatedStageCatalog.stages)
        for (final pattern in stage.patterns)
          ...findInitialStageLayoutOverlaps(stage: stage, pattern: pattern),
    ];

    expect(overlaps, isEmpty, reason: overlaps.join('\n'));
  });

  test('숨은 기믹은 schema 직사각형이 아니라 실제 ? 상자 크기로 감사한다', () {
    const pattern = StagePattern(
      patternId: 'hidden_preview_overlap',
      weight: 1,
      parShots: 1,
      difficultyBand: 'fixture',
      ballSpawn: Vec2(40, 500),
      objects: [
        PatternObjectDefinition(
          id: 'hidden_switch',
          type: EntityType.switchPad,
          position: Vec2(214, 214),
          size: Vec2(62, 40),
          solid: false,
          visualState: HiddenMechanicState.concealed,
        ),
        PatternObjectDefinition(
          id: 'balloon',
          type: EntityType.balloon,
          position: Vec2(184, 260),
          size: Vec2(52, 58),
        ),
      ],
    );
    const stage = StageDefinition(
      stageId: 'fixture',
      title: 'fixture',
      patterns: [pattern],
    );

    final overlaps = findInitialStageLayoutOverlaps(
      stage: stage,
      pattern: pattern,
    );

    expect(overlaps, hasLength(1));
    expect(overlaps.single.firstId, 'hidden_switch');
    expect(overlaps.single.secondId, 'balloon');
    expect(overlaps.single.depth, greaterThan(6));
  });
}
