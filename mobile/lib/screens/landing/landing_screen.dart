import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

const _kBlue = Color(0xFF1847D6);
const _kBg = Color(0xFFF5F3EE);

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        child: Column(children: [
          _HeroSection(isWide: isWide),
          const _SocialProof(),
          _FeaturesSection(isWide: isWide),
          const _PreviewSection(),
          _HowItWorks(isWide: isWide),
          const _CtaSection(),
          const _Footer(),
        ]),
      ),
    );
  }
}

// ── Hero ─────────────────────────────────────────────────────────

class _HeroSection extends StatelessWidget {
  final bool isWide;
  const _HeroSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: isWide ? 80 : 48),
      decoration: const BoxDecoration(color: _kBlue),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.description_outlined, size: 22, color: _kBlue)),
          const SizedBox(width: 12),
          Text('MonCV', style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white)),
        ]),
        SizedBox(height: isWide ? 48 : 32),
        Text('Créez votre CV\nprofessionnel en minutes', textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(fontSize: isWide ? 52 : 32, fontWeight: FontWeight.w400, color: Colors.white, height: 1.2)),
        const SizedBox(height: 16),
        Text('Intelligence artificielle intégrée. 6 templates. Export PDF & DOCX.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: isWide ? 18 : 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 32),
        Wrap(alignment: WrapAlignment.center, spacing: 12, runSpacing: 12, children: [
          ElevatedButton(onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _kBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Créer mon CV gratuitement', style: TextStyle(fontWeight: FontWeight.w700))),
          OutlinedButton(onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Se connecter')),
        ]),
      ]),
    );
  }
}

// ── Preuve sociale ───────────────────────────────────────────────

class _SocialProof extends StatelessWidget {
  const _SocialProof();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StatChip(value: '500+', label: 'CV créés'),
          SizedBox(width: 40),
          _StatChip(value: '6', label: 'Templates'),
          SizedBox(width: 40),
          _StatChip(value: '100%', label: 'Gratuit'),
          SizedBox(width: 40),
          _StatChip(value: 'IA', label: 'Intégrée'),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String value, label;
  const _StatChip({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _kBlue)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
    ]);
  }
}

// ── Features ─────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isWide;
  const _FeaturesSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.auto_awesome_rounded, 'Intelligence Artificielle', 'Améliorez votre CV avec l\'IA. Résultats chiffrés, verbes d\'action, anti-clichés.'),
      (Icons.picture_as_pdf_outlined, '6 Templates PDF', 'Moderne, Classique, Minimaliste, Créatif, Executive, ATS-Safe.'),
      (Icons.work_outline_rounded, 'Score ATS', 'Collez une offre et obtenez un score de correspondance.'),
      (Icons.description_outlined, 'Export DOCX', 'Téléchargez en Word pour une compatibilité ATS maximale.'),
      (Icons.palette_outlined, 'Personnalisation', 'Couleurs, polices Google Fonts, templates personnalisables.'),
      (Icons.share_outlined, 'Partage public', 'Générez un lien public pour partager votre CV.'),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      child: Column(children: [
        const Text('Tout ce dont vous avez besoin',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Un outil complet pour créer des CV qui font la différence.',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 40),
        // 4 premieres cartes
        Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
          children: features.take(4).map((f) => SizedBox(
            width: isWide ? 280 : double.infinity,
            child: _FeatureCard(icon: f.$1, title: f.$2, desc: f.$3),
          )).toList()),
        const SizedBox(height: 24),
        // 2 dernieres centrees
        Wrap(spacing: 24, runSpacing: 24, alignment: WrapAlignment.center,
          children: features.skip(4).map((f) => SizedBox(
            width: isWide ? 280 : double.infinity,
            child: _FeatureCard(icon: f.$1, title: f.$2, desc: f.$3),
          )).toList()),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _FeatureCard({required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: _kBlue, size: 24)),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
      ]),
    );
  }
}

// ── Preview CV ───────────────────────────────────────────────────

class _PreviewSection extends StatelessWidget {
  const _PreviewSection();

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 800;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      color: const Color(0xFFF9FAFB),
      child: Column(children: [
        const Text('Un CV professionnel en quelques clics',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Voici un exemple de CV généré avec MonCV',
            style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        const SizedBox(height: 32),
        // Mockup CV
        Container(
          constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 10))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header bleu
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
              child: const Column(children: [
                Text('ISSOUF OUEDRAOGO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 2)),
                SizedBox(height: 4),
                Text('Ingénieur Logiciel Full Stack', style: TextStyle(fontSize: 12, color: Colors.white70, fontStyle: FontStyle.italic)),
                SizedBox(height: 8),
                Text('issouf@gmail.com  |  +225 07 44 21 01 12  |  Abidjan', style: TextStyle(fontSize: 9, color: Colors.white60)),
              ]),
            ),
            // Corps
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _mockSection('PROFIL'),
                const Text('Ingénieur Full Stack avec 3 ans d\'expérience. Expert Java/Spring Boot et Flutter.',
                    style: TextStyle(fontSize: 10, color: Color(0xFF374151), height: 1.5)),
                const SizedBox(height: 12),
                _mockSection('COMPÉTENCES'),
                Wrap(spacing: 6, runSpacing: 6, children: ['Java', 'Spring Boot', 'Angular', 'Flutter', 'Docker']
                    .map((s) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(s, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600)))).toList()),
                const SizedBox(height: 12),
                _mockSection('EXPÉRIENCES'),
                const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Lead Developer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  Text('2024 - 2026', style: TextStyle(fontSize: 9, color: _kBlue, fontWeight: FontWeight.w600)),
                ]),
                const Text('DIGIT AFRICAN - Abidjan', style: TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _mockSection(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [
      Container(width: 3, height: 10, decoration: BoxDecoration(color: _kBlue, borderRadius: BorderRadius.circular(1.5))),
      const SizedBox(width: 6),
      Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _kBlue, letterSpacing: 1)),
    ]),
  );
}

// ── Comment ça marche ────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool isWide;
  const _HowItWorks({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      child: Column(children: [
        const Text('Comment ça marche', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 40),
        Wrap(spacing: 32, runSpacing: 32, alignment: WrapAlignment.center, children: [
          _step('1', 'Remplissez', 'Saisissez vos informations étape par étape.'),
          _step('2', 'Améliorez', 'L\'IA corrige et ajoute des résultats chiffrés.'),
          _step('3', 'Téléchargez', 'Choisissez un template et exportez en PDF ou DOCX.'),
        ]),
      ]),
    );
  }

  Widget _step(String n, String title, String desc) => SizedBox(width: 280,
    child: Column(children: [
      CircleAvatar(radius: 28, backgroundColor: _kBlue,
        child: Text(n, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(desc, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
    ]));
}

// ── CTA ──────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: _kBlue,
      child: Column(children: [
        const Text('Prêt à créer votre CV ?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text('Gratuit. Aucune carte bancaire requise.',
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => context.go('/register'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _kBlue,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Commencer maintenant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      ]),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: const Color(0xFF111827),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.description_outlined, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text('MonCV', style: GoogleFonts.playfairDisplay(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 12),
        Text('© 2026 MonCV. Créateur de CV professionnel avec IA.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
      ]),
    );
  }
}
