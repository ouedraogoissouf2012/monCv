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
          _FeaturesSection(isWide: isWide),
          _HowItWorks(isWide: isWide),
          const _CtaSection(),
          const _Footer(),
        ]),
      ),
    );
  }
}

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
        Text('Creez votre CV\nprofessionnel en minutes', textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(fontSize: isWide ? 52 : 32, fontWeight: FontWeight.w400, color: Colors.white, height: 1.2)),
        const SizedBox(height: 16),
        Text('Intelligence artificielle integree. 6 templates. Export PDF & DOCX.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: isWide ? 18 : 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 32),
        Wrap(alignment: WrapAlignment.center, spacing: 12, children: [
          ElevatedButton(onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _kBlue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Creer mon CV gratuitement', style: TextStyle(fontWeight: FontWeight.w700))),
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

class _FeaturesSection extends StatelessWidget {
  final bool isWide;
  const _FeaturesSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.auto_awesome_rounded, 'IA DeepSeek', 'Ameliorez votre CV avec l\'IA. Resultats chiffres, verbes d\'action, anti-cliches.'),
      (Icons.picture_as_pdf_outlined, '6 Templates PDF', 'Moderne, Classique, Minimaliste, Creatif, Executive, ATS-Safe.'),
      (Icons.work_outline_rounded, 'Score ATS', 'Collez une offre et obtenez un score de correspondance.'),
      (Icons.description_outlined, 'Export DOCX', 'Telecharger en Word pour une compatibilite ATS maximale.'),
      (Icons.palette_outlined, 'Personnalisation', 'Couleurs, polices Google Fonts, templates customisables.'),
      (Icons.share_outlined, 'Partage public', 'Generez un lien public pour partager votre CV.'),
    ];
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      child: Column(children: [
        const Text('Tout ce dont vous avez besoin', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 40),
        Wrap(spacing: 24, runSpacing: 24, children: features.map((f) => SizedBox(
          width: isWide ? 320 : double.infinity,
          child: Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 48, height: 48,
                decoration: BoxDecoration(color: _kBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
                child: Icon(f.$1, color: _kBlue, size: 24)),
              const SizedBox(height: 16),
              Text(f.$2, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(f.$3, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
            ])),
        )).toList()),
      ]),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  final bool isWide;
  const _HowItWorks({required this.isWide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      color: const Color(0xFFF9FAFB),
      child: Column(children: [
        const Text('Comment ca marche', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 40),
        Wrap(spacing: 32, runSpacing: 32, alignment: WrapAlignment.center, children: [
          _step('1', 'Remplissez', 'Saisissez vos informations etape par etape.'),
          _step('2', 'Ameliorez', 'L\'IA corrige et ajoute des resultats chiffres.'),
          _step('3', 'Telecharger', 'Choisissez un template et exportez en PDF ou DOCX.'),
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

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: _kBlue,
      child: Column(children: [
        const Text('Pret a creer votre CV ?',
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
        Text('2026 MonCV. Createur de CV professionnel avec IA.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
      ]),
    );
  }
}
