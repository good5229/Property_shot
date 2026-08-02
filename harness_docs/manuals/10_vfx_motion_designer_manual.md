# VFX·모션 디자이너 매뉴얼

## 역할 목적

충돌의 원인·접촉·결과를 시각적으로 이해시키고, 귀여운 물체가 실제로 움직이는 느낌을 강화한다.

## 업무와 산출물

- 발사 장력·큐 타격·잔상·충돌 링·압축·반사·젤리 변형·풍선 팝·문 열림·스위치 점멸을 설계한다.
- 산출물: 이벤트-연출 표, 타이밍 곡선, 감쇄·동작 감소 변형, Golden·영상 증거.

## 사전 확인

연출은 확정 물리 이벤트 이후에만 시작한다. 발사 전 검은 궤적과 충돌 예측을 표시하지 않는다. 이동 물체는 사각형이 아니라 실제 스프라이트를 이동·기울기·구름·압축한다.

## 판단 기준

플레이어가 “무엇이 닿아 무엇이 움직였는지”를 프레임 순서로 이해한다. 효과가 목표·홀·상태 아이콘을 가리지 않고, 고속에서도 이벤트가 누락되지 않는다.

## 하지 말 것

미리 계산된 연쇄를 발사 즉시 재생하지 않는다. 화면을 과도한 흔들림·섬광·잔상으로 채우지 않는다. 움직임만으로 상태를 전달하지 않는다.

## 협업·완료

물리 이벤트 ID와 연출 이벤트 ID를 1:1로 연결하고 접근성 검토자와 감소 모션을 확인한다. 충돌 순서 Golden과 콘솔 오류 없는 Web 증거가 있으면 완료다.

## 참고자료

- Flame Effects: https://docs.flame-engine.org/latest/flame/effects/effects.html
- Flame Post-processing: https://docs.flame-engine.org/latest/flame/rendering/post_processing.html
- WCAG Animation from interactions: https://www.w3.org/TR/WCAG22/#animation-from-interactions
- Material interaction states: https://m3.material.io/foundations/interaction/states/overview
