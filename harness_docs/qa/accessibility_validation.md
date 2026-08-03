# 접근성 검증

## 확인한 항목

- 색상 외 실루엣·무늬·한글 상태 문구를 제공한다.
- 정보 팝업과 버튼에 역할별 Semantics 라벨을 제공한다.
- 팝업 뒤 입력을 차단하고 작은 화면에서 내용을 스크롤한다.
- 터치 대상·문구·대비는 Flutter 위젯 회귀와 Golden으로 확인한다.

## 참고 기준

[Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing), [WCAG 2.2](https://www.w3.org/TR/WCAG22/), [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)

## 잔여

VoiceOver·TalkBack의 실제 접근성 트리, Dynamic Type, reduced motion, 실기기 터치 크기는 장치 검증 전까지 미확정이다.
