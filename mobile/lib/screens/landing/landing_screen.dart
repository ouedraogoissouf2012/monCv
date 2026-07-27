import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/app_colors.dart';

const _kBlue = AppColors.brandBlue;
const _kBg = AppColors.warmBackground;

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
    final l = AppLocalizations.of(context)!;
    final heroTitle = isWide ? l.landingHeroTitle : l.landingHeroTitleMobile;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
          horizontal: isWide ? 80 : 24, vertical: isWide ? 80 : 48),
      decoration: const BoxDecoration(color: _kBlue),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.description_outlined,
                  size: 22, color: _kBlue)),
          const SizedBox(width: 12),
          Text('MonCV',
              style: AppTypography.display(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
        ]),
        SizedBox(height: isWide ? 48 : 32),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 720 : 320),
          child: Text(
            heroTitle,
            textAlign: TextAlign.center,
            style: AppTypography.display(
              fontSize: isWide ? 52 : 31,
              fontWeight: FontWeight.w400,
              color: Colors.white,
              height: 1.16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 680 : 300),
          child: Text(
            l.landingHeroSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: isWide ? 18 : 14,
                color: Colors.white.withValues(alpha: 0.8),
                height: 1.45),
          ),
        ),
        const SizedBox(height: 32),
        _HeroActions(isWide: isWide),
      ]),
    );
  }
}

class _HeroActions extends StatelessWidget {
  final bool isWide;
  const _HeroActions({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final primary = ElevatedButton(
      onPressed: () => context.go('/register'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: _kBlue,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(l.createCvFree,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
    final secondary = OutlinedButton(
      onPressed: () => context.go('/login'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(l.login),
    );

    if (isWide) {
      return Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [primary, secondary]);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        primary,
        const SizedBox(height: 12),
        secondary,
      ]),
    );
  }
}

// ── Preuve sociale ───────────────────────────────────────────────

class _SocialProof extends StatelessWidget {
  const _SocialProof();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      color: Colors.white,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 16,
        children: [
          SizedBox(
              width: 86, child: _StatChip(value: 'FR/EN', label: l.bilingual)),
          SizedBox(width: 72, child: _StatChip(value: '6', label: l.templates)),
          SizedBox(
              width: 86, child: _StatChip(value: 'ATS', label: l.compatible)),
          SizedBox(
              width: 92, child: _StatChip(value: 'WhatsApp', label: l.share)),
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
      Text(value,
          style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.w800, color: _kBlue)),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: AppColors.neutral450),
      ),
    ]);
  }
}

// ── Features ─────────────────────────────────────────────────────

class _FeaturesSection extends StatelessWidget {
  final bool isWide;
  const _FeaturesSection({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final features = [
      (Icons.auto_awesome_rounded, l.aiFeatureTitle, l.aiFeatureDescription),
      (
        Icons.picture_as_pdf_outlined,
        l.templatesFeatureTitle,
        l.templatesFeatureDescription
      ),
      (Icons.work_outline_rounded, l.atsFeatureTitle, l.atsFeatureDescription),
      (
        Icons.description_outlined,
        l.docxFeatureTitle,
        l.docxFeatureDescription
      ),
      (
        Icons.palette_outlined,
        l.mobileFeatureTitle,
        l.mobileFeatureDescription
      ),
      (
        Icons.chat_outlined,
        l.whatsAppFeatureTitle,
        l.whatsAppFeatureDescription
      ),
    ];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      child: Column(children: [
        Text(l.allYouNeed,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(l.allYouNeedSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral450)),
        const SizedBox(height: 40),
        // 4 premieres cartes
        Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: features
                .take(4)
                .map((f) => SizedBox(
                      width: isWide ? 280 : double.infinity,
                      child: _FeatureCard(icon: f.$1, title: f.$2, desc: f.$3),
                    ))
                .toList()),
        const SizedBox(height: 24),
        // 2 dernieres centrees
        Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: features
                .skip(4)
                .map((f) => SizedBox(
                      width: isWide ? 280 : double.infinity,
                      child: _FeatureCard(icon: f.$1, title: f.$2, desc: f.$3),
                    ))
                .toList()),
      ]),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  const _FeatureCard(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neutral100)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: _kBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _kBlue, size: 24)),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(desc,
            style: const TextStyle(
                fontSize: 13, color: AppColors.neutral450, height: 1.5)),
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
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      color: AppColors.sectionSurface,
      child: Column(children: [
        Text(l.clearCvTitle,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(l.clearCvSubtitle,
            style: const TextStyle(fontSize: 14, color: AppColors.neutral450)),
        const SizedBox(height: 32),
        // Mockup CV
        Container(
          constraints: BoxConstraints(maxWidth: isWide ? 500 : double.infinity),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 10))
              ]),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Header bleu
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: _kBlue,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(12))),
              child: Column(children: [
                Text(l.sampleCandidateName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                Text(l.sampleCandidateRole,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        fontStyle: FontStyle.italic)),
                const SizedBox(height: 8),
                Text(l.sampleCandidateContact,
                    style: const TextStyle(fontSize: 9, color: Colors.white60)),
              ]),
            ),
            // Corps
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _mockSection(l.sampleProfile),
                    Text(l.sampleProfileText,
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.neutral700,
                            height: 1.5)),
                    const SizedBox(height: 12),
                    _mockSection(l.sampleSkills),
                    Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          'Java',
                          'Spring Boot',
                          'Angular',
                          'Flutter',
                          'Docker'
                        ]
                            .map((s) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: _kBlue.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(4)),
                                child: Text(s,
                                    style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600))))
                            .toList()),
                    const SizedBox(height: 12),
                    _mockSection(l.sampleExperiences),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.sampleCandidatePosition,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                          const Text('2024 - 2026',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: _kBlue,
                                  fontWeight: FontWeight.w600)),
                        ]),
                    Text(l.sampleCandidateCompany,
                        style: const TextStyle(
                            fontSize: 9, color: AppColors.neutral450)),
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
          Container(
              width: 3,
              height: 10,
              decoration: BoxDecoration(
                  color: _kBlue, borderRadius: BorderRadius.circular(1.5))),
          const SizedBox(width: 6),
          Text(title,
              style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _kBlue,
                  letterSpacing: 1)),
        ]),
      );
}

// ── Comment ça marche ────────────────────────────────────────────

class _HowItWorks extends StatelessWidget {
  final bool isWide;
  const _HowItWorks({required this.isWide});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      child: Column(children: [
        Text(l.howItWorks,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
        const SizedBox(height: 40),
        Wrap(
            spacing: 32,
            runSpacing: 32,
            alignment: WrapAlignment.center,
            children: [
              _step('1', l.fillIn, l.fillInDescription),
              _step('2', l.adapt, l.adaptDescription),
              _step('3', l.send, l.sendDescription),
            ]),
      ]),
    );
  }

  Widget _step(String n, String title, String desc) => SizedBox(
      width: 280,
      child: Column(children: [
        CircleAvatar(
            radius: 28,
            backgroundColor: _kBlue,
            child: Text(n,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white))),
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13, color: AppColors.neutral450, height: 1.5)),
      ]));
}

// ── CTA ──────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      color: _kBlue,
      child: Column(children: [
        Text(l.readyToApply,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white)),
        const SizedBox(height: 8),
        Text(l.readyToApplySubtitle,
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 24),
        ElevatedButton(
            onPressed: () => context.go('/register'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _kBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text(l.startNow,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
      ]),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      color: AppColors.neutral900,
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.description_outlined, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text('MonCV',
              style: AppTypography.display(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ]),
        const SizedBox(height: 12),
        Text(l.landingFooter,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.5))),
      ]),
    );
  }
}
