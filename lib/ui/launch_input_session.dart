import '../game/domain/geometry.dart';

enum LaunchInputReleaseKind { ignored, tap, aimed, launch }

class LaunchInputRelease {
  const LaunchInputRelease({
    required this.kind,
    this.power,
    this.lastLogicalPosition,
    this.chargeStartedAt,
  });

  final LaunchInputReleaseKind kind;
  final double? power;
  final Vec2? lastLogicalPosition;
  final Duration? chargeStartedAt;

  bool get shouldLaunch => kind == LaunchInputReleaseKind.launch;
}

/// Pointer 입력과 충전 계산을 렌더링 프레임에서 분리한다.
class LaunchInputSession {
  static const activationDelay = Duration(milliseconds: 450);
  static const moveThreshold = 8.0;
  static const minimumPower = 0.12;
  static const maximumPower = 1.0;
  static const powerPerChargePeriod = 0.055;
  static const chargePeriod = Duration(milliseconds: 80);

  int? get activePointer => _activePointer;
  bool get isActive => _activePointer != null;
  bool get hasMoved => _hasMoved;
  bool get chargeCancelled => _chargeCancelled;
  Vec2? get lastLogicalPosition => _lastLogicalPosition;
  Duration? get pointerDownAt => _pointerDownAt;
  Duration? get chargeStartedAt =>
      _pointerDownAt == null ? null : _pointerDownAt! + activationDelay;
  Duration? get lastEventAt => _lastEventAt;

  int? _activePointer;
  Vec2? _pointerDownPosition;
  Vec2? _lastLogicalPosition;
  Duration? _pointerDownAt;
  Duration? _lastEventAt;
  bool _onBall = false;
  bool _hasMoved = false;
  bool _chargeCancelled = false;

  bool begin({
    required int pointer,
    required Vec2 logicalPosition,
    required Duration timeStamp,
    required bool onBall,
  }) {
    if (isActive) {
      return false;
    }
    _activePointer = pointer;
    _pointerDownPosition = logicalPosition;
    _lastLogicalPosition = null;
    _pointerDownAt = timeStamp;
    _lastEventAt = timeStamp;
    _onBall = onBall;
    _hasMoved = false;
    _chargeCancelled = false;
    return true;
  }

  bool move({
    required int pointer,
    required Vec2 logicalPosition,
    required Duration timeStamp,
  }) {
    if (pointer != _activePointer) {
      return false;
    }
    _lastEventAt = timeStamp;
    final down = _pointerDownPosition;
    if (down == null) {
      return false;
    }
    if (!_hasMoved && down.distanceTo(logicalPosition) < moveThreshold) {
      return false;
    }
    if (!_hasMoved) {
      _hasMoved = true;
      if (_onBall && !isChargingAt(timeStamp)) {
        _chargeCancelled = true;
      }
    }
    _lastLogicalPosition = logicalPosition;
    return true;
  }

  bool isChargingAt(Duration timeStamp) {
    final startedAt = chargeStartedAt;
    return _onBall &&
        !_chargeCancelled &&
        startedAt != null &&
        timeStamp >= startedAt;
  }

  double powerAt(Duration timeStamp) {
    final startedAt = chargeStartedAt;
    if (startedAt == null || !isChargingAt(timeStamp)) {
      return minimumPower;
    }
    final elapsedMicros = timeStamp.inMicroseconds - startedAt.inMicroseconds;
    final periods = elapsedMicros / chargePeriod.inMicroseconds;
    return (minimumPower + periods * powerPerChargePeriod)
        .clamp(minimumPower, maximumPower)
        .toDouble();
  }

  LaunchInputRelease release({
    required int pointer,
    required Vec2 logicalPosition,
    required Duration timeStamp,
  }) {
    if (pointer != _activePointer) {
      return const LaunchInputRelease(kind: LaunchInputReleaseKind.ignored);
    }
    _lastEventAt = timeStamp;
    if (_hasMoved) {
      _lastLogicalPosition = logicalPosition;
    }
    final lastPosition = _lastLogicalPosition;
    final startedAt = chargeStartedAt;
    final result = isChargingAt(timeStamp)
        ? LaunchInputRelease(
            kind: LaunchInputReleaseKind.launch,
            power: powerAt(timeStamp),
            lastLogicalPosition: lastPosition,
            chargeStartedAt: startedAt,
          )
        : LaunchInputRelease(
            kind: _hasMoved
                ? LaunchInputReleaseKind.aimed
                : LaunchInputReleaseKind.tap,
            lastLogicalPosition: lastPosition,
            chargeStartedAt: startedAt,
          );
    reset();
    return result;
  }

  bool cancel({int? pointer}) {
    if (pointer != null && pointer != _activePointer) {
      return false;
    }
    final hadPointer = isActive;
    reset();
    return hadPointer;
  }

  void reset() {
    _activePointer = null;
    _pointerDownPosition = null;
    _lastLogicalPosition = null;
    _pointerDownAt = null;
    _lastEventAt = null;
    _onBall = false;
    _hasMoved = false;
    _chargeCancelled = false;
  }
}
