import 'geometry.dart';
import 'trait.dart';

class ShotInput {
  const ShotInput({
    required this.direction,
    required this.power,
    this.equippedTrait,
  });

  final Vec2 direction;
  final double power;
  final TraitType? equippedTrait;

  ShotInput normalized() {
    return ShotInput(
      direction: direction.normalized(),
      power: power.clamp(0, 1),
      equippedTrait: equippedTrait,
    );
  }
}
