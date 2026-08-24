import '../game/domain/entity_state.dart';
import '../game/domain/game_state.dart';
import '../game/simulation/shot_resolver.dart';

bool bonusGoalReached({
  required int levelIndex,
  required int shotCount,
  required bool bumperHit,
  required bool switchPressed,
  bool drainedSourceMoved = false,
}) {
  if (shotCount <= 0) {
    return false;
  }
  return switch (levelIndex) {
    0 => shotCount <= 3,
    1 => bumperHit,
    2 || 3 => switchPressed,
    4 => drainedSourceMoved,
    _ => false,
  };
}

/// 완료 화면과 재개 복구가 같은 기준으로 선택 도전을 판정한다.
///
/// 6~10단계는 단순 클리어가 아니라 각 단계에서 새로 배운 기믹을 실제로
/// 사용했는지를 결과 증거로 확인한다. 8단계는 별도의 연쇄 분석기가 맡는다.
bool stageBonusGoalReached({
  required int levelIndex,
  required int shotCount,
  required Iterable<ShotResult> results,
  bool drainedSourceMoved = false,
}) {
  final completedResults = results.toList(growable: false);
  if (shotCount <= 0 ||
      completedResults.isEmpty ||
      completedResults.last.state.phase != GamePhase.success) {
    return false;
  }
  final events = completedResults.expand((result) => result.events).toSet();
  final impacts = completedResults.expand((result) => result.impacts).toList();
  final bumperHit = impacts.any(
    (impact) => impact.entityType == EntityType.bumper,
  );
  final switchPressed =
      events.contains('switch_pressed') ||
      events.contains('balloon_switch_pressed');

  return switch (levelIndex) {
    0 => shotCount <= 3,
    1 => bumperHit,
    2 => switchPressed,
    3 => events.contains('balloon_switch_revealed') || switchPressed,
    4 => drainedSourceMoved,
    5 =>
      events.contains('power_slider_activated') ||
          completedResults.any(
            (result) => result.powerSliderActivations.isNotEmpty,
          ),
    6 =>
      events.contains('spent_ball_bounced') ||
          impacts.any(
            (impact) =>
                impact.entityId.startsWith('spent_ball_') ||
                impact.sourceEntityId.startsWith('spent_ball_'),
          ),
    7 => false,
    8 =>
      events.contains('reflector_rotated') ||
          completedResults.any(
            (result) => result.reflectorRotations.isNotEmpty,
          ),
    9 => _propertyShotMechanicCount(completedResults, events) >= 2,
    _ => false,
  };
}

int _propertyShotMechanicCount(List<ShotResult> results, Set<String> events) {
  var count = 0;
  if (events.contains('power_slider_activated')) count++;
  if (events.contains('reflector_rotated') ||
      results.any((result) => result.reflectorRotations.isNotEmpty)) {
    count++;
  }
  if (events.contains('sticky_attached') ||
      events.contains('spent_ball_bounced')) {
    count++;
  }
  if (events.contains('balloon_bounced') || events.contains('balloon_popped')) {
    count++;
  }
  if (events.contains('crate_pushed') || events.contains('switch_pressed')) {
    count++;
  }
  if (results.any(
    (result) => result.moves.any(
      (move) => move.visualState == 'drained' || move.visualState == 'pushed',
    ),
  )) {
    count++;
  }
  return count;
}
