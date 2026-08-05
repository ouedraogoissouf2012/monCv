import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/cv_style.dart';

/// Panneau d'options de style : templates, couleurs, polices (issue #247, B4a).
///
/// Extrait de `_buildOptionsPane` du monolithe. Sans etat propre : chaque tap
/// remonte le nouveau [CvStyle] via [onSelect] (le controller B2 gere le
/// debounce/save).
class CvStyleOptionsPane extends StatelessWidget {
  const CvStyleOptionsPane({
    super.key,
    required this.style,
    required this.onSelect,
  });

  final CvStyle style;
  final ValueChanged<CvStyle> onSelect;

  static const _templateAspectRatio = 2.2;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _label(l.template, colorScheme),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: _templateAspectRatio,
          children: CvStyle.templates.map((t) {
            final selected = style.templateId == t.id;
            return GestureDetector(
              onTap: () => onSelect(style.copyWith(templateId: t.id)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected
                        ? style.primaryColor
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: selected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  color: selected
                      ? style.primaryColor.withValues(alpha: 0.06)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.description_outlined,
                        color: t.previewColor, size: 16),
                    const SizedBox(width: 6),
                    Text(t.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.normal)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _label(l.color, colorScheme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CvStyle.paletteColors.map((c) {
            final selected = style.primaryColor.toARGB32() == c.toARGB32();
            return GestureDetector(
              onTap: () => onSelect(style.copyWith(primaryColor: c)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(color: colorScheme.onSurface, width: 2.5)
                      : null,
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _label(l.font, colorScheme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: CvStyle.fontFamilies.map((f) {
            final selected = style.fontFamily == f;
            return GestureDetector(
              onTap: () => onSelect(style.copyWith(fontFamily: f)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: selected
                        ? style.primaryColor
                        : colorScheme.outline.withValues(alpha: 0.3),
                    width: selected ? 2 : 1,
                  ),
                  color: selected
                      ? style.primaryColor.withValues(alpha: 0.1)
                      : null,
                ),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 11,
                        color: selected ? style.primaryColor : null,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.normal)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _label(String text, ColorScheme colorScheme) => Text(text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
        letterSpacing: 0.5,
      ));
}
