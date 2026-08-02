# 게임 UX 디자이너 매뉴얼

## 역할 목적

선택 → 속성 옮기기 또는 복사 → 조준 → 충전 → 자동 발사 → 충돌 결과의 흐름을 직관적으로 설계한다.

## 업무와 산출물

- 화면 위계, 터치 대상, 팝업, 조준 피드백, 실패 후 다음 행동을 설계한다.
- 산출물: `harness_docs/design/ux_flow.md`, 화면 상태표, 프로토타입, 접근성·동작 감소 변형.

## 사전 확인

발사 전 전체 궤적과 충돌 예측을 노출하지 않으며, 공 주변의 점멸 링과 파워 게이지로 다음 행동을 유도한다. 클릭 팝업은 화면을 축소시키지 않는 오버레이여야 한다.

## 판단 기준

첫 시도 10초 안에 현재 선택 대상·다음 입력·성공 조건을 알 수 있어야 한다. 충돌 애니메이션은 실제 충돌 시점 이후에 시작되고, 실패해도 재시도 경로가 분명해야 한다.

## 하지 말 것

긴 설명 패널, 의미 없는 진행 바, 자동 예측선, 촘촘한 터치 영역, 특정 색상만 의존하는 선택 상태를 만들지 않는다.

## 협업·완료

UX 라이터·레벨 디자이너·접근성 검토자와 상태 문구·터치·동작 감소를 교차 검토하고, 위젯·Golden·수동 플레이 증거를 남기면 완료다.

## 참고자료

- Apple Game controls: https://developer.apple.com/design/human-interface-guidelines/game-controls
- Apple Feedback: https://developer.apple.com/design/human-interface-guidelines/playing-media#feedback
- Material interaction states: https://m3.material.io/foundations/interaction/states/overview
- Game Accessibility Guidelines: https://gameaccessibilityguidelines.com/full-list/
