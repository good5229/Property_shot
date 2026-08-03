# Goal 완료 감사

기준일: 2026-08-03 KST

## 최신 Release·성능 감사 보정

- 최신 `flutter build web --release`는 통과했고 `build/web/main.dart.js` SHA-256은 `4cdb3941b7d7f4bd91004f49954c8f95cf9dad92e41ccfe88c5f8a431a2bbf42`다. 이전 8080 서버를 종료한 뒤 최신 번들을 PID `34563`으로 제공 중이다.
- 최신 `scripts/web_performance_audit.py`는 Pillow 12.3.0 격리 환경에서 5초 워밍업 후 Long Task를 함께 수집했다. no-cache 번들의 390×844 발사 평균·p95는 25.681·66.6ms, 768×1024는 35.953·66.7ms이며 콘솔 오류는 0건이다.
- 빈 Chromium 기준은 두 해상도 모두 평균 약 16.7ms·p95 18.6ms다. Picture 캐시는 Golden 동적 효과 회귀로 제거했고 Web 60FPS 게이트는 아직 미통과다. 이 결과는 실기기 성능의 대체 증거가 아니다.
- 따라서 현재 종합 판정은 여전히 `실험 진행 중`이며, 렌더·래스터·Web 합성 비용 프로파일링, iPhone·Android·iPad 실기기 측정, 외부 초보 플레이테스트, Web·모바일 이벤트 지문 비교, 생성 에셋 권리 최종 검토가 남아 있다.

## 최신 저장·계측·런타임 보강

- 단계 정의에 안정적인 내부 ID를 추가하고 `ProgressStore`가 단계 ID 키와 기존 인덱스 키를 함께 읽고 쓰도록 보강했다. 배열 순서 변경과 구버전 숫자 키 복원 회귀를 추가했다.
- 플레이 계측을 메모리 전용에서 개인정보 없는 로컬 최근 이벤트 저장소로 확장했다. 최대 2,000개 이벤트를 순차 저장하고 복원·삭제할 수 있으며, 동시 기록 순서 회귀를 추가했다.
- 전체 `flutter test`: 최신 실행 기준 251개 통과
- `flutter analyze`: 통과
- `flutter build web --release`: 통과, `main.dart.js` SHA-256 `f22d8e7bd9e3f4156a5220eb0d37de7db8722fee1cb7095b18faa483e12bfaa8`
- `flutter build apk --release`: 통과, APK 57.3MB, SHA-256 `546be5692ab2d5b861c35ef7c1d9cf14b0d59a14efa1a7979a729e6eacafc9f6`
- Web 데모는 이전 서버를 종료한 뒤 PID `18121`로 8080에서 재시작했고 루트와 `main.dart.js` HTTP 200을 확인했다.
- Android ARM64 API 28 에뮬레이터에 최신 APK를 재설치·실행했고 앱 PID `4012`, `FATAL EXCEPTION` 0건을 확인했다. 최신 시작 화면 해시는 `281daca02f798c35d77b8caefccbfbb357a5cd74a24dfa266420084b02466486`이다.
- 기능 commit `bbd9117 feat: 로컬 계측과 안정 단계 저장 보강`을 원격에 push했다.

## 최신 저장 스키마·릴리스 재검증

- 저장 스키마 버전을 `1`에서 `2`로 갱신하고 안정 단계 ID 키 마이그레이션 회귀를 통과시켰다. 기능 commit `5dda324 fix: 저장 스키마 버전 갱신`을 원격에 push했다.
- 저장 스키마 2를 포함한 전체 `flutter test`: 251개 통과, `flutter analyze`: 통과
- 최신 Web Release `main.dart.js` SHA-256: `194b9635968c62249d50d7195379eaecb6637517b6ed73be8f3edd53b8369f36`
- 최신 Android Release APK SHA-256: `b8552526ddf24547f30d832791073ad319fa556884d895d6a6bdffeae7625214`
- 기존 Web 서버를 종료한 뒤 PID `30256`으로 8080 서버를 교체했고 루트·번들 HTTP 200을 확인했다.
- Android ARM64 에뮬레이터에 APK를 재설치·실행했다. 설치 직후 약 5.8초의 시작 화면 이후 앱 PID `4167`에서 한글 홈·공·돌·상자·홀 이미지를 확인했으며 `FATAL EXCEPTION`은 0건이다.
- 로딩 완료 캡처 `android-arm64-schema2-latest-layout.png` SHA-256: `16cd6fb99dbc740ac0799bec0aaa6048a0138150b3642ad669870210bc98cb00`

## 최신 계측 비용·릴리스 재검증

- 기능 commit `2489b55 perf: 로컬 계측 묶음 저장 보강`을 원격 브랜치에 push했다.
- 플레이 계측 저장을 이벤트별 쓰기에서 250ms 묶음 저장으로 바꾸고, 조회·화면 종료 시 대기 이벤트 flush를 보장했다.
- 전체 `flutter test`: 최신 실행 기준 252개 통과
- `flutter analyze`: 통과
- 물리 벤치마크: 1단계 381.1µs, 2단계 290.0µs, 3단계 302.2µs, 4단계 350.1µs
- 최신 Web Release `main.dart.js` SHA-256: `1fe40c3251534312926e5a93f41b409bbb95711d29ad01295d06da93ed904b88`
- 최신 Android Release APK SHA-256: `f914baa8786d339cf1abddbc18b4b4ef69c68f876e783fdb4555940c1c32f37f`
- 기존 Web 서버를 종료한 뒤 PID `81320`으로 8080 서버를 교체했고 새 루트·번들 HTTP 200을 확인했다.
- Android ARM64 에뮬레이터 최신 앱 PID `4338`, `FATAL EXCEPTION` 0건, 로딩 완료 한글 홈 화면 캡처 해시 `f10c347539533e3eb572be2b44d893b3ac4efad9c8caed983ed946d5913f4d23`

## 최신 계측 스키마·iOS·릴리스 재검증

- 계측 이벤트에 안정 `stage_id`, `result_code`, `route_tag` 필드를 추가한 기능 commit `898afd2 feat: 계측 이벤트 스키마 확장`을 원격 브랜치에 push했다.
- 전체 `flutter test`: 252개 통과, `flutter analyze`: 통과
- `flutter build web --release`: 통과, `main.dart.js` SHA-256 `4cdb3941b7d7f4bd91004f49954c8f95cf9dad92e41ccfe88c5f8a431a2bbf42`
- `flutter build apk --release`: 통과, APK 57.3MB, SHA-256 `ecb73064d8fb198f782cf02c8a4560c035171eb91985902fe6522f04138ce8e1`
- 기존 Web 데모 PID `48924`를 종료한 뒤 최신 빌드를 PID `75036`으로 8080에서 교체했고 루트·`main.dart.js` HTTP 200을 확인했다.
- Android ARM64 API 28 에뮬레이터에 최신 APK를 재설치·실행했고 앱 PID `4503`, `FATAL EXCEPTION` 0건을 확인했다. 최신 한글 홈 캡처 `android-arm64-batched-telemetry-latest.png` SHA-256은 `71fbfc08aa5f37d508837ea4ed3f224630547f240a005a7e080b9f0fa20ef6ed`다.
- `flutter build ios --no-codesign`에서 Xcode 컴파일은 완료됐고, Development Team·Provisioning Profile 부족으로 배포 가능한 iOS 앱 생성은 차단됐다.

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

따라서 현재 종합 판정은 **실험 진행 중**이다. 자동 검증과 Web·Android 에뮬레이터 기능 흐름은 확인했지만, 실제 iPhone·Android·iPad 성능, 외부 초보 플레이테스트, Web·모바일 이벤트 지문 동등성, 생성 에셋의 최종 법적 검토는 완료되지 않았다. 이 영역들을 통과하기 전에는 `Go` 또는 `Conditional Go`로 확정하지 않는다.

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
