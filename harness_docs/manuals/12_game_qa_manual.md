# 게임 QA 매뉴얼

## 역할 목적

요구사항·기능·물리·연쇄·시각·접근성·성능·회귀를 증거 기반으로 판정한다.

## 업무와 산출물

- 재현 절차, 기대 결과, 실제 결과, 심각도, 화면·로그·테스트 증거를 남긴다.
- 산출물: `harness_docs/qa/` 버그·회귀·스크린샷·검증 결과, 교차 리뷰, 품질 게이트 보고서.

## 사전 확인

기존 테스트 172개를 삭제하지 않고 기준으로 유지한다. 벽 비관통, 홀 우선, 닫힌 문, 공 연쇄, 풍선 고정 반사·뾰족함 팝, 한글 UI를 우선 확인한다.

## 판단 기준

물리 판정과 연출 순서가 맞고, 같은 입력이 같은 결과를 내며, 실패 시 필드 밖 이탈·점멸 이동·뒤늦은 팝업·클리어 누락이 없어야 한다.

## 검증 순서

1. 단위·도메인·물리 회귀.
2. 위젯·Golden·한글 문자열.
3. Web release·서버 HTTP·브라우저 콘솔·다중 해상도.
4. 수동 플레이와 접근성.

## 기본 명령·판정 기준

```bash
flutter test --reporter compact
flutter analyze
flutter build web --release
```

- 단위·위젯·Golden은 모두 통과해야 한다.
- 기존 회귀 수는 실행 시점 출력으로 기록하며, 과거 수치와 현재 수치를 같은 문장에 섞지 않는다.
- Web 루트와 `main.dart.js`는 HTTP 200이어야 한다.
- 다섯 목표 해상도에서 콘솔 오류 0건을 확인한다.
- P0/P1 미해결이면 구현 완료나 서버 최신화를 승인하지 않는다.

## 하지 말 것

한 번 통과한 화면을 최신 증거로 재사용하지 않는다. 테스트 수를 줄여 녹색을 만들지 않는다. 서버에 남은 이전 번들을 최신 결과로 오인하지 않는다.

## 협업·완료

물리·VFX·UX·접근성·성능의 확인을 모아 P0/P1이 없고, 명령·결과·잔여 위험이 문서화되면 완료다.

## 참고자료

- Flutter accessibility testing: https://docs.flutter.dev/ui/accessibility/accessibility-testing
- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- 현행 회귀 체크리스트: `harness_docs/qa/regression_checklist.md`
- 현행 스크린샷 매트릭스: `harness_docs/qa/screenshot_matrix.md`
