import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/error_helper.dart';
import '../../auth/presentation/components/auth_form_field.dart';
import '../../auth/presentation/components/auth_headline.dart';
import '../../auth/presentation/components/auth_logo.dart';
import '../../auth/presentation/components/auth_nav_link.dart';
import '../../auth/presentation/components/auth_primary_button.dart';
import '../../auth/presentation/components/auth_shell.dart';
import '../../auth/presentation/controllers/auth_submit_outcome.dart';
import '../application/request_password_reset.dart';
import 'forgot_password_controller.dart';

/// Ecran « mot de passe oublie » (issue #381).
///
/// Orchestrateur mince sur les composants d'auth partages et
/// [ForgotPasswordController]. Le use case est injecte par le routeur (testable
/// avec un double). Route publique : accessible sans authentification.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, required this.requestReset});

  final RequestPasswordResetUseCase requestReset;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  late final ForgotPasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ForgotPasswordController(
      submit: (email) =>
          widget.requestReset.call(RequestPasswordResetParams(email: email)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final outcome = await _controller.submit(_email.text);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    switch (outcome) {
      case AuthSubmitOutcome.success:
        // Message neutre : ne revele jamais si le compte existe (anti-enumeration).
        ErrorHelper.showSuccess(context, l.forgotPasswordSent);
      case AuthSubmitOutcome.backendError:
        ErrorHelper.showError(
            context, _controller.lastError?.message ?? l.resetLinkError,
            onRetry: _submit);
      case AuthSubmitOutcome.invalidInput:
        break; // La validation inline du Form affiche deja l'erreur.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AuthShell(
      child: AuthCard(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthLogo(),
              const SizedBox(height: 28),
              AuthHeadline(
                  title: l.forgotPasswordTitle,
                  subtitle: l.forgotPasswordSubtitle),
              const SizedBox(height: 28),
              AuthFormField(
                label: l.email,
                icon: Icons.email_outlined,
                controller: _email,
                hint: l.emailHint,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return l.fieldRequired;
                  if (!v.contains('@')) return l.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => AuthPrimaryButton(
                  label: l.sendResetLink,
                  loading: _controller.loading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 24),
              AuthNavLink(
                  prompt: l.rememberedPassword,
                  action: l.login,
                  onTap: () => context.go('/login')),
            ],
          ),
        ),
      ),
    );
  }
}
