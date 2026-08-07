import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('8단계 직접·고연쇄 해법은 연결된 입력 허용 영역을 가진다', () {
    final root =
        jsonDecode(
              File(
                'harness_docs/qa/replays/stage8_solution_regions.json',
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final patterns = (root['patterns'] as List).cast<Map>();

    expect(root['schemaVersion'], 1);
    expect(root['directAngleStepDegrees'], 2);
    expect(root['chainAngleStepDegrees'], 1);
    expect(root['aimSnapDegrees'], 1);
    expect(root['powerStepPercent'], 2);
    expect(
      Map<String, Object?>.from(
        root['validator'] as Map,
      )['staticAndRuntimeIssueCount'],
      0,
    );
    expect(patterns, hasLength(4));
    for (final raw in patterns) {
      final pattern = Map<String, Object?>.from(raw);
      final direct = Map<String, Object?>.from(pattern['direct'] as Map);
      final chain = Map<String, Object?>.from(pattern['chain'] as Map);
      expect(
        direct['largestConnectedRegion'],
        greaterThanOrEqualTo(100),
        reason: '${pattern['patternId']} 직접 경로',
      );
      expect(
        chain['successCount'],
        greaterThanOrEqualTo(5),
        reason: '${pattern['patternId']} 고연쇄 경로',
      );
      expect(
        chain['largestConnectedRegion'],
        greaterThanOrEqualTo(5),
        reason: '${pattern['patternId']} 고연쇄 연결 영역',
      );
      expect(
        chain['successfulFirstInputs'],
        greaterThanOrEqualTo(3),
        reason: '${pattern['patternId']} 첫째 발 허용 영역',
      );
      expect(
        chain['successfulSecondInputs'],
        greaterThanOrEqualTo(3),
        reason: '${pattern['patternId']} 둘째 발 허용 영역',
      );
      expect(
        chain['firstSelectableAngleBins'],
        greaterThanOrEqualTo(3),
        reason: '${pattern['patternId']} 첫째 발 논리 각도 구간',
      );
      expect(
        chain['secondSelectableAngleBins'],
        greaterThanOrEqualTo(3),
        reason: '${pattern['patternId']} 둘째 발 논리 각도 구간',
      );
      expect(
        chain['firstPowerSpanPercent'],
        greaterThanOrEqualTo(4),
        reason: '${pattern['patternId']} 첫째 발 힘 허용 폭',
      );
      expect(
        chain['secondPowerSpanPercent'],
        greaterThanOrEqualTo(4),
        reason: '${pattern['patternId']} 둘째 발 힘 허용 폭',
      );
    }
  });
}
