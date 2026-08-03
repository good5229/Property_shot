# Goal 완료 감사

기준일: 2026-08-03 KST

## 최신 레벨·런타임 보정

- 4단계 `balloon_crate`가 논리 보드 밖 `y=640`에 있던 P1 배치 결함을 `y=400`으로 수정했다. 화면 Golden에서 상자 전체가 보이고 하단 조작 패널에 가리지 않는 것을 확인했다.
- 이동 가능한 초기·연쇄 엔티티의 히트박스가 논리 보드 안에 남는 경계 회귀를 추가했고, 네 단계 16방향·3개 힘 입력 192개에서 안전 중단·비유한 좌표·필드 이탈이 없음을 확인했다.
- 홈 라우터와 플레이 화면에 동일 `ProgressStore`를 주입해 앱 한 세션의 진행 저장 큐를 공유한다. 실제 클리어 후 주입 저장소 재조회 위젯 회귀도 통과했다.
- 고정 2발 리플레이 시드를 결정 격자 자동 탐색으로 바꿔 레벨 배치 변경에도 생성기가 검증된 2발 시드를 찾도록 했다.
- 전체 `flutter test`: 최신 실행 기준 247개 통과
- `flutter analyze`: 통과
- `flutter build web --release`: 통과, `main.dart.js` SHA-256 `dd82d9304257e16161a62db9a4f1d72d5721c84903137e60bbfc9ca79cb17bda`
- `flutter build apk --release`: 통과, APK 57.3MB, SHA-256 `246e6052aa8ab2ca5bcf275ab785c643a7469d0770f964fb7aa7e34a3dd5d854`
- Web 데모: 이전 PID 31813을 종료한 뒤 최신 빌드를 PID 84934 유지 세션에서 제공한다.
- Android ARM64 API 28 에뮬레이터: 최신 APK 설치·실행, 앱 PID 3708, 1080×1920 시작 화면 캡처, `FATAL EXCEPTION` 0건.
- 변경 커밋: `5425dcb fix: 4단계 물체 경계와 저장소 공유 보강`, 원격 브랜치 푸시 완료

## 최신 저장 동시성 보정

- `ProgressStore`의 동일 인스턴스 작업을 `_writeTail` 기반 순차 큐로 묶어 클리어·최고 기록·보너스·복제 코어·초기화·전체 해금의 읽기-수정-쓰기가 서로 덮어쓰지 않게 했다.
- 동시 클리어 3건, 최고 기록 2건, 보너스 기록을 동시에 요청해 클리어 집합·다음 해금 단계·최고 기록·보너스가 모두 보존되는 회귀를 추가했다.
- 전체 `flutter test`: 최신 실행 기준 247개 통과
- `flutter analyze`: 통과
- `flutter build web --release`: 통과, `main.dart.js` SHA-256 `8d93ef76caafa5dbe97ce7a70c1f038987fb2ab81f68a89ba201bf5f97bb34ad`
- `flutter build apk --release`: 통과, APK 57.3MB
- Web 데모: 기존 PID 95164를 종료한 뒤 최신 빌드를 PID 31813 유지 세션에서 제공한다.
- 변경 커밋: `74e86e5 fix: 동시 저장 순서 보장`, 원격 브랜치 푸시 완료

## 최신 감사 보정

이 문서는 초기 감사 기록을 보존하면서 최신 실행 증거를 아래와 같이 추가한다.

- 전체 `flutter test`: 최신 실행 기준 245개 통과
- `flutter analyze`: 통과
- `flutter build web --release`: 통과
- `flutter build apk --release`: 통과, ARM64 Android 런타임 설치에 사용한 최신 APK 57.3MB
- Web 데모: 기존 프로세스를 종료한 뒤 최신 빌드를 PID 31813 유지 세션에서 8080에 실행. `main.dart.js` SHA-256은 `8d93ef76caafa5dbe97ce7a70c1f038987fb2ab81f68a89ba201bf5f97bb34ad`다.
- Android ARM64 API 28 에뮬레이터: 지도 `4 / 4`, 4단계 설명, 뾰족함 속성 이전, 충전·자동 발사, 스위치·문, 홀 성공, 클리어 팝업을 실제 입력으로 재생
- Android 실행 로그: 앱 `FATAL EXCEPTION` 0건. 단, 에뮬레이터는 실기기 성능·GPU·메모리·햅틱 증거가 아님
- Debug 진단 화면의 내부 영문 ID 노출은 `4b83361`에서 한글 표시명 변환과 회귀 테스트로 수정

따라서 현재 종합 판정은 **Conditional Go**다. 자동 검증과 Web·Android 에뮬레이터 기능 흐름은 확인했지만, 실제 iPhone·Android·iPad 성능, 외부 초보 플레이테스트, 생성 에셋의 최종 법적 검토는 완료되지 않았다. 이 세 영역을 통과하기 전에는 최종 Go로 승격하지 않는다.

| 요구 영역 | 현재 증거 | 판정 |
|---|---|---|
| 18개 매뉴얼·역할별 업무 | `harness_docs/manuals/00..17` | 저장소 확인 |
| 공식 웹 참고자료 | `role_reference_index.md`, `web_reference_verification_2026-08-03.md` | 확인 |
| 활성화·독립 진단·교차 검토 | `activation_records.md`, `independent_reviews.md`, `manual_cross_review_2026-08-03.md` | 확인 |
| UX Writer·한글 문구 | `copy_inventory.md`, `copy_validation.md`, 위젯·Golden | 자동 확인 |
| 스테이지4 인과·우회 | `stage4_causality_redesign.md`, `stage4_validation.md`, 순서 테스트 | 통과 |
| 홀·깃발 깊이·포획 우선 | `hole_flag_layering_spec.md`, `hole_flag_validation.md`, 25 Golden | 통과 |
| 신규 에셋·상태·권리 | `art/`, `asset_registry.md`, `attribution.md`, `license_review.md` | 권리 최종 확인 잔여 |
| 자율 제안 평가 | `proposal_scoreboard.md` | 3건 채택, 2건 거절 |
| 자동 검증 | 비다중샷 212개 + 다중샷 1개, `flutter analyze` | 통과 |
| Web release·서버 | `commit_push_summary.md`, PID 67394, HTTP 200 | 확인 |
| 실기기·사용자 | `remaining_risks.md`, `accessibility_validation.md` | 미검증으로 명시 |

## 판정 방식

`확인`은 파일·명령 출력·Golden·서버 응답이 있는 항목이다. 실제 기기·사용자·법무 검증이 없는 항목은 완료로 위장하지 않고 잔여 위험으로 남긴다. 외부 자료는 프로젝트 규칙의 근거이지 물리 성공이나 상업 권리의 자동 승인이 아니다.
