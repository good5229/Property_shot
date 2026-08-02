# 기기 검증 매트릭스

| 환경 | 현재 증거 | 판정 |
| --- | --- | --- |
| Flutter 위젯 320x568 | 축약 HUD·팝업 경계·한글 오버플로 회귀 | 통과 |
| Flutter 위젯 390x844 | 일반 모바일 레이아웃·팝업·접근성 회귀 | 통과 |
| Web release | `flutter build web --release`, 루트·번들 HTTP 200 | 통과 |
| iOS 무서명 빌드 | Swift Package Manager 의존성 해결 단계 실패 | 미완료 |
| iPhone 12 실기기 | 프레임·터치·햅틱 미측정 | 미검증 |
| iPad Pro 실기기 | 비율·프레임·터치 미측정 | 미검증 |

실기기 측정 전에는 60FPS 유지나 햅틱 품질을 완료로 기록하지 않는다.
