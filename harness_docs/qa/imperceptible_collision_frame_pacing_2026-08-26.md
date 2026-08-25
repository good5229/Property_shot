# 충돌 프레임 무감지 수준 페이싱 검증

## 문제와 원인

공·벽·상자 같은 일반 충돌마다 게임판 전체에 확대와 평행 이동을 적용했다. 실제 프레임 시간이 정상이어도 30~60 FPS에서는 보드 가장자리가 프레임 사이에 수 픽셀 이동해 끊김처럼 보일 수 있었다. 같은 충돌 콜백에서 Web Audio 노드와 햅틱 플랫폼 호출을 시작하고, 여러 파티클 효과가 매 프레임 새 `Paint`를 생성하는 비용도 겹쳤다.

## 수정 계약

- 일반 벽·문·상자·돌·공·젤리 충돌은 게임판 전체를 움직이지 않는다.
- 홀 진입, 풍선, 스위치, 파워 슬라이더, 회전 반사판처럼 장면 의미가 바뀌는 사건만 작은 카메라 강조를 사용한다.
- 강조 이동은 첫 프레임에서 0으로 시작하고 단일 연속 곡선으로 0에 돌아온다. 확대 최대값도 기존보다 낮춘다.
- 충돌 효과용 `Paint`는 효과별 인스턴스를 재사용해 타격 순간의 래퍼 할당과 GC 집중을 줄인다.
- Web 소리·진동 생성은 충돌을 그리는 현재 프레임이 끝난 뒤 시작한다. 게임 물리와 사건 순서는 바꾸지 않는다.
- 저모션에서는 기존처럼 카메라 변형을 적용하지 않는다.

## 자동 검증

```sh
flutter analyze
flutter test test/animation_timeline_test.dart test/game_feedback_test.dart
flutter test test/rotating_reflector_golden_test.dart test/stage_bouncy_gimmick_golden_test.dart test/stage4_causality_golden_test.dart
flutter test --concurrency=1
dart run tool/generate_stage_catalog.dart --check --validate-runtime
flutter build web --release --wasm
```

## 결과

- 정적 분석: 문제 0건
- 충돌 시간축·장치 피드백 집중 테스트: 33건 통과
- 충돌·기믹 시각 회귀: 53건 통과
- 전체 직렬 Flutter 테스트: 1,473건 통과
- 30·45·60 FPS 및 불규칙 30~60 FPS: 일반 충돌 보드 이동 0, 핵심 사건 첫 프레임 이동 0, 사건 순서·중복 없음
- 생산 40패턴 제한 실행과 카탈로그 동기화: 통과
- WebAssembly 릴리스 빌드: 통과

전체 병렬 실행에서는 서로 무관한 홈·실패 팝업 Golden 두 건이 테스트 간 전역 상태 간섭으로 실패했다. 두 테스트의 단독 재실행은 모두 통과했고, 간섭을 제거한 `--concurrency=1` 전체 1,473건도 통과했으므로 제품 회귀로 판정하지 않았다.

이 검증은 결정론적 렌더·시간축 계약과 배포 빌드 안정성을 증명한다. 실제 사용자의 지각이나 특정 GPU·브라우저의 프레임 시간을 대신한다고 표현하지 않는다. 공개 배포 뒤 동일 장면의 최종 체감 확인을 별도로 수행한다.
