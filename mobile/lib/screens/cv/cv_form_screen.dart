import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/di/injection_container.dart';
import '../../features/cv/domain/policies/cv_validation_thresholds.dart';
import '../../l10n/app_localizations.dart';
import '../../features/cv/presentation/cv_presentation_model.dart';
import '../../features/cv/presentation/controllers/cv_list_controller.dart';
import '../../features/cv/presentation/cv_store.dart';
import '../../repositories/cv_repository.dart';
import '../../utils/constants.dart';
import '../../widgets/cv_preview.dart';
import 'controllers/cv_form_controller.dart';
import 'controllers/cv_wizard_draft_store.dart';
import 'sections/certifications_section.dart';
import 'sections/education_section.dart';
import 'sections/experience_section.dart';
import 'sections/languages_section.dart';
import 'sections/personal_info_section.dart';
import 'sections/projects_section.dart';
import 'sections/skills_section.dart';
import 'validators/cv_form_validator.dart';

part 'widgets/cv_form_desktop_layout.dart';
part 'widgets/cv_form_actions.dart';
part 'widgets/cv_form_navigation.dart';
part 'widgets/cv_form_progress.dart';
part 'widgets/cv_form_sections.dart';

class _StepInfo {
  const _StepInfo(this.icon, this.label, this.description);

  final IconData icon;
  final String label;
  final String description;
}

List<_StepInfo> _steps(BuildContext context) {
  final l = AppLocalizations.of(context)!;
  return [
    _StepInfo(Icons.person_outline_rounded, l.identity, l.contactAndProfile),
    _StepInfo(Icons.work_outline_rounded, l.experiences, l.careerPath),
    _StepInfo(Icons.school_outlined, l.education, l.degreesAndStudies),
    _StepInfo(Icons.psychology_outlined, l.skills, l.skillsAndLanguages),
    _StepInfo(Icons.verified_outlined, l.extras, l.certificationsAndProjects),
  ];
}

const _kStepCount = 5;

class CvFormScreen extends StatefulWidget {
  const CvFormScreen({super.key, this.cv, this.controller});

  final Cv? cv;
  final CvFormController? controller;

  @override
  State<CvFormScreen> createState() => _CvFormScreenState();
}

class _CvFormScreenState extends State<CvFormScreen> {
  final _personalInfoFormKey = GlobalKey<FormState>();
  final _pageController = PageController();
  CvFormController? _controller;
  bool _ownsController = false;

  CvFormController get controller => _controller!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final l = AppLocalizations.of(context)!;
    final draft = sl<CvWizardDraftStore>();
    final initial = widget.cv ??
        (widget.controller == null && draft.hasDraft ? draft.cv : null);
    _controller = widget.controller ??
        CvFormController(
          repository: sl<CvRepository>(),
          initialCv: initial,
          fallbackTitle: l.myCv,
          titleBuilder: l.cvDefaultTitle,
        );
    _ownsController = widget.controller == null;
    if (_ownsController && widget.cv == null && draft.hasDraft) {
      _controller!.goToStep(draft.step);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(_controller!.currentStep);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_ownsController && _controller != null) {
      final draft = sl<CvWizardDraftStore>();
      if (_controller!.savedCv == null && widget.cv == null) {
        draft.save(
          cv: _controller!.currentCv,
          step: _controller!.currentStep,
        );
      }
      _controller!.dispose();
    }
    super.dispose();
  }

  bool _validatePersonalInfo() {
    final formState = _personalInfoFormKey.currentState;
    return formState?.validate() ??
        CvFormValidator.isPersonalInfoValid(controller.personalInfo);
  }

  void _goToStep(int step) {
    final movingForward = step > controller.currentStep;
    if (movingForward && !_validatePersonalInfoOnCurrentStep()) return;
    if (!controller.goToStep(step)) return;
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        step,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validatePersonalInfoOnCurrentStep() =>
      controller.currentStep != 0 || _validatePersonalInfo();

  void _next() {
    if (_validatePersonalInfoOnCurrentStep()) {
      _goToStep(controller.currentStep + 1);
    }
  }

  void _previous() => _goToStep(controller.currentStep - 1);

  Future<void> _save() async {
    if (!_validatePersonalInfo()) {
      _goToStep(0);
      return;
    }

    final l = AppLocalizations.of(context)!;
    final issue = CvFormValidator.validateForSave(controller.currentCv, l);
    if (issue != null) {
      _goToStep(issue.section.index);
      _showValidationError(issue.message);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final success = await controller.save();
    if (!mounted) return;

    if (success) {
      sl<CvWizardDraftStore>().clear();
      final saved = controller.savedCv;
      if (saved != null && controller.isEditing && saved.id != null) {
        sl<CvStore>().replaceCv(saved.id!, saved);
      } else if (saved != null) {
        sl<CvStore>().addCv(saved, makeCurrent: true);
      }
      await context.read<CvListController>().load();
      if (!mounted) return;
      router.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              controller.isEditing ? l.cvUpdatedSuccess : l.cvCreatedSuccess),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(controller.error ?? l.errorGeneric),
          backgroundColor: colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showPreview() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CvPreviewSheet(cv: controller.currentCv),
    );
  }

  List<Widget> get _stepContents => [
        PersonalInfoSection(
          personalInfo: controller.personalInfo,
          onChanged: controller.updatePersonalInfo,
          formKey: _personalInfoFormKey,
        ),
        _StepWrapper(
          stepIndex: 1,
          child: ExperienceSection(
            experiences: controller.experiences,
            onChanged: controller.updateExperiences,
          ),
        ),
        _StepWrapper(
          stepIndex: 2,
          child: EducationSection(
            educations: controller.educations,
            onChanged: controller.updateEducations,
          ),
        ),
        _CompetencesStep(
          skills: controller.skills,
          languages: controller.languages,
          onSkillsChanged: controller.updateSkills,
          onLanguagesChanged: controller.updateLanguages,
        ),
        _ExtrasStep(
          certifications: controller.certifications,
          projects: controller.projects,
          onCertificationsChanged: controller.updateCertifications,
          onProjectsChanged: controller.updateProjects,
        ),
      ];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final isWide = MediaQuery.sizeOf(context).width >= 900;
          final l = AppLocalizations.of(context)!;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
              title: Text(
                controller.isEditing ? l.editCv : l.newCv,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: l.preview,
                  onPressed: _showPreview,
                ),
                if (isWide)
                  _DesktopSaveButton(controller: controller, onSave: _save),
              ],
            ),
            body: isWide
                ? _DesktopLayout(
                    currentStep: controller.currentStep,
                    onStepTap: _goToStep,
                    stepComplete: controller.stepComplete,
                    readinessScore: controller.readinessScore,
                    stepContents: _stepContents,
                  )
                : _MobileLayout(
                    currentStep: controller.currentStep,
                    pageController: _pageController,
                    onStepTap: _goToStep,
                    stepComplete: controller.stepComplete,
                    readinessScore: controller.readinessScore,
                    stepContents: _stepContents,
                    onNext: _next,
                    onPrevious: _previous,
                    onSave: _save,
                    isLoading: controller.isLoading,
                    isEditing: controller.isEditing,
                  ),
          );
        },
      );
}
