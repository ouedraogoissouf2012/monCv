import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cv.dart';
import '../../providers/cv_provider.dart';
import '../../utils/constants.dart';

class CvListScreen extends StatelessWidget {
  const CvListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CvProvider>(
      builder: (context, cvProvider, _) {
        return RefreshIndicator(
          onRefresh: () => cvProvider.loadCvs(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cvProvider.cvs.length,
            itemBuilder: (context, index) {
              final cv = cvProvider.cvs[index];
              return _CvCard(cv: cv);
            },
          ),
        );
      },
    );
  }
}

class _CvCard extends StatelessWidget {
  final Cv cv;

  const _CvCard({required this.cv});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push('/cvs/${cv.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cv.titre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (cv.personalInfo?.titrePoste != null)
                          Text(
                            cv.personalInfo!.titrePoste!,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        context.push('/cvs/${cv.id}/edit', extra: cv);
                      } else if (value == 'delete') {
                        _showDeleteDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Modifier'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Supprimer',
                                style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.school,
                    '${cv.educations.length} formation(s)',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.work,
                    '${cv.experiences.length} experience(s)',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.star,
                    '${cv.skills.length} competence(s)',
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.language,
                    '${cv.languages.length} langue(s)',
                  ),
                ],
              ),
              if (cv.updatedAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Modifie le ${dateFormat.format(cv.updatedAt!)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le CV'),
        content: Text('Voulez-vous vraiment supprimer "${cv.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<CvProvider>().deleteCv(cv.id!);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
