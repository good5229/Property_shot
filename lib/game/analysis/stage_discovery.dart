import '../domain/entity_state.dart';
import '../domain/game_state.dart';
import '../domain/shot_input.dart';
import '../domain/trait.dart';
import '../simulation/shot_resolver.dart';

/// 클리어 여부와 별개로 플레이어가 이번 탐사에서 확인한 인과를 요약한다.
/// 물리 상태에는 들어가지 않으므로 replay와 판정 결과를 바꾸지 않는다.
class StageDiscoveryMilestone {
  const StageDiscoveryMilestone({
    required this.id,
    required this.label,
    required this.achieved,
  });

  final String id;
  final String label;
  final bool achieved;
}

String stageDiscoveryQuestion(int levelIndex) => switch (levelIndex) {
  0 => '무거운 공으로 상자를 움직여 길을 만들 수 있을까?',
  1 => '탄성을 옮겨 벽 반사를 내 경로로 바꿀 수 있을까?',
  2 => '속성과 스위치를 이어 닫힌 문을 열 수 있을까?',
  3 => '뾰족한 공으로 풍선 뒤의 장치를 드러낼 수 있을까?',
  4 => '공이 얻은 능력과 비워진 원본을 함께 쓸 수 있을까?',
  5 => '감속한 공을 발판으로 다시 가속할 수 있을까?',
  6 => '과거 공을 남겨 다음 발사의 도구로 쓸 수 있을까?',
  7 => '여러 충돌을 이으면 더 깊은 연쇄를 만들 수 있을까?',
  8 => '반사판을 돌려 다음 공의 길을 바꿀 수 있을까?',
  9 => '배운 속성과 기물을 나만의 순서로 엮을 수 있을까?',
  _ => '기물의 반응을 발견해 새로운 길을 만들 수 있을까?',
};

String stageDiscoveryCompactPath(int levelIndex) => switch (levelIndex) {
  0 => '무거움 → 상자 → 홀',
  1 => '탄성 → 벽 반사 → 홀',
  2 => '스위치 → 문 → 홀',
  3 => '뾰족함 → 풍선 → 장치',
  4 => '능력 획득 → 원본 이동',
  5 => '감속 → 발판 → 재가속',
  6 => '과거 공 → 다음 충돌',
  7 => '기물 2개 → 연쇄 4단계',
  8 => '반사판 회전 → 다음 경로',
  9 => '속성 → 기믹 연계 → 홀',
  _ => '기믹 반응 → 새로운 경로',
};

List<StageDiscoveryMilestone> stageDiscoveryMilestones({
  required GameState state,
  required Iterable<ShotInput> shotInputs,
  required Iterable<ShotResult> shotResults,
}) {
  final inputs = shotInputs.toList(growable: false);
  final results = shotResults.toList(growable: false);
  final events = <String>{for (final result in results) ...result.events};
  final impacts = [for (final result in results) ...result.impacts];
  final moves = [for (final result in results) ...result.moves];
  final usedTraits = <TraitType>{};
  for (final input in inputs) {
    final trait = input.equippedTrait;
    if (trait != null) usedTraits.add(trait);
  }
  usedTraits.addAll(state.entityById('active_ball')?.traits ?? const {});
  final success = state.phase == GamePhase.success;
  final hasWallImpact = impacts.any(
    (impact) => impact.entityType == EntityType.wall,
  );
  final hasSpentBall = state.entities.any(
    (entity) => entity.type == EntityType.ball && entity.id != 'active_ball',
  );

  StageDiscoveryMilestone item(String id, String label, bool achieved) =>
      StageDiscoveryMilestone(id: id, label: label, achieved: achieved);

  final mechanics = switch (state.levelIndex) {
    0 => [
      item('heavy_equipped', '무거움 장착', usedTraits.contains(TraitType.heavy)),
      item(
        'crate_moved',
        '상자 움직임',
        impacts.any((impact) => impact.entityType == EntityType.crate) ||
            moves.any((move) => move.entityId.contains('crate')),
      ),
    ],
    1 => [
      item('bouncy_equipped', '탄성 장착', usedTraits.contains(TraitType.bouncy)),
      item(
        'wall_bounce',
        '벽 반사 발견',
        hasWallImpact || events.contains('bounced'),
      ),
    ],
    2 => [
      item('switch_pressed', '스위치 작동', events.contains('switch_pressed')),
      item(
        'gate_opened',
        '문 열림',
        events.any((event) => event.contains('gate_open')) ||
            state.entities.any(
              (entity) => entity.type == EntityType.gate && !entity.active,
            ),
      ),
    ],
    3 => [
      item('sharp_equipped', '뾰족함 장착', usedTraits.contains(TraitType.sharp)),
      item(
        'balloon_popped',
        '풍선 파열',
        events.contains('balloon_popped') ||
            state.entities.any(
              (entity) => entity.type == EntityType.balloon && !entity.active,
            ),
      ),
    ],
    4 => [
      item(
        'source_drained',
        '원본 비우기',
        state.entities.any((entity) => entity.visualState == 'drained'),
      ),
      item(
        'drained_source_moved',
        '비워진 원본 이동',
        events.contains('drained_source_moved') ||
            moves.any((move) => move.entityId.contains('source')),
      ),
    ],
    5 => [
      item(
        'speed_restored',
        '발판 가속',
        results.any((result) => result.powerSliderActivations.isNotEmpty),
      ),
      item('speed_bank', '가속 뒤 반사', hasWallImpact),
    ],
    6 => [
      item('past_ball_left', '과거 공 남기기', hasSpentBall),
      item(
        'past_ball_used',
        '과거 공 재활용',
        impacts.any((impact) => impact.entityType == EntityType.ball) ||
            events.contains('spent_ball_bounced'),
      ),
    ],
    7 => [
      item(
        'chain_started',
        '연쇄 시작',
        impacts
                .where((impact) => impact.entityType != EntityType.hole)
                .length >=
            2,
      ),
      item(
        'chain_deepened',
        '연쇄 4단계',
        impacts
                .where((impact) => impact.entityType != EntityType.hole)
                .length >=
            4,
      ),
    ],
    8 => [
      item(
        'reflector_rotated',
        '반사판 회전',
        results.any((result) => result.reflectorRotations.isNotEmpty),
      ),
      item('rotated_route_used', '바뀐 면 활용', state.shotCount >= 2),
    ],
    _ => [
      item('trait_combined', '속성 활용', usedTraits.isNotEmpty),
      item(
        'systems_combined',
        '기믹 연계',
        results.any(
              (result) =>
                  result.powerSliderActivations.isNotEmpty ||
                  result.reflectorRotations.isNotEmpty,
            ) ||
            hasSpentBall ||
            impacts
                    .where((impact) => impact.entityType != EntityType.hole)
                    .length >=
                3,
      ),
    ],
  };

  return List.unmodifiable([
    ...mechanics,
    item('hole_reached', '홀 도착', success),
  ]);
}
