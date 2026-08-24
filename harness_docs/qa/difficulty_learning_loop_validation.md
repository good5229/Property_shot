# 난도·학습·반복 루프 검증

검증 기준: 2026-08-25 KST

## 난도 조정 원칙

- 실제 `ShotResolver`와 고정 시드 가상 플레이를 함께 사용한다.
- 한 번에 한 변수군만 변경하고, 대표 해법·선택 도전·기믹 우위가 깨지면 변경을 폐기한다.
- 기물 충돌 범위 확대가 연쇄 순서를 바꾸는 경우에는 쉬워지더라도 채택하지 않는다.
- 의도한 반사 경로를 수행한 뒤 홀 가장자리에서 발생하는 근접 실패만 제한적으로 구제한다.

## 채택 결과

| 패턴 | 변경 | 모바일 초보 STANDARD | 일반 PC STANDARD | 성급한 조작 STANDARD |
|---|---|---:|---:|---:|
| `stage_bouncy_02` | 홀 포획 배율 `0.88 → 1.20` | `18% → 24%` | `32% → 46%` | `31% → 36%` |
| `stage_bouncy_04` | 홀 포획 배율 `0.88 → 0.96` | `15% → 16%` | `34% → 34%` | `18% → 18%` |

두 패턴 모두 `STANDARD < OFF` 회귀가 없고 안전 중단은 0건이다. 2번 패턴은 보이는 홀 반지름과 실제 포획 반지름의 차이를 6.1 논리 픽셀 이하, 4번 패턴은 2.1 이하로 제한했다.

## 폐기한 후보

- `balloon_b`, 비워진 속성 원본, 속도 발판, 회전판의 충돌 범위를 직접 넓히는 후보는 대표 해법의 충돌 순서나 성공을 깨뜨려 폐기했다.
- `stage_bouncy_04`의 홀을 더 크게 잡는 후보는 기존 두 벽 반사 풀이가 홀에 일찍 포획되어 풀이 계열 증거가 사라져 폐기했다.
- 다중 샷 패턴의 낮은 최종 성공률은 어느 샷이 병목인지 분리하기 전까지 배치 변경 근거로 사용하지 않는다.

## 검증 명령

- `dart run tool/generate_stage_catalog.dart --validate-runtime`
- `flutter test test/stage_catalog_test.dart test/stage_bouncy_patterns_test.dart`
- `flutter test test/all_stage_gimmick_advantage_test.dart`
- `dart run tool/generate_virtual_player_report.dart`

최종 수치는 `harness_docs/qa/intent_assist_virtual_player_report.md`에 저장한다.

## 캠페인 첫 cycle 학습 파형

- 10개 스테이지마다 패턴을 `learn → confirm → apply → mastery` 역할로 명시했다.
- 첫 cycle의 네 번만 역할 순서로 노출하고, 두 번째 cycle부터 기존 결정론 셔플을 그대로 사용한다.
- 기존 first-cycle 중간 저장은 이미 저장된 `remainingPatternIds`를 다시 배열하지 않는다.
- 일일 도전과 탐사 세션은 공용 셔플 정책을 유지한다.
- `drained_03`처럼 쉬운 규칙 확인 패턴은 learn, `balloon_04`·`rotating_reflector_03`처럼 정밀도가 높은 패턴은 mastery에 배치했다.

역할 계획은 현지화된 난도 문자열이나 파일명 순서를 파싱하지 않고 typed `CampaignPatternRole`과 안정 패턴 ID 목록으로 관리한다. 카탈로그와 목록이 다르거나 역할이 빠지면 fresh 캠페인 draw가 명시적으로 실패한다.
