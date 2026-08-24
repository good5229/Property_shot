# Dev-Wiki Backlog

GitHub Issues own task status. This file owns planning context.

## How To Use

- Prefer one issue = one branch = one PR.
- Record issue / branch / PR linkage in each active entry.
- Let the owner decide merge order unless a project explicitly delegates it.

## Merge Order

- _(empty)_

## Active Queue

- [ ] 난도·학습·반복 루프 튜닝
  - branch: codex/difficulty-learning-loop
  - issue: 없음
  - summary: Stage 10 런타임 증거 공백을 닫고, 가상 플레이에서 과도한 난도로 분류된 패턴을 조정하며, 캠페인 난도 곡선·시각적 실패 학습·복구 시설과 개인 기록의 반복 동기를 순차적으로 강화한다.
  - notes: 기존 제출용 PPT/PDF와 보고서 생성 스크립트의 미커밋 변경은 범위 밖으로 보존한다. 새 모드·화폐·외부 자산은 추가하지 않고, 결정론적 물리·기믹 우위·보정 선택권을 유지한다.
  - progress:
    - [x] Stage 10 런타임 대표 해법·무보상 경로 증거 동기화
    - [x] 과도한 난도 패턴 조정과 가상 플레이 임계 검증
    - [x] 학습→확인→응용→숙련 캠페인 난도 곡선
    - [ ] 보드 위 첫 이탈·첫/마지막 충돌 실패 학습 피드백
    - [ ] 복구 시설·개인 기록 주간 목표와 상태 가시화
    - [ ] 전체 검증·커밋·푸시·배포

- [x] OpenAI Game Builders Seoul Track 1 대응
  - branch: main (사용자 요청으로 별도 브랜치 없음)
  - issue: 없음
  - summary: 60초 핵심 체험, 양면 속성 변화, 점진적 홈 공개, Codex Puzzle Forge, 챌린지 신규 개발 설명, 검증된 반복 변주, 한·영 UI와 반응형 시연 구성을 기능별로 구현한다.
  - notes: 3분 영상 제작은 사용자 요청으로 보류한다. 각 기능은 관련 테스트와 정적 분석을 통과한 뒤 독립 커밋하고 즉시 push한다. 기존 게임소개서 PPT/PDF 미커밋 변경은 소유 범위 밖이므로 스테이징하지 않고 보존한다.
  - progress:
    - [x] 캠페인 저장과 분리된 60초 핵심 체험과 대표 3장면
    - [x] 속성 강탈의 양면 효과 강화
    - [x] 첫 화면·설명 단순화와 점진적 공개
    - [x] Codex Puzzle Forge와 역할·반려 증거 시각화
    - [x] 챌린지 기간 신규 개발 내역과 제출용 자료
    - [x] 검증된 일일 변주와 Hive 확장 경계
    - [x] 핵심 체험 한·영 UI와 PC·모바일 반응형 구성
    - [x] 비정상 입력·저장 손상·브라우저 회귀와 최종 감사

- [ ] 상용 수직 슬라이스 고도화
  - branch: commercial/wall-physics-qa
  - issue: 없음
  - summary: 대표 무거움 스테이지의 보드·오브젝트·조준 UI·실패 피드백을 개선하고 첫 3스테이지의 난이도와 속성 선택을 재검증한다.
  - notes: 결정론적 물리와 기존 테스트를 보존한다. 복사 자원의 최종 모델은 사용자 결정 전까지 확정하지 않는다.

## Recently Closed

- [x] 반복 플레이·섬 지원 확장
  - branch: codex/island-progression
  - issue: 없음
  - summary: 패턴별 해법 도장과 공유 카드, 직전 성공 조준 비교, 실패 다음 실험, 복구 시설 집중 지원, 창의 탐사를 추가했다.
  - notes: 집중 지원은 한 런에서 최초 선택 하나만 적용하며, 손상·과도한 저장값과 변조된 공유 코드는 안전하게 거부한다.

- [x] 건강한 몰입 루프 1~6 고도화
  - branch: codex/engagement-loop
  - issue: 없음
  - summary: 발견 영구 저장, 실패 재도전 비교, 2단계 성공 폭, 개별 도움 설정, 보상 활용 안내, 3스테이지 탐사 계약을 순차 구현했다.
  - notes: 각 항목을 집중 회귀 검수 뒤 독립 커밋했고, 통합 증거 갱신과 Web 빌드를 검증한 뒤 원격 브랜치에 push했다. 사용자 요청에 따라 후반 기믹 미리보기는 제외했다.

## Cross-Issue Themes

- _(empty)_

<!-- **`docs/dev-wiki/backlog.md`**
```md
# Dev-Wiki Backlog

GitHub Issue가 있으면 상태 관리는 Issue를 기준으로 하고, 이 문서는 작업 맥락과 메모를 정리하는 용도로 사용한다.

## How To Use

- 가능하면 작업 1개당 이슈 1개, 브랜치 1개, PR 1개로 맞춘다.
- 작업을 시작할 때 Active Queue에 적는다.
- 작업이 끝나면 Recently Closed로 옮긴다.
- 중요한 결정이나 의존성은 짧게 메모한다.

## Merge Order

- 현재 없음

## Active Queue

- [ ] harness 초기 적용
  - branch: 없음
  - issue: 없음
  - summary: 로컬 운영 하네스 구조를 프로젝트에 적용하고 기본 문서를 초기화한다.
  - notes: AGENTS.md, docs/index.md, docs/dev-wiki/contract.md를 먼저 기준 문서로 사용한다.

- [ ] testing.md 초기 설정
  - branch: 없음
  - issue: 없음
  - summary: 이 프로젝트의 실제 테스트 명령과 확인 절차를 `docs/rules/testing.md`에 반영한다.
  - notes: 사용 언어/프레임워크에 맞는 명령으로 교체 필요

- [ ] knowledge 문서 초기 작성
  - branch: 없음
  - issue: 없음
  - summary: 프로젝트 목적, 구조, 주의사항을 `docs/knowledge/`에 정리한다.
  - notes: 새 세션에서 AI가 빠르게 이해할 수 있도록 핵심만 먼저 작성

## Recently Closed

- 없음

## Cross-Issue Themes

- 프로젝트 규칙 정리
- 테스트 방식 표준화
- 반복 설명 줄이기 -->
