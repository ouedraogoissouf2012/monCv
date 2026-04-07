import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    final themes = [
      (
        AppThemeMode.minimal,
        'Minimal',
        const Color(0xFF2563EB),
        const Color(0xFFF8FAFC),
        Icons.wb_sunny_outlined,
      ),
      (
        AppThemeMode.vibrant,
        'Vibrant',
        const Color(0xFF667EEA),
        const Color(0xFFF5F0FF),
        Icons.palette_outlined,
      ),
      (
        AppThemeMode.premium,
        'Premium',
        const Color(0xFFFFD700),
        const Color(0xFF0F1117),
        Icons.stars_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thème',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: themes.map((t) {
            final isSelected = themeProvider.mode == t.$1;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _ThemeCard(
                  mode: t.$1,
                  label: t.$2,
                  primary: t.$3,
                  background: t.$4,
                  icon: t.$5,
                  isSelected: isSelected,
                  onTap: () => context.read<ThemeProvider>().setTheme(t.$1),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppThemeMode mode;
  final String label;
  final Color primary;
  final Color background;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.mode,
    required this.label,
    required this.primary,
    required this.background,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primary.withValues(alpha: 0.3), blurRadius: 8)]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.normal,
                color: primary,
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primary, size: 14),
          ],
        ),
      ),
    );
  }
}
