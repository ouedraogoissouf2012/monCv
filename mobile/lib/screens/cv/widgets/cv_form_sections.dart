part of '../cv_form_screen.dart';

class _StepWrapper extends StatelessWidget {
  final int stepIndex;
  final Widget child;

  const _StepWrapper({required this.stepIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_steps(context)[stepIndex].icon,
                color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_steps(context)[stepIndex].label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(_steps(context)[stepIndex].description,
                style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5))),
          ]),
        ]),
        const SizedBox(height: 20),
        child,
      ],
    );
  }
}

// ── Étape 4 — Compétences & Langues ───────────────────────────

class _CompetencesStep extends StatelessWidget {
  final List<Skill> skills;
  final List<Language> languages;
  final Function(List<Skill>) onSkillsChanged;
  final Function(List<Language>) onLanguagesChanged;

  const _CompetencesStep({
    required this.skills,
    required this.languages,
    required this.onSkillsChanged,
    required this.onLanguagesChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubSectionTitle(
          icon: Icons.psychology_outlined,
          title: l.skills,
          count: skills.length,
        ),
        const SizedBox(height: 12),
        SkillsSection(skills: skills, onChanged: onSkillsChanged),
        const SizedBox(height: 28),
        _SubSectionTitle(
          icon: Icons.translate_rounded,
          title: l.languages,
          count: languages.length,
        ),
        const SizedBox(height: 12),
        LanguagesSection(languages: languages, onChanged: onLanguagesChanged),
      ],
    );
  }
}

// ── Étape 5 — Certifications & Projets ────────────────────────

class _ExtrasStep extends StatelessWidget {
  final List<Certification> certifications;
  final List<Project> projects;
  final Function(List<Certification>) onCertificationsChanged;
  final Function(List<Project>) onProjectsChanged;

  const _ExtrasStep({
    required this.certifications,
    required this.projects,
    required this.onCertificationsChanged,
    required this.onProjectsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubSectionTitle(
          icon: Icons.verified_outlined,
          title: l.certifications,
          count: certifications.length,
        ),
        const SizedBox(height: 12),
        CertificationsSection(
            certifications: certifications, onChanged: onCertificationsChanged),
        const SizedBox(height: 28),
        _SubSectionTitle(
          icon: Icons.rocket_launch_outlined,
          title: l.projects,
          count: projects.length,
        ),
        const SizedBox(height: 12),
        ProjectsSection(projects: projects, onChanged: onProjectsChanged),
      ],
    );
  }
}

// ── Widget titre de sous-section ──────────────────────────────

class _SubSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;

  const _SubSectionTitle({
    required this.icon,
    required this.title,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: colorScheme.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (count > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Barre de navigation desktop ────────────────────────────────
