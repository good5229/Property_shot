# 스테이지4 인과관계 검증

기준일: 2026-08-03 KST

## 목표

풍선 팝이 문을 직접 여는 것으로 끝나지 않고, 실제 충돌 순서에 따라 풍선 뒤 스위치가 드러나고 스위치 충돌 뒤 연결된 문이 열리는지 검증한다. 뾰족함을 사용하지 않는 우회 성공은 계속 허용한다.

## 결정론 판정 계약

### 뾰족한 공 경로

1. `balloon_popped`
2. `sharpness_consumed`
3. `balloon_switch_revealed`
4. `balloon_switch_pressed`
5. `balloon_gate`가 `open: true`, `solid: false`
6. 홀 진입 또는 이후의 허용된 물리 경로로 성공

풍선 팝만 발생한 샷에서는 문을 열지 않는다. 스위치는 팝 전 `solid: false`, `visualState: hidden`이고 팝 후 `solid: true`, `visualState: revealed`가 된다.

### 일반 공·우회 경로

- 일반 공은 풍선에서 반사되고 풍선을 비활성화하지 않는다.
- 풍선과 스위치를 거치지 않는 성공 입력도 최소 하나 이상 존재해야 한다.
- 특정 속성이나 기믹을 성공의 유일한 조건으로 만들지 않는다.

## 자동 검증

| 검증 | 증거 | 결과 |
|---|---|---|
| 일반 공 풍선 반사 | `test/balloon_physics_test.dart` | 통과 |
| 고파워 충돌 충격 증가 | `test/balloon_physics_test.dart` | 통과 |
| 팝 후 스위치 노출, 문 직접 개방 금지 | `test/balloon_physics_test.dart` | 통과 |
| 팝→스위치→문 이벤트 순서 | `test/puzzle_solution_audit_test.dart` | 통과 |
| 뾰족함 없는 우회 성공 | `test/puzzle_solution_audit_test.dart` | 통과 |
| 기본 플레이 화면 20개(4단계×5해상도) | `test/game_screen_golden_test.dart` | 통과 |
| 시작·팝·스위치/문·홀·결과 25개(5상태×5해상도) | `test/stage4_causality_golden_test.dart` | 통과 |

## 화면 상태 기준

- 시작: 풍선, 문, 홀, 박스가 식별되고 스위치는 표시하지 않는다.
- 팝 직후: 풍선 팝 이펙트와 드러난 스위치가 보이고, 안내는 스위치 충돌을 다음 행동으로 제시한다.
- 스위치 충돌: 스위치가 점멸·눌림 상태가 되고 문 열림 애니메이션이 시작된다.
- 홀 진입: 홀 표면·테두리·어두운 내부·깃발이 겹치지 않고 공 포획 애니메이션이 우선한다.

## 남은 검증

- 5개 상태·5개 해상도 Golden fixture 25개는 추가·통과했다. 상태별 실제 기기 캡처만 남아 있다.
- 실제 iOS·Android 장치에서 접근성 트리와 reduced motion 상태를 확인한다.
- 긴 연쇄와 고속 진입에서 `chain_safety_stop`이 정상 성공으로 은닉되지 않는지 스트레스 테스트한다.
