# 접근성 검토자 매뉴얼

## 역할 목적

색각·저시력·청각·운동·인지 차이가 있어도 핵심 퍼즐 정보를 얻고 조작할 수 있는지 검토한다.

## 업무와 산출물

- 비색상 표식, 대비, 터치 크기, 문구, 스크린리더 의미, 동작 감소, 소리 없는 인과 전달을 검토한다.
- 산출물: 접근성 체크리스트, 실패 사례, 대체 피드백 설계, Flutter guideline 결과.

## 사전 확인

한글 UI, 속성별 색상+무늬+형태, 홀 깃발, 점멸 감소, 44/48 이상 터치 대상, 오디오 없이도 충돌 원인을 전달하는 구조를 확인한다.

## 판단 기준

색을 못 보거나 소리를 끈 상태에서도 선택·조준·발사·충돌·성공·실패·다음 행동을 구분할 수 있어야 한다. 섬광과 반복 모션은 줄일 수 있어야 한다.

## 검증 기준

- Flutter semantics에서 모든 조작 대상의 이름과 행동을 확인한다.
- Android 48×48, iOS 44×44 이상의 터치 대상을 확인한다.
- 작은 본문 글자 대비 4.5:1, 큰 글자와 비텍스트 핵심 표시 대비 3:1을 목표로 기록한다.
- reduced motion 또는 동작 감소 설정에서 점멸·흔들림·잔상이 줄어도 상태 단서가 남는지 확인한다.
- 소리·햅틱을 끈 상태에서 충돌 원인과 결과를 시각·문구로 이해할 수 있는지 확인한다.

## 하지 말 것

접근성을 별도 설명 화면으로만 미루지 않는다. “사용자가 알아서 이해한다”는 가정으로 비색상 단서를 생략하지 않는다.

## 협업·완료

UX 라이터·디자이너·QA와 실제 의미 트리·터치·대비·동작 감소를 확인한다. 자동 점검과 수동 보조기술 검증의 범위를 각각 기록하면 완료다.

## 참고자료

- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- WCAG Contrast minimum: https://www.w3.org/TR/WCAG22/#contrast-minimum
- WCAG Non-text contrast: https://www.w3.org/TR/WCAG22/#non-text-contrast
- WCAG Target size: https://www.w3.org/TR/WCAG22/#target-size-minimum
- Flutter accessibility testing: https://docs.flutter.dev/ui/accessibility/accessibility-testing
- Game Accessibility Guidelines: https://gameaccessibilityguidelines.com/full-list/
