# UI·힌트·시연 난이도 최종 Sol 리뷰

작성 기준: 2026-08-10 KST
기준: `main` 배포 커밋 `69744c6d3183b4933817066f80221c2f8fd69630`, Pages run `31373105599`

## 판정

**CONDITIONAL GO**

코드·레벨·저장·Validator·접근성·Golden·Web/APK 빌드, 실제 60초 MOV와 변경판 GitHub Pages 배포는 제출 후보 수준의 자동·시각 증거를 확보했다. 그러나 iOS Simulator·실제 iPhone/iPad 성능, 외부 플레이테스트, 한 번에 전부 초록인 전체 회귀 실행은 아직 없다. 이 항목을 통과로 과장하지 않는다.

## 최종 질문별 답변

| 질문 | 판정 | 근거와 한계 |
|---|---|---|
| 모바일 첫 화면 하단이 더 이상 잘리거나 답답하지 않은가? | 자동·시각 PASS | 320×568, 375×812, 390×844, 393×852, 430×932, 768×1024, 1024×1366 전체 화면 Golden. compact 보상은 scroll fade와 SafeArea 고정 footer를 사용한다. 실제 노치 기기는 미검증이다. |
| 외부 레퍼런스에서 무엇을 참고하고 복제하지 않았는가? | PASS | Apple HIG, Flutter SafeArea·adaptive, Flame Camera/World, 공식 App Store 3종에서 안전 영역·HUD 계층·작은 화면 정보 축약 원칙만 채택했다. 고유 아트·화면·수치·해법은 복제하지 않았다. 상세는 `ui_hint_reference_research.md`에 기록했다. |
| 파워 게이지가 모바일·웹에서 즉시 인지되는가? | 자동·시각 PASS | 중앙 편향 부유 게이지, 초록·노랑·빨강·경고 점멸·회색, 단계명·아이콘·눈금·퍼센트 Semantics를 좌우와 320/390/768 Golden으로 확인했다. |
| 게이지가 조준·주요 기물을 방해하지 않는가? | 자동 PASS | 공·홀·풍선·상자·범퍼·점착·무거움·스위치·문·가시·파워 슬라이더·회전판·열쇠 회피 후보를 사용하고, stage4 풍선·slider·key 비중첩 Golden을 둔다. 후보 전부 충돌 시 최저 중첩 선택의 전수 실기기 검사는 남는다. |
| 시연 대표 패턴이 핵심 기믹을 보여 주는가? | PASS | `stage_bouncy_01` 실제 telemetry attestation이 탄성 이전, 48°·0.90 demo-only 발사, 벽 사용 4회, `directClear=false`, 열쇠, L1/L2를 증명한다. 최종 MOV는 60.000초·H.264/avc1·identity transform이고 대표 27프레임을 시각 검사했다. |
| 직선 대체 경로가 항상 최적해가 아닌가? | PASS | 40패턴 기믹 우위: 단발 32패턴 각각 1.40배 이상, 7단계 합계 1.92배, 8단계 점수 1.48–1.74배, 10단계 합계 36.67배. 우회는 남기되 더 좁거나 낮은 점수다. |
| 어려운 패턴의 L1/L2가 행동 방향을 주는가? | 자동 PASS | 40패턴 `HintCatalog v1`이 대상 기믹·위치·세기·순서·예상 결과를 제공한다. Validator가 추상 문구와 잘못된 대상 참조를 거부한다. 외부 초보자 이해도는 미검증이다. |
| 힌트가 정답 각도·파워 버튼인가? | PASS | 숫자 각도·퍼센트·완성 궤적을 카탈로그 Validator가 거부한다. demo-only 48°/90% 제어는 제품 힌트와 일반 UI에 노출되지 않는다. |
| 다음 스테이지 팁 보상이 확정 패턴과 연결되는가? | PASS | 다음 draw를 저장한 뒤 `stageId + patternId + hintVersion` 권한을 원자 지급한다. 재시작·선추첨 복구·중복 병합 테스트가 통과했다. 일일 도전에는 사용할 수 없는 dead reward를 제시하지 않는다. |
| 열쇠가 현재 스테이지 힌트를 해금하는가? | PASS | 공 경로의 결정론 접촉 → 저장 큐 승인 → 같은 패턴 entitlement → `팁 사용 가능` 순서다. 저장 전에는 VFX·잠금 해제를 확정하지 않는다. |
| 열쇠 획득 난이도가 부당하게 높지 않은가? | 자동 조건 PASS | demo key 대표 경로와 주변 입력 도달성, 보드/고체/홀 중첩 금지, 결정론 지문을 검사한다. 실제 사용자 획득률은 미검증이다. |
| 열쇠를 무시해도 클리어 가능한가? | PASS | 열쇠는 비물리 수집물이고 `ShotResolver` 충돌·점수·홀 판정에 들어가지 않는다. 기본 대표 클리어 fixture가 열쇠 없이 유지된다. |
| Validator가 잘못된 열쇠·힌트·직선 시연을 잡는가? | PASS | `invalid_key_unreachable`, `invalid_key_overlap`, `invalid_key_blocks_hole`, `invalid_hint_*`, `invalid_demo_direct_clear` fixture가 안정 오류 코드를 검출한다. |
| Validator 메타 테스트가 규칙 파손 시 실패하는가? | PASS | 누락·오참조·추상·정답 수치·L1/L2 위반·열쇠 배치·직선 clear 결함 변이를 실제 테스트한다. `invalid_hint_entitlement_restore`는 RunState 복원 경계에서 검증한다. |
| 화면 비율·FPS가 물리 결과에 영향을 주지 않는가? | 구조·자동 PASS | ShotResolver 입력은 viewport/HUD를 참조하지 않고 30/60/120Hz 결정론과 replay fingerprint를 유지한다. 실제 기기 GPU/FPS 교차 검사는 남는다. |
| 기존 10단계·셔플·RunState·리플레이와 충돌하지 않는가? | PASS | 생산 40패턴, 캠페인 전용 첫 baseline, daily 기존 shuffle, RunState v1/v2→v3, replay fixture·결정론 표적 회귀를 확인했다. |
| 전체 회귀와 release build가 통과하는가? | 조건부 | Web/APK release와 `flutter analyze`는 통과했다. 사용자 요청에 따라 전체 직렬 실행은 한 번만 수행했고 1,062건 중 997건 통과·65건 실패였다. 실패는 stale Golden 61장과 replay fixture로 분류·수정해 영향권 67/67, replay 9/9, 핵심 239/239를 재통과했지만 전체를 다시 한 번에 실행하지는 않았다. |
| 공개 배포·최종 제출 증거가 완료됐는가? | PASS | 커밋 `69744c6d…` push, Pages run `31373105599`, 공개 루트·번들 HTTP 200과 SHA-256, PDF/PPTX 렌더 및 최종 MOV 검증을 확인했다. |

## 최신 성능 대리 증거

2026-08-10 17:04 KST, 최신 Web release를 에이전트·빌드 작업이 없는 상태에서 각 뷰포트 3회 측정했다.

| 뷰포트 | 발사 p90 | 발사 p99 | 누락 | 50ms 초과 | Long Task | 콘솔 오류 |
|---|---:|---:|---:|---:|---:|---:|
| 390×844 | 17.2ms | 17.6ms | 0 | 0 | 0 | 0 |
| 768×1024 | 17.2ms | 17.6ms | 0 | 0 | 0 | 0 |

평균은 16.664–16.666ms였지만 p90 16.7ms 엄격 목표는 0.5ms 초과했다. 이는 Chromium rAF 대리값이며 실제 Flutter build/raster 또는 모바일 실기기 성능으로 확대하지 않는다.

## 제품 전체 GO 전 남은 게이트

1. iOS Simulator runtime 또는 실제 iPhone/iPad에서 SafeArea·화면 읽기·저모션·터치·프레임을 확인한다. 불가능하면 제출 범위를 명시하고 상용 `GO`가 아닌 `CONDITIONAL GO`를 유지한다.
2. 초보자 외부 플레이테스트로 힌트 이해도·열쇠 발견률·기믹 우회 발견률을 확인한다.
