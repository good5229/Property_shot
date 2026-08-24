import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/input/intent_assist_resolver.dart';
import 'package:property_shot/ui/game_screen.dart';

void main() {
  testWidgets('포인터 근접 실패는 저장 직전 입력에 보정 전·후 증거를 함께 남긴다', (
    tester,
  ) async {
    ShotInput? committed;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _state(),
          showStageSelector: false,
          loadGameAssets: false,
          intentAssistStrength: IntentAssistStrength.standard,
          onShotCommitted: (input, _) async {
            committed = input;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await _launchAt(tester, degrees: 9.5);

    expect(committed, isNotNull);
    expect(committed!.assistKind, ShotAssistKind.targetSnap);
    expect(committed!.assistTargetId, 'target');
    expect(committed!.rawDirection, isNotNull);
    expect(committed!.rawPower, isNotNull);
    expect(committed!.holeForgivenessRadius, 6);
    expect(
      _angleDeltaDegrees(committed!.rawDirection!, committed!.direction),
      lessThanOrEqualTo(3.0001),
    );
  });

  testWidgets('의도 보정 끄기는 같은 포인터 입력을 변경하지 않는다', (tester) async {
    ShotInput? committed;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: _state(),
          showStageSelector: false,
          loadGameAssets: false,
          intentAssistStrength: IntentAssistStrength.off,
          onShotCommitted: (input, _) async {
            committed = input;
            return true;
          },
        ),
      ),
    );
    await tester.pump();

    await _launchAt(tester, degrees: 9.5);

    expect(committed, isNotNull);
    expect(committed!.assistKind, ShotAssistKind.none);
    expect(committed!.assistTargetId, isNull);
    expect(committed!.rawDirection, isNull);
    expect(committed!.rawPower, isNull);
    expect(committed!.holeForgivenessRadius, 0);
  });
}

Future<void> _launchAt(WidgetTester tester, {required double degrees}) async {
  final start = _logicalOffset(tester, 100, 280);
  final radians = degrees * math.pi / 180;
  final target = _logicalOffset(
    tester,
    100 + math.cos(radians) * 100,
    280 + math.sin(radians) * 100,
  );
  const downAt = Duration(seconds: 10);
  const heldFor = Duration(milliseconds: 1150);
  final gesture = await tester.createGesture();
  await gesture.down(start, timeStamp: downAt);
  await tester.pump(const Duration(milliseconds: 500));
  await gesture.moveTo(target, timeStamp: downAt + heldFor);
  await gesture.up(timeStamp: downAt + heldFor);
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Offset _logicalOffset(WidgetTester tester, double x, double y) {
  final rect = tester.getRect(find.byKey(const Key('aim_area')));
  final scale = math.min(rect.width / 360, rect.height / 560);
  final origin = Offset(
    rect.left + (rect.width - 360 * scale) / 2,
    rect.top + (rect.height - 560 * scale) / 2,
  );
  return origin + Offset(x * scale, y * scale);
}

double _angleDeltaDegrees(Vec2 from, Vec2 to) {
  final cross = from.x * to.y - from.y * to.x;
  final dot = from.x * to.x + from.y * to.y;
  return math.atan2(cross, dot).abs() * 180 / math.pi;
}

GameState _state() => const GameState(
  levelIndex: 0,
  levelName: '의도 보정 UI 시험',
  ballSpawn: Vec2(100, 280),
  entities: [
    EntityState(
      id: 'active_ball',
      type: EntityType.ball,
      position: Vec2(100, 280),
      size: Vec2(20, 20),
      movable: true,
      hitboxScale: 1,
    ),
    EntityState(
      id: 'target',
      type: EntityType.crate,
      position: Vec2(260, 280),
      size: Vec2(32, 32),
      movable: false,
      hitboxScale: 0.88,
    ),
    EntityState(
      id: 'hole',
      type: EntityType.hole,
      position: Vec2(320, 480),
      size: Vec2(30, 30),
      solid: false,
    ),
  ],
);
