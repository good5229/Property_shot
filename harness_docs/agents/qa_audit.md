# QA 독립 감사

## 통과 근거

- `flutter analyze` 문제 없음.
- `flutter test` 105개 통과.
- 320x568·390x844 위젯에서 팝업 경계, 한글 안내, 접근성, 축약 보드 폭을 확인했다.
- 동일 물리 입력, 벽·홀 우선순위, 연쇄 이벤트, 복사권 소모·복원을 회귀로 고정했다.
- Web release 빌드와 새 8080 서버의 루트·번들 HTTP 200을 확인했다.

## 미통과 또는 미검증

- `flutter build ios --no-codesign`은 Swift Package Manager 의존성 해결 단계에서 실패했다.
- 실제 iPhone/iPad 프레임·메모리·터치·햅틱과 Canvas 픽셀 골든은 미검증이다.
- 자동 성공 영역이 초보자의 이해도를 대체하지 않는다.
