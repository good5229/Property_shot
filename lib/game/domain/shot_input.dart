import 'geometry.dart';
import 'trait.dart';

enum ShotAssistKind { none, stabilized, targetSnap, adaptiveTargetSnap }

class ShotInput {
  const ShotInput({
    required this.direction,
    required this.power,
    this.equippedTrait,
    this.rawDirection,
    this.rawPower,
    this.assistKind = ShotAssistKind.none,
    this.assistTargetId,
    this.holeForgivenessRadius = 0,
  });

  final Vec2 direction;
  final double power;
  final TraitType? equippedTrait;

  /// 플레이어가 실제로 놓은 방향과 힘이다. 보정되지 않은 입력을 남겨
  /// 리플레이·텔레메트리에서 보정 효과와 원래 의도를 구분한다.
  final Vec2? rawDirection;
  final double? rawPower;
  final ShotAssistKind assistKind;
  final String? assistTargetId;

  /// 저속으로 홀 가장자리에 접근한 공만 허용하는 추가 포획 여유다.
  /// 직접 입력과 기존 리플레이는 0을 유지한다.
  final double holeForgivenessRadius;

  bool get wasAssisted => assistKind != ShotAssistKind.none;

  ShotInput normalized() {
    if (!direction.x.isFinite ||
        !direction.y.isFinite ||
        direction.length == 0) {
      throw ArgumentError.value(direction, 'direction', '0이 아닌 유한한 벡터여야 합니다.');
    }
    if (!power.isFinite) {
      throw ArgumentError.value(power, 'power', '유한한 수여야 합니다.');
    }
    final sourceDirection = rawDirection;
    if (sourceDirection != null &&
        (!sourceDirection.x.isFinite ||
            !sourceDirection.y.isFinite ||
            sourceDirection.length == 0)) {
      throw ArgumentError.value(
        sourceDirection,
        'rawDirection',
        '0이 아닌 유한한 벡터여야 합니다.',
      );
    }
    final sourcePower = rawPower;
    if (sourcePower != null &&
        (!sourcePower.isFinite || sourcePower < 0 || sourcePower > 1)) {
      throw ArgumentError.value(
        sourcePower,
        'rawPower',
        '0 이상 1 이하의 유한한 수여야 합니다.',
      );
    }
    if (!holeForgivenessRadius.isFinite ||
        holeForgivenessRadius < 0 ||
        holeForgivenessRadius > 16) {
      throw ArgumentError.value(
        holeForgivenessRadius,
        'holeForgivenessRadius',
        '0 이상 16 이하의 유한한 수여야 합니다.',
      );
    }
    return ShotInput(
      direction: direction.normalized(),
      power: power.clamp(0, 1).toDouble(),
      equippedTrait: equippedTrait,
      rawDirection: sourceDirection?.normalized(),
      rawPower: sourcePower?.clamp(0, 1).toDouble(),
      assistKind: assistKind,
      assistTargetId: assistTargetId,
      holeForgivenessRadius: holeForgivenessRadius,
    );
  }
}
