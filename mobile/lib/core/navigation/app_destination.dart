import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Une destination de navigation principale (issue #249, D2).
///
/// Source UNIQUE et typee alimentant a la fois la sidebar (desktop), la
/// NavigationBar (mobile) et le routing GoRouter — le monolithe dupliquait ces
/// 4 entrees a TROIS endroits (_onNavTap, _Sidebar, _BottomNav).
class AppDestination {
  const AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.route,
    required this.label,
    this.push = false,
    this.sidebarOnly = false,
  });

  final IconData icon;
  final IconData selectedIcon;

  /// Route GoRouter cible.
  final String route;

  /// Libelle localise (resolu au build : le domaine reste localise-agnostique).
  final String Function(AppLocalizations) label;

  /// `true` -> `context.push` (empile, ex. creation) ; sinon `context.go`.
  final bool push;

  /// Visible seulement dans la sidebar desktop (pas la barre mobile).
  final bool sidebarOnly;
}

/// Les destinations principales, dans l'ordre d'affichage. L'index dans cette
/// liste est le `currentIndex` des barres de navigation.
const List<AppDestination> appDestinations = [
  AppDestination(
    icon: Icons.description_outlined,
    selectedIcon: Icons.description,
    route: '/home',
    label: _myCvs,
  ),
  AppDestination(
    icon: Icons.add_circle_outline,
    selectedIcon: Icons.add_circle,
    route: '/cvs/create',
    label: _newCv,
    push: true,
  ),
  AppDestination(
    icon: Icons.work_outline,
    selectedIcon: Icons.work,
    route: '/applications',
    label: _applications,
  ),
  AppDestination(
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    route: '/profile',
    label: _profile,
  ),
  AppDestination(
    icon: Icons.delete_outline,
    selectedIcon: Icons.delete,
    route: '/cvs/trash',
    label: _trash,
    sidebarOnly: true,
  ),
];

// Selecteurs de libelles (fonctions top-level -> utilisables dans un const).
String _myCvs(AppLocalizations l) => l.myCvs;
String _newCv(AppLocalizations l) => l.newCv;
String _applications(AppLocalizations l) => l.applications;
String _profile(AppLocalizations l) => l.profile;
String _trash(AppLocalizations l) => l.trashTitle;
