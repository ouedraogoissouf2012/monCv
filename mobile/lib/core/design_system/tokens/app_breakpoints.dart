/// Points de rupture responsive de l'application, source unique.
///
/// Le code existant melange des seuils "wide" a 800 et 900 dp pour le meme
/// concept (mesure sur landing/cv). On les unifie ici sur une echelle a trois
/// classes proche des conventions Material, exposee via un helper unique
/// [isWide] pour eviter la re-divergence des ecrans.
abstract final class AppBreakpoints {
  const AppBreakpoints._();

  /// En dessous : telephone en portrait, mise en page a une colonne.
  static const double tablet = 600;

  /// En dessous de [desktop] et au-dessus de [tablet] : tablette / paysage.
  static const double desktop = 1024;

  /// Contenu centre au-dela de cette largeur (evite les lignes trop longues).
  static const double maxContentWidth = 1200;

  /// Vrai des que la mise en page doit passer en disposition large
  /// (deux colonnes, gouttieres etendues). Seuil unique pour toute l'app.
  static bool isWide(double width) => width >= tablet;

  /// Classe de taille de l'ecran courant, pour les rares cas a trois branches.
  static AppScreenClass classOf(double width) {
    if (width >= desktop) return AppScreenClass.desktop;
    if (width >= tablet) return AppScreenClass.tablet;
    return AppScreenClass.handset;
  }
}

/// Classe de largeur d'ecran, pour piloter les mises en page a trois niveaux.
enum AppScreenClass { handset, tablet, desktop }
