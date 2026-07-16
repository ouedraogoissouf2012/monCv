import 'dart:async';

import 'package:cv_mobile/services/http_timeout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interrompt une requete qui depasse le delai configure', () async {
    final never = Completer<String>().future;

    await expectLater(
      withRequestTimeout(never, timeout: const Duration(milliseconds: 5)),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('retourne une reponse terminee avant le delai', () async {
    final result = await withRequestTimeout(
      Future.value('ok'),
      timeout: const Duration(milliseconds: 5),
    );

    expect(result, 'ok');
  });
}
