# 기기·성능 검증 보고서

작성 기준: 2026-08-03 KST
기준 브랜치: `commercial/wall-physics-qa`

## 최신 Release 빌드 기준 · 2026-08-03 KST

- Web Release는 기존 데모 PID 31813을 종료한 뒤 최신 빌드를 PID 84934 유지 세션으로 교체했다. 최신 `main.dart.js` SHA-256은 `dd82d9304257e16161a62db9a4f1d72d5721c84903137e60bbfc9ca79cb17bda`다.
- Android Release APK는 최신 코드로 다시 빌드되어 57.3MB이며 ARM64 API 28 에뮬레이터에 설치·실행됐다.
- 앱 PID 3708이 실행 중이고 최근 로그에서 앱 `FATAL EXCEPTION` 0건을 확인했다.
- 전체 Flutter 테스트는 247개 통과했고 저장소 공유·4단계 경계·고속 연쇄 회귀를 포함한다.
- 최신 APK와 시작 화면 캡처는 `android-arm64-latest-layout-evidence.json` 및 `android-arm64-latest-layout.png`에 보존했다.
- 실기기 FPS·GPU·메모리·터치 지연·햅틱은 여전히 미측정이다.

## 측정 원칙

성능 결론은 Release 빌드에서만 내린다. 순수 물리 계산 시간, Headless Chromium 프레임 시간, 실제 모바일 기기 프레임 시간을 서로 다른 증거로 기록한다.

## 확보된 측정

| 측정 대상 | 결과 | 한계 |
|---|---|---|
| `ShotResolver` 1단계 | 평균 416.8µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 2단계 | 평균 329.8µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 3단계 | 평균 338.6µs | 렌더링·GPU·입력 제외 |
| `ShotResolver` 4단계 | 평균 354.9µs | 렌더링·GPU·입력 제외 |
| Web 390×844 | 평균·p95 약 16.7ms | Headless Chromium |
| Web 768×1024 | 평균·p95 약 16.7ms | Headless Chromium |
| Web 콘솔 | 5개 뷰포트 오류 0건 | 실제 모바일 브라우저 아님 |
| Android ARM64 API 28 AVD | 1080×1920 세로 Release에서 4단계 진입·속성 이전·45% 충전·자동 발사·홀 성공까지 입력 스모크 통과 | 프레임 시간·GPU·메모리·햅틱 미측정 |

Web 캡처 뷰포트는 `390×844`, `393×852`, `430×932`, `768×1024`, `1024×1366`이며 홈·섬 지도·플레이 화면을 확인했다.

## 빌드 상태

- `flutter analyze`: 통과
- `flutter build web --release`: 통과
- `flutter build apk --debug`: 통과, Android 호스트 추가 후 APK 생성
- `flutter build apk --release`: 통과, `build/app/outputs/flutter-apk/app-release.apk` 57.3MB
- `flutter build ios --no-codesign`: Xcode 컴파일까지 통과
- iOS 배포 단계: Development Team과 프로비저닝 프로파일 부족으로 미완료
- iOS Simulator: 설치된 Runtime이 없어 실행 검증 미완료
- Android Pixel 3 AVD: x86 시스템 이미지와 Apple Silicon Emulator의 QEMU 아키텍처 불일치로 기동 실패

## 필수 후속 측정

- iPhone 12급 세로 화면에서 평균 60FPS, p95 16.7ms, p99 25ms 확인
- 최근 노치·Dynamic Island 기기의 Safe Area와 터치 좌표 확인
- iPad Pro 4:3 화면의 보드·팝업·지도 카드 배치 확인
- 소형·중급 Android에서 입력 지연과 이미지 디코딩 확인
- 20분 플레이, 50회 재시도, 다중 공·다중 물체 스트레스 후 메모리 추세 확인
- 실제 iOS 햅틱·사운드 타이밍 확인

Android ARM64 에뮬레이터에서는 홈, 1단계 물체 정보 팝업·속성 옮기기와 4단계 전체 흐름을 실제 입력으로 확인했다. 결과는 [android-arm64-evidence.json](../../screenshots/commercial-vertical-slice/android-arm64-evidence.json), [android-arm64-stage4-evidence.json](../../screenshots/commercial-vertical-slice/android-arm64-stage4-evidence.json)과 캡처에 보존했으며, 에뮬레이터 실행만으로 60FPS나 실기기 성능을 판정하지 않는다.

실기기와 호환되는 에뮬레이터 런타임 측정이 없으므로 현재 성능 판정은 `미검증`이다.
