import '../domain/stage_catalog.dart';
import '../domain/stage_pattern.dart';
import 'stable_seed.dart';
import 'stage_shuffle_bag.dart';

/// 일반 캠페인의 첫 학습 진입에만 적용하는 패턴 선택 정책이다.
///
/// 물리 카탈로그와 공용 셔플 알고리즘은 건드리지 않고, fresh bag의 첫 draw가
/// 기준 패턴이 되도록 이미 만들어진 결정론적 bag 순서만 교환한다.
class CampaignStageSelectionPolicy {
  const CampaignStageSelectionPolicy._();

  static const int tutorialStageCount = 4;

  static bool shouldPreferTutorialBaseline({
    required int stageIndex,
    required bool alreadyCleared,
  }) {
    return stageIndex >= 0 &&
        stageIndex < tutorialStageCount &&
        !alreadyCleared;
  }

  static StagePatternDraw drawTutorialBaselineFirst({
    required StageDefinition stage,
    required StageShuffleBagState state,
    required int rootSeed,
  }) {
    final standard = StageShuffleBag.draw(
      stage: stage,
      state: state,
      rootSeed: rootSeed,
    );
    if (state.drawIndex != 0) return standard;

    final baseline = stage.patterns.singleWhere(
      (pattern) =>
          pattern.metadata[StageCatalog.baselineMetadataKey] ==
          StageCatalog.baselineMetadataValue,
    );
    if (standard.patternId == baseline.patternId) return standard;

    final remaining = standard.nextState.remainingPatternIds.toList();
    final baselineIndex = remaining.indexOf(baseline.patternId);
    if (baselineIndex < 0) return standard;
    remaining[baselineIndex] = standard.patternId;

    final patternSeed = StableSeed.patternSeed(
      rootSeed: rootSeed,
      stageId: stage.stageId,
      cycle: standard.cycle,
      drawIndex: standard.drawIndex,
      patternId: baseline.patternId,
    );
    return StagePatternDraw(
      stageId: stage.stageId,
      patternId: baseline.patternId,
      patternSeed: patternSeed,
      cycle: standard.cycle,
      drawIndex: standard.drawIndex,
      pattern: baseline,
      nextState: StageShuffleBagState(
        stageId: stage.stageId,
        cycle: standard.nextState.cycle,
        drawIndex: standard.nextState.drawIndex,
        remainingPatternIds: remaining,
        lastPatternId: baseline.patternId,
      ),
    );
  }
}
