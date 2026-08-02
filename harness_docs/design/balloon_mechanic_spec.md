# 풍선 기믹 명세

풍선 상태는 `intact → pushed 또는 punctureQualified → popped → inactive`다. 일반 공·무거움·탄성·점착은 풍선을 밀거나 반사할 수 있으나 터뜨리지 않는다. `TraitType.sharp`를 가진 공 또는 이전 공이 유효 충돌하면 풍선을 비활성화하고 `balloon_popped`, `sharpness_consumed`를 순서대로 기록한다. 링크된 문은 `opening` 이동 이벤트 후 열린다.
