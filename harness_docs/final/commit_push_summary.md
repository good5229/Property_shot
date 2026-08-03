# Commit·Push 요약

브랜치: `commercial/wall-physics-qa`

## 최신 기준

작업별 커밋은 모두 원격 브랜치에 Push되어 있다. 최신 원격 HEAD는 문서 갱신 전 기준 `bbd9117`이다.

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

최신 검증 기준은 전체 Flutter 테스트 251개, `flutter analyze`, Web Release 빌드, Android Release APK 빌드다. 데모 서버는 기존 PID 18121을 먼저 종료한 뒤 PID 30256으로 교체했으며, 최신 `main.dart.js` 해시는 `194b9635968c62249d50d7195379eaecb6637517b6ed73be8f3edd53b8369f36`다. 최신 Android Release APK는 57.3MB이고 ARM64 에뮬레이터 설치·시작 스모크와 로딩 완료 한글 시작 화면 캡처를 통과했다.

| Commit | 내용 | Push |
|---|---|---|
| `70b5f79` | 풍선 뒤 스위치 인과와 우회 풀이 고도화 | 완료 |
| `25252a3` | 스테이지4 시각 인과·한글 UI·Golden | 완료 |
| `656a84e` | 역할 활성화·스테이지4 QA 근거 | 완료 |
| `b88e14d` | 최신 데모 서버 검증 기록 | 완료 |

검증: 비다중샷 212개, 다중샷 1개, `flutter analyze`, `flutter build web --release` 통과. 이전 서버 PID 44882 종료 후 최신 서버 PID 67394를 8080에 띄우고 루트·`main.dart.js` HTTP 200을 확인했다.
