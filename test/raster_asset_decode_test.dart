import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('플레이 래스터 자산은 테스트 호스트에서도 첫 프레임을 디코드한다', () async {
    for (final asset in const [
      'assets/generated/stone-v2.png',
      'assets/generated/crate-v2.png',
      'assets/generated/jelly-bumper-v1.png',
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
      codec.dispose();
      frame.image.dispose();
    }
  });
}
