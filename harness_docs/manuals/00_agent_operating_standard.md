# 에이전트 공통 운영 표준

## 목적

`속성 한방`의 모든 에이전트가 같은 기준으로 조사하고, 제안하고, 검증하고, 인계하도록 한다. 이 문서는 역할 매뉴얼보다 우선하는 작업 계약이다.

## 작업 순서

1. `README.md`, `harness_docs/readme.md`, `harness_docs/agents/current_shared_context.md`, 관련 규칙·결정·QA 문서를 읽는다.
2. 이 매뉴얼과 자신의 역할 매뉴얼, 역할 참고자료 색인을 읽는다.
3. 목표·범위·비협상 규칙·현재 기준 수치를 기록한다.
4. 외부 참고자료를 확인하고 링크, 확인일, 적용할 원칙을 남긴다.
5. 독립 진단과 제안을 작성한다. 제안은 최대 5개이며 문제·근거·효과·검증법을 포함한다.
6. 동료 검토 후 승인된 1~3개만 구현한다.
7. 기능·시각·접근성·성능·회귀 검증을 수행한다.
8. 변경사항을 작업 단위로 commit하고 push하며, 최신 데모 서버를 이전 서버 종료 후 교체한다.

## 공통 범위

- 순수 Dart 결정론 판정과 Flame 렌더링·연출의 분리.
- 한글 UI, 단일 탑뷰, 고정 벽, 홀 포획 우선, 실제 충돌 뒤 연쇄 이동.
- 무거움·탄성·점착·뾰족함과 풍선·가시·젤리·점착판·문·스위치의 일관된 의미.
- 기존 3단계를 보존하고 신규 기믹은 대체 풀이를 남긴다.

## 공통 금지사항

- 증거 없이 “완료”, “정확”, “상용 가능”이라고 단정하지 않는다.
- 물리 판정에 시각 애니메이션이나 프레임 타이밍을 사용하지 않는다.
- 벽을 이동시키거나 닫힌 문을 통과시키거나 홀 뒤 벽을 먼저 처리하지 않는다.
- 색상만으로 상태를 전달하지 않는다.
- 원문 프롬프트·결과물·역사 기록을 덮어쓰지 않는다.
- 출처·라이선스가 불명확한 이미지·음원·폰트를 추가하지 않는다.

## 활성화 게이트

작업 시작 전에 `harness_docs/agents/activation_gate_2026-08-03.md`의 역할별 기록을 채운다. 역할 매뉴얼, 프로젝트 문서, 외부 참고자료, 현재 범위, 비범위, 동료 검토 항목 중 하나라도 확인하지 않았으면 제안을 승인하지 않는다.

## 공통 인계 형식

```text
문제:
관찰 증거:
제안:
핵심 가치:
부작용·권리·접근성 위험:
변경 파일:
검증 명령과 결과:
동료에게 확인받을 질문:
commit/push:
```

## 참고자료

- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
- Apple Designing for games: https://developer.apple.com/design/human-interface-guidelines/designing-for-games/
- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- Flutter accessibility: https://docs.flutter.dev/ui/accessibility
- Flame components: https://docs.flame-engine.org/latest/flame/components/components.html
- Flame effects: https://docs.flame-engine.org/latest/flame/effects/effects.html
