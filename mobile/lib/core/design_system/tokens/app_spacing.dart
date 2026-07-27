/// Echelle d'espacement de l'application, source unique.
///
/// Base 4 : toutes les valeurs derivent d'une unite de [_baseUnit]. L'echelle
/// reflete les valeurs reellement utilisees dans les ecrans (mesurees sur le
/// code existant : 4, 8, 12, 16, 20, 24, 28, 32 dominent, avec des demi-pas
/// 2/6/10/14). Changer l'unite de base ici re-espace toute l'application.
///
/// Usage : `AppSpacing.md` plutot qu'un litteral `16`. Les demi-pas
/// ([xxs], [xs]) couvrent les ajustements fins deja presents dans le code.
abstract final class AppSpacing {
  const AppSpacing._();

  /// Unite de base de la grille d'espacement (en dp logiques).
  static const double _baseUnit = 4;

  /// Retourne un multiple de l'unite de base. Pour les valeurs hors echelle
  /// nommee ponctuelles, preferer un pas nomme; ce helper existe pour composer.
  static double step(double multiplier) => _baseUnit * multiplier;

  /// 2 dp — separations tres fines (chips internes, badges).
  static const double xxs = _baseUnit / 2;

  /// 4 dp — plus petit ecart standard.
  static const double xs = _baseUnit;

  /// 8 dp — ecart compact entre elements lies.
  static const double sm = _baseUnit * 2;

  /// 12 dp — ecart par defaut le plus courant dans l'app.
  static const double md = _baseUnit * 3;

  /// 16 dp — padding de contenu, gouttiere standard.
  static const double lg = _baseUnit * 4;

  /// 20 dp — separation de groupes.
  static const double xl = _baseUnit * 5;

  /// 24 dp — marge de section.
  static const double xxl = _baseUnit * 6;

  /// 32 dp — grande respiration verticale.
  static const double xxxl = _baseUnit * 8;

  /// 48 dp — separation de blocs majeurs (heros, sections landing).
  static const double huge = _baseUnit * 12;

  /// 80 dp — gouttiere de mise en page large (desktop/landing).
  static const double gutterWide = _baseUnit * 20;
}
