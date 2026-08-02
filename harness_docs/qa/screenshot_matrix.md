# 스크린샷 검증 매트릭스

## 목표 해상도

| 해상도 | 홈 | 지도 | 플레이 | 결과 | 상태 |
| --- | --- | --- | --- | --- | --- |
| 390×844 | 확인 | 확인 | 확인 | 확인 | 최신 Web release 실제 입력·콘솔 오류 0건, 속성 이전·조준·발사·클리어까지 실행 |
| 393×852 | 확인 | 미확인 | 확인 | 미확인 | 최신 플레이 캡처와 보드·HUD 경계 확인 |
| 430×932 | 확인 | 미확인 | 확인 | 미확인 | 최신 플레이 캡처와 보드·HUD 경계 확인 |
| 768×1024 | 확인 | 미확인 | 확인 | 미확인 | 최신 태블릿 플레이 캡처, 실제 발사 입력은 별도 미검증 |
| 1024×1366 | 확인 | 미확인 | 확인 | 미확인 | 최신 태블릿 플레이 캡처, 보드 중앙 배치와 하단 컨트롤 확인 |
| 데스크톱 Web | 확인 | 확인 | 확인 | 확인 | 최신 1024×1366 보조 실행 기준, 데스크톱 전용 성능은 별도 미검증 |

## 판정 기준

- 게임 보드가 화면의 주인공이고 거대한 빈 여백이 없다.
- Safe Area 밖에 HUD·버튼·팝업이 나가지 않는다.
- 한글 문장이 잘리지 않고 버튼 텍스트가 부모 밖으로 넘치지 않는다.
- 공·홀·속성 물체·충돌면을 장식이 가리지 않는다.
- 결과 화면에서 다음과 재도전이 실제로 보이고 탭할 수 있다.
- 홈·플레이의 공 표현과 조명·테마가 이어진다.

현재 최신 코드 기준 캡처는 다음 구현 단위에서 각 크기로 생성하고 파일 경로와 실행 명령을 기록한다. 이전 Web 스크린샷은 새 홈·플레이의 증거로 재사용하지 않는다.

## 2026-08-02 최신 화면 캡처

- `390x844-home.png`, `390x844-map.png`, `390x844-play.png`, `390x844-result.png`는 같은 최신 Web release에서 다시 생성했다.
- `390x844-play.png`는 속성 이전 후 방향 조정과 힘 충전 발사를 실제로 실행한 제품 경로 캡처다.
- `390x844-result.png`는 첫 단계 실제 클리어 후 저장했다. 결과 패널은 고정 전체 높이가 아니라 콘텐츠·버튼 중심의 제한 높이로 표시된다.
- `393x852-play.png`, `430x932-play.png`, `768x1024-play.png`, `1024x1366-play.png`는 최신 release의 실제 시작 흐름으로 생성했다. 1024×1366은 시작 버튼 좌표를 별도로 확인한 뒤 캡처했다.
- 모든 캡처 실행에서 브라우저 콘솔 오류는 0건이었다. 393·430·768·1024 화면은 브라우저 렌더링 확인이며 실제 기기 터치·프레임 측정 증거로 해석하지 않는다.

## 2026-08-02 최신 벽·조준·축약 HUD 캡처

- `390x844-hud-background-after.png`: 한 줄 목표, 산호색 탄성 조준 리본, 해안선·모래결·조개 장식을 확인했다.
- `768x1024-hud-background-after.png`: 축약 HUD와 넓은 보드가 겹치지 않고, 조준 리본·벽 판재·홀 깃발이 식별된다.
- `390x844-material-aim-play.png`, `430x932-material-aim-play.png`, `768x1024-material-aim-play.png`: 벽 재질과 조준 리본 변경 전후 비교용 캡처다.
- `390x844-material-source-popup.png`: 최신 390px 빌드에서 무거운 돌 상세 팝업을 실제 탭으로 열었다.
- `390x844-material-transfer-after.png`: 상세 팝업의 `떼어 공에 옮기기`를 실제 탭한 뒤 공의 무거움 상태와 안내 문구를 확인했다.
- 최신 브라우저 실행은 390×844·430×932·768×1024에서 콘솔 오류 0건이었다. 이 캡처들은 Web 상호작용 증거이며 실제 iPhone/iPad 프레임·GPU·메모리 증거가 아니다.

## 2026-08-02 Canvas 표면 마감 캡처

- `390x844-canvas-finish-play.png`: 390px Chromium 뷰포트에서 첫 시작 버튼을 좌표 입력해 플레이 화면에 진입한 뒤 저장했다. 벽의 상단 광원·하단 음영·압출면과 공·홀·상자·돌의 시각 위계를 확인했다.
- `390x844-canvas-finish.png`, `768x1024-canvas-finish.png`: 최신 Web release 홈 화면의 모바일·태블릿 배치와 해변 배경 연결을 확인했다. 768×1024 플레이 물체 배치는 별도 캡처가 필요하다.
- 해당 플레이 캡처의 브라우저 콘솔 오류는 0건이다. WebKit 런타임이 설치되지 않아 Chromium 뷰포트를 사용했으며, 실제 기기 렌더링 증거로 해석하지 않는다.

## 2026-08-02 래스터 표면 마감 캡처

- `390x844-raster-finish-play.png`: 첫 단계 실제 플레이 화면에서 돌·상자 래스터 에셋과 벽 Canvas 도형의 광원·하단 음영·접지감을 비교했다.
- `768x1024-raster-finish-play.png`: 768px 실제 플레이 화면에서 보드 점유율, HUD, 공·돌·상자·홀의 시각 위계를 확인했다.
- 두 캡처 모두 시작 입력 뒤 브라우저 콘솔 오류는 0건이다. Chromium 뷰포트 검증이며 실제 iPhone/iPad 렌더링·성능 증거로 해석하지 않는다.

## 2026-08-02 하단 해변 세계 연결 캡처

- `390x844-shore-detail-play.png`: 하단 모래 영역의 조수 웅덩이·잎사귀·불가사리 장식이 HUD와 입력 영역을 침범하지 않는지 확인했다.
- `768x1024-shore-detail-play.png`: 큰 플레이 보드와 주변 해변 배경의 비율, 장식의 낮은 대비와 비충돌성을 확인했다.
- 두 캡처 모두 브라우저 콘솔 오류 0건이다. Chromium 뷰포트 검증이며 실제 기기 렌더링·성능 증거로 해석하지 않는다.

## 2026-08-02 전체 플레이 화면 Golden 회귀 게이트

- `test/goldens/game_screen_stage{1,2,3}_{390x844,768x1024}.png`를 생성해 첫 3단계의 6개 기준을 고정했다.
- 전체 플레이 화면은 해변 배경, HUD, 보드 프레임, 벽, 홀, 공, 물체, 조준 화살표, 하단 컨트롤을 함께 캡처한다.
- 2단계는 중앙 반사벽·젤리, 3단계는 스위치·문·점착판·상자까지 단계별 기믹 배치를 자동 픽셀 회귀로 보호한다.
- Golden 호스트에서는 Flame 래스터 디코더 교착을 피하기 위해 `loadGameAssets: false`를 사용한다. 제품 기본 실행은 래스터 자산을 계속 사용하므로 Web 캡처와 자산 HTTP 200 검증을 함께 본다.
- 390×844와 768×1024에서 1·2·3단계 Golden 테스트 6개가 통과했다. 실제 Flame 래스터 로딩을 켠 동일 테스트는 `toBeLoaded()` 교착으로 분리했으며, 실제 iOS 렌더링과 프레임 측정은 별도 미검증이다.

## 2026-08-02 최신 Web release 시각·성능 증거

- `390x844-audio-release-home.png`, `390x844-audio-release-play.png`, `768x1024-audio-release-home.png`, `768x1024-audio-release-play.png`는 최신 오디오 코드가 포함된 Web release의 변경 후 캡처다.
- `harness_docs/qa/web_performance_latest.json`은 Chromium 390×844·768×1024에서 idle·발사 구간을 측정한 결과로, 콘솔 오류 0건·평균 약 16.67ms·20ms 초과 프레임 0%를 기록한다.
- 이 자료는 Web 보조 측정이며 실제 iPhone/iPad GPU·메모리·터치·햅틱 결과로 해석하지 않는다.

## 2026-08-02 공 화풍 일관성 Golden

- `test/goldens/raster_assets_390x844.png`, `test/goldens/raster_assets_768x1024.png`에 돌·상자·젤리 래스터와 얼굴 공을 함께 캡처했다.
- 홈 미리보기와 플레이 공은 `GameBallIconPainter`를 공유하며, 레거시 농구공 이미지가 화면에 다시 사용되지 않도록 회귀를 추가했다.

## 2026-08-02 벽 재질 회귀

- `test/goldens/game_screen_390x844.png`, `test/goldens/game_screen_768x1024.png`를 벽 표면 변경 후 재생성했다.
- 390×844·768×1024에서 벽의 고정 경계 가독성, 내부 모래색 가장자리, 공·홀·상자 배치를 확인했다.
- Golden은 Canvas 재질 회귀를 검증하며 실제 Web 색감·터치·실기기 성능을 대신하지 않는다.

## 2026-08-02 섬 지도 진행 경로 Golden

- `test/goldens/stage_select_390x844.png`, `test/goldens/stage_select_768x1024.png`를 추가했다.
- `stage_route_map` 안에 진행 경로·잠금 상태·진행률을 표시하고, 하단 `map_hint_card`에서 여러 풀이 원칙을 짧게 전달한다.
- 지도 화면 Golden 2개와 한 번 탭 접근성 힌트 위젯 테스트가 통과했다.
- 768×1024는 Web 보조 태블릿 비율이며 실제 iPad 입력·프레임 증거가 아니다.

- `test/goldens/gameplay_backdrop_390x844.png`, `test/goldens/gameplay_backdrop_768x1024.png`를 해변 플레이 배경의 기준 이미지로 추가했다.
- `390x844-golden-gate-play.png`, `768x1024-golden-gate-play.png`는 Golden 추가 후 최신 Web release의 실제 시작 흐름 캡처다.
- Golden은 배경 레이어만 픽셀 비교하며, 실제 기기 렌더링·성능 검증으로 확대 해석하지 않는다.

## 2026-08-02 홈 화면 Golden 캡처

- `test/goldens/home_screen_390x844.png`, `test/goldens/home_screen_768x1024.png`를 홈 전체 화면의 기준 이미지로 추가했다.
- 홈 Golden은 한글 제목·설명·시작 버튼·스테이지 선택 버튼·Material 아이콘·보드 미리보기를 포함한다.
- 테스트 환경 폰트 로딩을 명시해 네모 글리프가 기준 이미지에 섞이지 않도록 했다.
- `390x844-home-font-gate.png`, `768x1024-home-font-gate.png`는 폰트 보정 후 최신 Web release의 실제 홈 화면 캡처이며 두 화면의 콘솔 오류는 0건이다.
- 시작 버튼 `첫 섬에서 시작하기`는 Golden과 실제 Web 캡처에서 동일한 한글 글리프로 확인했다.
- Golden 캡처 전 `stone-v2.png`·`crate-v2.png`·`jelly-bumper-v1.png`를 명시적으로 precache해 래스터 오브젝트가 누락되는 순서 의존성을 제거했다. 공은 `GameBallIconPainter`로 그리며, 최신 캡처와 기준 이미지 모두 돌·상자·젤리·얼굴 공을 포함한다.

## 2026-08-02 모바일 HUD 안내 축약 캡처

- 변경 전 기준: `390x844-current-play-audit.png`, `768x1024-current-play-audit.png`, `1024x1366-current-play-audit.png`.
- 변경 후: `390x844-compact-hud-pass.png`, `393x852-compact-hud-pass.png`, `430x932-compact-hud-pass.png`, `768x1024-compact-hud-pass.png`, `1024x1366-compact-hud-pass.png`.
- 변경 후 다섯 뷰포트에서 보드·공·돌·상자·홀·컨트롤이 보드 안에 유지되고 콘솔 오류는 0건이었다. 실제 iPhone·iPad 렌더링이나 터치 지연을 증명하는 캡처는 아니다.

## 2026-08-02 피드백 설정 캡처

- `390x844-feedback-settings.png`: 홈 설정에서 효과음·진동 토글이 보이는 실제 Web 팝업.
- `390x844-feedback-persisted.png`: 효과음을 끈 뒤 새로고침하고 팝업을 다시 열어 꺼짐 상태가 복원된 캡처.
- 두 캡처 모두 Chromium Web 실행이며 콘솔 오류 0건이다. 실제 기기 사운드·무음 모드·햅틱 체감 증거로 해석하지 않는다.

## 2026-08-02 별·메달 피드백 포함 최신 캡처

- `390x844-medal-feedback-release-home.png`, `390x844-medal-feedback-release-play.png`는 별·메달 보상 큐가 포함된 최신 Web release에서 생성했다.
- `768x1024-medal-feedback-release-home.png`, `768x1024-medal-feedback-release-play.png`는 같은 번들의 넓은 세로 뷰포트 캡처다.
- 두 해상도 모두 시작 입력 후 콘솔 오류 0건을 확인했다. 캡처는 Web 렌더링 증거이며 실제 iOS 사운드·햅틱·기기 성능을 의미하지 않는다.

## 2026-08-02 세부 피드백 큐 포함 최신 캡처

- `390x844-feedback-queue-release-home.png`, `390x844-feedback-queue-release-play.png`는 전용 피드백 큐와 오디오 순서화가 포함된 최신 Web release 캡처다.
- `768x1024-feedback-queue-release-home.png`, `768x1024-feedback-queue-release-play.png`는 같은 번들의 넓은 세로 뷰포트 캡처다.
- 두 해상도 모두 한글 HUD·해변 보드·공·홀·돌·상자의 위치와 보드 경계를 확인했으며 브라우저 콘솔 오류는 0건이었다.
- 이 캡처는 실제 기기 사운드·햅틱·GPU·메모리 측정이 아니다.

## 2026-08-02 항해 지도·첫 행동 코치마크 최신 캡처

- 변경 전 지도·플레이 기준은 `390x844-map.png`, `390x844-play.png`다. 변경 후에는 카드가 좌우로 이어지는 섬 경로로 보이도록 재배치했다.
- `390x844-stage-route-coach-release.png`, `768x1024-stage-route-coach-release.png`는 최신 Web release 항해 지도다.
- `390x844-tutorial-coach-release.png`, `768x1024-tutorial-coach-release.png`는 첫 단계 바위 선택 코치마크다.
- `390x844-tutorial-ball-coach-release.png`는 속성 이전 뒤 공 충전 코치마크와 하단 상태 문구가 일치하는 화면이다.
- 다섯 캡처는 Chromium 콘솔 오류 0건이며, 실제 사용자 발견성·iOS 기기 결과로 확대 해석하지 않는다.

## 2026-08-02 분석 파 표시 최신 캡처

- `390x844-stage-route-par-release.png`, `768x1024-stage-route-par-release.png`는 자동 분석 결과와 동기화된 추천 파 `2·2·3`이 지도 카드에 표시되는 최신 Web release 캡처다.
- Chromium에서 두 화면의 콘솔 오류 0건을 확인했으며, 캡처는 Web 보조 증거로 실제 iPhone/iPad 성능·입력 결과를 대신하지 않는다.

## 2026-08-02 자동 분석 지표 포함 최신 캡처

- `390x844-stage-route-analysis-release.png`, `768x1024-stage-route-analysis-release.png`는 자동 분석 지표 보강 후 PID 80147의 최신 Web release에서 실제 스테이지 선택 화면으로 이동해 캡처했다.
- 분석기 변경은 게임 화면을 변경하지 않으므로 지도 구성·추천 파 표시·한글 줄바꿈이 이전 기준과 동일하게 유지되는지 확인하는 회귀 증거로 사용한다.

## 2026-08-02 대체 전략 해석 포함 최종 캡처

- `390x844-stage-route-analysis-final.png`, `768x1024-stage-route-analysis-final.png`는 최신 서버 PID 2452에서 실제 스테이지 선택 화면으로 이동해 생성했다.
- 이전 통합 분석 반복의 Web release는 PID 55374에서 실행됐고, 해당 지도 캡처는 분석 화면 회귀의 역사적 근거로 유지한다. 현재 화면 근거는 아래 PID 16872 직접 캡처를 사용한다.
- 분석 화면은 지배 전략 커버리지와 대체 전략 수를 코드 리포트에서 별도로 제공하며, 이 캡처에서는 추천 파·경로·한글 UI의 시각 회귀를 확인한다.

## 2026-08-02 현재 서버 직접 캡처

- `scripts/capture_web_screenshots.py --url http://127.0.0.1:8080/`로 현재 PID 55374에서 `390x844-home-current.png`, `390x844-map-current.png`, `390x844-play-current.png`, `768x1024-home-current.png`, `768x1024-map-current.png`, `768x1024-play-current.png`를 생성했다.
- `scripts/capture_web_screenshots.py --url http://127.0.0.1:8080/`로 현재 PID 16872에서 `390x844-home-current.png`, `390x844-map-current.png`, `390x844-play-current.png`, `768x1024-home-current.png`, `768x1024-map-current.png`, `768x1024-play-current.png`를 갱신했다.
- `test/widget_test.dart`의 결과 상태를 동일한 PID 기준 현재 레벨 값으로 고정해 `390x844-result-current.png`, `768x1024-result-current.png`를 생성했다. 결과 화면은 `파 2회 · 3/3 별`, 리더보드, `다음` 버튼을 포함한다.
- 시작·지도·플레이 상태 모두 콘솔 오류 0건이다. Web 의미 DOM 대신 기존 성능 감사에서 확인한 Flutter Web 좌표를 사용했으므로 실제 iOS 터치 좌표 검증으로 확대하지 않는다.

## 2026-08-02 선택형 추가 도전 포함 최신 캡처

- `390x844-bonus-goal-release-home.png`, `390x844-bonus-goal-release-play.png`는 단계별 추가 도전 기록 코드가 포함된 최신 Web release의 모바일 캡처다.
- `768x1024-bonus-goal-release-home.png`, `768x1024-bonus-goal-release-play.png`는 같은 번들의 넓은 세로 뷰포트 캡처다.
- 플레이 캡처에서 한글 HUD, 실제 돌·상자 래스터, 홀·공·발사 조작 영역과 보드 경계를 확인했다. 결과 팝업의 저장 상태 표시는 `클리어 팝업은 로컬에 저장된 추가 도전 달성을 표시한다` 위젯 회귀로 보호한다.
- 두 해상도 모두 브라우저 콘솔 오류 0건이다. Chromium Web 보조 증거이며 실제 iPhone/iPad 렌더링·성능·햅틱 증거는 아니다.

## 2026-08-03 조준 가이드·목표 해상도 최신 캡처

- 기존 PID 16872를 종료하고 조준 가이드 리디자인이 포함된 Web release를 PID 95957으로 교체했다.
- `scripts/capture_web_screenshots.py --url http://127.0.0.1:8080/`로 `390x844`, `393x852`, `430x932`, `768x1024`, `1024x1366` 각각의 홈·지도·플레이 캡처를 생성했다.
- 1024×1366은 시작 버튼 좌표를 별도로 보정한 뒤 플레이 화면 전환을 확인했다. 다섯 해상도 모두 Chromium 콘솔 오류 0건이다.
- 조준 화면은 큐 장력·탄성 줄·짧은 점형 방향 마커를 사용하고 최종 궤적은 표시하지 않는다. 캡처는 Web 보조 증거이며 실제 iOS 터치 좌표 검증을 의미하지 않는다.
