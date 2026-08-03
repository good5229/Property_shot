# 시각 캡처 증거

## 목표 해상도

`390×844`, `393×852`, `430×932`, `768×1024`, `1024×1366`

## 상태 범위

홈·지도·플레이 기본, 스테이지4 시작·팝 직후·스위치/문 열림·홀 포획·결과를 Golden으로 고정했다. 기본 플레이 Golden은 20개, 스테이지4 인과 Golden은 25개다.

## 판정

- 자동 픽셀 비교: 통과
- Web 최신 번들 루트·`main.dart.js`: HTTP 200, 최신 유지 서버 PID 91916 (단계4 캡처 실행 서버는 아래 기록대로 PID 54628)
- 브라우저 콘솔 오류: 최신 5해상도 캡처에서 0건
- 390×844 섬 지도에서 4단계 설명·잠금·한글 안내 확인
- 390×844 플레이에서 입체 물체·홀 깃발·조준 UI·하단 조작 영역 비겹침 확인
- 실기기 색감·프레임·터치·햅틱: 미검증

## 2026-08-03 단계4 실제 Web 조작 증거

- `scripts/capture_stage4_web_evidence.py`가 390×844 Release Web에서 홈→섬 지도→4단계 진입, 뾰족함 원본 팝업, 속성 이전, 조준, 충전, 발사 후 충돌·결과를 실제 좌표 입력으로 재생한다.
- `stage4-start.png`, `stage4-source-popup.png`, `stage4-property-ready.png`, `stage4-aim.png`, `stage4-charge.png`, `stage4-impact-120ms.png`, `stage4-impact-470ms.png`, `stage4-result.png` 8장을 생성했다.
- `stage4-web-evidence.json`의 `console_errors`가 빈 목록이며, 실행 당시 서버 PID는 54628이다.
- 최초 실행에서 성공 상태의 `active_ball` 조회 예외를 발견해 `07ef7b3`에서 수정하고, 수정 후 재실행으로 오류 0건을 확인했다.
- 이는 Chromium Web 상호작용 증거이며 실제 iPhone·iPad 터치·프레임·GPU·메모리·햅틱 증거로 확대 해석하지 않는다.

## 2026-08-03 Android ARM64 런타임 스모크 증거

- `PropertyShot_ARM64` Android API 28 에뮬레이터에서 Release APK를 설치하고 1080×1920 세로 화면을 확인했다.
- 홈에서 첫 단계 진입, 무거운 돌 선택, 정보 팝업, `속성 옮기기`, 공 속성 변경까지 실제 좌표 입력으로 재생했다.
- `android-arm64-start.png`, `android-arm64-play.png`, `android-arm64-source-popup.png`, `android-arm64-property-transferred.png`를 보존했다.
- 앱 프로세스가 실행 중이었고 수집한 로그에서 앱 `FATAL EXCEPTION`은 0건이었다.
- 이는 Android 에뮬레이터 런타임 스모크 증거이며 실제 Android 기기의 프레임·GPU·메모리·햅틱 결과를 대신하지 않는다.

## 2026-08-03 Android ARM64 단계4 전체 흐름 증거

- Release APK로 교체한 뒤 섬 지도에서 `4 / 4` 해금 상태와 4단계 설명 카드를 확인했다.
- 4단계에서 뾰족함 원본 팝업, 속성 옮기기, 방향 설정, 45% 충전, 손을 뗀 자동 발사, 문 열림·홀 진입 성공, 클리어 팝업을 실제 좌표 입력으로 재생했다.
- `android-arm64-stage4-evidence.json`과 1080×1920 캡처 8장을 보존했다.
- 실행 로그에서 앱 `FATAL EXCEPTION`은 0건이었다.
- 해당 결과는 Android ARM64 에뮬레이터의 기능·화면 스모크이며 실제 기기 성능·입력 지연·햅틱 증거가 아니다.

원본 파일은 `test/goldens/`와 [screenshot_matrix.md](screenshot_matrix.md)에 둔다.
