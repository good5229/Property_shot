# 스테이지 패턴 검증기 실행 안전망 검증

작업 ID: `PS-VALID-03`  
검증 기준: 2026-08-08 KST

## 적용 범위

- `ShotResolverPatternRuntimeProbe`가 이름·풀이 계열·복수 샷·무보상 여부를 가진 대표 시나리오를 제한 실행한다.
- `dart run tool/generate_stage_catalog.dart --check --validate-runtime`이 생산 카탈로그 10단계×4패턴을 모두 검사한다.
- 기존 단계별 대표 fixture를 개발 전용 manifest에서 재사용한다. 게임 UI나 정답 추천에는 노출하지 않는다.
- 선언된 `solutionFamilies`와 일치하는 실제 성공 증거가 없거나 런 보상 없는 성공 증거가 없으면 각각 안정 오류 코드로 실패한다.
- `RuntimeValidationRulePolicy`로 홀 통과 규칙을 실제 비활성화한 변이가 fixture 계약에서 검출되는지 확인한다.

## 증거 수준

| 구분 | fixture | 증거 |
|---|---|---|
| 실제 배치와 실제 resolver | `invalid_auto_clear`, `invalid_no_route` | 깨진 배치를 실제 `ShotResolver` probe가 실행해 자동 클리어와 완전 차단을 관찰 |
| 실제 resolver 기반 결함 변이 | `invalid_wall_moves`, `invalid_infinite_bounce`, `invalid_non_deterministic`, `invalid_hole_pass_through` | 정상 resolver 결과에 한 종류의 결함만 주입하고 실제 probe 판정기가 이를 검출 |
| 정적 fixture | `invalid_overlap`, `invalid_reward_required`, `invalid_duplicate_object_id` | 구조·메타데이터 규칙으로 결정적으로 검출 |
| scripted evidence 유지 | `invalid_slider_tunneling`, `invalid_rotator_order`, `invalid_soft_lock` | 안정 오류 코드 매핑 계약만 검증 |

`invalid_soft_lock`은 현재 `GameState`와 `ShotResult`에 발사 가능 여부를 나타내는 생산 필드가 없어 실제 probe가 `launchUnavailable=true`를 만들 수 없다. 파워 슬라이더와 회전 반사판의 실제 판정기는 별도 runtime probe 테스트에서 고장 resolver 결과를 검출하지만, 이름 있는 invalid fixture는 이번 작업 범위에서 scripted 상태를 유지한다.

## 생산 카탈로그 계약

- manifest 키는 생산 패턴 ID 40개와 정확히 일치해야 한다.
- 각 패턴은 기존 대표 fixture를 실제 물리로 두 번 재생한다.
- 두 실행의 전체 상태·경로·충돌·기물 이동·물리 사건 지문이 같아야 한다.
- 벽 이동, 홀 통과, 안전중단, 비유한 수치, 음수 사건 순서, 슬라이더 터널링, 회전 순서 위반이 없어야 한다.
- 선언된 풀이 계열과 일치하는 성공 시나리오가 하나 이상이어야 한다.
- 런 보상을 주입하지 않은 성공 시나리오가 하나 이상이어야 한다.
- fixture 하나를 제거하거나 성공 시나리오를 보상 전용으로 바꾸는 음성 테스트가 게이트 실패를 확인한다.

범용 정답 탐색기는 추가하지 않았다. 대표 fixture는 QA 회귀 증거이며 특정 기믹만을 유일한 성공 조건으로 만들지 않는다.

## 실행 결과

| 명령 | 결과 |
|---|---|
| `flutter analyze` | 통과, 문제 0건 |
| validator·meta·runtime probe·catalog 집중 테스트 | 66개 통과 |
| `dart run tool/generate_stage_catalog.dart --check --validate-runtime` | 생산 패턴 40개 통과, 생성본 최신 |
| 카탈로그 runtime timing bound | 15초 미만 계약 통과 |
| `git diff --check` | 통과 |

## 불변 조건 확인

- `ShotResolver` 물리 공식과 스테이지 배치를 변경하지 않았다.
- 정상 10단계×4패턴의 runtime 오탐은 0건이다.
- 벽 불변·홀 우선·복수 해법·무보상 기본 성공 조건을 유지한다.
- 기존 오류 코드 이름은 바꾸지 않았고, 신규 실행 증거 누락 코드만 추가했다.
- 사용자 대상 UI 변경은 없다.

## 남은 한계

- 실제 발사 불가 상태 모델이 생기기 전까지 soft lock은 scripted evidence 계약이다.
- 이름 있는 슬라이더 터널링·회전 순서 invalid fixture의 완전한 실제 배치 전환은 후속 validator 작업 대상이다.
- timing bound는 로컬 자동 테스트 상한이며 실기기 성능 증거가 아니다.
