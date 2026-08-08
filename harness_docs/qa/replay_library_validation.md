# PS-REPLAY-02A 로컬 리플레이 라이브러리 검증

기준일: 2026-08-08 KST

## 저장 계약

- `ReplayDocument.toCanonicalJson()`의 SHA-256으로 `replay_<64자리 hex>` 식별자를 만든다.
- 문서 원문은 기존 UTF-8 16KiB 상한을 그대로 적용한다.
- 목록 메타데이터는 생성 UTC 시각, 모드, 일일 도전 식별 정보, 단계·패턴, 총점, 샷 수만 저장하며 개인정보를 저장하지 않는다.
- 기본 최대 24개, 제품 상한 64개다. 같은 모드·도전·단계·패턴에서 높은 점수, 동점이면 적은 샷을 최고 기록으로 계산한다.
- 용량 초과 시 오래된 비최고 기록을 먼저 지우고, 모든 항목이 최고 기록이면 가장 오래된 항목부터 정리한다.
- 라이브러리는 기존 RunState·진행·오늘의 도전 키와 겹치지 않는 revision/checksum A/B 슬롯을 사용한다.

## 중단·호환 계약

- 새 슬롯을 완전히 쓰고 다시 읽어 검증한 뒤 pointer를 변경한다. pointer 기록 전 중단되어도 높은 유효 revision을 복구한다.
- 최신 슬롯의 checksum·문서·메타데이터가 손상되면 직전 유효 슬롯로 복구한다.
- 과거 공 회수 시점이 없는 문서는 `unsupported_between_shot_state`로 저장 전에 거부한다.
- resolver·카탈로그 불일치는 저장 문서를 재생할 때 기존 `ReplayCaptureService`의 명시 실패로 처리한다.
- UI 연결 순서는 반드시 `ReplayLibraryStore.save` 후 `StagePatternSession.recordCurrentStageReplayReference`다. 두 저장소는 교차 트랜잭션이 아니므로 이 순서로 dangling reference를 막는다.

## 후속 UI 연결 API

- 목록: `ReplayLibraryStore.load()`
- 문서 읽기: `ReplayLibraryStore.readDocument(replayId)`
- 저장: `ReplayLibraryStore.save(document: ..., totalScore: ...)`
- 삭제: `ReplayLibraryStore.delete(replayId)`
- 현재 런 연결: `StagePatternSession.recordCurrentStageReplayReference(stageId: ..., replayId: ...)`

이번 작업은 `main.dart`, `game_screen.dart`, `daily_challenge_screen.dart`, 클립보드와 재생 화면을 수정하지 않는다.

## 자동 검증

- 전용 저장·복구·통합 테스트 7개 통과
- 지정 변경 파일 `flutter analyze` 이슈 0건
- 저장된 실제 캡처 문서의 playback 결과 지문 재검증 통과
