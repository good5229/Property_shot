# PS-OBJ-02 회전 반사판 QA 검증 기록

기준일: 2026-08-06 KST

## 범위

`rotating_reflector`의 8방향 데이터·JSON 왕복, OBB 대 AABB SAT, 원형 공 corner normal, 직사각형 이동체 최소 분리축, 충돌·회전 사건 순서, 연쇄 이동, 벽·홀·점착 우선순위, runtime probe, replay 재구성을 검증한다. 기존 1~4단계 배치와 PS-STAGE 패턴 제작은 변경하지 않는다. 이 문서는 Luna 실행 증거이며 Sol의 독립 PASS 판정을 대신하지 않는다.

## 확인 항목

| 항목 | 검증 내용 | 결과 |
|---|---|---|
| 8방향 | orientation 0~7, `(before + 2) % 8`, count 증가, 화면 좌표 규칙 | 통과 |
| JSON 호환 | rotating reflector만 방향·횟수 필드 출력, 레거시 object JSON 키 불변 | 통과 |
| 원형 공 OBB | 축면 직격, 끝 cap, 대각 corner, 접촉 접선 보존 | 통과 |
| rectangular mover SAT | 반사판 normal/tangent·world x/y 4축, 최소 depth, 고정 tie 순서 | 통과 |
| 분리 | crate·weight의 AABB support와 같은 SAT normal, 잔여 overlap 없음 | 통과 |
| 사건 순서 | impact가 pre-orientation normal로 먼저 기록되고 rotation이 같은 target 뒤에 기록 | 통과 |
| 접촉 원장 | 동일 contact는 1회, 완전 이탈 후 다른 pathIndex 재접촉은 2회, 회전 직후 새 OBB 겹침은 중복 0회 | 통과 |
| 연쇄 범위 | movable spent ball·crate·weight 적용, fixed spent ball은 source가 아님 | 통과 |
| 다중 순서 | 다중 반사판·다중 이동 source의 실제 이동과 event ID·parent·type·path 순서가 엔티티 나열 순서에 무관 | 통과 |
| 우선순위 | hole, sticky, 고체 충돌, reflector rotation의 기존 상대 순서 보존 | 통과 |
| swept 연속성 | 반사판만 analytic swept(원-OBB face/corner, AABB-OBB 4축 SAT)로 판정하고 일반 고체는 1.25 샘플을 유지 | 통과 |
| swept 순서 | analytic 반사판 후보와 일반 후보를 전체 progress로 비교해 앞선 벽·홀·슬라이더·이동체를 선점하지 않음 | 통과 |
| 얇은 벽 | 최소 두께 반사판/얇은 벽 충돌, 반사 후 벽·보드 경계 재검사, 벽 EntityState 전체 불변 | 통과 |
| 저장·replay | 기존 RunState shotInputLog 왕복 후 순차 resolve의 orientation/count/fingerprint 일치 | 통과 |
| 결정론 | 동일 입력 100회 fingerprint와 event ID·parent·kind·order 동일, RunState 최종 rotation count > 0 | 통과 |
| 8방향 반사 | orientation 0~7 각각 기대 반사 단위 벡터와 pre-orientation normal을 비교 | 통과 |
| runtime probe | 적용 여부와 실제 countDelta/event payload를 비교하고 rotation-before-impact·wrong parent·velocity mismatch를 양성 검출 | 통과 |
| qualifying 계약 | sticky·동일 contact impact는 비자격, 새 nonsticky impact는 자격으로 기록하고 probe가 누락과 비자격 가짜 회전을 모두 구분 | 통과 |
| 사건 속도 | active·chain 반사판 impact의 resulting velocity가 동일 회전 사건의 실제 velocityAfter와 일치 | 통과 |
| 시각 계약 | Canvas OBB debug hitbox, 회전 사건 후에만 새 방향 노출, 회전 OBB 터치·접근성 영역, 한글 라벨 | 통과 |
| reduced 다중 일정 | 같은 path의 복수 회전은 원래 pathIndex에서 최종 방향으로 즉시 누적하고 queue 지연을 만들지 않음 | 통과 |

## 집중 실행 증거

```text
flutter test test/rotating_reflector_physics_test.dart
30 tests passed

flutter test test/stage_pattern_runtime_probe_test.dart
25 tests passed

flutter test test/rotating_reflector_golden_test.dart
16 tests passed (14 Golden + rotated selection + multi-rotation schedule)

flutter test --concurrency=1 --reporter compact
508 tests passed

flutter analyze
집중 실행에서 No issues found!

dart run tool/generate_stage_catalog.dart --check
스테이지 카탈로그 생성본이 최신입니다.

flutter build web --release
Web Release 빌드 성공
```

집중 fixture는 다음을 포함한다.

- 390x844·768x1024 Golden 14개를 실제 PS-OBJ-02 화면 상태 fixture로 갱신·재비교했다. impact는 이전 방향, progress는 45도 중간, complete/reduced는 수직 after 방향으로 직접 확인했다.
- 축면, 대각, impact 직전, 회전 진행·완료, 팝업, 저모션 상태가 동일 이벤트 로그와 화면에 연결된다.
- 회전 본체와 debug OBB가 `-pi/2 + orientation*pi/4` 계약으로 일치하고, 진행 상태는 8 cursor 단위의 시계 방향 90도 보간을 사용한다.
- 임시 출력문은 테스트 파일에 남기지 않으며, 물리 결과는 matcher와 fingerprint로만 검증한다.
- replay signature와 runtime probe fingerprint에는 impact·generic physics의 source/contact/qualifying 플래그를 포함한다.
- 강화된 fingerprint 계약에 맞춰 단일 샷 16개와 다중 샷 20개의 저장 기준을 재생성했다. 입력·경로·예상 종료 상태는 유지되고 fingerprint만 변경됐으며, 두 fixture 재생 테스트가 모두 통과했다.

## 최종 전체 검증

P1 보완과 리플레이 기준 갱신 이후 `flutter test --concurrency=1 --reporter compact`에서 508개 테스트가 모두 통과했다. `flutter analyze`는 `No issues found!`, 생성 카탈로그 `--check`는 최신 상태, `flutter build web --release`는 성공으로 끝났다. 390x844·768x1024의 14개 Golden을 직접 비교해 충돌 전 방향, 회전 중간 방향, 회전 완료 방향, 팝업과 저모션 상태가 서로 구분되는 것도 확인했다.

독립 QA가 비자격 impact의 가짜 회전 검출 누락, 연쇄 이동체 impact·rotation의 결과 속도 불일치, 회전 후 고정된 선택 영역을 찾아 1차 FAIL 판정했다. 보완 후 모든 회전은 정확히 하나의 qualifying 부모를 요구하고, impact는 실제 `velocityAfter`를 공유하며, 터치와 접근성 영역은 회전 OBB를 따른다. 각 결함의 양성 회귀를 추가했고 두 번째 독립 재검토도 새 P0/P1 없이 PASS했다.

기존 1~4단계 원본 카탈로그에는 회전 반사판을 배치하지 않았고 생성본 드리프트도 없다. 벽 상태 불변, 홀·점착 우선순위, 다중 이동체 연쇄, 고속 swept 충돌, 사건 순서와 replay 결정론을 집중·전체 회귀에서 함께 검증했으므로 PS-OBJ-02를 PASS로 판정한다.

## 잔여 위험

- 실제 모바일 GPU의 OBB debug overlay와 회전 애니메이션 프레임은 실기기 캡처가 필요하다.
- 공식 replay service 연결은 PS-REPLAY-01 범위다. 이번 작업에서는 RunState 생산 코드를 확장하지 않았다.
- analytic swept는 이번 작업에서 `rotating_reflector`에만 적용한다. 일반 고체의 기존 1.25 논리 단위 샘플링 성능·경계는 전체 회귀로 확인하지만, 별도 연속 해석으로 확장하지 않는다.
- 전체 회귀의 `multi_shot_analyzer_test.dart` 한 fixture는 약 1분 동안 진행 표시가 정체된 뒤 통과했다. 실패나 비유한 상태는 아니지만, 후속 성능 분석 대상이다.
