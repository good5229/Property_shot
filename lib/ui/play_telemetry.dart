import 'dart:convert';

/// 실제 사용자 식별 정보 없이 내부 플레이 흐름만 기록하는 로컬 계측기다.
/// 서버 전송은 하지 않으며, 테스트 빌드에서 JSON/CSV 문자열로 내보낼 수 있다.
class LocalPlayTelemetry {
  final List<Map<String, Object?>> _events = [];

  List<Map<String, Object?>> get events => List.unmodifiable(_events);

  void record(
    String type, {
    required int stage,
    int? attempt,
    String? action,
    String? trait,
    double? angle,
    double? power,
    String? target,
    String? result,
  }) {
    final event = <String, Object?>{
      '시간': DateTime.now().toUtc().toIso8601String(),
      '유형': type,
      '단계': stage + 1,
    };
    if (attempt != null) event['시도'] = attempt;
    if (action != null) event['행동'] = action;
    if (trait != null) event['속성'] = trait;
    if (angle != null) event['각도'] = angle;
    if (power != null) event['힘'] = power;
    if (target != null) event['대상'] = target;
    if (result != null) event['결과'] = result;
    _events.add(event);
  }

  String exportJson() => const JsonEncoder.withIndent('  ').convert(_events);

  String exportCsv() {
    const columns = ['시간', '유형', '단계', '시도', '행동', '속성', '각도', '힘', '대상', '결과'];
    final rows = <String>[columns.join(',')];
    for (final event in _events) {
      rows.add(columns.map((column) => _csvValue(event[column])).join(','));
    }
    return rows.join('\n');
  }

  static String _csvValue(Object? value) {
    final text = value?.toString() ?? '';
    if (!text.contains(',') && !text.contains('"') && !text.contains('\n')) {
      return text;
    }
    return '"${text.replaceAll('"', '""')}"';
  }
}
