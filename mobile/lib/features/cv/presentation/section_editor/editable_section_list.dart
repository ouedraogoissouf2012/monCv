import 'package:flutter/material.dart';

import 'section_primitives.dart' show SectionAddButton, SectionEmptyState;

/// Liste editable et typee d'items de section CV (issue #239).
///
/// Absorbe la triade add / edit(index) / delete(index) dupliquee dans les 6
/// sections (voir `skills_section.dart`, `experience_section.dart`...), qui se
/// resumait partout a :
///
/// ```dart
/// void _add()      => onChanged([...items, built]);
/// void _edit(i)    => onChanged(list..[i] = built);
/// void _delete(i)  => onChanged(list..removeAt(i));
/// ```
///
/// Ce widget ne connait ni le type concret ni la mise en forme d'un item : il
/// recoit un [itemBuilder] (chaque section fournit sa tuile ou son chip) et
/// deux callbacks d'edition. Il n'effectue AUCUNE mutation en place : chaque
/// operation produit une nouvelle liste passee a [onChanged] (immutabilite,
/// coherent avec [showSectionEditor]).
///
/// [onAdd] / [onEdit] recoivent l'item courant (`null` pour un ajout) et
/// doivent retourner le `T` construit, ou `null` si l'utilisateur a annule —
/// typiquement le resultat de `showSectionEditor<T>(...)`.
class EditableSectionList<T> extends StatelessWidget {
  const EditableSectionList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onChanged,
    required this.onAdd,
    required this.onEdit,
    required this.addLabel,
    required this.emptyIcon,
    required this.emptyLabel,
    this.layout = SectionListLayout.column,
    this.wrapSpacing = 8,
    this.wrapRunSpacing = 8,
  });

  /// Items actuels (source de verite detenue par le parent).
  final List<T> items;

  /// Construit la representation visuelle d'un item, avec ses actions cablees.
  final Widget Function(
    BuildContext context,
    T item,
    int index, {
    required VoidCallback onEditItem,
    required VoidCallback onDeleteItem,
  }) itemBuilder;

  /// Notifie le parent de la nouvelle liste apres add / edit / delete.
  final ValueChanged<List<T>> onChanged;

  /// Ouvre l'editeur d'ajout ; retourne le `T` construit ou `null` si annule.
  final Future<T?> Function(BuildContext context) onAdd;

  /// Ouvre l'editeur d'edition ; retourne le `T` construit ou `null` si annule.
  final Future<T?> Function(BuildContext context, T current) onEdit;

  final String addLabel;
  final IconData emptyIcon;
  final String emptyLabel;

  /// Disposition des items : colonne verticale (tuiles) ou Wrap (chips).
  final SectionListLayout layout;
  final double wrapSpacing;
  final double wrapRunSpacing;

  Future<void> _add(BuildContext context) async {
    final created = await onAdd(context);
    if (created != null) onChanged([...items, created]);
  }

  Future<void> _edit(BuildContext context, int index) async {
    final updated = await onEdit(context, items[index]);
    if (updated != null) {
      final next = List<T>.of(items);
      next[index] = updated;
      onChanged(next);
    }
  }

  void _delete(int index) {
    final next = List<T>.of(items)..removeAt(index);
    onChanged(next);
  }

  Widget _tile(BuildContext context, int index) => itemBuilder(
        context,
        items[index],
        index,
        onEditItem: () => _edit(context, index),
        onDeleteItem: () => _delete(index),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          SectionEmptyState(icon: emptyIcon, label: emptyLabel)
        else if (layout == SectionListLayout.wrap)
          Wrap(
            spacing: wrapSpacing,
            runSpacing: wrapRunSpacing,
            children: [
              for (var i = 0; i < items.length; i++) _tile(context, i),
            ],
          )
        else
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) _tile(context, i),
            ],
          ),
        const SizedBox(height: 8),
        SectionAddButton(label: addLabel, onTap: () => _add(context)),
      ],
    );
  }
}

/// Disposition des items d'une [EditableSectionList].
enum SectionListLayout {
  /// Tuiles empilees verticalement (experience, formations, projets...).
  column,

  /// Chips disposes en Wrap (competences, langues...).
  wrap,
}
