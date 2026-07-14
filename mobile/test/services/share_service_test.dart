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

  test('buildPublicPortfolioUrl pointe vers la route Flutter publique', () {
    final url = ShareService().buildPublicPortfolioUrl(
      'abc123',
      baseUrl: 'https://moncv.example/',
    );

    expect(url, 'https://moncv.example/#/public/cv/abc123');
  });

  test('buildLinkedInUri encode le lien du portfolio', () {
    final uri = ShareService()
        .buildLinkedInUri('https://moncv.example/#/public/cv/abc123');

    expect(uri.host, 'www.linkedin.com');
    expect(
        uri.queryParameters['url'], 'https://moncv.example/#/public/cv/abc123');
  });
}
