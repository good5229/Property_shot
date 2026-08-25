# 충돌·로딩·스테이지·복구 보상 통합 QA

검수일: 2026-08-26

## 검수 범위

- 3~N중 충돌에서 이동·재질 변형·효과음·진동이 같은 프레임에 몰리는 문제
- 첫 화면 준비가 2초 이상 걸릴 때 빈 화면처럼 보이는 문제
- 60초 핵심 체험과 생산 40패턴의 시작 공 주변 안전영역, 기물 겹침, 무기믹 직선 우회
- 관측소·등대·다리의 해금 조건과 실제 플레이 지원 연결
- 모바일·태블릿·PC·대형 PC의 배치 기준 이미지와 비정상 입력 회귀

## 역할별 감사와 공통 원인

| 역할 | 주요 발견 | 공통 원인 | 조치 |
|---|---|---|---|
| 성능·물리 | 같은 물리 path index의 연쇄 충돌이 한 표시 프레임에 압축되고, 기물 위치와 재질 변형이 서로 다른 시간축을 사용함 | 물리 판정 순서와 화면 표시 순서를 같은 cursor로 사용 | 물리 기록은 유지하고 별도 presentation timeline을 컴파일했다. 실제 이동 거리 기반 재생 시간, 최소 충돌 beat, 샷 단위 조회 캐시를 적용했다. |
| UI·운영 | 로딩 중 진행 상태가 없고 bootstrap 실패 뒤 사용자가 회복할 방법이 없음 | Flutter 첫 프레임 전 제품 UI 부재 | 엔진 준비·기록 로드·첫 화면 렌더 상태, 진행 표시, 저모션, 오류 alert, 다시 시도 행동을 HTML/bootstrap 단계에 추가했다. |
| 레벨·보상 | 일부 패턴은 공 주변 기물이 가깝거나 직선 통로가 열리고, fixture와 기준 이미지가 새 배치와 어긋남 | 과거 개별 배치·고정 좌표 검증에 의존 | 전 40패턴에 72px 시작 여백, shape-aware 겹침, 직선 통로 차단, 기믹 성공 영역 우위 계약을 적용하고 대표 입력·리플레이·기준 이미지를 실제 resolver 결과로 갱신했다. |
| 시설 효과 | 기능 구현은 존재했으나 세 시설의 해금·추천·집중 지원·중복 지급을 함께 확인하는 통합 근거가 필요함 | 기능별 테스트가 흩어짐 | 15개 발견 실제 진입 상태에서 관측소 분석, 등대 L1·조준 지원, 다리 런당 복제 코어가 연결되는 통합 회귀를 포함해 16건을 재검증했다. |

초기 독립 검수에서 나온 P1은 모두 해소했다. 생성 기믹 Golden 불일치는 의도한 새 배치를 직접 확인한 뒤 기준 이미지를 갱신했고, 회전판·탐사·위젯 테스트의 과거 고정 좌표는 실제 활성 공과 presentation 구간을 읽도록 바꿨다. Sol 최종 검수에서 데이터 직사각형보다 크게 그려지는 4단계 `?` 상자와 풍선의 6.37px 시각 겹침을 추가로 발견했다. Canvas와 감사가 같은 미리보기 크기 함수를 사용하게 하고 8px 시각 여백을 검사하며, 해당 배치를 실제 간격 9.34px·12.34px로 분리했다. 과거 좌표는 겹침으로 검출하는 회귀로 보존했다. 최종 Terra와 Sol 재검수는 P0/P1 없음으로 판정했다.

## 자동 합격 계약

- 생산 40패턴은 발사 전 `planning`, 0발, 홀 밖 상태다.
- 공 중심에서 모든 활성 기물까지 최소 72px, 즉 공 지름 3배를 비운다.
- 서로 다른 두 시각 요소가 시작 시 겹치지 않는다.
- 공에서 홀까지 열린 직선 통로를 허용하지 않는다.
- 기믹 사용 성공 영역은 무기믹 우회보다 패턴별 최소 1.4배 넓다. 연쇄 점수 패턴은 최소 1.3배다.
- 젤리 속성은 동일 충돌 입력에서 무속성보다 이동 경로가 네 패턴 모두 길다.
- 3·5·8·12중 연쇄 충돌은 30·45·60 FPS와 불규칙 프레임에서 사건을 한 번씩만 재생하고 표시 프레임에 압축하지 않는다.
- bootstrap 성공은 Flutter 첫 프레임 뒤 로딩 UI를 한 번 제거하고, 엔진 또는 외부 bootstrap 실패는 접근 가능한 alert와 다시 시도를 유지한다.

## 검증 결과

- `flutter test --concurrency=1`: 1,483건 통과
- `flutter analyze`: 이슈 0건
- `flutter build web --release --wasm`: 성공
- `git diff --check`: 통과
- 320×568부터 1920×1080까지 갱신된 기준 이미지 포함 전체 Golden 통과
- 로컬 Wasm 릴리스 브라우저: 홈과 60초 핵심 체험 진입 성공, console warning/error 0건
- 40패턴 시작 상태·72px 여백·겹침·직선 우회·기믹 우위 통과
- 관측소·등대·다리 모델·저장·추천·지도 UI·실제 게임 연결 통과

## 참고 기준

- Flutter의 프레임 예산·렌더링 성능: <https://docs.flutter.dev/perf/rendering-performance>
- Flutter Web 초기화 수명주기: <https://docs.flutter.dev/platform-integration/web/initialization>
- `requestAnimationFrame`의 화면 갱신 동기화: <https://developer.mozilla.org/en-US/docs/Web/API/Window/requestAnimationFrame>
- 긴 애니메이션 프레임 관측: <https://developer.mozilla.org/en-US/docs/Web/API/Performance_API/Long_animation_frame_timing>
- 입력 실수 방지와 복구: <https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/115>
- 퍼즐의 teach-test-twist와 pacing: <https://book.leveldesignbook.com/process/preproduction/pacing>

## 남은 한계

- 자동 테스트와 headless/로컬 브라우저는 실제 사람의 충돌 체감이나 모든 저사양 실기기의 프레임 시간을 대체하지 않는다.
- 탄성 패턴 일부의 대표 입력 근방 성공점은 15점 중 4~5점으로 자동 기준은 넘지만 터치 흔들림에는 상대적으로 좁다. 배포 후 실제 실패율과 재시도율을 수집해 넓힐 후보로 유지한다.
- 세션 단위 포기·재도전·보상 사용·입력 보정 효과를 함께 판정하는 텔레메트리 회귀는 후속 운영 QA 항목이다.
