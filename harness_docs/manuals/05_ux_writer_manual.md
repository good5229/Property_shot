# 게임 UX 라이터 매뉴얼

## 역할 목적

모든 화면 문구를 짧고 친절한 한글로 작성해 플레이어가 지금 할 일과 결과를 오해 없이 이해하게 한다.

## 업무와 산출물

- 한 번에 하나의 행동만 안내하고, 실패 문구는 비난 대신 다음 시도를 제시한다.
- 버튼은 행동을 말한다: `다음`, `다시 시도`, `속성 옮기기`, `닫기`, `처음부터 다시`.
- 산출물: `harness_docs/ux/copy_inventory.md`, `terminology_guide.md`, `copy_decision_log.md`.

## 사전 확인

영어 UI 금지, `무게추` 같은 오해 용어 제거, 긴 도움말 축약, 공·물체 클릭 팝업, 선택형 추가 도전과 필수 성공의 구분을 확인한다.

## 판단 기준

문구가 상태·행동·결과를 분리하고, 한 화면에서 가장 중요한 행동 하나가 먼저 보이며, 용어가 단계마다 바뀌지 않아야 한다.

## 나쁜 예와 좋은 예

- 나쁨: `공을 선택하고 속성을 이전한 다음 힘을 조절하여 목표에 도달해 보세요.`
- 좋음: `돌을 눌러 무거움을 확인하세요.` → `공을 길게 눌러 힘을 모으세요.`
- 나쁨: `실패했습니다.`
- 좋음: `홀을 조금 지나쳤어요. 힘을 줄여 다시 쏴 보세요.`

## 하지 말 것

영어 표현, 긴 툴팁, 색상만 설명하는 문구, 플레이어를 탓하는 문구, 실제 온라인 통계처럼 보이는 데모 기록을 쓰지 않는다.

## 협업·완료

UX 디자이너가 문구의 표시 위치와 순서를 확인하고 접근성 검토자가 읽기·스크린리더 순서를 확인한다. 모든 문자열에 상태·행동·대체 문구·검증 결과가 있으면 완료다.

## 참고자료

- Apple Writing: https://developer.apple.com/design/human-interface-guidelines/writing
- Apple Onboarding: https://developer.apple.com/design/human-interface-guidelines/onboarding
- Material content design: https://m3.material.io/foundations/content-design/overview
- Microsoft 짧고 명확한 문장: https://learn.microsoft.com/en-us/style-guide/global-communications/writing-tips
- Microsoft 단계별 지시: https://learn.microsoft.com/en-us/style-guide/procedures-instructions/writing-step-by-step-instructions
