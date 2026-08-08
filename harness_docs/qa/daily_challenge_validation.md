# PS-DAILY-01A 오늘의 도전 기반 검증

## 범위

오늘의 도전의 날짜, 시드, 정식 시도, 연습 모드, 완료 복구와 로컬 기록 기반만
구현한다. 홈 화면, 게임 화면, 지도 해금, 리더보드, 리플레이와 공유는 다음
작업 범위다.

## 결정론 정의

- 날짜는 입력 시각을 UTC로 바꾼 뒤 고정 `UTC+09:00`을 더해 계산한다.
- 날짜 키는 `YYYY-MM-DD`, 사용자 표시 날짜는 `YYYY년 M월 D일`이다.
- 도전 정의 버전은 `dailyChallengeVersion = daily-challenge-v1`이다.
- 물리 판정 버전은 `dailyChallengePhysicsResolverVersion = shot-resolver-v1`이다.
- 루트 시드는 도전 버전, 물리 버전, KST 날짜 키를 안정 해시로 함께 섞은
  unsigned 32비트 값이다.
- 같은 날짜와 버전은 열 단계의 패턴 순서, 패턴 시드와 보상 후보가 모두 같다.
- 정식 재도전은 다른 `attemptId`와 `runId`를 쓰되 루트 시드는 유지한다.

## 저장 격리

- 일반 런, 날짜별 정식 시도, 날짜별 연습은 서로 다른 namespace를 쓴다.
- 정식 RunState는 시도별 namespace와 A/B 슬롯, checksum, revision으로 저장한다.
- 완료된 정식 시도는 같은 `runId`로 다시 시작할 수 없으며, 일일 도전 저장소는
  외부에 쓰기 가능한 RunStateStore 대신 읽기 전용 최신 스냅숏만 노출한다.
- `StagePatternSession`도 내부 RunStateStore를 공개하지 않아 완료 상태를 직접
  덮어쓰는 우회 경로가 없다.
- 연습 모드는 공개 생성 API에서 `MemoryRunStateBackend`만 사용해 앱 종료 뒤
  복원되지 않는다.
- 공식 기록 schema v2는 날짜, 도전 버전, 물리 버전 fingerprint별 A/B 슬롯과
  active pointer에 저장한다.
- 공식 기록은 시도 수, 최고 총점, 최소 발사 합계, 활성 시도, 완료 시도와
  RunState revision, 단조 증가 UTC 시각을 보존한다.
- 같은 실제 backend를 감싼 여러 저장소 인스턴스도 공유 직렬화 큐를 사용한다.
- 기본 제공 메모리·SharedPreferences·namespace backend는 동기화 identity를
  제공한다. 같은 실제 저장소를 감싸는 사용자 정의 backend도 이 계약을 구현해야
  여러 adapter 인스턴스가 같은 큐를 공유한다.
- v1 기록은 출시 전 내부 초안이며 제품 데이터가 아니므로 v2로 이전하지 않고
  초기화한다.

## 정식 시도와 완료 복구

- 같은 `attemptId`의 중복 시작은 한 번만 센다.
- 활성 시도가 있으면 다른 시도 시작을 거부한다. 사용자가 명시적으로 포기한
  뒤에만 새 정식 시도를 시작할 수 있다.
- 완료 기록은 호출자가 전달한 점수로 만들지 않는다.
  `reconcileCompletedRun`이 최신 RunState를 직접 읽고 다음을 모두 검증한다.
  - phase가 `runCompleted`인지
  - 활성 시도의 `runId`와 같은지
  - 날짜에서 파생한 루트 시드와 같은지
  - 물리 판정 버전과 같은지
  - 검증된 최신 revision이 존재하는지
- 총점과 발사 합계는 검증한 RunState에서 산출한다.
- RunState 완료 저장 뒤 공식 기록 저장 전에 앱이 종료돼도 같은 대조 작업을
  다시 실행해 멱등 복구한다.
- 완료 스냅숏을 읽은 뒤에는 동일 시도의 RunState가 더 갱신될 수 없어 기록한
  revision과 실제 완료 revision이 어긋나지 않는다.

## 검증 결과

- 집중 회귀 68개 통과
  - `daily_challenge_test.dart` 22개
  - `run_state_store_test.dart` 14개
  - `stage_pattern_session_test.dart` 32개
- KST 자정 경계, 날짜·버전별 seed, 열 단계 전체 패턴·보상 재현을 검사했다.
- 일반·정식·연습 key 비침범과 시도별 재도전 분리를 검사했다.
- 정식 시작·포기·중복 호출·다중 인스턴스 경합을 검사했다.
- 실제 완료 RunState 대조, 미완료·다른 시도 거부, 완료 재요청 멱등성을 검사했다.
- 공식 기록의 checksum·최신 슬롯 손상 복구, 읽기·쓰기 오류 전파, 시계 역행,
  버전 분리와 불변 조건을 검사했다.
