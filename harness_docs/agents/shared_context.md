# 공유 컨텍스트

이 문서는 현재 반복의 공통 기준을 짧게 고정한다. 상세 기록은 [current_shared_context.md](current_shared_context.md)와 [collaboration_protocol.md](collaboration_protocol.md)를 따른다.

- 단일 탑뷰, 논리 좌표 360x560, 순수 Dart 판정과 Flame 연출을 유지한다.
- 속성은 무거움·탄성·점착이며, 이전과 제한 복사를 구분한다.
- 복사권은 1/1/2회이고 성공 때만 차감되며 되감기·초기화 때 복원된다.
- 홀에 도달하는 물리 경로는 특정 기믹을 요구하지 않는다.
- 모든 화면 문구는 한글이며 실제 사용자 테스트와 iOS 실기기 검증은 별도 미완료다.

## 최신 증거

- `flutter analyze`: 통과
- `flutter test`: 105개 통과
- `flutter build web --release`: 통과
- 2026-08-02 독립 Subagent 재평가: 기능·물리 조건부 통과, 실기기·사용자 이해도 미검증
