# 로컬 세션 역할별 평가기 검증

검증 기준: 2026-08-25 KST

## 역할과 경계

- 설명을 건너뛰는 심사자: 첫 3분 네 이정표와 첫 발사 시간을 본다.
- 성급한 모바일 사용자: 반복 빈 공간 입력, 충전 취소, 재시도, 포기를 본다.
- 퍼즐 숙련자: 한 세션에서 실제로 발생한 서로 다른 핵심 상호작용과 클리어를 본다.
- 키보드·접근성 사용자: 각도·힘 미세 조정 사용 증거와 별도 수동 확인 필요성을 본다.

평가기 결과는 관찰 가능한 사건을 정해진 규칙으로 분류한 대리 보고서다. 사람의 재미·감정·이해도를 입증하거나 LLM의 주관적 플레이 소감으로 표현하지 않는다.

## 제품 연결

- 설정의 `내 플레이 기록`에 `역할별 평가 복사`를 추가했다.
- 현재 세션의 개인정보 제거 JSON을 다시 읽어 Markdown 보고서를 만든다.
- 링크를 만들거나 서버로 전송하지 않는다.
- 개발 환경에서는 `dart run tool/review_local_session.dart <session.json>`으로 같은 보고서를 출력할 수 있다.
- 각도·힘 미세 조정 버튼과 키보드 조작은 `precision_control_adjusted` 사건으로 기록한다.

## 자동 검증

```text
flutter test test/session_role_review_test.dart test/settings_golden_test.dart test/keyboard_accessibility_test.dart --concurrency=1
10 tests passed

flutter analyze <changed files>
No issues found
```

설정 Golden은 320×568, 390×844, 768×1024에서 새 평가 항목의 겹침·잘림을 확인한 뒤 갱신하고, 업데이트 옵션 없이 다시 비교해 통과했다.

## 판정

통과. 사람을 모집하지 못하는 상황에서도 동일한 세션을 네 관점으로 반복 비교할 수 있다. 실제 재미 판단과 VoiceOver·TalkBack 체감은 여전히 별도 사람·실기기 검증 범위다.
