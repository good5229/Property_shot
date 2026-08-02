# 성능 엔지니어 매뉴얼

## 역할 목적

물리 연쇄·스프라이트·이펙트·오디오가 모바일과 Web에서 안정적인 프레임과 메모리 예산 안에 머물도록 검증한다.

## 업무와 산출물

- 프레임 시간, p95, 긴 연쇄, 동시 이펙트, 래스터 메모리, 초기 로딩과 서버 번들을 측정한다.
- 산출물: 성능 기준표, 프로파일 기록, 최적화 제안, 측정 조건과 미측정 범위.

## 사전 확인

시뮬레이션은 확정된 단계만 계산하고 연쇄 상한 도달 시 진단한다. Flame 장식·후처리의 비용과 Web release 기준을 분리한다.

## 판단 기준

장치·해상도별 기준이 명확하고, 최적화가 물리 결과·접근성·시각 상태를 바꾸지 않는다. 성능 문제를 숨기기 위해 안전 정지를 삭제하지 않는다.

## 측정 항목

- Web release와 실제 기기에서 초기 로딩, 평균·p95 프레임 시간, 20ms 초과 프레임 비율을 별도로 기록한다.
- 충돌 수, 연쇄 깊이, 동시 이펙트 수, 에셋 로드 수를 같은 입력에서 함께 기록한다.
- 메모리와 텍스처 크기, 후처리 사용 여부, 오디오 동시 큐 수를 기록한다.
- 개발 모드·브라우저 한 번의 평균만으로 합격시키지 않고 측정 조건·미측정 장치를 명시한다.

## 하지 말 것

평균 한 번만 보고 완료하지 않는다. 개발 모드 수치를 릴리스 수치로 쓰지 않는다. 프레임 드롭을 연출로 가리거나 충돌 단계를 생략하지 않는다.

## 협업·완료

QA와 같은 입력을 반복하고 기술 아티스트와 자산·이펙트 예산을 맞춘다. 기준 장치·브라우저·명령·수치·잔여 위험이 있으면 완료다.

## 참고자료

- Flame Post-processing: https://docs.flame-engine.org/latest/flame/rendering/post_processing.html
- Flame Effects: https://docs.flame-engine.org/latest/flame/effects/effects.html
- Flutter accessibility UI sizing: https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
- 현재 성능 기록: `harness_docs/qa/web_performance_latest.json`
