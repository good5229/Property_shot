import '../domain/stage_pattern.dart';
import 'stable_seed.dart';
import 'stage_shuffle_bag.dart';

enum CampaignPatternRole { learn, confirm, apply, mastery }

/// 일반 캠페인의 첫 cycle을 학습 파형으로 구성하는 패턴 선택 정책이다.
///
/// 저장된 중간 bag과 두 번째 cycle 이후의 공용 셔플은 건드리지 않는다.
class CampaignStageSelectionPolicy {
  const CampaignStageSelectionPolicy._();

  static const Map<String, List<String>> learningWavePatternIds = {
    'stage_heavy': [
      'stage_heavy_01',
      'stage_heavy_03',
      'stage_heavy_02',
      'stage_heavy_04',
    ],
    'stage_bouncy': [
      'stage_bouncy_01',
      'stage_bouncy_03',
      'stage_bouncy_02',
      'stage_bouncy_04',
    ],
    'stage_chain_gate': [
      'stage_chain_gate_01',
      'stage_chain_gate_03',
      'stage_chain_gate_04',
      'stage_chain_gate_02',
    ],
    'stage_balloon': [
      'stage_balloon_03',
      'stage_balloon_02',
      'stage_balloon_01',
      'stage_balloon_04',
    ],
    'stage_drained': [
      'stage_drained_03',
      'stage_drained_01',
      'stage_drained_02',
      'stage_drained_04',
    ],
    'stage_speed': [
      'stage_speed_01',
      'stage_speed_02',
      'stage_speed_03',
      'stage_speed_04',
    ],
    'stage_persistent': [
      'stage_persistent_01',
      'stage_persistent_02',
      'stage_persistent_03',
      'stage_persistent_04',
    ],
    'stage_chain_score': [
      'stage_chain_score_01',
      'stage_chain_score_02',
      'stage_chain_score_04',
      'stage_chain_score_03',
    ],
    'stage_rotating_reflector': [
      'stage_rotating_reflector_01',
      'stage_rotating_reflector_02',
      'stage_rotating_reflector_04',
      'stage_rotating_reflector_03',
    ],
    'stage_property_shot': [
      'stage_property_shot_a',
      'stage_property_shot_b',
      'stage_property_shot_d',
      'stage_property_shot_c',
    ],
  };

  static CampaignPatternRole roleFor({
    required String stageId,
    required String patternId,
  }) {
    final index = learningWavePatternIds[stageId]?.indexOf(patternId) ?? -1;
    if (index < 0 || index >= CampaignPatternRole.values.length) {
      throw StateError('캠페인 학습 역할이 없습니다: $stageId/$patternId');
    }
    return CampaignPatternRole.values[index];
  }

  static bool shouldPreferTutorialBaseline({
    required int stageIndex,
    required bool alreadyCleared,
  }) {
    return stageIndex >= 0 && !alreadyCleared;
  }

  /// 이전 호출부 호환용 이름이다. fresh bag에서는 이제 baseline 하나가 아니라
  /// learn→confirm→apply→mastery 전체 순서를 저장한다.
  static StagePatternDraw drawTutorialBaselineFirst({
    required StageDefinition stage,
    required StageShuffleBagState state,
    required int rootSeed,
  }) => drawLearningWave(stage: stage, state: state, rootSeed: rootSeed);

  static StagePatternDraw drawLearningWave({
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

    final orderedIds = learningWavePatternIds[stage.stageId];
    final actualIds = stage.patterns
        .map((pattern) => pattern.patternId)
        .toSet();
    if (orderedIds == null ||
        orderedIds.length != stage.patterns.length ||
        orderedIds.toSet().length != orderedIds.length ||
        orderedIds.toSet().difference(actualIds).isNotEmpty ||
        actualIds.difference(orderedIds.toSet()).isNotEmpty) {
      throw StateError('캠페인 학습 파형이 카탈로그와 일치하지 않습니다: ${stage.stageId}');
    }
    final patternId = orderedIds.first;
    final pattern = stage.patternById(patternId);

    final patternSeed = StableSeed.patternSeed(
      rootSeed: rootSeed,
      stageId: stage.stageId,
      cycle: standard.cycle,
      drawIndex: standard.drawIndex,
      patternId: patternId,
    );
    return StagePatternDraw(
      stageId: stage.stageId,
      patternId: patternId,
      patternSeed: patternSeed,
      cycle: standard.cycle,
      drawIndex: standard.drawIndex,
      pattern: pattern,
      nextState: StageShuffleBagState(
        stageId: stage.stageId,
        cycle: standard.nextState.cycle,
        drawIndex: standard.nextState.drawIndex,
        remainingPatternIds: orderedIds.skip(1).toList(growable: false),
        lastPatternId: patternId,
      ),
    );
  }
}
