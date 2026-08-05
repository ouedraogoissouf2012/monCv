import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import 'app_destination.dart';

/// Barre de navigation basse (mobile), construite depuis [appDestinations]
/// (issue #249, D2).
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onSelected,
      destinations: [
        for (final d in appDestinations)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label(l),
          ),
      ],
    );
  }
}

/// Barre laterale (desktop), construite depuis [appDestinations] (issue #249).
class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 200,
      color: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : colorScheme.surface,
      child: Column(
        children: [
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.description_outlined, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text('MonCV',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold, color: colorScheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < appDestinations.length; i++)
            _SidebarItem(
              destination: appDestinations[i],
              selected: currentIndex == i,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          const Divider(height: 1),
          const Padding(padding: EdgeInsets.all(8), child: _LogoutButton()),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem(
      {required this.destination, required this.selected, required this.onTap});

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    final color = selected
        ? colorScheme.primary
        : colorScheme.onSurface.withValues(alpha: 0.6);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: selected
            ? BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12))
            : null,
        child: Row(
          children: [
            Icon(selected ? destination.selectedIcon : destination.icon,
                size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(destination.label(l),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton de deconnexion (action UI ; delegue a AuthProvider). Confine a la
/// navigation, hors du shell (l'AppShell ne porte aucune logique auth).
class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () => _confirmAndLogout(context, l, colorScheme),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(Icons.logout_rounded,
                size: 20, color: colorScheme.error.withValues(alpha: 0.8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(l.logoutTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndLogout(
      BuildContext context, AppLocalizations l, ColorScheme colorScheme) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.logoutTitle),
        content: Text(l.logoutConfirm),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
              child: Text(l.disconnect)),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) context.go('/login');
    }
  }
}
