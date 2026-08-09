import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/frame_performance_tracker.dart';

void main() {
  test('120프레임의 build·raster 최댓값으로 p90·p99 통과를 판정한다', () {
    final tracker = FramePerformanceTracker();
    for (var index = 0; index < 120; index++) {
      tracker.addSample(
        buildMilliseconds: (7 + (index % 3)).toDouble(),
        rasterMilliseconds: (8 + (index % 4)).toDouble(),
      );
    }

    final report = tracker.report;

    expect(report.sampleCount, 120);
    expect(report.processingP90Milliseconds, 11);
    expect(report.processingP99Milliseconds, 11);
    expect(report.status, FramePerformanceGateStatus.passed);
    expect(report.summaryLabel, '프레임 p90 11.0 · p99 11.0밀리초 · 기준 통과');
  });

  test('표본 부족과 50밀리초 초과 프레임을 통과로 오인하지 않는다', () {
    final insufficient = FramePerformanceTracker();
    for (var index = 0; index < 119; index++) {
      insufficient.addSample(buildMilliseconds: 4, rasterMilliseconds: 5);
    }
    final failed = FramePerformanceTracker();
    for (var index = 0; index < 119; index++) {
      failed.addSample(buildMilliseconds: 4, rasterMilliseconds: 5);
    }
    failed.addSample(buildMilliseconds: 51, rasterMilliseconds: 5);

    expect(
      insufficient.report.status,
      FramePerformanceGateStatus.insufficientSamples,
    );
    expect(failed.report.over50MillisecondsCount, 1);
    expect(failed.report.status, FramePerformanceGateStatus.failed);
  });

  test('잘못된 표본을 제외하고 최근 표본 상한을 지킨다', () {
    final tracker = FramePerformanceTracker(maximumSamples: 3);
    tracker.addSample(buildMilliseconds: double.nan, rasterMilliseconds: 1);
    for (var index = 1; index <= 5; index++) {
      tracker.addSample(
        buildMilliseconds: index.toDouble(),
        rasterMilliseconds: index + 0.5,
      );
    }

    final report = tracker.report;

    expect(report.sampleCount, 3);
    expect(report.invalidSampleCount, 1);
    expect(report.maximumProcessingMilliseconds, 5.5);
    expect(tracker.latestProcessingDurationMilliseconds, 5.5);
    expect(report.toJson()['판정'], '표본 부족');
  });
}
