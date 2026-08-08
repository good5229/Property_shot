import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/persistence/replay_library_store.dart';
import 'package:property_shot/game/persistence/run_state_store.dart';
import 'package:property_shot/game/replay/replay_capture_service.dart';
import 'package:property_shot/game/run/stage_pattern_session.dart';
import 'package:property_shot/ui/replay_library_screen.dart';

void main() {
  testWidgets('저장된 리플레이를 목록에서 검증하고 실제 게임 화면으로 재생한다', (tester) async {
    final library = ReplayLibraryStore(backend: MemoryRunStateBackend());
    final session = StagePatternSession(
      catalog: generatedStageCatalog,
      store: RunStateStore(backend: MemoryRunStateBackend()),
      fixedRootSeed: 73,
      fixedRunId: 'replay-screen-test',
      now: () => DateTime.utc(2026, 8, 8),
    );
    await session.selectStage('stage_heavy');
    await session.recordShot(
      input: const ShotInput(direction: Vec2(0, -1), power: 0.6),
    );
    final document = const ReplayCaptureService().capture(
      runState: session.state!,
      catalog: generatedStageCatalog,
    );
    await library.save(document: document, totalScore: 700);

    await tester.pumpWidget(
      MaterialApp(
        home: ReplayLibraryScreen(store: library, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('1단계'), findsOneWidget);
    expect(find.textContaining('700점'), findsOneWidget);
    await tester.tap(find.textContaining('1단계'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('replay_viewer_screen')), findsOneWidget);
    expect(find.text('리플레이 재생'), findsOneWidget);
  });

  testWidgets('홈과 같은 빈 라이브러리는 한글 빈 상태와 가져오기 행동을 제공한다', (tester) async {
    final library = ReplayLibraryStore(backend: MemoryRunStateBackend());
    await tester.pumpWidget(
      MaterialApp(
        home: ReplayLibraryScreen(store: library, onBack: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 저장된 리플레이가 없습니다.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('replay_import_button')));
    await tester.pumpAndSettle();
    expect(find.text('리플레이 가져오기'), findsOneWidget);
    expect(find.text('검증하고 저장'), findsOneWidget);
  });
}
