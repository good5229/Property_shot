import 'dart:math' as math;

import 'geometry.dart';

/// 숨은 기믹의 정체가 플레이어에게 언제 공개되는지를 표현하는 공통 계약이다.
///
/// 물리 상태와 화면 상태를 분리해, 결과 스냅샷에 실제 기믹이 이미 존재하더라도
/// 애니메이션과 접근성 UI가 공개 시점 전에는 정체를 먼저 말하지 않게 한다.
abstract final class HiddenMechanicState {
  static const String concealed = 'hidden';
  static const String opening = 'mystery_opening';
  static const String revealed = 'revealed';

  static bool masksIdentity(String visualState) =>
      visualState == concealed || visualState == opening;
}

/// 숨은 기믹을 대신하는 `?` 상자의 실제 렌더 한 변 길이.
///
/// 배치 감사와 Canvas가 같은 계산을 공유해 데이터 hitbox보다 큰 미리보기의
/// 겹침을 놓치지 않게 한다.
double hiddenMechanicPreviewSide(Vec2 entitySize) =>
    math.max(48.0, math.min(56.0, math.max(entitySize.x, entitySize.y) * 0.86));
