import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/island_restoration.dart';
import 'package:property_shot/main.dart';
import 'package:property_shot/ui/game_feedback.dart';

void main() {
  setUp(GameFeedback.resetForTesting);
  tearDown(GameFeedback.resetForTesting);

  for (final fixture in const [
    (size: Size(320, 568), textScale: 1.0),
    (size: Size(390, 844), textScale: 1.0),
    (size: Size(768, 1024), textScale: 1.0),
    (size: Size(1440, 900), textScale: 1.0),
    (size: Size(390, 844), textScale: 1.6),
  ]) {
    testWidgets(
      '피날레는 ${fixture.size.width.toInt()}x${fixture.size.height.toInt()} '
      '글자 ${fixture.textScale}에서 겹침 없이 모든 행동에 도달한다',
      (tester) async {
        await tester.binding.setSurfaceSize(fixture.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: fixture.size,
                textScaler: TextScaler.linear(fixture.textScale),
              ),
              child: buildCampaignFinaleForTesting(
                totalScore: 8970,
                totalBestShots: 24,
                rewardCount: 7,
                restorationProgress: IslandRestorationProgress(
                  discoveryCount: 18,
                  optionalMasteryCount: 7,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('첫 번째 섬 완주!'), findsOneWidget);
        expect(
          find.byKey(const Key('campaign_finale_restored_count')),
          findsOneWidget,
        );
        expect(find.text('3/3'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.byKey(const Key('new_run_button')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('run_result_home_button')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('부분 복구 피날레는 완료하지 않은 시설과 다음 목표를 과장하지 않는다', (tester) async {
    var restarted = false;
    var returnedHome = false;
    await tester.pumpWidget(
      MaterialApp(
        home: buildCampaignFinaleForTesting(
          totalScore: 1970,
          totalBestShots: 3,
          rewardCount: 1,
          restorationProgress: IslandRestorationProgress(discoveryCount: 4),
          onStartNewRun: () => restarted = true,
          onHome: () => returnedHome = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1/3'), findsOneWidget);
    expect(find.textContaining('등대까지 발견 5개'), findsOneWidget);
    expect(find.textContaining('다음 목표 · 등대 복구'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('new_run_button')));
    await tester.tap(find.byKey(const Key('new_run_button')));
    expect(restarted, isTrue);
    await tester.tap(find.byKey(const Key('run_result_home_button')));
    expect(returnedHome, isTrue);
  });
}
