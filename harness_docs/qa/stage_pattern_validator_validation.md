# 스테이지 패턴 검증기 실행 안전망 검증

작업 ID: `PS-VALID-03`, `PS-VALID-04`
검증 기준: 2026-08-09 KST

## 적용 범위

- `ShotResolverPatternRuntimeProbe`가 이름·풀이 계열·복수 샷·무보상 여부를 가진 대표 시나리오를 제한 실행한다.
- `dart run tool/generate_stage_catalog.dart --check --validate-runtime`이 생산 카탈로그 10단계×4패턴을 모두 검사한다.
- 기존 단계별 대표 fixture를 개발 전용 manifest에서 재사용한다. 게임 UI나 정답 추천에는 노출하지 않는다.
- 선언된 `solutionFamilies`와 일치하는 실제 성공 증거가 없거나 런 보상 없는 성공 증거가 없으면 각각 안정 오류 코드로 실패한다.
- `RuntimeValidationRulePolicy`로 홀 통과 규칙을 실제 비활성화한 변이가 fixture 계약에서 검출되는지 확인한다.
- `validateHintCatalog`가 40개 생산 패턴과 HintCatalog entry를 일대일로 대조한다. `stageId + patternId + hintVersion`, 실제 대상 기물, 정확히 L1·L2인 레벨 순서, 금지된 숫자 정답과 추상 문구를 검사한다.
- 선택 열쇠는 보드·홀 포획 반경·고체 기물과의 중첩을 정적으로 검사하고, 실제 `ShotResult` 경로 기반 수집 가능성·두 번 실행 지문·공 이외 이동체 무시를 실행 검사한다.
- `demoPreferred` 패턴은 홀 중심 방향의 힘 격자를 실제 resolver로 실행해 의도 기믹 없는 직선 클리어가 없음을 검사한다.

## 증거 수준

| 구분 | fixture | 증거 |
|---|---|---|
| 실제 배치와 실제 resolver | `invalid_auto_clear`, `invalid_no_route` | 깨진 배치를 실제 `ShotResolver` probe가 실행해 자동 클리어와 완전 차단을 관찰 |
| 실제 resolver 기반 결함 변이 | `invalid_wall_moves`, `invalid_infinite_bounce`, `invalid_slider_tunneling`, `invalid_non_deterministic`, `invalid_hole_pass_through`, `invalid_rotator_order`, `invalid_soft_lock` | 정상 resolver 결과 또는 생산 발사 가능성 계약에 한 종류의 결함만 주입하고 실제 probe 판정기가 이를 검출 |
| 정적 fixture | `invalid_overlap`, `invalid_reward_required`, `invalid_duplicate_object_id` | 구조·메타데이터 규칙으로 결정적으로 검출 |
| 힌트 fixture | `invalid_hint_missing`, `invalid_hint_wrong_pattern`, `invalid_hint_too_vague`, `invalid_hint_exact_solution`, `duplicate_level`, `noncontiguous_level`, `unexpected_l3` | 40패턴 누락·대상 불일치·추상 문구·숫자 정답·L1/L2 위반을 안정 코드로 검출 |
| 열쇠·시연 fixture | `invalid_key_unreachable`, `invalid_key_overlap`, `invalid_key_blocks_hole`, `invalid_demo_direct_clear` | 비물리 열쇠 배치와 시연 직선 우회를 정적·실제 resolver 증거로 검출 |
| 저장 복원 fixture | `invalid_hint_entitlement_restore` | 현행 v3에서 허용하지 않는 L3 권한을 거부하고, v2 L3는 L2로 명시 이관 |

`invalid_slider_tunneling`은 실제 슬라이더를 통과한 결과에서 작동 payload와 사건만 제거하고, `invalid_rotator_order`는 실제 반사판 충돌 결과에서 회전 payload와 사건만 제거한다. `invalid_soft_lock`은 생산 `ShotResolver.canLaunch` 계약을 거부하는 단일 변이를 사용한다. 대표 입력 무이동만으로는 소프트락을 만들지 않는다.

## 생산 카탈로그 계약

- manifest 키는 생산 패턴 ID 40개와 정확히 일치해야 한다.
- 각 패턴은 기존 대표 fixture를 실제 물리로 두 번 재생한다.
- 두 실행의 전체 상태·경로·충돌·기물 이동·물리 사건 지문이 같아야 한다.
- 벽 이동, 홀 통과, 안전중단, 비유한 수치, 음수 사건 순서, 슬라이더 터널링, 회전 순서 위반이 없어야 한다.
- 선언된 풀이 계열과 일치하는 성공 시나리오가 하나 이상이어야 한다.
- 런 보상을 주입하지 않은 성공 시나리오가 하나 이상이어야 한다.
- fixture 하나를 제거하거나 성공 시나리오를 보상 전용으로 바꾸는 음성 테스트가 게이트 실패를 확인한다.
- 10단계 A/C는 정규 기믹 해법과 문 개방 뒤 뱅크 샷 해법을 별도 시나리오로 재생하며, 선언한 모든 풀이 계열의 성공 증거가 모였는지 집중 회귀 테스트가 확인한다.
- HintCatalog은 생산 패턴 40개 각각에 정확히 하나의 entry와 L1·L2를 제공해야 한다. 생성본은 `dart run tool/generate_hint_catalog.dart --check`와 일치해야 한다.

범용 정답 탐색기는 추가하지 않았다. 대표 fixture는 QA 회귀 증거이며 특정 기믹만을 유일한 성공 조건으로 만들지 않는다.

## 실행 결과

| 명령 | 결과 |
|---|---|
| `flutter analyze` | 통과, 문제 0건 |
| validator·meta·runtime probe·catalog 집중 테스트 | 66개 통과 |
| `dart run tool/generate_stage_catalog.dart --check --validate-runtime` | 생산 패턴 40개 통과, 생성본 최신 |
| 카탈로그 runtime timing bound | 15초 미만 계약 통과 |
| `git diff --check` | 통과 |

### 2026-08-25 시작 공 주변 벽 여유 회귀 방지

- 신규 안정 오류 코드 `ball_spawn_too_close_to_wall`을 추가했다.
- 생산 40패턴의 시작 공과 내부 벽·닫힌 문 사이 여유는 모두 24 이상이며 최솟값은 `stage_drained_01`의 약 24.12이다.
- `stage_drained_01` 차단벽은 결정론적 후보 탐색으로 대표 무거움 해법, 무속성 대체 해법, 기존 근방 성공 영역을 함께 보존하는 `(82, 425.5)`로 이동했다. 900입력 격자에서 기믹 경로는 우회보다 1.61배 넓고 홀 중심 무충돌 직행은 0개다.
- `stage_speed_01` 차단벽은 `(97, 437)`로 이동해 약 24.75의 여유를 확보했다.
- `stage_chain_score_01` 차단벽은 `(103, 462)`로 이동해 약 24.48의 여유를 확보했다.
- 생산 40패턴 제한 실행, 단일·다중샷 리플레이 재생, 반응형 골든을 포함한 전체 테스트 1,468개가 통과했다.

PS-VALID-04 영향권에서는 validator·runtime probe 31개와 슬라이더·회전판·실제 UI 입력 139개, `flutter analyze`가 통과했다. 당시 도구 사용량 제한으로 미뤄졌던 생산 40패턴 CLI는 2026-08-09 현재 HEAD에서 다시 실행해 40개 제한 실행과 생성본 일치를 모두 확인했다.

## 불변 조건 확인

- `ShotResolver`의 결정론·홀 판정·리플레이 입력 계약은 유지했다. 최신 레벨 보강에서는 패턴 전용 switch·slider·sticky link가 문을 여는 명시 사건과 기믹 우위용 배치를 추가했으며, 생성 카탈로그·대표 fixture·리플레이 지문을 함께 갱신했다.
- 정상 10단계×4패턴의 runtime 오탐은 0건이다.
- 벽 불변·홀 우선·복수 해법·무보상 기본 성공 조건을 유지한다.
- 기존 오류 코드 이름은 바꾸지 않았고, 신규 실행 증거 누락 코드만 추가했다.
- UI 발사·조준·충전 입구가 같은 생산 발사 가능성 판정을 사용한다.
- 열쇠는 `GameState` 물리 엔티티가 아니며, Validator와 수집 resolver를 추가해도 ShotResolver 공식·점수·홀 판정은 변하지 않는다.

## 남은 한계

- timing bound는 로컬 자동 테스트 상한이며 실기기 성능 증거가 아니다.
