# 역할 매뉴얼 기반 에이전트 활성화 프롬프트

## 목적

`속성 한방`의 후속 작업을 시작할 때 각 역할 에이전트가 동일한 프로젝트 규칙과 외부 근거를 이해한 뒤 독립 진단·제안·검증을 수행하게 한다.

## 선행 읽기

1. `README.md`
2. `harness_docs/readme.md`
3. `harness_docs/manuals/00_agent_operating_standard.md`
4. 자신의 역할 매뉴얼 `harness_docs/manuals/<역할>.md`
5. `harness_docs/research/role_reference_index.md`
6. `harness_docs/agents/activation_gate_2026-08-03.md`
7. 최신 `harness_docs/agents/current_shared_context.md`, 관련 설계·QA·결정 문서

## 활성화 답변 형식

```text
역할 매뉴얼 확인:
프로젝트 문서 확인:
외부 참고자료 확인:
이번 작업 범위:
이번 작업 비범위:
현재 가장 큰 위험:
동료 검토 요청:
제안 최대 5개:
각 제안의 검증 방법:
```

## 작업 규칙

- 제안은 문제·관찰 증거·플레이어 가치·구현 영향·테스트 계획을 포함한다.
- 최대 5개를 제안하고, 교차 검토 후 상위 1~3개만 구현한다.
- 일반적인 상용 게임 관행이라고 주장하려면 `commercial_game_practice_matrix.md`의 비교 근거 또는 2개 이상의 독립 참고자료를 제시한다.
- 외부 자료는 일반 원칙이며, 저장소의 결정론 테스트·Golden·QA 결과가 최종 근거다.
- 사용자 노출 텍스트는 한글이고, 물리 판정은 순수 Dart에 남긴다.
- 특정 기믹을 필수 정답으로 만들지 않고, 대체 풀이를 분석한다.
- 코드·문서 변경 전 `harness_docs/dev-wiki/log.md`에 작업 의도를 기록한다.
- 작업 단위별로 테스트·commit·push·데모 서버 교체 여부를 기록한다.

## 산출물

- 역할별 독립 진단 문서
- 동료 교차 검토 문서
- 구현 변경과 회귀 테스트
- 시각·접근성·성능·라이선스 증거
- commit/push와 최신 데모 서버 상태
- 남은 위험과 다음 작업 목록
