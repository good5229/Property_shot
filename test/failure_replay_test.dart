import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/failure_replay.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';

void main() {
  test('실패 원인 분석은 충돌 순서와 마지막 접촉을 한글로 만든다', () {
    final before = levels.first.createState(0, productRules: true);
    final impact = ShotImpact(
      entityId: 'wall_top',
      entityType: EntityType.wall,
      position: const Vec2(180, 40),
      normal: const Vec2(0, 1),
      pathIndex: 2,
      strength: 0.8,
    );
    final result = ShotResult(
      state: before.copyWith(shotCount: 1),
      path: const [Vec2(80, 500), Vec2(140, 180), Vec2(180, 40)],
      events: const ['power_low', 'bounced'],
      impacts: [impact],
      physicsEvents: buildPhysicsEvents(
        path: const [Vec2(80, 500), Vec2(140, 180), Vec2(180, 40)],
        impacts: [impact],
        moves: const [],
        chainSafetyDiagnostics: const [],
      ),
    );
    final data = FailureReplayData(
      beforeState: before,
      input: const ShotInput(direction: Vec2(1, -1), power: 0.2),
      result: result,
    );

    final analysis = const FailureReplayAnalyzer().analyze(data);

    expect(analysis.title, '힘 조절이 필요해요');
    expect(analysis.detail, contains('마지막 충돌'));
    expect(analysis.lastContact?.label, '벽');
    expect(analysis.lastContact?.highlight, isTrue);
    expect(analysis.markers.single.label, '벽');
  });

  test('실패 인과 분석은 판정 상태와 결과 객체를 변경하지 않는다', () {
    final before = levels.first.createState(0, productRules: true);
    final result = const ShotResolver().resolve(
      before,
      const ShotInput(direction: Vec2(-1, 0), power: 0.2),
    );
    final data = FailureReplayData(
      beforeState: before,
      input: const ShotInput(direction: Vec2(-1, 0), power: 0.2),
      result: result,
    );
    final originalEntities = result.state.entities;

    const FailureReplayAnalyzer().analyze(data);

    expect(identical(result.state.entities, originalEntities), isTrue);
    expect(result.state.shotCount, greaterThanOrEqualTo(1));
  });

  test('근소한 홀 빗나감은 첫 실패와 반복 실패의 정보량을 다르게 만든다', () {
    final before = levels.first.createState(0, productRules: true);
    final hole = before.entities.firstWhere(
      (entity) => entity.type == EntityType.hole,
    );
    final ball = before.activeBall;
    final edge = hole.hitRadius + ball.hitRadius + 8;
    final result = ShotResult(
      state: before.copyWith(shotCount: 1),
      path: [before.ballSpawn, hole.position + Vec2(edge, 0)],
      events: const [],
    );
    final data = FailureReplayData(
      beforeState: before,
      input: const ShotInput(direction: Vec2(1, 0), power: 0.6),
      result: result,
    );

    final advice = const FailureActionAdvisor().analyze(data);

    expect(advice.causeKey, 'near_hole');
    expect(advice.messageForAttempt(1), '목표를 근소하게 지나쳤어요.');
    expect(advice.messageForAttempt(2), contains('각도를 한 칸'));
  });

  test('기믹 거부는 힘 피드백보다 먼저 분류한다', () {
    final before = levels.first.createState(0, productRules: true);
    final result = ShotResult(
      state: before.copyWith(shotCount: 1),
      path: [before.ballSpawn],
      events: const ['switch_rejected', 'power_low'],
    );
    final advice = const FailureActionAdvisor().analyze(
      FailureReplayData(
        beforeState: before,
        input: const ShotInput(direction: Vec2(1, 0), power: 0.2),
        result: result,
      ),
    );

    expect(advice.causeKey, 'mechanic_required');
    expect(advice.headline, '기믹을 먼저 작동해야 해요.');
  });
}
