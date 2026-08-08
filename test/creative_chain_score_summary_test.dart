import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/domain/geometry.dart';
import 'package:property_shot/game/domain/level_definition.dart';
import 'package:property_shot/game/domain/shot_input.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/ui/creative_chain_score_summary.dart';
import 'package:property_shot/ui/game_screen.dart';

import 'fixtures/stage_chain_score_patterns.dart';

void main() {
  testWidgets('연쇄 점수 상세을 끄면 총점만 남고 가산 근거는 숨긴다', (tester) async {
    final level = _directScoreLevel(0);
    final result = const ShotResolver().resolve(
      level.createState(0, productRules: true),
      const ShotInput(direction: Vec2(1, 0), power: 0.8),
    );
    final analysis = const CreativeChainScoreAnalyzer().analyze(
      [result],
      parShots: level.parShots,
      optionalChallengeIds: CreativeChainChallengeId.all,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CreativeChainScoreSummary(
            analysis: analysis,
            showDetails: false,
          ),
        ),
      ),
    );

    expect(find.text('연쇄 점수 ${analysis.totalScore}점'), findsOneWidget);
    for (final evidence in analysis.evidence) {
      expect(find.text(evidence.label), findsNothing);
      expect(find.text('+${evidence.points}점'), findsNothing);
    }
  });

  for (var levelIndex = 0; levelIndex < 10; levelIndex++) {
    testWidgets('${levelIndex + 1}단계 성공 결과는 연쇄 점수 요약을 표시한다', (tester) async {
      final level = _directScoreLevel(levelIndex);
      final result = const ShotResolver().resolve(
        level.createState(levelIndex, productRules: true),
        const ShotInput(direction: Vec2(1, 0), power: 0.8),
      );
      final analysis = const CreativeChainScoreAnalyzer().analyze(
        [result],
        parShots: level.parShots,
        optionalChallengeIds: CreativeChainChallengeId.all,
      );
      expect(result.state.phase, GamePhase.success);

      await tester.pumpWidget(
        MaterialApp(
          home: GameScreen(
            initialState: result.state,
            initialShotResults: [result],
            levelOverride: level,
            showStageSelector: false,
            loadGameAssets: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('clear_popup')), findsOneWidget);
      expect(
        find.byKey(const Key('creative_chain_score_summary')),
        findsOneWidget,
      );
      expect(find.text('연쇄 점수 ${analysis.totalScore}점'), findsOneWidget);
      expect(find.text('홀 진입'), findsOneWidget);
    });
  }

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

LevelDefinition _directScoreLevel(int levelIndex) {
  return LevelDefinition(
    id: 'score_stage_$levelIndex',
    name: '${levelIndex + 1}. 점수 흐름 시험',
    ballSpawn: const Vec2(56, 456),
    parShots: 3,
    entities: const [
      EntityState(
        id: 'hole',
        type: EntityType.hole,
        position: Vec2(220, 456),
        size: Vec2(34, 34),
        solid: false,
      ),
    ],
  );
}
