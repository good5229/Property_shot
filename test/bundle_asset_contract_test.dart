import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('제품 번들은 실행 자산만 포함하고 원본과 보관 자산은 제외한다', () async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final bundledAssets = manifest.listAssets().toSet();

    expect(
      bundledAssets,
      containsAll(const {
        'assets/generated/crate-v2.png',
        'assets/generated/island-restoration-world-v1.webp',
        'assets/generated/island-observatory-v1.png',
        'assets/generated/island-lighthouse-v1.png',
        'assets/generated/island-bridge-v1.png',
        'assets/generated/jelly-bumper-v1.png',
        'assets/generated/nav-physics-lab-v1.png',
        'assets/generated/nav-expedition-v1.png',
        'assets/generated/nav-reward-satchel-v1.png',
        'assets/generated/stone-v2.png',
        'assets/audio/property_shot_island_loop.wav',
        'assets/stages/chapter_1.json',
      }),
    );
    expect(
      bundledAssets.intersection(const {
        'assets/generated/jelly-bumper-v1-source.png',
        'assets/icons/property_shot_app_icon_source.png',
        'assets/icons/ball.png',
        'assets/icons/crate.png',
        'assets/icons/stone_boulder.png',
        'assets/icons/README.md',
      }),
      isEmpty,
    );
  });
}
