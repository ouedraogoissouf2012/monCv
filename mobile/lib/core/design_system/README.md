# Design system de l'application (`core/design_system/`)

Source unique de la charte graphique de l'app Flutter (issue #233). Le but :
**changer la palette, la police ou l'échelle d'espacement depuis un seul
endroit, sans toucher aux écrans.**

> Les styles du **document CV/PDF** (`lib/pdf/`, `widgets/cv_preview.dart`)
> sont volontairement séparés : ils ont leur propre catalogue de polices, car
> l'utilisateur choisit la police de son CV. Ne pas mélanger les deux.

## Arborescence

```
core/design_system/
  tokens/
    app_color_tokens.dart   # couleurs sémantiques métier (ThemeExtension)
    app_typography.dart      # familles + échelle de texte
    app_spacing.dart         # échelle d'espacement (base 4)
    app_radii.dart           # rayons de bordure
    app_motion.dart          # durées et courbes d'animation
    app_breakpoints.dart     # points de rupture responsive
  theme/
    app_theme_spec.dart      # ce qui DIFFÈRE entre les modes
    app_theme_modes.dart     # les 3 specs (Minimal / Vibrant / Premium)
    app_theme_factory.dart   # construit le ThemeData commun (une seule fois)
    app_theme_extensions.dart# accès ergonomique : context.colorTokens, ...
```

## Recettes en un lieu

### Changer la police par défaut de l'app
Modifier **une seule constante** dans
[`tokens/app_typography.dart`](tokens/app_typography.dart) :

```dart
static const String fontFamilyBody = 'Poppins';       // corps + UI
static const String fontFamilyDisplay = 'Playfair Display'; // titres de marque
```

La famille doit être déclarée dans `pubspec.yaml > flutter > fonts` (polices
embarquées, résolues hors ligne — aucun écran n'appelle `GoogleFonts`). Pour
ajouter une police : déposer les `.ttf` dans `mobile/assets/fonts/`, les
déclarer sous `fonts:`, puis pointer la constante dessus.

### Changer une couleur sémantique (success, warning, statut…)
Éditer la palette concernée dans
[`tokens/app_color_tokens.dart`](tokens/app_color_tokens.dart)
(`AppColorTokens.light` pour Minimal/Vibrant, `AppColorTokens.dark` pour
Premium). Les teintes de base viennent de `utils/app_colors.dart`.

Dans un widget, lire une couleur sémantique via l'extension de contexte :

```dart
import 'core/design_system/theme/app_theme_extensions.dart';

Container(color: context.colorTokens.success);   // et .onSuccess pour le texte
Text('...', style: TextStyle(color: context.colors.onSurface)); // rôle Material
```

> **Toute paire `couleur` / `onCouleur` doit rester ≥ 4.5:1 (WCAG AA).** Le
> test `test/core/design_system/app_color_tokens_test.dart` échoue sinon.

### Changer l'échelle d'espacement / les rayons / le motion
Une valeur source par échelle :
- Espacement : `AppSpacing` (base 4). Utiliser `AppSpacing.md` plutôt que `16`.
- Rayons : `AppRadii` (`AppRadii.lg`, `AppRadii.pill`, …).
- Animations : `AppMotion` (`AppMotion.fast/normal/slow`).
- Responsive : `AppBreakpoints.isWide(width)` (seuil unique).

### Ajouter ou modifier un thème
Ne **jamais** dupliquer un thème de composant. Ajouter une entrée
`AppThemeSpec` dans [`theme/app_theme_modes.dart`](theme/app_theme_modes.dart)
en ne décrivant que ses différences (couleurs, fonds, remplissages). La
construction du `ThemeData` (barre d'app, cartes, bouton élevé, champs) est
faite une seule fois par
[`theme/app_theme_factory.dart`](theme/app_theme_factory.dart).

> **Non-régression** : cette PR socle reproduit à l'identique les 4 thèmes de
> composants qui préexistaient et l'échelle typographique Material. Étendre le
> thème à d'autres composants (feuilles, dialogues, navigation, snackbars) est
> un **changement visuel** : il doit venir avec ses goldens, dans une PR
> dédiée, jamais se glisser ici (l'issue #233 interdit tout redesign implicite).

## Migration en cours

`utils/app_theme.dart` (`AppThemes`) est une **façade de compatibilité** qui
route `mode → ThemeData/ColorScheme` vers la factory. Le nouveau code doit
utiliser directement les tokens et `AppThemeFactory` ; la façade sera retirée
quand tous les appelants seront migrés (suivi de #233).
```
