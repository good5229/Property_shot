# Commit·Push 요약

브랜치: `commercial/wall-physics-qa`

## 최신 기준

작업별 커밋은 모두 원격 브랜치에 Push되어 있다. 아래 표에 기능·증거·문서 보정 작업의 주요 원격 커밋을 기록한다.

| Commit | 내용 | Push |
|---|---|---|
| `0552e4d` | Android ARM64 런타임 스모크 증거 및 캡처 | 완료 |
| `fe86495` | 최신 Web 데모 서버 교체·검증 문서 | 완료 |
| `4b83361` | Debug 진단 내부 물체 ID의 한글 표시명 변환 | 완료 |
| `6f774a1` | Android 단계4 전체 흐름 캡처·로그 증거 | 완료 |
| `2b430d7` | 최신 Release 빌드·Web 서버 PID·검증 기준 갱신 | 완료 |
| `74e86e5` | `ProgressStore` 동시 저장 순서 보장 및 회귀 | 완료 |
| `5425dcb` | 4단계 물체 경계·저장소 공유·고속 회귀·리플레이·Golden 갱신 | 완료 |
| `bbd9117` | 로컬 계측 저장·안정 단계 ID·구버전 저장 호환·회귀 테스트 | 완료 |
| `5dda324` | 저장 스키마 버전 2와 마이그레이션 회귀 | 완료 |
| `2489b55` | 250ms 로컬 계측 묶음 저장·조회/종료 flush·회귀 테스트 | 완료 |
| `898afd2` | 안정 stage_id·result_code·route_tag 계측 필드·회귀 테스트 | 완료 |
| `174be05` | 최신 계측·Web·Android·iOS 검증 증거 문서와 캡처 | 완료 |
| `a35c373` | 최신 원격 HEAD 표기 보정 | 완료 |

최신 검증 기준은 전체 Flutter 테스트 252개, `flutter analyze`, Web Release 빌드, Android Release APK 빌드다. 데모 서버는 기존 PID 48924를 먼저 종료한 뒤 PID 75036으로 교체했으며, 최신 `main.dart.js` 해시는 `4cdb3941b7d7f4bd91004f49954c8f95cf9dad92e41ccfe88c5f8a431a2bbf42`다. 최신 Android Release APK는 57.3MB이고 ARM64 에뮬레이터 설치·시작 스모크와 로딩 완료 한글 시작 화면 캡처를 통과했다. iOS는 Xcode 컴파일 후 서명 환경 부족으로 배포 단계가 차단됐다.
`2489b55 perf: 로컬 계측 묶음 저장 보강`을 기능 단위로 별도 commit하고 `commercial/wall-physics-qa` 원격 브랜치에 push했다.

| Commit | 내용 | Push |
|---|---|---|
| `70b5f79` | 풍선 뒤 스위치 인과와 우회 풀이 고도화 | 완료 |
| `25252a3` | 스테이지4 시각 인과·한글 UI·Golden | 완료 |
| `656a84e` | 역할 활성화·스테이지4 QA 근거 | 완료 |
| `b88e14d` | 최신 데모 서버 검증 기록 | 완료 |

검증: 비다중샷 212개, 다중샷 1개, `flutter analyze`, `flutter build web --release` 통과. 이전 서버 PID 44882 종료 후 최신 서버 PID 67394를 8080에 띄우고 루트·`main.dart.js` HTTP 200을 확인했다.
