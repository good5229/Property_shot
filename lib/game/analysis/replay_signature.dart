import '../domain/geometry.dart';
import '../simulation/shot_resolver.dart';

String shotResultSignature(ShotResult result) {
  final state = result.state;
  final buffer = StringBuffer()
    ..write('phase=${state.phase.name};')
    ..write('shots=${state.shotCount};score=${state.score};')
    ..write('events=${result.events.join(',')};');

  final entities = [...state.entities]
    ..sort((left, right) => left.id.compareTo(right.id));
  for (final entity in entities) {
    buffer
      ..write('entity=${entity.id}:${entity.type.name};')
      ..write('p=${_vector(entity.position)};')
      ..write('size=${_vector(entity.size)};')
      ..write(
        'traits=${entity.traits.map((trait) => trait.name).toList()..sort()};',
      )
      ..write(
        'active=${entity.active};open=${entity.open};pressed=${entity.pressed};',
      )
      ..write('visual=${entity.visualState};');
  }
  for (final impact in result.impacts) {
    buffer
      ..write('impact=${impact.sourceEntityId}>${impact.entityId};')
      ..write('type=${impact.entityType.name};path=${impact.pathIndex};')
      ..write(
        'position=${_vector(impact.position)};normal=${_vector(impact.normal)};',
      )
      ..write('impulse=${_number(impact.impulse)};');
  }
  for (final event in result.physicsEvents) {
    buffer
      ..write('physics=${event.eventId}:${event.kind.name};')
      ..write('parent=${event.parentEventId};path=${event.pathIndex};')
      ..write(
        'target=${event.targetEntityId};position=${_vector(event.position)};',
      )
      ..write('velocity=${_vector(event.resultingVelocity)};');
  }
  for (final move in result.moves) {
    buffer
      ..write(
        'move=${move.entityId}:${move.visualState};path=${move.triggerPathIndex};',
      )
      ..write('from=${_vector(move.from)};to=${_vector(move.to)};')
      ..write('points=${move.path.map(_vector).join(',')};');
  }
  return buffer.toString();
}

String shotResultFingerprint(ShotResult result) {
  const offset = '14695981039346656037';
  final mask = (BigInt.one << 64) - BigInt.one;
  var hash = BigInt.parse(offset);
  for (final codeUnit in shotResultSignature(result).codeUnits) {
    hash = ((hash ^ BigInt.from(codeUnit)) * BigInt.from(1099511628211)) & mask;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}

String _vector(Vec2 vector) => '${_number(vector.x)},${_number(vector.y)}';

String _number(double value) => value.toStringAsFixed(6);
