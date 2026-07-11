@Tags(['web-smoke'])
import 'dart:convert';

import 'package:cv_mobile/main.dart' as app;
import 'package:cv_mobile/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('smoke web parcours CV complet', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final flutterErrors = <FlutterErrorDetails>[];
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      flutterErrors.add(details);
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    String? accessToken;
    int? cvId;
    int? duplicateId;
    addTearDown(() async {
      final token = accessToken;
      if (token == null) return;
      final copyId = duplicateId;
      if (copyId != null) {
        await _deleteCv(token, copyId);
      }
      final createdId = cvId;
      if (createdId != null) {
        await _deleteCv(token, createdId);
      }
    });

    app.main();
    await _shortPump(tester);

    final suffix = DateTime.now().millisecondsSinceEpoch;
    final email = 'smoke.$suffix@example.com';
    const password = 'Test1234!';
    const cvTitle = 'Architecte QA Web';

    await _tapText(
      tester,
      'Créer mon CV gratuitement',
      timeout: const Duration(seconds: 20),
    );
    await _waitFor(tester, find.text('Créer mon compte'));

    await _enterField(tester, 0, 'Smoke');
    await _enterField(tester, 1, 'Codex');
    await _enterField(tester, 2, email);
    await _enterField(tester, 3, password);
    await _enterField(tester, 4, password);
    await _tapButtonText(tester, 'Créer mon compte');

    await _waitFor(tester, find.text('Mes CVs'),
        timeout: const Duration(seconds: 20));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ??
        fail('Token absent apres inscription');
    accessToken = token;

    await _tapText(tester, 'Nouveau CV');
    await _waitFor(tester, find.text('Nouveau CV'));

    await _enterFieldByLabel(tester, 'Prénom *', 'Smoke');
    await _enterFieldByLabel(tester, 'Nom *', 'Codex');
    await _enterFieldByLabel(tester, 'Titre du poste', cvTitle);
    await _enterFieldByLabel(tester, 'Email *', email);
    await _enterFieldByLabel(tester, 'Téléphone', '+2250700000000');
    await _enterFieldByLabel(tester, 'Pays', "Côte d'Ivoire");
    await _enterFieldByLabel(tester, 'Ville', 'Abidjan');
    await _enterFieldByLabel(
      tester,
      'Resume professionnel',
      'Profil QA cree par le smoke E2E web pour verifier le parcours complet.',
    );
    await _waitFor(tester, find.text('Complétion : 20%'));

    for (var i = 0; i < 4; i++) {
      await _tapButtonText(tester, 'Suivant');
    }
    await _tapButtonText(tester, 'Enregistrer le CV');

    await _waitFor(tester, find.text(cvTitle),
        timeout: const Duration(seconds: 20));
    await _waitFor(tester, find.text('55%'));

    final cvs = await _apiList('/cvs', token);
    final created = cvs
        .cast<Map<String, dynamic>>()
        .firstWhere((cv) => cv['titre'] == cvTitle);
    cvId = (created['id'] as num).toInt();

    await _tapText(tester, 'Voir');
    await _waitFor(tester, find.byTooltip('Personnaliser'));

    await _assertBinaryEndpoint('/cvs/$cvId/pdf', token, minBytes: 1000);
    await _assertBinaryEndpoint('/cvs/$cvId/docx', token, minBytes: 1000);

    final shared = await _apiJson('POST', '/cvs/$cvId/share', token);
    final publicToken =
        shared['publicToken'] as String? ?? fail('Token public absent');
    final publicCv = await _apiJson('GET', '/cvs/public/$publicToken', null);
    expect(publicCv['titre'], cvTitle);

    final duplicated = await _apiJson('POST', '/cvs/$cvId/duplicate', token);
    duplicateId = (duplicated['id'] as num).toInt();
    expect(duplicated['titre'], startsWith('Copie de'));
    final duplicateDelete = await _deleteCv(token, duplicateId);
    expect(duplicateDelete, 204);
    duplicateId = null;

    await _tapFinder(tester, find.byTooltip('Personnaliser'));
    await _waitFor(tester, find.text('Personnaliser le CV'));
    await _tapText(tester, 'Classique');
    await _tapText(tester, 'Lato');
    await _waitForGone(tester, find.text('Sauvegarde...'));

    final styledCv = await _apiJson('GET', '/cvs/$cvId', token);
    expect(styledCv['style']['templateId'], 'classique');
    expect(styledCv['style']['fontFamily'], 'Lato');

    expect(find.byType(ErrorWidget), findsNothing);
    expect(
      flutterErrors.map((details) => details.exceptionAsString()).toList(),
      isEmpty,
      reason:
          'Aucune erreur Flutter bloquante ne doit apparaître pendant le smoke.',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}

const _waitStep = Duration(milliseconds: 100);

Future<void> _enterField(WidgetTester tester, int index, String value) async {
  final field = find.byType(TextFormField).at(index);
  await _waitFor(tester, field);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await _shortPump(tester);
}

Future<void> _enterFieldByLabel(
  WidgetTester tester,
  String label,
  String value,
) async {
  final field = find.widgetWithText(TextFormField, label);
  await _waitFor(tester, field);
  final target = field.first;
  await tester.ensureVisible(target);
  await _shortPump(tester);
  await tester.tap(target, warnIfMissed: false);
  await tester.enterText(target, value);
  await _shortPump(tester);
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  Duration timeout = const Duration(seconds: 10),
}) {
  return _tapFinder(tester, find.text(text), timeout: timeout);
}

Future<void> _tapButtonText(WidgetTester tester, String text) async {
  final buttonFinders = [
    find.widgetWithText(ElevatedButton, text),
    find.widgetWithText(FilledButton, text),
    find.widgetWithText(TextButton, text),
    find.widgetWithText(OutlinedButton, text),
  ];

  for (final finder in buttonFinders) {
    if (finder.evaluate().isNotEmpty) {
      await _tapFinder(tester, finder);
      return;
    }
  }

  throw TestFailure(
    'Bouton introuvable: $text. Textes visibles: ${_visibleTextSummary()}',
  );
}

Future<void> _tapFinder(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await _waitFor(tester, finder, timeout: timeout);
  final target = finder.first;
  await tester.ensureVisible(target);
  await tester.tap(target, warnIfMissed: false);
  await _shortPump(tester);
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final attempts = (timeout.inMilliseconds / _waitStep.inMilliseconds).ceil();
  for (var i = 0; i <= attempts; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await _pumpAndYield(tester, _waitStep);
  }
  throw TestFailure(
    'Element introuvable apres $timeout: $finder. '
    'Textes visibles: ${_visibleTextSummary()}',
  );
}

Future<void> _waitForGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final attempts = (timeout.inMilliseconds / _waitStep.inMilliseconds).ceil();
  for (var i = 0; i <= attempts; i++) {
    if (finder.evaluate().isEmpty) return;
    await _pumpAndYield(tester, _waitStep);
  }
  throw TestFailure(
    'Element toujours visible apres $timeout: $finder. '
    'Textes visibles: ${_visibleTextSummary()}',
  );
}

Future<void> _shortPump(WidgetTester tester) async {
  await tester.pump();
  await _pumpAndYield(tester, const Duration(milliseconds: 250));
}

Future<void> _pumpAndYield(WidgetTester tester, Duration duration) async {
  await tester.pump(duration);
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
  });
}

Future<List<dynamic>> _apiList(String path, String token) async {
  final response = await http.get(_apiUri(path), headers: _headers(token));
  expect(response.statusCode, 200, reason: response.body);
  return jsonDecode(response.body) as List<dynamic>;
}

Future<Map<String, dynamic>> _apiJson(
  String method,
  String path,
  String? token,
) async {
  final headers =
      token == null ? {'Accept': 'application/json'} : _headers(token);
  final response = switch (method) {
    'GET' => await http.get(_apiUri(path), headers: headers),
    'POST' => await http.post(_apiUri(path), headers: headers),
    _ => throw ArgumentError('Methode HTTP non supportee: $method'),
  };
  expect(response.statusCode, anyOf(200, 201), reason: response.body);
  return jsonDecode(response.body) as Map<String, dynamic>;
}

Future<void> _assertBinaryEndpoint(
  String path,
  String token, {
  required int minBytes,
}) async {
  final response = await http.get(_apiUri(path), headers: _headers(token));
  expect(response.statusCode, 200, reason: response.body);
  expect(response.bodyBytes.length, greaterThan(minBytes));
}

Future<int> _deleteCv(String token, int id) async {
  final response =
      await http.delete(_apiUri('/cvs/$id'), headers: _headers(token));
  return response.statusCode;
}

Uri _apiUri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

Map<String, String> _headers(String token) => {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };

String _visibleTextSummary() {
  return find
      .byType(Text)
      .evaluate()
      .map((element) {
        final widget = element.widget as Text;
        return widget.data ?? widget.textSpan?.toPlainText() ?? '';
      })
      .where((text) => text.trim().isNotEmpty)
      .take(30)
      .join(' | ');
}
