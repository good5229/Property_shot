# 물리 결정론 검증 보고서

작성 기준: 2026-08-03 KST
기준 브랜치: `commercial/wall-physics-qa`
관련 커밋: `0b516ba`

## 검증 목적

동일한 `GameState`와 `ShotInput`이 주어졌을 때 물리 판정이 반복 실행마다 달라지지 않는지 확인한다. 화면 애니메이션의 중간 프레임은 판정 근거로 사용하지 않고, 순수 Dart `ShotResolver`가 반환한 상태·충돌·연쇄 이벤트를 비교한다.

## 현재 자동 증거

### 최신 실행 기준

최신 전체 회귀 기준은 252개 통과다. 아래 표의 244개·231개는 당시 문서 시점의 역사적 수치로 보존하며 최신 종합 판정에는 사용하지 않는다. Android ARM64 에뮬레이터에서 동일한 기능 흐름을 재생했지만, Web·iOS·Android 실기기 간 이벤트 지문 동등성은 아직 검증하지 않았다.

| 항목 | 결과 |
|---|---|
| 대표 입력 방향·힘 조합 | 8방향과 여러 힘 구간을 4개 단계에 적용 |
| 동일 입력 반복 | 각 입력 100회 반복 |
| 비교 대상 | 상태 서명, 충돌 대상·순서, 연쇄 이동, 물리 이벤트 |
| 속성별 반복 | 대표 속성 입력을 단계별로 비교 |
| 벽 불변성 | 모든 벽의 좌표·속도·이동 가능 여부 확인 |
| 대상 충돌 행렬 | 벽·상자·돌·젤리·점착판·이전 공·풍선 확인 |
| 다중 발사 | 기존 공을 유지한 후 새 공과 재충돌 확인 |
| 저장 다중 발사 재생 | 4개 단계 × 5개, 총 20개 시퀀스 재생 |
| 실행 결과 | 결정론 3개, 충돌 행렬 1개, 다중샷 분석 1개, 저장 다중샷 재생 1개, 전체 회귀 252개 통과 |

단계별 대표 재생 입력은 `harness_docs/qa/replays/single_shot_fixtures.json`에 저장했다. 1~4단계 각각 성공 2개·실패 2개씩 총 16개이며, 입력 각도·힘·속성, 예상 종료 단계, 물리 결과 지문을 포함한다. `test/replay_fixture_test.dart`는 JSON을 다시 읽어 동일 입력을 `ShotResolver`에 넣고 안정적 지문과 종료 단계를 비교한다.

다중샷 대표 재생 입력은 `harness_docs/qa/replays/multi_shot_fixtures.json`에 저장했다. 각 시퀀스는 최대 2발로 구성되며, 첫 발의 결과 상태를 다음 발의 시작 상태로 전달한다. 네 단계 모두 최소 1개의 2발 시퀀스를 포함하고, 직접·복사·대체 경로 태그와 발별 물리 지문을 함께 보존한다. `test/multi_replay_fixture_test.dart`가 20개 시퀀스와 단계별 2발 조건을 재생 비교한다.

재현 명령:

```bash
flutter test --reporter compact test/replay_determinism_test.dart
flutter test --reporter compact test/physics_collision_matrix_test.dart
flutter test --reporter compact test/multi_shot_analysis_test.dart
flutter test --reporter compact test/replay_fixture_test.dart
flutter test --reporter compact test/multi_replay_fixture_test.dart
dart run tool/physics_benchmark.dart
```

## 고정된 물리 규칙

- 벽은 모든 연쇄 충돌에서 고정이다.
- 충돌 대상의 타입·질량·재질·충돌 법선을 후속 계산에 전달한다.
- 이전 공은 필드의 물리 객체로 남는다.
- 홀 충돌은 뒤 벽 충돌보다 우선하며, 포획 후 후속 이동을 만들지 않는다.
- 일반 공과 풍선의 충돌은 풍선을 유지하고 공을 반사한다.
- 뾰족한 공과 풍선의 충돌은 풍선을 비활성화하고 뾰족함을 소모한다.
- 점착판과 점착 속성은 정지 이벤트를 만든다.
- 연쇄 충돌은 선행 충돌이 끝난 뒤 후속 물체에 대해 다시 계산한다.

## 아직 확보하지 못한 증거

- Web·iOS Release·Android에서 동일 이벤트 서명을 비교한 결과
- 실제 30·60·120Hz 기기에서 이벤트와 렌더링 순서를 함께 측정한 결과
- 고속 접선·모서리·동일 위치 공 겹침에 대한 실기기 영상 증거
- 10개 공·10개 이동 물체·30개 충돌 스트레스의 실제 프레임 결과

따라서 현재 보고서는 자동 물리 회귀 통과를 증명하지만, 크로스플랫폼 최종 통과를 의미하지 않는다.
