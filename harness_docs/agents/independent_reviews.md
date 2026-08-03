# 독립 진단 기록

## 참여 관점

Epicurus(레벨·제품), Hooke(QA·접근성·성능), Newton(아트·오브젝트), Lorentz(물리·연출), Descartes(UX 문구)가 역할 매뉴얼과 외부 참고자료를 기준으로 독립 검토했다.

## 핵심 발견과 조치

| 발견 | 심각도 | 조치 | 근거 |
|---|---|---|---|
| 풍선 팝 직후 문 직접 개방 | P0 | 스위치 실제 충돌 후에만 문 개방 | `shot_resolver.dart`, 스테이지4 테스트 |
| 풍선 일반 충돌에서 풍선 이동 | P1 | 풍선을 고정 탄성 표면으로 변경 | `balloon_physics_test.dart` |
| 한글 문구 길이·정보 제목 중복 | P1 | 문구 인벤토리·의미별 팝업·Golden 갱신 | `copy_inventory.md`, 위젯 테스트 |
| 홀 포획 공의 깊이감 부족 | P1 | 포획 공 노출·깃발 레이어 보정 | 홀 Golden 25개 |
| 실제 기기·사용자 증거 부재 | P1 | 미검증 위험으로 남김 | `remaining_risks.md` |

전체 원문은 [manual_cross_review_2026-08-03.md](manual_cross_review_2026-08-03.md)와 역할별 리뷰 문서에 연결한다.
