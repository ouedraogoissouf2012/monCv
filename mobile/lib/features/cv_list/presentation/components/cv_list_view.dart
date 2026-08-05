import 'package:flutter/material.dart';

import '../../../../models/cv.dart';
import '../../../../utils/responsive.dart';

/// Vue liste (mobile) / grille (desktop) des CV (issue #249, D4). Extraite de
/// home_screen pour garder l'ecran mince ; l'element est fourni par [itemBuilder].
class CvListView extends StatelessWidget {
  const CvListView({super.key, required this.cvs, required this.itemBuilder});

  final List<Cv> cvs;
  final Widget Function(Cv cv) itemBuilder;

  @override
  Widget build(BuildContext context) {
    if (!Responsive.isDesktop(context)) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: cvs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => itemBuilder(cvs[i]),
      );
    }
    final columns = MediaQuery.of(context).size.width >= 1200 ? 3 : 2;
    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.4,
      ),
      itemCount: cvs.length,
      itemBuilder: (_, i) => itemBuilder(cvs[i]),
    );
  }
}
