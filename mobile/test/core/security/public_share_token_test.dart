import 'package:cv_mobile/core/security/public_share_token.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepte les jetons actuels et les anciens UUID sans tirets', () {
    expect(PublicShareToken.isValid(List.filled(43, 'A').join()), isTrue);
    expect(
      PublicShareToken.isValid('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'),
      isTrue,
    );
  });

  test('rejette traversal, separateurs, espaces et tailles excessives', () {
    for (final value in [
      '../admin',
      'abc/def',
      ' abc',
      'abc ',
      List.filled(10 * 1024, 'a').join(),
      '',
    ]) {
      expect(
        () => PublicShareToken.requireValid(value),
        throwsA(isA<FormatException>()),
      );
    }
  });
}
