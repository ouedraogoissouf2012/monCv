import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../utils/responsive.dart';
import 'app_destination.dart';
import 'responsive_navigation.dart';

/// Ossature responsive de l'application (issue #249, D2).
///
/// Ne gere QUE la structure et les slots (body/title/actions/fab) + le choix
/// sidebar (desktop) vs NavigationBar (mobile). La navigation est pilotee par la
/// liste unique [appDestinations]. Aucune logique auth metier ici (la
/// deconnexion vit dans la navigation). Remplace `AppScaffold`.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    required this.currentIndex,
    this.title,
    this.actions,
    this.floatingActionButton,
  });

  final Widget body;
  final int currentIndex;
  final String? title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  void _onSelected(BuildContext context, int index) {
    final destination = appDestinations[index];
    if (destination.push) {
      context.push(destination.route);
    } else {
      context.go(destination.route);
    }
  }

  PreferredSizeWidget? _appBar() => title == null
      ? null
      : AppBar(
          title: Text(title!),
          actions: actions,
          automaticallyImplyLeading: false,
        );

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            AppSidebar(
                currentIndex: currentIndex,
                onSelected: (i) => _onSelected(context, i)),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(
              child: Scaffold(
                appBar: _appBar(),
                body: body,
                floatingActionButton: floatingActionButton,
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: _appBar(),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: currentIndex,
        onSelected: (i) => _onSelected(context, i),
      ),
    );
  }
}
