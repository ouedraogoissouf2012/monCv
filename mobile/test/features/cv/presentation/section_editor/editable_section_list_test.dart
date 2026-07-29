import 'package:cv_mobile/features/cv/presentation/section_editor/editable_section_list.dart';
import 'package:cv_mobile/features/cv/presentation/section_editor/section_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('liste vide -> affiche l etat vide (#239)', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: const [],
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (_) {},
          onAdd: (_) async => null,
          onEdit: (_, c) async => null,
          itemBuilder: (ctx, item, index,
                  {required onEditItem, required onDeleteItem}) =>
              SectionItemTile(
            title: item,
            subtitle: '',
            onEdit: onEditItem,
            onDelete: onDeleteItem,
          ),
        ),
      ),
    ));
    expect(find.byType(SectionEmptyState), findsOneWidget);
    expect(find.text('Vide'), findsOneWidget);
    expect(find.byType(SectionItemTile), findsNothing);
  });

  testWidgets('add valide -> nouvelle liste avec l item ajoute en fin (#239)',
      (tester) async {
    List<String>? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: const ['A'],
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (next) => captured = next,
          onAdd: (_) async => 'B',
          onEdit: (_, c) async => null,
          itemBuilder: (ctx, item, index,
                  {required onEditItem, required onDeleteItem}) =>
              SectionItemTile(
            title: item,
            subtitle: '',
            onEdit: onEditItem,
            onDelete: onDeleteItem,
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    expect(captured, ['A', 'B']);
  });

  testWidgets('add annule (null) -> onChanged non appele (#239)',
      (tester) async {
    var changedCalled = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: const ['A'],
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (_) => changedCalled = true,
          onAdd: (_) async => null, // annulation
          onEdit: (_, c) async => null,
          itemBuilder: (ctx, item, index,
                  {required onEditItem, required onDeleteItem}) =>
              SectionItemTile(
            title: item,
            subtitle: '',
            onEdit: onEditItem,
            onDelete: onDeleteItem,
          ),
        ),
      ),
    ));

    await tester.tap(find.byType(SectionAddButton));
    await tester.pumpAndSettle();

    expect(changedCalled, isFalse);
  });

  testWidgets('edit valide -> remplace l item a son index (#239)',
      (tester) async {
    List<String>? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: const ['A', 'B', 'C'],
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (next) => captured = next,
          onAdd: (_) async => null,
          onEdit: (_, current) async => '$current*',
          itemBuilder: (ctx, item, index,
                  {required onEditItem, required onDeleteItem}) =>
              SectionItemTile(
            title: item,
            subtitle: '',
            onEdit: onEditItem,
            onDelete: onDeleteItem,
          ),
        ),
      ),
    ));

    // Edite le 2e item (index 1 = 'B').
    await tester.tap(find.byIcon(Icons.edit_outlined).at(1));
    await tester.pumpAndSettle();

    expect(captured, ['A', 'B*', 'C']);
  });

  testWidgets('delete -> retire l item a son index (#239)', (tester) async {
    List<String>? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: const ['A', 'B', 'C'],
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (next) => captured = next,
          onAdd: (_) async => null,
          onEdit: (_, c) async => null,
          itemBuilder: (ctx, item, index,
                  {required onEditItem, required onDeleteItem}) =>
              SectionItemTile(
            title: item,
            subtitle: '',
            onEdit: onEditItem,
            onDelete: onDeleteItem,
          ),
        ),
      ),
    ));

    // Supprime le 1er item (index 0 = 'A').
    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    expect(captured, ['B', 'C']);
  });

  testWidgets('layout wrap -> items dans un Wrap (competences/langues) (#239)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: const ['A', 'B'],
          layout: SectionListLayout.wrap,
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (_) {},
          onAdd: (_) async => null,
          onEdit: (_, c) async => null,
          itemBuilder: (ctx, item, index,
                  {required onEditItem, required onDeleteItem}) =>
              Chip(label: Text(item)),
        ),
      ),
    ));

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(2));
  });

  testWidgets('immutabilite : la liste source n est pas mutee en place (#239)',
      (tester) async {
    final source = <String>['A', 'B'];
    List<String>? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: source,
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (next) => captured = next,
          onAdd: (_) async => null,
          onEdit: (_, c) async => null,
          itemBuilder: (ctx, item, index,
                  {required onEditItem, required onDeleteItem}) =>
              SectionItemTile(
            title: item,
            subtitle: '',
            onEdit: onEditItem,
            onDelete: onDeleteItem,
          ),
        ),
      ),
    ));

    await tester.tap(find.byIcon(Icons.delete_outline).first);
    await tester.pumpAndSettle();

    // La nouvelle liste est amputee...
    expect(captured, ['B']);
    // ...mais la liste source d origine reste intacte (aucune mutation en place).
    expect(source, ['A', 'B']);
    expect(identical(source, captured), isFalse);
  });
}
