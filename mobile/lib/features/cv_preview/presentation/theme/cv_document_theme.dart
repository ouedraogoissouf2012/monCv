import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../utils/app_colors.dart';

/// Catalogue centralise des jetons visuels du DOCUMENT CV en preview
/// (issue #243), distinct du theme de l'application.
///
/// Regroupe les couleurs, tailles de police, hauteurs de ligne et graisses
/// aujourd'hui dispersees et repetees dans chaque template du monolithe
/// `cv_preview.dart`. Les templates doivent puiser ici, sans reintroduire de
/// `GoogleFonts`, `Colors.*` ou litteral de taille (critere #243).
///
/// Ces valeurs reproduisent a l'identique celles du monolithe (iso-rendu).
abstract final class CvDocumentTheme {
  // ── Couleurs (deja issues du catalogue app AppColors) ──────────
  /// Couleur du texte principal (noms, intitules forts).
  static const Color textStrong = AppColors.neutral900;

  /// Couleur du corps de texte (descriptions, contenu).
  static const Color textBody = AppColors.neutral700;

  /// Couleur du texte attenue (dates, meta).
  static const Color textMuted = AppColors.neutral450;

  /// Couleur du texte tres discret (contact/titre des templates epures).
  static const Color textFaint = AppColors.neutral300;

  /// Couleur des filets de separation fins.
  static const Color divider = AppColors.neutral100;

  // ── Tailles de police (echelle du document) ────────────────────
  static const double sizeName = 12;
  static const double sizeTitle = 11;
  static const double sizeSectionTitle = 10;
  static const double sizeBody = 10;
  static const double sizeMeta = 9;
  static const double sizeChipLabel = 7.5;

  // ── Rythme vertical ────────────────────────────────────────────
  /// Interligne du corps de texte.
  static const double bodyLineHeight = 1.4;

  /// Interligne du resume (plus aere).
  static const double summaryLineHeight = 1.5;

  // ── Graisses ───────────────────────────────────────────────────
  static const FontWeight weightSectionTitle = FontWeight.w700;
  static const FontWeight weightEntryTitle = FontWeight.w600;

  /// Applique une police Google Fonts a [base] de facon SURE : en cas d'echec
  /// (police indisponible, hors ligne), retombe sur [base] sans lever. Reprend
  /// l'ancien helper `_font` du monolithe.
  static TextStyle font(String fontFamily, TextStyle base) {
    try {
      return GoogleFonts.getFont(fontFamily, textStyle: base);
    } catch (_) {
      return base;
    }
  }
}
