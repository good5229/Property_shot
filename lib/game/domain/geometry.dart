import 'dart:math' as math;

class Vec2 {
  const Vec2(this.x, this.y);

  final double x;
  final double y;

  static const zero = Vec2(0, 0);

  Vec2 operator +(Vec2 other) => Vec2(x + other.x, y + other.y);
  Vec2 operator -(Vec2 other) => Vec2(x - other.x, y - other.y);
  Vec2 operator -() => Vec2(-x, -y);
  Vec2 operator *(double scale) => Vec2(x * scale, y * scale);

  double get length => math.sqrt((x * x) + (y * y));

  double dot(Vec2 other) => (x * other.x) + (y * other.y);

  Vec2 normalized() {
    final magnitude = length;
    if (magnitude == 0) {
      return zero;
    }
    return Vec2(x / magnitude, y / magnitude);
  }

  double distanceTo(Vec2 other) => (this - other).length;

  Vec2 reflectX() => Vec2(-x, y);
  Vec2 reflectY() => Vec2(x, -y);

  Vec2 reflectedBy(Vec2 normal) {
    final unit = normal.normalized();
    return (this - unit * (2 * dot(unit))).normalized();
  }

  Map<String, double> toJson() => {'x': x, 'y': y};

  @override
  bool operator ==(Object other) {
    return other is Vec2 &&
        (x - other.x).abs() < 0.001 &&
        (y - other.y).abs() < 0.001;
  }

  @override
  int get hashCode => Object.hash(x.toStringAsFixed(3), y.toStringAsFixed(3));

  @override
  String toString() => 'Vec2(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)})';
}

class Bounds {
  const Bounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
  double get bottom => top + height;
  Vec2 get center => Vec2(left + width / 2, top + height / 2);

  bool contains(Vec2 point) {
    return point.x >= left &&
        point.x <= right &&
        point.y >= top &&
        point.y <= bottom;
  }

  bool intersectsCircle(Vec2 center, double radius) {
    final nearestX = center.x.clamp(left, right);
    final nearestY = center.y.clamp(top, bottom);
    return center.distanceTo(Vec2(nearestX, nearestY)) <= radius;
  }

  Vec2 nearestPoint(Vec2 point) {
    return Vec2(point.x.clamp(left, right), point.y.clamp(top, bottom));
  }

  Bounds scaled(double scale) {
    final nextWidth = width * scale;
    final nextHeight = height * scale;
    return Bounds(
      left: center.x - nextWidth / 2,
      top: center.y - nextHeight / 2,
      width: nextWidth,
      height: nextHeight,
    );
  }
}
