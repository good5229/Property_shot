# 검증 결과

실행 일시: 2026-08-01 KST

| 명령 | 결과 |
|---|---|
| `dart format --output=none --set-exit-if-changed .` | 통과, 변경 없음 |
| `flutter analyze` | 통과, 이슈 없음 |
| `flutter test` | 통과, 67개 |
| `flutter build web --release` | 통과 |
| `curl http://127.0.0.1:8080` | HTTP 200, 새 빌드 서버 |
| `flutter build ios --no-codesign` | Xcode 빌드 완료 후 Development Team/프로비저닝 프로파일 부족으로 배포 빌드 실패 |

기존 8080 프로세스를 종료한 뒤 새 빌드 서버를 시작했고 HTTP 200 응답을 확인했다.

이번 검증에는 벽 네 방향 경계, 연쇄 벽 반사, 벽 충돌 법선 시각 피드백, 탄성 학습 단계의 일반 공 감속, 재질별 반발력, 동일 질량 공 충돌, 점착 지속성, 연쇄 스위치 조건, 홀 경계 성공·실패, 실패 복구 패널, 팝업 접근성 격리, 접근성 힘 조절, 보드 우선 반응형 레이아웃 회귀가 포함되며 전체 67개 테스트가 통과했다.
