import 'package:cv_mobile/services/share_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildRecruiterMessage produit un message WhatsApp professionnel', () {
    final message = ShareService().buildRecruiterMessage(
      'https://api.example.com/cvs/public/abc',
      title: 'Chef de Projet Digital',
    );

    expect(message, contains('Bonjour'));
    expect(message, contains('Chef de Projet Digital'));
    expect(message, contains('https://api.example.com/cvs/public/abc'));
  });

  test('buildWhatsAppUri encode le message pour wa.me', () {
    final uri = ShareService().buildWhatsAppUri('Bonjour CV');

    expect(uri.host, 'wa.me');
    expect(uri.queryParameters['text'], 'Bonjour CV');
  });
}
