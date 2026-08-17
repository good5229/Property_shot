import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/level_definition.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/ui/game_screen.dart';

import 'fixtures/stage_chain_score_patterns.dart';

void main() {
  testWidgets('8단계 되돌리기는 저장 완료 뒤에만 점수용 샷 기록을 제거한다', (tester) async {
    final setup = _setup();
    final persisted = Completer<void>();
    var rewindCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: setup.first.state,
          initialShotResults: [setup.first],
          levelOverride: setup.level,
          showStageSelector: false,
          loadGameAssets: false,
          onShotRewound: () async {
            rewindCalls++;
            await persisted.future;
            return const <String>{};
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('시도 횟수 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('rewind_button')).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('rewind_button')).first);
    await tester.pump();
    expect(find.byTooltip('시도 횟수 1'), findsOneWidget);
    expect(rewindCalls, 1);

    persisted.complete();
    await _pumpForAsyncWork(tester);
    expect(find.byTooltip('시도 횟수 0'), findsOneWidget);
  });

  testWidgets('8단계 처음부터는 저장 완료 뒤에만 화면과 샷 기록을 초기화한다', (tester) async {
    final setup = _setup();
    final persisted = Completer<void>();
    var restartCalls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: setup.first.state,
          initialShotResults: [setup.first],
          levelOverride: setup.level,
          showStageSelector: false,
          loadGameAssets: false,
          onStageRestarted: () {
            restartCalls++;
            return persisted.future;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('시도 횟수 1'), findsOneWidget);
    await tester.tap(find.byKey(const Key('reset_button')).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('reset_button')).first);
    await tester.pump();
    expect(find.byTooltip('시도 횟수 1'), findsOneWidget);
    expect(restartCalls, 1);

    persisted.complete();
    await _pumpForAsyncWork(tester);
    expect(find.byTooltip('시도 횟수 0'), findsOneWidget);
  });
}

Future<void> _pumpForAsyncWork(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  for (var frame = 0; frame < 20; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

({LevelDefinition level, ShotResult first}) _setup() {
  final stage = generatedStageCatalog.stageById('stage_chain_score');
  final solution = stageChainScoreSolutions.first;
  final pattern = stage.patternById(solution.patternId);
  final level = pattern.toLevelDefinition(
    stageId: stage.stageId,
    stageTitle: stage.title,
  );
  final first = const ShotResolver().resolve(
    level.createState(7, productRules: true),
    solution.firstInput,
  );
  return (level: level, first: first);
}
