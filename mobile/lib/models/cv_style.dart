import 'dart:ui';

import '../utils/app_colors.dart';

class CvStyle {
  final String templateId;
  final Color primaryColor;
  final String fontFamily;

  const CvStyle({
    this.templateId = 'moderne',
    this.primaryColor = AppColors.primary,
    this.fontFamily = 'Roboto',
  });

  static const List<CvTemplateInfo> templates = [
    CvTemplateInfo(
      id: 'moderne',
      label: 'Moderne',
      description: 'Corporate polyvalent pour PME et candidatures locales',
      previewColor: AppColors.primary,
    ),
    CvTemplateInfo(
      id: 'classique',
      label: 'Classique',
      description: 'Sobre, lisible et compatible ATS',
      previewColor: AppColors.neutral700,
    ),
    CvTemplateInfo(
      id: 'minimaliste',
      label: 'Junior',
      description: 'Épuré pour stages, premiers emplois et reconversion',
      previewColor: AppColors.indigo,
    ),
    CvTemplateInfo(
      id: 'creatif',
      label: 'Tech',
      description: 'Bicolonne pour projets, stack et réalisations',
      previewColor: AppColors.pink,
    ),
    CvTemplateInfo(
      id: 'executive',
      label: 'Senior',
      description: 'Cadre supérieur, management et expertise',
      previewColor: AppColors.neutral750,
    ),
    CvTemplateInfo(
      id: 'ats',
      label: 'ATS-Safe',
      description: 'International, 1 colonne, sans éléments graphiques',
      previewColor: AppColors.neutral900,
    ),
  ];

  static const List<Color> paletteColors = [
    AppColors.primary, // Bleu
    AppColors.neutral750, // Marine
    AppColors.neutral700, // Ardoise
    AppColors.indigo, // Indigo
    AppColors.pink, // Rose
    AppColors.green, // Emeraude
    AppColors.amber, // Ambre
    AppColors.redStrong, // Rouge
    AppColors.violet, // Violet
    AppColors.tealLight, // Teal
    AppColors.black, // Noir
    AppColors.neutral500, // Gris bleu
  ];

  static const List<String> fontFamilies = [
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Raleway',
    'Playfair Display',
    'Source Sans Pro',
    'Nunito',
    'Poppins',
    'Merriweather',
  ];

  CvStyle copyWith({
    String? templateId,
    Color? primaryColor,
    String? fontFamily,
  }) {
    return CvStyle(
      templateId: templateId ?? this.templateId,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'primaryColor': primaryColor.toARGB32(),
        'fontFamily': fontFamily,
      };

  factory CvStyle.fromJson(Map<String, dynamic> json) => CvStyle(
        templateId: json['templateId'] as String? ?? 'moderne',
        primaryColor: Color(json['primaryColor'] as int? ?? 0xFF2563EB),
        fontFamily: json['fontFamily'] as String? ?? 'Roboto',
      );

  static const CvStyle defaultStyle = CvStyle();
}

class CvTemplateInfo {
  final String id;
  final String label;
  final String description;
  final Color previewColor;

  const CvTemplateInfo({
    required this.id,
    required this.label,
    required this.description,
    required this.previewColor,
  });
}
