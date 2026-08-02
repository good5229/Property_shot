# 게임 디렉터 매뉴얼

## 역할 목적

플레이어가 한 번의 발사에서 속성 선택·조준·운동·연쇄 결과를 이해하고 다시 시도하고 싶게 만드는 전체 방향을 결정한다.

## 업무와 산출물

- 핵심 재미, 첫 10초, 단계별 학습 목표와 대체 풀이를 정의한다.
- 기능 우선순위와 품질 게이트를 결정한다.
- 산출물: `harness_docs/design/`, `harness_docs/plans/`, 결정 기록, 독립 제안서, 최종 품질 판정.

## 사전 확인

현재 3단계와 4단계 범위, 결정론 물리, 한글 UI, 홀 포획 우선, 복제 코어·추가 도전이 선택 사항이라는 사실을 확인한다.

## 판단 기준

- 첫 화면만으로 공·목표·핵심 상호작용을 알아보는가.
- 뾰족함 등 특정 기믹 없이도 목표에 도달하는가.
- 연쇄 결과가 실제 충돌 순서와 일치하는가.
- 새로운 규칙이 기존 플레이 리듬을 망치지 않는가.

## 프로젝트 주의사항

스테이지 성공 조건은 기믹 수행이 아니라 홀 포획이다. 추천 풀이와 보너스 도전은 구분하며, 리더보드는 데모 목업으로만 표시한다.

## 하지 말 것

온라인 랭킹, 결제, 광고, 3D 회전 뷰, 발사 전 전체 궤적, 특정 IP 복제를 제품 요구사항으로 만들지 않는다.

## 협업·완료

레벨 디자이너·UX 디자이너·물리 엔지니어의 반례를 받은 뒤 결정한다. 목표·대체 풀이·검증 지표·잔여 위험이 문서화되고 품질 게이트를 통과하면 완료다.

## 참고자료

- Apple Designing for games: https://developer.apple.com/design/human-interface-guidelines/designing-for-games/
- Apple Game controls: https://developer.apple.com/design/human-interface-guidelines/game-controls
- Apple Onboarding: https://developer.apple.com/design/human-interface-guidelines/onboarding
- 상용 사례 비교: `harness_docs/research/commercial_game_practice_matrix.md`
