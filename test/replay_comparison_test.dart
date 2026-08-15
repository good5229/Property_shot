import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/replay/replay.dart';

void main() {
  test('같은 패턴의 두 기록을 발사 수와 평균 힘으로만 로컬 비교한다', () {
    final left = _document();
    final right = _document(
      shots: [
        ...left.shots,
        ReplayShot(
          shotIndex: left.shots.length,
          ballId: 'ball_compare',
          direction: ReplayDirection.fromDoubles(1, 0),
          power: ReplayFixedPoint.encode(0.8),
        ),
      ],
      outcomes: const [
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      ],
    );

    final comparison = ReplayComparison.compare(left, right);

    expect(comparison.shotDifference, 1);
    expect(comparison.summary, contains('1발 더'));
    expect(comparison.normalizedDistance, inInclusiveRange(0, 1));
  });

  test('다른 패턴은 오해를 막기 위해 비교하지 않는다', () {
    final left = _document();
    final right = _document(patternId: 'different_pattern');
    expect(
      () => ReplayComparison.compare(left, right),
      throwsFormatException,
    );
  });
}

ReplayDocument _document({
  String patternId = 'stage_heavy_01',
  List<ReplayShot>? shots,
  List<String>? outcomes,
}) {
  final actualShots = shots ?? [
    ReplayShot(
      shotIndex: 0,
      ballId: 'ball_0',
      direction: ReplayDirection.fromDoubles(0.6, -0.8),
      power: ReplayFixedPoint.encode(0.6),
    ),
  ];
  return ReplayDocument(
    mode: ReplayMode.normal,
    dateKey: null,
    challengeVersion: null,
    rootSeed: 1,
    resolverVersion: 'shot-resolver-v1',
    catalogFingerprint: 'catalog-v1-fingerprint',
    stageId: 'stage_heavy',
    patternId: patternId,
    patternSeed: 2,
    drawCycle: 0,
    drawIndex: 0,
    shots: actualShots,
    outcomeFingerprints: outcomes ?? const [
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    ],
  );
}
