import 'feedback_cue.dart';

enum FeedbackWave { sine, triangle, square, sawtooth }

class FeedbackTone {
  const FeedbackTone({
    required this.frequency,
    required this.milliseconds,
    required this.volume,
    this.wave = FeedbackWave.sine,
    this.gapAfterMilliseconds = 0,
  });

  final double frequency;
  final int milliseconds;
  final double volume;
  final FeedbackWave wave;
  final int gapAfterMilliseconds;
}

List<FeedbackTone> feedbackTonesFor(FeedbackCue cue) => switch (cue) {
  FeedbackCue.ui => const [_SineTone(620, 45, 0.045)],
  FeedbackCue.trait => const [_SineTone(740, 90, 0.055)],
  FeedbackCue.copy => const [
    _TriangleTone(720, 65, 0.055, gap: 8),
    _TriangleTone(880, 75, 0.06),
  ],
  FeedbackCue.copyCoreAwarded => const [
    _TriangleTone(720, 65, 0.06, gap: 8),
    _TriangleTone(960, 80, 0.065, gap: 8),
    _TriangleTone(1200, 90, 0.06),
  ],
  FeedbackCue.aimCharge => const [_SineTone(320, 80, 0.035)],
  FeedbackCue.launch => const [_SawTone(190, 110, 0.08)],
  FeedbackCue.lightCollision => const [_TriangleTone(520, 70, 0.05)],
  FeedbackCue.heavyCollision => const [
    _SawTone(105, 115, 0.09, gap: 5),
    _TriangleTone(82, 70, 0.055),
  ],
  FeedbackCue.bouncyCollision => const [
    _SineTone(610, 70, 0.055, gap: 6),
    _SineTone(850, 100, 0.06),
  ],
  FeedbackCue.stickyCollision => const [
    _TriangleTone(290, 90, 0.055, gap: 4),
    _SineTone(165, 120, 0.04),
  ],
  FeedbackCue.jellyCollision => const [
    _SineTone(560, 65, 0.055, gap: 4),
    _SineTone(720, 80, 0.06),
  ],
  FeedbackCue.sharpCollision => const [
    _SquareTone(1180, 45, 0.045, gap: 5),
    _TriangleTone(780, 65, 0.05),
  ],
  FeedbackCue.mysteryReveal => const [
    _TriangleTone(620, 55, 0.055, gap: 8),
    _TriangleTone(880, 70, 0.065, gap: 8),
    _SineTone(1100, 75, 0.055),
  ],
  FeedbackCue.switchPressed => const [_SquareTone(420, 120, 0.065)],
  FeedbackCue.gateOpened => const [
    _TriangleTone(260, 95, 0.06, gap: 8),
    _SineTone(360, 130, 0.065),
  ],
  FeedbackCue.holeEntered => const [
    _SineTone(420, 100, 0.06, gap: 8),
    _SineTone(620, 190, 0.075),
  ],
  FeedbackCue.clear => const [
    _SineTone(660, 75, 0.065, gap: 8),
    _SineTone(820, 85, 0.07, gap: 8),
    _SineTone(990, 110, 0.065),
  ],
  FeedbackCue.medal => const [
    _TriangleTone(1040, 75, 0.055, gap: 8),
    _TriangleTone(1320, 110, 0.05),
  ],
  FeedbackCue.discovery => const [
    _TriangleTone(760, 65, 0.05, gap: 8),
    _TriangleTone(920, 95, 0.055),
  ],
  FeedbackCue.rewardActivated => const [
    _SineTone(680, 65, 0.055, gap: 8),
    _SineTone(820, 90, 0.06),
  ],
  FeedbackCue.restoration => const [
    _TriangleTone(480, 75, 0.06, gap: 9),
    _TriangleTone(620, 85, 0.07, gap: 9),
    _TriangleTone(780, 120, 0.065),
  ],
  FeedbackCue.observatoryRestored => const [
    _TriangleTone(520, 70, 0.06, gap: 10),
    _TriangleTone(690, 85, 0.07, gap: 10),
    _SineTone(860, 130, 0.065),
  ],
  FeedbackCue.lighthouseRestored => const [
    _SineTone(660, 75, 0.055, gap: 10),
    _SineTone(880, 90, 0.07, gap: 10),
    _SineTone(1100, 145, 0.065),
  ],
  FeedbackCue.bridgeRestored => const [
    _TriangleTone(260, 75, 0.065, gap: 10),
    _TriangleTone(390, 95, 0.07, gap: 10),
    _TriangleTone(520, 155, 0.065),
  ],
  FeedbackCue.labComplete => const [
    _SineTone(560, 70, 0.055, gap: 8),
    _SineTone(700, 100, 0.06),
  ],
  FeedbackCue.fail => const [
    _TriangleTone(220, 65, 0.055, gap: 6),
    _TriangleTone(170, 95, 0.06),
  ],
};

int feedbackPatternDurationMilliseconds(FeedbackCue cue) => feedbackTonesFor(
  cue,
).fold(0, (sum, tone) => sum + tone.milliseconds + tone.gapAfterMilliseconds);

class _SineTone extends FeedbackTone {
  const _SineTone(
    double frequency,
    int milliseconds,
    double volume, {
    int gap = 0,
  }) : super(
         frequency: frequency,
         milliseconds: milliseconds,
         volume: volume,
         gapAfterMilliseconds: gap,
       );
}

class _TriangleTone extends FeedbackTone {
  const _TriangleTone(
    double frequency,
    int milliseconds,
    double volume, {
    int gap = 0,
  }) : super(
         frequency: frequency,
         milliseconds: milliseconds,
         volume: volume,
         wave: FeedbackWave.triangle,
         gapAfterMilliseconds: gap,
       );
}

class _SquareTone extends FeedbackTone {
  const _SquareTone(
    double frequency,
    int milliseconds,
    double volume, {
    int gap = 0,
  }) : super(
         frequency: frequency,
         milliseconds: milliseconds,
         volume: volume,
         wave: FeedbackWave.square,
         gapAfterMilliseconds: gap,
       );
}

class _SawTone extends FeedbackTone {
  const _SawTone(
    double frequency,
    int milliseconds,
    double volume, {
    int gap = 0,
  }) : super(
         frequency: frequency,
         milliseconds: milliseconds,
         volume: volume,
         wave: FeedbackWave.sawtooth,
         gapAfterMilliseconds: gap,
       );
}
