import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/ui/game_feedback.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('충돌 재질에 따라 플랫폼 사운드 강도가 구분된다', () {
    final cues = <SystemSoundType>[];
    final feedback = GameFeedback(soundPlayer: (type) async => cues.add(type));

    feedback.collision(EntityType.wall);
    feedback.collision(EntityType.bumper);

    expect(cues, [SystemSoundType.alert, SystemSoundType.click]);
  });
}
