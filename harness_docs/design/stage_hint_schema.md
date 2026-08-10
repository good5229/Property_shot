# 스테이지·힌트·열쇠 데이터 스키마

상태: 구현 계약, 2026-08-10 KST. 원본 데이터는 `assets/stages/chapter_1.json`과 `assets/stages/hints_v1.json`, 생성 결과는 `lib/game/levels/generated_stage_catalog.dart`와 `lib/game/hint/generated_hint_catalog.dart`다. 생성본을 직접 편집하지 않는다.

## 스테이지 패턴

각 생산 패턴은 `stageId`, `patternId`, 결정론 seed에서 파생되는 배치, 엔티티 목록, 허용 풀이 계열과 난이도 메타데이터를 가진다. 생산 카탈로그는 10단계×4패턴 40개이며 `tool/generate_stage_catalog.dart --check --validate-runtime`가 원본·생성본 동기화와 실제 `ShotResolver` 대표 경로를 검사한다.

시연 대상으로 지정한 패턴은 `demoPreferred=true`와 직선 클리어 금지 정책을 함께 가져야 한다. 직선 금지는 정적 시선만이 아니라 홀 중심 방향의 힘 격자를 실제 resolver로 두 번 실행해 판정한다.

## HintCatalog v1

최상위 `version`과 `entries`를 사용한다. 각 entry는 다음 식별·검증 필드를 가진다.

- `stageId`, `patternId`, `hintVersion`: 저장 권한과 화면 데이터가 공유하는 복합 키.
- `mechanicId`, `targetObjectIds`: 해당 패턴에 실제 존재하는 기믹과 목표 기물.
- `intent`: 행동과 기대 결과를 구조적으로 설명하는 검증용 의도.
- `levels`: 정확히 L1·L2 두 항목. L1은 목표와 첫 행동, L2는 조준 위치·세기·순서·결과를 구체화한다.
- `key`: 선택 필드. `id`, 논리 좌표 `position`, 수집 반경/버전을 가진 비물리 배치.

Validator는 누락 패턴, 잘못된 패턴/대상 참조, 중복·비연속 레벨, L3, 빈 문장, 숫자 각도·퍼센트 정답 노출, 추상 행동만 있는 문장을 안정 오류 코드로 거부한다.

## 비물리 열쇠

열쇠는 `GameState` 엔티티가 아니며 질량·충돌·반사·점수·홀 진입에 영향을 주지 않는다. `DeterministicKeyCollectionResolver`가 확정된 `ShotResult.path`와 공 타입 이동만 훑는다. 현재 공과 과거 공의 모든 접촉 후보를 `(pathIndex, segmentIndex, t, sourceBallId)`로 전역 정렬한 뒤 열쇠별 첫 직접 접촉만 채택한다. 상자·돌 등 공이 아닌 이동체의 경로는 수집으로 인정하지 않는다.

정적 검사는 보드 밖, 홀 포획 반경, 고체 히트박스 중첩을 거부한다. 실행 검사는 대표 입력 주변에서 합리적인 수집 폭, 두 번 실행 지문 일치, 중복 이벤트 멱등성을 확인한다.

## RunState v3

`RunHintEntitlement`의 정체성은 `stageId + patternId + hintVersion`이다. 권한 출처는 `clear_reward`, `stage_key`를 병합할 수 있고, 수집 열쇠 ID, 열린 최고 레벨(0–2), 열람 횟수, 실패 누계, 최초 열람 시 실패 기준값을 저장한다.

- v1/v2 저장본은 v3로 명시 마이그레이션한다.
- 과거 L3는 L2로 낮춘다.
- `consumed`와 `openedCount`, 최초 열람 기준과 실패 누계의 모순은 복원을 거부한다.
- 다음 스테이지 팁 보상은 `completeCurrentStage`가 선추첨·저장한 다음 패턴 정체성에 원자적으로 결속한다.
- 열쇠 수집, 실패 누계, 단계 완료는 한 저장 작업 큐에서 호출 순서를 보존한다.
- 일일 도전은 Hint UI를 연결하지 않으므로 팁 보상 후보도 만들지 않는다.

## 변경 절차

1. JSON 원본을 수정한다.
2. 생성기를 실행하고 `--check`로 드리프트 0을 확인한다.
3. Validator meta fixture와 실제 resolver runtime fixture를 통과시킨다.
4. 저장 스키마가 바뀌면 이전 모든 버전 fixture와 canonical round-trip을 추가한다.
5. 화면 문구·시연 경로가 바뀌면 HintCatalog, Golden, 녹화 manifest와 보고서를 같은 변경에서 갱신한다.
