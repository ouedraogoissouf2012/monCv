import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/error_helper.dart';
import '../../domain/password_policy.dart';
import '../components/auth_feature_strip.dart';
import '../components/auth_form_field.dart';
import '../components/auth_headline.dart';
import '../components/auth_logo.dart';
import '../components/auth_nav_link.dart';
import '../components/auth_palette.dart';
import '../components/auth_password_strength_bar.dart';
import '../components/auth_primary_button.dart';
import '../components/auth_shell.dart';
import '../controllers/auth_submit_outcome.dart';
import '../controllers/register_controller.dart';
import 'register_name_fields.dart';

/// Ecran d'inscription (issue #248, C4).
///
/// Orchestrateur mince sur les composants partages (C2) et [RegisterController]
/// (C3, force du mot de passe via PasswordPolicy). Remplace le monolithe de
/// 667 lignes.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  late final RegisterController _controller;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _controller = RegisterController(
      submit: ({required email, required password, required firstName, required lastName}) =>
          auth.register(
              email: email, password: password, prenom: firstName, nom: lastName),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final c in [_firstName, _lastName, _email, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final outcome = await _controller.submit(
      email: _email.text,
      password: _password.text,
      firstName: _firstName.text,
      lastName: _lastName.text,
    );
    if (!mounted || outcome != AuthSubmitOutcome.backendError) return;
    final auth = context.read<AuthProvider>();
    ErrorHelper.showError(
        context, auth.error ?? AppLocalizations.of(context)!.registerError);
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
    final narrow = MediaQuery.sizeOf(context).width < 420;
    return AuthShell(
      orbs: AuthShell.twoOrbs,
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
                  title: l.createAccount, subtitle: l.createAccountSubtitle),
              const SizedBox(height: 28),
              RegisterNameFields(
                  firstName: _firstName, lastName: _lastName, narrow: narrow),
              const SizedBox(height: 14),
              AuthFormField(
                label: l.email,
                icon: Icons.email_outlined,
                controller: _email,
                hint: l.emailHint,
                compact: narrow,
                keyboardType: TextInputType.emailAddress,
                uppercaseLabel: false,
                validator: (v) {
                  if (v == null || v.isEmpty) return l.fieldRequired;
                  if (!v.contains('@')) return l.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              AuthFormField(
                label: l.password,
                icon: Icons.lock_outline,
                controller: _password,
                hint: '••••••••',
                obscure: _obscure,
                compact: narrow,
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
                compact: narrow,
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
                  label: l.createMyAccount,
                  loading: _controller.loading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 20),
              AuthNavLink(
                  prompt: l.hasAccount,
                  action: l.login,
                  onTap: () => context.go('/login')),
              const SizedBox(height: 20),
              const AuthFeatureStrip(),
            ],
          ),
        ),
      ),
    );
  }

}

