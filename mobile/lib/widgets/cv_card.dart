import 'package:flutter/material.dart';
import '../models/cv.dart';
import 'stats_badge.dart';

class CvCard extends StatelessWidget {
  final Cv cv;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDownloadPdf;
  final VoidCallback onDownloadDocx;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final VoidCallback onShare;

  const CvCard({
    super.key,
    required this.cv,
    required this.onTap,
    required this.onEdit,
    required this.onDownloadPdf,
    required this.onDownloadDocx,
    required this.onDelete,
    required this.onDuplicate,
    required this.onShare,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981);
    if (score >= 50) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _scoreLabel(int score) {
    if (score >= 80) return 'Complet';
    if (score >= 50) return 'En cours';
    return 'Incomplet';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final score = cv.completionScore;
    final scoreColor = _scoreColor(score);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge variante
              if (cv.isVariante) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.tune_rounded, size: 12, color: Color(0xFF2563EB)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Variante — ${cv.varianteLabel}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],
              // Header : titre + menu actions
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cv.titre,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Score badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$score%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  // Popup menu
                  PopupMenuButton<_CvCardAction>(
                    icon: Icon(Icons.more_vert,
                        size: 20,
                        color: colorScheme.onSurface.withValues(alpha: 0.6)),
                    padding: EdgeInsets.zero,
                    onSelected: (action) {
                      switch (action) {
                        case _CvCardAction.edit:
                          onEdit();
                        case _CvCardAction.duplicate:
                          onDuplicate();
                        case _CvCardAction.share:
                          onShare();
                        case _CvCardAction.delete:
                          onDelete();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: _CvCardAction.edit,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Modifier'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: _CvCardAction.duplicate,
                        child: ListTile(
                          leading: Icon(Icons.copy_outlined),
                          title: Text('Dupliquer'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: _CvCardAction.share,
                        child: ListTile(
                          leading: Icon(Icons.share_outlined),
                          title: Text('Partager'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: _CvCardAction.delete,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error),
                          title: Text('Supprimer',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.error)),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Date
              Row(
                children: [
                  Text(
                    _formatDate(cv.updatedAt ?? cv.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                  ),
                  if ((cv.variantCount ?? 0) > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${cv.variantCount} variante${cv.variantCount! > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF2563EB),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Barre de progression
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 5,
                        backgroundColor:
                            colorScheme.onSurface.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _scoreLabel(score),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StatsBadge(
                    count: cv.experiences.length,
                    label: 'Exp.',
                    color: colorScheme.primary,
                  ),
                  StatsBadge(
                    count: cv.skills.length,
                    label: 'Compét.',
                    color: colorScheme.secondary,
                  ),
                  StatsBadge(
                    count: cv.educations.length,
                    label: 'Formations',
                    color: const Color(0xFF10B981),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                  height: 1,
                  color: colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              // Actions principales
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Voir'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDownloadPdf,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    child: const Text('PDF'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDownloadDocx,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 12),
                    ),
                    child: const Text('DOCX'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _CvCardAction { edit, duplicate, share, delete }
