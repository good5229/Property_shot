import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/analysis/island_restoration.dart';

void main() {
  test('발견 수에 따라 관측소·등대·다리가 순서대로 복구된다', () {
    expect(IslandRestorationProgress(discoveryCount: 2).restoredCount, 0);

    final observatory = IslandRestorationProgress(discoveryCount: 3);
    expect(observatory.isRestored(IslandLandmark.observatory), isTrue);
    expect(observatory.nextLandmark, IslandLandmark.lighthouse);
    expect(IslandLandmark.observatory.benefitLabel, '분석 강화');

    final lighthouse = IslandRestorationProgress(discoveryCount: 9);
    expect(lighthouse.isRestored(IslandLandmark.lighthouse), isTrue);
    expect(lighthouse.nextLandmark, IslandLandmark.bridge);
    expect(IslandLandmark.lighthouse.benefitDescription, contains('실패 전'));

    final complete = IslandRestorationProgress(discoveryCount: 30);
    expect(complete.restoredCount, 3);
    expect(complete.restoredLandmarks, IslandLandmark.values);
    expect(complete.nextLandmark, isNull);
    expect(complete.statusText, contains('모두 복구'));
  });

  test('알 수 없는 발견은 복구 수에 포함하지 않는다', () {
    final progress = IslandRestorationProgress.fromDiscoveries(
      discoveriesByStageId: {
        'stage_a': {'heavy_equipped', 'unknown'},
        'stage_b': {'bouncy_equipped'},
      },
      stageIds: const ['stage_a', 'stage_b'],
    );

    expect(progress.discoveryCount, 2);
    expect(progress.total, 6);
  });

  test('복구 진행률은 각 시설 구간 안에서 0과 1 사이로 제한된다', () {
    final progress = IslandRestorationProgress(discoveryCount: 8);
    expect(progress.repairProgress(IslandLandmark.observatory), 1);
    expect(
      progress.repairProgress(IslandLandmark.lighthouse),
      closeTo(5 / 6, 0.0001),
    );
    expect(progress.repairProgress(IslandLandmark.bridge), 0);
  });

  test('복구 뒤 시설 성장은 6·12·18개 발견에서 실용 기능을 연다', () {
    final six = IslandRestorationProgress(discoveryCount: 6);
    expect(six.isUpgraded(IslandLandmark.observatory), isTrue);
    expect(six.isUpgraded(IslandLandmark.lighthouse), isFalse);
    expect(IslandLandmark.observatory.upgradeLabel, '4주 실험 기록');

    final twelve = IslandRestorationProgress(discoveryCount: 12);
    expect(twelve.isUpgraded(IslandLandmark.lighthouse), isTrue);
    expect(twelve.upgradeProgress(IslandLandmark.bridge), 0);

    final eighteen = IslandRestorationProgress(discoveryCount: 18);
    expect(IslandLandmark.values.every(eighteen.isUpgraded), isTrue);
    expect(IslandLandmark.bridge.upgradeDescription, contains('리플레이'));
  });
}
