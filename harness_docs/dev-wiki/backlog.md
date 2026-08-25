# Dev-Wiki Backlog

GitHub Issues own task status. This file owns planning context.

## How To Use

- Prefer one issue = one branch = one PR.
- Record issue / branch / PR linkage in each active entry.
- Let the owner decide merge order unless a project explicitly delegates it.

## Merge Order

- _(empty)_

## Active Queue

- [x] 시작 공 주변 벽 여유 공간 표준화
  - branch: codex/spawn-wall-clearance
  - issue: 없음
  - summary: 전체 생산 패턴과 60초 핵심 체험에서 시작 공 주변 벽의 최소 시각·물리 여유를 보장한다.
  - notes: StagePatternValidator에 내부 벽·닫힌 문 최소 여유 24(공 한 지름)와 `ball_spawn_too_close_to_wall` 계약을 추가했다. 생산 40패턴 최솟값 24.12, 무충돌 직행 0개, 5단계 기믹 우위 1.61, 전체 테스트 1,468개 통과를 확인했다. 기존 제출용 PPT/PDF와 보고서 생성 스크립트의 미커밋 변경은 스테이징하지 않고 보존한다.

- [x] OpenAI Game Builders 심사 준비 릴리스
  - branch: codex/judge-ready-release
  - issue: 없음
  - summary: 첫 3분 심사 경로, 역할별 세션 평가기, 최신 Web 품질 게이트, 통합 피날레, 사운드 패스, 제출 패키지를 순차 완성한다.
  - notes: 접수 마감 직전 범위이므로 신규 재화·온라인 기능보다 심사자가 설명 없이 코어 재미와 복구 보상을 확인하는 흐름을 우선한다. 각 단계는 독립 검증·커밋하며 기존 제출용 PPT/PDF와 보고서 생성 스크립트의 미커밋 변경은 스테이징하지 않고 보존한다. 실제 사람의 재미는 에이전트 세션 평가로 입증했다고 표현하지 않는다.
  - progress:
    - [x] 첫 3분 심사 경로와 자동 합격 계약
    - [x] 로컬 세션 역할별 평가기
    - [x] 최신 Web 성능·접근성 릴리스 게이트
    - [x] 복구 시설 통합 피날레
    - [x] 재질·복구 상태 기반 사운드 패스
    - [x] 16:9 썸네일과 제출 패키지 동결

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

- [x] 첫 10분 상용 수직 슬라이스 고도화
  - branch: codex/commercial-first-ten-minutes
  - issue: 없음
  - summary: 역할별 대리 플레이 증거를 바탕으로 첫 3스테이지 학습 계약, 물리 강도 기반 피드백, 생산 40패턴 의도 경로 검증, 전 해상도 콘솔 밀도, 복구 지원 추천을 순차 개선했다.
  - notes: 기능별 독립 커밋과 집중 검증 후 전체 1,441개 테스트, 정적 분석, 생산 40패턴 런타임 검증, 358개 Golden, Web Release 빌드를 통과했다. 전체 회귀에서 발견한 반응형 엔티티 탭 차단과 390px 지도 첫 항해 가시성 회귀도 수정한 뒤 처음부터 재검증했다. 대리 플레이 평가는 실제 사람의 재미 검증으로 표현하지 않으며, 기존 제출용 PPT/PDF와 보고서 생성 스크립트의 미커밋 변경은 범위 밖으로 보존했다.
  - progress:
    - [x] 역할별 에이전트 대리 플레이 평가
    - [x] 첫 3스테이지 학습 목적과 조준 허용폭 재구성
    - [x] 충돌·성공 피드백과 저모션 대응 고도화
    - [x] 생산 40패턴 지름길·기믹 우회 전수 감사
    - [x] 전 해상도 시각 일관성 검수
    - [x] 복구 시설의 반복 플레이 선택 가치 강화

- [x] 난도·학습·반복 루프 튜닝
  - branch: codex/difficulty-learning-loop
  - issue: 없음
  - summary: Stage 10 런타임 증거 공백, 과난도 탄성 패턴, 캠페인 학습 파동, 보드 위 실패 학습 표식, 복구 시설 주간 목표를 순차 구현했다.
  - notes: 다섯 기능 커밋을 각각 집중 검증한 뒤 전체 1,426개 테스트, 정적 분석, 생산 40패턴 런타임 검증, 생성본 동기화와 Web Release 빌드를 통과했다. 기존 제출용 PPT/PDF와 보고서 생성 스크립트의 미커밋 변경은 범위 밖으로 보존했다.

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
