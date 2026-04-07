import 'package:flutter/material.dart';

/// Types d'erreur pour adapter le style.
enum ErrorType { auth, network, validation, server, info, success }

/// Messages d'erreur bienveillants mappant les erreurs techniques.
class ErrorHelper {
  /// Transforme une erreur technique en message utilisateur.
  static String friendlyMessage(String raw) {
    final lower = raw.toLowerCase();

    // Auth
    if (lower.contains('identifiants') || lower.contains('incorrect') || lower.contains('credentials')) {
      return 'Identifiants incorrects. Vérifiez votre email et mot de passe.';
    }
    if (lower.contains('email') && lower.contains('existe')) {
      return 'Cette adresse email est déjà utilisée. Essayez de vous connecter.';
    }

    // Reseau
    if (lower.contains('connection refused') || lower.contains('failed to fetch') || lower.contains('socketexception')) {
      return 'Impossible de joindre le serveur. Vérifiez votre connexion internet.';
    }
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Le serveur met trop de temps à répondre. Réessayez dans quelques instants.';
    }

    // Serveur
    if (lower.contains('500') || lower.contains('internal')) {
      return 'Une erreur serveur est survenue. Réessayez dans quelques instants.';
    }
    if (lower.contains('403') || lower.contains('forbidden') || lower.contains('non autorise')) {
      return 'Accès refusé. Reconnectez-vous et réessayez.';
    }
    if (lower.contains('429') || lower.contains('rate limit') || lower.contains('trop de tentatives')) {
      return 'Trop de tentatives. Patientez une minute avant de réessayer.';
    }

    // CV
    if (lower.contains('cv non trouve')) {
      return 'Ce CV n\'existe plus ou a été supprimé.';
    }

    // PDF/DOCX
    if (lower.contains('pdf') || lower.contains('docx')) {
      return 'Le téléchargement a échoué. Réessayez dans quelques instants.';
    }

    // IA
    if (lower.contains('deepseek') || lower.contains('ia') || lower.contains('enhance')) {
      return 'Le service IA est temporairement indisponible. Réessayez plus tard.';
    }

    // Upload
    if (lower.contains('upload') || lower.contains('fichier')) {
      return 'L\'envoi du fichier a échoué. Vérifiez le format et la taille.';
    }

    // Defaut : nettoyer le message technique
    String cleaned = raw.replaceAll('Exception: ', '').replaceAll('Exception:', '').trim();
    if (cleaned.length > 100) cleaned = '${cleaned.substring(0, 100)}...';
    return cleaned;
  }

  /// Determine le type d'erreur pour adapter le style.
  static ErrorType errorType(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('identifiants') || lower.contains('credentials') || lower.contains('incorrect')) return ErrorType.auth;
    if (lower.contains('connection') || lower.contains('socket') || lower.contains('timeout') || lower.contains('fetch')) return ErrorType.network;
    if (lower.contains('requis') || lower.contains('invalide') || lower.contains('validation')) return ErrorType.validation;
    return ErrorType.server;
  }

  /// Affiche un SnackBar d'erreur bienveillant.
  static void showError(BuildContext context, String rawError, {VoidCallback? onRetry}) {
    final message = friendlyMessage(rawError);
    final type = errorType(rawError);
    _showSnackBar(context, message, type, onRetry: onRetry);
  }

  /// Affiche un SnackBar de succes.
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(context, message, ErrorType.success);
  }

  /// Affiche un SnackBar d'info.
  static void showInfo(BuildContext context, String message) {
    _showSnackBar(context, message, ErrorType.info);
  }

  static void _showSnackBar(BuildContext context, String message, ErrorType type, {VoidCallback? onRetry}) {
    final config = _configForType(type);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: type == ErrorType.network ? 6 : 4),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: config.border),
      ),
      backgroundColor: config.bg,
      content: Row(
        children: [
          Icon(config.icon, size: 20, color: config.fg),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: config.fg, fontSize: 13, fontWeight: FontWeight.w500))),
          if (onRetry != null)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                onRetry();
              },
              child: Text('Réessayer', style: TextStyle(color: config.fg, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ],
      ),
    ));
  }

  static _SnackConfig _configForType(ErrorType type) {
    return switch (type) {
      ErrorType.auth => _SnackConfig(
        bg: const Color(0xFFFEF2F2), fg: const Color(0xFFDC2626),
        border: const Color(0xFFFECACA), icon: Icons.lock_outline_rounded),
      ErrorType.network => _SnackConfig(
        bg: const Color(0xFFFFF7ED), fg: const Color(0xFFEA580C),
        border: const Color(0xFFFED7AA), icon: Icons.wifi_off_rounded),
      ErrorType.validation => _SnackConfig(
        bg: const Color(0xFFFEFCE8), fg: const Color(0xFFCA8A04),
        border: const Color(0xFFFEF08A), icon: Icons.info_outline_rounded),
      ErrorType.server => _SnackConfig(
        bg: const Color(0xFFFEF2F2), fg: const Color(0xFFDC2626),
        border: const Color(0xFFFECACA), icon: Icons.error_outline_rounded),
      ErrorType.success => _SnackConfig(
        bg: const Color(0xFFF0FDF4), fg: const Color(0xFF16A34A),
        border: const Color(0xFFBBF7D0), icon: Icons.check_circle_outline_rounded),
      ErrorType.info => _SnackConfig(
        bg: const Color(0xFFEFF6FF), fg: const Color(0xFF2563EB),
        border: const Color(0xFFBFDBFE), icon: Icons.info_outline_rounded),
    };
  }
}

class _SnackConfig {
  final Color bg, fg, border;
  final IconData icon;
  const _SnackConfig({required this.bg, required this.fg, required this.border, required this.icon});
}
