# 결정론 물리 이벤트 스트림 검증

기준일: 2026-08-03 KST

## 변경 범위

`ShotImpact`와 `ShotAnimationMove`를 `PhysicsEvent` 스트림으로 합성하고, 판정 중 적용된 상태 변경은 `PhysicsStateTransition`으로 직접 기록한다. 이벤트는 결정론 `eventId`, `parentEventId`, 경로 시점, 출발·대상 ID, 대상 타입, 접촉 위치·법선, 충격량, 관찰된 후속 속도를 가진다. 상태 변경 이벤트는 풍선 팝·속성 소모·스위치 노출·스위치 작동·문 개방·홀 포획의 이전·이후 상태를 보존한다.

`chain_safety_stop`은 `ChainSafetyDiagnostic`으로 구조화되어 대상 ID, 경로 시점, 깊이, 반복 수, 잔여 거리, 잔여 속도를 기록한다. 이 진단은 정상 충돌 이벤트와 같은 스트림에서 별도 종류로 재생되고, 정상 클리어로 숨겨지지 않는다.

## 검증 결과

| 검증 | 결과 | 증거 |
|---|---|---|
| 결정론 이벤트 ID | 통과 | 동일 상태·입력의 이벤트 ID 목록 비교 |
| 충돌·이동 부모 관계 | 통과 | 부모 이벤트가 자식 이벤트보다 먼저 생성됨 |
| 충돌·이동 일대일 재생 | 통과 | `animation_timeline_test.dart` 구조화 스트림 회귀 |
| 30/60/120Hz 중복 방지 | 통과 | 기존 타임라인 회귀와 새 공유 스트림 회귀 |
| 관찰된 후속 속도 | 통과 | 충돌 이벤트의 다음 경로 벡터 기록 |
| 판정 중 상태 변경 직접 기록 | 통과 | `PhysicsStateTransition`과 `PhysicsEventKind.stateChange` |
| 스테이지4 종단간 인과 | 통과 | `puzzle_solution_audit_test.dart`의 충돌·팝·노출·작동·개방·홀 순서 |
| 기존 충돌·연쇄 회귀 | 통과 | `flutter test --reporter compact`, 174개 |
| 정적 분석 | 통과 | `flutter analyze` |
| Web release | 통과 | `flutter build web --release` |

## 남은 한계

- `resultingVelocity`는 현재 물리 내부 속도 객체가 아니라 충돌 후 경로에서 관찰한 벡터다. 실제 post-solve 속도 객체 연결은 후속 물리 고도화 대상으로 남긴다.
- 연쇄 안전 종료가 발생하는 고의 스트레스 스테이지와 실기기 프레임 지연 검증은 별도 QA가 필요하다.
- 실제 iOS·Android 장치의 햅틱·오디오·GPU 성능은 검증하지 않았다.
