import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/cv.dart';
import '../../providers/cv_provider.dart';
import '../../utils/constants.dart';
import 'cv_form_screen.dart';

class CvDetailScreen extends StatefulWidget {
  final int cvId;

  const CvDetailScreen({super.key, required this.cvId});

  @override
  State<CvDetailScreen> createState() => _CvDetailScreenState();
}

class _CvDetailScreenState extends State<CvDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CvProvider>().loadCvById(widget.cvId);
    });
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
          appBar: AppBar(
            title: Text(cv.titre),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CvFormScreen(cv: cv),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (cv.personalInfo != null) _buildPersonalInfoSection(cv.personalInfo!),
                if (cv.experiences.isNotEmpty) _buildExperiencesSection(cv.experiences),
                if (cv.educations.isNotEmpty) _buildEducationsSection(cv.educations),
                if (cv.skills.isNotEmpty) _buildSkillsSection(cv.skills),
                if (cv.languages.isNotEmpty) _buildLanguagesSection(cv.languages),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection(PersonalInfo info) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    info.fullName.isNotEmpty ? info.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.fullName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (info.titrePoste != null)
                        Text(
                          info.titrePoste!,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            if (info.email != null) _buildInfoRow(Icons.email, info.email!),
            if (info.telephone != null) _buildInfoRow(Icons.phone, info.telephone!),
            if (info.adresse != null || info.ville != null)
              _buildInfoRow(
                Icons.location_on,
                [info.adresse, info.ville, info.pays].where((e) => e != null).join(', '),
              ),
            if (info.linkedIn != null) _buildInfoRow(Icons.link, info.linkedIn!),
            if (info.resumeProfessionnel != null) ...[
              const SizedBox(height: 16),
              Text(
                'A propos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(info.resumeProfessionnel!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildExperiencesSection(List<Experience> experiences) {
    final dateFormat = DateFormat('MMM yyyy', 'fr_FR');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Experiences', Icons.work),
        ...experiences.map((exp) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.poste ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      exp.entreprise ?? '',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exp.dateDebut != null ? dateFormat.format(exp.dateDebut!) : ''} - ${exp.actuel ? 'Present' : (exp.dateFin != null ? dateFormat.format(exp.dateFin!) : '')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (exp.description != null) ...[
                      const SizedBox(height: 8),
                      Text(exp.description!),
                    ],
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildEducationsSection(List<Education> educations) {
    final dateFormat = DateFormat('yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Formations', Icons.school),
        ...educations.map((edu) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu.diplome ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      edu.etablissement ?? '',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    if (edu.domaine != null)
                      Text(
                        edu.domaine!,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${edu.dateDebut != null ? dateFormat.format(edu.dateDebut!) : ''} - ${edu.dateFin != null ? dateFormat.format(edu.dateFin!) : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildSkillsSection(List<Skill> skills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Competences', Icons.star),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: skills.map((skill) => Chip(
                label: Text(skill.nom ?? ''),
                backgroundColor: AppColors.primary.withOpacity(0.1),
              )).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguagesSection(List<Language> languages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Langues', Icons.language),
        ...languages.map((lang) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(lang.langue ?? ''),
              trailing: Chip(
                label: Text(lang.niveau ?? ''),
                backgroundColor: AppColors.accent.withOpacity(0.2),
              ),
            )),
      ],
    );
  }
}
