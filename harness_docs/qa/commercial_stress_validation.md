# 반복 사용 스트레스 검증

작성 기준: 2026-08-09 KST

## 자동 검증 범위

| 항목 | 반복·범위 | 결과 |
|---|---:|---|
| 클리어 뒤 재도전 | 20회 | 콜백 1회, 팝업 제거, 조준 화면 복구, 위젯 예외 없음 |
| 개별 설정 저장 | 14개 설정 × 30회 | 직렬 저장 뒤 마지막 상태 전체 복원 |
| 리플레이 재생 | 동일 문서 100회 | 결과 지문·최종 발사 수 동일, 원문 문서 불변 |
| 연속 런 상태 | 1~10단계 | 단계별 점수·총점 누적과 새 세션 복원 |
| 저장 중단·손상 | A/B 슬롯 | 포인터 중단 뒤 완결 후보 선택, 최신 checksum 손상 때 이전 슬롯 복구 |

집중 실행은 69개 테스트와 `flutter analyze` 오류 0건으로 통과했다.

## Android Release 반복 메모리 대리 검증

- ARM64 API 28, 1080×1920, SwiftShader AVD에서 최신 Release APK를 사용했다.
- 단계 초기화·속성 이전·자동 발사를 20회 반복한 뒤 PSS는 93,517KB였다.
- 과거 공을 유지한 `다시 조준` 20회 첫 주기는 PSS 고수위가 120,520KB까지 증가했다.
- 단계 초기화 뒤 같은 20회 부하를 다시 가한 두 번째 주기는 시작 122,944KB, 종료 122,517KB로 추가 지속 증가가 없었다.
- 최종 화면에 시도 20회와 과거 공 20개가 표시됐고 앱 PID의 `FATAL` 및 Flutter 예외는 0건이었다.
- 원자료: `screenshots/commercial-vertical-slice/android-arm64-retry-memory-evidence.json`

## 실행 명령

```bash
flutter test test/game_feedback_test.dart test/replay_capture_service_test.dart test/retry_stress_test.dart test/stage_pattern_session_test.dart test/run_state_store_test.dart
flutter analyze
```

## 해석 한계

- 위젯 테스트에 더해 Android 에뮬레이터 PSS 고수위 재사용을 확인했지만 실제 heap·GPU 자산·플러그인 객체의 실기기 추세를 확정하지 않는다.
- 20분 플레이와 50회 재도전의 실기기 메모리 추세는 DevTools 또는 플랫폼 프로파일러로 별도 측정해야 한다.
- 10단계 검증은 생산 세션·저장 계층의 연속 흐름이다. 사람이 실제 UI를 통해 열 단계를 장시간 플레이한 증거는 아니다.
- 실제 백그라운드 전환, 화면 회전·크기 변경, 저메모리 종료는 기존 개별 회귀가 있으나 실제 모바일 운영체제의 종료 압력을 대체하지 않는다.
