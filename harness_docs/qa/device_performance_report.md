# 기기·성능 검증 보고서

작성 기준: 2026-08-10 KST
기준 브랜치: `main`
기준: 작업 트리 / 기반 커밋 `bfb7a39734cad39b458273a6bca55a5485950d7c`

## 최종 제출 자동 회귀 재확인

- 실행 시각: 2026-08-10 KST
- 명령: `flutter test --concurrency=1`
- 결과: 사용자가 요청한 단 한 번의 직렬 실행 **1,062건 중 997건 통과·65건 실패**. 실패 분류 후 Golden 영향권 67/67, replay·결정론 9/9, 핵심 변경 239/239 표적 재검증 통과
- 추가 결과: `flutter analyze` 문제 0건, Web Release와 Android Release APK(63,261,407바이트·약 60.33MiB) 빌드 통과
- 아래의 898개·901개·988개 수치는 기능 추가 과정의 과거 실행 기록이다. 최신 제출 자동 회귀는 위의 직렬·단독 재검증 결과를 기준으로 한다.
- 이 자동 결과는 Web rAF 대리 측정이나 Android 에뮬레이터 증거와 구분하며, 실제 모바일 성능 게이트를 통과시키지 않는다.

## 최신 판정

2026-08-10 최신 Web Release를 에이전트·빌드 작업이 없는 독립 상태에서 뷰포트별 3회 다시 측정했다. 390×844와 768×1024 모두 발사 구간 p90 17.2ms·p99 17.6ms·누락 0·50ms 초과 0·Long Task 0·콘솔 오류 0이었다. 과거 768×1024 3회차의 p90 33.4ms·p99 67.4ms는 동일 조건에서 재현되지 않았다. 따라서 최신 판정은 `브라우저 rAF 대리 안정·16.7ms 엄격 목표는 0.5ms 초과·실기기 미검증`이다.

## 측정 원칙

성능 결론은 Release 빌드에서만 내린다. 순수 물리 계산 시간, Headless Chromium 프레임 시간, 에뮬레이터 실행, 실제 모바일 기기 프레임 시간을 서로 다른 증거로 기록한다. Web 결과를 모바일 실기기 결과로 확대하지 않는다.

## 최신 Web 감사

측정 시각: 2026-08-10 17:04 KST

대상: `http://127.0.0.1:8090/Property_shot/` Web Release

도구: `scripts/web_performance_audit.py`
조건: 각 회차를 새 브라우저 컨텍스트에서 시작해 페이지 5초·플레이 5초 워밍업 후 유휴 1.8초와 충전 0.65초를 포함한 발사 입력 3.15초를 해상도별 3회 측정

| 뷰포트 | 구간 | 표본 | 평균 | 중앙값 | p90 | p95 | p99 | 최대 | 누락 프레임 | 50ms 초과 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 390×844 | 유휴 | 326 | 16.721ms | 16.7ms | 17.2ms | 17.4ms | 17.6ms | 33.5ms | 1건 | 0건 |
| 390×844 | 발사 입력 | 569 | 16.664ms | 16.7ms | 17.2ms | 17.4ms | 17.6ms | 17.7ms | 0건 | 0건 |
| 768×1024 | 유휴 | 325 | 16.719ms | 16.7ms | 17.2ms | 17.4ms | 17.6ms | 33.5ms | 1건 | 0건 |
| 768×1024 | 발사 입력 | 569 | 16.666ms | 16.7ms | 17.2ms | 17.4ms | 17.6ms | 17.7ms | 0건 | 0건 |

- 두 뷰포트의 3회 모두 콘솔 오류와 유휴·발사 입력 Long Task가 0건이다.
- 누락 프레임은 각 구간 중앙값의 1.5배를 초과한 rAF 간격으로 정의했다. 각 뷰포트 유휴에서 1건씩 있었지만 발사 입력 구간은 두 해상도 모두 0건이다.
- 과거 단일 측정의 390×844 유휴 50.6ms 1건은 역사 기록으로 남기되, 최신 독립 3회 집계에서는 50ms 초과가 재현되지 않았다.
- 첫 최신 감사에서 오래된 Flutter Web build cache가 `audioplayers_web` 등록을 누락해 `MissingPluginException`을 냈다. 서버를 종료하고 `flutter clean`·`flutter pub get`·Release 재빌드를 수행했으며 생성 registrant의 `AudioplayersPlugin.registerWith`와 재감사 콘솔 오류 0건을 확인했다.
- `idle_long_tasks`에는 PerformanceObserver의 buffered 항목 때문에 워밍업·초기 로딩 작업이 포함된다. 발사 구간 결과와 혼합해 판정하지 않는다.
- 시스템 Pillow의 JPEG ABI를 사용할 수 없는 환경에서도 동일한 검증 뷰포트의 고정 시작 좌표로 감사를 수행하도록 도구를 보강했다.
- 원자료는 [web_performance_latest.json](web_performance_latest.json)에 보존한다.

## 목표 대비

| 목표 | 결과 | 판정 |
|---|---|---|
| 발사 입력 rAF p90 ≤ 16.7ms | 두 뷰포트 17.2ms | 미통과(0.5ms 초과) |
| 발사 입력 rAF p99 ≤ 25ms | 두 뷰포트 17.6ms | 통과 |
| 발사 입력 누락 프레임 0건 | 두 뷰포트 0건 | 통과 |
| 전체 측정 50ms 초과 0건 | 유휴·발사 입력 모두 0건 | 통과 |
| 콘솔 오류 0건 | 두 뷰포트 0건 | 통과 |
| 실제 모바일 기기 확인 | 증거 없음 | 미검증 |

rAF p90 미통과만으로 앱 렌더 작업이 16.7ms를 넘었다고 단정하지 않는다. 중앙값 16.7ms에 브라우저 콜백 간격이 양쪽으로 흔들리면서 평균은 16.664–16.666ms를 유지했고 발사 입력 구간의 누락 프레임은 없었다. Flutter build/raster 시간은 DevTools 또는 실기기 profile 측정으로 별도 판정해야 한다.

## 발사 입력 지연 계측 교정

2026-08-09 코드 감사에서 기존 `input_latency_ms`가 손을 뗀 시각을 사용하지 않고 `ShotResolver` 실행 시간만 기록한다는 계약 불일치를 발견했다. 현재는 포인터 해제 직전에 단조 시계를 표식하고, 발사 기록의 비동기 저장과 물리 판정이 끝난 직후까지의 시간을 기록한다.

- 단조 시계의 37.5ms 계산과 역행 방어 회귀 통과
- 30ms 비동기 저장을 주입한 실제 게임 화면 발사에서 20ms 이상의 계측값 기록 확인
- 성공 샷 텔레메트리의 유한·비음수 `input_latency_ms` 연결 확인

이는 측정 경로의 정확성을 확인한 자동 증거다. 실제 모바일 터치 샘플 분포가 없으므로 p95 50ms 게이트는 아직 `미검증`이며 통과로 승격하지 않는다.

실기기 측정 시에는 개발 진단 메뉴에서 현재 앱 세션의 비리플레이 발사 20개 이상을 수집한 뒤 `입력 지연 보고서 복사`를 사용한다. 보고서는 최근접 순위 p95를 계산하고 50밀리초 이하만 통과시키며, 20개 미만은 `표본 부족`으로 남긴다. 이 도구가 생겼다는 사실만으로 실기기 게이트를 통과시키지는 않는다.

## 최신 데모 서버

기존 PID 79482를 먼저 종료하고 Web Release를 PID 796으로 교체했다. 입력 지연 p95 진단 기능을 추가한 뒤 Release에서 진단 문구가 제거되고 앱 번들 해시가 바뀌지 않음을 확인했으며, PID 796을 종료한 다음 최신 서버 PID 21973으로 다시 교체했다. `http://127.0.0.1:8080/`의 루트, `main.dart.js`, 실제 번들 음악 `property_shot_island_loop.wav`가 모두 HTTP 200이며 앱 번들 SHA-256은 `ccf9b216d38098d45486429a652be2604435598378aa36a3a54e9dbbc8a3cd59`다.

## 확보된 기타 측정

| 측정 대상 | 결과 | 한계 |
|---|---|---|
| `ShotResolver` 1단계 | 평균 416.8µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 2단계 | 평균 329.8µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 3단계 | 평균 338.6µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 4단계 | 평균 354.9µs | 렌더링·GPU·입력 제외 |
| Android ARM64 API 28 AVD | 최신 10단계 Release에서 홈·1단계·속성 이전·충전·발사·실패 인과와 20회 반복 메모리 대리 검사 통과 | SwiftShader 에뮬레이터이며 실기기 FPS·GPU·햅틱 대체 불가 |

## 최신 Android Release 감사

측정 시각: 2026-08-08 23:38~2026-08-09 00:03 KST

| 항목 | 결과 |
|---|---|
| 빌드·설치 | Release APK 62.3MB, ARM64 API 28 AVD 재설치 성공 |
| 실제 입력 흐름 | 홈 → 1단계 → 무거운 돌 팝업 → 속성 옮기기 → 1.1초 충전 → 자동 발사 → 실패 인과 |
| 접근성 트리 | `무거운 돌 정보`, 속성 설명, `속성 옮기기`, `닫기` 한글 라벨과 클릭 영역 확인 |
| 단계 초기화 반복 | 20회 뒤 PSS 93,517KB, Flutter 예외 없음 |
| 연속 재조준 1주기 | 5·10·15·20회 PSS 101,360·111,124·110,440·120,520KB |
| 연속 재조준 2주기 | 시작 122,944KB, 5·10·15·20회 118,835·112,632·120,703·122,517KB |
| 지속 증가 판정 | 같은 두 번째 20회 부하의 시작 대비 -427KB로 allocator 고수위 재사용 확인 |
| 치명적 로그 | 앱 PID `FATAL` 0건, Flutter 예외 0건 |

첫 연속 주기는 과거 공 20개와 실패 결과를 처음 처리하며 고수위가 증가했다. 단계 초기화 뒤 같은 부하를 다시 가했을 때 PSS가 더 증가하지 않았으므로 에뮬레이터 반복 메모리 대리 게이트는 통과로 판정한다. 이 결과는 20분 실기기 heap·GPU·열 상태를 대신하지 않는다. 원자료는 [android-arm64-retry-memory-evidence.json](../../screenshots/commercial-vertical-slice/android-arm64-retry-memory-evidence.json), 최종 화면은 [android-arm64-20-retries-latest.png](../../screenshots/commercial-vertical-slice/android-arm64-20-retries-latest.png)에 보존한다.

## 최신 자동 검증

- `flutter analyze`: 통과, 오류 0건
- 스테이지 카탈로그: 생산 패턴 40개 제한 실행 검증 및 생성본 일치 통과
- 당시 전체 `flutter test`: 입력 지연 계측·p95 판정과 최신 자산 번들 계약을 포함해 898개 통과. 최종 제출 전체 회귀는 문서 상단의 988개 결과다.
- `flutter build web --release`: 최신 제품 소스 클린 빌드와 Wasm dry run 통과

## 기존 빌드·실행 증거

- Android Debug·Release APK 컴파일 통과, 최신 Release APK 62.3MB
- ARM64 API 28 에뮬레이터에서 최신 Release 설치·실행, 속성 이전·발사·실패 인과와 반복 메모리 흐름 통과
- `flutter build ios --no-codesign`: Xcode 컴파일 통과
- iOS 배포: Development Team·프로비저닝 프로파일 부족으로 미완료
- iOS Simulator: 2026-08-09 `xcrun simctl list runtimes` 결과 설치 Runtime 0개로 실행 검증 미완료

기존 Android 증거는 [android-arm64-evidence.json](../../screenshots/commercial-vertical-slice/android-arm64-evidence.json)과 [android-arm64-stage4-evidence.json](../../screenshots/commercial-vertical-slice/android-arm64-stage4-evidence.json)에 보존한다.

## 필수 후속 측정

- iPhone 12급 세로 화면에서 p90 16.7ms, p99 25ms와 입력 지연 확인
- 노치·Dynamic Island 기기의 Safe Area와 터치 좌표 확인
- iPad Pro 4:3 화면의 보드·팝업·지도 배치 확인
- 소형·중급 Android에서 프레임 시간·이미지 디코딩·햅틱 확인
- 실기기에서 20분 플레이, 50회 재시도, 다중 공·다중 물체 스트레스 후 메모리 추세 확인
- Web rAF p90 17.2ms가 브라우저 표시 스케줄러 흔들림인지 실제 렌더 비용인지 Flutter DevTools·실기기 profile로 분리
- 자동 발사 입력 뒤 시도 횟수 증가를 접근성 상태로 확인하는 감사 후속 검증
