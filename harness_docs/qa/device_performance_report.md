# 기기·성능 검증 보고서

작성 기준: 2026-08-03 KST
기준 브랜치: `commercial/wall-physics-qa`

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

Web 캡처 뷰포트는 `390×844`, `393×852`, `430×932`, `768×1024`, `1024×1366`이며 홈·섬 지도·플레이 화면을 확인했다.

## 빌드 상태

- `flutter analyze`: 통과
- `flutter build web --release`: 통과
- `flutter build ios --no-codesign`: Xcode 컴파일까지 통과
- iOS 배포 단계: Development Team과 프로비저닝 프로파일 부족으로 미완료
- iOS Simulator: 설치된 Runtime이 없어 실행 검증 미완료

## 필수 후속 측정

- iPhone 12급 세로 화면에서 평균 60FPS, p95 16.7ms, p99 25ms 확인
- 최근 노치·Dynamic Island 기기의 Safe Area와 터치 좌표 확인
- iPad Pro 4:3 화면의 보드·팝업·지도 카드 배치 확인
- 소형·중급 Android에서 입력 지연과 이미지 디코딩 확인
- 20분 플레이, 50회 재시도, 다중 공·다중 물체 스트레스 후 메모리 추세 확인
- 실제 iOS 햅틱·사운드 타이밍 확인

실기기 측정이 없으므로 현재 성능 판정은 `미검증`이다.
