# 홀·깃발 레이어 명세

## 렌더 순서

`바닥 장식 → 홀 외곽 림 → 어두운 내부 → 포획 중 공 일부 → 깃발 기둥 하단 → 공·기둥 Y-sort → 깃발 천 → 클리어 VFX → HUD`

홀은 원형 판정과 시각 레이어를 분리한다. 포획이 논리적으로 먼저 확정되면 뒤 벽과 충돌하지 않으며, 깃발은 목표를 표시하지만 콜라이더가 아니다.

## 검증

- 시작·접근·포획·클리어를 `stage4_*` Golden으로 5개 해상도에 고정한다.
- 홀 크기·위치를 바꾸어도 물리 판정 테스트의 결과가 변하지 않는지 확인한다.
- 공의 포획 중 축소·투명도는 공 형태가 완전히 사라지기 전에 일부를 남긴다.

구현 근거: `lib/game/property_shot_game.dart`, `test/stage4_causality_golden_test.dart`, [stage4_causality_validation.md](../qa/stage4_causality_validation.md).
