import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/cv.dart';
import '../../providers/cv_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/cv_preview.dart';
import 'sections/personal_info_section.dart';
import 'sections/education_section.dart';
import 'sections/experience_section.dart';
import 'sections/skills_section.dart';
import 'sections/languages_section.dart';
import 'sections/certifications_section.dart';
import 'sections/projects_section.dart';

// ── Définition des étapes ──────────────────────────────────────

class _StepInfo {
  final IconData icon;
  final String label;
  final String description;
  const _StepInfo(this.icon, this.label, this.description);
}

const _kSteps = [
  _StepInfo(Icons.person_outline_rounded, 'Identite', 'Coordonnees & profil'),
  _StepInfo(Icons.work_outline_rounded, 'Experiences', 'Parcours professionnel'),
  _StepInfo(Icons.school_outlined, 'Formations', 'Diplomes & etudes'),
  _StepInfo(Icons.psychology_outlined, 'Competences', 'Skills & langues'),
  _StepInfo(Icons.verified_outlined, 'Extras', 'Certifications & projets'),
];

// ── Écran principal ────────────────────────────────────────────

class CvFormScreen extends StatefulWidget {
  final Cv? cv;
  const CvFormScreen({super.key, this.cv});

  @override
  State<CvFormScreen> createState() => _CvFormScreenState();
}

class _CvFormScreenState extends State<CvFormScreen> {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _pageController = PageController();
  PersonalInfo? _personalInfo;
  List<Education> _educations = [];
  List<Experience> _experiences = [];
  List<Skill> _skills = [];
  List<Language> _languages = [];
  List<Certification> _certifications = [];
  List<Project> _projects = [];

  int _currentStep = 0;
  bool _isLoading = false;

  bool get isEditing => widget.cv != null;

  @override
  void initState() {
    super.initState();
    if (widget.cv != null) {
      _personalInfo = widget.cv!.personalInfo;
      _educations = List.from(widget.cv!.educations);
      _experiences = List.from(widget.cv!.experiences);
      _skills = List.from(widget.cv!.skills);
      _languages = List.from(widget.cv!.languages);
      _certifications = List.from(widget.cv!.certifications);
      _projects = List.from(widget.cv!.projects);
    }
  }

  // Genere le titre automatiquement depuis le titre du poste ou le nom
  String get _autoTitre {
    final poste = _personalInfo?.titrePoste;
    if (poste != null && poste.trim().isNotEmpty) return poste;
    final prenom = _personalInfo?.prenom ?? '';
    final nom = _personalInfo?.nom ?? '';
    if (prenom.isNotEmpty || nom.isNotEmpty) return 'CV $prenom $nom'.trim();
    return 'Mon CV';
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Cv get _currentCv => Cv(
        id: widget.cv?.id,
        titre: widget.cv?.titre ?? _autoTitre,
        personalInfo: _personalInfo,
        educations: _educations,
        experiences: _experiences,
        skills: _skills,
        languages: _languages,
        certifications: _certifications,
        projects: _projects,
      );

  bool _stepComplete(int index) {
    switch (index) {
      case 0:
        return _personalInfo?.prenom != null && _personalInfo?.email != null;
      case 1:
        return _experiences.isNotEmpty;
      case 2:
        return _educations.isNotEmpty;
      case 3:
        return _skills.isNotEmpty || _languages.isNotEmpty;
      case 4:
        return _certifications.isNotEmpty || _projects.isNotEmpty;
      default:
        return false;
    }
  }

  int get _completionPercent {
    int done = 0;
    for (int i = 0; i < 5; i++) {
      if (_stepComplete(i)) done++;
    }
    return ((done / 5) * 100).round();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _personalInfoFormKey.currentState?.validate() ?? false;
    }
    return true;
  }

  void _goToStep(int step) {
    if (step > _currentStep && !_validateCurrentStep()) return;
    setState(() => _currentStep = step);
    // PageController n'est attache qu'en mode mobile (PageView)
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _next() {
    if (!_validateCurrentStep()) return;
    if (_currentStep < 4) _goToStep(_currentStep + 1);
  }

  void _previous() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  Future<void> _save() async {
    if (!(_personalInfoFormKey.currentState?.validate() ?? false)) {
      _goToStep(0);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    setState(() => _isLoading = true);
    final cvProvider = context.read<CvProvider>();
    final bool success = isEditing
        ? await cvProvider.updateCv(widget.cv!.id!, _currentCv)
        : await cvProvider.createCv(_currentCv);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      router.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(isEditing ? 'CV mis à jour ✓' : 'CV créé avec succès ✓'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(cvProvider.error ?? 'Erreur'),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  void _showPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        builder: (ctx, sc) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Aperçu — ${_currentCv.titre}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(child: CvPreviewWidget(cv: _currentCv)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get _stepContents => [
        PersonalInfoSection(
          personalInfo: _personalInfo,
          onChanged: (info) => setState(() => _personalInfo = info),
          formKey: _personalInfoFormKey,
        ),
        _StepWrapper(
          stepIndex: 2,
          child: ExperienceSection(
            experiences: _experiences,
            onChanged: (list) => setState(() => _experiences = list),
          ),
        ),
        _StepWrapper(
          stepIndex: 3,
          child: EducationSection(
            educations: _educations,
            onChanged: (list) => setState(() => _educations = list),
          ),
        ),
        _CompetencesStep(
          skills: _skills,
          languages: _languages,
          onSkillsChanged: (list) => setState(() => _skills = list),
          onLanguagesChanged: (list) => setState(() => _languages = list),
        ),
        _ExtrasStep(
          certifications: _certifications,
          projects: _projects,
          onCertificationsChanged: (list) => setState(() => _certifications = list),
          onProjectsChanged: (list) => setState(() => _projects = list),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEditing ? 'Modifier le CV' : 'Nouveau CV',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined),
            tooltip: 'Aperçu',
            onPressed: _showPreview,
          ),
          if (isWide) ...[
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _save,
                icon: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded, size: 18),
                label: Text(isEditing ? 'Mettre à jour' : 'Enregistrer'),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
      body: isWide
          ? _DesktopLayout(
              currentStep: _currentStep,
              onStepTap: _goToStep,
              stepComplete: _stepComplete,
              completionPercent: _completionPercent,
              stepContents: _stepContents,
            )
          : _MobileLayout(
              currentStep: _currentStep,
              pageController: _pageController,
              onStepTap: _goToStep,
              stepComplete: _stepComplete,
              completionPercent: _completionPercent,
              stepContents: _stepContents,
              onNext: _next,
              onPrevious: _previous,
              onSave: _save,
              isLoading: _isLoading,
              isEditing: isEditing,
            ),
    );
  }
}

// ── Layout Mobile — Stepper ────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final int currentStep;
  final PageController pageController;
  final Function(int) onStepTap;
  final bool Function(int) stepComplete;
  final int completionPercent;
  final List<Widget> stepContents;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSave;
  final bool isLoading;
  final bool isEditing;

  const _MobileLayout({
    required this.currentStep,
    required this.pageController,
    required this.onStepTap,
    required this.stepComplete,
    required this.completionPercent,
    required this.stepContents,
    required this.onNext,
    required this.onPrevious,
    required this.onSave,
    required this.isLoading,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == 4;

    return Column(
      children: [
        // Barre de progression
        _CompletionBar(percent: completionPercent),

        // Stepper horizontal
        _StepperHeader(
          currentStep: currentStep,
          stepComplete: stepComplete,
          onStepTap: onStepTap,
        ),

        // Contenu de l'étape
        Expanded(
          child: PageView.builder(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            itemBuilder: (_, i) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: stepContents[i],
            ),
          ),
        ),

        // Boutons navigation
        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Précédent'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: isLastStep
                    ? FilledButton.icon(
                        onPressed: isLoading ? null : onSave,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          isLoading
                              ? 'Enregistrement...'
                              : isEditing
                                  ? 'Mettre à jour'
                                  : 'Enregistrer le CV',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      )
                    : FilledButton.icon(
                        onPressed: onNext,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Suivant',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${currentStep + 1}/6',
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Stepper horizontal ─────────────────────────────────────────

class _StepperHeader extends StatelessWidget {
  final int currentStep;
  final bool Function(int) stepComplete;
  final Function(int) onStepTap;

  const _StepperHeader({
    required this.currentStep,
    required this.stepComplete,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(6, (i) {
            final isActive = i == currentStep;
            final isDone = stepComplete(i) && i < currentStep;
            final isPast = i < currentStep;

            return Row(
              children: [
                if (i > 0)
                  Container(
                    width: 20,
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: isPast
                        ? colorScheme.primary.withValues(alpha: 0.6)
                        : colorScheme.outline.withValues(alpha: 0.25),
                  ),
                GestureDetector(
                  onTap: () => onStepTap(i),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colorScheme.primary
                              : isPast
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : colorScheme.outline.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: isActive
                              ? null
                              : Border.all(
                                  color: isPast
                                      ? colorScheme.primary.withValues(alpha: 0.4)
                                      : colorScheme.outline.withValues(alpha: 0.25),
                                ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Center(
                          child: isDone
                              ? Icon(Icons.check_rounded,
                                  size: 16, color: colorScheme.primary)
                              : Icon(
                                  _kSteps[i].icon,
                                  size: 16,
                                  color: isActive
                                      ? Colors.white
                                      : isPast
                                          ? colorScheme.primary
                                          : colorScheme.onSurface
                                              .withValues(alpha: 0.35),
                                ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _kSteps[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ── Barre de complétion ────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  final int percent;
  const _CompletionBar({required this.percent});

  Color _barColor(ColorScheme cs) {
    if (percent < 35) return cs.error;
    if (percent < 70) return const Color(0xFFF59E0B);
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _barColor(colorScheme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: colorScheme.outline.withValues(alpha: 0.12),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 6,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 4, 16, 2),
          child: Text(
            'Complétion : $percent%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Layout Desktop — Sidebar ───────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepTap;
  final bool Function(int) stepComplete;
  final int completionPercent;
  final List<Widget> stepContents;

  const _DesktopLayout({
    required this.currentStep,
    required this.onStepTap,
    required this.stepComplete,
    required this.completionPercent,
    required this.stepContents,
  });

  Color _barColor(ColorScheme cs, int pct) {
    if (pct < 35) return cs.error;
    if (pct < 70) return const Color(0xFFF59E0B);
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = _barColor(colorScheme, completionPercent);

    return Row(
      children: [
        // ── Sidebar ──────────────────────────────────────
        Container(
          width: 250,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              right: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.15)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Score de complétion
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMPLÉTION DU CV',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: completionPercent / 100,
                        backgroundColor:
                            colorScheme.outline.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(barColor),
                        minHeight: 7,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '$completionPercent%',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: barColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          completionPercent < 50
                              ? 'À compléter'
                              : completionPercent < 80
                                  ? 'Bon début !'
                                  : 'Excellent !',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(
                  height: 1,
                  color: colorScheme.outline.withValues(alpha: 0.15)),

              // Liste des sections
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: 5,
                  itemBuilder: (_, i) {
                    final isActive = i == currentStep;
                    final isDone = stepComplete(i);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: Material(
                        color: isActive
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => onStepTap(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? colorScheme.primary
                                        : isDone
                                            ? AppColors.success
                                                .withValues(alpha: 0.12)
                                            : colorScheme.outline
                                                .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    isDone && !isActive
                                        ? Icons.check_rounded
                                        : _kSteps[i].icon,
                                    size: 17,
                                    color: isActive
                                        ? Colors.white
                                        : isDone
                                            ? AppColors.success
                                            : colorScheme.onSurface
                                                .withValues(alpha: 0.45),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _kSteps[i].label,
                                        style: TextStyle(
                                          fontWeight: isActive
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          fontSize: 13,
                                          color: isActive
                                              ? colorScheme.primary
                                              : null,
                                        ),
                                      ),
                                      Text(
                                        _kSteps[i].description,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  Icon(Icons.chevron_right_rounded,
                                      size: 16,
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.6)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Zone de contenu ───────────────────────────────
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: currentStep,
                  children: stepContents
                      .map((content) => SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 700),
                                child: content,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
              // Boutons navigation desktop
              _DesktopNavBar(
                currentStep: currentStep,
                onStepTap: onStepTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Wrapper avec en-tête d'étape ───────────────────────────────

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
            child:
                Icon(_kSteps[stepIndex].icon, color: colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_kSteps[stepIndex].label,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            Text(_kSteps[stepIndex].description,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubSectionTitle(
          icon: Icons.psychology_outlined,
          title: 'Compétences',
          count: skills.length,
        ),
        const SizedBox(height: 12),
        SkillsSection(skills: skills, onChanged: onSkillsChanged),
        const SizedBox(height: 28),
        _SubSectionTitle(
          icon: Icons.translate_rounded,
          title: 'Langues',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SubSectionTitle(
          icon: Icons.verified_outlined,
          title: 'Certifications',
          count: certifications.length,
        ),
        const SizedBox(height: 12),
        CertificationsSection(
            certifications: certifications,
            onChanged: onCertificationsChanged),
        const SizedBox(height: 28),
        _SubSectionTitle(
          icon: Icons.rocket_launch_outlined,
          title: 'Projets',
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

class _DesktopNavBar extends StatelessWidget {
  final int currentStep;
  final Function(int) onStepTap;

  const _DesktopNavBar({
    required this.currentStep,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLast = currentStep == 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.15)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Row(
            children: [
              if (currentStep > 0)
                OutlinedButton.icon(
                  onPressed: () => onStepTap(currentStep - 1),
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(_kSteps[currentStep - 1].label),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              const Spacer(),
              // Indicateur d'étape
              Text(
                '${currentStep + 1} / 6',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (!isLast)
                FilledButton.icon(
                  onPressed: () => onStepTap(currentStep + 1),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: Text(_kSteps[currentStep + 1].label),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
