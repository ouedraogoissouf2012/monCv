import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// ── Palette ─────────────────────────────────────────────────────
const _kBlue = Color(0xFF1847D6);
const _kBg = Color(0xFFF5F3EE);
const _kText = Color(0xFF1A1A18);
const _kMuted = Color(0xFF7A7A72);
const _kBorder = Color(0xFFDDDBD4);
const _kWhite = Color(0xFFFFFFFF);
const _kFieldBg = Color(0xFFFAFAF8);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  late AnimationController _shineCtrl;

  @override
  void initState() {
    super.initState();
    _shineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(period: const Duration(milliseconds: 3500));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _shineCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
        email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erreur de connexion'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Grille subtile
          const _GridBackground(),
          // Orbes flottantes
          const _FloatingOrb(
            size: 500, color: _kBlue, opacity: 0.10,
            top: -100, right: -100, delay: 0,
          ),
          const _FloatingOrb(
            size: 400, color: _kBlue, opacity: 0.06,
            bottom: -80, left: -80, delay: 3,
          ),
          const _FloatingOrb(
            size: 300, color: Color(0xFF7864C8), opacity: 0.07,
            top: 200, left: 150, delay: 6,
          ),
          // Contenu
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCard(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(36, 40, 36, 32),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _kBorder, width: 0.5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 64,
              offset: Offset(0, 24),
            ),
            BoxShadow(
              color: Color(0x0A000000),
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
              _buildLogo(),
              const SizedBox(height: 28),
              // Headline
              _buildHeadline(),
              const SizedBox(height: 28),
              // Fields
              _buildField(
                label: 'Adresse email',
                icon: Icons.email_outlined,
                controller: _emailCtrl,
                hint: 'vous@exemple.com',
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Champ requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildField(
                label: 'Mot de passe',
                icon: Icons.lock_outline,
                controller: _passwordCtrl,
                hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
                obscure: _obscure,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18, color: _kMuted,
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
              ),
              const SizedBox(height: 8),
              // Mot de passe oublié
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Mot de passe oublié ?',
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Bouton Se connecter
              _buildLoginButton(),
              const SizedBox(height: 20),
              // Séparateur
              _buildSeparator(),
              const SizedBox(height: 20),
              // Social buttons
              _buildSocials(),
              const SizedBox(height: 20),
              // Signup link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Pas encore de compte ? ',
                    style: TextStyle(fontSize: 13, color: _kMuted),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text(
                      'Créer un compte',
                      style: TextStyle(
                        fontSize: 13, color: _kBlue, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Features strip
              _buildFeatures(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Row(
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _kBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.description_outlined, size: 20, color: _kWhite),
        ),
        const SizedBox(width: 10),
        Text(
          'MonCV',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w500, color: _kText,
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bon retour\nparmi nous.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 32, fontWeight: FontWeight.w400,
            color: _kText, height: 1.2, letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Connectez-vous pour continuer sur MonCV',
          style: TextStyle(fontSize: 14, color: _kMuted, fontWeight: FontWeight.w300),
        ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w500,
            letterSpacing: 0.8, color: _kMuted,
          ),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: _kText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFBBB9B2)),
            prefixIcon: Icon(icon, size: 18, color: _kMuted),
            suffixIcon: suffixIcon != null
                ? Padding(padding: const EdgeInsets.only(right: 8), child: suffixIcon)
                : null,
            suffixIconConstraints: const BoxConstraints(maxHeight: 24),
            filled: true,
            fillColor: _kFieldBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: auth.isLoading ? null : _login,
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
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(_kWhite),
                  ),
                )
              : const Text(
                  'Se connecter',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0.3),
                ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return const Row(
      children: [
        Expanded(child: Divider(color: _kBorder, thickness: 0.5)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'ou continuer avec',
            style: TextStyle(fontSize: 12, color: _kMuted, letterSpacing: 0.5),
          ),
        ),
        Expanded(child: Divider(color: _kBorder, thickness: 0.5)),
      ],
    );
  }

  Widget _buildSocials() {
    return Row(
      children: [
        Expanded(
          child: _SocialButton(
            label: 'Google',
            icon: _googleIcon(),
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SocialButton(
            label: 'Facebook',
            icon: const Icon(Icons.facebook, size: 18, color: Color(0xFF1877F2)),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _googleIcon() {
    return SizedBox(
      width: 16, height: 16,
      child: CustomPaint(painter: _GoogleIconPainter()),
    );
  }

  Widget _buildFeatures() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _kBorder, width: 0.5)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _FeatureChip('Suggestions IA'),
          SizedBox(width: 20),
          _FeatureChip('Export PDF'),
          SizedBox(width: 20),
          _FeatureChip('Partage public'),
        ],
      ),
    );
  }
}

// ── Social Button ────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: _kFieldBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorder, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, color: _kText)),
          ],
        ),
      ),
    );
  }
}

// ── Feature strip chip ──────────────────────────────────────────

class _FeatureChip extends StatelessWidget {
  final String text;
  const _FeatureChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5, height: 5,
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

// ── Grid Background ─────────────────────────────────────────────

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

// ── Floating Orbs ───────────────────────────────────────────────

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
    this.top, this.right, this.bottom, this.left,
    required this.delay,
  });

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    Future.delayed(Duration(seconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
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
          top: widget.top != null ? widget.top! + 20 * math.sin(t * math.pi) : null,
          right: widget.right,
          bottom: widget.bottom,
          left: widget.left != null ? widget.left! + 15 * math.cos(t * math.pi) : null,
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

// ── Google Icon Painter ─────────────────────────────────────────

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Blue
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.45, bluePaint);

    // White center
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.25, whitePaint);

    // Simplified G shape
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.35, w * 0.45, h * 0.15),
      bluePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(w * 0.48, h * 0.35, w * 0.45, h * 0.15),
      whitePaint..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
