# 창의 연쇄 점수 검증

기준일: 2026-08-07 KST  
작업 ID: `PS-SCORE-01`  
범위: 점수 도메인·물리 사건 분석·리플레이 결정론·집중 테스트·QA 문서

## 목표와 불변 조건

창의 연쇄 점수는 기본 클리어 조건의 선택적 고득점 요소다. 공이 홀에 들어가는지, 충돌·연쇄 물리 결과가 어떻게 결정되는지, `ShotResolver`가 반환하는 `GameState`가 어떻게 바뀌는지는 이 작업에서 변경하지 않는다.

분석기는 기존 `PhysicsEvent`, `ShotImpact`, `ShotResult`, `ReplayFixture`를 읽기 전용으로 소비한다. 화면 UI, 8단계, 결과 팝업, 점수 저장은 이 작업의 범위에 포함하지 않는다.

점수는 단순 충돌 횟수 합이 아니다.

1. 최종 홀 진입 사건을 찾는다.
2. `parentEventId`를 따라 부모 사건을 복원한다.
3. 부모 정보가 없는 연속 이동 사건은 출발 기물과 경로 시점을 기준으로 결정론적인 이전 사건을 선택한다.
4. 해당 인과 사슬의 기물·상태·이동만 고득점 근거로 인정한다.
5. 사슬 밖 충돌은 무관 충돌 제한을 거친 뒤 작은 보정만 적용한다.

## 공개 API

구현 파일: `lib/game/analysis/creative_chain_score.dart`

### `CreativeChainScoreAnalyzer`

```dart
const analyzer = CreativeChainScoreAnalyzer();

final analysis = analyzer.analyze(
  shotResults,
  parShots: 3,
  optionalChallengeIds: {
    CreativeChainChallengeId.wallReflection,
    CreativeChainChallengeId.pastBall,
  },
);
```

주요 인자와 기본 제한은 다음과 같다.

| 인자 | 기본값 | 의미 |
|---|---:|---|
| `parShots` | 필수 | 최소 샷 보너스의 기준 발사 수 |
| `maxCausalImpacts` | 12 | 최종 인과 사슬에서 점수화할 충돌 상한; 제품 절대 상한 12를 넘길 수 없음 |
| `maxUnrelatedImpacts` | 3 | 홀과 무관한 충돌의 점수화 상한; 제품 절대 상한 3을 넘길 수 없음 |
| `repeatWindowPathIndices` | 12 | 같은 접촉의 단시간 반복 판정 범위 |
| `microVibrationSpeed` | 0.35 | 미세 진동으로 제외할 상대 법선 속력 기준 |
| `microVibrationImpulse` | 0.1 | 미세 진동으로 제외할 충격량 기준 |

`analyzeReplay`는 기존 `ReplayFixture`와 이미 재생한 `ShotResult` 목록을 받는다.

```dart
final analysis = analyzer.analyzeReplay(
  fixture,
  replayResults,
  parShots: 3,
);
```

발사 수가 fixture와 다르면 입력 오류로 처리한다. `expectedFingerprints`가 비어 있지 않으면 각 결과의 `shotResultFingerprint`를 같은 순서로 비교하고, 불일치 시 `replayMatchesFixture == false`를 반환한다. 물리 재생 자체는 호출자가 기존 resolver와 리플레이 흐름으로 수행한다.

### 결과 모델

`CreativeChainScoreAnalysis`는 다음을 함께 보존한다.

- `clearReached`, `holeShotIndex`: 홀 진입 및 최종 홀 샷
- `causalEventIds`: 샷 번호가 붙은 인과 사건 식별자
- `preparationContributions`: 준비 샷별 기물·상태 근거와 점수
- `completedOptionalChallengeIds`: 실제 사건에서 확인된 선택 도전
- `breakdown`: 모든 개수·감쇠·상한·점수 구성요소
- `evidence`: 한글 설명, 사건 ID, 기물 ID가 포함된 점수 근거
- `replayMatchesFixture`, `replaySignature`: 리플레이 검증 결과와 결정론 서명

`CreativeChainScoreBreakdown.totalPoints`가 합산 점수이며, 클리어 전 결과는 항상 0점이다.
`evidence`는 기본점부터 제한된 무관 충돌 보정까지 Breakdown과 같은 집계 단위로 기록하므로 모든 근거의 점수 합이 `totalPoints`와 정확히 일치한다.

## 점수 공식

클리어한 경우에만 다음 구성요소를 합산한다.

```text
총점 = 클리어 기본점
     + 인과 깊이
     + 기물 타입 다양성
     + 개별 기물 다양성
     + 벽 반사
     + 과거 공
     + 속성 발동
     + 속성 소모
     + 파워 슬라이더
     + 스위치·문·회전판 상태 변화
     + 한 샷 이동 기물
     + 준비 샷 기여
     + 최소 샷 보너스
     + 선택 도전
     + 제한된 무관 충돌 보정
```

| 구성요소 | 계산 |
|---|---|
| 클리어 기본점 | `1000` |
| 인과 깊이 | `min(유효 깊이, 8) × 45`; 미세 진동·상한 초과·빠른 반복 충돌은 깊이에서 제외 |
| 타입 다양성 | `min(타입 수, 2) × 35 + min(max(타입 수 - 2, 0), 6) × 25` |
| 개별 기물 | `min(개별 ID 수, 8) × 22` |
| 벽 반사 | 유효 벽 사건마다 `30 × 감쇠 계수`, 소수점 반올림 |
| 과거 공 | `min(서로 다른 과거 공 수, 3) × 55` |
| 속성 발동 | `min(발동 수, 3) × 45` |
| 속성 소모 | `min(소모 수, 3) × 65` |
| 파워 슬라이더 | `min(서로 다른 작동 슬라이더 수, 3) × 50` |
| 상태 변화 | `min(서로 다른 스위치·문·회전판 대상 수, 5) × 35` |
| 한 샷 이동 | 인과 사슬에 포함된 이동 기물 `min(수, 5) × 30` |
| 준비 샷 | 샷별 근거 점수 합산 후 최대 `150` |
| 최소 샷 | `max(parShots - 사용 샷 수, 0) × 35` |
| 선택 도전 | 검증된 도전마다 `40` |
| 무관 충돌 | `min(무관 유효 충돌 수, 3) × 4` |

인과 사슬의 타입·개별 ID는 충돌 사건뿐 아니라 사슬에 포함된 파워 슬라이더와 스위치·문·회전판 상태 사건도 포함한다. 홀 자체는 다양성 대상에서 제외한다.

기본 클리어 여부는 `GameState.phase == success`와 홀 사건이 함께 존재할 때만 참이다. 홀 모양과 접촉했더라도 게임 상태가 클리어로 확정되지 않았다면 점수를 주지 않는다.

## 요구사항별 산출 근거

| 요구사항 | 결과 모델 |
|---|---|
| 홀 진입 인과 사슬 깊이 | `causalDepth`, `causalEventIds`, `causalDepthPoints` |
| 서로 다른 기물 타입 | `distinctEntityTypes`, `distinctEntityTypePoints` |
| 서로 다른 개별 기물 | `distinctEntityIds`, `distinctEntityPoints` |
| 벽 반사 | 벽 대상·접촉 법면별 `wallReflectionCount`, `wallReflectionPoints` |
| 과거 공 | `pastBallCount`, 과거 공 사건의 `entityId` |
| 속성 발동·소모 | 충돌 주체의 무거움·탄성·점착·뾰족함 비트 마스크와 `stuck`·`popped` 상태를 발동, `sharpness_consumed`를 소모로 기록 |
| 파워 슬라이더 | `PhysicsEventKind.powerSliderActivation` 사건 |
| 스위치·문·회전판 | `stateChange` 대상 및 `reflectorRotation` 사건 |
| 한 샷 이동 기물 | 최종 홀 샷의 인과 대상과 일치하는 이동 사건의 고유 ID |
| 준비 샷 | 해당 샷에서 새로 만든 과거 공, 영속 상태 변화, 영속 이동을 최종 사슬 대상과 연결 |
| 최소 샷 | `parShots`와 홀 진입까지 사용한 샷 수의 차이 |
| 선택 도전 | `CreativeChainChallengeId`별 사건 검출 후 설정된 도전과 교집합 |

선택 도전 ID는 `wall_reflection`, `past_ball`, `trait_reaction`, `power_slider`, `board_state`, `preparation_shot`, `diverse_chain`이다. 설정된 도전만 보너스를 받으며, 분석기가 사건을 확인하지 못한 도전은 점수에 포함하지 않는다.

## 파밍 방지 규칙

### 반복 접촉 감쇠

- 같은 기물의 같은 접촉이 `12` 경로 시점 이내에 반복되면 해당 사건의 계수는 `0.25`로 줄인다.
- 벽은 기물 ID와 법면(`위·아래·왼쪽·오른쪽`)을 함께 키로 만든다.
- 같은 벽면이 `24` 경로 시점 이내에 반복되면 계수는 최대 `0.2`가 된다.
- 감쇠 사건은 `dampedImpactCount`에 기록하며 인과 깊이를 늘리거나 새 개별 기물 다양성을 만들지 않는다.
- 같은 과거 공, 파워 슬라이더, 스위치·문·회전판은 한 인과 사슬에서 개체별 한 번만 전용 보너스를 받는다.
- 생성자에 더 큰 제한값이 들어와도 인과 충돌 12건, 무관 충돌 3건의 제품 절대 상한을 넘지 않으며 음수 제한값은 0으로 처리한다.

### 미세 진동·접촉 유지 제외

충돌의 상대 법선 속력이 `0.35` 미만이고 충격량이 `0.1` 미만이면 `ignoredImpactCount`로만 기록하고 점수화하지 않는다. 둘 중 하나라도 충분히 크면 실제 타격으로 취급한다.

### 인과 무관 충돌 제한

최종 홀 사건의 부모 사슬 밖에 있는 충돌은 인과 깊이·타입 다양성·개별 기물 점수에 참여하지 않는다. 최대 3건까지만 건당 4점을 부여하며, 이후 충돌은 추가 점수를 만들지 않는다.

### 전체 충돌 상한

인과 사슬의 유효 충돌은 최대 12건만 점수화한다. 초과 사건은 `cappedImpactCount`로 기록한다. 따라서 같은 벽을 계속 왕복하거나 기물 사이에서 미세하게 떨면서 점수를 무한히 늘릴 수 없다.

## 결정론·리플레이 검증

점수 서명에는 다음을 안정적인 순서로 포함한다.

- 점수 분석 버전 `creative-chain-score-v1`
- fixture ID·스테이지·경로·각도·파워·속성
- 최종 홀 샷 번호
- 모든 `ShotResult`의 기존 물리 fingerprint
- 점수와 핵심 breakdown 값

동일한 fixture와 `ShotResult` 목록은 매번 같은 `totalScore`, breakdown, 근거 순서, `replaySignature`를 만든다. 물리 결과 fingerprint가 fixture 기대값과 다르면 점수 계산을 억지로 성공으로 간주하지 않고 `replayMatchesFixture`를 거짓으로 남긴다.

## 검증 증거

집중 테스트: `test/creative_chain_score_test.dart`

- 부모 사건 기반 인과 깊이·타입·개별 기물 다양성
- 벽 반복 감쇠·미세 진동 제외·12건 상한
- 반복 과거 공 전용 보너스 중복 방지
- 홀과 무관한 충돌의 별도 제한
- 준비 샷으로 만든 과거 공 기여
- 과거 공의 다음 준비 샷 중복 적립 방지
- 다음 샷 전에 되돌아간 이동 제외 및 같은 상태를 복원한 마지막 준비 샷에만 귀속
- 활성 공과 다른 물체의 직전 사건 인과 혼입 방지
- 무거움·탄성 충돌 속성 발동 기록과 원본 집합 변경으로부터의 불변성
- 기존 공 홀 진입 성공의 홀 충돌·상태 사건 보존
- 설명 근거 점수 합과 Breakdown 총점의 일치
- 실제 7단계 과거 공 대표 경로
- 회전판·스위치·문·파워 슬라이더·속성 상태·한 샷 이동 근거
- `ReplayFixture` fingerprint 일치와 반복 실행 결정론
- 실패 결과와 비클리어 홀 접촉 0점 및 클리어 조건 비변경
- 외부에서 결과 컬렉션을 변경할 수 없는지 확인

실행 기준:

```text
dart format lib/game/analysis/creative_chain_score.dart test/creative_chain_score_test.dart
flutter analyze lib/game/analysis/creative_chain_score.dart test/creative_chain_score_test.dart
flutter test test/creative_chain_score_test.dart --reporter compact
```

결과: 집중 테스트 17개, 전체 Flutter 회귀 602개 통과, 전체 정적 분석 이슈 없음. 충돌 속성 필드가 리플레이 서명에 추가되어 공식 생성기로 단일 28개·다중 35개 fixture를 다시 생성했고, 두 fixture 재생 테스트와 전체 회귀가 모두 일치했다.

## 독립 QA 결과

독립 QA의 최초 감사는 설명 근거와 Breakdown 상한 불일치, 준비 샷 영속성 부족, 무거움·탄성 메타데이터 누락, 기존 공 홀 사건 누락을 P1으로 판정했다. 보완 뒤 재감사에서는 가변 속성 Set 노출을 마지막 P1으로 확인했다.

최종 구현은 설명 근거를 집계 단위로 통합하고, 엔티티별 마지막 영속 변경만 준비 샷에 귀속하며, 속성을 정수 비트 마스크로 복사 저장하고, 기존 공 홀 진입에 충돌·상태 사건을 보충한다. 원본 속성 Set 변경·외부 수정 시도, 상태 해제 후 복원, 되돌아간 이동, 비클리어 홀 접촉을 회귀로 추가했다. 독립 QA 최종 재감사는 P0·P1 없이 `PASS`를 판정했다.

## 남은 위험과 후속 작업

- `ShotImpact`와 `PhysicsEvent`는 충돌 주체의 속성을 가변 Set이 아닌 정수 비트 마스크로 보존한다. 공개 getter는 불변 Set을 반환하므로 원본 엔티티나 호출자의 Set 변경이 점수·리플레이 서명을 사후 변경하지 않는다.
- 부모 사건이 없는 활성 공 연속 사건은 경로 시점과 출발 ID로 보완한다. 이는 결정론적이지만, 향후 물리 엔진이 더 정밀한 교차 인과를 제공하면 직접 부모 ID를 우선 연결하는 후속 검토가 필요하다.
- 점수의 저장·결과 UI·랭킹·8단계 설계는 다음 작업의 범위다. 이번 작업에서 사용자 화면이나 기본 점수 필드는 변경하지 않았다.
- 실제 장치 프레임 속도와 네트워크 환경은 점수 분석 계층에 영향을 주지 않지만, 최종 제품 통합 때 리플레이 입력 저장과 함께 실기기 재현을 추가 검증해야 한다.
