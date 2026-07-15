part of '../cv_form_screen.dart';

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
    if (pct < 70) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = _barColor(colorScheme, completionPercent);
    final l = AppLocalizations.of(context)!;

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
                      l.cvCompletion,
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
                              ? l.toComplete
                              : completionPercent < 80
                                  ? l.goodStart
                                  : l.excellent,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.55),
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
                  itemCount: _kStepCount,
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
                                        : _steps(context)[i].icon,
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
                                        _steps(context)[i].label,
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
                                        _steps(context)[i].description,
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
                                constraints:
                                    const BoxConstraints(maxWidth: 700),
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
