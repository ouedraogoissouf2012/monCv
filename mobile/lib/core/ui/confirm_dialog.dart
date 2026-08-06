import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../design_system/theme/app_theme_extensions.dart';

/// Affiche une boite de dialogue de confirmation reutilisable (issue #250).
///
/// Retourne `true` si l'utilisateur confirme, `false`/`null` sinon. Quand
/// [destructive] est vrai, le bouton de confirmation adopte le token `danger`
/// du design system (au lieu d'une couleur codee en dur). Le libelle d'annulation
/// est localise.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(AppLocalizations.of(ctx)!.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: ctx.colorTokens.danger)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}
