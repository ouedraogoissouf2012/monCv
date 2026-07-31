part of '../cv_form_screen.dart';

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
          children: List.generate(_kStepCount, (i) {
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
                                      ? colorScheme.primary
                                          .withValues(alpha: 0.4)
                                      : colorScheme.outline
                                          .withValues(alpha: 0.25),
                                ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.3),
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
                                  _steps(context)[i].icon,
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
                        _steps(context)[i].label,
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
    if (percent < CvValidationThresholds.progressBarMediumThreshold) {
      return cs.error;
    }
    if (percent < CvValidationThresholds.progressBarGoodThreshold) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _barColor(colorScheme);
    final l = AppLocalizations.of(context)!;

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
            l.completion(percent),
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
