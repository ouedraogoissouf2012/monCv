import 'package:flutter/material.dart';

/// Splash screen affiche pendant le chargement de l'app.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo icone
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.onPrimary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.description_outlined,
                size: 44,
                color: colors.primary,
                semanticLabel: 'MonCV',
              ),
            ),
            const SizedBox(height: 24),
            // Nom
            Text(
              'MonCV',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: colors.onPrimary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creez votre CV professionnel',
              style: TextStyle(
                fontSize: 14,
                color: colors.onPrimary.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 48),
            // Loading
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation(
                  colors.onPrimary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
