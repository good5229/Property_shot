import 'dart:math' as math;

import '../domain/geometry.dart';
import '../domain/shot_input.dart';
import '../domain/trait.dart';

class ReplayShotFixture {
  const ReplayShotFixture({
    required this.angleRadians,
    required this.power,
    this.equippedTrait,
  });

  final double angleRadians;
  final double power;
  final TraitType? equippedTrait;

  ShotInput toInput() {
    return ShotInput(
      direction: Vec2(math.cos(angleRadians), math.sin(angleRadians)),
      power: power,
      equippedTrait: equippedTrait,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'angleRadians': angleRadians,
      'power': power,
      'equippedTrait': equippedTrait?.name,
    };
  }

  factory ReplayShotFixture.fromJson(Map<String, Object?> json) {
    final traitName = json['equippedTrait'] as String?;
    return ReplayShotFixture(
      angleRadians: (json['angleRadians'] as num).toDouble(),
      power: (json['power'] as num).toDouble(),
      equippedTrait: traitName == null
          ? null
          : TraitType.values.byName(traitName),
    );
  }
}

class ReplayFixture {
  const ReplayFixture({
    required this.id,
    required this.stageIndex,
    required this.routeTag,
    required this.shots,
    required this.expectedFingerprints,
    required this.expectedPhase,
    this.copyCoreCount = 0,
  });

  final String id;
  final int stageIndex;
  final String routeTag;
  final List<ReplayShotFixture> shots;
  final List<String> expectedFingerprints;
  final String expectedPhase;
  final int copyCoreCount;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'stageIndex': stageIndex,
      'routeTag': routeTag,
      'copyCoreCount': copyCoreCount,
      'shots': shots.map((shot) => shot.toJson()).toList(),
      'expectedFingerprints': expectedFingerprints,
      'expectedPhase': expectedPhase,
    };
  }

  factory ReplayFixture.fromJson(Map<String, Object?> json) {
    return ReplayFixture(
      id: json['id'] as String,
      stageIndex: json['stageIndex'] as int,
      routeTag: json['routeTag'] as String,
      copyCoreCount: (json['copyCoreCount'] as num?)?.toInt() ?? 0,
      shots: [
        for (final shot in (json['shots'] as List))
          ReplayShotFixture.fromJson(Map<String, Object?>.from(shot as Map)),
      ],
      expectedFingerprints: [
        for (final fingerprint in (json['expectedFingerprints'] as List))
          fingerprint as String,
      ],
      expectedPhase: json['expectedPhase'] as String,
    );
  }
}
