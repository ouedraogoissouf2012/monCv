import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../utils/error_helper.dart';
import '../../../../widgets/google_login_section.dart';
import '../components/auth_feature_strip.dart';
import '../components/auth_form_field.dart';
import '../components/auth_headline.dart';
import '../components/auth_logo.dart';
import '../components/auth_nav_link.dart';
import '../components/auth_palette.dart';
import '../components/auth_primary_button.dart';
import '../components/auth_shell.dart';
import '../controllers/auth_submit_outcome.dart';
import '../controllers/login_controller.dart';

/// Ecran de connexion (issue #248, C4).
///
/// Orchestrateur mince sur les composants partages (C2) et [LoginController]
/// (C3). Remplace le monolithe de 560 lignes. Le lien "mot de passe oublie"
/// pointe vers le flux de reinitialisation (issue #381).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _controller = LoginController(submit: auth.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final outcome = await _controller.submit(
        email: _email.text, password: _password.text);
    if (!mounted || outcome != AuthSubmitOutcome.backendError) return;
    final auth = context.read<AuthProvider>();
    ErrorHelper.showError(
        context, auth.error ?? AppLocalizations.of(context)!.loginError,
        onRetry: _submit);
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
              AuthHeadline(title: l.welcomeBack, subtitle: l.welcomeSubtitle),
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
              const SizedBox(height: 14),
              AuthFormField(
                label: l.password,
                icon: Icons.lock_outline,
                controller: _password,
                hint: '••••••••',
                obscure: _obscure,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 18,
                      color: AuthPalette.muted),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? l.fieldRequired : null,
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.go('/forgot-password'),
                  child: Text(l.forgotPassword,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AuthPalette.blue,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: _controller,
                builder: (context, _) => AuthPrimaryButton(
                  label: l.login,
                  loading: _controller.loading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 16),
              const GoogleLoginSection(),
              const SizedBox(height: 24),
              AuthNavLink(
                  prompt: l.noAccount,
                  action: l.register,
                  onTap: () => context.go('/register')),
              const SizedBox(height: 20),
              const AuthFeatureStrip(),
            ],
          ),
        ),
      ),
    );
  }
}

