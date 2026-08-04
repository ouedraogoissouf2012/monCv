import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Selecteur de ton (puces horizontales). Les valeurs sont des cles neutres
/// (SIMPLE/PROFESSIONAL/...), les libelles sont resolus ici (issue #245, G5).
class MessageToneSelector extends StatelessWidget {
  const MessageToneSelector({
    super.key,
    required this.tones,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> tones;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  String _labelFor(AppLocalizations l, String tone) => switch (tone) {
        'SIMPLE' => l.toneSimple,
        'PROFESSIONAL' => l.toneProfessional,
        'DIRECT' => l.toneDirect,
        'JUNIOR' => l.toneJunior,
        'SENIOR' => l.toneSenior,
        _ => tone,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: tones
            .map((tone) => ButtonSegment<String>(
                  value: tone,
                  label: Text(_labelFor(l, tone)),
                ))
            .toList(),
        selected: {selected},
        onSelectionChanged:
            enabled ? (selection) => onSelected(selection.first) : null,
      ),
    );
  }
}

/// Poignee de la feuille modale (barre grise superieure).
class MessageSheetHandle extends StatelessWidget {
  const MessageSheetHandle({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 4,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
      );
}

/// En-tete de la feuille (icone + titre + sous-titre + fermeture).
class MessageSheetHeader extends StatelessWidget {
  const MessageSheetHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.send_rounded,
                color: colorScheme.onPrimaryContainer, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.applicationMessagesTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(l.applicationMessagesSubtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

/// Banniere d'information (ex. resultat de repli IA). Extraite du monolithe.
class MessageStatusBanner extends StatelessWidget {
  const MessageStatusBanner({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: TextStyle(color: colors.onTertiaryContainer, fontSize: 12)),
    );
  }
}

/// Panneau depliable d'un message (titre + texte selectionnable + bouton de
/// copie). La copie est deleguee via [onCopy] (separee de la generation).
class MessagePanel extends StatelessWidget {
  const MessagePanel({
    super.key,
    required this.title,
    required this.icon,
    required this.text,
    required this.initiallyExpanded,
    required this.onCopy,
  });

  final String title;
  final IconData icon;
  final String text;
  final bool initiallyExpanded;
  final Future<void> Function() onCopy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, size: 20, color: colors.primary),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        trailing: IconButton(
          tooltip: l.copy,
          onPressed: onCopy,
          icon: const Icon(Icons.copy_rounded, size: 19),
        ),
        children: [
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(text,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}
