# PS-REPLAY-01A 리플레이 문서 검증

기준일: 2026-08-08 KST

## 결정론 계약

- `ReplayDocument`는 한 단계 시도만 기록하며 `runId`, 시각, frame, 화면 데이터와 위치·속도 snapshot을 저장하지 않는다.
- 각 `ReplayShot`은 0부터 연속인 `shotIndex`와 시도 안에서 고유한 `ballId`를 갖는다.
- `recoveredPastBallIds`는 앞선 shot의 `ballId` 부분집합이다. 재생기는 stage 초기 상태를 만든 뒤 shot을 순서대로 결정론적으로 다시 실행해 과거 공의 위치·속성·동적 상태를 복원하고, 마지막에 정확한 회수 ID를 적용한다.
- 방향과 힘은 `1,000,000` 배율 고정소수점 정수이며 root/pattern seed는 unsigned 32비트다. draw 카운터와 초기 복제 코어 수도 제품 상한 안의 정수만 허용한다.
- 결과 지문은 `outcomeFingerprintVersion=sha256-v1`과 소문자 SHA-256 64자리 hex로 고정한다.
- 보상 재현에는 bounded `acquiredRewardIds`와 `(rewardId, useKey)` 쌍인 `consumedRewardUses`를 명시하며, 현재 `RunState.acquiredRewards`와 `consumeRewardUse(rewardId, useKey)` 용어에 대응한다.

## 입력·공유 보안 계약

- ID와 버전 문자열은 `[a-zA-Z0-9_.:|-]`만 허용한다. `|`는 기존 RunState의 `stageId|attempt` use key와 `run_reward_used:*` record를 무손실 보존하기 위한 구분자이며, 공백·슬래시·`@`·한글 자유 입력은 계속 거부해 개인정보성 값이 섞이지 않게 한다.
- canonical JSON 원문은 UTF-8 16KiB를 넘으면 `jsonDecode` 전에 거부한다. 배열은 객체 변환 전에 각 개수 상한을 검사하고, 파싱 뒤 canonical 재직렬화가 원문과 정확히 같아야 한다.
- `속한1:` 공유 코드는 정확히 64개 한글 음절의 6-bit 인코딩과 SHA-256 integrity tag를 사용한다.
- 공유 코드의 SHA-256 태그는 전송 오류와 변조를 검출할 뿐이다. 비밀 키가 없으므로 작성자·기기·서버 출처를 인증하지 않으며, 공식 기록의 진위나 순위를 신뢰하는 근거로 사용해서는 안 된다. 공식 기록은 별도의 서버 서명 또는 신뢰 가능한 검증 경계가 필요하다.

## 자동 검증

```text
flutter test test/replay_document_test.dart test/replay_share_code_test.dart --reporter compact
flutter analyze
git diff --check
```

검증 결과:

- replay 집중 테스트 통과
- Dart 분석기 이슈 0건
- 전체 회귀 테스트 831개 통과
- replay 변경 범위 `git diff --check` 통과

참고: 현재 실행 환경에서는 Flutter 분석 명령이 SDK 캐시 갱신 권한에서 중단될 수 있어
캐시를 변경하지 않는 Dart 분석기로 동일한 소스 분석을 확인했다.
