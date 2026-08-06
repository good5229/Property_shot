# 결정 기록

- 속성은 현재 공에 복사할 수 있고 원본 물체에서 제거하지 않는다. 게임 정체성에 영향을 주는 변경이므로 유지했다.
- 별도 발사 버튼 대신 공 길게 누르기 후 손 떼기 자동 발사를 채택했다.
- 입체 보기와 회전 뷰를 모두 제거하고 위에서 내려다보는 단일 보기로 통일했다.
- 온라인 리더보드는 범위에서 제외하고 로컬 목업을 유지했다.
- 공-공 연쇄 이동은 최종 위치 점프가 아니라 단계별 충돌과 웨이포인트 재생으로 보완했다.
- 충돌 애니메이션은 재귀 깊이 보정이 아니라 실제 충돌 단계 이후에 시작하도록 통일했다.
- PS-OBJ-02 회전 반사판의 직사각형 이동체 법선은 화면상 회전만 표현하는 axis-aligned 판정이 아니라 반사판 OBB와 mover AABB의 SAT 최소 penetration 축으로 확정한다. 축 순서는 반사판 normal, tangent, 화면 x, 화면 y이며 동률은 앞선 축을 선택한다.
- PS-OBJ-02의 저장 범위는 기존 RunState의 stage/pattern/seed/resolverVersion/ordered shotInputLog로 제한한다. GameStateSnapshot이나 RunState.activeGameState를 추가하지 않고, 로그를 순차 resolve해 회전판 orientation/count와 replay fingerprint를 재구성한다.
- PS-OBJ-02 반사판 sweep은 얇은 OBB와 접선 고속 스침을 보장하기 위해 반사판 전용 analytic 연속 판정으로 확정한다. 원형 공은 face/corner interval, 직사각형 이동체는 4축 swept SAT를 사용하고, 일반 고체의 1.25 샘플링과 분리한다. analytic 후보는 전체 segment progress에서 일반 후보와 안정 비교한다.
- 2026-08-06 PS-OBJ-02 P1 보완: 시작 OBB 겹침은 outward MTV escape와 inward bounce를 분리하고, qualifying reflector impact만 rotation을 요구한다. 미래 방향 validator는 고정 고체만 검사하며 동일 고정 pair 오류를 deduplicate한다. replay/runtime fingerprint에는 source·contact·qualifying을 포함하고, reduced 회전 일정은 원래 pathIndex에서 복수 사건을 즉시 누적한다.
- 2026-08-03 역할별 전문 에이전트가 독립 제안과 구현을 시작하기 전에 공통 운영 표준·역할 매뉴얼·외부 참고자료·활성화 게이트를 확인하도록 정했다. 매뉴얼은 `harness_docs/manuals/`에 추가하고, 원문·기존 기록은 덮어쓰지 않는다.
- 2026-08-03 UX 라이터의 필수 산출물을 `harness_docs/ux/copy_inventory.md`, `terminology_guide.md`, `copy_decision_log.md`로 고정했다. 한글 UI·한 단계 안내·비난하지 않는 실패 문구를 품질 게이트로 삼는다.
