import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/game/replay/replay.dart';

void main() {
  test('공유 코드는 prefix/version과 64개 한글 alphabet을 사용한다', () {
    expect(replayKoreanAlphabet.runes.length, 64);
    expect(replayKoreanAlphabet.runes.toSet(), hasLength(64));

    final code = ReplayShareCode.encode(_document());
    expect(code, startsWith('속한1:'));
    expect(code.length, lessThanOrEqualTo(replayShareMaxDisplayCharacters));
    expect(
      code
          .substring(replaySharePrefix.length)
          .runes
          .every(
            (rune) => replayKoreanAlphabet.contains(String.fromCharCode(rune)),
          ),
      isTrue,
    );
    expect(
      ReplayShareCode.decode(code).toCanonicalJson(),
      _document().toCanonicalJson(),
    );
  });

  test('공백과 하이픈만 제거해도 같은 공유 코드로 복원된다', () {
    final code = ReplayShareCode.encode(_document());
    final decorated = '${code.substring(0, 7)} - ${code.substring(7)}';
    expect(
      ReplayShareCode.decode(decorated).toCanonicalJson(),
      _document().toCanonicalJson(),
    );
    expect(
      ReplayShareCode.decode('$code${' ' * 3000}').toCanonicalJson(),
      _document().toCanonicalJson(),
    );
    expect(
      () => ReplayShareCode.decode('${code}x'),
      throwsA(_failure(ReplayFailureCode.invalidShareAlphabet)),
    );
  });

  test('SHA-256은 표준 known vector를 사용한다', () {
    expect(
      replaySha256Hex('abc'),
      'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
    );
  });

  test('한 글자 변조는 integrityMismatch로 거부한다', () {
    final code = ReplayShareCode.encode(_document());
    final index = replaySharePrefix.length + 10;
    final original = code[index];
    final replacement = original == replayKoreanAlphabet[0]
        ? replayKoreanAlphabet[1]
        : replayKoreanAlphabet[0];
    final tampered =
        '${code.substring(0, index)}$replacement${code.substring(index + 1)}';
    expect(
      () => ReplayShareCode.decode(tampered),
      throwsA(_failure(ReplayFailureCode.integrityMismatch)),
    );
  });

  test('구버전, 잘못된 prefix, 표시 초과를 구분한다', () {
    final code = ReplayShareCode.encode(_document());
    expect(
      () => ReplayShareCode.decode(code.replaceFirst('속한1:', '속한0:')),
      throwsA(_failure(ReplayFailureCode.unsupportedShareVersion)),
    );
    expect(
      () => ReplayShareCode.decode(code.replaceFirst('속한1:', '나쁜1:')),
      throwsA(_failure(ReplayFailureCode.invalidSharePrefix)),
    );
    expect(
      () => ReplayShareCode.decode(
        code.padRight(replayShareMaxDisplayCharacters + 1, '가'),
      ),
      throwsA(_failure(ReplayFailureCode.displayTooLarge)),
    );
  });

  test('tryDecode는 UI에서 사용할 안정 실패 코드를 반환한다', () {
    final result = ReplayShareCode.tryDecode('속한1:잘못된코드');
    expect(result.isSuccess, isFalse);
    expect(result.failure?.code, ReplayFailureCode.invalidShareAlphabet);
    expect(result.failure?.uiMessage, contains('공유 코드'));
    expect(
      replayFailureMessage(ReplayFailureCode.integrityMismatch),
      contains('변조'),
    );
  });
}

ReplayDocument _document() {
  return ReplayDocument(
    mode: ReplayMode.normal,
    dateKey: null,
    challengeVersion: null,
    rootSeed: 1,
    resolverVersion: 'shot-resolver-v1',
    catalogFingerprint: 'catalog-v1-fingerprint',
    stageId: 'stage_heavy',
    patternId: 'stage_heavy_01',
    patternSeed: 2,
    drawCycle: 0,
    drawIndex: 0,
    shots: [
      ReplayShot(
        shotIndex: 0,
        ballId: 'ball_0',
        direction: ReplayDirection.fromDoubles(0.6, -0.8),
        power: 600000,
        traitActions: const [
          ReplayTraitAction(
            sourceId: 'stone',
            action: ReplayTraitActionKind.transfer,
          ),
        ],
      ),
    ],
    outcomeFingerprints: const [
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    ],
  );
}

Matcher _failure(ReplayFailureCode code) {
  return predicate<ReplayFailure>(
    (failure) => failure.code == code,
    'ReplayFailure(${code.stableName})',
  );
}
