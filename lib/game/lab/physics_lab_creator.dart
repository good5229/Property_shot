import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../domain/entity_state.dart';
import '../domain/geometry.dart';
import '../domain/level_definition.dart';
import 'physics_lab.dart';

const physicsLabSharePrefix = '속실1:';
const physicsLabShareMaxCharacters = 1024;

enum LabGoalPosition {
  northwest('왼쪽 위', Vec2(70, 85)),
  north('가운데 위', Vec2(180, 85)),
  northeast('오른쪽 위', Vec2(290, 85));

  const LabGoalPosition(this.label, this.position);
  final String label;
  final Vec2 position;
}

class PhysicsLabDraft {
  const PhysicsLabDraft({
    required this.baseScenarioId,
    required this.goalPosition,
  });

  final String baseScenarioId;
  final LabGoalPosition goalPosition;

  Map<String, Object> toJson() => {
    'version': 1,
    'baseScenarioId': baseScenarioId,
    'goalPosition': goalPosition.name,
  };

  static PhysicsLabDraft fromJson(Map<String, Object?> json) {
    if (json.length != 3 || json['version'] != 1) {
      throw const FormatException('지원하지 않는 실험 코드입니다.');
    }
    final scenarioId = json['baseScenarioId'];
    final positionName = json['goalPosition'];
    if (scenarioId is! String || positionName is! String) {
      throw const FormatException('실험 코드의 형식이 올바르지 않습니다.');
    }
    final position = LabGoalPosition.values
        .where((item) => item.name == positionName)
        .firstOrNull;
    if (position == null) {
      throw const FormatException('알 수 없는 목표 위치입니다.');
    }
    return PhysicsLabDraft(baseScenarioId: scenarioId, goalPosition: position);
  }
}

class PhysicsLabDraftValidator {
  const PhysicsLabDraftValidator();

  String? validate(PhysicsLabDraft draft) {
    final base = physicsLabScenarios
        .where((item) => item.id == draft.baseScenarioId)
        .firstOrNull;
    if (base == null) return '알 수 없는 실험 템플릿입니다.';
    final scenario = build(draft);
    final entities = scenario.level.entities;
    if (entities.length > 12) return '기물이 너무 많습니다.';
    if (entities.map((item) => item.id).toSet().length != entities.length) {
      return '기물 이름이 중복됩니다.';
    }
    final hole = entities
        .where((item) => item.type == EntityType.hole)
        .firstOrNull;
    if (hole == null) return '목표 홀이 없습니다.';
    if (!_insideBoard(hole) || !_insidePoint(scenario.level.ballSpawn)) {
      return '공이나 홀이 보드 밖에 있습니다.';
    }
    final ballDistance = scenario.level.ballSpawn.distanceTo(hole.position);
    if (ballDistance <= hole.hitRadius + 12) {
      return '공과 홀이 너무 가깝습니다.';
    }
    for (final entity in entities) {
      if (!_insideBoard(entity)) return '${entity.id}가 보드 밖에 있습니다.';
      if (entity.id == hole.id || !entity.solid) continue;
      if (_overlaps(hole.hitBounds, entity.hitBounds)) {
        return '홀이 다른 기물과 겹칩니다.';
      }
    }
    return null;
  }

  PhysicsLabScenario build(PhysicsLabDraft draft) {
    final base = physicsLabScenarios.firstWhere(
      (item) => item.id == draft.baseScenarioId,
      orElse: () => throw const FormatException('알 수 없는 실험 템플릿입니다.'),
    );
    final entities = [
      for (final entity in base.level.entities)
        entity.type == EntityType.hole
            ? entity.copyWith(position: draft.goalPosition.position)
            : entity,
    ];
    return PhysicsLabScenario(
      id: 'custom_${base.id}_${draft.goalPosition.name}_v1',
      title: '나만의 ${base.title}',
      question: '${base.title} 규칙으로 ${draft.goalPosition.label} 목표에 도전해 보세요.',
      linkedStageIndex: base.linkedStageIndex,
      level: LevelDefinition(
        id: 'custom_${base.level.id}_${draft.goalPosition.name}_v1',
        stageId: base.level.stageId,
        name: '실험실 · 나만의 ${base.title}',
        ballSpawn: base.level.ballSpawn,
        entities: entities,
        parShots: base.level.parShots,
      ),
    );
  }

  bool _insidePoint(Vec2 point) =>
      point.x >= 12 && point.x <= 348 && point.y >= 12 && point.y <= 548;

  bool _insideBoard(EntityState entity) {
    final bounds = entity.bounds;
    return bounds.left >= 4 &&
        bounds.top >= 4 &&
        bounds.right <= 356 &&
        bounds.bottom <= 556;
  }

  bool _overlaps(Bounds a, Bounds b) =>
      a.left < b.right &&
      a.right > b.left &&
      a.top < b.bottom &&
      a.bottom > b.top;
}

class PhysicsLabShareCode {
  PhysicsLabShareCode._();

  static String encode(PhysicsLabDraft draft) {
    final error = const PhysicsLabDraftValidator().validate(draft);
    if (error != null) throw FormatException(error);
    final payload = utf8.encode(jsonEncode(draft.toJson()));
    final tag = sha256.convert(payload).bytes.sublist(0, 8);
    return '$physicsLabSharePrefix${base64Url.encode([...payload, ...tag])}';
  }

  static PhysicsLabDraft decode(String raw) {
    final value = raw.trim();
    if (value.length > physicsLabShareMaxCharacters) {
      throw const FormatException('실험 코드가 너무 깁니다.');
    }
    if (!value.startsWith(physicsLabSharePrefix)) {
      throw const FormatException('실험 코드 머리말이 올바르지 않습니다.');
    }
    try {
      final bytes = base64Url.decode(
        value.substring(physicsLabSharePrefix.length),
      );
      if (bytes.length <= 8) throw const FormatException('실험 코드가 비어 있습니다.');
      final payload = bytes.sublist(0, bytes.length - 8);
      final supplied = bytes.sublist(bytes.length - 8);
      final expected = sha256.convert(payload).bytes.sublist(0, 8);
      var mismatch = supplied.length ^ expected.length;
      for (
        var index = 0;
        index < supplied.length && index < expected.length;
        index++
      ) {
        mismatch |= supplied[index] ^ expected[index];
      }
      if (mismatch != 0) throw const FormatException('실험 코드가 손상되었습니다.');
      final decoded = jsonDecode(utf8.decode(payload));
      if (decoded is! Map<String, Object?>) {
        throw const FormatException('실험 코드 형식이 올바르지 않습니다.');
      }
      final draft = PhysicsLabDraft.fromJson(decoded);
      final error = const PhysicsLabDraftValidator().validate(draft);
      if (error != null) throw FormatException(error);
      return draft;
    } on FormatException {
      rethrow;
    } on Object {
      throw const FormatException('실험 코드를 읽을 수 없습니다.');
    }
  }
}
