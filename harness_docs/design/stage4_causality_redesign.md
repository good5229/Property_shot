# 스테이지4 인과관계 재설계

## 후보 비교

| 후보 | 장점 | 위험 | 판정 |
|---|---|---|---|
| A 잠금 풍선 | 풍선과 문을 직접 연결 | 새 규칙과 전용 표현 필요 | 보류 |
| B 풍선 뒤 스위치 | 기존 스위치·문 규칙 재사용, 실제 충돌 순서가 보임 | 스위치 배치가 좁으면 어려움 | 채택 |
| C 고정 로프 | 팝과 문 해제가 직접 보임 | 로프 판정·연출 복잡도 증가 | 보류 |
| D 공기압 장치 | 세계관 설명 가능 | 설명 비용과 규칙 증가 | 보류 |

## 채택 계약

`일반 공 반사 → 뾰족한 공 팝 → 스위치 노출 → 스위치 충돌 → 문 열림 → 홀` 순서를 사용한다. 풍선 팝만으로 문을 열지 않는다. 풍선·스위치 경로를 거치지 않는 우회 성공은 남긴다.

근거: [stage4_causality_validation.md](../qa/stage4_causality_validation.md), [balloon_mechanic_spec.md](balloon_mechanic_spec.md), `test/puzzle_solution_audit_test.dart`, `test/stage4_causality_golden_test.dart`.
