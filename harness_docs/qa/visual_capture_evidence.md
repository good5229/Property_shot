# 시각 캡처 증거

## 목표 해상도

`390×844`, `393×852`, `430×932`, `768×1024`, `1024×1366`

## 상태 범위

홈·지도·플레이 기본, 스테이지4 시작·팝 직후·스위치/문 열림·홀 포획·결과를 Golden으로 고정했다. 기본 플레이 Golden은 20개, 스테이지4 인과 Golden은 25개다.

## 판정

- 자동 픽셀 비교: 통과
- Web 최신 번들 루트·`main.dart.js`: HTTP 200, 서버 PID 54628
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

원본 파일은 `test/goldens/`와 [screenshot_matrix.md](screenshot_matrix.md)에 둔다.
