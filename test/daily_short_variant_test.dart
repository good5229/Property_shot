import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/game_state.dart';
import 'package:property_shot/game/levels/generated_stage_catalog.dart';
import 'package:property_shot/game/run/daily_challenge.dart';
import 'package:property_shot/game/services/game_platform_gateway.dart';
import 'package:property_shot/game/validation/stage_pattern_runtime_probe.dart';
import 'package:property_shot/game/validation/stage_pattern_validator.dart';
import 'package:property_shot/ui/game_screen.dart';

import '../tool/stage_pattern_runtime_manifest.dart';

void main() {
  test('날짜별 변주는 항상 서로 다른 생산 장면 세 개로 결정된다', () {
    final seen = <String>{};
    for (var day = 4; day <= 7; day++) {
      final definition = DailyChallengeDefinition.fromDateKey(
        '2026-08-${day.toString().padLeft(2, '0')}',
      );
      final catalog = definition.selectCatalog(generatedStageCatalog);

      expect(catalog.stages, hasLength(3));
      expect(
        catalog.stages.map((stage) => stage.stageId),
        definition.variant.stageIds,
      );
      expect(definition.variant.stageIds.toSet(), hasLength(3));
      seen.addAll(definition.variant.stageIds);
    }
    expect(
      seen,
      generatedStageCatalog.stages.map((stage) => stage.stageId).toSet(),
    );
  });

  test('일일 변주가 사용하는 모든 생산 패턴은 정적·실제 물리 검증을 통과한다', () {
    final manifest = buildRuntimeValidationManifest();
    final validator = StagePatternValidator();
    final selectedStageIds = dailyChallengeVariants
        .expand((variant) => variant.stageIds)
        .toSet();

    for (final stageId in selectedStageIds) {
      final stage = generatedStageCatalog.stageById(stageId);
      expect(
        validator.validate(stage).isValid,
        isTrue,
        reason: '$stageId 정적 검증',
      );
      for (final pattern in stage.patterns) {
        final scenarios = manifest[pattern.patternId] ?? const [];
        final requiredShots = scenarios.fold<int>(
          0,
          (sum, scenario) => sum + scenario.inputs.length * 2,
        );
        final evidence = ShotResolverPatternRuntimeProbe(
          representativeInputs: const [],
          representativeScenarios: scenarios,
          requireSolutionContract: true,
          maxProbeCount: math.max(1, scenarios.length),
          maxShots: math.max(2, requiredShots),
        ).probe(stage: stage, pattern: pattern);
        final report = validator.validatePatternWithRuntimeEvidence(
          stage,
          pattern,
          evidence,
        );
        expect(
          report.isValid,
          isTrue,
          reason: '${pattern.patternId}: ${report.issues}',
        );
      }
    }
  });

  test('기기 전용 플랫폼 경계는 Hive 연동을 과장하지 않는다', () async {
    const gateway = DeviceOnlyGamePlatformGateway();
    final receipt = await gateway.publishDailyResult(
      DailyPlatformResult(
        dateKey: '2026-08-23',
        variantId: 'trait_foundations',
        totalScore: 120,
        totalShots: 6,
        official: true,
      ),
    );

    expect(gateway.capabilities.guestPlay, isTrue);
    expect(gateway.capabilities.remoteLeaderboard, isFalse);
    expect(gateway.capabilities.cloudSave, isFalse);
    expect(receipt.savedOnDevice, isTrue);
    expect(receipt.publishedRemotely, isFalse);
    expect(receipt.playerMessage, contains('아직 연결하지 않았습니다'));
  });

  test('플랫폼 제출 DTO는 비정상 날짜·ID·점수를 거부한다', () {
    expect(
      () => DailyPlatformResult(
        dateKey: '../2026-08-23',
        variantId: 'trait_foundations',
        totalScore: 1,
        totalShots: 1,
        official: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => DailyPlatformResult(
        dateKey: '2026-08-23',
        variantId: 'HIVE/../../score',
        totalScore: -1,
        totalShots: 0,
        official: true,
      ),
      throwsArgumentError,
    );
  });

  testWidgets('세 장면의 마지막 결과 버튼은 네 번째 장면 대신 런을 완료한다', (tester) async {
    var completed = false;
    var requestedAnotherStage = false;
    final level = generatedStageCatalog.baselineLevelDefinitionFor(
      generatedStageCatalog.stageById('stage_drained'),
    );
    final success = level
        .createState(2, productRules: true)
        .copyWith(phase: GamePhase.success, message: '홀 진입 성공!');

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          initialState: success,
          levelOverride: level,
          showStageSelector: false,
          loadGameAssets: false,
          sequencePosition: 2,
          sequenceLength: 3,
          nextActionLabel: '도전 결과 보기',
          onRunCompleted: () async => completed = true,
          onStageRequested: (_) async => requestedAnotherStage = true,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('next_stage_button')));
    await tester.pump();

    expect(completed, isTrue);
    expect(requestedAnotherStage, isFalse);
  });
}
