import 'package:flutter_test/flutter_test.dart';
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
}
