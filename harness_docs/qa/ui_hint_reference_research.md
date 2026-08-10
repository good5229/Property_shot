# UI·힌트·시연 난이도 레퍼런스 조사

작성일: 2026-08-09. 이 문서는 구현 지시가 아니라, 현재 합의된 채택안을 추적할 수 있게 한 조사·QA 기준이다. 외부 게임은 기능과 표현을 복제하기 위한 자료가 아니며, 아래 `not copied` 범위를 지킨다.

## 레퍼런스 카드

### name: Apple HIG — Layout

- source: [Apple Human Interface Guidelines — Layout](https://developer.apple.com/design/human-interface-guidelines/layout)
- problem: 작은 세로 화면에서 클리어 팝업의 하단 CTA와 보상 선택지가 가려지거나, 시스템 안전 영역과 충돌할 수 있다.
- principle: 콘텐츠와 컨트롤의 계층을 명확히 두고, 다양한 창 크기·안전 영역에서 적응하는 배치를 우선한다.
- not copied: Apple의 시각 자산, 컴포넌트 외형, 고정 치수나 화면 구성을 복제하지 않는다.

### name: Apple HIG — Designing for games

- source: [Apple Human Interface Guidelines — Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games)
- problem: 게임 세계와 시스템 UI가 경쟁하면 시연에서 목표·다음 행동이 흐려진다.
- principle: 플랫폼의 익숙한 상호작용을 지키면서도 게임 콘텐츠가 우선 읽히는 시각적 위계를 둔다.
- not copied: Apple 게임 예시의 스타일·아트·내비게이션 패턴을 그대로 사용하지 않는다.

### name: Apple HIG — Game controls

- source: [Apple Human Interface Guidelines — Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls)
- problem: 파워 게이지가 화면 가장자리에 묻히고, 조작 중인 손이나 시스템 영역과 겹칠 수 있다.
- principle: 터치 컨트롤은 안전 영역과 엄지 도달 범위를 고려하고, 자주 쓰는 요소에는 명확한 시각·촉각 상태를 제공한다. 게임 맥락과 무관한 컨트롤은 숨겨 혼잡을 줄인다.
- not copied: Apple의 컨트롤 그래픽, 아이콘, 배치 템플릿은 사용하지 않는다.

### name: Flutter — SafeArea & MediaQuery

- source: [Flutter — SafeArea & MediaQuery](https://docs.flutter.dev/ui/adaptive-responsive/safearea-mediaquery)
- problem: 노치·홈 인디케이터·둥근 모서리 때문에 세로 모바일의 마지막 보상/버튼이 잘릴 수 있다.
- principle: 전면 풀블리드 게임 영역과 실제로 피해야 하는 HUD/팝업 영역을 분리하고, 필요한 자식에만 `SafeArea`를 적용한다. 창 크기·inset은 `MediaQuery`로 읽는다.
- not copied: Flutter 문서의 샘플 UI나 소스 코드를 제품 화면으로 전재하지 않는다.

### name: Flutter — Adaptive general approach

- source: [Flutter — General approach to adaptive apps](https://docs.flutter.dev/ui/adaptive-responsive/general)
- problem: 기기 종류나 방향을 기준으로 고정 분기하면 웹·태블릿·작은 모바일에서 HUD가 불안정해진다.
- principle: 공통 데이터를 추상화하고, 창 전체는 `MediaQuery.sizeOf`, 로컬 슬롯은 `LayoutBuilder` 제약으로 측정한 뒤 사용 가능한 공간에 따라 분기한다.
- not copied: 문서의 내비게이션 예제나 중단점 값을 게임 규칙으로 가져오지 않는다.

### name: Flutter — Adaptive best practices

- source: [Flutter — Best practices for adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)
- problem: 하나의 큰 오버레이와 기기명 기반 조건은 재빌드 비용과 작은 화면의 회귀 위험을 키운다.
- principle: 터치 우선으로 작은 위젯을 조합하고, 하드웨어 유형·방향 대신 실제 가용 공간을 사용한다. 상태는 크기 변경 뒤에도 보존한다.
- not copied: Flutter 브랜드/Material 화면을 게임의 고유 UI로 모사하지 않는다.

### name: Flame — Camera & World

- source: [Flame — Camera & World](https://docs.flame-engine.org/latest/flame/camera.html)
- problem: 카메라가 월드를 투영하는 구조에서 HUD·열쇠·힌트가 같은 좌표계로 취급되면 가시성과 판정이 흔들릴 수 있다.
- principle: 월드 요소와 카메라의 viewport/viewfinder에 붙는 HUD를 분리한다. 월드는 게임 좌표, HUD는 표시 좌표의 책임을 가진다.
- not copied: Flame 문서의 예제 구조를 그대로 복사하거나 엔진 기능을 요구사항 이상으로 도입하지 않는다.

### name: Cut the Rope: Physics Puzzle

- source: [App Store — Cut the Rope: Physics Puzzle](https://apps.apple.com/us/app/cut-the-rope-physics-puzzle/id1024506959)
- problem: 물리 퍼즐에서 새 기믹을 발견해도 목적·도구·결과 연결이 약하면 무작위 발사가 된다.
- principle: 앱 설명에서 확인되는 물리 기반 퍼즐, 기믹별 도전, 수집 요소라는 고수준 구조를 참고해, 속성 한방에서는 열쇠 획득과 구체적인 해결 힌트를 연결한다.
- not copied: 캐릭터, 로프/사탕 규칙, 레벨, 아트, 명칭, UI 및 해법을 사용하지 않는다.

### name: Where's My Water?

- source: [App Store — Where's My Water?](https://apps.apple.com/us/app/wheres-my-water/id449735650)
- problem: 사용자가 기믹을 어떤 목표 상태로 변환해야 하는지 이해하지 못하면 스테이지가 ‘너무 어려움’으로 느껴진다.
- principle: 앱 설명에서 확인되는 물리 요소의 목표 지향적 조작과 수집/보너스 구조를 참고해, 힌트는 “무엇을 어떤 순서·방향으로” 수행할지 명시한다.
- not copied: 물, 캐릭터, 흙 파기, 레벨 구도, 수집물, 카피, 아트를 사용하지 않는다.

### name: Monument Valley

- source: [App Store — Monument Valley](https://apps.apple.com/us/app/monument-valley/id728293409?platform=ipad)
- problem: 조작 가능한 기믹과 배경 장식이 구분되지 않으면 퍼즐의 관찰 부담이 커진다.
- principle: 앱 설명에서 확인되는 ‘경로를 드러내고 착시를 푸는’ 퍼즐 전달 방식을 고수준으로만 참고해, 본 게임은 다음 행동을 한 문장으로, 목표 기물·방향·결과까지 표현한다.
- not copied: 불가능 건축, 착시 기하, Ida/까마귀 캐릭터, 레벨, 색·구도·아트·카피를 사용하지 않는다.

## 이 프로젝트에 채택할 해석

1. 모바일은 **SafeArea 적용 뒤 `LayoutBuilder`로 HUD 밴드의 실제 제약을 계산**한다. 월드는 가능한 한 풀블리드로 두되, 상단 상태·중앙 파워 게이지·하단 발사/보상 영역은 안전 영역 안의 독립 밴드로 둔다.
2. 클리어 화면은 작은 높이에서 보상 선택을 먼저 보이게 하는 compact 변형을 쓴다. 부가 점수 내역은 스크롤/접힘 처리하고, 전환은 짧은 fade로 제한하며, 다음 버튼은 안전 영역 안 고정 footer에 둔다.
3. 파워 게이지는 발사선/볼과 경쟁하지 않는 화면 중앙 쪽 부유 HUD로 옮기며, 색상 외 단계 표식·텍스트와 충분한 터치 상태를 유지한다.
4. 열쇠는 물리 충돌·반사에 영향 주지 않는 **비물리적·결정론적 수집물**이다. 스테이지 클리어와 별개인 도달 가능한 경로에 놓고, 한 번의 공 접촉으로 획득한다.
5. 보상 선택에는 다음 스테이지의 ‘클리어 팁 보기’를 포함한다. 팁은 추상적 격려가 아니라 대상 기믹, 조준/세기, 순서, 기대 결과를 포함한다. 예: “왼쪽 아래 스프링을 중간 세기로 맞혀 공을 위로 올린 뒤, 세로 반사판의 왼쪽 면으로 보내 홀 입구 쪽으로 꺾으세요.”
6. 팁 데이터는 버전이 있는 `HintCatalog`에 40개 패턴으로 관리한다. 잠금 해제·열쇠 수집·이미 본 L1/L2는 `RunState v3` entitlement/key 상태로 보존한다. v1·v2 저장본의 기본값과 L3→L2 마이그레이션을 명시한다.
7. 시연용 `bouncy_01`은 직선 발사만으로 성공하지 않게 구성한다. 오른쪽 아래 젤리에서 탄성을 이전한 뒤 다중 벽 반사를 거쳐 홀로 가는 실제 결정론 경로를 사용한다. 열쇠는 핵심 클리어선과 분리하되 화면에서 읽히고 합리적인 한 번의 별도 샷으로 닿는 곳에 둔다.

## 구현·검증 상태

- 위 채택안은 Flutter/Flame 코드와 320×568·375×812·390×844·430×932·768×1024·1024×1366 Golden/위젯 테스트, 40패턴 HintCatalog Validator, 열쇠 결정론, RunState v1/v2→v3 마이그레이션 및 저모션·Semantics 회귀에 반영됐다.
- 실제 iPhone·Android·iPad의 SafeArea·보조기술·프레임 성능과 최종 공개 Web 리사이즈는 릴리스 후보에서 다시 확인해야 하며, 확인 전에는 통과로 쓰지 않는다.
- 외부 앱 스토어 설명은 제품 기능의 공개 설명만 확인한 자료다. 실제 게임의 화면 흐름·수치·퍼즐 해법을 조사하거나 사용하지 않았으며, 이를 품질 보증 근거로 삼지 않는다.
