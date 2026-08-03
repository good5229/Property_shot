# 기기 검증 매트릭스

| 환경 | 현재 증거 | 판정 |
| --- | --- | --- |
| Flutter 위젯 320x568 | 축약 HUD·팝업 경계·한글 오버플로 회귀 | 통과 |
| Flutter 위젯 390x844 | 일반 모바일 레이아웃·팝업·접근성 회귀 | 통과 |
| Web release | `flutter build web --release`, 루트·번들 HTTP 200 | 통과 |
| Headless Chromium Web 390×844·768×1024 | 최신 5초 워밍업 발사 rAF 감사, p95 66.6·150ms, 콘솔 오류 0건 | 성능 게이트 미통과, 실기기 대체 아님 |
| Android Debug APK | `flutter build apk --debug` 성공 | 컴파일 통과, 실기기 미검증 |
| Android Release APK | 최신 `flutter build apk --release` 성공, 57.3MB, ARM64 에뮬레이터 재설치·시작 | 컴파일·에뮬레이터 시작 통과, 서명·실기기 미검증 |
| Android ARM64 API 28 AVD | Release APK 설치·실행, 지도 4/4·4단계 카드·뾰족함 이전·충전·자동 발사·홀 성공·클리어 팝업 실제 입력과 1080×1920 캡처 | 조건부 통과, 에뮬레이터 스모크이며 실기기 대체 아님 |
| Pixel 3 API 30 AVD | x86 시스템 이미지와 Apple Silicon Emulator의 QEMU 아키텍처 불일치 | 미검증, 기존 호환성 한계 |
| iOS 무서명 빌드 | Xcode 컴파일 후 Development Team·프로비저닝 프로파일 부족 | 미완료 |
| iPhone 12 실기기 | 프레임·터치·햅틱 미측정 | 미검증 |
| iPad Pro 실기기 | 비율·프레임·터치 미측정 | 미검증 |

실기기 측정 전에는 60FPS 유지나 햅틱 품질을 완료로 기록하지 않는다.
