# 3~N중 연쇄 충돌 프레임 페이싱 검증

## 관찰한 원인

- 같은 경로 시점의 충돌 사건이 한 Flame 프레임에 함께 도착하면서 Web Audio·햅틱 예약과 로컬 텔레메트리 Map 생성이 충돌 렌더와 경쟁했다.
- 연쇄 이동 위치는 거리 기반으로 보간하지만 눌림·회전 변형은 경로 점 인덱스로 계산해, 충돌 직전·분리 직후의 짧은 점에서 변형 속도가 튀었다.
- 움직이는 상자·돌·젤리는 매 프레임 고해상도 이미지를 두께·외곽선 포함 8회 이상 다시 그렸다. 5중 연쇄에서는 본체만 40회 이상 이미지 명령을 만들 수 있었다.
- 다수 충돌의 링·파편·속성 입자가 같은 14~16 cursor 창에 모두 남아 사람이 구분하기 어려운 효과와 렌더 비용이 함께 증가했다.

## 수정 계약

- 한 프레임에 들어온 Web 충돌 피드백은 가장 중요한 신호 하나로 합성한다. 홀 진입은 다른 충돌보다 항상 우선한다.
- 충돌 텔레메트리는 현재 렌더 프레임에서 분리하고 프레임당 최대 4개 콜백씩 기록한다. 화면 종료 전에는 남은 기록을 모두 보존한다.
- 연쇄 이동체의 위치와 재질 변형은 같은 거리 기반 시간축을 사용한다.
- 동시에 남는 이동 충돌 효과는 최근 4개, 직접 충돌 효과는 최근 5개로 제한한다. 물리 사건과 점수는 줄이지 않는다.
- 래스터 오브젝트의 두께·외곽선·표면 광원은 계획 화면에서 `ui.Picture`로 한 번 기록하고, 연쇄 이동 중에는 위치·회전·눌림 변환만 적용한다.
- 5개 이동체는 30·45·60 FPS에서 프레임당 4.55 논리 단위 이내로 이동하며 순간이동하지 않는다.

## 자동 검증

```sh
flutter analyze
flutter test test/game_feedback_test.dart test/animation_timeline_test.dart --concurrency=1
flutter test test/power_slider_golden_test.dart test/widget_test.dart --concurrency=1
flutter test test/animation_timeline_test.dart test/generated_gimmick_golden_test.dart --concurrency=1
flutter test --concurrency=1
dart run tool/generate_stage_catalog.dart --check --validate-runtime
flutter build web --release --wasm
python3 scripts/web_performance_audit.py --url http://127.0.0.1:8081/ --viewport 390x844 --repetitions 3
```

## 결과

- 정적 분석: 문제 0건
- 피드백·30/45/60 FPS·5중 연쇄·불균일 경로 집중 테스트: 통과
- 래스터 캐시: 계획 화면에서 만든 그림 수가 60개 애니메이션 프레임 동안 증가하지 않음
- 생성 이미지 시각 회귀: 전 10단계·4개 화면 등급과 4종 속성 공 Golden 포함 69건 통과
- 게임 화면·파워 슬라이더·텔레메트리 회귀: 109건 통과
- 전체 직렬 Flutter 테스트: 1,476건 통과. 이후 래스터 캐시 전용 테스트 1건을 추가하고 관련 69건을 다시 통과함
- 생산 40패턴 제한 실행과 카탈로그 동기화: 통과
- WebAssembly 릴리스 빌드: 통과
- 390×844 Chromium headless Wasm 3회: 콘솔 오류 0, 발사 구간 p95 17.5~17.6ms, p99 32.6~33.4ms. 각 회차의 50ms 초과 장기 작업 1건은 포인터 해제 전 충전 UI 구간에서 시작했고, 해제 뒤 충돌 재생 구간에서는 50ms 초과 장기 작업이 관찰되지 않음

브라우저 수치는 `requestAnimationFrame` 간격을 보는 Chromium headless 프록시이며 실제 사용자의 지각이나 특정 모바일·GPU의 Flutter build/raster 시간을 대신하지 않는다. 공개 배포 뒤 사용자가 지적한 3~N중 추돌 장면의 체감 확인은 별도로 필요하다.
