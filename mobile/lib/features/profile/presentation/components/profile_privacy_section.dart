import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../settings/presentation/components/destructive_action_tile.dart';
import '../../../settings/presentation/components/settings_section.dart';
import '../../../settings/presentation/components/settings_tile.dart';

/// Section confidentialite du profil (issue #250, E4) : politique, export RGPD
/// et suppression de compte.
///
/// Les actions sont deleguees a la vue via des callbacks — l'export et la
/// suppression (effets presse-papier / reseau / navigation) sont orchestres par
/// l'ecran a partir de l'AccountActionsController (E2), pas ici.
class ProfilePrivacySection extends StatelessWidget {
  const ProfilePrivacySection({
    super.key,
    required this.onPrivacyPolicy,
    required this.onExportData,
    required this.onDeleteAccount,
  });

  final VoidCallback onPrivacyPolicy;
  final VoidCallback onExportData;
  final VoidCallback onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsSection(
      title: l.privacy,
      child: SettingsCard(children: [
        SettingsTile(
          icon: Icons.privacy_tip_outlined,
          title: l.privacyPolicy,
          subtitle: l.privacyPolicySubtitle,
          onTap: onPrivacyPolicy,
        ),
        SettingsTile(
          icon: Icons.file_download_outlined,
          title: l.exportMyData,
          subtitle: l.exportMyDataSubtitle,
          onTap: onExportData,
        ),
        DestructiveActionTile(
          icon: Icons.delete_forever_outlined,
          title: l.deleteMyAccount,
          subtitle: l.deleteMyAccountSubtitle,
          onTap: onDeleteAccount,
        ),
      ]),
    );
  }
}
