# 게임용 물리 규칙

- 기본 공은 질량 1.0, 무거운 공은 질량 4.4다.
- 발사 속도는 힘에 따라 증가하고 매 단계 마찰로 감소한다.
- 원형 객체는 반지름 합, 사각 객체는 축소 히트박스로 충돌한다.
- 반사는 `v - 2(v·n)n`의 방향을 사용한다.
- 모든 공은 벽에 반사되며, 장애물의 반발력과 공의 탄성 속성에 따라 충돌 후 운동 에너지가 달라진다.
- 움직이는 객체는 충돌 후 짧은 단계로 이동하며 매 단계 첫 충돌을 다시 계산한다.
- 벽·닫힌 문은 고정, 점착판은 정지, 젤리는 반사, 스위치는 눌림과 문 열림을 발생시킨다.
- 렌더링은 확정된 `GameState`, 발사 경로, 이동 웨이포인트를 재생할 뿐 판정을 변경하지 않는다.

## 회전 반사판 PS-OBJ-02

- `rotating_reflector`는 `active=true`, `movable=false`, `solid=true`인 고정 OBB 기물이다. 위치와 크기는 resolve 전후 절대 바뀌지 않는다.
- `reflectorOrientation`은 화면 좌표계(y가 아래로 증가)의 8방향 octant 정수다. `0=위`, `1=오른쪽 위`, `2=오른쪽`, `3=오른쪽 아래`, `4=아래`, `5=왼쪽 아래`, `6=왼쪽`, `7=왼쪽 위`이며 45도 간격이다. 시계 방향 90도 회전은 `(before + 2) % 8`, `reflectorRotationCount`는 0 이상이다.
- 반사판의 긴 축은 `size.x`, 짧은 두께 축은 `size.y`다. 원형 공은 OBB의 nearest point와 corner normal을 사용한다. 직사각형 crate·weight 등은 반사판 법선, 반사판 접선, 화면 x축, 화면 y축 순서의 OBB 대 AABB SAT를 사용한다.
- 직사각형 이동체의 SAT overlap depth가 가장 작은 축이 실제 충돌·분리 법선이다. depth 동률은 위의 고정 축 순서에서 먼저 나온 축을 선택한다. AABB support radius와 같은 SAT normal로 분리해 잔여 overlap·반대편 통과·순간이동을 막는다.
- 기하 법선은 반사판 중심에서 이동체 중심을 향한다. 이벤트에는 `velocityBefore`와 마주보도록 필요한 경우 부호를 뒤집어 `normal.dot(velocityBefore) <= 0`을 유지한다. active 공의 `ShotImpact.normal`과 `ReflectorRotation.collisionNormal`은 동일해야 한다.
- 같은 접촉에서 먼저 pre-orientation OBB 법선으로 속도를 반사하고, impact가 확정된 다음 정확히 90도 회전한다. 현재 충돌은 이전 방향을 사용하며 다음 충돌·다음 샷부터 새 방향을 사용한다. 같은 contact 원장 안에서는 중복 회전하지 않고 완전 이탈 후 재충돌은 다시 회전할 수 있다.
- `ReflectorRotation`은 source/reflector/contact ID, path index, 이전·이후 방향·회전 횟수, collision normal, velocityBefore/After를 보존한다. `PhysicsEvent.resultingVelocity`는 velocityAfter이며 rotation event의 parent는 같은 target impact다. 이벤트 우선순위는 홀, 점착 정지, 실제 고체 impact, reflector rotation 순서를 보존한다.
- 반사 직후에는 새 OBB로 벽·홀·점착·얇은 기물·보드 경계를 swept 재검사한다. 렌더 프레임과 VFX는 확정 사건을 재생할 뿐 판정을 선행하거나 바꾸지 않는다.
- 반사판의 sweep은 전역 샘플 간격에 의존하지 않는다. 원형 공은 OBB의 두 face strip interval과 네 corner quadratic root를, 직사각형 이동체는 반사판 normal·tangent·화면 x·y의 연속 swept SAT interval을 사용한다. 일반 고체 충돌의 기존 1.25 논리 단위 sampling은 유지하며, 반사판 후보는 전체 segment progress에서 일반 후보와 비교한 뒤 가장 이른 충돌만 선택한다.
- `_segmentHasFullReflectorExit`의 0.5 논리 단위 sampling은 충돌 판정이 아니라 접촉 원장의 완전 이탈 확인에만 사용한다. 앞선 벽·홀·슬라이더·연쇄 이동체가 뒤쪽 반사판 후보보다 먼저 선택되는 progress 순서를 훼손하지 않는다.
- analytic sweep의 시작점이 이미 OBB와 겹치면 outward MTV 법선을 반환한다. 이동 속도가 그 법선의 바깥쪽이면 반사·회전 없이 같은 MTV로 분리하고 contact를 소비하며, 안쪽으로 향할 때만 같은 법선으로 bounce와 separation을 함께 수행한다.
- `ShotImpact.contactId`와 `triggersReflectorRotation`은 qualifying 여부를 안정적으로 보존한다. sticky 충돌과 ledger 중복 impact는 비자격이고, 새 nonsticky 반사판 접촉만 자격이다. runtime probe는 자격 impact에만 정확히 하나의 matching rotation을 요구한다.
- 미래 방향의 정적 검증은 회전판이 도달 가능한 네 OBB 방향 모두에 대해 보드 경계와 `movable=false` 고정 고체 겹침만 검사한다. movable 기물과의 미래 겹침은 런타임 분리 물리로 처리하며, 같은 고정 pair의 방향별 중복 오류는 한 건으로 합친다.
- 일반 회전 애니메이션은 사건별 effectiveStart를 순차 적용하지만 reducedMotion은 각 사건의 원래 pathIndex를 due로 사용해 같은 path의 복수 회전을 즉시 최종 방향까지 누적한다.
- 이번 작업은 `GameStateSnapshot`과 `RunState.activeGameState`를 추가하지 않는다. 기존 `stage/pattern/seed/resolverVersion/ordered shotInputLog`를 왕복 저장하고, 로그를 기준 패턴 상태에 순서대로 resolve해 방향·회전 횟수·fingerprint를 재구성한다. 공식 replay service 연결 계약은 PS-REPLAY-01에서 다룬다.

## 파워 슬라이더 PS-OBJ-01

- `power_slider`는 `active=true`, `movable=false`, `solid=false`인 비고체 영역이다. 자체적으로 벽·홀·문·물리 충돌을 만들지 않는다.
- JSON의 `direction`은 슬라이더의 배치·시각 방향 전용이다. 유한하고 0이 아닌 벡터로 검증하고, 렌더러에서만 정규화한다. 공 또는 연쇄 물체의 물리 이동 방향에는 절대 사용하지 않는다.
- `referenceSpeed`는 양의 유한 기준 속력이고, 작동 후 적용 속력은 단순 가산이 아니라 `max(현재 속력, 기준 속력)`이다. 현재 이동 방향은 그대로 보존하며, 여러 슬라이더가 같은 접촉 시점에 작동해도 기준 속력의 최댓값만 한 번 적용한다.
- `allowedTargets`는 `Set<EntityType>`를 표현하는 불변·안정 순서 JSON 배열이다. 비어 있지 않아야 하며, 런타임에서는 `mover.movable=true`이고 대상 타입이 집합에 있을 때만 적용한다. 벽·홀·문·다른 파워 슬라이더 등 비적용 타입은 안정 오류 코드로 거부한다.
- 한 `resolve` 전체에서 활성 공과 재귀 연쇄는 하나의 접촉 원장을 공유한다. 동일한 `sourceEntityId:sliderEntityId` 접촉은 영역 안에 머무는 동안 한 번만 작동한다. 경계 epsilon은 `0.0001`로 고정하며, 완전 이탈을 확인한 뒤 재진입하면 다시 작동할 수 있다.
- 동일 시점 우선순위는 `홀 > 점착 정지 > 실제 고체 충돌 > 파워 슬라이더`다. 슬라이더의 swept 진입이 다른 사건보다 epsilon보다 엄밀히 빠른 경우에만 진입점으로 이동해 속력을 적용하고 남은 선분을 다시 검사한다. 고체 충돌과 같거나 늦으면 슬라이더를 적용하지 않는다.
- 슬라이더 진입은 1.25 논리 단위 이하 샘플과 이분 탐색으로 계산하는 swept collision을 사용한다. 진입점으로 순간이동하거나, 검은 예정 궤적을 판정 결과처럼 표시하지 않는다. 적용 뒤에도 벽·홀·얇은 물체를 같은 연속 선분 규칙으로 재검사한다.
- `PowerSliderActivation`과 `PhysicsEventKind.powerSliderActivation`은 `ShotImpact`와 분리한다. 이벤트는 기존 ID와 비슬라이더 결과를 유지하면서 `contactId`, 적용 전·후 속력, 기준 속력, 진입 위치와 시각 방향을 직접 보존한다.
- activation은 시각 `direction`과 별도로 실제 `motionDirection`, `velocityBefore`, `velocityAfter`를 보존하고 `PhysicsEvent.resultingVelocity`는 `velocityAfter`와 같아야 한다. runtime fingerprint는 두 방향과 세 속력 필드를 안정 순서로 직렬화한다.
- 슬라이더 후보 탐색은 접촉 원장을 변경하지 않는다. 실제로 소비한 `from→chosen endpoint`에서만 완전 이탈을 기록하고, 가장 빠른 후보 그룹을 선택한 순간에만 진입을 기록한다.
- 기준 속력은 `0 < referenceSpeed <= 48`로 제한한다. 일반 최대 발사 속력 약 24의 2배이며, 연쇄 이동이 약 4 단위씩 전개되고 `entities.length * 2 + 16` 반복 상한을 사용하므로 감쇠 반복을 과도하게 늘리지 않도록 보수적으로 고정한다. 이 상한은 swept collision을 대신하는 근거가 아니다.
