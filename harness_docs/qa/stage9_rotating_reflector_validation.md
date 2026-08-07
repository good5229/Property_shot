# PS-STAGE-06A/B: 9단계 회전 반사판 검증

## 범위

- 단계 ID: `stage_rotating_reflector`
- 제목: `9. 판을 돌려 놓아라`
- 패턴: `stage_rotating_reflector_01`~`04`
- 기준 패턴: 1번의 `metadata.baseline=true`
- 모든 패턴 `parShots`: 2
- 모든 패턴 `acceptedStrategyIds`: 대표 반사판 풀이와 `none`
- 모든 패턴 `solutionFamilies`: 반사판 풀이와 직접 우회 풀이를 함께 선언

이번 작업은 `assets/stages/chapter_1.json`에 9단계만 추가하고 생성 카탈로그를 갱신했다. 기존 1~8단계 JSON과 공통 물리 코드는 수정하지 않았다. 반사판의 충돌·회전 판정은 기존 `ShotResolver`를 그대로 사용하며, 이 작업은 실제 입력으로 그 계약을 고정한다.

## 학습 가족과 대표 입력

각도는 논리 좌표계 기준 정수 도, 힘은 실제 UI와 같은 2% 눈금이다. 모든 대표 힘은 12% 이상이다.

| 패턴 | 대표 준비 → 성공 | 반사판 사건 | 직접 우회 |
| --- | --- | --- | --- |
| 01 | `296도/12% → 222도/48%` | `active_ball:reflector_a → active_ball:reflector_a` | `270도/26%` |
| 02 | `228도/12% → 54도/72%` | 첫 샷 A, 둘째 샷 B | `62도/64%` |
| 03 | `347도/56% → 293도/84%` | 둘째 샷 `spent_ball_1:reflector_a` | `300도/38%` |
| 04 | `312도/12% → 72도/54%` | 첫 샷 슬라이더 뒤 `reflector_a` | `224도/36%` |

대표 경로의 공통 성공 조건은 홀 진입이다. 특정 반사판, 슬라이더, 과거 공을 성공 필수 조건으로 선언하지 않았고, 각 패턴의 직접 입력은 반사판 회전 없이 `GamePhase.success`에 도달한다.

## 해법 허용 영역

직접 우회는 2도·2% 전수 격자 8,100개, 반사판 경로는 대표 입력 주변 1도·2% 4차원 격자로 다시 실행했다. 3번의 과거 공 경로도 한 점이 아니라 `346도`와 `347도`의 연속 첫 조준 각도에서 성공한다.

| 패턴 | 직접 성공/최대 연결 | 반사판 성공/최대 연결 | 성공 첫째/둘째 입력 |
| --- | --- | --- | --- |
| 01 | 750/477 | 378/253 | 21/29 |
| 02 | 70/48 | 435/435 | 29/15 |
| 03 | 484/213 | 18/9 | 2/18 |
| 04 | 309/180 | 201/89 | 23/11 |

수치는 `tool/generate_stage9_solution_regions.dart`가 생성한 `harness_docs/qa/replays/stage9_solution_regions.json`에 고정하며 `--check`로 동기화를 검사한다.

## 사건·물리 계약

- 회전판 충돌 이벤트가 먼저 기록되고, 해당 이벤트를 `parentEventId`로 가리키는 `reflectorRotation` 이벤트가 뒤따른다.
- 회전 전 속도는 충돌 법선에 대해 입사 방향을 유지하고, 반사 후 속도는 충돌 직전 방향을 반사한 값이다.
- 회전 후 방향은 `orientationAfter = (orientationBefore + 2) % 8`로 저장한다. 8방향이 45도 간격이므로 이는 정확한 90도 회전이다.
- 같은 접촉을 중복 회전으로 세지 않으며, 다음 충돌부터 변경된 방향을 사용한다.
- 4번 패턴은 `powerSliderActivation`이 먼저 기록되고 그 뒤 `reflectorRotation`이 기록된다.
- 반사판은 `active=true`, `solid=true`, `movable=false`다.
- 모든 벽은 `solid=true`, `movable=false`이며 두 발 이후 위치가 초기 위치와 같다.
- 동적 Validator는 실제 `ShotResolverPatternRuntimeProbe` evidence로 회전 순서, 결정론, 벽 불변, 유한값과 안전 중단 부재를 검사한다.
- 첫 샷 입력을 `RunStateStore`에 저장하고 새 `StagePatternSession`으로 재개해도 추첨 패턴, 반사판 방향·회전 수, 둘째 샷 결과 지문이 연속 실행과 같다.

## 화면 계약

- 섬 지도는 `1 / 9` 진행과 9단계 카드, 회전 반사판 아이콘, 한글 설명, 잠금 상태를 표시한다.
- 9단계 화면은 현재 면으로 먼저 반사하고 충돌 뒤 90도 회전한다는 규칙을 긴 화면과 압축 화면에 맞춰 한글로 안내한다.
- 반사판을 누르면 정보 팝업에 현재 가로·세로·대각선 방향과 누적 회전 수를 표시한다.
- 390×844, 393×852, 430×932, 768×1024, 1024×1366 플레이 화면 Golden 5장과 390×844·768×1024 지도 하단 Golden 2장을 직접 확인했다.

## 변경 파일

- `assets/stages/chapter_1.json`: 9단계 원본 데이터와 네 패턴
- `lib/game/levels/generated_stage_catalog.dart`: 생성 도구 산출 스냅샷
- `test/fixtures/stage9_rotating_reflector_patterns.dart`: 대표·직접 입력 fixture
- `test/stage9_rotating_reflector_patterns_test.dart`: 구조, 정적·동적 Validator, 런타임 사건, 회귀 fingerprint
- `test/stage9_solution_region_test.dart`: 직접·반사판 경로의 연결 영역과 입력 허용 폭
- `tool/generate_stage9_solution_regions.dart`: 9단계 해법 영역 생성·동기화 검사
- `tool/stage9_solution_search.dart`: 실제 `ShotResolver` 기반 대표 입력 탐색기
- `test/stage_catalog_test.dart`: 단계 수 9와 9단계 난이도 band 기대값
- `README.md`: 아홉 단계와 9단계 학습 내용 반영

## 실행한 검증

- 외부 SDK `/Users/bellhundred/flutter_3_44_0/bin/flutter` 사용 제한을 승인 경로로 해제해 모든 Flutter 명령을 실행했다.
- 9단계 전용 구조·물리·저장·해법 영역 테스트 16개 통과.
- 공용 단일 리플레이 36개와 다중 리플레이 45개를 재생성하고 재생 비교 통과. 7단계 이후 다중샷 탐색은 실제 UI 범위인 12% 이상 힘만 사용한다.
- `flutter test`: 전체 704개 통과.
- `flutter analyze`: 문제 없음.
- `flutter build web --release`: 성공.
- 카탈로그·9단계 해법 영역 생성기 `--check`, JSON 구문 검사, `git diff --check`: 통과.
- 독립 Luna 최초 감사의 P2 두 건을 보완했다. 해법 영역 테스트는 실제 엔진 계산 결과와 JSON 전체를 비교하고, 저장 재개는 네 패턴 모두를 검증한다. 재감사 결과 미해결 P0·P1·P2 없음.

## 잔여 위험

- 9단계의 실제 사용자 난이도와 반사판 순서 발견성은 수동 플레이 검증이 필요하다.
- 실제 모바일 기기의 손가락 조준 오차와 반사판 순서 발견률은 사용자 플레이테스트가 필요하다.
- 3번 과거 공 반사판 경로는 연속 두 첫 조준 각도를 허용하지만 다른 패턴보다 좁다. 직접 우회는 213셀 연결 영역으로 넓고 기믹을 강제하지 않는다.
