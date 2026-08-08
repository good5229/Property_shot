import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'replay_document.dart';
import 'replay_failure.dart';

const String replaySharePrefix = '속한1:';
const String replaySharePrefixFamily = '속한';
const int replayShareVersion = 1;
const int replayShareMaxPayloadBytes = 16 * 1024;
const int replayShareMaxDisplayCharacters = 2048;
const int replayShareMaxRawInputCharacters = 64 * 1024;

/// 정확히 64개의 서로 다른 한글 음절이며 순서 자체가 전송 규격이다.
const String replayKoreanAlphabet =
    '가각간갇갈감갑값갓강개객갠갤갬갯갱걀걔거건걸검겁것겉게겨격견결겸경계고곡곤골곰곱곳공과관광괘괴굉교구국군굴굵굶굽궁권귀규균귤그극';

class ReplayShareCode {
  ReplayShareCode._();

  static const prefix = replaySharePrefix;
  static const version = replayShareVersion;
  static const alphabet = replayKoreanAlphabet;
  static const maxPayloadBytes = replayShareMaxPayloadBytes;
  static const maxDisplayCharacters = replayShareMaxDisplayCharacters;
  static const maxRawInputCharacters = replayShareMaxRawInputCharacters;

  /// SHA-256 태그는 공유 중 생긴 오류와 변조를 검출하기 위한 값일 뿐이다.
  /// 비밀 키가 없는 해시이므로 작성자나 출처를 인증하지 않으며, 서버가
  /// 검증한 공식 기록의 신뢰 근거로 사용해서는 안 된다.
  static String encode(ReplayDocument document) {
    final payload = document.toCanonicalJson();
    final payloadBytes = utf8.encode(payload);
    if (payloadBytes.length > maxPayloadBytes) {
      throw const ReplayFailure(ReplayFailureCode.payloadTooLarge);
    }
    final bytes = <int>[...payloadBytes, ...sha256.convert(payloadBytes).bytes];
    final code = '$prefix${_encode6Bit(bytes)}';
    if (code.length > maxDisplayCharacters) {
      throw const ReplayFailure(ReplayFailureCode.displayTooLarge);
    }
    return code;
  }

  static ReplayDocument decode(String value) {
    if (value.length > maxRawInputCharacters) {
      throw const ReplayFailure(ReplayFailureCode.rawInputTooLarge);
    }
    final normalized = _removeIgnored(value);
    if (normalized.length > maxDisplayCharacters) {
      throw const ReplayFailure(ReplayFailureCode.displayTooLarge);
    }
    if (!normalized.startsWith(replaySharePrefixFamily)) {
      throw const ReplayFailure(ReplayFailureCode.invalidSharePrefix);
    }
    if (normalized.length < 4 || normalized[2] != '1') {
      throw const ReplayFailure(ReplayFailureCode.unsupportedShareVersion);
    }
    if (!normalized.startsWith(replaySharePrefix)) {
      throw const ReplayFailure(ReplayFailureCode.invalidSharePrefix);
    }
    final encoded = normalized.substring(replaySharePrefix.length);
    if (encoded.isEmpty) {
      throw const ReplayFailure(ReplayFailureCode.invalidSharePayload);
    }
    for (final rune in encoded.runes) {
      if (!replayKoreanAlphabet.contains(String.fromCharCode(rune))) {
        throw const ReplayFailure(ReplayFailureCode.invalidShareAlphabet);
      }
    }
    final bytes = _decode6Bit(encoded);
    if (bytes.length < 32) {
      throw const ReplayFailure(ReplayFailureCode.invalidSharePayload);
    }
    final payloadLength = bytes.length - 32;
    if (payloadLength > maxPayloadBytes) {
      throw const ReplayFailure(ReplayFailureCode.payloadTooLarge);
    }
    final payloadBytes = bytes.sublist(0, payloadLength);
    final suppliedTag = bytes.sublist(payloadLength);
    final expectedTag = sha256.convert(payloadBytes).bytes;
    if (!_constantTimeEquals(suppliedTag, expectedTag)) {
      throw const ReplayFailure(ReplayFailureCode.integrityMismatch);
    }
    try {
      final payload = utf8.decode(payloadBytes, allowMalformed: false);
      final document = ReplayDocument.fromCanonicalJson(payload);
      if (document.toCanonicalJson() != payload) {
        throw const ReplayFailure(ReplayFailureCode.invalidSharePayload);
      }
      return document;
    } on ReplayFailure {
      rethrow;
    } on Object catch (error) {
      throw ReplayFailure(ReplayFailureCode.invalidSharePayload, '$error');
    }
  }

  static ReplayParseResult<ReplayDocument> tryDecode(String value) {
    try {
      return ReplayParseResult.success(decode(value));
    } on ReplayFailure catch (failure) {
      return ReplayParseResult.failure(failure);
    }
  }
}

class ReplayShareCodec {
  ReplayShareCodec._();

  static String encode(ReplayDocument document) =>
      ReplayShareCode.encode(document);
  static ReplayDocument decode(String value) => ReplayShareCode.decode(value);
  static ReplayParseResult<ReplayDocument> tryDecode(String value) =>
      ReplayShareCode.tryDecode(value);
}

String encodeReplayShareCode(ReplayDocument document) =>
    ReplayShareCode.encode(document);
ReplayDocument decodeReplayShareCode(String value) =>
    ReplayShareCode.decode(value);

/// 무결성 연산을 표준 벡터로 독립 검증하기 위한 공개 도우미다.
String replaySha256Hex(String value) {
  final bytes = sha256.convert(utf8.encode(value)).bytes;
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}

String _removeIgnored(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    if (rune == 0x20 ||
        rune == 0x09 ||
        rune == 0x0a ||
        rune == 0x0d ||
        rune == 0x2d) {
      continue;
    }
    buffer.writeCharCode(rune);
  }
  return buffer.toString();
}

String _encode6Bit(List<int> bytes) {
  final buffer = StringBuffer();
  var accumulator = 0;
  var bits = 0;
  for (final byte in bytes) {
    accumulator = (accumulator << 8) | byte;
    bits += 8;
    while (bits >= 6) {
      bits -= 6;
      buffer.write(replayKoreanAlphabet[(accumulator >> bits) & 0x3f]);
    }
    if (bits > 0) accumulator &= (1 << bits) - 1;
  }
  if (bits > 0) {
    buffer.write(replayKoreanAlphabet[(accumulator << (6 - bits)) & 0x3f]);
  }
  return buffer.toString();
}

List<int> _decode6Bit(String encoded) {
  final bytes = <int>[];
  var accumulator = 0;
  var bits = 0;
  for (final rune in encoded.runes) {
    final value = replayKoreanAlphabet.indexOf(String.fromCharCode(rune));
    accumulator = (accumulator << 6) | value;
    bits += 6;
    while (bits >= 8) {
      bits -= 8;
      bytes.add((accumulator >> bits) & 0xff);
    }
    if (bits > 0) accumulator &= (1 << bits) - 1;
  }
  if (bits > 0 && accumulator != 0) {
    throw const ReplayFailure(ReplayFailureCode.invalidSharePayload);
  }
  return bytes;
}

bool _constantTimeEquals(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  var difference = 0;
  for (var index = 0; index < left.length; index++) {
    difference |= left[index] ^ right[index];
  }
  return difference == 0;
}
