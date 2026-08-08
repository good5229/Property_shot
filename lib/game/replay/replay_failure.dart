/// Replay 문서와 공유 코드에서 외부에 노출할 안정적인 실패 분류다.
enum ReplayFailureCode {
  invalidDocument('invalid_document', '리플레이 문서가 올바르지 않습니다.'),
  unsupportedDocumentVersion(
    'unsupported_document_version',
    '지원하지 않는 리플레이 문서 버전입니다.',
  ),
  invalidMode('invalid_mode', '리플레이 모드가 올바르지 않습니다.'),
  invalidDateChallenge('invalid_date_challenge', '일일 도전 날짜와 도전 정보가 올바르지 않습니다.'),
  invalidSeed('invalid_seed', '리플레이 seed가 올바르지 않습니다.'),
  invalidReference('invalid_reference', '리플레이 참조 정보가 올바르지 않습니다.'),
  integerOutOfRange('integer_out_of_range', '리플레이 숫자가 허용 범위를 벗어났습니다.'),
  unsupportedInputEncodingVersion(
    'unsupported_input_encoding_version',
    '지원하지 않는 입력 인코딩 버전입니다.',
  ),
  invalidInitialState('invalid_initial_state', '리플레이 시작 상태가 올바르지 않습니다.'),
  invalidBallHistory('invalid_ball_history', '과거 공 이력이 올바르지 않습니다.'),
  invalidRewardState('invalid_reward_state', '리플레이 보상 상태가 올바르지 않습니다.'),
  invalidShotSequence('invalid_shot_sequence', '리플레이 발사 순서가 올바르지 않습니다.'),
  tooManyShots('too_many_shots', '리플레이 발사 수가 제한을 초과했습니다.'),
  tooManyTraitActions('too_many_trait_actions', '리플레이 속성 행동 수가 제한을 초과했습니다.'),
  invalidFixedPoint('invalid_fixed_point', '리플레이 방향과 힘이 올바르지 않습니다.'),
  invalidFingerprint('invalid_fingerprint', '리플레이 결과 지문이 올바르지 않습니다.'),
  unsupportedOutcomeFingerprintVersion(
    'unsupported_outcome_fingerprint_version',
    '지원하지 않는 결과 지문 버전입니다.',
  ),
  invalidSharePrefix('invalid_share_prefix', '공유 코드 접두사가 올바르지 않습니다.'),
  unsupportedShareVersion('unsupported_share_version', '지원하지 않는 공유 코드 버전입니다.'),
  invalidShareAlphabet('invalid_share_alphabet', '공유 코드에 허용되지 않은 문자가 있습니다.'),
  invalidSharePayload('invalid_share_payload', '공유 코드 내용이 올바르지 않습니다.'),
  integrityMismatch('integrity_mismatch', '공유 코드가 변조되었거나 손상되었습니다.'),
  payloadTooLarge('payload_too_large', '리플레이 데이터가 허용 크기를 초과했습니다.'),
  rawInputTooLarge('raw_input_too_large', '공유 코드 입력이 허용 크기를 초과했습니다.'),
  displayTooLarge('display_too_large', '공유 코드 표시 길이가 허용 범위를 초과했습니다.');

  const ReplayFailureCode(this.stableName, this.uiMessage);

  final String stableName;
  final String uiMessage;
}

/// 파서와 디코더가 같은 실패 코드를 유지하도록 사용하는 예외다.
class ReplayFailure implements Exception {
  const ReplayFailure(this.code, [this.detail]);

  final ReplayFailureCode code;
  final String? detail;

  String get uiMessage => code.uiMessage;

  @override
  String toString() => detail == null
      ? 'ReplayFailure(${code.stableName})'
      : 'ReplayFailure(${code.stableName}): $detail';
}

/// UI 계층이 예외 타입을 알 필요 없이 한글 문구를 얻는 함수다.
String replayFailureMessage(ReplayFailureCode code) => code.uiMessage;

class ReplayParseResult<T> {
  const ReplayParseResult.success(this.value) : failure = null;
  const ReplayParseResult.failure(this.failure) : value = null;

  final T? value;
  final ReplayFailure? failure;

  bool get isSuccess => value != null;
}
