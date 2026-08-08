# PS-UX-02 실패 인과 재생·설정 검증

## 범위

- 실패 직전 약 3초를 기존 `ShotResult` 타임라인으로 반속도 재생한다.
- 재생은 최종 판정을 다시 계산하지 않으며, 원본 발사 시작 상태와 결과를 읽기 전용으로 사용한다.
- 실패 원인, 충돌 순서, 마지막 접촉 대상, 홀 최근접 위치를 한글로 표시한다.
- 실패 팝업에서 인과 재생, 다시 조준, 입력 조정을 선택할 수 있다.
- 효과음, 진동, 모션 감소, 카메라 흔들림 강도, 도움말 다시 보기를 설정한다.
- 설정은 `SharedPreferences`에 저장하고 스키마 버전 2로 마이그레이션한다.

## 구현 위치

| 항목 | 파일 |
| --- | --- |
| 실패 원인 분석 | `lib/game/analysis/failure_replay.dart` |
| 읽기 전용 타임라인 재생 | `lib/ui/failure_replay_dialog.dart`, `lib/game/property_shot_game.dart` |
| 실패 팝업 연결 | `lib/ui/game_screen.dart` |
| 피드백 설정·마이그레이션 | `lib/ui/game_feedback.dart`, `lib/main.dart` |

## 자동 검증

- `test/failure_replay_test.dart`: 원인·충돌 표기와 분석 과정의 상태 불변을 검증한다.
- `test/game_feedback_test.dart`: 기존 설정 마이그레이션, 흔들림 강도, 도움말 다시 보기 저장을 검증한다.
- `test/settings_widget_test.dart`: 320x568 화면과 큰 글자 배율 1.5에서 설정 메뉴를 열고 조작한다.
- `test/widget_test.dart`: 실패 팝업에서 인과 재생을 열고 닫은 뒤 기존 재시도 흐름이 유지되는지 검증한다.

## 수동 검증 잔여 항목

- 실제 iOS·Android 기기에서 효과음, 진동, 모션 감소, 카메라 흔들림 강도를 확인한다.
- VoiceOver·TalkBack에서 재생 화면, 충돌 순서, 설정 컨트롤의 한글 접근성 라벨을 확인한다.
- 큰 글자 최댓값에서 실패 팝업과 설정 메뉴의 세로 스크롤 및 버튼 접근성을 확인한다.
