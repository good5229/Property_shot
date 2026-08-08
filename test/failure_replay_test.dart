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
}
