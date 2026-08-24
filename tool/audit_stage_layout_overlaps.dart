// ignore_for_file: avoid_print

import 'dart:io';

import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/validation/stage_layout_overlap_audit.dart';

void main() {
  final overlaps =
      <StageLayoutOverlap>[
        for (final stage in generatedStageCatalog.stages)
          for (final pattern in stage.patterns)
            ...findInitialStageLayoutOverlaps(stage: stage, pattern: pattern),
      ]..sort((first, second) {
        final stageOrder = first.stageId.compareTo(second.stageId);
        if (stageOrder != 0) return stageOrder;
        final patternOrder = first.patternId.compareTo(second.patternId);
        if (patternOrder != 0) return patternOrder;
        return second.depth.compareTo(first.depth);
      });

  if (overlaps.isEmpty) {
    print('생산 패턴 전체에서 초기 시각 요소 겹침이 없습니다.');
    return;
  }
  for (final overlap in overlaps) {
    print(overlap);
  }
  print('총 ${overlaps.length}개 요소 쌍이 겹칩니다.');
  exitCode = 1;
}
