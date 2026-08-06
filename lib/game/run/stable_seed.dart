/// VM과 Web에서 같은 결과를 내는 32비트 seed와 난수 도구다.
///
/// 모든 중간 연산을 unsigned 32비트로 제한한다. 특히 곱셈은 JavaScript의
/// 안전 정수 범위를 넘지 않도록 16비트 부분곱으로 계산한다.
class StableSeed {
  StableSeed._();

  static const int mask = 0xffffffff;
  static const int _fnvOffset = 0x811c9dc5;
  static const int _fnvPrime = 0x01000193;
  static const int _mixConstant = 0x9e3779b1;

  /// UTF-16 code unit을 대상으로 하는 고정 FNV-1a 해시다.
  static int hashString(String value, {int seed = _fnvOffset}) {
    var hash = normalize(seed);
    for (final codeUnit in value.codeUnits) {
      hash = normalize(hash ^ codeUnit);
      hash = _multiply32(hash, _fnvPrime);
    }
    return hash;
  }

  /// 문자열과 정수 필드를 섞어 목적별 seed를 만든다.
  static int deriveSeed({
    required int rootSeed,
    required String stageId,
    required int cycle,
    required int drawIndex,
    String? patternId,
    String purpose = 'pattern',
  }) {
    _requireNonNegative(cycle, 'cycle');
    _requireNonNegative(drawIndex, 'drawIndex');
    if (stageId.isEmpty) {
      throw ArgumentError.value(stageId, 'stageId', '비어 있을 수 없습니다.');
    }

    var hash = _mix(_fnvOffset, normalize(rootSeed));
    hash = _mix(hash, hashString(stageId));
    hash = _mix(hash, cycle);
    hash = _mix(hash, drawIndex);
    hash = _mix(hash, patternId == null ? 0 : hashString(patternId));
    hash = _mix(hash, hashString(purpose));
    return _avalanche(hash);
  }

  static int bagSeed({
    required int rootSeed,
    required String stageId,
    required int cycle,
  }) {
    return deriveSeed(
      rootSeed: rootSeed,
      stageId: stageId,
      cycle: cycle,
      drawIndex: 0,
      purpose: 'bag',
    );
  }

  static int patternSeed({
    required int rootSeed,
    required String stageId,
    required int cycle,
    required int drawIndex,
    required String patternId,
  }) {
    if (patternId.isEmpty) {
      throw ArgumentError.value(patternId, 'patternId', '비어 있을 수 없습니다.');
    }
    return deriveSeed(
      rootSeed: rootSeed,
      stageId: stageId,
      cycle: cycle,
      drawIndex: drawIndex,
      patternId: patternId,
      purpose: 'pattern',
    );
  }

  static int normalize(int value) => value & mask;

  static int _mix(int hash, int value) {
    final mixed = _multiply32(normalize(hash ^ normalize(value)), _mixConstant);
    return normalize(mixed ^ (mixed >> 16));
  }

  static int _avalanche(int value) {
    var hash = normalize(value);
    hash = normalize(hash ^ (hash >> 16));
    hash = _multiply32(hash, 0x85ebca6b);
    hash = normalize(hash ^ (hash >> 13));
    hash = _multiply32(hash, 0xc2b2ae35);
    return normalize(hash ^ (hash >> 16));
  }

  // a와 b의 16비트 부분곱만 사용해 53비트 안전 정수 범위 안에서 계산한다.
  static int _multiply32(int a, int b) {
    final aLow = normalize(a) & 0xffff;
    final aHigh = normalize(a) >> 16;
    final bLow = normalize(b) & 0xffff;
    final bHigh = normalize(b) >> 16;
    final low = aLow * bLow;
    final middle = (aHigh * bLow) + (aLow * bHigh);
    return normalize(low + ((middle & 0xffff) << 16));
  }

  static void _requireNonNegative(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, '음수일 수 없습니다.');
    }
  }
}

/// StableSeed가 생성한 seed만 사용하는 결정론적 Fisher-Yates 도구다.
class StableRandom {
  StableRandom(int seed)
    : _state = StableSeed.normalize(seed) == 0
          ? 0x6d2b79f5
          : StableSeed.normalize(seed);

  int _state;

  int nextUint32() {
    var value = _state;
    value = StableSeed.normalize(value ^ (value << 13));
    value = StableSeed.normalize(value ^ (value >> 17));
    value = StableSeed.normalize(value ^ (value << 5));
    _state = value;
    return value;
  }

  int nextInt(int max) {
    if (max <= 0) {
      throw ArgumentError.value(max, 'max', '0보다 커야 합니다.');
    }
    return nextUint32() % max;
  }

  List<T> shuffled<T>(Iterable<T> values) {
    final result = values.toList();
    for (var index = result.length - 1; index > 0; index--) {
      final swapIndex = nextInt(index + 1);
      final value = result[index];
      result[index] = result[swapIndex];
      result[swapIndex] = value;
    }
    return result;
  }
}
