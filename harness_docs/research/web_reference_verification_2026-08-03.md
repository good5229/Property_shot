# 역할 매뉴얼 웹 참고자료 재검증

확인일: 2026-08-03 KST

## 검증 방법

역할 매뉴얼의 링크를 공식 문서 또는 원저작자·라이선스 기관 페이지와 대조했다. 외부 문서는 일반 원칙의 근거로만 사용하며, 게임 규칙과 성공 판정은 저장소의 결정론 테스트가 최종 기준이다.

| 영역 | 재확인한 공식 자료 | 매뉴얼 적용 |
|---|---|---|
| 게임 설계·조작 | [Apple Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games/), [Game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls) | 직접 조작, 터치 영역, 누름 상태, 색상 외 정보 |
| 문구·온보딩 | [Apple Writing](https://developer.apple.com/design/human-interface-guidelines/writing), [Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding), [Microsoft writing tips](https://learn.microsoft.com/en-us/style-guide/top-10-tips-style-voice) | 짧은 행동 지시, 한 번에 하나의 목표, 비난 없는 실패 |
| 접근성 | [Flutter accessibility](https://docs.flutter.dev/ui/accessibility), [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing), [WCAG 2.2](https://www.w3.org/TR/WCAG22/) | Semantics, 터치 영역, 대비, 색상 외 상태 정보 |
| 게임 렌더링·연출 | [Flame components](https://docs.flame-engine.org/latest/flame/components/components.html), [Flame effects](https://docs.flame-engine.org/latest/flame/effects/effects.html), [Flame post-processing](https://docs.flame-engine.org/latest/flame/rendering/post_processing.html) | 판정과 렌더 분리, 이벤트 기반 효과, 레이어·비용 관리 |
| 권리 | [Creative Commons Chooser](https://creativecommons.org/chooser/), [CC licenses](https://creativecommons.org/share-your-work/use-remix/cc-licenses/), [Kenney support](https://kenney.nl/support), [OpenGameArt FAQ](https://opengameart.org/content/faq) | 상업 이용·수정·표시·ShareAlike·개별 자산 조건 기록 |

## 역할별 연결

18개 매뉴얼은 각자의 `참고자료` 절에서 위 자료와 역할별 추가 링크를 연결한다. 작업자는 먼저 [역할 참고자료 색인](role_reference_index.md)을 확인하고, 외부 원칙을 Property Shot 체크리스트와 테스트 증거로 변환한다.

## 한계

공식 문서가 특정 게임의 물리 수식, 성공률, 상용 라이선스 승인 또는 실제 사용자 결과를 보장하지는 않는다. 그런 결론은 외부 문서에서 추론하지 않고 별도 QA·권리·플레이테스트 기록으로 분리한다.
