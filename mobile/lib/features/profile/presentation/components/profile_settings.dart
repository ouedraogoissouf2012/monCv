import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/design_system/tokens/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../models/notification_preferences.dart';
import '../../../../providers/locale_provider.dart';
import '../../../../providers/notification_provider.dart';
import '../../../../widgets/theme_selector.dart';
import '../../../settings/presentation/components/settings_section.dart';
import '../../../settings/presentation/components/settings_tile.dart';
import '../profile_controller.dart';

/// Groupes de reglages du profil (issue #250, E4) : informations, apparence,
/// langue et notifications. Chaque groupe est une [SettingsSection] reutilisee.
///
/// L'etat de sauvegarde des notifications est visible : les interrupteurs sont
/// desactives pendant [NotificationProvider.isLoading].
class ProfileSettings extends StatelessWidget {
  const ProfileSettings({super.key, required this.controller});

  final ProfileController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSection(
          title: l.information,
          child: SettingsCard(children: [
            SettingsTile.info(
              icon: Icons.person_outline,
              label: l.fullName,
              value: controller.fullName ?? '—',
            ),
            SettingsTile.info(
              icon: Icons.email_outlined,
              label: l.email,
              value: controller.email.isEmpty ? '—' : controller.email,
            ),
          ]),
        ),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(title: l.appearance, child: const ThemeSelector()),
        const SizedBox(height: AppSpacing.xl),
        SettingsSection(title: l.language, child: const _LanguageSelector()),
        const SizedBox(height: AppSpacing.xxl),
        SettingsSection(title: l.notifications, child: const _NotificationToggles()),
      ],
    );
  }
}

/// Selecteur de langue (fr/en) branche sur [LocaleProvider].
class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'fr', label: Text(l.french)),
        ButtonSegment(value: 'en', label: Text(l.english)),
      ],
      selected: {context.watch<LocaleProvider>().locale.languageCode},
      onSelectionChanged: (selection) =>
          context.read<LocaleProvider>().setLocale(Locale(selection.first)),
    );
  }
}

/// Interrupteurs de notifications branches sur [NotificationProvider].
class _NotificationToggles extends StatelessWidget {
  const _NotificationToggles();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final value = provider.value;
        void toggle(NotificationPreferences next) => provider.update(next);
        return SettingsCard(children: [
          SwitchListTile(
            secondary: const Icon(Icons.update_rounded),
            title: Text(l.staleCvReminder),
            subtitle: Text(l.staleCvReminderSubtitle),
            value: value.staleCvEnabled,
            onChanged: provider.isLoading
                ? null
                : (on) => toggle(value.copyWith(staleCvEnabled: on)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.visibility_outlined),
            title: Text(l.cvViewNotifications),
            subtitle: Text(l.cvViewNotificationsSubtitle),
            value: value.cvViewsEnabled,
            onChanged: provider.isLoading
                ? null
                : (on) => toggle(value.copyWith(cvViewsEnabled: on)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: Text(l.aiTipNotifications),
            subtitle: Text(l.aiTipNotificationsSubtitle),
            value: value.aiTipsEnabled,
            onChanged: provider.isLoading
                ? null
                : (on) => toggle(value.copyWith(aiTipsEnabled: on)),
          ),
        ]);
      },
    );
  }
}
