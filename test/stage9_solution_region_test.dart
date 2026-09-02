import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/generate_stage9_solution_regions.dart';

void main() {
  test('9단계 직접·반사판 해법은 연결된 입력 허용 영역을 가진다', () {
    final root =
        jsonDecode(
              File(
                'harness_docs/qa/replays/stage9_solution_regions.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final patterns = (root['patterns'] as List).cast<Map>();

    expect(root, buildStage9SolutionRegionReport());
    expect(root['schemaVersion'], 2);
    expect(root['directAngleStepDegrees'], 2);
    expect(root['preparedAngleStepDegrees'], 1);
    expect(root['aimSnapDegrees'], 1);
    expect(root['powerStepPercent'], 2);
    expect(patterns, hasLength(4));
    for (final raw in patterns) {
      final pattern = Map<String, Object?>.from(raw);
      final direct = Map<String, Object?>.from(pattern['direct'] as Map);
      final prepared = Map<String, Object?>.from(pattern['prepared'] as Map);
      expect(
        direct['largestConnectedRegion'],
        greaterThanOrEqualTo(5),
        reason: '${pattern['patternId']} 제한된 직접 우회 연결 영역',
      );
      expect(
        prepared['largestConnectedRegion'],
        greaterThanOrEqualTo(5),
        reason: '${pattern['patternId']} 반사판 연결 영역',
      );
      expect(
        prepared['successfulFirstInputs'],
        greaterThanOrEqualTo(2),
        reason: '${pattern['patternId']} 첫째 발 허용 영역',
      );
      expect(
        prepared['successfulSecondInputs'],
        greaterThanOrEqualTo(3),
        reason: '${pattern['patternId']} 둘째 발 허용 영역',
      );
      final firstAngleBins = prepared['firstSelectableAngleBins'] as int;
      final firstPowerSpan = prepared['firstPowerSpanPercent'] as int;
      expect(
        firstAngleBins >= 2 || firstPowerSpan >= 2,
        isTrue,
        reason: '${pattern['patternId']} 첫째 발 각도·파워 허용 영역',
      );
      expect(
        prepared['secondSelectableAngleBins'],
        greaterThanOrEqualTo(2),
        reason: '${pattern['patternId']} 둘째 발 연속 각도',
      );
      expect(
        prepared['causalSuccessCount'],
        prepared['successCount'],
        reason: '${pattern['patternId']} 성공은 실제 반사판 인과 경로여야 한다.',
      );
      expect(
        (prepared['finalShotReflectorSuccessCount'] as int) +
            (prepared['preparedStateSuccessCount'] as int),
        prepared['successCount'],
        reason: '${pattern['patternId']} 직접 접촉 또는 반사실 준비 효과로 분류되어야 한다.',
      );
    }
  });
}
