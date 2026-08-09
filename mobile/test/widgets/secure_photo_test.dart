import 'dart:convert';
import 'dart:typed_data';

import 'package:cv_mobile/features/media/domain/secure_photo_repository.dart';
import 'package:cv_mobile/widgets/secure_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecurePhotoRepository extends Mock
    implements SecurePhotoRepository {}

/// PNG 1x1 transparent valide (decodable par Image.memory).
final _validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk'
  '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

Widget _wrap(SecurePhotoRepository repo, {String url = '/p.png'}) =>
    MaterialApp(
      home: Scaffold(
        body: SecurePhoto(
          url: url,
          fallback: const Text('FALLBACK'),
          repository: repo,
        ),
      ),
    );

void main() {
  testWidgets('affiche le fallback quand le repo retourne null',
      (tester) async {
    final repo = _MockSecurePhotoRepository();
    when(() => repo.load('/p.png')).thenAnswer((_) async => null);

    await tester.pumpWidget(_wrap(repo));
    await tester.pump(); // resout le future du repo

    expect(find.text('FALLBACK'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('affiche l\'image quand le repo retourne des octets',
      (tester) async {
    final repo = _MockSecurePhotoRepository();
    when(() => repo.load('/p.png'))
        .thenAnswer((_) async => Uint8List.fromList(_validPng));

    await tester.pumpWidget(_wrap(repo));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
    expect(find.text('FALLBACK'), findsNothing);
  });

  testWidgets('recharge via le repo quand l\'URL change', (tester) async {
    final repo = _MockSecurePhotoRepository();
    when(() => repo.load(any())).thenAnswer((_) async => null);

    await tester.pumpWidget(_wrap(repo, url: '/a.png'));
    await tester.pump();
    await tester.pumpWidget(_wrap(repo, url: '/b.png'));
    await tester.pump();

    verify(() => repo.load('/a.png')).called(1);
    verify(() => repo.load('/b.png')).called(1);
  });
}
