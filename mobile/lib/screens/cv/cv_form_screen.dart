import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/cv.dart';
import '../../providers/cv_provider.dart';
import '../../utils/constants.dart';
import 'sections/personal_info_section.dart';
import 'sections/education_section.dart';
import 'sections/experience_section.dart';
import 'sections/skills_section.dart';
import 'sections/languages_section.dart';

class CvFormScreen extends StatefulWidget {
  final Cv? cv;

  const CvFormScreen({super.key, this.cv});

  @override
  State<CvFormScreen> createState() => _CvFormScreenState();
}

class _CvFormScreenState extends State<CvFormScreen> {
  final _titreFormKey = GlobalKey<FormState>();
  final _personalInfoFormKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  PersonalInfo? _personalInfo;
  List<Education> _educations = [];
  List<Experience> _experiences = [];
  List<Skill> _skills = [];
  List<Language> _languages = [];

  bool _isLoading = false;

  bool get isEditing => widget.cv != null;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.cv?.titre ?? '');
    if (widget.cv != null) {
      _personalInfo = widget.cv!.personalInfo;
      _educations = List.from(widget.cv!.educations);
      _experiences = List.from(widget.cv!.experiences);
      _skills = List.from(widget.cv!.skills);
      _languages = List.from(widget.cv!.languages);
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final titreOk = _titreFormKey.currentState?.validate() ?? false;
    final infoOk = _personalInfoFormKey.currentState?.validate() ?? false;
    if (!titreOk || !infoOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez corriger les champs obligatoires'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    setState(() => _isLoading = true);

    final cv = Cv(
      id: widget.cv?.id,
      titre: _titreController.text,
      personalInfo: _personalInfo,
      educations: _educations,
      experiences: _experiences,
      skills: _skills,
      languages: _languages,
    );

    final cvProvider = context.read<CvProvider>();
    final bool success;

    if (isEditing) {
      success = await cvProvider.updateCv(widget.cv!.id!, cv);
    } else {
      success = await cvProvider.createCv(cv);
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      router.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'CV mis à jour ✓' : 'CV créé avec succès ✓'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(cvProvider.error ?? 'Erreur'),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // ── Hero AppBar ────────────────────────────────
                SliverAppBar(
                  expandedHeight: 150,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.pop(),
                  ),
                  backgroundColor: colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.description_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    isEditing ? 'Modifier le CV' : 'Nouveau CV',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isEditing
                                    ? 'Mettez à jour vos informations'
                                    : 'Remplissez les sections ci-dessous',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Contenu ────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Titre du CV
                        _TitleField(
                          formKey: _titreFormKey,
                          controller: _titreController,
                        ),
                        const SizedBox(height: 16),

                        _SectionCard(
                          title: 'Informations personnelles',
                          icon: Icons.person_outline_rounded,
                          child: PersonalInfoSection(
                            personalInfo: _personalInfo,
                            onChanged: (info) => setState(() => _personalInfo = info),
                            formKey: _personalInfoFormKey,
                          ),
                        ),
                        _SectionCard(
                          title: 'Expériences',
                          icon: Icons.work_outline_rounded,
                          count: _experiences.length,
                          child: ExperienceSection(
                            experiences: _experiences,
                            onChanged: (list) => setState(() => _experiences = list),
                          ),
                        ),
                        _SectionCard(
                          title: 'Formations',
                          icon: Icons.school_outlined,
                          count: _educations.length,
                          child: EducationSection(
                            educations: _educations,
                            onChanged: (list) => setState(() => _educations = list),
                          ),
                        ),
                        _SectionCard(
                          title: 'Compétences',
                          icon: Icons.psychology_outlined,
                          count: _skills.length,
                          child: SkillsSection(
                            skills: _skills,
                            onChanged: (list) => setState(() => _skills = list),
                          ),
                        ),
                        _SectionCard(
                          title: 'Langues',
                          icon: Icons.translate_rounded,
                          count: _languages.length,
                          child: LanguagesSection(
                            languages: _languages,
                            onChanged: (list) => setState(() => _languages = list),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bouton sticky ─────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16, 12, 16, 16 + MediaQuery.of(context).viewInsets.bottom,
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
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(
                _isLoading
                    ? 'Enregistrement...'
                    : isEditing
                        ? 'Mettre à jour'
                        : 'Enregistrer le CV',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Titre du CV ──────────────────────────────────────────────

class _TitleField extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;

  const _TitleField({required this.formKey, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.title_rounded,
                      color: colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(
                  'Titre du CV',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(requis)',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Ex : Développeur Full Stack',
                  prefixIcon: Icon(Icons.edit_outlined, size: 20),
                ),
                style: const TextStyle(fontWeight: FontWeight.w600),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Titre requis' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Card ─────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final int? count;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
                if (count != null && count! > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: colorScheme.outline.withValues(alpha: 0.15),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}
