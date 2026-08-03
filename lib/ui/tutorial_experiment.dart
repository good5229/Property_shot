enum TutorialExperimentVariant { guided, action, silent }

extension TutorialExperimentVariantDetails on TutorialExperimentVariant {
  String get label => switch (this) {
    TutorialExperimentVariant.guided => '안내형',
    TutorialExperimentVariant.action => '행동 유도형',
    TutorialExperimentVariant.silent => '무설명형',
  };

  String get description => switch (this) {
    TutorialExperimentVariant.guided => '대상과 짧은 행동 문구를 함께 보여줍니다.',
    TutorialExperimentVariant.action => '대상은 보여주고 행동을 먼저 유도합니다.',
    TutorialExperimentVariant.silent => '코치마크와 튜토리얼 문구를 보여주지 않습니다.',
  };

  String get code => switch (this) {
    TutorialExperimentVariant.guided => 'guided',
    TutorialExperimentVariant.action => 'action',
    TutorialExperimentVariant.silent => 'silent',
  };
}
