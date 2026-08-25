import 'package:flutter_test/flutter_test.dart';
import 'package:property_shot/ui/admin_access_verifier.dart';

void main() {
  test('관리자 표시는 ID와 비밀번호가 모두 일치할 때만 열린다', () {
    const sampleId = 'sample-admin';
    const samplePassword = 'sample-password';
    final verifier = AdminAccessVerifier(
      expectedIdHash: AdminAccessVerifier.digestForTesting(sampleId),
      expectedPasswordHash: AdminAccessVerifier.digestForTesting(
        samplePassword,
      ),
    );

    expect(verifier.verify(id: sampleId, password: samplePassword), isTrue);
    expect(verifier.verify(id: 'wrong', password: samplePassword), isFalse);
    expect(verifier.verify(id: sampleId, password: 'wrong'), isFalse);
    expect(verifier.verify(id: '', password: samplePassword), isFalse);
  });
}
