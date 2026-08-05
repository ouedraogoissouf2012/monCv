import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'auth_palette.dart';

/// Grille de fond des ecrans d'auth (issue #248, C2). Extraite a l'identique de
/// login/register (etait dupliquee : login:441-472 / register:550-581).
class AuthGridBackground extends StatelessWidget {
  const AuthGridBackground({super.key});

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Opacity(opacity: 0.35, child: CustomPaint(painter: _GridPainter())),
      );
}

class _GridPainter extends CustomPainter {
  static const double _step = 48;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AuthPalette.border
      ..strokeWidth = 0.5;
    for (double x = 0; x <= size.width; x += _step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += _step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Orbe floue animee (mouvement sin/cos, demarrage differe) — fond des ecrans
/// d'auth. Extraite a l'identique (login:476-560 / register:583-667).
class AuthFloatingOrb extends StatefulWidget {
  const AuthFloatingOrb({
    super.key,
    required this.size,
    required this.color,
    required this.opacity,
    required this.delay,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  final double size;
  final Color color;
  final double opacity;
  final int delay;
  final double? top, right, bottom, left;

  @override
  State<AuthFloatingOrb> createState() => _AuthFloatingOrbState();
}

class _AuthFloatingOrbState extends State<AuthFloatingOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 12));
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
          top: widget.top != null ? widget.top! + 20 * math.sin(t * math.pi) : null,
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
