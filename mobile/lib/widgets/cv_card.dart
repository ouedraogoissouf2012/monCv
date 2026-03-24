import 'package:flutter/material.dart';
import '../models/cv.dart';
import 'stats_badge.dart';

class CvCard extends StatelessWidget {
  final Cv cv;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDownloadPdf;

  const CvCard({
    super.key,
    required this.cv,
    required this.onTap,
    required this.onEdit,
    required this.onDownloadPdf,
  });

  bool get _isComplete =>
      cv.personalInfo != null &&
      (cv.experiences.isNotEmpty || cv.educations.isNotEmpty);

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header : titre + badge statut
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
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _isComplete
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isComplete ? 'Complet' : 'Incomplet',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: _isComplete
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Date
              Text(
                _formatDate(cv.updatedAt ?? cv.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
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
              Divider(height: 1, color: colorScheme.onSurface.withValues(alpha: 0.1)),
              const SizedBox(height: 10),
              // Actions
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
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                    ),
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
