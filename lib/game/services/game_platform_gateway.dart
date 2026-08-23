/// 외부 게임 플랫폼과 제품 코드를 분리하는 게스트 우선 경계다.
///
/// Hive SDK가 Flutter Web을 공식 지원하는지 확인된 뒤 이 인터페이스의
/// 새 구현을 주입한다. 현재 제품은 [DeviceOnlyGamePlatformGateway]만 쓴다.
abstract interface class GamePlatformGateway {
  GamePlatformCapabilities get capabilities;

  Future<GamePlatformReceipt> publishDailyResult(DailyPlatformResult result);
}

class GamePlatformCapabilities {
  const GamePlatformCapabilities({
    required this.providerId,
    required this.guestPlay,
    required this.remoteLeaderboard,
    required this.cloudSave,
    required this.achievements,
  });

  final String providerId;
  final bool guestPlay;
  final bool remoteLeaderboard;
  final bool cloudSave;
  final bool achievements;
}

class DailyPlatformResult {
  static const maxTotalScore = 1000000;
  static const maxTotalShots = 10000;

  DailyPlatformResult({
    required this.dateKey,
    required this.variantId,
    required this.totalScore,
    required this.totalShots,
    required this.official,
  }) {
    if (!_isCalendarDate(dateKey)) {
      throw ArgumentError.value(dateKey, 'dateKey', 'YYYY-MM-DD 형식이어야 합니다.');
    }
    if (!RegExp(r'^[a-z0-9_]{1,64}$').hasMatch(variantId)) {
      throw ArgumentError.value(
        variantId,
        'variantId',
        '영문 소문자, 숫자, 밑줄로 된 1~64자여야 합니다.',
      );
    }
    if (totalScore < 0 || totalScore > maxTotalScore) {
      throw ArgumentError.value(
        totalScore,
        'totalScore',
        '0~$maxTotalScore 범위여야 합니다.',
      );
    }
    if (totalShots <= 0 || totalShots > maxTotalShots) {
      throw ArgumentError.value(
        totalShots,
        'totalShots',
        '1~$maxTotalShots 범위여야 합니다.',
      );
    }
  }

  static bool _isCalendarDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (year < 2000 || year > 2100 || month < 1 || month > 12 || day < 1) {
      return false;
    }
    final parsed = DateTime.utc(year, month, day);
    return parsed.year == year && parsed.month == month && parsed.day == day;
  }

  final String dateKey;
  final String variantId;
  final int totalScore;
  final int totalShots;
  final bool official;
}

class GamePlatformReceipt {
  const GamePlatformReceipt({
    required this.providerId,
    required this.savedOnDevice,
    required this.publishedRemotely,
    required this.playerMessage,
  });

  final String providerId;
  final bool savedOnDevice;
  final bool publishedRemotely;
  final String playerMessage;
}

/// 로그인 없이 기기 기록만 사용하는 현재 제품 구현이다.
class DeviceOnlyGamePlatformGateway implements GamePlatformGateway {
  const DeviceOnlyGamePlatformGateway();

  @override
  GamePlatformCapabilities get capabilities => const GamePlatformCapabilities(
    providerId: 'device_only',
    guestPlay: true,
    remoteLeaderboard: false,
    cloudSave: false,
    achievements: false,
  );

  @override
  Future<GamePlatformReceipt> publishDailyResult(
    DailyPlatformResult result,
  ) async {
    return GamePlatformReceipt(
      providerId: capabilities.providerId,
      savedOnDevice: true,
      publishedRemotely: false,
      playerMessage: result.official
          ? '기기 기록에 저장했습니다. 온라인 순위는 아직 연결하지 않았습니다.'
          : '연습 기록은 이 화면에서만 확인할 수 있습니다.',
    );
  }
}
