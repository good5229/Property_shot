import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:property_shot/main.dart';

void main() {
  testWidgets('정상 충전 release는 실제 발사 흐름에 들어간다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final rect = tester.getRect(area);
    final scale = rect.width / 360 < rect.height / 560
        ? rect.width / 360
        : rect.height / 560;
    final origin = Offset(
      rect.left + (rect.width - 360 * scale) / 2,
      rect.top + (rect.height - 560 * scale) / 2,
    );
    final gesture = await tester.createGesture();
    await gesture.down(
      origin + Offset(56 * scale, 456 * scale),
      timeStamp: Duration.zero,
    );
    await tester.pump(const Duration(milliseconds: 760));
    await gesture.up(timeStamp: const Duration(milliseconds: 760));
    await tester.pump();

    expect(find.textContaining('시도 1'), findsOneWidget);
  });

  testWidgets('과충전 release는 시도와 물리 발사를 만들지 않는다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final rect = tester.getRect(area);
    final scale = rect.width / 360 < rect.height / 560
        ? rect.width / 360
        : rect.height / 560;
    final origin = Offset(
      rect.left + (rect.width - 360 * scale) / 2,
      rect.top + (rect.height - 560 * scale) / 2,
    );
    final gesture = await tester.createGesture();
    await gesture.down(
      origin + Offset(56 * scale, 456 * scale),
      timeStamp: Duration.zero,
    );
    await _pumpChargeFrames(tester, const Duration(milliseconds: 2280));
    expect(find.textContaining('손을 떼고 새로 누르세요'), findsOneWidget);
    expect(find.textContaining('회색 · 발사 취소 · 손을 떼면 발사됩니다'), findsNothing);
    await gesture.up(timeStamp: const Duration(milliseconds: 2280));
    await tester.pump();

    expect(find.textContaining('시도 0'), findsOneWidget);
    expect(find.textContaining('과충전되어 발사를 취소했습니다'), findsOneWidget);
  });

  testWidgets('과충전 취소 뒤 새 포인터 입력은 초록에서 다시 시작해 발사한다', (tester) async {
    await tester.pumpWidget(const PropertyShotApp());
    await tester.pump();
    final area = find.byKey(const Key('aim_area'));
    final rect = tester.getRect(area);
    final scale = rect.width / 360 < rect.height / 560
        ? rect.width / 360
        : rect.height / 560;
    final ballPosition = Offset(
      rect.left + (rect.width - 360 * scale) / 2 + 56 * scale,
      rect.top + (rect.height - 560 * scale) / 2 + 456 * scale,
    );

    final overcharged = await tester.createGesture(pointer: 71);
    await overcharged.down(ballPosition, timeStamp: Duration.zero);
    await tester.pump(const Duration(milliseconds: 2200));
    await overcharged.up(timeStamp: const Duration(milliseconds: 2200));
    await tester.pump();
    expect(find.textContaining('시도 0'), findsOneWidget);

    final retry = await tester.createGesture(pointer: 72);
    await retry.down(
      ballPosition,
      timeStamp: const Duration(milliseconds: 2300),
    );
    await tester.pump(const Duration(milliseconds: 760));
    await retry.up(timeStamp: const Duration(milliseconds: 3060));
    await tester.pump();

    expect(find.textContaining('시도 1'), findsOneWidget);
  });
}

Future<void> _pumpChargeFrames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 80);
  var elapsed = Duration.zero;
  while (elapsed + frame <= duration) {
    await tester.pump(frame);
    elapsed += frame;
  }
  if (elapsed < duration) {
    await tester.pump(duration - elapsed);
  }
}
