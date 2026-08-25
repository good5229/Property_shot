/// 캠페인 셔플과 별개인 시연 재생 계약이다.
///
/// `patternId`와 검증된 fixture/event 순서가 영상에 무엇을 보여야 하는지
/// 명시한다. root seed는 녹화 환경의 시각 난수용이며 shuffle bag에 주입하지 않는다.
class DemoPlaybackPlan {
  const DemoPlaybackPlan({
    required this.id,
    required this.stageId,
    required this.patternId,
    required this.visualSeed,
    required this.fixtureId,
    required this.launchDegree,
    required this.launchPower,
    required this.expectedEvents,
  });

  final String id;
  final String stageId;
  final String patternId;
  final int visualSeed;
  final String fixtureId;
  final int launchDegree;
  final double launchPower;
  final List<String> expectedEvents;
}

const stageBouncy01DemoPlaybackPlan = DemoPlaybackPlan(
  id: 'demo_bouncy_01_v1',
  stageId: 'stage_bouncy',
  patternId: 'stage_bouncy_01',
  visualSeed: 0x0b0,
  fixtureId: 'stage_bouncy_01_bouncy_multi_wall_reflection',
  launchDegree: 114,
  launchPower: 0.94,
  expectedEvents: ['bounced', 'bounced', 'bounced', 'hole_entered'],
);
