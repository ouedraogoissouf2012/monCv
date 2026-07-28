/// Reference de style d'un CV, cote domaine, sous forme pure.
///
/// Le domaine ne connait pas `Color` ni Flutter : la couleur primaire est
/// portee en entier ARGB (`0xAARRGGBB`). La conversion vers/depuis `Color`
/// (objet de presentation `CvStyle`) est faite au boundary par le mapper et
/// le wrapper de presentation, jamais ici.
///
/// Type de domaine pur : aucune dependance a Flutter, HTTP ou JSON.
final class CvStyleRef {
  final String templateId;
  final String fontFamily;

  /// Couleur primaire encodee en ARGB (`0xAARRGGBB`).
  final int primaryColorArgb;

  const CvStyleRef({
    this.templateId = 'moderne',
    this.fontFamily = 'Roboto',
    this.primaryColorArgb = 0xFF2563EB,
  });

  /// Style par defaut, utilise quand aucun style n'est fourni.
  static const CvStyleRef fallback = CvStyleRef();

  CvStyleRef copyWith({
    String? templateId,
    String? fontFamily,
    int? primaryColorArgb,
  }) {
    return CvStyleRef(
      templateId: templateId ?? this.templateId,
      fontFamily: fontFamily ?? this.fontFamily,
      primaryColorArgb: primaryColorArgb ?? this.primaryColorArgb,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CvStyleRef &&
      other.templateId == templateId &&
      other.fontFamily == fontFamily &&
      other.primaryColorArgb == primaryColorArgb;

  @override
  int get hashCode => Object.hash(templateId, fontFamily, primaryColorArgb);

  @override
  String toString() =>
      'CvStyleRef(templateId: $templateId, fontFamily: $fontFamily, '
      'primaryColorArgb: ${primaryColorArgb.toRadixString(16)})';
}
