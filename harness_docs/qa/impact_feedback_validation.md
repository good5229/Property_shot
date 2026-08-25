# 충돌 피드백·저모션 검증

## 제품 변경

- 물리 충격량을 `tap`, `light`, `heavy`, `critical` 4단계로 분류한다.
- 같은 벽에 부딪혀더라도 실제 충격량에 따라 효과음과 진동 강도가 달라진다.
- 중간 이상 충돌에 20~46ms의 짧은 타격 정지를 적용해 시각적 무게를 준다. 물리 결과와 이벤트 순서는 바꾸지 않는다.
- 화면 흔들림도 같은 충격량을 사용하며 사용자 설정 강도를 유지한다.
- 앱 설정과 운영체제 `disableAnimations` 중 하나라도 켜져 있으면 타격 정지와 화면 흔들림을 제거한다.

## 회귀 검증

- 30·60·120Hz: 충돌 이벤트와 완료 콜백은 정확히 한 번씩 발생
- 강한 충돌: 다음 프레임의 커서가 멈추고 설정 시간 후 계속 진행
- 저모션: 동일한 충돌에서 커서 정지 없이 진행
- 운영체제 접근성 설정: `GameScreen`이 실제 `PropertyShotGame`에 전달
- 효과음 큐: 동일 재질의 0.18/0.92 충격량을 가벼운/강한 타격으로 구분

검증 파일은 `test/animation_timeline_test.dart`, `test/impact_feedback_test.dart`, `test/game_feedback_test.dart`, `test/reduced_motion_integration_test.dart`다.
