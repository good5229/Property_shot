# 역할별 외부 참고자료 색인

확인일: 2026-08-03 KST

| 역할 | 참고자료 | 적용할 원칙 |
|---|---|---|
| 게임 디렉터 | [Apple Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games/), [Apple onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding) | 게임 목표를 먼저 보이고 점진적으로 학습시킨다. |
| 게임 아트 디렉터 | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines), [Material content design](https://m3.material.io/foundations/content-design/overview) | 시각 언어와 콘텐츠 구조를 일관되게 유지한다. |
| 오브젝트 아티스트 | [Flame components](https://docs.flame-engine.org/latest/flame/components/components.html), [Flame effects](https://docs.flame-engine.org/latest/flame/effects/effects.html) | 상태별 이미지와 시간 기반 효과를 분리한다. |
| 테크니컬 아티스트 | [Flame priority/components](https://docs.flame-engine.org/latest/flame/components/components.html), [Flame post-processing](https://docs.flame-engine.org/latest/flame/rendering/post_processing.html) | z-order와 후처리 비용을 명시한다. |
| UX 라이터 | [Apple writing](https://developer.apple.com/design/human-interface-guidelines/writing), [Microsoft writing tips](https://learn.microsoft.com/en-us/style-guide/global-communications/writing-tips), [step-by-step](https://learn.microsoft.com/en-us/style-guide/procedures-instructions/writing-step-by-step-instructions) | 짧고 직접적인 한 단계 지시를 쓴다. 영어 규칙을 한국어에 기계적으로 복사하지 않는다. |
| 게임 UX 디자이너 | [Apple game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls), [Material states](https://m3.material.io/foundations/interaction/states/overview) | 입력 상태·피드백·결과를 구분한다. |
| 퍼즐·레벨 디자이너 | [Apple Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games/), [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/) | 학습·도전·대체 풀이와 상황별 도움을 함께 설계한다. |
| 시스템 디자이너 | [Apple Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games/), [Flame components](https://docs.flame-engine.org/latest/flame/components/components.html) | 규칙·보상·상태 전이를 작게 유지한다. |
| 물리 엔지니어 | [Flame components](https://docs.flame-engine.org/latest/flame/components/components.html), [Apple game controls](https://developer.apple.com/design/human-interface-guidelines/game-controls) | 엔진 렌더 구조와 입력을 물리 판정과 분리한다. 게임별 수식은 프로젝트 테스트가 최종 근거다. |
| VFX·모션 | [Flame effects](https://docs.flame-engine.org/latest/flame/effects/effects.html), [WCAG animation](https://www.w3.org/TR/WCAG22/#animation-from-interactions) | 실제 이벤트 뒤에 연출하고 감소 모션을 제공한다. |
| 오디오·햅틱 | [Apple accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility/), [IGDA GASIG](https://igda-gasig.org/) | 소리가 없어도 상태를 알 수 있게 한다. |
| QA | [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing), [WCAG 2.2](https://www.w3.org/TR/WCAG22/) | 자동·수동·보조기술 검증을 구분해 증거화한다. |
| 접근성 | [WCAG contrast](https://www.w3.org/TR/WCAG22/#contrast-minimum), [non-text contrast](https://www.w3.org/TR/WCAG22/#non-text-contrast), [target size](https://www.w3.org/TR/WCAG22/#target-size-minimum), [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) | 색상·소리·동작에 의존하지 않는 대체 정보를 제공한다. |
| 성능 | [Flame post-processing](https://docs.flame-engine.org/latest/flame/rendering/post_processing.html), [Flame effects](https://docs.flame-engine.org/latest/flame/effects/effects.html) | 후처리·이펙트·연쇄 계산 비용을 별도로 측정한다. |
| 제품 평가 | [Apple Design Awards](https://developer.apple.com/design/awards/), [Apple Designing for games](https://developer.apple.com/design/human-interface-guidelines/designing-for-games/) | 첫인상·완성도·핵심 가치로 독립 평가한다. |
| 라이선스 | [CC Chooser](https://creativecommons.org/chooser/), [CC licenses](https://creativecommons.org/share-your-work/use-remix/cc-licenses/), [Kenney support](https://kenney.nl/support), [OpenGameArt FAQ](https://opengameart.org/content/faq) | 상업 이용·수정·표시·ShareAlike·개별 자산 조건을 확인한다. |
| Git·릴리스 | [Git documentation](https://git-scm.com/doc), [Flutter Web build](https://docs.flutter.dev/platform-integration/web/building) | 검증된 commit과 번들을 연결한다. |

## 해석 원칙

외부 문서는 일반 설계 원칙의 참고자료이고 게임별 최종 판정은 저장소의 결정론 테스트·Golden·QA 증거다. 특히 WCAG 수치는 법률 자문이 아니라 설계·검증 기준으로 사용한다.

## 최신 웹 검증

2026-08-03 KST에 Apple HIG, Flutter 접근성, Flame 컴포넌트·효과·후처리, Creative Commons 라이선스 페이지를 다시 확인했다. 페이지의 현재 적용 원칙과 역할별 연결은 [웹 참고자료 재검증 기록](web_reference_verification_2026-08-03.md)에 정리했다. 링크가 갱신되거나 역할 범위가 바뀌면 해당 기록과 매뉴얼의 `참고자료` 절을 함께 갱신한다.
