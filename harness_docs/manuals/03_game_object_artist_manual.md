# 게임 오브젝트 아티스트 매뉴얼

## 역할 목적

게임 화면에서 실제로 움직이고 상태가 변하는 공·상자·돌·젤리·풍선·가시·문·홀을 판독 가능한 이미지와 상태 세트로 제작한다.

## 업무와 산출물

- 기본·선택·장착·충돌·정지·파괴·포획 상태를 정의한다.
- 피벗, 투명 여백, 충돌 외곽과 표시 외곽의 정렬 정보를 남긴다.
- 산출물: 스프라이트/프레임, 상태표, 피벗·히트박스 표, `harness_docs/assets/asset_registry.md`, 변경 전후 캡처.

## 사전 확인

실제 판정 도형은 순수 Dart에 있고 아트는 이를 속이지 않아야 함을 확인한다. 풍선은 일반 공에 고정·고탄성으로 반사되고 뾰족한 공에만 팝되며, 팝 뒤 충돌 후보에서 제외된다.

## 판단 기준

탑뷰에서 공은 구, 박스는 직육면체의 상면·측면 착시, 돌은 덩어리 실루엣, 젤리는 변형 가능한 몸체로 읽힌다. 충돌 전·직후·후속 상태가 한 프레임씩 구분된다.

## 하지 말 것

히트박스에 맞춰 이미지를 찌그러뜨리거나, 풍선 팝을 발사 직후 재생하거나, 형태가 다른 상태를 같은 프레임으로 재사용하지 않는다.

## 협업·완료

아트 디렉터의 스타일과 기술 아티스트의 앵커 규칙을 통과시키고, QA의 상태별 시각 회귀가 통과하면 완료다.

## 참고자료

- Flame Sprite components: https://docs.flame-engine.org/latest/flame/components/components.html
- Flame effects: https://docs.flame-engine.org/latest/flame/effects/effects.html
- OpenGameArt FAQ: https://opengameart.org/content/faq
- 에셋 권리 기록: `harness_docs/release/asset_rights_ledger.md`
