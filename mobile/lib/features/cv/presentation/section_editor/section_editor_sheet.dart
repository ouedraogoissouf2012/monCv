import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Ouvre un bottom sheet d'edition de section CV type et retourne le resultat
/// (issue #239).
///
/// Remplace l'ancien `showFormSheet` (void + callback onSave) par une API
/// typee et sure :
/// - retourne `Future<T?>` : `T` valide si l'utilisateur sauvegarde, `null`
///   s'il annule / ferme / swipe (l'agregat parent n'est JAMAIS modifie par
///   ce sheet ; l'appelant applique le `T` retourne).
/// - la sauvegarde n'est possible qu'apres `FormState.validate()`.
///
/// [content] recoit le [StateSetter] du sheet pour rafraichir son etat local
/// (dates, switch...). [buildResult] construit le `T` a partir de l'etat saisi
/// et n'est appele que si le formulaire est valide.
Future<T?> showSectionEditor<T>({
  required BuildContext context,
  required String title,
  required IconData icon,
  required Widget Function(BuildContext, StateSetter) content,
  required T Function() buildResult,
}) {
  final l = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final colorScheme = theme.colorScheme;

      return StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Handle(colorScheme: colorScheme),
                  _Header(
                    title: title,
                    icon: icon,
                    onClose: () => Navigator.of(ctx).pop(),
                  ),
                  const SizedBox(height: 4),
                  Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.15)),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: content(ctx, setState),
                    ),
                  ),
                  _Actions(
                    cancelLabel: l.cancel,
                    saveLabel: l.save,
                    onCancel: () => Navigator.of(ctx).pop(),
                    onSave: () {
                      if (formKey.currentState?.validate() ?? true) {
                        Navigator.of(ctx).pop(buildResult());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Handle extends StatelessWidget {
  final ColorScheme colorScheme;
  const _Handle({required this.colorScheme});

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 4),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onClose;
  const _Header(
      {required this.title, required this.icon, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorScheme.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const _Actions({
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: Text(cancelLabel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(saveLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      );
}
