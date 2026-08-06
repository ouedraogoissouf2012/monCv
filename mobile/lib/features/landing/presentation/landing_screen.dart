import 'package:flutter/material.dart';

import '../../../utils/app_colors.dart';
import 'sections/feature_overview.dart';
import 'sections/how_it_works.dart';
import 'sections/landing_cta.dart';
import 'sections/landing_footer.dart';
import 'sections/landing_hero.dart';
import 'sections/product_preview.dart';
import 'sections/social_proof.dart';

/// Page d'accueil publique (issue #251).
///
/// Composition mince : chaque section vit dans son propre fichier
/// (`sections/`), les motifs communs dans `components/`. Remplace le monolithe
/// `screens/landing/landing_screen.dart` (563 l.).
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.warmBackground,
      body: SingleChildScrollView(
        child: Column(children: [
          LandingHero(),
          SocialProof(),
          FeatureOverview(),
          ProductPreview(),
          HowItWorks(),
          LandingCta(),
          LandingFooter(),
        ]),
      ),
    );
  }
}
