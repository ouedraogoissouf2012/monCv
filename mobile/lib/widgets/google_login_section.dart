import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/error_helper.dart';
import 'google_sign_in_button.dart';

class GoogleLoginSection extends StatelessWidget {
  const GoogleLoginSection({super.key});

  @override
  Widget build(BuildContext context) => GoogleSignInButton(
        onCredential: (credential) async {
          final auth = context.read<AuthProvider>();
          final ok = await auth.loginWithGoogle(credential);
          if (!ok && context.mounted) {
            ErrorHelper.showError(
              context,
              auth.error ?? AppLocalizations.of(context)!.googleSignInFailed,
            );
          }
        },
      );
}
