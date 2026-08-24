import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('플레이 래스터 자산은 테스트 호스트에서도 첫 프레임을 디코드한다', () async {
    for (final asset in const [
      'assets/generated/stone-v3.png',
      'assets/generated/crate-v3.png',
      'assets/generated/mystery-crate-v1.png',
      'assets/generated/jelly-bumper-v2.png',
      'assets/generated/ball-base-v1.png',
      'assets/generated/ball-heavy-v1.png',
      'assets/generated/ball-bouncy-v1.png',
      'assets/generated/ball-sticky-v1.png',
      'assets/generated/ball-sharp-v1.png',
      'assets/generated/hole-flag-v1.png',
      'assets/generated/wall-segment-v1.png',
      'assets/generated/sticky-pad-v1.png',
      'assets/generated/spike-source-v1.png',
      'assets/generated/power-slider-v1.png',
      'assets/generated/rotating-reflector-v1.png',
      'assets/generated/gate-closed-v1.png',
      'assets/generated/switch-pad-v1.png',
      'assets/generated/balloon-v1.png',
      'assets/generated/island-observatory-v2.png',
      'assets/generated/island-lighthouse-v2.png',
      'assets/generated/island-bridge-v2.png',
      'assets/generated/nav-physics-lab-v1.png',
      'assets/generated/nav-expedition-v1.png',
      'assets/generated/nav-reward-satchel-v1.png',
      'assets/generated/nav-helm-v1.png',
      'assets/generated/nav-stage-map-v1.png',
      'assets/generated/nav-replay-v1.png',
      'assets/generated/nav-daily-challenge-v1.png',
      'assets/generated/nav-activities-v1.png',
      'assets/generated/hint-key-v1.png',
      'assets/generated/hint-lantern-v2.png',
      'assets/generated/stage-icon-heavy-v1.png',
      'assets/generated/stage-icon-bouncy-v1.png',
      'assets/generated/stage-icon-chain-gate-v1.png',
      'assets/generated/stage-icon-sharp-balloon-v1.png',
      'assets/generated/stage-icon-property-transfer-v1.png',
      'assets/generated/stage-icon-speed-slider-v1.png',
      'assets/generated/stage-icon-persistent-ball-v1.png',
      'assets/generated/stage-icon-chain-score-v1.png',
      'assets/generated/stage-icon-rotating-reflector-v1.png',
      'assets/generated/stage-icon-finale-v1.png',
    ]) {
      final bytes = await rootBundle.load(asset);
      final codec = await ui
          .instantiateImageCodec(bytes.buffer.asUint8List())
          .timeout(const Duration(seconds: 3));
      final frame = await codec.getNextFrame().timeout(
        const Duration(seconds: 3),
      );

      expect(frame.image.width, greaterThan(0), reason: asset);
      expect(frame.image.height, greaterThan(0), reason: asset);
      expect(
        frame.image.width > frame.image.height
            ? frame.image.width
            : frame.image.height,
        greaterThanOrEqualTo(600),
        reason: '$asset: 네 화면 등급에서 확대해도 주축 해상도를 유지해야 합니다.',
      );
      expect(
        frame.image.width < frame.image.height
            ? frame.image.width
            : frame.image.height,
        greaterThanOrEqualTo(240),
        reason: '$asset: 좁은 축도 실제 UI 크기에서 윤곽이 뭉개지지 않아야 합니다.',
      );
      codec.dispose();
      frame.image.dispose();
    }
  });
}
