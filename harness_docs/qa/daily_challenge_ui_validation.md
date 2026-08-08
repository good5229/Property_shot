# PS-DAILY-01B 오늘의 도전 UI 통합 검증

## 범위

- 홈의 한글 `오늘의 도전` 진입과 날짜별 개요를 검증한다.
- KST 날짜, 시드 코드, 정식 시도 수, 완료, 최고 총점, 최소 발사 합계를 표시한다.
- `정식 도전`과 `연습`을 분리한다. 정식은 `attempt_N`과 날짜별 RunState를 사용하고,
  연습은 `MemoryRunStateBackend`만 사용한다.
- 일반 `ProgressStore`의 로드·쓰기·개발 저장 동작은 `GameProgressPersistencePolicy.disabled`
  로 차단한다.
- 생성 카탈로그의 다음 10개 ID와 순서를 제품 UI 계약으로 고정한다.
  `stage_heavy`, `stage_bouncy`, `stage_chain_gate`, `stage_balloon`,
  `stage_drained`, `stage_speed`, `stage_persistent`, `stage_chain_score`,
  `stage_rotating_reflector`, `stage_property_shot`
- 라우터의 상태 전이는 단일 비동기 작업열로 직렬화한다.
- 앱 재시작과 앱 복귀 시 KST 날짜를 다시 계산한다. 날짜가 바뀌면 전날 화면을
  이어하지 않고 새 날짜 개요로 돌아간다.

## 완료 복구 계약

- `playing`: 현재 단계의 저장된 샷과 속성 행동을 결정론적으로 재생한다.
- `stageCompleted`: 보상 후보를 다시 준비하고 클리어 화면으로 복원한다.
- `rewardSelectionPending`: 동일한 세 후보를 다시 표시한다.
- `rewardSelectionCompleted`: 선택한 보상을 유지하고 다음 단계 이동을 허용한다.
- `runCompleted`: 공식 시도는 `reconcileCompletedRun` 성공 뒤에만 결과 화면을 표시한다.
- 마지막 보상 선택과 `completeRun` 저장 사이에서 앱이 종료되어도 재시작 시 같은
  완료 RunState와 공식 기록을 복구한다.

## 실행한 검증

- `test/daily_challenge_widget_test.dart`: 위젯 회귀 11개 통과
  - 홈 진입, 정식 중복 탭 방지, 연습 비기록·일반 진행 비오염
  - 활성 시도 이어하기, 완료된 이전 시도보다 활성 재시도 우선
  - KST 자정 전환, 열 단계 완료·공식 기록 복구
  - 연습 결과 문구·재연습 동작, ProgressStore 저장 감시
  - 카탈로그 재배열·단일 단계 완료 거부, 320×700·390×844 큰 글자 overflow
- `test/daily_challenge_golden_test.dart`: 320×700, 390×844, 768×1024 및
  390×844 큰 글자(1.35배) Golden 4개 생성·대조 통과
- `test/daily_challenge_test.dart`, `test/run_state_store_test.dart`,
  `test/stage_pattern_session_test.dart`: PS-DAILY-01A 집중 회귀와 함께 실행
- 위 파일 묶음 합계 83개 테스트 통과

`flutter analyze`는 이슈 0건으로 통과했다. 전체 회귀는 첫 실행에서 홈 진입
버튼 추가로 기존 홈 Golden 2개가 기준 이미지와 달라 실패했으며, 해당 2개를
현재 화면 기준으로 갱신했다. 이후 최종 전체 회귀 817개가 모두 통과했다.

Golden 4개를 사람이 직접 확인했다. 첫 산출물에서 테스트 전용 한글 글꼴과
Material Icons가 로드되지 않아 글자와 아이콘이 네모로 표시되는 문제를 발견해
수정하고 기준 이미지를 다시 생성했다. 768×1024에서는 콘텐츠 최대 폭을 560으로
제한해 태블릿의 과도한 가로 확장을 줄였다. 실제 기기·웹 브라우저 검증은 최종
통합 게이트에서 별도로 수행한다.
