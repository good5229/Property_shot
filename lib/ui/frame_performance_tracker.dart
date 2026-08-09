import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/scheduler.dart';

enum FramePerformanceGateStatus { insufficientSamples, passed, failed }

class FramePerformanceReport {
  const FramePerformanceReport._({
    required this.sampleCount,
    required this.invalidSampleCount,
    required this.buildP90Milliseconds,
    required this.buildP99Milliseconds,
    required this.rasterP90Milliseconds,
    required this.rasterP99Milliseconds,
    required this.processingP90Milliseconds,
    required this.processingP99Milliseconds,
    required this.maximumProcessingMilliseconds,
    required this.over50MillisecondsCount,
    required this.status,
  });

  static const minimumSampleCount = 120;
  static const targetP90Milliseconds = 16.7;
  static const targetP99Milliseconds = 25.0;

  factory FramePerformanceReport.fromSamples({
    required Iterable<double> buildMilliseconds,
    required Iterable<double> rasterMilliseconds,
    int invalidSampleCount = 0,
  }) {
    final rawBuild = buildMilliseconds.toList();
    final rawRaster = rasterMilliseconds.toList();
    if (rawBuild.length != rawRaster.length) {
      throw ArgumentError('build와 raster 표본 수가 같아야 합니다.');
    }
    final processing = <double>[
      for (var index = 0; index < rawBuild.length; index++)
        math.max(rawBuild[index], rawRaster[index]),
    ]..sort();
    final build = rawBuild..sort();
    final raster = rawRaster..sort();
    final buildP90 = _percentile(build, 0.90);
    final buildP99 = _percentile(build, 0.99);
    final rasterP90 = _percentile(raster, 0.90);
    final rasterP99 = _percentile(raster, 0.99);
    final processingP90 = _percentile(processing, 0.90);
    final processingP99 = _percentile(processing, 0.99);
    final over50 = processing.where((sample) => sample > 50).length;
    final status = processing.length < minimumSampleCount
        ? FramePerformanceGateStatus.insufficientSamples
        : processingP90! <= targetP90Milliseconds &&
              processingP99! <= targetP99Milliseconds &&
              over50 == 0
        ? FramePerformanceGateStatus.passed
        : FramePerformanceGateStatus.failed;
    return FramePerformanceReport._(
      sampleCount: processing.length,
      invalidSampleCount: invalidSampleCount,
      buildP90Milliseconds: buildP90,
      buildP99Milliseconds: buildP99,
      rasterP90Milliseconds: rasterP90,
      rasterP99Milliseconds: rasterP99,
      processingP90Milliseconds: processingP90,
      processingP99Milliseconds: processingP99,
      maximumProcessingMilliseconds: processing.isEmpty
          ? null
          : processing.last,
      over50MillisecondsCount: over50,
      status: status,
    );
  }

  final int sampleCount;
  final int invalidSampleCount;
  final double? buildP90Milliseconds;
  final double? buildP99Milliseconds;
  final double? rasterP90Milliseconds;
  final double? rasterP99Milliseconds;
  final double? processingP90Milliseconds;
  final double? processingP99Milliseconds;
  final double? maximumProcessingMilliseconds;
  final int over50MillisecondsCount;
  final FramePerformanceGateStatus status;

  String get statusLabel => switch (status) {
    FramePerformanceGateStatus.insufficientSamples => '표본 부족',
    FramePerformanceGateStatus.passed => '기준 통과',
    FramePerformanceGateStatus.failed => '기준 미통과',
  };

  String get summaryLabel {
    final p90 = processingP90Milliseconds;
    final p99 = processingP99Milliseconds;
    if (p90 == null || p99 == null) {
      return '프레임 표본 0/$minimumSampleCount개 · 더 수집 필요';
    }
    if (status == FramePerformanceGateStatus.insufficientSamples) {
      return '프레임 표본 $sampleCount/$minimumSampleCount개 · '
          'p90 ${p90.toStringAsFixed(1)}밀리초';
    }
    return '프레임 p90 ${p90.toStringAsFixed(1)} · '
        'p99 ${p99.toStringAsFixed(1)}밀리초 · $statusLabel';
  }

  Map<String, Object?> toJson() => {
    '판정': statusLabel,
    '유효표본수': sampleCount,
    '최소표본수': minimumSampleCount,
    '제외된잘못된표본수': invalidSampleCount,
    '빌드p90밀리초': buildP90Milliseconds,
    '빌드p99밀리초': buildP99Milliseconds,
    '래스터p90밀리초': rasterP90Milliseconds,
    '래스터p99밀리초': rasterP99Milliseconds,
    '처리p90밀리초': processingP90Milliseconds,
    '처리p99밀리초': processingP99Milliseconds,
    '처리최대밀리초': maximumProcessingMilliseconds,
    '50밀리초초과수': over50MillisecondsCount,
    '목표p90밀리초': targetP90Milliseconds,
    '목표p99밀리초': targetP99Milliseconds,
  };

  static double? _percentile(List<double> sorted, double ratio) {
    if (sorted.isEmpty) return null;
    final rank = (sorted.length * ratio)
        .ceil()
        .clamp(1, sorted.length)
        .toInt();
    return sorted[rank - 1];
  }
}

class FramePerformanceTracker {
  FramePerformanceTracker({this.maximumSamples = 7200}) {
    if (maximumSamples < 1) {
      throw ArgumentError.value(
        maximumSamples,
        'maximumSamples',
        '최대 표본 수는 1 이상이어야 합니다.',
      );
    }
  }

  final int maximumSamples;
  final List<double> _buildMilliseconds = [];
  final List<double> _rasterMilliseconds = [];
  var _invalidSampleCount = 0;
  var _started = false;

  double get latestProcessingDurationMilliseconds {
    if (_buildMilliseconds.isEmpty) return 0;
    return math.max(_buildMilliseconds.last, _rasterMilliseconds.last);
  }

  FramePerformanceReport get report => FramePerformanceReport.fromSamples(
    buildMilliseconds: _buildMilliseconds,
    rasterMilliseconds: _rasterMilliseconds,
    invalidSampleCount: _invalidSampleCount,
  );

  String exportReportJson() =>
      const JsonEncoder.withIndent('  ').convert(report.toJson());

  void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
  }

  void stop() {
    if (!_started) return;
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    _started = false;
  }

  void addSample({
    required double buildMilliseconds,
    required double rasterMilliseconds,
  }) {
    if (!buildMilliseconds.isFinite ||
        !rasterMilliseconds.isFinite ||
        buildMilliseconds < 0 ||
        rasterMilliseconds < 0) {
      _invalidSampleCount++;
      return;
    }
    _buildMilliseconds.add(buildMilliseconds);
    _rasterMilliseconds.add(rasterMilliseconds);
    final overflow = _buildMilliseconds.length - maximumSamples;
    if (overflow > 0) {
      _buildMilliseconds.removeRange(0, overflow);
      _rasterMilliseconds.removeRange(0, overflow);
    }
  }

  void _recordTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      addSample(
        buildMilliseconds:
            timing.buildDuration.inMicroseconds /
            Duration.microsecondsPerMillisecond,
        rasterMilliseconds:
            timing.rasterDuration.inMicroseconds /
            Duration.microsecondsPerMillisecond,
      );
    }
  }
}
