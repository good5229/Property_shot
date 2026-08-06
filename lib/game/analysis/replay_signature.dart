import '../domain/geometry.dart';
import '../domain/entity_state.dart';
import '../domain/trait.dart';
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
      ..write(
        'movable=${entity.movable};solid=${entity.solid};'
        'movable_when_drained=${entity.movableWhenDrained};',
      )
      ..write('visual=${entity.visualState};');
    if (entity.type == EntityType.rotatingReflector) {
      buffer
        ..write('reflector_orientation=${entity.reflectorOrientation};')
        ..write('reflector_rotation_count=${entity.reflectorRotationCount};');
    }
  }
  for (final impact in result.impacts) {
    buffer
      ..write('impact=${impact.sourceEntityId}>${impact.entityId};')
      ..write('type=${impact.entityType.name};path=${impact.pathIndex};')
      ..write(
        'position=${_vector(impact.position)};normal=${_vector(impact.normal)};',
      )
      ..write('contact=${impact.contactId};')
      ..write(
        'triggers_reflector_rotation=${impact.triggersReflectorRotation};',
      )
      ..write('source_traits=${_traits(impact.sourceTraits)};')
      ..write('impulse=${_number(impact.impulse)};');
  }
  for (final event in result.physicsEvents) {
    buffer
      ..write('physics=${event.eventId}:${event.kind.name};')
      ..write('parent=${event.parentEventId};path=${event.pathIndex};')
      ..write(
        'target=${event.targetEntityId};position=${_vector(event.position)};',
      )
      ..write('source=${event.sourceEntityId};')
      ..write('contact=${event.contactId};')
      ..write('triggers_reflector_rotation=${event.triggersReflectorRotation};')
      ..write('source_traits=${_traits(event.sourceTraits)};')
      ..write('velocity=${_vector(event.resultingVelocity)};');
    final rotation = event.reflectorRotation;
    if (rotation != null) {
      buffer
        ..write('reflector_source=${rotation.sourceEntityId};')
        ..write('reflector_target=${rotation.reflectorEntityId};')
        ..write('reflector_contact=${rotation.contactId};')
        ..write('reflector_path=${rotation.pathIndex};')
        ..write('reflector_before=${rotation.orientationBefore};')
        ..write('reflector_after=${rotation.orientationAfter};')
        ..write('reflector_count_before=${rotation.rotationCountBefore};')
        ..write('reflector_count_after=${rotation.rotationCountAfter};')
        ..write(
          'reflector_velocity_before=${_vector(rotation.velocityBefore)};',
        )
        ..write(
          'reflector_collision_normal=${_vector(rotation.collisionNormal)};',
        )
        ..write('reflector_velocity_after=${_vector(rotation.velocityAfter)};');
    }
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

String _traits(Iterable<TraitType> traits) {
  final names = traits.map((trait) => trait.name).toList()..sort();
  return names.join(',');
}
