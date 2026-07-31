part of '../cv_form_screen.dart';

class _MobileLayout extends StatelessWidget {
  final int currentStep;
  final PageController pageController;
  final Function(int) onStepTap;
  final bool Function(int) stepComplete;
  final int readinessScore;
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
    required this.readinessScore,
    required this.stepContents,
    required this.onNext,
    required this.onPrevious,
    required this.onSave,
    required this.isLoading,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final isLastStep = currentStep == _kStepCount - 1;
    final l = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Barre de progression
        _CompletionBar(percent: readinessScore),

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
            itemCount: _kStepCount,
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
                    label: Text(l.previous),
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
                              ? l.saving
                              : isEditing
                                  ? l.update
                                  : l.saveCv,
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
                            Text(l.next,
                                style: const TextStyle(
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
                                '${currentStep + 1}/$_kStepCount',
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
    final isLast = currentStep == _kStepCount - 1;

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
                  label: Text(_steps(context)[currentStep - 1].label),
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
                '${currentStep + 1} / $_kStepCount',
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
                  label: Text(_steps(context)[currentStep + 1].label),
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
