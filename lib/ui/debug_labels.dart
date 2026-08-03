/// 개발 진단 화면에서도 내부 식별자를 사용자 언어로 표시한다.
String debugEntityLabel(String id) {
  if (id == 'active_ball' || id.startsWith('spent_ball_')) {
    return '공';
  }
  if (id == 'hole') return '홀';
  if (id.startsWith('wall_') || id == 'blocker' || id == 'approach_guard') {
    return '벽';
  }
  if (id.startsWith('crate') || id == 'balloon_crate') return '상자';
  if (id == 'anvil' || id == 'steel') return '무거운 돌';
  if (id == 'jelly') return '젤리';
  if (id == 'glue') return '점착판';
  if (id == 'switch' || id == 'balloon_switch') return '스위치';
  if (id == 'gate' || id == 'balloon_gate') return '문';
  if (id == 'balloon') return '풍선';
  if (id == 'spike_source') return '뾰족함 원본';
  return '물체';
}

String debugEntityTypeLabel(String type) {
  return switch (type) {
    'ball' => '공',
    'hole' => '홀',
    'wall' => '벽',
    'crate' => '상자',
    'weight' => '무거운 돌',
    'bumper' => '젤리',
    'stickySurface' => '점착판',
    'switchPad' => '스위치',
    'gate' => '문',
    'balloon' => '풍선',
    'spikeSource' => '뾰족함 원본',
    _ => '물체',
  };
}

String debugPhaseLabel(String phase) {
  return switch (phase) {
    'ready' => '준비',
    'aiming' => '조준',
    'charging' => '힘 모으기',
    'animating' => '이동 중',
    'success' => '성공',
    'failed' => '실패',
    'paused' => '멈춤',
    _ => '진행 중',
  };
}

String debugPhysicsEventLabel(String kind) {
  return switch (kind) {
    'impact' => '충돌',
    'move' => '이동',
    'capture' => '홀 포획',
    'stateChange' => '상태 변경',
    'traitTransfer' => '속성 이전',
    _ => '물리 사건',
  };
}
