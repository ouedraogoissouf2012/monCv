import 'dart:ui';

class CvStyle {
  final String templateId;
  final Color primaryColor;
  final String fontFamily;

  const CvStyle({
    this.templateId = 'moderne',
    this.primaryColor = const Color(0xFF2563EB),
    this.fontFamily = 'Roboto',
  });

  static const List<CvTemplateInfo> templates = [
    CvTemplateInfo(
      id: 'moderne',
      label: 'Moderne',
      description: 'Bandeau coloré, mise en page dynamique',
      previewColor: Color(0xFF2563EB),
    ),
    CvTemplateInfo(
      id: 'classique',
      label: 'Classique',
      description: 'Sobre et élégant, ATS-friendly',
      previewColor: Color(0xFF374151),
    ),
    CvTemplateInfo(
      id: 'minimaliste',
      label: 'Minimaliste',
      description: 'Épuré, lignes fines, espaces généreux',
      previewColor: Color(0xFF6366F1),
    ),
    CvTemplateInfo(
      id: 'creatif',
      label: 'Créatif',
      description: 'Sidebar colorée, design bicolonne',
      previewColor: Color(0xFFEC4899),
    ),
    CvTemplateInfo(
      id: 'executive',
      label: 'Executive',
      description: 'Format cadre supérieur, sobre et impactant',
      previewColor: Color(0xFF1E3A5F),
    ),
  ];

  static const List<Color> paletteColors = [
    Color(0xFF2563EB), // Bleu
    Color(0xFF1E3A5F), // Marine
    Color(0xFF374151), // Ardoise
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Rose
    Color(0xFF10B981), // Emeraude
    Color(0xFFF59E0B), // Ambre
    Color(0xFFEF4444), // Rouge
    Color(0xFF8B5CF6), // Violet
    Color(0xFF14B8A6), // Teal
    Color(0xFF000000), // Noir
    Color(0xFF64748B), // Gris bleu
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
