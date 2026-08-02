import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/domain/entity_state.dart';
import 'package:property_shot/game/domain/trait.dart';
import 'package:property_shot/game/levels/levels.dart';
import 'package:property_shot/game/simulation/trait_resolver.dart';

void main() {
  const traits = TraitResolver();

  test('뾰족함은 한글 이름·설명과 형태 식별 문자를 갖는다', () {
    expect(TraitType.sharp.label, '뾰족함');
    expect(TraitType.sharp.symbol, '뾰');
    expect(TraitType.sharp.description, contains('풍선'));
  });

  test('뾰족함을 옮기면 공급 물체가 비워지고 공에 장착된다', () {
    final state = levels[3].createState(3);
    final selected = traits.selectSource(state, 'spike_source');
    final moved = traits.transferSelectedTrait(selected);

    expect(moved.activeBall.traits, {TraitType.sharp});
    expect(moved.entityById('spike_source')!.traits, isEmpty);
    expect(moved.equippedTrait, TraitType.sharp);
  });

  test('복사는 공급 물체를 유지한다', () {
    final state = levels[3]
        .createState(3, productRules: true, copyCoreCount: 1)
        .copyWith(copyCharges: 1);
    final selected = traits.selectSource(state, 'spike_source');
    final copied = traits.copySelectedTrait(selected);

    expect(copied.activeBall.traits, {TraitType.sharp});
    expect(copied.entityById('spike_source')!.traits, {TraitType.sharp});
    expect(copied.copyCoreCount, 0);
  });

  test('뾰족함 공급 물체는 이동 물체가 아니다', () {
    expect(
      levels[3].entities.firstWhere((entity) => entity.type == EntityType.spikeSource).movable,
      isFalse,
    );
  });
}
