enum TraitType { heavy, bouncy, sticky, sharp }

extension TraitTypeLabel on TraitType {
  String get label {
    switch (this) {
      case TraitType.heavy:
        return '무거움';
      case TraitType.bouncy:
        return '탄성';
      case TraitType.sticky:
        return '점착';
      case TraitType.sharp:
        return '뾰족함';
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
      case TraitType.sharp:
        return '뾰';
    }
  }

  String get description {
    switch (this) {
      case TraitType.heavy:
        return '가벼운 상자를 밀고 무게 스위치를 누를 수 있습니다.';
      case TraitType.bouncy:
        return '벽에 부딪힐 때마다 탄성을 유지하며 방향을 바꿔 강하게 튕깁니다.';
      case TraitType.sticky:
        return '처음 닿은 유효 표면에 붙어 다음 전략의 발판이 됩니다.';
      case TraitType.sharp:
        return '풍선만 찌를 수 있으며, 한 번 사용하면 사라집니다.';
    }
  }

  /// 플레이 중 작은 영역에서도 발동 조건과 소모 여부를 바로 알 수 있는 요약.
  String get compactEffect {
    switch (this) {
      case TraitType.heavy:
        return '상자 밀기 · 무게 스위치';
      case TraitType.bouncy:
        return '벽에 닿을 때마다 탄성 반사';
      case TraitType.sticky:
        return '첫 유효 표면에 고정';
      case TraitType.sharp:
        return '풍선 1회 파열 후 소모';
    }
  }
}
