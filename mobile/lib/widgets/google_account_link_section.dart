import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'google_sign_in_button.dart';

class GoogleAccountLinkSection extends StatelessWidget {
  const GoogleAccountLinkSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = auth.user?.authProvider;
    if (provider == null || provider == 'GOOGLE' || provider == 'BOTH') {
      return const SizedBox.shrink();
    }
    final l = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.googleAccount, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      GoogleSignInButton(onCredential: (value) => _link(context, value)),
      const SizedBox(height: 24),
    ]);
  }

  Future<void> _link(BuildContext context, String credential) async {
    final l = AppLocalizations.of(context)!;
    final auth = context.read<AuthProvider>();
    final ok = await auth.linkGoogle(credential);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(ok ? l.googleLinkSuccess : auth.error ?? l.googleLinkFailed),
      behavior: SnackBarBehavior.floating,
      backgroundColor:
          ok ? AppColors.success : Theme.of(context).colorScheme.error,
    ));
  }
}
