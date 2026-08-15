# 플레이테스트 프로토콜

## 목적

모바일 터치, 키보드, 접근성 의미 정보, 비정상 입력에서 조작이 막히거나 잘못 실행되지 않는지 확인한다. 대리 플레이는 이 네 입력 위험의 회귀를 빠르게 선별할 때만 사용한다. 일반적인 재미·몰입·장기 반복 플레이를 에이전트 점수로 대신하지 않는다.

## 물리 실험실

섬 지도의 `물리 실험실`에서 무거움으로 상자 움직이기, 여러 벽에서 탄성 유지 확인하기, 점착 공을 다음 발사의 발판으로 사용하기, 뾰족함으로 풍선 터뜨리기, 스위치로 문 열기를 캠페인 기록 없이 연습한다.

실험실은 고정 시나리오 ID만 허용하며 임의 엔티티 JSON이나 정답 발사를 주입하지 않는다. 진행, 최고 기록, 도감, 섬 복구, 보상, 리플레이, 오늘의 도전 저장은 시작 전후에 같아야 한다.

## 입력별 대리 사용자 역할

- `mobile_touch`: 320×568 화면에서 터치만 사용하는 모바일 초보
- `keyboard_only`: Tab·방향키·Space·Esc만 사용하는 키보드 사용자
- `semantics_only`: 스크린샷 없이 의미 라벨과 custom action만 사용하는 사용자
- `abnormal_input`: 연타, 중복 Space, 팝업 뒤 배경 키 입력 등 잘못된 순서를 시험하는 사용자

각 역할은 저장소·소스 코드·물리 판정기·QA fixture·정답 각도와 힘을 볼 수 없다. 공개 빌드의 스크린샷과 접근성 트리만 사용하며 매 실행은 새 브라우저 저장소에서 시작한다.

## 행동 문법과 절차

공통 행동은 의미 라벨 읽기, 라벨 버튼 활성화, 상태 변화 대기와 스크린샷이다. 역할별 허용 입력과 질문은 `proxy_playtest_prompts.md`에 고정한다. 모바일 역할은 포인터만, 키보드 역할은 키 이벤트만, semantics 역할은 의미 동작만 사용한다. 비정상 입력 역할은 의도된 중복·경계 입력 외에 정답 탐색을 하지 않는다. 행동은 최대 25회, 발사는 최대 5회, 실행은 최대 120초다.

각 역할은 다섯 실험을 세 번씩 실행해 총 60회를 만든다. 모바일은 작은 화면에서 가림·오조작·스크롤을, 키보드는 포커스 위치·중복 발사·Esc 정책을, semantics는 라벨만으로 목표와 상태를 구별하는지를, 비정상 입력은 무시·복구·저장 불변을 판정한다. 역할 사이의 점수는 합산하지 않고 네 개의 독립 게이트로 보고한다.

에이전트에는 opaque run ID와 공개 화면만 제공한다. 내부 scenario ID, 기대 이벤트, 테스트 fixture는 orchestrator가 실행 후 결합한다. 목표 문구를 그대로 반복한 답은 인과 이해로 세지 않고, 실제 전후 화면 근거가 두 개 이상 있어야 정답으로 판정한다.

## 결과 JSON 계약

```json
{
  "schema": "property-shot-proxy-playtest/v1",
  "build": {"git_sha": "...", "url": "...", "viewport": [390, 844], "locale": "ko-KR"},
  "agent": {"profile": "mobile_touch", "input_mode": "pointer", "prompt_version": "2", "model": "declared-family"},
  "run_id": "opaque-run-id",
  "isolation": {"unchanged": true, "checked_domains": ["progress", "campaign_run", "expedition", "daily", "solutions", "replays", "rewards"]},
  "steps": [{"seq": 1, "t_ms": 0, "action": "activate", "target": "공을 조준하는 게임 화면", "no_op": false}],
  "objective": {"status": "completed", "shots": 2, "retries": 1, "first_meaningful_action_ms": 8200, "no_op_actions": 1},
  "judgment": {"goal_clarity": 4, "control_discoverability": 3, "causal_readability": 4, "frustration": 2, "retry_desire": 4, "causal_explanation": "..."},
  "limitations": ["agent_proxy_not_human"]
}
```

내부 scenario ID, 기대 이벤트와 인과 순서 판정은 harness가 별도 결과에 결합한다. 객관 이벤트·발사 수·시간은 harness, 화면 라벨은 semantics, 명확성·좌절·재시도 의향은 agent judgment로 출처를 구분한다. 알 수 없는 필드, 범위를 벗어난 점수, 50개 초과 step, 비유한 숫자와 과도한 문자열은 거부한다. 기계 검증 계약은 `harness_docs/design/proxy_playtest.schema.json`에 둔다.

## 진단 게이트

- 모바일 320×568에서 첫 의미 행동 중앙값 20초 이하, 오조작 중앙값 2회 이하
- 키보드 전용 완료율 80% 이상, 중복 Space 발사 0회, 모달 포커스 이탈 0회
- semantics-only 완료율 70% 이상, 목표·현재 상태·다음 행동 설명 정확도 80% 이상
- 비정상 입력에서 crash·중복 저장·팝업 뒤 배경 조작 0회
- 저장 격리 100%

게이트 통과는 인간 테스트 준비 완료를 뜻한다. 실제 재미와 반복 플레이 의향은 초행 사용자 화면 녹화와 인터뷰로 별도 확인한다.

## 인간 플레이테스트 질문

- 방금 무엇을 하려고 했나요?
- 공에 어떤 변화가 생겼다고 생각했나요?
- 실패 원인은 무엇이며 다음에는 무엇을 바꾸겠나요?
- 이번 시도에서 새로 알아낸 것은 무엇인가요?
- 한 번 더 시도하고 싶은가요? 그 이유는 무엇인가요?
