# 관리자 도구 격리·애니메이션 최적화 검증

## 범위

- 공개 홈에서 `AI 제작 과정` 진입점을 제거한다.
- 일반 설정에서 세션 JSON 복사와 역할별 평가 복사를 숨긴다.
- 세 도구는 관리자 인증에 성공한 현재 앱 세션에서만 표시한다.
- 충돌과 기믹 연출의 물리 시간축을 바꾸지 않고 프레임당 조회·오디오 비용을 줄인다.
- Web 릴리스는 SkWasm을 우선 사용하고 호환되지 않는 브라우저에는 JavaScript 빌드를 제공한다.

## 보안 경계

GitHub Pages는 정적 호스팅이므로 이번 인증은 일반 사용자 화면에서 관리자 도구를 분리하는 표시 게이트다. 서버가 검증하는 실제 권한 경계는 아니다. 자격증명 원문은 저장하지 않고 SHA-256 비교값만 번들에 포함하며, 인증 상태는 로컬 저장소에 기록하지 않아 새로고침하면 해제된다. 관리자 도구가 외부 전송이나 서버 쓰기 권한을 갖게 될 경우 정적 게이트를 재사용하지 말고 서버 인증과 권한 검사를 추가해야 한다.

## 구현 증거

- ID와 비밀번호가 모두 일치할 때만 세션 관리자 상태를 연다.
- 실패 메시지는 어느 입력이 틀렸는지 구분하지 않고 비밀번호 입력을 매 시도 후 지운다.
- 인증 전에는 Puzzle Forge 경로, 세션 JSON 복사, 역할별 평가 복사가 렌더되지 않는다.
- 반사판 일정, 애니메이션 대상 ID, 엔티티 타입, 홀 충돌을 샷마다 한 번 계산해 프레임 루프의 반복 탐색을 제거한다.
- Web에서는 Web Audio와 시스템 사운드를 중복 실행하지 않고, 배경음 복구 재시도를 제한한다.
- 30·60·120·144Hz 업데이트에서 충돌 사건, 완료 콜백, 최종 상태가 동일한지 검사한다.

## 검증 명령

```sh
flutter analyze
flutter test test/admin_access_verifier_test.dart test/puzzle_forge_screen_test.dart test/animation_timeline_test.dart test/feedback_audio_native_test.dart test/core_path_localization_test.dart test/settings_golden_test.dart test/home_screen_golden_test.dart test/openai_core_path_golden_test.dart test/final_flow_golden_test.dart --concurrency=1
flutter test --concurrency=1
dart run tool/generate_stage_catalog.dart --check --validate-runtime
flutter build web --release --wasm --base-href "/Property_shot/"
```

## 시각 검수 행렬

- 모바일: 320×568, 390×844
- 태블릿: 768×1024, 1024×768
- 일반 PC: 1440×900
- 대형 모니터: 1920×1080

공개 홈에서는 관리자 기능이 보이지 않고, 설정 하단에는 인증 전 `관리자 도구` 진입점만 표시되어야 한다. 인증 후에만 세 관리자 기능과 로그아웃이 표시되어야 한다. 각 화면은 텍스트 겹침, 잘림, 가로 오버플로가 없어야 한다.

## 판정

- `flutter analyze`: 통과
- 집중 관리자·애니메이션·반응형 회귀 55건: 통과
- 전체 Flutter 테스트 1,470건: 통과
- 생산 40패턴 런타임 검증과 카탈로그 동기화: 통과
- SkWasm 우선·JavaScript 폴백 Web 릴리스: 빌드 통과
- 로컬 브라우저 320×568, 390×844, 768×1024, 1440×900, 1920×1080: 공개 홈·설정·로그인 배치 통과
- 공개 설정 DOM: 세션 JSON·역할별 평가 복사 미노출, 관리자 로그인만 노출
- 로컬 네트워크: `main.dart.wasm` HTTP 200, `application/wasm`; 브라우저 오류 로그 0건

배포 워크플로와 공개 URL의 최종 판정은 main push 뒤 GitHub Pages 실행 결과로 확인한다.
