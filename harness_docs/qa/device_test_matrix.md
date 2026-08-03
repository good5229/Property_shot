# 기기 검증 매트릭스

| 환경 | 현재 증거 | 판정 |
| --- | --- | --- |
| Flutter 위젯 320x568 | 축약 HUD·팝업 경계·한글 오버플로 회귀 | 통과 |
| Flutter 위젯 390x844 | 일반 모바일 레이아웃·팝업·접근성 회귀 | 통과 |
| Web release | `flutter build web --release`, 루트·번들 HTTP 200 | 통과 |
| Headless Chromium Web 390×844·768×1024 | 홈→플레이→발사 rAF 감사, p95 16.7~16.8ms, 콘솔 오류 0건 | 조건부 통과, 실기기 대체 아님 |
| Android Debug APK | `flutter build apk --debug` 성공 | 컴파일 통과, 실기기 미검증 |
| Android Release APK | `flutter build apk --release` 성공, 57.2MB | 컴파일 통과, 서명·실기기 미검증 |
| Pixel 3 API 30 AVD | x86 시스템 이미지와 Apple Silicon Emulator의 QEMU 아키텍처 불일치 | 미검증 |
| iOS 무서명 빌드 | Xcode 컴파일 후 Development Team·프로비저닝 프로파일 부족 | 미완료 |
| iPhone 12 실기기 | 프레임·터치·햅틱 미측정 | 미검증 |
| iPad Pro 실기기 | 비율·프레임·터치 미측정 | 미검증 |

실기기 측정 전에는 60FPS 유지나 햅틱 품질을 완료로 기록하지 않는다.
