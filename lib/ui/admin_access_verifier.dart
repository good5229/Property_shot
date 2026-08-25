import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// 정적 Web 빌드에서 일반 사용자에게 내부 제작 도구를 노출하지 않기 위한
/// 세션 한정 표시 게이트다.
///
/// 서버 인증이 아니므로 권한 경계로 사용하지 않는다. 입력 원문은 저장하지
/// 않고 SHA-256 결과만 일정 시간 비교하며, 새로고침하면 인증 상태가 사라진다.
class AdminAccessVerifier {
  const AdminAccessVerifier({
    this.expectedIdHash =
        '2196a47462dd61cb1e59afec24f7d581499268019e3afd15c523be67c8cf6320',
    this.expectedPasswordHash =
        'b1a508392abc47e8c3f14be2da38ba19fd654ee6b7c765b9368b1d824502d277',
  });

  final String expectedIdHash;
  final String expectedPasswordHash;

  bool verify({required String id, required String password}) {
    if (id.isEmpty || password.isEmpty) return false;
    return _constantTimeEquals(_digest(id.trim()), expectedIdHash) &
        _constantTimeEquals(_digest(password), expectedPasswordHash);
  }

  @visibleForTesting
  static String digestForTesting(String value) => _digest(value);

  static String _digest(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static bool _constantTimeEquals(String actual, String expected) {
    var difference = actual.length ^ expected.length;
    final length = actual.length < expected.length
        ? actual.length
        : expected.length;
    for (var index = 0; index < length; index++) {
      difference |= actual.codeUnitAt(index) ^ expected.codeUnitAt(index);
    }
    return difference == 0;
  }
}
