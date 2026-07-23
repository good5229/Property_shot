enum TraitType { heavy, bouncy, sticky }

extension TraitTypeLabel on TraitType {
  String get label {
    switch (this) {
      case TraitType.heavy:
        return '무거움';
      case TraitType.bouncy:
        return '탄성';
      case TraitType.sticky:
        return '점착';
    }
  }

  String get symbol {
    switch (this) {
      case TraitType.heavy:
        return '무';
      case TraitType.bouncy:
        return '탄';
      case TraitType.sticky:
        return '점';
    }
  }

  String get description {
    switch (this) {
      case TraitType.heavy:
        return '가벼운 상자를 밀고 무게 스위치를 누를 수 있습니다.';
      case TraitType.bouncy:
        return '벽에 부딪히면 첫 충돌 뒤 방향을 바꿔 튕깁니다.';
      case TraitType.sticky:
        return '처음 닿은 유효 표면에 붙어 다음 전략의 발판이 됩니다.';
    }
  }
}
