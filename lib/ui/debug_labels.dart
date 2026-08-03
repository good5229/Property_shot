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
