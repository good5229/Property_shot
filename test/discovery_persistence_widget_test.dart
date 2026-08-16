import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/persistence/progress_store.dart';
import 'package:property_shot/ui/game_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('클리어 전 발견은 섬 복구 진행에 먼저 기록되지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((level) => level.id),
    );
    final initial = levels.first.createState(0, productRules: true);
    final equipped = initial.copyWith(
      equippedTrait: TraitType.heavy,
      entities: [
        for (final entity in initial.entities)
          entity.id == 'active_ball'
              ? entity.copyWith(traits: const {TraitType.heavy})
              : entity,
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: equipped,
          loadGameAssets: false,
          showStageSelector: false,
          progressStore: store,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );

    final snapshot = await store.load();
    expect(snapshot.discoveriesByStageId, isEmpty);
    expect(find.text('클리어하면 이번 발견이 기록돼요'), findsNothing);
  });

  testWidgets('진행 저장 비활성 화면은 캠페인 발견 기록을 오염시키지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final store = ProgressStore(
      stageCount: levels.length,
      stageIds: levels.map((level) => level.id),
    );
    final initial = levels.first.createState(0, productRules: true);
    final equipped = initial.copyWith(
      equippedTrait: TraitType.heavy,
      entities: [
        for (final entity in initial.entities)
          entity.id == 'active_ball'
              ? entity.copyWith(traits: const {TraitType.heavy})
              : entity,
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: equipped,
          loadGameAssets: false,
          showStageSelector: false,
          progressStore: store,
          progressPersistencePolicy: GameProgressPersistencePolicy.disabled,
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );

    expect((await store.load()).discoveriesByStageId, isEmpty);
  });
}
