import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../../utils/error_helper.dart';
import '../../auth/domain/password_policy.dart';
import '../../auth/presentation/components/auth_form_field.dart';
import '../../auth/presentation/components/auth_headline.dart';
import '../../auth/presentation/components/auth_logo.dart';
import '../../auth/presentation/components/auth_palette.dart';
import '../../auth/presentation/components/auth_password_strength_bar.dart';
import '../../auth/presentation/components/auth_primary_button.dart';
import '../../auth/presentation/components/auth_shell.dart';
import '../../auth/presentation/controllers/auth_submit_outcome.dart';
import '../application/confirm_password_reset.dart';
import 'reset_password_controller.dart';

/// Ecran « nouveau mot de passe » (issue #381).
///
/// Atteint via le lien recu par email : le [token] provient de la route
/// (`/reset-password/:token`), le use case est injecte par le routeur. Reutilise
/// la politique de mot de passe de l'inscription (barre de force + regles).
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.confirmReset,
  });

  final String token;
  final ConfirmPasswordResetUseCase confirmReset;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  late final ResetPasswordController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ResetPasswordController(
      submit: (newPassword) => widget.confirmReset.call(
        ConfirmPasswordResetParams(
            token: widget.token, newPassword: newPassword),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final outcome = await _controller.submit(newPassword: _password.text);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    switch (outcome) {
      case AuthSubmitOutcome.success:
        ErrorHelper.showSuccess(context, l.resetPasswordSuccess);
        context.go('/login');
      case AuthSubmitOutcome.backendError:
        ErrorHelper.showError(
            context, _controller.lastError?.message ?? l.resetPasswordError);
      case AuthSubmitOutcome.invalidInput:
        break; // La validation inline du Form affiche deja l'erreur.
    }
  }

  Widget _obscureToggle(bool value, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Icon(
            value ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: AuthPalette.muted),
      );

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
                  title: l.resetPasswordTitle,
                  subtitle: l.resetPasswordSubtitle),
              const SizedBox(height: 28),
              AuthFormField(
                label: l.newPassword,
                icon: Icons.lock_outline,
                controller: _password,
                hint: '••••••••',
                obscure: _obscure,
                uppercaseLabel: false,
                onChanged: _controller.onPasswordChanged,
                suffixIcon: _obscureToggle(
                    _obscure, () => setState(() => _obscure = !_obscure)),
                validator: (v) => switch (_controller.validatePassword(v)) {
                  PasswordRuleError.empty => l.required,
                  PasswordRuleError.tooShort => l.passwordMinLength,
                  null => null,
                },
              ),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => _password.text.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: AuthPasswordStrengthBar(
                          strength: _controller.passwordStrength,
                          score: _controller.passwordScore,
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              AuthFormField(
                label: l.confirmPassword,
                icon: Icons.lock_outline,
                controller: _confirm,
                hint: '••••••••',
                obscure: _obscureConfirm,
                uppercaseLabel: false,
                suffixIcon: _obscureToggle(_obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm)),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.required;
                  if (v != _password.text) return l.passwordsDoNotMatch;
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => AuthPrimaryButton(
                  label: l.resetPasswordButton,
                  loading: _controller.loading,
                  onPressed: _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
