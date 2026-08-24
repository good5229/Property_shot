import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/ui/bonus_goal.dart';

void main() {
  test('첫 단계는 세 번 이하의 클리어를 추가 도전으로 인정한다', () {
    expect(
      bonusGoalReached(
        levelIndex: 0,
        shotCount: 3,
        bumperHit: false,
        switchPressed: false,
      ),
      isTrue,
    );
    expect(
      bonusGoalReached(
        levelIndex: 0,
        shotCount: 4,
        bumperHit: false,
        switchPressed: false,
      ),
      isFalse,
    );
  });

  test('두 번째 단계는 젤리 충돌을 추가 도전으로 인정한다', () {
    expect(
      bonusGoalReached(
        levelIndex: 1,
        shotCount: 2,
        bumperHit: true,
        switchPressed: false,
      ),
      isTrue,
    );
    expect(
      bonusGoalReached(
        levelIndex: 1,
        shotCount: 2,
        bumperHit: false,
        switchPressed: false,
      ),
      isFalse,
    );
  });

  test('세 번째 단계는 스위치 작동을 추가 도전으로 인정한다', () {
    expect(
      bonusGoalReached(
        levelIndex: 2,
        shotCount: 2,
        bumperHit: false,
        switchPressed: true,
      ),
      isTrue,
    );
    expect(
      bonusGoalReached(
        levelIndex: 2,
        shotCount: 2,
        bumperHit: false,
        switchPressed: false,
      ),
      isFalse,
    );
  });

  test('되감기는 직전 발사 전의 추가 도전 누적 상태를 복원한다', () {
    var bumperHit = false;
    var switchPressed = false;
    final bumperHistory = <bool>[bumperHit];
    final switchHistory = <bool>[switchPressed];

    bumperHit = true;
    switchPressed = true;
    bumperHit = bumperHistory.removeAt(0);
    switchPressed = switchHistory.removeAt(0);

    expect(bumperHit, isFalse);
    expect(switchPressed, isFalse);
  });

  test('6·7·9단계는 새 기믹을 실제 사용한 성공만 선택 도전으로 인정한다', () {
    expect(_achieved(5, ['power_slider_activated']), isTrue);
    expect(_achieved(6, ['spent_ball_bounced']), isTrue);
    expect(_achieved(8, ['reflector_rotated']), isTrue);
    expect(_achieved(5, const []), isFalse);
    expect(_achieved(6, const []), isFalse);
    expect(_achieved(8, const []), isFalse);
  });

  test('10단계는 서로 다른 속성 기믹 둘 이상의 결합을 요구한다', () {
    expect(_achieved(9, ['power_slider_activated']), isFalse);
    expect(
      _achieved(9, ['power_slider_activated', 'reflector_rotated']),
      isTrue,
    );
  });
}

bool _achieved(int levelIndex, List<String> events) => stageBonusGoalReached(
  levelIndex: levelIndex,
  shotCount: 2,
  results: [
    ShotResult(
      state: levels[levelIndex]
          .createState(levelIndex)
          .copyWith(phase: GamePhase.success, shotCount: 2),
      path: const [],
      events: events,
    ),
  ],
);
