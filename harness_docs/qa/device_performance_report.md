# 기기·성능 검증 보고서

작성 기준: 2026-08-08 KST
기준 브랜치: `commercial/wall-physics-qa`

## 최신 판정

Web Release 대리 측정은 이전 후보보다 크게 안정화됐지만, 발사 구간 p90이 16.9~17.2ms로 엄격 목표 16.7ms를 0.2~0.5ms 초과했다. p99 25ms 이하와 50ms 초과 프레임 0건은 충족했다. 실제 iPhone·Android·iPad 측정이 없으므로 최종 판정은 `엄격 성능 게이트 미통과·실기기 미검증`이다.

## 측정 원칙

성능 결론은 Release 빌드에서만 내린다. 순수 물리 계산 시간, Headless Chromium 프레임 시간, 에뮬레이터 실행, 실제 모바일 기기 프레임 시간을 서로 다른 증거로 기록한다. Web 결과를 모바일 실기기 결과로 확대하지 않는다.

## 최신 Web 감사

측정 시각: 2026-08-08 17:55 KST

대상: `http://127.0.0.1:8080/` Web Release

도구: `scripts/web_performance_audit.py`
조건: 페이지 5초·플레이 5초 워밍업 후 idle 및 실제 발사 구간 측정

| 뷰포트 | 구간 | 평균 | p90 | p95 | p99 | 최대 | 50ms 초과 |
|---|---|---:|---:|---:|---:|---:|---:|
| 390×844 | idle | 16.822ms | 17.2ms | 17.4ms | 17.6ms | 33.5ms | 0건 |
| 390×844 | 발사 | 16.778ms | 16.9ms | 17.0ms | 17.4ms | 33.326ms | 0건 |
| 768×1024 | idle | 16.823ms | 17.2ms | 17.3ms | 17.5ms | 33.5ms | 0건 |
| 768×1024 | 발사 | 16.777ms | 17.2ms | 17.5ms | 17.6ms | 33.2ms | 0건 |

- 두 뷰포트 모두 콘솔 오류 0건, 측정된 발사 구간 Long Task 0건이다.
- `idle_long_tasks`에는 PerformanceObserver의 buffered 항목 때문에 워밍업·초기 로딩 작업이 포함된다. 발사 구간 결과와 혼합해 판정하지 않는다.
- 시스템 Pillow의 JPEG ABI를 사용할 수 없는 환경에서도 동일한 검증 뷰포트의 고정 시작 좌표로 감사를 수행하도록 도구를 보강했다.
- 원자료는 [web_performance_latest.json](web_performance_latest.json)에 보존한다.

## 목표 대비

| 목표 | 결과 | 판정 |
|---|---|---|
| 발사 p90 ≤ 16.7ms | 16.9ms·17.2ms | 미통과 |
| 발사 p99 ≤ 25ms | 17.4ms·17.6ms | 통과 |
| 발사 중 50ms 초과 0건 | 두 뷰포트 0건 | 통과 |
| 콘솔 오류 0건 | 두 뷰포트 0건 | 통과 |
| 실제 모바일 기기 확인 | 증거 없음 | 미검증 |

## 확보된 기타 측정

| 측정 대상 | 결과 | 한계 |
|---|---|---|
| `ShotResolver` 1단계 | 평균 416.8µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 2단계 | 평균 329.8µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 3단계 | 평균 338.6µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 4단계 | 평균 354.9µs | 렌더링·GPU·입력 제외 |
| Android ARM64 API 28 AVD | 세로 Release에서 4단계 진입·속성 이전·45% 충전·자동 발사·홀 성공 입력 스모크 통과 | FPS·GPU·메모리·햅틱 미측정 |

## 최신 자동 검증

- `flutter analyze`: 통과, 오류 0건
- 스테이지 카탈로그: 생산 패턴 40개 제한 실행 검증 및 생성본 일치 통과
- 전체 `flutter test`: 873개 통과, 홈 화면 최신 기능 반영 전 골든 2건 실패를 확인했다. 해당 기준 이미지 갱신 후 영향권 테스트 45개가 통과했으며 최종 전체 재검증을 별도로 수행한다.
- `flutter build web --release`: 직전 제품 소스 기준 통과

## 기존 빌드·실행 증거

- Android Debug·Release APK 컴파일 통과, Release APK 57.3MB
- ARM64 API 28 에뮬레이터에서 Release 설치·실행과 주요 입력 흐름 통과
- `flutter build ios --no-codesign`: Xcode 컴파일 통과
- iOS 배포: Development Team·프로비저닝 프로파일 부족으로 미완료
- iOS Simulator: 설치된 Runtime 부재로 실행 검증 미완료

기존 Android 증거는 [android-arm64-evidence.json](../../screenshots/commercial-vertical-slice/android-arm64-evidence.json)과 [android-arm64-stage4-evidence.json](../../screenshots/commercial-vertical-slice/android-arm64-stage4-evidence.json)에 보존한다.

## 필수 후속 측정

- iPhone 12급 세로 화면에서 p90 16.7ms, p99 25ms와 입력 지연 확인
- 노치·Dynamic Island 기기의 Safe Area와 터치 좌표 확인
- iPad Pro 4:3 화면의 보드·팝업·지도 배치 확인
- 소형·중급 Android에서 프레임 시간·이미지 디코딩·햅틱 확인
- 20분 플레이, 50회 재시도, 다중 공·다중 물체 스트레스 후 메모리 추세 확인
- Web p90 초과 0.2~0.5ms의 원인이 브라우저 타이머 양자화인지 실제 렌더 비용인지 DevTools·실기기 프로파일로 분리
