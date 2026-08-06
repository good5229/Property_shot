# PS-OBJ-01 파워 슬라이더 QA 검증 기록

기준일: 2026-08-06 KST

## 범위

파워 슬라이더의 데이터 경계, 정적 정책, 활성 공·연쇄 물체 물리, 접촉 원장, 이벤트 재생, runtime probe, 자체 Canvas 시각 표현을 검증한다. 기존 1~4단계 JSON과 생성 카탈로그, PS-STAGE-02 패턴 제작은 범위에 포함하지 않는다.

## 계약 검증

| 항목 | 증거 | 결과 |
|---|---|---|
| `direction` 물리 분리 | 시각 direction과 별도 motionDirection/velocityBefore/velocityAfter, 실제 resultingVelocity 회귀 | 통과 |
| 안정 `allowedTargets` | JSON 배열을 `ball, crate, weight` 순서로 왕복하고 불변 Set으로 변환 | 통과 |
| 비적용 대상 거부 | 빈 집합·wall 대상·정적/고체/비활성 슬라이더 안정 오류 코드 | 통과 |
| `max(현재, 기준)` | 현재 속력이 더 빠를 때 불변, 단순 가산 금지, 복수 기준 속력 최댓값 | 통과 |
| 기준 속력 안전 상한 | `48.0` 허용·`48.01` 거부, 실제 crate 연쇄의 기준 속력 48 경계에서 안전 종료·유한성·벽/보드 경계·결정론 | 통과 |
| 동일 접촉 1회 | 접촉 ID별 동일 path 시점 중복 금지 | 통과 |
| 완전 이탈 후 재진입 | 벽 반사로 영역을 완전히 빠져나온 뒤 정확히 두 번째 작동, 무한 반복 없음 | 통과 |
| 앞·뒤 슬라이더 | 한 attempted segment의 뒤쪽 후보를 선점하지 않고 도달 순서대로 1회씩 작동 | 통과 |
| 홀·점착 우선 | 홀 포획 또는 점착 정지 선분에서 슬라이더가 작동하지 않음 | 통과 |
| 연쇄 물체 적용 | `other_ball`, crate, weight 재귀 이동 중 실제 motion velocity와 별도 activation 기록 | 통과 |
| 직후 연속 충돌 | 슬라이더 뒤 벽·얇은 벽 반사, 홀 포획·뒤 벽 미발생 | 통과 |
| 이벤트 분리 | 슬라이더는 `ShotImpact`가 아니라 `PowerSliderActivation` 이벤트로 기록 | 통과 |
| runtime probe | 파워 슬라이더 존재 시 `sliderApplicable=true`, 실제 영역 통과·무활성일 때만 tunneling. 강제 무활성 resolver 양성 fixture 포함 | 통과 |
| validator 독립 경계 | direction/referenceSpeed 비유한·0·상한, 대상·상태·보드 밖·고체 겹침을 각각 독립 fixture로 검증 | 통과 |
| 결정론·스트레스 | activation/event ID·순서·최종 상태, 다수 slider/mover 유한성·safety stop 부재 | 통과 |

## 실행 증거

```text
flutter test test/power_slider_physics_test.dart --reporter compact
29 tests passed

flutter test --update-goldens test/power_slider_golden_test.dart --reporter compact
12 tests passed

flutter test --reporter compact
455 tests passed

flutter analyze
No issues found!

dart run tool/generate_stage_catalog.dart --check
스테이지 카탈로그 생성본이 최신입니다.

flutter build web --release
Web Release 빌드 성공
```

Golden은 다음 상태를 `390x844`, `768x1024` 각각 생성하고 시각 확인했다.

- 기본 정적 상태
- 작동 이벤트 도달 상태
- 파워 슬라이더 정보 팝업
- 저모션 작동 상태
- 수평·수직 시각 방향 상태

PS-OBJ-01 구현은 코드·검증 기록·Golden만 추가하며 기존 1~4단계 JSON과 생성 카탈로그는 변경하지 않았다. Sol 독립 검증과 시각 검토를 통과한 뒤 본 작업 단위만 별도 commit·push한다.

## 잔여 위험

- 실제 모바일 GPU에서 Canvas 발판의 가장자리·텍스트 가독성과 저모션 명도 대비는 실기기 확인이 필요하다.
- resolver의 기존 속력 모델은 경로 간격 기반 관찰값을 사용하므로 향후 속도 객체를 도입하면 이벤트의 `resultingVelocity` 계약을 함께 재검토해야 한다.
- 복수 슬라이더가 동일 epsilon 안에 들어오는 극단 배치는 모두 같은 post-speed를 기록하지만, 별도 레벨 난이도 설계는 PS-STAGE-02에서 검토한다.
