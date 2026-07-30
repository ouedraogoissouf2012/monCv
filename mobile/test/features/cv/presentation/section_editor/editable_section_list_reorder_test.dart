import 'package:cv_mobile/features/cv/presentation/section_editor/editable_section_list.dart';
import 'package:cv_mobile/features/cv/presentation/section_editor/section_primitives.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monte une liste reorderable et renvoie l'accesseur de la derniere liste.
  Future<List<String> Function()> pumpReorderable(WidgetTester tester,
      {required List<String> initial}) async {
    var current = List<String>.of(initial);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (ctx, setState) => EditableSectionList<String>(
            items: current,
            reorderable: true,
            keyOf: (item, index) => ValueKey('$item-$index'),
            addLabel: 'Ajouter',
            emptyIcon: Icons.inbox_outlined,
            emptyLabel: 'Vide',
            onChanged: (next) => setState(() => current = next),
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
      ),
    ));
    return () => current;
  }

  testWidgets('reorderable : rend un ReorderableListView (#239)',
      (tester) async {
    await pumpReorderable(tester, initial: ['A', 'B', 'C']);
    expect(find.byType(ReorderableListView), findsOneWidget);
  });

  testWidgets('reorder : deplacer un item descend produit la bonne liste (#239)',
      (tester) async {
    final read = await pumpReorderable(tester, initial: ['A', 'B', 'C']);

    // Convention ReorderableListView.onReorder : descendre A (0) apres C
    // se traduit par un deplacement de l'index 0 vers l'index 3 (fin).
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(0, 3);
    await tester.pumpAndSettle();

    expect(read(), ['B', 'C', 'A']);
  });

  testWidgets('reorder : remonter un item produit la bonne liste (#239)',
      (tester) async {
    final read = await pumpReorderable(tester, initial: ['A', 'B', 'C']);

    // Remonter C (index 2) en tete (index 0).
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(2, 0);
    await tester.pumpAndSettle();

    expect(read(), ['C', 'A', 'B']);
  });

  testWidgets('reorder sur meme position -> aucun changement (#239)',
      (tester) async {
    var changedCount = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: EditableSectionList<String>(
          items: const ['A', 'B'],
          reorderable: true,
          keyOf: (item, index) => ValueKey('$item-$index'),
          addLabel: 'Ajouter',
          emptyIcon: Icons.inbox_outlined,
          emptyLabel: 'Vide',
          onChanged: (_) => changedCount++,
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

    // Deplacer l'index 0 vers 1 (= meme position apres decrement) : no-op.
    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorder(0, 1);
    await tester.pumpAndSettle();

    expect(changedCount, 0);
  });

  test('reorderable=true sans keyOf -> assertion (#239)', () {
    expect(
      () => EditableSectionList<String>(
        items: const [],
        reorderable: true,
        addLabel: '',
        emptyIcon: Icons.abc,
        emptyLabel: '',
        onChanged: (_) {},
        onAdd: (_) async => null,
        onEdit: (_, c) async => null,
        itemBuilder: (ctx, item, index,
                {required onEditItem, required onDeleteItem}) =>
            const SizedBox(),
      ),
      throwsAssertionError,
    );
  });

  test('reorderable=true en layout wrap -> assertion (#239)', () {
    expect(
      () => EditableSectionList<String>(
        items: const [],
        reorderable: true,
        layout: SectionListLayout.wrap,
        keyOf: (item, index) => ValueKey(index),
        addLabel: '',
        emptyIcon: Icons.abc,
        emptyLabel: '',
        onChanged: (_) {},
        onAdd: (_) async => null,
        onEdit: (_, c) async => null,
        itemBuilder: (ctx, item, index,
                {required onEditItem, required onDeleteItem}) =>
            const SizedBox(),
      ),
      throwsAssertionError,
    );
  });
}
