import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/ui/creative_chain_score_summary.dart';
import 'package:property_shot/ui/game_screen.dart';

import 'fixtures/stage_chain_score_patterns.dart';

void main() {
  testWidgets('8단계 연쇄 점수는 총점과 모든 가산 근거를 한글로 설명한다', (tester) async {
    final catalog = stageCatalogFromJson(
      File('assets/stages/chapter_1.json').readAsStringSync(),
    );
    final stage = catalog.stageById('stage_chain_score');
    final pattern = stage.patternById('stage_chain_score_01');
    final solution = stageChainScoreSolutions.first;
    final level = pattern.toLevelDefinition(
      stageId: stage.stageId,
      stageTitle: stage.title,
    );
    final initial = level.createState(7, productRules: true);
    const resolver = ShotResolver();
    final first = resolver.resolve(initial, solution.firstInput);
    final second = resolver.resolve(first.state, solution.secondInput);
    final analysis = const CreativeChainScoreAnalyzer().analyze(
      [first, second],
      parShots: pattern.parShots,
      optionalChallengeIds: CreativeChainChallengeId.all,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CreativeChainScoreSummary(analysis: analysis),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('creative_chain_score_summary')),
      findsOneWidget,
    );
    expect(analysis.totalScore, greaterThanOrEqualTo(1800));
    expect(find.text('연쇄 점수 ${analysis.totalScore}점'), findsOneWidget);
    expect(find.text('홀 진입'), findsOneWidget);
    expect(find.text('벽 반사 4회'), findsOneWidget);
    expect(find.text('과거 공 1개 활용'), findsOneWidget);
    expect(find.text('준비 샷 1회 기여'), findsOneWidget);
    expect(find.text('+1000점'), findsOneWidget);

    final visibleTexts = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .join(' ');
    expect(visibleTexts, isNot(matches(RegExp('[A-Za-z]'))));
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(768, 1024),
  ]) {
    testWidgets(
      '8단계 실제 클리어 팝업은 ${size.width.toInt()}×${size.height.toInt()}에서 점수 근거를 스크롤한다',
      (tester) async {
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.binding.setSurfaceSize(size);
        final catalog = stageCatalogFromJson(
          File('assets/stages/chapter_1.json').readAsStringSync(),
        );
        final stage = catalog.stageById('stage_chain_score');
        final pattern = stage.patternById('stage_chain_score_01');
        final level = pattern.toLevelDefinition(
          stageId: stage.stageId,
          stageTitle: stage.title,
        );
        final solution = stageChainScoreSolutions.first;
        const resolver = ShotResolver();
        final first = resolver.resolve(
          level.createState(7, productRules: true),
          solution.firstInput,
        );
        final second = resolver.resolve(first.state, solution.secondInput);
        final analysis = const CreativeChainScoreAnalyzer().analyze(
          [first, second],
          parShots: pattern.parShots,
          optionalChallengeIds: CreativeChainChallengeId.all,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(size.width >= 700 ? 1.5 : 1),
              ),
              child: Scaffold(
                body: ClearResultPopup(
                  state: second.state,
                  level: level,
                  onNext: () {},
                  onRetry: () {},
                  isFinal: true,
                  bonusAchieved: true,
                  chainScoreAnalysis: analysis,
                  bestShot: 2,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('clear_popup')), findsOneWidget);
        expect(
          find.byKey(const Key('creative_chain_score_summary')),
          findsOneWidget,
        );
        expect(find.text('추가 도전 달성'), findsOneWidget);
        expect(find.text(level.bonusGoal), findsOneWidget);
        expect(find.text('연쇄 점수 ${analysis.totalScore}점'), findsOneWidget);
        expect(find.byKey(const Key('next_stage_button')), findsOneWidget);
        expect(find.byKey(const Key('retry_stage_button')), findsOneWidget);
        expect(
          tester
              .getSemantics(
                find.byKey(const Key('creative_chain_score_summary')),
              )
              .getSemanticsData()
              .label,
          contains('연쇄 점수 ${analysis.totalScore}점과 점수 근거'),
        );
        final lastEvidence = find.byKey(
          Key('creative_chain_evidence_${analysis.evidence.length - 1}'),
        );
        final resultScrollable = find.descendant(
          of: find.byKey(const Key('clear_result_scroll')),
          matching: find.byType(Scrollable),
        );
        await tester.scrollUntilVisible(
          lastEvidence,
          120,
          scrollable: resultScrollable,
        );
        await tester.pumpAndSettle();
        expect(lastEvidence, findsOneWidget);
        expect(lastEvidence.hitTestable(), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byKey(const Key('clear_leaderboard')),
          120,
          scrollable: resultScrollable,
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('clear_leaderboard')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('next_stage_button')).hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('retry_stage_button')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
