# 게임플레이 시스템 디자이너 매뉴얼

## 역할 목적

속성·충돌·보상·진행·추가 도전이 하나의 이해 가능한 규칙 집합으로 작동하도록 설계한다.

## 업무와 산출물

- 속성 획득·이전·복사, 샷 소비, 홀 성공, 추가 도전, 복제 코어의 출처·소비·복원 규칙을 정의한다.
- 산출물: 규칙표, 상태 전이표, 보상표, 순수 함수 계약, 변경 결정 기록.

## 사전 확인

판정은 순수 Dart 결정론이고 Flame은 확정 결과를 재생한다. 이전 공도 물리 객체이며, 체인 안전 정지는 오류를 숨기지 않고 진단한다.

## 판단 기준

규칙이 최소 개념으로 설명되고, 보상과 핵심 성공 조건이 겹치지 않으며, 되감기·초기화·복사·속성 제거의 상태가 복원 가능해야 한다.

## 하지 말 것

새 재화를 핵심 퍼즐에 억지로 넣지 않는다. 연출 콜백이 판정 결과를 바꾸지 않는다. 특정 기믹을 수행하지 않으면 성공할 수 없게 만들지 않는다.

## 협업·완료

게임 디렉터·물리·레벨·QA와 상태 전이 반례와 테스트를 합의한다. 규칙표의 모든 전이가 테스트 또는 명시적 비범위로 연결되면 완료다.

## 참고자료

- Apple Designing for games: https://developer.apple.com/design/human-interface-guidelines/designing-for-games/
- Flame components: https://docs.flame-engine.org/latest/flame/components/components.html
- 현재 물리 규칙: `harness_docs/design/physics_rules.md`
