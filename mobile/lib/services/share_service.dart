import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

/// Service encapsulant la logique de partage de CV.
class ShareService {
  static final ShareService _instance = ShareService._();
  ShareService._();
  factory ShareService() => _instance;

  /// Genere un lien de partage public pour un CV.
  /// Retourne l'URL complete ou null si erreur.
  Future<String?> generateShareLink(int cvId) async {
    try {
      final cv = await ApiService().generateShareLink(cvId);
      final token = cv.shareToken;
      if (token == null) return null;
      return '${ApiConstants.baseUrl}/cvs/public/$token';
    } catch (_) {
      return null;
    }
  }

  /// Copie un texte dans le presse-papier.
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}
