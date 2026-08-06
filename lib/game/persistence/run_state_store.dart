import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../run/run_state.dart';
import '../run/stable_seed.dart';

/// RunState 저장에 필요한 최소 key-value 계약이다.
/// 테스트에서는 이 계약을 구현해 각 저장 단계의 실패를 주입할 수 있다.
abstract interface class RunStateKeyValueBackend {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);
}

/// 실제 앱에서는 SharedPreferences를 별도 key 영역으로 감싼다.
class SharedPreferencesRunStateBackend implements RunStateKeyValueBackend {
  const SharedPreferencesRunStateBackend(this.preferences);

  final SharedPreferences preferences;

  @override
  Future<String?> read(String key) async => preferences.getString(key);

  @override
  Future<void> write(String key, String value) async {
    final written = await preferences.setString(key, value);
    if (!written) {
      throw StateError('RunState 저장에 실패했습니다: $key');
    }
  }

  @override
  Future<void> remove(String key) async {
    final removed = await preferences.remove(key);
    if (!removed && preferences.containsKey(key)) {
      throw StateError('RunState 삭제에 실패했습니다: $key');
    }
  }
}

/// RunState를 revision이 증가하는 두 슬롯에 저장한다.
///
/// 슬롯을 먼저 완결 상태로 기록하고 다시 읽어 검증한 다음 pointer를 바꾼다.
/// 따라서 pointer 기록 전에 프로세스가 끝나도 다음 load가 더 높은 유효
/// revision을 선택할 수 있다.
class RunStateStore {
  RunStateStore({required this.backend});

  static const schemaVersion = 1;
  static const slotAKey = 'property_shot_run_state_slot_a';
  static const slotBKey = 'property_shot_run_state_slot_b';
  static const activePointerKey = 'property_shot_run_state_active_pointer';

  final RunStateKeyValueBackend backend;
  Future<void> _writeTail = Future<void>.value();
  int? _lastRevision;

  int? get lastRevision => _lastRevision;

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    return next;
  }

  Future<RunState?> load() => _enqueue(_loadUnqueued);

  /// 저장한 revision을 반환한다. 호출자는 이 값을 화면 상태가 아니라
  /// 진단·테스트용으로만 사용하고, 재개 기준은 항상 load 결과로 삼는다.
  Future<int> save(RunState state) {
    return _enqueue(() async {
      final candidates = await _readCandidates();
      final pointer = await _readPointer();
      final selected = _selectCandidate(candidates, pointer);
      final nextRevision = _maxRevision(candidates) + 1;
      final targetSlot = _targetSlot(candidates, selected);
      final payload = canonicalJson(state.toJson());
      final envelope = _encodeEnvelope(
        revision: nextRevision,
        payload: payload,
      );

      await backend.write(_keyFor(targetSlot), envelope);
      final verified = await _readCandidate(targetSlot);
      if (verified == null ||
          verified.revision != nextRevision ||
          verified.payload != payload) {
        throw StateError('RunState 후보 슬롯 검증에 실패했습니다.');
      }

      await backend.write(activePointerKey, _pointerFor(targetSlot));
      _lastRevision = nextRevision;
      return nextRevision;
    });
  }

  /// 두 슬롯과 pointer를 순서대로 지운다. 중간에 실패하면 남은 유효 슬롯을
  /// load할 수 있으므로 부분 reset에서 저장 데이터가 조용히 사라지지 않는다.
  Future<void> reset() {
    return _enqueue(() async {
      await backend.remove(slotAKey);
      await backend.remove(slotBKey);
      await backend.remove(activePointerKey);
      _lastRevision = null;
    });
  }

  Future<RunState?> _loadUnqueued() async {
    final candidates = await _readCandidates();
    final pointer = await _readPointer();
    final selected = _selectCandidate(candidates, pointer);
    _lastRevision = selected?.revision;
    return selected?.state;
  }

  Future<Map<_RunStateSlot, _RunStateEnvelope?>> _readCandidates() async {
    return {
      _RunStateSlot.a: await _readCandidate(_RunStateSlot.a),
      _RunStateSlot.b: await _readCandidate(_RunStateSlot.b),
    };
  }

  Future<_RunStateEnvelope?> _readCandidate(_RunStateSlot slot) async {
    final raw = await _readSafely(_keyFor(slot));
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final envelope = _mapValue(jsonDecode(raw), 'RunState envelope');
      if (envelope['schemaVersion'] != schemaVersion ||
          envelope['complete'] != true ||
          envelope['revision'] is! int ||
          (envelope['revision'] as int) <= 0 ||
          envelope['payload'] is! String ||
          envelope['checksum'] is! String) {
        return null;
      }
      final revision = envelope['revision'] as int;
      final payload = envelope['payload'] as String;
      final checksum = envelope['checksum'] as String;
      final decodedPayload = _mapValue(jsonDecode(payload), 'RunState payload');
      final canonicalPayload = canonicalJson(decodedPayload);
      if (canonicalPayload != payload ||
          runStatePayloadChecksum(payload) != checksum) {
        return null;
      }
      final state = RunState.fromJson(decodedPayload);
      return _RunStateEnvelope(
        slot: slot,
        revision: revision,
        payload: payload,
        checksum: checksum,
        state: state,
      );
    } on Object {
      return null;
    }
  }

  Future<String?> _readSafely(String key) async {
    try {
      return await backend.read(key);
    } on Object {
      return null;
    }
  }

  Future<String?> _readPointer() async {
    final value = await _readSafely(activePointerKey);
    if (value == 'a' || value == 'b') {
      return value;
    }
    return null;
  }

  _RunStateEnvelope? _selectCandidate(
    Map<_RunStateSlot, _RunStateEnvelope?> candidates,
    String? pointer,
  ) {
    final a = candidates[_RunStateSlot.a];
    final b = candidates[_RunStateSlot.b];
    if (a == null) return b;
    if (b == null) return a;
    if (a.revision > b.revision) return a;
    if (b.revision > a.revision) return b;
    if (pointer == 'a') return a;
    if (pointer == 'b') return b;
    return a;
  }

  int _maxRevision(Map<_RunStateSlot, _RunStateEnvelope?> candidates) {
    var maximum = 0;
    for (final candidate in candidates.values) {
      if (candidate != null && candidate.revision > maximum) {
        maximum = candidate.revision;
      }
    }
    return maximum;
  }

  _RunStateSlot _targetSlot(
    Map<_RunStateSlot, _RunStateEnvelope?> candidates,
    _RunStateEnvelope? selected,
  ) {
    if (selected == null) return _RunStateSlot.a;
    return selected.slot == _RunStateSlot.a ? _RunStateSlot.b : _RunStateSlot.a;
  }

  String _keyFor(_RunStateSlot slot) {
    return slot == _RunStateSlot.a ? slotAKey : slotBKey;
  }

  String _pointerFor(_RunStateSlot slot) {
    return slot == _RunStateSlot.a ? 'a' : 'b';
  }

  String _encodeEnvelope({required int revision, required String payload}) {
    return jsonEncode({
      'schemaVersion': schemaVersion,
      'complete': true,
      'revision': revision,
      'payload': payload,
      'checksum': runStatePayloadChecksum(payload),
    });
  }
}

enum _RunStateSlot { a, b }

class _RunStateEnvelope {
  const _RunStateEnvelope({
    required this.slot,
    required this.revision,
    required this.payload,
    required this.checksum,
    required this.state,
  });

  final _RunStateSlot slot;
  final int revision;
  final String payload;
  final String checksum;
  final RunState state;
}

String runStatePayloadChecksum(String canonicalPayload) {
  return StableSeed.hashString(
    canonicalPayload,
  ).toRadixString(16).padLeft(8, '0');
}

/// Map의 key를 정렬해 VM/Web에서 동일한 JSON 문자열을 만든다.
String canonicalJson(Object? value) {
  return jsonEncode(_canonicalValue(value));
}

Object? _canonicalValue(Object? value) {
  if (value is Map) {
    final entries = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('canonical JSON의 key가 문자열이 아닙니다.');
      }
      entries[entry.key as String] = _canonicalValue(entry.value);
    }
    final keys = entries.keys.toList()..sort();
    return {for (final key in keys) key: entries[key]};
  }
  if (value is List) {
    return value.map(_canonicalValue).toList();
  }
  if (value is num && !value.isFinite) {
    throw FormatException('canonical JSON에 유한하지 않은 숫자가 있습니다.');
  }
  return value;
}

Map<String, dynamic> _mapValue(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('$path가 Map이 아닙니다.');
  }
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('$path의 key가 문자열이 아닙니다.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}
