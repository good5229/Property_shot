import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/admin_access_verifier.dart';
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

  testWidgets('AI 제작 과정은 홈에서 숨고 관리자 인증 뒤에만 열린다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final verifier = AdminAccessVerifier(
      expectedIdHash: AdminAccessVerifier.digestForTesting('sample-admin'),
      expectedPasswordHash: AdminAccessVerifier.digestForTesting('sample-pw'),
    );
    await tester.pumpWidget(
      PropertyShotApp(showHome: true, adminAccessVerifier: verifier),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('puzzle_forge_entry_button')), findsNothing);
    expect(find.byKey(const Key('local_session_export_button')), findsNothing);
    await tester.tap(find.byKey(const Key('feedback_settings_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('admin_login_button')));
    await tester.tap(find.byKey(const Key('admin_login_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin_id_field')),
      'sample-admin',
    );
    await tester.enterText(
      find.byKey(const Key('admin_password_field')),
      'wrong',
    );
    await tester.tap(find.byKey(const Key('admin_login_submit_button')));
    await tester.pumpAndSettle();
    expect(find.text('관리자 정보를 확인해 주세요.'), findsOneWidget);
    expect(find.byKey(const Key('local_session_export_button')), findsNothing);
    await tester.enterText(
      find.byKey(const Key('admin_password_field')),
      'sample-pw',
    );
    await tester.tap(find.byKey(const Key('admin_login_submit_button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('admin_puzzle_forge_button')),
    );
    expect(
      find.byKey(const Key('admin_puzzle_forge_button')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('local_session_export_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('local_session_role_review_button')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('admin_puzzle_forge_button')));
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
    await tester.ensureVisible(find.byKey(const Key('forge_role_flow')));
    await tester.pumpAndSettle();
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
