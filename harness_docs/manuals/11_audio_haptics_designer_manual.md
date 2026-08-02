# 오디오·햅틱 디자이너 매뉴얼

## 역할 목적

소리와 진동으로 발사·충돌·재질·성공을 구분하게 하되, 오디오가 없어도 원인과 결과를 이해하게 한다.

## 업무와 산출물

- 발사, 가벼운 충돌, 무거운 충돌, 벽 반사, 젤리, 점착, 풍선 팝, 스위치, 문, 홀, 성공을 구분한다.
- 산출물: 이벤트 큐·우선순위표, 동시 재생 상한, 음소거·감소 모션 연동, 장치별 QA 기록.

## 사전 확인

현재 Web은 외부 음원 없이 합성 톤, 모바일은 플랫폼 기본 피드백을 사용한다. 연쇄 이벤트는 순서를 보존하고 실패 시 예외를 흡수한다.

## 판단 기준

소리만 듣고도 재질 차이를 어느 정도 구분할 수 있지만, 소리 없는 환경에서도 색·무늬·움직임·문구로 같은 정보를 얻는다.

## 하지 말 것

오디오 콜백으로 물리 상태를 바꾸지 않는다. 연쇄음을 무제한 병렬 재생하지 않는다. 미검증 기기 동작을 사실처럼 기록하지 않는다.

## 협업·완료

VFX·물리·접근성 QA와 이벤트 순서, 음소거, 반복 재생, 성능을 검증한다. 실제 기기 검증 여부와 미검증 범위를 기록하면 완료다.

## 참고자료

- Apple Accessibility: https://developer.apple.com/design/human-interface-guidelines/accessibility/
- Game Accessibility Guidelines: https://gameaccessibilityguidelines.com/full-list/
- IGDA Game Accessibility SIG: https://igda-gasig.org/
- Flutter assistive technologies: https://docs.flutter.dev/ui/accessibility/assistive-technologies
