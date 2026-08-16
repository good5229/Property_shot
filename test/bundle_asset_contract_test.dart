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
        'assets/generated/island-observatory-v2.png',
        'assets/generated/island-lighthouse-v2.png',
        'assets/generated/island-bridge-v2.png',
        'assets/generated/jelly-bumper-v1.png',
        'assets/generated/nav-physics-lab-v1.png',
        'assets/generated/nav-expedition-v1.png',
        'assets/generated/nav-reward-satchel-v1.png',
        'assets/generated/nav-helm-v1.png',
        'assets/generated/nav-stage-map-v1.png',
        'assets/generated/nav-replay-v1.png',
        'assets/generated/nav-daily-challenge-v1.png',
        'assets/generated/nav-activities-v1.png',
        'assets/generated/hint-key-v1.png',
        'assets/generated/hint-lantern-v1.png',
        'assets/generated/stone-v2.png',
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
