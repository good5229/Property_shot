# 테크니컬 아티스트 매뉴얼

## 역할 목적

아트가 게임 상태·카메라·렌더 순서·성능과 일관되게 연결되도록 자산 파이프라인과 표시 규칙을 만든다.

## 업무와 산출물

- Canvas·래스터·하이브리드 선택, 스프라이트 아틀라스, 필터링, 해상도 대응, 메모리 예산을 정의한다.
- z-order, 앵커, 피벗, HUD와 월드 좌표, 홀·깃발 Y-sort를 고정한다.
- 산출물: 렌더링 규칙, 자산 import 표, 프레임 예산, Golden 기준, 성능 기록.

## 사전 확인

논리 좌표 `360 x 560`, 단일 탑뷰, 벽의 고정, 홀 포획 우선, 현재 Web release와 390×844·768×1024 기준을 확인한다.

## 판단 기준

스프라이트가 실제 판정 위치와 어긋나지 않고, 고해상도·저해상도에서 형태가 흐려지지 않으며, 이동 물체가 사각형 디버그 박스처럼 보이지 않아야 한다.

## 프로젝트 주의사항

Flame 효과는 연출에만 쓰며 판정 상태를 갱신하지 않는다. 전체 화면 후처리는 비용을 측정한 뒤 제한적으로 사용한다.

## 하지 말 것

렌더링 순서로 충돌 우선순위를 바꾸지 않는다. 아틀라스에 라이선스 정보 없는 원본을 섞지 않는다. 화면 크기에 따라 물리 좌표를 임의로 재계산하지 않는다.

## 협업·완료

물리·오브젝트 아티스트·성능 엔지니어와 앵커·프레임·메모리 표를 합의하고 Golden·Web 성능 검증을 남기면 완료다.

## 참고자료

- Flame Components와 priority: https://docs.flame-engine.org/latest/flame/components/components.html
- Flame Effects: https://docs.flame-engine.org/latest/flame/effects/effects.html
- Flame Post-processing: https://docs.flame-engine.org/latest/flame/rendering/post_processing.html
- Flutter UI 접근성: https://docs.flutter.dev/ui/accessibility/ui-design-and-styling
