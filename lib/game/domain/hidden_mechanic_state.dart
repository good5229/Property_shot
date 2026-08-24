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
