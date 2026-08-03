# 스테이지4 검증 요약

상세 계약은 [stage4_causality_validation.md](stage4_causality_validation.md)에 둔다.

| 상태 | 자동 근거 | 결과 |
|---|---|---|
| 시작 | 기본 플레이 Golden 5해상도 | 통과 |
| 풍선 팝 직후 | `balloon_popped`, `balloon_switch_revealed` | 통과 |
| 스위치·문 | `balloon_switch_pressed`, 연결 문 open | 통과 |
| 홀 포획 | 포획 우선·뒤 벽 차단 회귀 | 통과 |
| 결과 | 결과 팝업 Golden 5해상도 | 통과 |

뾰족함 없는 우회 성공과 복제 코어 없는 성공을 별도 자동 탐색으로 확인했다.
