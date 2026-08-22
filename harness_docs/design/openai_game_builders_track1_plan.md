# OpenAI Game Builders Seoul Track 1 대응 계획

작성 기준: 2026-08-23 KST

## 목표

공식 심사축인 Playability, Originality, Codex Collaboration, Release Potential, Presentation에 맞춰 기존 수직 프로토타입을 브라우저에서 즉시 이해하고 플레이할 수 있는 공모전 빌드로 발전시킨다. 기존 프로젝트를 사용하는 만큼 챌린지 기간에 새로 개발한 기능은 별도 manifest로 구분한다.

공식 근거:

- [Track 1 진행·제출·심사 기준](https://openaigame2026.com/#apply:track-1)
- [OpenAI harness engineering](https://openai.com/index/harness-engineering/)
- [WCAG 2.2 드래그 대체 입력](https://www.w3.org/WAI/WCAG22/Understanding/dragging-movements.html)
- [WCAG 2.2 색상 단독 의존 금지](https://www.w3.org/WAI/WCAG22/Understanding/use-of-color.html)
- [Hive SDK 공식 모듈](https://developers.withhive.com/HTML/v4_api_reference_en/Unity3D/modules.html)

## 구현 순서

1. 캠페인 저장과 분리된 60초 핵심 체험
2. 공이 얻은 속성과 원본이 잃은 속성의 동시 피드백
3. 첫 화면의 행동 수와 설명을 진행도에 따라 점진적으로 공개
4. 사람의 재미 목표 → Codex 후보 → Validator 반려/통과 → 사람 채택을 보여 주는 Puzzle Forge
5. 챌린지 기간 신규 개발 기능 manifest와 제출용 16:9 썸네일
6. 검증된 짧은 일일 변주와 향후 Hive 서비스 어댑터 경계
7. 핵심 제출 경로의 한국어·영어 UI와 PC·모바일 반응형 구성
8. 비정상 입력·저장 손상·다중 화면·브라우저 회귀

3분 영상은 사용자 요청에 따라 이 반복에서 제작하지 않는다.

## 60초 핵심 체험 계약

- 저장·로그인·메뉴 탐색 없이 홈 최상위 행동에서 시작한다.
- 실제 생산 패턴과 ShotResolver를 사용한다.
- `무거움 이전 → 비워진 원본 → 남은 공 재사용`의 세 장면을 고정 순서로 제공한다.
- 캠페인 진행, 보상, 발견, 리플레이 기록을 변경하지 않는다.
- 첫 입력 전 자동 클리어 상태가 없어야 한다.
- 각 장면에서 현재 순서, 단일 목표, 다음 행동을 짧게 표시한다.
- 320×568, 390×844, 768×1024, 1440×900 이상의 홈에서 핵심 진입을 가리지 않는다.

## 후속 품질 계약

- 속성 변화는 색뿐 아니라 형태·무늬·문구·Semantics로 구분한다.
- 드래그 조준에는 키보드와 버튼식 각도·힘 조절 대안을 유지한다.
- Web 심사 빌드는 로그인을 요구하지 않는다.
- Hive는 Flutter의 로컬 DB 패키지와 혼동하지 않도록 외부 게임 플랫폼 서비스 어댑터 뒤에 둔다.
- 실제 Flutter Web용 Hive SDK를 확인하기 전에는 연동 완료로 표현하지 않는다.
- 에이전트 대리 플레이는 비정상 입력과 발견 가능성 회귀에만 사용하고 실제 재미 검증을 대체하지 않는다.
