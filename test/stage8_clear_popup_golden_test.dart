import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/creative_chain_score.dart';
import 'package:property_shot/game/domain/level_definition.dart';
import 'package:property_shot/game/domain/stage_catalog.dart';
import 'package:property_shot/game/simulation/shot_resolver.dart';
import 'package:property_shot/ui/game_screen.dart';

import 'fixtures/stage_chain_score_patterns.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader('GoldenNanumGothic')
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/NanumGothic-ExtraBold.ttf'));
    await loader.load();
    final materialIcons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await materialIcons.load();
  });

  for (final fixture in const [
    (name: '390x844', width: 390.0, height: 844.0),
    (name: '393x852', width: 393.0, height: 852.0),
    (name: '430x932', width: 430.0, height: 932.0),
    (name: '768x1024', width: 768.0, height: 1024.0),
    (name: '1024x1366', width: 1024.0, height: 1366.0),
  ]) {
    testWidgets('8단계 결과 팝업 Golden ${fixture.name}', (tester) async {
      await tester.binding.setSurfaceSize(Size(fixture.width, fixture.height));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data = _popupFixture();

      await tester.pumpWidget(
        RepaintBoundary(
          key: const Key('stage8_clear_popup_golden'),
          child: MaterialApp(
            theme: ThemeData(fontFamily: 'GoldenNanumGothic'),
            home: Scaffold(
              body: ClearResultPopup(
                state: data.result.state,
                level: data.level,
                onNext: () {},
                onRetry: () {},
                isFinal: true,
                bonusAchieved: true,
                chainScoreAnalysis: data.analysis,
                bestShot: 2,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('clear_popup')), findsOneWidget);
      expect(find.text('추가 도전 달성'), findsOneWidget);
      await expectLater(
        find.byKey(const Key('stage8_clear_popup_golden')),
        matchesGoldenFile('goldens/stage8_clear_popup_${fixture.name}.png'),
      );
    });
  }
}

({
  LevelDefinition level,
  ShotResult result,
  CreativeChainScoreAnalysis analysis,
})
_popupFixture() {
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
  return (level: level, result: second, analysis: analysis);
}
