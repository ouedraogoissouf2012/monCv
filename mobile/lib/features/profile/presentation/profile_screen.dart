import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/navigation/app_shell.dart';
import '../../../core/ui/confirm_dialog.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cv_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../utils/app_colors.dart';
import '../../../widgets/google_account_link_section.dart';
import '../../account/application/delete_account.dart';
import '../../account/application/export_account_data.dart';
import '../../account/presentation/account_actions_controller.dart';
import 'components/profile_header.dart';
import 'components/profile_logout_button.dart';
import 'components/profile_privacy_section.dart';
import 'components/profile_settings.dart';
import 'components/profile_stats.dart';
import 'profile_controller.dart';

/// Ecran profil (issue #250, E4). Orchestrateur mince : entete/stats via le
/// [ProfileController] (E3), reglages via [ProfileSettings] (E1), actions de
/// compte deleguees a [AccountActionsController] (E2). Remplace l'ancien
/// monolithe (536 l.).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.exportData,
    required this.deleteAccount,
  });

  final ExportAccountDataUseCase exportData;
  final DeleteAccountUseCase deleteAccount;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AccountActionsController _account;

  @override
  void initState() {
    super.initState();
    _account = AccountActionsController(
      exportData: widget.exportData,
      deleteAccount: widget.deleteAccount,
      clearSession: context.read<AuthProvider>().logout,
    );
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<NotificationProvider>().load());
  }

  @override
  void dispose() {
    _account.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context)!;
    final ok = await _account.exportData() == AccountActionOutcome.success;
    if (!mounted) return;
    if (ok && _account.exportedJson != null) {
      await Clipboard.setData(ClipboardData(text: _account.exportedJson!));
      if (!mounted) return;
      messenger.showSnackBar(_snack(l.exportCopied, success: true));
    } else {
      messenger.showSnackBar(_snack(l.exportFailed(l.errorGeneric)));
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(context,
        title: l.deleteAccountTitle,
        content: l.deleteAccountConfirm,
        confirmLabel: l.delete,
        destructive: true);
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await _account.deleteAccount() == AccountActionOutcome.success;
    if (!mounted) return;
    if (ok) {
      context.go('/landing');
    } else {
      messenger.showSnackBar(_snack(l.deleteAccountFailed(l.errorGeneric)));
    }
  }

  Future<void> _logout() async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showConfirmDialog(context,
        title: l.logoutTitle,
        content: l.logoutConfirm,
        confirmLabel: l.disconnect,
        destructive: true);
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }

  SnackBar _snack(String text, {bool success = false}) => SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? AppColors.success : null,
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final user = context.watch<AuthProvider>().user;
    final controller = ProfileController.from(
      fullName: user?.fullName,
      email: user?.email,
      cvCount: context.watch<CvProvider>().cvs.length,
    );
    return AppShell(
      currentIndex: 3,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.lg),
            ProfileHeader(controller: controller, fallbackName: l.user),
            const SizedBox(height: AppSpacing.xxl),
            ProfileStats(dashboard: controller.dashboard),
            const SizedBox(height: AppSpacing.xxl),
            ProfileSettings(controller: controller),
            const SizedBox(height: AppSpacing.xxl),
            ProfilePrivacySection(
              onPrivacyPolicy: () => context.push('/privacy'),
              onExportData: _export,
              onDeleteAccount: _delete,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const GoogleAccountLinkSection(),
            ProfileLogoutButton(onPressed: _logout),
          ],
        ),
      ),
    );
  }
}
