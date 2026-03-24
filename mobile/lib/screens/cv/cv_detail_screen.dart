import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../models/cv.dart';
import '../../providers/cv_provider.dart';
import '../../services/api_service.dart';

class CvDetailScreen extends StatefulWidget {
  final int cvId;

  const CvDetailScreen({super.key, required this.cvId});

  @override
  State<CvDetailScreen> createState() => _CvDetailScreenState();
}

class _CvDetailScreenState extends State<CvDetailScreen> {
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CvProvider>().loadCvById(widget.cvId);
    });
  }

  Future<void> _downloadPdf(BuildContext context) async {
    if (_isDownloadingPdf) return;
    setState(() => _isDownloadingPdf = true);
    try {
      final bytes = await ApiService().downloadCvPdf(widget.cvId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/cv-${widget.cvId}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Erreur PDF : $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(this.context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CvProvider>(
      builder: (context, cvProvider, _) {
        final cv = cvProvider.currentCv;

        if (cvProvider.isLoading || cv == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('CV')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, cv),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildPersonalInfoTile(context, cv.personalInfo),
                    _buildExperiencesTile(context, cv.experiences),
                    _buildFormationsTile(context, cv.educations),
                    _buildCompetencesTile(context, cv.skills),
                    _buildLanguesTile(context, cv.languages),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/cvs/${cv.id}/edit', extra: cv),
            child: const Icon(Icons.edit),
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context, Cv cv) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      floating: false,
      actions: [
        _isDownloadingPdf
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Télécharger PDF',
                onPressed: () => _downloadPdf(context),
              ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          cv.titre,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: ExpansionTile(
        leading: Icon(icon, color: colorScheme.primary),
        title: Text(
          title,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyText(BuildContext context) {
    return Text(
      'Aucune information',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
    );
  }

  Widget _buildPersonalInfoTile(BuildContext context, PersonalInfo? info) {
    return _buildSectionCard(
      context: context,
      icon: Icons.person_outline,
      title: 'Infos personnelles',
      children: info == null
          ? [_buildEmptyText(context)]
          : [
              if (info.prenom != null || info.nom != null)
                _buildInfoRow(
                  context,
                  Icons.badge_outlined,
                  [info.prenom, info.nom]
                      .where((e) => e != null && e.isNotEmpty)
                      .join(' '),
                ),
              if (info.email != null)
                _buildInfoRow(context, Icons.email_outlined, info.email!),
              if (info.telephone != null)
                _buildInfoRow(context, Icons.phone_outlined, info.telephone!),
              if (info.adresse != null)
                _buildInfoRow(
                    context, Icons.location_on_outlined, info.adresse!),
              if (info.titrePoste != null)
                _buildInfoRow(context, Icons.work_outline, info.titrePoste!),
              if (info.resumeProfessionnel != null) ...[
                const SizedBox(height: 8),
                Text(
                  'A propos',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  info.resumeProfessionnel!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              if (info.prenom == null &&
                  info.nom == null &&
                  info.email == null &&
                  info.telephone == null &&
                  info.adresse == null &&
                  info.titrePoste == null &&
                  info.resumeProfessionnel == null)
                _buildEmptyText(context),
            ],
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildExperiencesTile(
      BuildContext context, List<Experience> experiences) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM yyyy', 'fr_FR');
    return _buildSectionCard(
      context: context,
      icon: Icons.work_outline,
      title: 'Expériences',
      children: experiences.isEmpty
          ? [_buildEmptyText(context)]
          : experiences
              .map(
                (exp) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (exp.poste != null)
                        Text(
                          exp.poste!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      if (exp.entreprise != null)
                        Text(
                          exp.entreprise!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.primary),
                        ),
                      Text(
                        '${exp.dateDebut != null ? dateFormat.format(exp.dateDebut!) : '?'}'
                        ' - '
                        '${exp.actuel ? 'Présent' : (exp.dateFin != null ? dateFormat.format(exp.dateFin!) : '?')}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      if (exp.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          exp.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (experiences.last != exp)
                        const Divider(height: 16),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildFormationsTile(
      BuildContext context, List<Education> educations) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy');
    return _buildSectionCard(
      context: context,
      icon: Icons.school_outlined,
      title: 'Formations',
      children: educations.isEmpty
          ? [_buildEmptyText(context)]
          : educations
              .map(
                (edu) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (edu.diplome != null)
                        Text(
                          edu.diplome!,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      if (edu.etablissement != null)
                        Text(
                          edu.etablissement!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: colorScheme.primary),
                        ),
                      if (edu.domaine != null)
                        Text(
                          edu.domaine!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Colors.grey),
                        ),
                      Text(
                        '${edu.dateDebut != null ? dateFormat.format(edu.dateDebut!) : '?'}'
                        ' - '
                        '${edu.dateFin != null ? dateFormat.format(edu.dateFin!) : '?'}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      if (educations.last != edu)
                        const Divider(height: 16),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildCompetencesTile(BuildContext context, List<Skill> skills) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildSectionCard(
      context: context,
      icon: Icons.star_outline,
      title: 'Compétences',
      children: skills.isEmpty
          ? [_buildEmptyText(context)]
          : [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills.map((skill) {
                  final label = skill.niveau != null
                      ? '${skill.nom ?? ''} (${skill.niveau}/5)'
                      : skill.nom ?? '';
                  return Chip(
                    label: Text(label),
                    backgroundColor:
                        colorScheme.primary.withValues(alpha: 0.12),
                    labelStyle: TextStyle(color: colorScheme.primary),
                  );
                }).toList(),
              ),
            ],
    );
  }

  Widget _buildLanguesTile(BuildContext context, List<Language> languages) {
    final colorScheme = Theme.of(context).colorScheme;
    return _buildSectionCard(
      context: context,
      icon: Icons.language_outlined,
      title: 'Langues',
      children: languages.isEmpty
          ? [_buildEmptyText(context)]
          : languages
              .map(
                (lang) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.langue ?? '',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (lang.niveau != null)
                        Chip(
                          label: Text(lang.niveau!),
                          backgroundColor:
                              colorScheme.secondary.withValues(alpha: 0.15),
                          labelStyle: TextStyle(color: colorScheme.secondary),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
