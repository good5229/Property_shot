# 플레이테스트 프로토콜

## 목적

초행 사용자가 화면만 보고 목표와 조작을 발견하고, 실패 뒤 원인을 설명하며 다음 시도를 바꿀 수 있는지 확인한다. 자동 테스트는 물리 결정론과 UI 계약을 검증하고, 대리 플레이 에이전트는 발견 가능성·문구·인과 설명의 회귀를 빠르게 선별한다. 손가락 감각, 실제 재미, 장기 몰입과 사회적 동기는 사람만 평가할 수 있으므로 대리 결과를 인간 플레이테스트의 대체 증거로 사용하지 않는다.

## 물리 실험실

섬 지도의 `물리 실험실`에서 무거움으로 상자 움직이기, 여러 벽에서 탄성 유지 확인하기, 점착 공을 다음 발사의 발판으로 사용하기, 뾰족함으로 풍선 터뜨리기, 스위치로 문 열기를 캠페인 기록 없이 연습한다.

실험실은 고정 시나리오 ID만 허용하며 임의 엔티티 JSON이나 정답 발사를 주입하지 않는다. 진행, 최고 기록, 도감, 섬 복구, 보상, 리플레이, 오늘의 도전 저장은 시작 전후에 같아야 한다.

## 대리 사용자 역할

- `novice_impatient`: 설명을 오래 읽지 않는 모바일 초보
- `observant_novice`: 변화를 살피지만 정답 지식이 없는 퍼즐 초보
- `semantics_only`: 의미 정보와 키보드만 사용하는 사용자
- `abnormal_input`: 연타, 중복 Space, 팝업 뒤 배경 키 입력 등 잘못된 순서를 시험하는 사용자

각 역할은 저장소·소스 코드·물리 판정기·QA fixture·정답 각도와 힘을 볼 수 없다. 공개 빌드의 스크린샷과 접근성 트리만 사용하며 매 실행은 새 브라우저 저장소에서 시작한다.

## 행동 문법과 절차

의미 라벨 읽기, 라벨 버튼 활성화, 조준 화면의 증가·감소, `시계 방향으로 조준`, `반시계 방향으로 조준`, `공 발사`, 상태 변화 대기와 스크린샷만 허용한다. 접근성 동작이 없을 때만 포인터 조작을 쓴다. 행동은 최대 25회, 발사는 최대 5회, 실행은 최대 120초다.

에이전트는 목표를 자기 말로 설명하고 첫 행동을 선택한다. 실패했다면 화면 근거 하나를 인용하고 다음 시도에서 각도나 힘 중 하나만 바꾼다. 완료 또는 포기 뒤 실패 원인, 기믹의 인과 순서, 다시 시도할 의향을 답한다. 세 기본 역할은 다섯 시나리오를 세 번씩 실행해 45회를 만들고, `abnormal_input`은 다섯 시나리오를 한 번씩 별도 실행해 총 50회를 만든다.

에이전트에는 opaque run ID와 공개 화면만 제공한다. 내부 scenario ID, 기대 이벤트, 테스트 fixture는 orchestrator가 실행 후 결합한다. 목표 문구를 그대로 반복한 답은 인과 이해로 세지 않고, 실제 전후 화면 근거가 두 개 이상 있어야 정답으로 판정한다.

## 결과 JSON 계약

```json
{
  "schema": "property-shot-proxy-playtest/v1",
  "build": {"git_sha": "...", "url": "...", "viewport": [390, 844], "locale": "ko-KR"},
  "agent": {"profile": "novice_impatient", "prompt_version": "1", "model": "declared-family"},
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

- 시각 역할 완료율 80% 이상
- semantics-only 완료율 70% 이상
- 인과 순서를 정확히 설명한 비율 80% 이상
- 첫 의미 행동 중앙값 20초 이하
- 의미 없는 행동 중앙값 2회 이하
- 저장 격리 100%

게이트 통과는 인간 테스트 준비 완료를 뜻한다. 실제 재미와 반복 플레이 의향은 초행 사용자 화면 녹화와 인터뷰로 별도 확인한다.

## 인간 플레이테스트 질문

- 방금 무엇을 하려고 했나요?
- 공에 어떤 변화가 생겼다고 생각했나요?
- 실패 원인은 무엇이며 다음에는 무엇을 바꾸겠나요?
- 이번 시도에서 새로 알아낸 것은 무엇인가요?
- 한 번 더 시도하고 싶은가요? 그 이유는 무엇인가요?
