import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_state.dart';
import '../domain/shot_input.dart';
import '../simulation/shot_resolver.dart';

const int maxSolutionRoutesPerPattern = 4;

class SolutionRoute {
  const SolutionRoute({
    required this.signature,
    required this.label,
    required this.firstInput,
  });

  final String signature;
  final String label;
  final ShotInput firstInput;
}

SolutionRoute? deriveSolutionRoute({
  required Iterable<ShotInput> inputs,
  required Iterable<ShotResult> results,
}) {
  final safeInputs = inputs.take(33).toList(growable: false);
  final safeResults = results.take(33).toList(growable: false);
  if (safeInputs.isEmpty ||
      safeResults.isEmpty ||
      safeInputs.length != safeResults.length ||
      safeInputs.length > 32 ||
      safeResults.last.state.phase != GamePhase.success) {
    return null;
  }
  final tokens = <String>[];
  for (final input in safeInputs) {
    tokens.add('trait:${input.equippedTrait?.name ?? 'none'}');
  }
  for (final result in safeResults) {
    for (final impact in result.impacts.take(24)) {
      tokens.add('hit:${impact.entityType.name}');
    }
    for (final event in result.events.take(24)) {
      if (_meaningfulEvents.contains(event)) {
        tokens.add('event:$event');
      }
    }
  }
  final canonical = tokens.join('|');
  final signature = _fnv1a(canonical).toRadixString(16).padLeft(8, '0');
  return SolutionRoute(
    signature: signature,
    label: _routeLabel(tokens),
    firstInput: safeInputs.first.normalized(),
  );
}

const _meaningfulEvents = <String>{
  'switch_pressed',
  'gate_opened',
  'balloon_popped',
  'sticky_attached',
  'spent_ball_bounced',
  'bounced',
  'crate_pushed',
};

String _routeLabel(List<String> tokens) {
  bool has(String value) => tokens.any((token) => token.contains(value));
  if (has('spent_ball')) return '과거 공 연쇄 해법';
  if (has('balloon_popped')) return '풍선 장치 해법';
  if (has('switch_pressed') || has('gate_opened')) return '스위치·문 해법';
  if (has('sticky_attached')) return '점착 고정 해법';
  if (has('powerSlider')) return '가속 발판 해법';
  if (has('rotatingReflector')) return '회전 반사판 해법';
  if (has('wall')) return '벽 반사 해법';
  return '직접 조준 해법';
}

int _fnv1a(String value) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(value)) {
    hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
  }
  return hash;
}

class SolutionMasteryEntry {
  const SolutionMasteryEntry({
    required this.stageId,
    required this.patternId,
    required this.signature,
    required this.label,
    required this.firstDirectionX,
    required this.firstDirectionY,
    required this.firstPower,
  });

  final String stageId;
  final String patternId;
  final String signature;
  final String label;
  final double firstDirectionX;
  final double firstDirectionY;
  final double firstPower;

  Map<String, Object> toJson() => {
    'stageId': stageId,
    'patternId': patternId,
    'signature': signature,
    'label': label,
    'x': firstDirectionX,
    'y': firstDirectionY,
    'power': firstPower,
  };

  factory SolutionMasteryEntry.fromJson(Map<String, dynamic> json) {
    final stageId = json['stageId'];
    final patternId = json['patternId'];
    final signature = json['signature'];
    final label = json['label'];
    final x = json['x'];
    final y = json['y'];
    final power = json['power'];
    if (stageId is! String ||
        patternId is! String ||
        signature is! String ||
        label is! String ||
        x is! num ||
        y is! num ||
        power is! num ||
        !_safeId.hasMatch(stageId) ||
        !_safeId.hasMatch(patternId) ||
        !RegExp(r'^[0-9a-f]{8}$').hasMatch(signature) ||
        label.isEmpty ||
        label.length > 40 ||
        !x.isFinite ||
        !y.isFinite ||
        x * x + y * y < 0.000001 ||
        !power.isFinite ||
        power < 0 ||
        power > 1) {
      throw const FormatException('해법 도장 데이터가 올바르지 않습니다.');
    }
    return SolutionMasteryEntry(
      stageId: stageId,
      patternId: patternId,
      signature: signature,
      label: label,
      firstDirectionX: x.toDouble(),
      firstDirectionY: y.toDouble(),
      firstPower: power.toDouble(),
    );
  }
}

final _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,80}$');

class SolutionMasteryRecordResult {
  const SolutionMasteryRecordResult({
    required this.entries,
    required this.isNew,
  });
  final List<SolutionMasteryEntry> entries;
  final bool isNew;
}

class SolutionMasteryStore {
  SolutionMasteryStore(this._preferences);
  static const storageKey = 'property_shot_solution_mastery_v1';
  static const maxStoredEntries = 160;
  final SharedPreferences _preferences;
  Future<void> _tail = Future<void>.value();

  Future<List<SolutionMasteryEntry>> loadFor(
    String stageId,
    String patternId,
  ) async {
    final all = await _loadAll();
    return List.unmodifiable(
      all.where(
        (entry) => entry.stageId == stageId && entry.patternId == patternId,
      ),
    );
  }

  Future<Map<String, int>> loadCountsByStage() async {
    final all = await _loadAll();
    final counts = <String, int>{};
    for (final entry in all) {
      counts.update(entry.stageId, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  Future<SolutionMasteryRecordResult> record({
    required String stageId,
    required String patternId,
    required SolutionRoute route,
  }) {
    final operation = _tail.then((_) async {
      if (!_safeId.hasMatch(stageId) || !_safeId.hasMatch(patternId)) {
        throw ArgumentError('스테이지와 패턴 ID가 올바르지 않습니다.');
      }
      if (!RegExp(r'^[0-9a-f]{8}$').hasMatch(route.signature) ||
          route.label.isEmpty ||
          route.label.length > 40 ||
          !route.firstInput.direction.x.isFinite ||
          !route.firstInput.direction.y.isFinite ||
          route.firstInput.direction.length < 0.001 ||
          !route.firstInput.power.isFinite) {
        throw ArgumentError('해법 도장 내용이 올바르지 않습니다.');
      }
      final all = await _loadAll();
      final existing = all
          .where(
            (entry) => entry.stageId == stageId && entry.patternId == patternId,
          )
          .toList();
      if (existing.any((entry) => entry.signature == route.signature) ||
          existing.length >= maxSolutionRoutesPerPattern) {
        return SolutionMasteryRecordResult(
          entries: List.unmodifiable(existing),
          isNew: false,
        );
      }
      final normalized = route.firstInput.normalized();
      all.add(
        SolutionMasteryEntry(
          stageId: stageId,
          patternId: patternId,
          signature: route.signature,
          label: route.label,
          firstDirectionX: normalized.direction.x,
          firstDirectionY: normalized.direction.y,
          firstPower: normalized.power,
        ),
      );
      if (all.length > maxStoredEntries) {
        all.removeRange(0, all.length - maxStoredEntries);
      }
      final succeeded = await _preferences.setString(
        storageKey,
        jsonEncode(all.map((entry) => entry.toJson()).toList()),
      );
      if (!succeeded) throw StateError('해법 도장을 저장하지 못했습니다.');
      return SolutionMasteryRecordResult(
        entries: List.unmodifiable(
          all.where(
            (entry) => entry.stageId == stageId && entry.patternId == patternId,
          ),
        ),
        isNew: true,
      );
    });
    _tail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<List<SolutionMasteryEntry>> _loadAll() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null) return <SolutionMasteryEntry>[];
    try {
      if (raw.length > 200000) throw const FormatException();
      final decoded = jsonDecode(raw);
      if (decoded is! List || decoded.length > maxStoredEntries) {
        throw const FormatException();
      }
      final result = <SolutionMasteryEntry>[];
      final identities = <String>{};
      final perPatternCounts = <String, int>{};
      for (final value in decoded) {
        if (value is! Map<String, dynamic>) throw const FormatException();
        final entry = SolutionMasteryEntry.fromJson(value);
        if (identities.add(
          '${entry.stageId}|${entry.patternId}|${entry.signature}',
        )) {
          final patternKey = '${entry.stageId}|${entry.patternId}';
          final count = (perPatternCounts[patternKey] ?? 0) + 1;
          if (count > maxSolutionRoutesPerPattern) {
            throw const FormatException();
          }
          perPatternCounts[patternKey] = count;
          result.add(entry);
        }
      }
      return result;
    } on Object {
      await _preferences.remove(storageKey);
      return <SolutionMasteryEntry>[];
    }
  }
}

class SolutionShareCardCodec {
  const SolutionShareCardCodec._();
  static const prefix = 'PSS1-';

  static String encode(SolutionMasteryEntry entry) {
    final bytes = utf8.encode(jsonEncode(entry.toJson()));
    final body = base64Url.encode(bytes).replaceAll('=', '');
    return '$prefix$body-${_fnvBytes(bytes).toRadixString(16).padLeft(8, '0')}';
  }

  static SolutionMasteryEntry decode(String code) {
    final value = code.trim();
    if (value.length > 4096 || !value.startsWith(prefix)) {
      throw const FormatException('속성 한방 해법 카드가 아닙니다.');
    }
    final split = value.lastIndexOf('-');
    if (split <= prefix.length) {
      throw const FormatException('해법 카드 형식이 올바르지 않습니다.');
    }
    try {
      final body = value.substring(prefix.length, split);
      final bytes = base64Url.decode(
        body.padRight((body.length + 3) ~/ 4 * 4, '='),
      );
      final expected = int.parse(value.substring(split + 1), radix: 16);
      if (_fnvBytes(bytes) != expected) {
        throw const FormatException('해법 카드가 손상되었습니다.');
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, dynamic>) throw const FormatException();
      return SolutionMasteryEntry.fromJson(json);
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('해법 카드를 읽을 수 없습니다.');
    }
  }

  static int _fnvBytes(List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final byte in bytes) {
      hash = ((hash ^ byte) * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
