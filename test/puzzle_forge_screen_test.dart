import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/puzzle_forge_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'property_shot_background_music_enabled': false,
    });
  });

  test('생성 요약은 실제 40패턴 통과와 반려 2건·채택 1건을 보존한다', () async {
    final summary = await loadPuzzleForgeSummary();

    expect(summary.productionPatternCount, 40);
    expect(summary.roles.map((role) => role.actor), [
      '사람',
      'Codex',
      'StagePatternValidator',
      '사람',
    ]);
    expect(
      summary.candidates
          .where(
            (candidate) =>
                candidate.status == PuzzleForgeCandidateStatus.rejected,
          )
          .length,
      2,
    );
    expect(
      summary.candidates
          .singleWhere(
            (candidate) =>
                candidate.status == PuzzleForgeCandidateStatus.adopted,
          )
          .patternId,
      'stage_persistent_01',
    );
  });

  testWidgets('초행 홈에서 AI 제작 과정을 열고 다시 홈으로 돌아온다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const PropertyShotApp(showHome: true));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('puzzle_forge_entry_button')).hitTestable(),
      findsOneWidget,
    );
    expect(
      tester
          .getSemantics(find.byKey(const Key('puzzle_forge_entry_button')))
          .label,
      contains('AI 제작 과정'),
    );
    await tester.tap(find.byKey(const Key('puzzle_forge_entry_button')));
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 150)),
    );
    await tester.pump();

    expect(find.byKey(const Key('puzzle_forge_screen')), findsOneWidget);
    expect(find.byKey(const Key('forge_validation_badge')), findsOneWidget);
    expect(find.textContaining('생산 패턴 40개'), findsOneWidget);
    expect(find.text('반려'), findsNWidgets(2));
    expect(find.text('채택'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.byKey(const Key('forge_role_flow')))
          .getSemanticsData()
          .label,
      allOf(
        contains('사람'),
        contains('Codex'),
        contains('StagePatternValidator'),
      ),
    );

    await tester.tap(find.byKey(const Key('puzzle_forge_back_button')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('home_screen_golden')), findsOneWidget);
  });
}
