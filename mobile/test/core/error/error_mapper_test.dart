import 'package:cv_mobile/core/error/error_mapper.dart';
import 'package:cv_mobile/core/error/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('503 AI_KEY_INVALID devient une AiException typee', () {
    // Le backend renvoie un libelle neutre (charte, issue #336), jamais le
    // nom technique du fournisseur.
    final error = ErrorMapper.fromHttpResponse(503, {
      'code': 'AI_KEY_INVALID',
      'message': 'provider rejected key',
      'details': {'provider': 'primary'},
    });

    expect(error, isA<AiException>());
    final aiError = error as AiException;
    expect(aiError.code, 'AI_KEY_INVALID');
    expect(aiError.provider, 'primary');
    expect(aiError.retryAfter, isNull);
    expect(aiError.message, contains('mal configure'));
  });

  test('quota convertit retryAfter en Duration', () {
    final error = ErrorMapper.fromHttpResponse(503, {
      'code': 'AI_QUOTA_EXCEEDED',
      'details': {'provider': 'primary', 'retryAfter': 120},
    }) as AiException;

    expect(error.retryAfter, const Duration(seconds: 120));
  });
}
