/// Identifiants des themes de l'application.
///
/// Vit dans le design system (et non dans `providers/`) pour respecter la
/// direction des dependances : la couche de presentation/etat depend du design
/// system, jamais l'inverse. `ThemeProvider` reexporte ce type pour la
/// compatibilite des appelants existants.
enum AppThemeMode { minimal, vibrant, premium }
