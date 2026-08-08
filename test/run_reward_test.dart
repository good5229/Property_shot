import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:property_shot/game/run/run_reward.dart';

void main() {
  group('런 보상 카탈로그', () {
    test('초기 보상 8종의 안정 ID와 한글 메타데이터를 정의한다', () {
      expect(initialRunRewards, hasLength(8));
      expect(initialRunRewards.map((reward) => reward.id), [
        runRewardCloneCoreId,
        runRewardShotCancelAssistId,
        runRewardSpentBallRecoveryId,
        runRewardFirstImpactGuideId,
        runRewardOptionalChallengeGuardId,
        runRewardFailureCauseBoostId,
        runRewardBallAppearanceId,
        runRewardStageRecordGuardId,
      ]);
      expect(
        initialRunRewards.map((reward) => reward.effectKind).toSet(),
        RunRewardEffectKind.values.toSet(),
      );
      for (final reward in initialRunRewards) {
        expect(reward.name, isNotEmpty);
        expect(reward.description, isNotEmpty);
        expect(reward.name, isNot(matches(RegExp('[A-Za-z]'))));
        expect(reward.description, isNot(matches(RegExp('[A-Za-z]'))));
      }
    });

    test('보상 JSON은 안정 ID와 효과 종류를 보존한다', () {
      final reward = initialRunRewards.first;
      final encoded = jsonEncode(reward.toJson());

      expect(
        encoded,
        '{"id":"clone_core_once","name":"복제 코어 1개",'
        '"description":"속성을 원본에 남긴 채 공에 한 번 복사할 수 있습니다.",'
        '"effectKind":"clone_core"}',
      );
      expect(RunReward.fromJson(jsonDecode(encoded)).toJson(), reward.toJson());
    });

    test('빈 ID와 중복 ID 카탈로그를 거부한다', () {
      expect(
        () => RunReward(
          id: '  ',
          name: '시험 보상',
          description: '시험 설명입니다.',
          effectKind: RunRewardEffectKind.cloneCore,
        ),
        throwsArgumentError,
      );

      final reward = initialRunRewards.first;
      expect(
        () => RunRewardCatalog([
          reward,
          reward,
          initialRunRewards[1],
          initialRunRewards[2],
        ]),
        throwsArgumentError,
      );
    });
  });

  group('결정론 보상 후보', () {
    test('같은 세 seed 입력은 항상 같은 후보를 만든다', () {
      final generator = RunRewardCandidateGenerator();
      final first = generator.generate(
        rootSeed: 0x12345678,
        stageId: 'stage_property_shot',
        patternSeed: 0x87654321,
      );
      final second = generator.generate(
        rootSeed: 0x12345678,
        stageId: 'stage_property_shot',
        patternSeed: 0x87654321,
      );

      expect(
        first.map((reward) => reward.id),
        second.map((reward) => reward.id),
      );
      expect(
        generator.candidateSeed(
          rootSeed: 0x12345678,
          stageId: 'stage_property_shot',
          patternSeed: 0x87654321,
        ),
        2980854957,
      );
      expect(first.map((reward) => reward.id), [
        runRewardStageRecordGuardId,
        runRewardFailureCauseBoostId,
        runRewardBallAppearanceId,
      ]);
      expect(
        generator.candidateSeed(
          rootSeed: 0x12345678,
          stageId: 'stage_property_shot',
          patternSeed: 0x87654321,
        ),
        generator.candidateSeed(
          rootSeed: 0x12345678,
          stageId: 'stage_property_shot',
          patternSeed: 0x87654321,
        ),
      );
    });

    test('항상 중복 없는 정확히 3개 후보를 만든다', () {
      for (var seed = 0; seed < 100; seed++) {
        final rewards = generateRunRewardCandidates(
          rootSeed: seed,
          stageId: 'stage_reward',
          patternSeed: seed * 17,
        );
        expect(rewards, hasLength(3));
        expect(rewards.map((reward) => reward.id).toSet(), hasLength(3));
      }
    });

    test('다른 seed들은 다양한 후보 조합과 순서를 만든다', () {
      final sequences = <String>{};
      for (var seed = 0; seed < 64; seed++) {
        final rewards = generateRunRewardCandidates(
          rootSeed: seed,
          stageId: 'stage_reward',
          patternSeed: 9000 + seed,
        );
        sequences.add(rewards.map((reward) => reward.id).join(','));
      }

      expect(sequences.length, greaterThan(20));
    });

    test('32비트 범위 밖 seed와 빈 스테이지 ID를 거부한다', () {
      final generator = RunRewardCandidateGenerator();

      expect(
        () => generator.generate(
          rootSeed: -1,
          stageId: 'stage_reward',
          patternSeed: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => generator.generate(
          rootSeed: 0x100000000,
          stageId: 'stage_reward',
          patternSeed: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => generator.generate(
          rootSeed: 0,
          stageId: 'stage_reward',
          patternSeed: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => generator.generate(
          rootSeed: 0,
          stageId: 'stage_reward',
          patternSeed: 0x100000000,
        ),
        throwsArgumentError,
      );
      expect(
        () => generator.generate(rootSeed: 0, stageId: '  ', patternSeed: 0),
        throwsArgumentError,
      );
    });
  });

  group('런 보상 보유 상태', () {
    test('공 꾸미기는 선택 ID만 남은 복원 상태에서도 활성화된다', () {
      final inventory = RunRewardInventory({runRewardBallAppearanceId});

      expect(inventory.ballAppearanceEnabled, isTrue);
      expect(inventory.has(runRewardBallAppearanceId), isFalse);
    });

    test('일회성 사용과 단계별 사용을 서로 구분해 복원한다', () {
      final oneShotSelection = runRewardSelectionRecordId(
        stageId: 'stage_heavy',
        patternSeed: 17,
        rewardId: runRewardSpentBallRecoveryId,
      );
      final stageSelection = runRewardSelectionRecordId(
        stageId: 'stage_bouncy',
        patternSeed: 29,
        rewardId: runRewardStageRecordGuardId,
      );
      final inventory = RunRewardInventory({
        oneShotSelection,
        stageSelection,
        runRewardUseRecordId(oneShotSelection, 'stage_heavy|spent_ball_2'),
        runRewardStageUseRecordId(stageSelection, 'stage_sticky'),
      });

      expect(inventory.has(runRewardSpentBallRecoveryId), isTrue);
      expect(inventory.availableUseCount(runRewardSpentBallRecoveryId), 0);
      expect(inventory.useKeys(runRewardSpentBallRecoveryId), [
        'stage_heavy|spent_ball_2',
      ]);
      expect(
        inventory.canUseForStage(runRewardStageRecordGuardId, 'stage_sticky'),
        isFalse,
      );
      expect(
        inventory.canUseForStage(runRewardStageRecordGuardId, 'stage_speed'),
        isTrue,
      );
    });

    test('단계 재도전 번호는 같은 단계에서 단조 증가한다', () {
      final records = {
        runStageAttemptRecordId('stage_heavy', 1),
        runStageAttemptRecordId('stage_heavy', 2),
        runStageAttemptRecordId('stage_bouncy', 4),
      };

      expect(runStageAttemptNumber(records, 'stage_heavy'), 2);
      expect(runStageAttemptNumber(records, 'stage_bouncy'), 4);
      expect(runStageAttemptNumber(records, 'stage_sticky'), 0);
    });
  });
}
