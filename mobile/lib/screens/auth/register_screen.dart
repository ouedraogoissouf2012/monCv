import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/error_helper.dart';

// Même palette que login
const _kBlue = AppColors.brandBlue;
const _kBg = AppColors.warmBackground;
const _kText = AppColors.neutral850;
const _kMuted = AppColors.neutral400;
const _kBorder = AppColors.neutral200;
const _kWhite = AppColors.white;
const _kFieldBg = AppColors.warmSurface;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;
  double _passwordStrength = 0;
  String _passwordLabel = '';
  Color _passwordColor = Colors.grey;

  void _checkPasswordStrength(String password) {
    double strength = 0;
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (password.length >= 12) strength += 0.1;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.1;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

    String label;
    Color color;
    if (strength < 0.3) {
      label = 'weak';
      color = Colors.red;
    } else if (strength < 0.6) {
      label = 'medium';
      color = Colors.orange;
    } else if (strength < 0.8) {
      label = 'good';
      color = AppColors.primary;
    } else {
      label = 'strong';
      color = AppColors.success;
    }

    setState(() {
      _passwordStrength = strength.clamp(0, 1);
      _passwordLabel = label;
      _passwordColor = color;
    });
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      prenom: _prenomCtrl.text.trim(),
      nom: _nomCtrl.text.trim(),
    );
    if (!ok && mounted) {
      ErrorHelper.showError(
          context, auth.error ?? AppLocalizations.of(context)!.registerError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 420;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          const _GridBackground(),
          const _FloatingOrb(
            size: 500,
            color: _kBlue,
            opacity: 0.10,
            top: -100,
            right: -100,
            delay: 0,
          ),
          const _FloatingOrb(
            size: 400,
            color: _kBlue,
            opacity: 0.06,
            bottom: -80,
            left: -80,
            delay: 3,
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 16 : 24,
                vertical: 24,
              ),
              child: _buildCard(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    final isNarrow = MediaQuery.of(context).size.width < 420;
    final l = AppLocalizations.of(context)!;
    final passwordLabel = switch (_passwordLabel) {
      'weak' => l.passwordStrengthWeak,
      'medium' => l.passwordStrengthMedium,
      'good' => l.passwordStrengthGood,
      'strong' => l.passwordStrengthStrong,
      _ => '',
    };

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 460),
        padding:
            EdgeInsets.fromLTRB(isNarrow ? 20 : 36, 36, isNarrow ? 20 : 36, 28),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(isNarrow ? 24 : 28),
          border: Border.all(color: _kBorder, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 64,
              offset: Offset(0, 24),
            ),
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: _kBlue,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description_outlined,
                        size: 20, color: _kWhite),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'MonCV',
                    style: AppTypography.display(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _kText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // Headline
              Text(
                l.createAccount,
                style: AppTypography.display(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: _kText,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.createAccountSubtitle,
                style: const TextStyle(
                    fontSize: 14, color: _kMuted, fontWeight: FontWeight.w300),
              ),
              const SizedBox(height: 28),
              // Prénom + Nom
              _buildNameFields(isNarrow, l),
              const SizedBox(height: 14),
              _buildField(
                label: l.email,
                icon: Icons.email_outlined,
                controller: _emailCtrl,
                hint: l.emailHint,
                compact: isNarrow,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return l.fieldRequired;
                  if (!v.contains('@')) return l.invalidEmail;
                  return null;
                },
              ),
              const SizedBox(height: 14),
              // Mot de passe
              _buildField(
                label: l.password,
                icon: Icons.lock_outline,
                controller: _passwordCtrl,
                hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                obscure: _obscure,
                compact: isNarrow,
                onChanged: _checkPasswordStrength,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: _kMuted,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.required;
                  if (v.length < 6) return l.passwordMinLength;
                  return null;
                },
              ),
              // Indicateur de force
              if (_passwordCtrl.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        minHeight: 4,
                        backgroundColor: _kBorder,
                        valueColor: AlwaysStoppedAnimation(_passwordColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(passwordLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _passwordColor)),
                ]),
              ],
              const SizedBox(height: 14),
              // Confirmation mot de passe
              _buildField(
                label: l.confirmPassword,
                icon: Icons.lock_outline,
                controller: _confirmCtrl,
                hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                obscure: _obscureConfirm,
                compact: isNarrow,
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: _kMuted,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return l.required;
                  if (v != _passwordCtrl.text) {
                    return l.passwordsDoNotMatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Bouton
              Consumer<AuthProvider>(
                builder: (_, auth, __) => SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: _kWhite,
                      disabledBackgroundColor: _kBlue.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(_kWhite),
                            ),
                          )
                        : Text(
                            l.createMyAccount,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Login link
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${l.hasAccount} ',
                    style: const TextStyle(fontSize: 13, color: _kMuted),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      l.login,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Features
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
                ),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _FeatureChip(l.featureAi),
                    _FeatureChip(l.featurePdf),
                    _FeatureChip(l.featureShare),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNameFields(bool isNarrow, AppLocalizations l) {
    final prenom = _buildField(
      label: l.firstName,
      icon: Icons.person_outline,
      controller: _prenomCtrl,
      hint: 'Issouf',
      compact: isNarrow,
      validator: (v) => (v == null || v.isEmpty) ? l.required : null,
    );
    final nom = _buildField(
      label: l.lastName,
      icon: Icons.person_outline,
      controller: _nomCtrl,
      hint: 'Ouedraogo',
      compact: isNarrow,
      validator: (v) => (v == null || v.isEmpty) ? l.required : null,
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          prenom,
          const SizedBox(height: 14),
          nom,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: prenom),
        const SizedBox(width: 12),
        Expanded(child: nom),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
    bool compact = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _kMuted,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          onChanged: onChanged,
          maxLines: 1,
          textCapitalization: keyboardType == TextInputType.text
              ? TextCapitalization.words
              : TextCapitalization.none,
          style: const TextStyle(fontSize: 14, color: _kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.neutral250),
            prefixIcon: Icon(icon, size: 18, color: _kMuted),
            prefixIconConstraints: BoxConstraints(
              minWidth: compact ? 38 : 46,
              minHeight: compact ? 42 : 48,
            ),
            suffixIcon: suffixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8), child: suffixIcon)
                : null,
            suffixIconConstraints: BoxConstraints(
              minWidth: compact ? 34 : 40,
              minHeight: compact ? 42 : 48,
            ),
            filled: true,
            fillColor: _kFieldBg,
            contentPadding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 14,
              vertical: compact ? 12 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBlue, width: 1),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets partagés ────────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final String text;
  const _FeatureChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: _kBlue.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(text, style: const TextStyle(fontSize: 11, color: _kMuted)),
      ],
    );
  }
}

class _GridBackground extends StatelessWidget {
  const _GridBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.35,
        child: CustomPaint(painter: _GridPainter()),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kBorder
      ..strokeWidth = 0.5;
    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _FloatingOrb extends StatefulWidget {
  final double size;
  final Color color;
  final double opacity;
  final double? top, right, bottom, left;
  final int delay;

  const _FloatingOrb({
    required this.size,
    required this.color,
    required this.opacity,
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.delay,
  });

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.delay == 0) {
      _ctrl.repeat(reverse: true);
    } else {
      _delayTimer = Timer(Duration(seconds: widget.delay), () {
        if (mounted) _ctrl.repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = _ctrl.value;
        return Positioned(
          top: widget.top != null
              ? widget.top! + 20 * math.sin(t * math.pi)
              : null,
          right: widget.right,
          bottom: widget.bottom,
          left: widget.left != null
              ? widget.left! + 15 * math.cos(t * math.pi)
              : null,
          child: child!,
        );
      },
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: widget.opacity),
              blurRadius: 80,
              spreadRadius: 40,
            ),
          ],
        ),
      ),
    );
  }
}
