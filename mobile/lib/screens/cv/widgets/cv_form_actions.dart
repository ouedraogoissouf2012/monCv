part of '../cv_form_screen.dart';

class _CvPreviewSheet extends StatelessWidget {
  const _CvPreviewSheet({required this.cv});

  final Cv cv;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (context, scrollController) => Container(
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
                    child: Text(
                      '${l.preview} — ${cv.titre}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(child: CvPreviewWidget(cv: cv)),
          ],
        ),
      ),
    );
  }
}

class _DesktopSaveButton extends StatelessWidget {
  const _DesktopSaveButton({required this.controller, required this.onSave});

  final CvFormController controller;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: FilledButton.icon(
        onPressed: controller.isLoading ? null : onSave,
        icon: controller.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_rounded, size: 18),
        label: Text(controller.isEditing ? l.update : l.save),
      ),
    );
  }
}
