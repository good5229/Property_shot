# 모바일 퍼즐 레퍼런스 조사 매트릭스

조사일: 2026-08-02 KST

공식 App Store, 개발사 공식 페이지, Apple Design Awards 자료에서 화면 위계·조작 피드백·반복 도전 원칙만 추출했다. 캐릭터·UI 배치·색상 조합·스테이지·에셋은 복제하지 않는다.

| 게임 | 조사 출처 | 참고한 원칙 | 속성 한방 적용 가능성 | 적용하지 않을 요소 | 모방 위험 | 최종 활용 |
| --- | --- | --- | --- | --- | --- | --- |
| Monument Valley 3 | [App Store](https://apps.apple.com/us/app/monument-valley-3/id6443563379) | 장면 자체가 목표와 다음 행동을 설명하고, 탐험 동선을 시각적으로 유도 | 섬 지도와 플레이 보드 사이의 시선 흐름, 장식 밀도 조절 | 착시 기반 회전 구조, 고유 건축물, 캐릭터 | 높음 | 목표·환경 위계 원칙만 채택 |
| Cut the Rope 3 | [App Store](https://apps.apple.com/us/app/cut-the-rope-3/id997332884), [ZeptoLab 공식 페이지](https://www.zeptolab.com/games/cut-the-rope) | 단순한 첫 행동, 물리 결과를 즉시 보여주는 귀여운 피드백, 작은 목표의 반복 | 속성 선택 직후 효과가 눈에 보이는 튜토리얼과 짧은 실패 피드백 | Om Nom·Nibble Nom, 밧줄·사탕 규칙, 고유 캐릭터 연출 | 높음 | 행동 발견성과 피드백 원칙만 채택 |
| Angry Birds Reloaded | [Rovio 공식 글](https://www.rovio.com/articles/angry-birds-reloaded-now-available-on-apple-arcade/), [App Store](https://apps.apple.com/us/app/angry-birds-reloaded/id1539172625) | 방향·힘 조작의 즉시성, 충돌 연쇄의 가독성, 결과를 다시 시도하게 하는 구조 | 조준·충전·충돌 링·잔류 공의 연쇄 관찰 | 새·돼지·새총 UI, 고유 레벨 구조, 파괴 연출 복제 | 매우 높음 | 타격감과 연쇄 시간축 원칙만 채택 |
| Color Block Jam | [App Store](https://apps.apple.com/us/app/color-block-jam/id6504332779) | 한 화면에서 목표·장애물·가능한 이동을 빠르게 비교, 단계가 진행될수록 사고량을 높임 | 홀·문·스위치의 대비와 단계별 정보량 조절 | 색상 맞춤 규칙, 블록 모양·문 구조·상점 모델 | 중간 | 보드 가독성과 난이도 상승 원칙만 채택 |
| Apple Design Awards 게임·퍼즐 사례 | [Apple Design Awards 2024](https://developer.apple.com/design/awards/2024/), [Apple Newsroom](https://www.apple.com/uk/newsroom/2024/06/apple-announces-winners-of-the-2024-apple-design-awards/) | 시각적 일관성, 접근성, 기기 기능을 장식이 아니라 경험에 연결 | 재질·소리·햅틱을 선택 상태와 충돌 결과에 연결하고 색상 외 패턴 제공 | 수상작의 브랜드·레이아웃·콘텐츠를 직접 차용 | 낮음 | 품질 평가 기준과 접근성 원칙에 반영 |

## Property Shot 최종 적용 원칙

- 첫 화면은 공·홀·이동 물체가 함께 보여 게임의 약속을 설명한다.
- 조작은 방향·힘·손 떼기의 세 단계로 짧게 안내한다.
- 충돌 결과는 실제 물리 이벤트 뒤에만 재생한다.
- 실패는 다음 실험의 변수 하나만 제안하고 정답 궤적은 숨긴다.
- 섬의 모래·물·목재·속성 재질은 자체 팔레트와 자체 도형·에셋으로 구성한다.
- 온라인 랭킹, 광고, 결제, 타 게임의 캐릭터·UI·스테이지 복제는 사용하지 않는다.
