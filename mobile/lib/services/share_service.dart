import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/i_api_client.dart';
import '../utils/constants.dart';

/// Service encapsulant la logique de partage de CV.
class ShareService {
  ShareService(this._api);

  final IApiClient _api;

  /// Genere un lien de partage public pour un CV.
  /// Retourne l'URL complete ou null si erreur.
  Future<String?> generateShareLink(int cvId) async {
    try {
      final cv = await _api.generateShareLink(cvId);
      final token = cv.shareToken;
      if (token == null) return null;
      return buildPublicPortfolioUrl(token);
    } catch (_) {
      return null;
    }
  }

  String buildPublicPortfolioUrl(String token, {String? baseUrl}) {
    final base = (baseUrl ?? PublicAppConstants.baseUrl)
        .replaceFirst(RegExp(r'/+$'), '');
    return '$base/#/public/cv/$token';
  }

  /// Copie un texte dans le presse-papier.
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  String buildRecruiterMessage(String url, {String? title}) {
    final cvTitle = title == null || title.trim().isEmpty
        ? 'mon CV professionnel'
        : 'mon CV "$title"';
    return 'Bonjour, je vous partage $cvTitle créé avec MonCV. Vous pouvez le consulter ici : $url';
  }

  Uri buildWhatsAppUri(String message) {
    return Uri.https('wa.me', '/', {'text': message});
  }

  Future<bool> shareToWhatsApp(String url, {String? title}) async {
    final message = buildRecruiterMessage(url, title: title);
    final uri = buildWhatsAppUri(message);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Uri buildLinkedInUri(String url) => Uri.https(
        'www.linkedin.com',
        '/sharing/share-offsite/',
        {'url': url},
      );

  Future<bool> shareToLinkedIn(String url) async {
    final uri = buildLinkedInUri(url);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
