import 'dart:io';

import 'package:property_shot/game/analysis/session_role_review.dart';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      '사용법: dart run tool/review_local_session.dart <session.json>',
    );
    exitCode = 64;
    return;
  }
  try {
    final source = File(arguments.single).readAsStringSync();
    stdout.writeln(
      SessionRoleEvaluation.fromPrivacySafeJson(source).toMarkdown(),
    );
  } on Object catch (error) {
    stderr.writeln('세션 평가 실패: $error');
    exitCode = 65;
  }
}
