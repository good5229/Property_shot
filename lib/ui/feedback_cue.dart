enum FeedbackCue {
  ui,
  trait,
  copy,
  copyCoreAwarded,
  aimCharge,
  launch,
  lightCollision,
  heavyCollision,
  bouncyCollision,
  stickyCollision,
  jellyCollision,
  switchPressed,
  gateOpened,
  holeEntered,
  clear,
  medal,
  discovery,
  rewardActivated,
  restoration,
  labComplete,
  fail,
}

extension FeedbackCueAccessibility on FeedbackCue {
  String get visualLabel => switch (this) {
    FeedbackCue.ui => '선택됨',
    FeedbackCue.trait => '속성 획득',
    FeedbackCue.copy => '속성 복사',
    FeedbackCue.copyCoreAwarded => '복사 코어 획득',
    FeedbackCue.aimCharge => '힘 충전',
    FeedbackCue.launch => '발사',
    FeedbackCue.lightCollision => '가벼운 충돌',
    FeedbackCue.heavyCollision => '강한 충돌',
    FeedbackCue.bouncyCollision => '탄성 반사',
    FeedbackCue.stickyCollision => '점착',
    FeedbackCue.jellyCollision => '젤리 반사',
    FeedbackCue.switchPressed => '스위치 작동',
    FeedbackCue.gateOpened => '문 열림',
    FeedbackCue.holeEntered => '홀 진입',
    FeedbackCue.clear => '스테이지 클리어',
    FeedbackCue.medal => '별 획득',
    FeedbackCue.discovery => '새 발견',
    FeedbackCue.rewardActivated => '보상 발동',
    FeedbackCue.restoration => '시설 복구',
    FeedbackCue.labComplete => '실험 완료',
    FeedbackCue.fail => '이번 샷 실패',
  };

  String get semanticsLabel => '$visualLabel 피드백';

  /// 소리나 진동만으로 사건을 전달하지 않는다는 접근성 계약이다.
  bool get requiresVisualAlternative => true;
}
